import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/timetable_event.dart';
import 'auth_service.dart';

class TimetableService {
  static const _url =
      'https://a5.fhv.at/ajax/122/EventPlanerSite/EventDateSiteJsonPage';
  static const _resetSelectionUrl =
      'https://a5.fhv.at/ajax/122/EventPlanerSite/SessionSaveJsonPage';
  static const _cacheFileName = 'timetable_cache.json';
  static const _nextEventCacheFileName = 'next_event_cache.json';
  static const _maxCachedWeeks = 8;

  static final TimetableService _instance = TimetableService._internal();
  factory TimetableService() => _instance;
  TimetableService._internal();

  Future<File> get _cacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<File> get _nextEventCacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_nextEventCacheFileName');
  }

  Future<TimetableEvent?> loadCachedNextEvent() async {
    try {
      final file = await _nextEventCacheFile;
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      if (json == null) return null;
      return TimetableEvent.fromCacheJson(json as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveNextEventCache(TimetableEvent? event) async {
    try {
      final file = await _nextEventCacheFile;
      await file.writeAsString(jsonEncode(event?.toCacheJson()));
    } catch (_) {}
  }

  Future<Map<DateTime, List<TimetableEvent>>?> loadCachedWeek(
    DateTime monday,
  ) async {
    try {
      final file = await _cacheFile;
      if (!await file.exists()) return null;
      final all = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final list = all[_fmt(monday)] as List?;
      if (list == null) return null;
      final events = list
          .cast<Map<String, dynamic>>()
          .map(TimetableEvent.fromCacheJson)
          .toList();
      return _groupByDay(events);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCacheWeek(
    DateTime monday,
    Map<DateTime, List<TimetableEvent>> grouped,
  ) async {
    try {
      final file = await _cacheFile;
      var all = <String, dynamic>{};
      if (await file.exists()) {
        try {
          all = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        } catch (_) {}
      }

      final events = grouped.values.expand((e) => e).toList();
      all[_fmt(monday)] = events.map((e) => e.toCacheJson()).toList();

      if (all.length > _maxCachedWeeks) {
        final oldestFirst = all.keys.toList()..sort();
        for (final key in oldestFirst.take(all.length - _maxCachedWeeks)) {
          all.remove(key);
        }
      }

      await file.writeAsString(jsonEncode(all));
    } catch (_) {}
  }

  Future<Map<DateTime, List<TimetableEvent>>> fetchWeek(DateTime monday) async {
    await _ensurePersonalSchedule();
    final sunday = monday.add(const Duration(days: 6));
    final result = await _fetchRange(monday, sunday);
    await _saveCacheWeek(monday, result);
    return result;
  }

  Future<void> _ensurePersonalSchedule() async {
    await AuthService().authenticatedGet('$_resetSelectionUrl?roomIds=');
  }

  Future<Map<DateTime, List<TimetableEvent>>> _fetchRange(
    DateTime from,
    DateTime to,
  ) async {
    final uri = Uri.parse(
      _url,
    ).replace(queryParameters: {'from': _fmt(from), 'to': _fmt(to)});
    final response = await AuthService().authenticatedGet(uri.toString());

    if (response.statusCode == 302) throw Exception('Session abgelaufen.');
    if (response.statusCode != 200) {
      throw Exception(
        'Fehler beim Laden des Stundenplans (${response.statusCode})',
      );
    }

    final body = response.data;
    if (body is List) return {};

    final raw = (body['data'] as List? ?? []).cast<Map<String, dynamic>>();

    final events = _mergeBySlot(raw);
    return _groupByDay(events);
  }

  List<TimetableEvent> _mergeBySlot(List<Map<String, dynamic>> raw) {
    final map = <String, Map<String, dynamic>>{};
    final extraParts = <String, List<String>>{};

    for (final json in raw) {
      final key =
          '${json['event_name']}_${json['start_date']}_${json['end_date']}';
      if (!map.containsKey(key)) {
        map[key] = json;
        extraParts[key] = [];
      } else {
        final part = (json['exam_part'] as String? ?? '').trim();
        if (part.isNotEmpty) extraParts[key]!.add(part);
      }
    }

    return map.entries
        .map(
          (e) => TimetableEvent.fromJson(
            e.value,
            extraExamParts: extraParts[e.key]!,
          ),
        )
        .where((e) => !e.isHoliday)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  Future<TimetableEvent?> fetchNextEvent() async {
    await _ensurePersonalSchedule();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    const windowSizesDays = [7, 23, 60, 90, 180, 60];
    var searchStart = today;

    for (final windowDays in windowSizesDays) {
      final searchEnd = searchStart.add(Duration(days: windowDays));
      final events = await _fetchRange(searchStart, searchEnd);
      final upcoming = _firstUpcoming(events, now);
      if (upcoming != null) {
        await _saveNextEventCache(upcoming);
        return upcoming;
      }
      searchStart = searchEnd.add(const Duration(days: 1));
    }

    await _saveNextEventCache(null);
    return null;
  }

  TimetableEvent? _firstUpcoming(
    Map<DateTime, List<TimetableEvent>> grouped,
    DateTime now,
  ) {
    final all =
        grouped.values
            .expand((events) => events)
            .where((e) => e.endDate.isAfter(now))
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return all.isEmpty ? null : all.first;
  }

  Map<DateTime, List<TimetableEvent>> _groupByDay(List<TimetableEvent> events) {
    final result = <DateTime, List<TimetableEvent>>{};
    for (final event in events) {
      final day = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      result.putIfAbsent(day, () => []).add(event);
    }
    return result;
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
