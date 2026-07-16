import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/grade.dart';

class NotificationService {
  static const _channelId = 'grades_channel';
  static const _channelName = 'Notenänderungen';
  static const _channelDescription =
      'Benachrichtigungen über neue oder geänderte Noten';

  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> showGradeChanges(List<GradeChange> changes) async {
    if (changes.isEmpty) return;
    await init();

    final lines = changes.map((c) {
      final label = c.isNew ? 'Neu' : 'Aktualisiert';
      final noteChange = c.isNew || c.oldNote == null
          ? c.newNote
          : '${c.oldNote} → ${c.newNote}';
      return '$label: ${c.modul} ($noteChange)';
    }).toList();

    final title = changes.length == 1
        ? (changes.first.isNew ? 'Neue Note' : 'Note aktualisiert')
        : '${changes.length} Notenänderungen';
    final body = lines.join('\n');

    await _plugin.show(
      0,
      title,
      changes.length == 1 ? body : '${changes.length} Module betroffen',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
