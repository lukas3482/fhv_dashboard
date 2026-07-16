import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _themeModeKey = 'settings_theme_mode';
  static const _notificationsEnabledKey = 'settings_notifications_enabled';
  static const _refreshIntervalKey = 'settings_refresh_interval_minutes';
  static const _targetEctsKey = 'settings_target_ects';

  static const defaultRefreshIntervalMinutes = 30;
  static const defaultTargetEcts = 180;

  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  final notificationsEnabled = ValueNotifier<bool>(true);
  final refreshIntervalMinutes = ValueNotifier<int>(
    defaultRefreshIntervalMinutes,
  );
  final targetEcts = ValueNotifier<int>(defaultTargetEcts);

  SharedPreferences? _prefs;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    final storedMode = prefs.getString(_themeModeKey);
    themeMode.value = ThemeMode.values.firstWhere(
      (m) => m.name == storedMode,
      orElse: () => ThemeMode.system,
    );

    notificationsEnabled.value =
        prefs.getBool(_notificationsEnabledKey) ?? true;
    refreshIntervalMinutes.value =
        prefs.getInt(_refreshIntervalKey) ?? defaultRefreshIntervalMinutes;
    targetEcts.value = prefs.getInt(_targetEctsKey) ?? defaultTargetEcts;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _prefs?.setString(_themeModeKey, mode.name);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabled.value = enabled;
    await _prefs?.setBool(_notificationsEnabledKey, enabled);
  }

  Future<void> setRefreshIntervalMinutes(int minutes) async {
    refreshIntervalMinutes.value = minutes;
    await _prefs?.setInt(_refreshIntervalKey, minutes);
  }

  Future<void> setTargetEcts(int ects) async {
    targetEcts.value = ects;
    await _prefs?.setInt(_targetEctsKey, ects);
  }
}
