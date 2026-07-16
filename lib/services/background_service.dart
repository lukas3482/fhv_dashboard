import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'auth_service.dart';
import 'grades_service.dart';

const gradesRefreshTaskName = 'gradesRefreshTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != gradesRefreshTaskName) return true;

    debugPrint(
      '[BackgroundService] $gradesRefreshTaskName started at ${DateTime.now()}',
    );

    try {
      final auth = AuthService();
      await auth.init();
      if (!await auth.hasCredentials()) {
        debugPrint('[BackgroundService] no stored credentials, skipping');
        return true;
      }

      await GradesService().fetchGradesDetailed();
      debugPrint(
        '[BackgroundService] $gradesRefreshTaskName finished at ${DateTime.now()}',
      );
    } catch (e) {
      debugPrint('[BackgroundService] $gradesRefreshTaskName failed: $e');
    }

    return true;
  });
}

class BackgroundService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      gradesRefreshTaskName,
      gradesRefreshTaskName,
      frequency: const Duration(minutes: 60),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  static Future<void> cancel() async {
    _initialized = false;
    await Workmanager().cancelAll();
  }
}
