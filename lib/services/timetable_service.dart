import '../models/timetable_event.dart';
import 'auth_service.dart';

class TimetableService {
  static const _url =
      'https://a5.fhv.at/ajax/122/EventPlanerSite/EventDateSiteJsonPage';
  static const _resetSelectionUrl =
      'https://a5.fhv.at/ajax/122/EventPlanerSite/SessionSaveJsonPage';

  static final TimetableService _instance = TimetableService._internal();
  factory TimetableService() => _instance;
  TimetableService._internal();

  Future<Map<DateTime, List<TimetableEvent>>> fetchWeek(DateTime monday) async {
    await _ensurePersonalSchedule();
    final sunday = monday.add(const Duration(days: 6));
    return _fetchRange(monday, sunday);
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
      if (upcoming != null) return upcoming;
      searchStart = searchEnd.add(const Duration(days: 1));
    }

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
