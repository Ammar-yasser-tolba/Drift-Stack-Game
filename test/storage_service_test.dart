import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drift_stack/models/game_mode.dart';
import 'package:drift_stack/models/ghost.dart';
import 'package:drift_stack/services/storage_service.dart';

Ghost _tower(int score) => Ghost(
      score: score,
      seed: 5,
      floors: List<GhostFloor>.generate(
        score + 1,
        (int i) => const GhostFloor(0.3, 0.4),
      ),
    );

Future<SharedPreferences> _loadWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  await StorageService.instance.load();
  return SharedPreferences.getInstance();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh install starts with the ghost OFF and no ghost on the canvas',
      () async {
    final SharedPreferences p = await _loadWith(<String, Object>{});

    expect(StorageService.instance.ghostSource, GhostSource.off);
    expect(StorageService.instance.activeGhostFor(GameMode.classic), isNull);
    expect(p.getString(StorageService.kGhostSource), isNull);
  });

  test('ghost still stays hidden when a personal best exists', () async {
    await _loadWith(<String, Object>{});
    StorageService.instance.commitRun(
      mode: GameMode.classic,
      score: 7,
      ghost: _tower(7),
    );

    expect(StorageService.instance.ghostClassic?.score, 7);
    expect(StorageService.instance.activeGhostFor(GameMode.classic), isNull);
  });

  test('the old MY BEST default is migrated to OFF exactly once', () async {
    final SharedPreferences p = await _loadWith(<String, Object>{
      StorageService.kGhostSource: GhostSource.mine.name,
    });

    expect(StorageService.instance.ghostSource, GhostSource.off);
    expect(p.getString(StorageService.kGhostSource), GhostSource.off.name);
    expect(p.getBool(StorageService.kGhostOffMigration), isTrue);
  });

  test('a deliberate MY BEST chosen after migrating is kept', () async {
    await _loadWith(<String, Object>{
      StorageService.kGhostSource: GhostSource.mine.name,
      StorageService.kGhostOffMigration: true,
    });

    expect(StorageService.instance.ghostSource, GhostSource.mine);
  });

  test('migration leaves a deliberate FRIEND setting alone', () async {
    final String ghost = _tower(4).encode();
    await _loadWith(<String, Object>{
      StorageService.kGhostSource: GhostSource.friend.name,
      StorageService.kFriendGhost: ghost,
    });

    expect(StorageService.instance.ghostSource, GhostSource.friend);
  });

  test('removing the friend ghost falls back to OFF', () async {
    await _loadWith(<String, Object>{});
    StorageService.instance.importFriendGhost(_tower(4));
    expect(StorageService.instance.ghostSource, GhostSource.friend);

    StorageService.instance.removeFriendGhost();
    expect(StorageService.instance.ghostSource, GhostSource.off);
  });

  test('reset progress returns the ghost to OFF', () async {
    final SharedPreferences p = await _loadWith(<String, Object>{});
    StorageService.instance.setGhostSource(GhostSource.mine);
    expect(StorageService.instance.ghostSource, GhostSource.mine);

    StorageService.instance.resetProgress();
    await pumpEventQueue();
    expect(StorageService.instance.ghostSource, GhostSource.off);
    expect(p.getString(StorageService.kGhostSource), GhostSource.off.name);
  });
}
