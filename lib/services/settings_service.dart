import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_card.dart';

enum StundenplanViewMode { list, grid }

class SettingsService {
  static const _themeModeKey = 'settings_theme_mode';
  static const _notificationsEnabledKey = 'settings_notifications_enabled';
  static const _refreshIntervalKey = 'settings_refresh_interval_minutes';
  static const _targetEctsKey = 'settings_target_ects';
  static const _dashboardCardsKey = 'settings_dashboard_cards';
  static const _stundenplanViewModeKey = 'settings_stundenplan_view_mode';

  static const defaultRefreshIntervalMinutes = 30;
  static const defaultTargetEcts = 180;
  static const defaultDashboardCards = [
    DashboardCardType.nextEvent,
    DashboardCardType.ectsProgress,
    DashboardCardType.profile,
    DashboardCardType.platforms,
  ];

  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  final notificationsEnabled = ValueNotifier<bool>(true);
  final refreshIntervalMinutes = ValueNotifier<int>(
    defaultRefreshIntervalMinutes,
  );
  final targetEcts = ValueNotifier<int>(defaultTargetEcts);
  final dashboardCards = ValueNotifier<List<DashboardCardConfig>>([
    for (final type in defaultDashboardCards)
      DashboardCardConfig(type: type, visible: true),
  ]);
  final stundenplanViewMode = ValueNotifier<StundenplanViewMode>(
    StundenplanViewMode.list,
  );

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

    final storedCards = prefs.getStringList(_dashboardCardsKey);
    if (storedCards != null) {
      dashboardCards.value = _decodeDashboardCards(storedCards);
    }

    final storedViewMode = prefs.getString(_stundenplanViewModeKey);
    stundenplanViewMode.value = StundenplanViewMode.values.firstWhere(
      (m) => m.name == storedViewMode,
      orElse: () => StundenplanViewMode.list,
    );
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

  Future<void> setDashboardCards(List<DashboardCardConfig> cards) async {
    dashboardCards.value = cards;
    await _prefs?.setStringList(
      _dashboardCardsKey,
      _encodeDashboardCards(cards),
    );
  }

  Future<void> setStundenplanViewMode(StundenplanViewMode mode) async {
    stundenplanViewMode.value = mode;
    await _prefs?.setString(_stundenplanViewModeKey, mode.name);
  }

  List<String> _encodeDashboardCards(List<DashboardCardConfig> cards) =>
      cards.map((c) => '${c.type.name}:${c.visible ? '1' : '0'}').toList();

  List<DashboardCardConfig> _decodeDashboardCards(List<String> raw) {
    final result = <DashboardCardConfig>[];
    final seen = <DashboardCardType>{};

    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length != 2) continue;
      try {
        final type = DashboardCardType.values.byName(parts[0]);
        result.add(DashboardCardConfig(type: type, visible: parts[1] == '1'));
        seen.add(type);
      } catch (_) {
        // Unknown card id —> skip.
      }
    }

    for (final type in DashboardCardType.values) {
      if (!seen.contains(type)) {
        result.add(DashboardCardConfig(type: type, visible: true));
      }
    }

    return result;
  }
}
