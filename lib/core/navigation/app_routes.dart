import 'package:flutter/material.dart';

/// Rule 1.5-5: push = slide from the right 250 ms (pop = reverse),
/// S0 → S1 = fade 400 ms, S3 → S5 = fade 300 ms.
class AppRoutes {
  AppRoutes._();

  static Route<T> slide<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      opaque: true,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (BuildContext c, Animation<double> a, Animation<double> s) => page,
      transitionsBuilder: (BuildContext c, Animation<double> a, Animation<double> s, Widget child) {
        final Animation<Offset> offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: a,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ));
        return SlideTransition(position: offset, child: child);
      },
    );
  }

  static Route<T> fade<T>(Widget page, {int milliseconds = 300, RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      opaque: true,
      transitionDuration: Duration(milliseconds: milliseconds),
      reverseTransitionDuration: Duration(milliseconds: milliseconds),
      pageBuilder: (BuildContext c, Animation<double> a, Animation<double> s) => page,
      transitionsBuilder: (BuildContext c, Animation<double> a, Animation<double> s, Widget child) =>
          FadeTransition(opacity: a, child: child),
    );
  }

  /// S0 → S1 or S0 → S2 (400 ms fade).
  static Route<T> splashExit<T>(Widget page) => fade<T>(page, milliseconds: 400);

  /// S3 → S5 (300 ms fade).
  static Route<T> gameOver<T>(Widget page) => fade<T>(page, milliseconds: 300);
}
