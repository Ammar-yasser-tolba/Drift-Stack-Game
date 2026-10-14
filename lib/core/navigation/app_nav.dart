import 'package:flutter/material.dart';

/// Global keys so services can show snackbars / navigate without a context.
class AppNav {
  AppNav._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();
}
