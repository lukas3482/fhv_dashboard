import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().load();
  runApp(const FhvDashboardApp());
}

class FhvDashboardApp extends StatelessWidget {
  const FhvDashboardApp({super.key});

  static const _seedColor = Color(0xFF2E7D32);

  static final _navigationBarTheme = NavigationBarThemeData(
    labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService().themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'FHV Dashboard',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
            useMaterial3: true,
            navigationBarTheme: _navigationBarTheme,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _seedColor,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            navigationBarTheme: _navigationBarTheme,
          ),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
