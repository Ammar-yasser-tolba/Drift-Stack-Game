import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/navigation/app_nav.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'services/storage_service.dart';
import 'widgets/app_snackbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Rule 1.5-1: portrait locked, bars hidden (immersive sticky).
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Storage is loaded by S0 (Splash) so the logo animation can run meanwhile.
  runApp(const DriftStackApp());
}

class DriftStackApp extends StatefulWidget {
  const DriftStackApp({super.key});

  @override
  State<DriftStackApp> createState() => _DriftStackAppState();
}

class _DriftStackAppState extends State<DriftStackApp> with WidgetsBindingObserver {
  StreamSubscription<String>? _messageSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Rule 1.5-7: "Couldn't save progress." (the service emits it once per session).
    _messageSub = StorageService.instance.messages.listen(AppSnackbar.show);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // System bars can reappear after the app was in the background or a
    // keyboard was shown; hide them again.
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drift Stack',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNav.navigatorKey,
      scaffoldMessengerKey: AppNav.messengerKey,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      // Layout is fixed to the spec: ignore the system font scale.
      builder: (BuildContext context, Widget? child) {
        return MediaQuery.withNoTextScaling(
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }
}
