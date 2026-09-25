import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'presentation/providers/core_providers.dart';
import 'presentation/screens/auth/auth_gate.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  ConnectivityService.instance.init();

  final prefs = await SharedPreferences.getInstance();

  // Asks for the notification permission on Android 13+. Not awaited:
  // a worker should never wait on a permission dialog to reach the
  // login screen, and a refusal only means no confirmations. Prefs are
  // passed so the record of what has already been announced survives a
  // restart and nothing announces itself twice.
  NotificationService.instance.init(prefs);

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const SalamaApp(),
    ),
  );
}

class SalamaApp extends StatelessWidget {
  const SalamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      routes: {
        AppConstants.routeLogin: (_) => const LoginScreen(),
        AppConstants.routeHome: (_) => const HomeScreen(),
      },
    );
  }
}
