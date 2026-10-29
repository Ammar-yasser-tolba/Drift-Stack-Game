import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift_stack/core/navigation/app_router.dart';
import 'package:drift_stack/models/game_mode.dart';
import 'package:drift_stack/models/ghost.dart';
import 'package:drift_stack/models/run_result.dart';

void main() {
  test('registered routes resolve', () {
    for (final String name in <String>[
      AppRouter.splash,
      AppRouter.home,
      AppRouter.howToPlay,
      AppRouter.game,
    ]) {
      expect(
        AppRouter.onGenerateRoute(RouteSettings(name: name)),
        isNotNull,
        reason: name,
      );
    }
  });

  test('menu screens resolve', () {
    for (final String name in <String>[
      AppRouter.skins,
      AppRouter.settings,
      AppRouter.importGhost,
    ]) {
      expect(
        AppRouter.onGenerateRoute(RouteSettings(name: name)),
        isNotNull,
        reason: name,
      );
    }
  });

  test('game route accepts a mode argument', () {
    final Route<dynamic>? route = AppRouter.onGenerateRoute(
      const RouteSettings(
        name: AppRouter.game,
        arguments: RouteArgs(data: GameMode.daily),
      ),
    );
    expect(route, isNotNull);
  });

  test('game-over resolves only with a result', () {
    expect(
      AppRouter.onGenerateRoute(const RouteSettings(name: AppRouter.gameOver)),
      isNull,
    );
    final Route<dynamic>? route = AppRouter.onGenerateRoute(
      const RouteSettings(
        name: AppRouter.gameOver,
        arguments: RouteArgs(
          data: RunResult(
            mode: GameMode.classic,
            score: 1,
            perfects: 0,
            maxCombo: 0,
            ghost: Ghost(
              score: 1,
              seed: 1,
              floors: <GhostFloor>[GhostFloor(0.2, 0.6), GhostFloor(0.25, 0.5)],
            ),
          ),
        ),
      ),
    );
    expect(route, isNotNull);
  });

  test('unknown routes fall through to the safety net', () {
    expect(
      AppRouter.onGenerateRoute(const RouteSettings(name: '/does-not-exist')),
      isNull,
    );
    expect(
      AppRouter.onUnknownRoute(const RouteSettings(name: '/does-not-exist')),
      isNotNull,
    );
  });

  test('route transitions follow rule 1.5-5', () {
    final TransitionRoute<dynamic> splash = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRouter.splash))! as TransitionRoute<dynamic>;
    expect(splash.transitionDuration, Duration.zero);

    final TransitionRoute<dynamic> game = AppRouter.onGenerateRoute(
      const RouteSettings(
        name: AppRouter.game,
        arguments: RouteArgs(transition: RouteTransition.fade300),
      ),
    )! as TransitionRoute<dynamic>;
    expect(game.transitionDuration, const Duration(milliseconds: 300));

    final TransitionRoute<dynamic> slide = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRouter.howToPlay),
    )! as TransitionRoute<dynamic>;
    expect(slide.transitionDuration, const Duration(milliseconds: 250));
  });
}
