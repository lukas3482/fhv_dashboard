import '../models/room_availability.dart';
import '../models/timetable_event.dart';
import 'auth_service.dart';

class RoomInfo {
  final int id;
  final String name;
  const RoomInfo(this.id, this.name);
}

const kUBuildingRooms = [
  RoomInfo(38, 'U126 Projektraum E'),
  RoomInfo(39, 'U130 eLab'),
  RoomInfo(40, 'Lab. auton. Systeme'),
  RoomInfo(41, 'U204'),
  RoomInfo(42, 'U205'),
  RoomInfo(43, 'U206'),
  RoomInfo(44, 'U207'),
  RoomInfo(45, 'U210'),
  RoomInfo(46, 'U212'),
  RoomInfo(47, 'U214'),
  RoomInfo(48, 'U215'),
  RoomInfo(297, 'U216'),
  RoomInfo(49, 'U225'),
  RoomInfo(50, 'U226'),
  RoomInfo(51, 'U227'),
  RoomInfo(52, 'U304'),
  RoomInfo(53, 'U305'),
  RoomInfo(4, 'U306'),
  RoomInfo(55, 'U307'),
  RoomInfo(56, 'U310'),
  RoomInfo(57, 'U311'),
  RoomInfo(58, 'U312'),
  RoomInfo(59, 'U313'),
  RoomInfo(60, 'U314'),
  RoomInfo(61, 'U315'),
  RoomInfo(82, 'U325 DesignThinkingLab'),
  RoomInfo(63, 'U326 nw-lab'),
  RoomInfo(64, 'U327 db-lab'),
  RoomInfo(65, 'U328 se-lab'),
  RoomInfo(66, 'U329 cad-lab2'),
  RoomInfo(67, 'U330'),
  RoomInfo(68, 'U404'),
  RoomInfo(69, 'U405'),
  RoomInfo(70, 'U406'),
  RoomInfo(71, 'U407'),
  RoomInfo(72, 'U410'),
  RoomInfo(73, 'U411'),
  RoomInfo(74, 'U412'),
  RoomInfo(75, 'U413'),
  RoomInfo(76, 'U414'),
  RoomInfo(77, 'U415'),
  RoomInfo(78, 'U425 PC-Pool'),
  RoomInfo(79, 'U426 PC-Pool'),
  RoomInfo(80, 'U427 3D/CAD Lab/PC-Pool'),
  RoomInfo(81, 'U428'),
  RoomInfo(62, 'U429 PC-Pool'),
  RoomInfo(83, 'U430 PC-Pool'),
];

class RoomSearchService {
  static const _selectUrl =
      'https://a5.fhv.at/ajax/122/EventPlanerSite/SessionSaveJsonPage';
  static const _scheduleUrl =
      'https://a5.fhv.at/ajax/122/EventPlanerSite/EventDateSiteJsonPage';

  static final RoomSearchService _instance = RoomSearchService._internal();
  factory RoomSearchService() => _instance;
  RoomSearchService._internal();

  Future<List<RoomAvailability>> findFreeRooms({
    required DateTime date,
    required int hoursToCheck,
  }) async {
    final roomIds = kUBuildingRooms.map((r) => r.id).join(',');
    final selectUri = Uri.parse(
      _selectUrl,
    ).replace(queryParameters: {'roomIds': roomIds});
    final selectResponse = await AuthService().authenticatedGet(
      selectUri.toString(),
    );
    if (selectResponse.statusCode != 200) {
      throw Exception(
        'Raumauswahl fehlgeschlagen (${selectResponse.statusCode}).',
      );
    }

    final dateStr = _fmt(date);
    final scheduleUri = Uri.parse(
      _scheduleUrl,
    ).replace(queryParameters: {'from': dateStr, 'to': dateStr});
    final scheduleResponse = await AuthService().authenticatedGet(
      scheduleUri.toString(),
    );
    if (scheduleResponse.statusCode != 200) {
      throw Exception(
        'Belegungsplan konnte nicht geladen werden '
        '(${scheduleResponse.statusCode}).',
      );
    }

    final body = scheduleResponse.data;
    final rawEvents = body is Map
        ? (body['data'] as List? ?? const [])
        : const [];

    final roomEvents = <int, List<(DateTime, DateTime)>>{};
    for (final raw in rawEvents.cast<Map<String, dynamic>>()) {
      final startStr = raw['start_date'] as String?;
      final endStr = raw['end_date'] as String?;
      final roomIdsStr = raw['roomIds'] as String?;
      if (startStr == null || endStr == null) continue;
      if (roomIdsStr == null || roomIdsStr.isEmpty) continue;

      final start = DateTime.parse(startStr);
      final end = DateTime.parse(endStr);
      for (final idPart in roomIdsStr.split(',')) {
        final id = int.tryParse(idPart.trim());
        if (id == null) continue;
        (roomEvents[id] ??= []).add((start, end));
      }
    }

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final reference = isToday ? now : DateTime(date.year, date.month, date.day);

    final results = <RoomAvailability>[];
    for (final room in kUBuildingRooms) {
      final intervals = List.of(
        roomEvents[room.id] ?? const <(DateTime, DateTime)>[],
      )..sort((a, b) => a.$1.compareTo(b.$1));

      final busyNow = intervals.any(
        (i) => !i.$1.isAfter(reference) && i.$2.isAfter(reference),
      );
      if (busyNow) continue;

      DateTime? nextStart;
      for (final interval in intervals) {
        if (interval.$1.isAfter(reference)) {
          nextStart = interval.$1;
          break;
        }
      }

      results.add(
        RoomAvailability(
          name: room.name,
          freeFor: nextStart?.difference(reference),
          busyAgainAt: nextStart,
        ),
      );
    }

    results.sort((a, b) {
      if (a.freeFor == null && b.freeFor == null) return 0;
      if (a.freeFor == null) return -1;
      if (b.freeFor == null) return 1;
      return b.freeFor!.compareTo(a.freeFor!);
    });

    return results;
  }

  Future<List<TimetableEvent>> fetchRoomSchedule({
    required RoomInfo room,
    required DateTime date,
  }) async {
    final selectUri = Uri.parse(
      _selectUrl,
    ).replace(queryParameters: {'roomIds': '${room.id}'});
    final selectResponse = await AuthService().authenticatedGet(
      selectUri.toString(),
    );
    if (selectResponse.statusCode != 200) {
      throw Exception(
        'Raumauswahl fehlgeschlagen (${selectResponse.statusCode}).',
      );
    }

    final dateStr = _fmt(date);
    final scheduleUri = Uri.parse(
      _scheduleUrl,
    ).replace(queryParameters: {'from': dateStr, 'to': dateStr});
    final scheduleResponse = await AuthService().authenticatedGet(
      scheduleUri.toString(),
    );
    if (scheduleResponse.statusCode != 200) {
      throw Exception(
        'Belegungsplan konnte nicht geladen werden '
        '(${scheduleResponse.statusCode}).',
      );
    }

    final body = scheduleResponse.data;
    final rawEvents = body is Map
        ? (body['data'] as List? ?? const [])
        : const [];

    final map = <String, Map<String, dynamic>>{};
    final extraParts = <String, List<String>>{};
    for (final raw in rawEvents.cast<Map<String, dynamic>>()) {
      final key =
          '${raw['event_subject']}_${raw['start_date']}_${raw['end_date']}';
      if (!map.containsKey(key)) {
        map[key] = raw;
        extraParts[key] = [];
      } else {
        final part = (raw['exam_part'] as String? ?? '').trim();
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

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
