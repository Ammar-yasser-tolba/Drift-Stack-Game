import 'package:flutter/material.dart';

import '../../models/game_mode.dart';
import '../../models/run_result.dart';
import '../../screens/game/game_screen.dart';
import '../../screens/game_over/game_over_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/how_to_play/how_to_play_screen.dart';
import '../../screens/import_ghost/import_ghost_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/skins/skins_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/unknown_screen.dart';

/// How a screen enters (Rule 1.5-5).
enum RouteTransition { slide, fade400, fade300, none }

/// Arguments for every named route: the transition plus screen data
/// (e.g. `true` = first-run mode for How To Play).
class RouteArgs {
  const RouteArgs({this.transition = RouteTransition.slide, this.data});

  final RouteTransition transition;
  final Object? data;
}

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String home = '/home';
  static const String howToPlay = '/how-to-play';
  static const String game = '/game';
  static const String gameOver = '/game-over';
  static const String skins = '/skins';
  static const String settings = '/settings';
  static const String importGhost = '/import-ghost';

  static Widget? _pageFor(RouteSettings s, RouteArgs args) {
    switch (s.name) {
      case splash:
        return const SplashScreen();
      case home:
        return const HomeScreen();
      case howToPlay:
        return HowToPlayScreen(firstRun: args.data == true);
      case game:
        return GameScreen(
          mode: args.data is GameMode ? args.data! as GameMode : GameMode.classic,
        );
      case gameOver:
        return args.data is RunResult
            ? GameOverScreen(result: args.data! as RunResult)
            : null;
      case skins:
        return const SkinsScreen();
      case settings:
        return const SettingsScreen();
      case importGhost:
        return const ImportGhostScreen();
      // Each new screen is added here as it is built.
      default:
        return null;
    }
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Object? a = settings.arguments;
    final RouteArgs args = a is RouteArgs ? a : const RouteArgs();
    final Widget? page = _pageFor(settings, args);
    if (page == null) return null;
    final RouteTransition t = settings.name == splash ? RouteTransition.none : args.transition;

    switch (t) {
      case RouteTransition.none:
        return PageRouteBuilder<dynamic>(
          settings: settings,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (BuildContext c, Animation<double> a, Animation<double> s) => page,
        );
      case RouteTransition.fade400:
        return _fade(settings, page, 400);
      case RouteTransition.fade300:
        return _fade(settings, page, 300);
      case RouteTransition.slide:
        return PageRouteBuilder<dynamic>(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (BuildContext c, Animation<double> a, Animation<double> s) => page,
          transitionsBuilder:
              (BuildContext c, Animation<double> a, Animation<double> s, Widget child) {
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic),
              ),
              child: child,
            );
          },
        );
    }
  }

  static Route<dynamic> _fade(RouteSettings settings, Widget page, int ms) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: Duration(milliseconds: ms),
      reverseTransitionDuration: Duration(milliseconds: ms),
      pageBuilder: (BuildContext c, Animation<double> a, Animation<double> s) => page,
      transitionsBuilder: (BuildContext c, Animation<double> a, Animation<double> s, Widget child) =>
          FadeTransition(opacity: a, child: child),
    );
  }

  /// Safety net for a route name that has no screen registered.
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return _fade(settings, UnknownScreen(routeName: settings.name ?? ''), 200);
  }
}
