import '../models/timetable_event.dart';
import 'auth_service.dart';

class TimetableService {
  static const _url =
      'https://a5.fhv.at/ajax/122/EventPlanerSite/EventDateSiteJsonPage';

  static final TimetableService _instance = TimetableService._internal();
  factory TimetableService() => _instance;
  TimetableService._internal();

  Future<Map<DateTime, List<TimetableEvent>>> fetchWeek(DateTime monday) async {
    final sunday = monday.add(const Duration(days: 6));

    final response = await AuthService().dio.get(
      _url,
      queryParameters: {'from': _fmt(monday), 'to': _fmt(sunday)},
    );

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
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
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
