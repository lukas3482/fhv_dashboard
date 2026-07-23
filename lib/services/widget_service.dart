import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/timetable_event.dart';
import '../utils/event_time_format.dart';

class WidgetService {
  static const _androidProviderName = 'NextEventWidgetProvider';

  static const _keyHasEvent = 'next_event_has_event';
  static const _keyHeader = 'next_event_header';
  static const _keyTitle = 'next_event_title';
  static const _keyTime = 'next_event_time';
  static const _keyRoom = 'next_event_room';
  static const _keyColor = 'next_event_color';

  static Future<void> updateNextEvent(TimetableEvent? event) async {
    try {
      await HomeWidget.saveWidgetData<bool>(_keyHasEvent, event != null);
      if (event != null) {
        await HomeWidget.saveWidgetData<String>(_keyHeader, _header(event));
        await HomeWidget.saveWidgetData<String>(_keyTitle, event.eventName);
        await HomeWidget.saveWidgetData<String>(
          _keyTime,
          '${EventTimeFormat.time(event.startDate)} – ${EventTimeFormat.time(event.endDate)}',
        );
        await HomeWidget.saveWidgetData<String>(_keyRoom, event.rooms);
        await HomeWidget.saveWidgetData<int>(
          _keyColor,
          _toAndroidColorInt(event.color.toARGB32()),
        );
      }
      await HomeWidget.updateWidget(androidName: _androidProviderName);
    } catch (e) {
      debugPrint('[WidgetService] failed to update widget: $e');
    }
  }

  static String _header(TimetableEvent event) {
    final now = DateTime.now();
    final isOngoing =
        now.isAfter(event.startDate) && now.isBefore(event.endDate);
    if (isOngoing) return 'Läuft gerade';
    return 'Nächste Veranstaltung — ${EventTimeFormat.relativeDay(event.startDate)}';
  }

  static int _toAndroidColorInt(int argb32) =>
      argb32 >= 0x80000000 ? argb32 - 0x100000000 : argb32;
}
