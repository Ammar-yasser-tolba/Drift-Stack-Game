import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/skins.dart';
import '../core/utils/utc_date.dart';
import '../models/game_mode.dart';
import '../models/ghost.dart';

/// Result of [StorageService.commitRun] — everything S5 needs to display.
class RunCommitResult {
  const RunCommitResult({
    required this.isNewBest,
    required this.best,
    required this.streak,
    required this.coinsEarned,
  });

  final bool isNewBest;
  final int best;
  final int streak;
  final int coinsEarned;
}

/// All persisted data (Section 1.4). Values live in memory and are mirrored
/// to shared_preferences. If loading or saving fails the game keeps working
/// from memory (Rule 1.5-7, Section F-01).
class StorageService extends ChangeNotifier {
  StorageService._();

  static final StorageService instance = StorageService._();

  // ---- keys (Section 1.4) ----
  static const String kBestClassic = 'bestClassic';
  static const String kGhostClassic = 'ghostClassic';
  static const String kBestDaily = 'bestDaily';
  static const String kBestDailyDate = 'bestDailyDate';
  static const String kGhostDaily = 'ghostDaily';
  static const String kStreak = 'streak';
  static const String kLastDailyDate = 'lastDailyDate';
  static const String kCoins = 'coins';
  static const String kOwnedSkins = 'ownedSkins';
  static const String kEquippedSkin = 'equippedSkin';
  static const String kSoundOn = 'soundOn';
  static const String kHapticsOn = 'hapticsOn';
  static const String kGhostSource = 'ghostSource';
  static const String kGhostOffMigration = 'ghostOffMigration';
  static const String kFriendGhost = 'friendGhost';
  static const String kTutorialSeen = 'tutorialSeen';

  static const Duration loadTimeout = Duration(seconds: 5);

  SharedPreferences? _prefs;
  bool _loaded = false;
  bool _loadFailed = false;
  bool _saveFailureReported = false;

  final StreamController<String> _messages = StreamController<String>.broadcast();

  // ---- in-memory values ----
  int _bestClassic = 0;
  Ghost? _ghostClassic;
  int _bestDaily = 0;
  String _bestDailyDate = '';
  Ghost? _ghostDaily;
  int _streak = 0;
  String _lastDailyDate = '';
  int _coins = 0;
  Set<String> _ownedSkins = <String>{Skins.neon.id};
  String _equippedSkin = Skins.neon.id;
  bool _soundOn = true;
  bool _hapticsOn = true;
  GhostSource _ghostSource = GhostSource.off;
  Ghost? _friendGhost;
  bool _tutorialSeen = false;

  // ---- status ----
  bool get isLoaded => _loaded;

  /// True when storage could not be read (or took > 5 s). Saving is skipped
  /// for the whole session in that case.
  bool get loadFailed => _loadFailed;

  /// Runtime messages that need a snackbar (e.g. `Couldn't save progress.`).
  /// Emitted at most once per app session.
  Stream<String> get messages => _messages.stream;

  // ---- getters ----
  int get bestClassic => _bestClassic;
  Ghost? get ghostClassic => _ghostClassic;
  int get bestDaily => _bestDaily;
  String get bestDailyDate => _bestDailyDate;
  Ghost? get ghostDaily => _ghostDaily;
  int get streak => _streak;
  String get lastDailyDate => _lastDailyDate;
  int get coins => _coins;
  Set<String> get ownedSkins => Set<String>.unmodifiable(_ownedSkins);
  String get equippedSkinId => _equippedSkin;
  SkinDef get equippedSkin => Skins.byId(_equippedSkin);
  bool get soundOn => _soundOn;
  bool get hapticsOn => _hapticsOn;
  GhostSource get ghostSource => _ghostSource;
  Ghost? get friendGhost => _friendGhost;
  bool get tutorialSeen => _tutorialSeen;

  // ---- derived (Section 3.2, 13) ----

  /// Daily card is in State B (already played today).
  bool get dailyPlayedToday => _bestDailyDate == UtcDate.todayKey;

  /// Today's Daily best (0 if the stored best belongs to another date).
  int get dailyBestToday => dailyPlayedToday ? _bestDaily : 0;

  /// Streak shown on S1: the stored number only if lastDailyDate is today,
  /// yesterday, or (clock tampering) in the future; otherwise 0.
  int get displayStreak {
    if (_lastDailyDate.isEmpty) return 0;
    final int last = int.tryParse(_lastDailyDate) ?? 0;
    final int yesterday = int.parse(UtcDate.yesterdayKey);
    return last >= yesterday ? _streak : 0;
  }

  bool ownsSkin(String id) => _ownedSkins.contains(id);

  /// The ghost to race against, honouring `ghostSource` (Section 5.4).
  /// Returns null when the chosen ghost does not exist.
  Ghost? activeGhostFor(GameMode mode) {
    switch (_ghostSource) {
      case GhostSource.off:
        return null;
      case GhostSource.friend:
        return _friendGhost;
      case GhostSource.mine:
        if (mode == GameMode.classic) return _ghostClassic;
        return dailyPlayedToday ? _ghostDaily : null;
    }
  }

  // ======================================================================
  // Loading
  // ======================================================================

  /// Loads everything. Never throws. On failure (or after 5 s) the defaults
  /// stay in memory, [loadFailed] becomes true and nothing is saved.
  Future<void> load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance().timeout(loadTimeout);
      _prefs = p;
      _readAll(p);
      await _migrateGhostOff(p);
      _loadFailed = false;
    } catch (_) {
      _prefs = null;
      _loadFailed = true;
      _applyDefaults(keepSettings: false);
    }
    _loaded = true;
    notifyListeners();
  }

  void _readAll(SharedPreferences p) {
    _bestClassic = _readInt(p, kBestClassic).clamp(0, 1 << 30).toInt();
    _ghostClassic = Ghost.fromStored(_readString(p, kGhostClassic));
    _bestDaily = _readInt(p, kBestDaily).clamp(0, 1 << 30).toInt();
    _bestDailyDate = _readString(p, kBestDailyDate);
    _ghostDaily = Ghost.fromStored(_readString(p, kGhostDaily));
    _streak = _readInt(p, kStreak).clamp(0, 1 << 30).toInt();
    _lastDailyDate = _readString(p, kLastDailyDate);
    _coins = _readInt(p, kCoins).clamp(0, 1 << 30).toInt();

    final Set<String> owned = <String>{Skins.neon.id};
    try {
      final List<String>? list = p.getStringList(kOwnedSkins);
      if (list != null) {
        for (final String id in list) {
          if (Skins.all.any((SkinDef s) => s.id == id)) owned.add(id);
        }
      }
    } catch (_) {}
    _ownedSkins = owned;

    final String eq = _readString(p, kEquippedSkin, Skins.neon.id);
    _equippedSkin = owned.contains(eq) ? eq : Skins.neon.id;

    _soundOn = _readBool(p, kSoundOn, true);
    _hapticsOn = _readBool(p, kHapticsOn, true);
    _ghostSource = GhostSource.fromName(_readString(p, kGhostSource, GhostSource.off.name));
    _friendGhost = Ghost.fromStored(_readString(p, kFriendGhost));
    if (_ghostSource == GhostSource.friend && _friendGhost == null) {
      _ghostSource = GhostSource.off;
    }
    _tutorialSeen = _readBool(p, kTutorialSeen, false);
  }

  /// Ghost preview used to be on by default, so every run started under the
  /// best tower. Runs now start clean; one migration turns the old default
  /// into OFF without touching a later, deliberate MY BEST / FRIEND choice.
  Future<void> _migrateGhostOff(SharedPreferences p) async {
    if (_readBool(p, kGhostOffMigration, false)) return;
    try {
      if (_readString(p, kGhostSource) == GhostSource.mine.name) {
        _ghostSource = GhostSource.off;
        await p.setString(kGhostSource, GhostSource.off.name);
      }
      await p.setBool(kGhostOffMigration, true);
    } catch (_) {}
  }

  int _readInt(SharedPreferences p, String key, [int def = 0]) {
    try {
      return p.getInt(key) ?? def;
    } catch (_) {
      return def;
    }
  }

  String _readString(SharedPreferences p, String key, [String def = '']) {
    try {
      return p.getString(key) ?? def;
    } catch (_) {
      return def;
    }
  }

  bool _readBool(SharedPreferences p, String key, bool def) {
    try {
      return p.getBool(key) ?? def;
    } catch (_) {
      return def;
    }
  }

  void _applyDefaults({required bool keepSettings}) {
    _bestClassic = 0;
    _ghostClassic = null;
    _bestDaily = 0;
    _bestDailyDate = '';
    _ghostDaily = null;
    _streak = 0;
    _lastDailyDate = '';
    _coins = 0;
    _ownedSkins = <String>{Skins.neon.id};
    _equippedSkin = Skins.neon.id;
    _ghostSource = GhostSource.off;
    _friendGhost = null;
    if (!keepSettings) {
      _soundOn = true;
      _hapticsOn = true;
      _tutorialSeen = false;
    }
  }

  // ======================================================================
  // Saving
  // ======================================================================

  /// Writes [values] (int / bool / String / List<String>). Fire-and-forget;
  /// failures show one snackbar per session and the game continues.
  Future<void> _save(Map<String, Object> values) async {
    final SharedPreferences? p = _prefs;
    if (p == null) return; // load failed → skip all saving this session
    try {
      for (final MapEntry<String, Object> e in values.entries) {
        final Object v = e.value;
        bool ok;
        if (v is int) {
          ok = await p.setInt(e.key, v);
        } else if (v is bool) {
          ok = await p.setBool(e.key, v);
        } else if (v is String) {
          ok = await p.setString(e.key, v);
        } else if (v is List<String>) {
          ok = await p.setStringList(e.key, v);
        } else {
          ok = false;
        }
        if (!ok) throw StateError('write failed: ${e.key}');
      }
    } catch (_) {
      _reportSaveFailure();
    }
  }

  void _reportSaveFailure() {
    if (_saveFailureReported) return;
    _saveFailureReported = true;
    _messages.add("Couldn't save progress.");
  }

  void _persist(Map<String, Object> values) {
    notifyListeners();
    unawaited(_save(values));
  }

  // ======================================================================
  // Settings
  // ======================================================================

  void setSoundOn(bool value) {
    _soundOn = value;
    _persist(<String, Object>{kSoundOn: value});
  }

  void setHapticsOn(bool value) {
    _hapticsOn = value;
    _persist(<String, Object>{kHapticsOn: value});
  }

  void setGhostSource(GhostSource value) {
    if (value == GhostSource.friend && _friendGhost == null) return;
    _ghostSource = value;
    _persist(<String, Object>{kGhostSource: value.name});
  }

  void setTutorialSeen(bool value) {
    _tutorialSeen = value;
    _persist(<String, Object>{kTutorialSeen: value});
  }

  // ======================================================================
  // Friend ghost (S8)
  // ======================================================================

  /// Saves an imported ghost and switches `ghostSource` to friend.
  void importFriendGhost(Ghost ghost) {
    _friendGhost = ghost;
    _ghostSource = GhostSource.friend;
    _persist(<String, Object>{
      kFriendGhost: ghost.encode(),
      kGhostSource: GhostSource.friend.name,
    });
  }

  /// REMOVE on S8: cleared immediately; if friend was selected it becomes OFF.
  void removeFriendGhost() {
    _friendGhost = null;
    final Map<String, Object> w = <String, Object>{kFriendGhost: ''};
    if (_ghostSource == GhostSource.friend) {
      _ghostSource = GhostSource.off;
      w[kGhostSource] = GhostSource.off.name;
    }
    _persist(w);
  }

  // ======================================================================
  // Skins & coins (S6)
  // ======================================================================

  /// Equips an owned skin. Returns false if not owned.
  bool equipSkin(String id) {
    if (!_ownedSkins.contains(id)) return false;
    _equippedSkin = id;
    _persist(<String, Object>{kEquippedSkin: id});
    return true;
  }

  /// Buys and auto-equips a skin. Returns false if the skin is already owned
  /// or the player cannot afford it (caller shows D4 in the latter case).
  bool buySkin(SkinDef skin) {
    if (_ownedSkins.contains(skin.id)) return false;
    if (_coins < skin.price) return false;
    _coins -= skin.price;
    _ownedSkins = <String>{..._ownedSkins, skin.id};
    _equippedSkin = skin.id;
    _persist(<String, Object>{
      kCoins: _coins,
      kOwnedSkins: _ownedSkins.toList(),
      kEquippedSkin: _equippedSkin,
    });
    return true;
  }

  // ======================================================================
  // Finished run (S5, Section 7.1 + 13)
  // ======================================================================

  /// Called the moment S5 opens: adds coins, updates best/ghost, applies the
  /// Daily streak rules. [ghost] is the tower of the finished run.
  RunCommitResult commitRun({
    required GameMode mode,
    required int score,
    required Ghost ghost,
  }) {
    final Map<String, Object> w = <String, Object>{};
    _coins += score;
    w[kCoins] = _coins;

    bool isNewBest = false;
    int best;
    int streakNow = _streak;

    if (mode == GameMode.classic) {
      if (score > _bestClassic) {
        _bestClassic = score;
        _ghostClassic = ghost;
        isNewBest = true;
        w[kBestClassic] = _bestClassic;
        w[kGhostClassic] = ghost.encode();
      }
      best = _bestClassic;
    } else {
      final String today = UtcDate.todayKey;
      if (_bestDailyDate != today) {
        _bestDaily = 0;
        _ghostDaily = null;
        w[kBestDaily] = 0;
        w[kGhostDaily] = '';
      }
      if (score > _bestDaily) {
        _bestDaily = score;
        _bestDailyDate = today;
        _ghostDaily = ghost;
        isNewBest = true;
        w[kBestDaily] = _bestDaily;
        w[kBestDailyDate] = today;
        w[kGhostDaily] = ghost.encode();
      }
      best = _bestDaily;

      // Streak rules (Section 13).
      final int todayN = int.parse(today);
      final int yesterdayN = int.parse(UtcDate.yesterdayKey);
      final int lastN = int.tryParse(_lastDailyDate) ?? 0;
      if (_lastDailyDate.isNotEmpty && lastN >= todayN) {
        // Same day, or phone date moved back (future lastDailyDate):
        // treat as today → streak unchanged, keep the stored date.
      } else if (_lastDailyDate.isNotEmpty && lastN == yesterdayN) {
        _streak += 1;
        _lastDailyDate = today;
      } else {
        _streak = 1;
        _lastDailyDate = today;
      }
      streakNow = _streak;
      w[kStreak] = _streak;
      w[kLastDailyDate] = _lastDailyDate;
    }

    _persist(w);
    return RunCommitResult(
      isNewBest: isNewBest,
      best: best,
      streak: streakNow,
      coinsEarned: score,
    );
  }

  // ======================================================================
  // Reset (D5)
  // ======================================================================

  /// Everything in 1.4 returns to default except soundOn, hapticsOn and
  /// tutorialSeen.
  void resetProgress() {
    _applyDefaults(keepSettings: true);
    _persist(<String, Object>{
      kBestClassic: 0,
      kGhostClassic: '',
      kBestDaily: 0,
      kBestDailyDate: '',
      kGhostDaily: '',
      kStreak: 0,
      kLastDailyDate: '',
      kCoins: 0,
      kOwnedSkins: <String>[Skins.neon.id],
      kEquippedSkin: Skins.neon.id,
      kGhostSource: GhostSource.off.name,
      kFriendGhost: '',
    });
  }
}
