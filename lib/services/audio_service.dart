import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';

import '../core/constants/game_constants.dart';
import 'storage_service.dart';

enum Sfx { tap, perfect, over }

/// Sound effects. Each sound has a small pool of players so quick repeated
/// drops can overlap. If anything fails, sound is silently disabled
/// (Section F-01: "Sound files failed to load → continue silently").
class AudioService {
  AudioService._() {
    _soundEnabled = StorageService.instance.soundOn;
    StorageService.instance.addListener(_onSettingsChanged);
  }

  static final AudioService instance = AudioService._();

  static const Map<Sfx, String> _files = <Sfx, String>{
    Sfx.tap: 'sounds/tap.wav',
    Sfx.perfect: 'sounds/perfect.wav',
    Sfx.over: 'sounds/over.wav',
  };
  static const int _poolSize = 3;

  final Map<Sfx, List<AudioPlayer>> _pools = <Sfx, List<AudioPlayer>>{};
  final Map<Sfx, int> _next = <Sfx, int>{};
  bool _available = false;
  bool _soundEnabled = true;

  bool get isAvailable => _available;

  /// Turning Sound off anywhere in the app stops every player immediately.
  void _onSettingsChanged() {
    final bool on = StorageService.instance.soundOn;
    if (!on && _soundEnabled) unawaited(stopAll());
    _soundEnabled = on;
  }

  /// Never throws. Gives up after 5 s.
  Future<void> load() async {
    try {
      await _loadInternal().timeout(const Duration(seconds: 5));
      _available = true;
    } catch (_) {
      _available = false;
    }
  }

  Future<void> _loadInternal() async {
    // Do not steal audio focus from the user's music.
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
    );
    await AudioCache.instance.loadAll(_files.values.toList());
    for (final Sfx sfx in Sfx.values) {
      final List<AudioPlayer> pool = <AudioPlayer>[];
      for (int i = 0; i < _poolSize; i++) {
        final AudioPlayer p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        pool.add(p);
      }
      _pools[sfx] = pool;
      _next[sfx] = 0;
    }
  }

  /// Plays [sfx]. [rate] changes pitch (1.0 = normal).
  Future<void> play(Sfx sfx, {double volume = 1.0, double rate = 1.0}) async {
    if (!_available || !StorageService.instance.soundOn) return;
    final List<AudioPlayer>? pool = _pools[sfx];
    if (pool == null || pool.isEmpty) return;
    final int index = ((_next[sfx] ?? 0) + 1) % pool.length;
    _next[sfx] = index;
    final AudioPlayer p = pool[index];
    try {
      await p.setPlaybackRate(rate.clamp(0.5, 2.0).toDouble());
      // Sound may have been switched off while this call was awaiting.
      if (!StorageService.instance.soundOn) return;
      await p.play(AssetSource(_files[sfx]!), volume: volume.clamp(0.0, 1.0).toDouble());
    } catch (_) {
      // Sound plays too late or fails → ignored, game continues (Section 14).
    }
  }

  /// perfect.wav, one semitone higher for each combo step (max 8 steps).
  Future<void> playPerfect(int combo) {
    final int steps = (combo - 1).clamp(0, GameConst.maxPitchSteps).toInt();
    final double rate = math.pow(2, steps / 12).toDouble();
    return play(Sfx.perfect, rate: rate);
  }

  /// Turning sound off stops everything immediately.
  Future<void> stopAll() async {
    for (final List<AudioPlayer> pool in _pools.values) {
      for (final AudioPlayer p in pool) {
        try {
          await p.stop();
        } catch (_) {}
      }
    }
  }
}
