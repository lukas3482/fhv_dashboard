import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/departure.dart';

class DepartureService {
  static const _endpoint = 'https://fahrplan.oebb.at/bin/mgate.exe';

  /// Dornbirn Sägerbrücke/Campus V — the stop next to the FHV campus.
  static const campusStationId = '893119';
  static const campusStationName = 'Sägerbrücke/Campus V';

  static const _busProductMask = 64;

  static const _requestBase = {
    'auth': {'type': 'AID', 'aid': 'OWDL4fE4ixNiPBBm'},
    'client': {
      'type': 'IPH',
      'id': 'OEBB',
      'v': '6030600',
      'name': 'oebbPROD-ADHOC',
    },
    'ver': '1.45',
    'lang': 'de',
  };

  static const _cacheMaxAge = Duration(minutes: 15);

  static final DepartureService _instance = DepartureService._internal();
  factory DepartureService() => _instance;
  DepartureService._internal();

  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  Future<List<Departure>> fetchDepartures({
    String stationId = campusStationId,
    int maxJourneys = 8,
    int durationMinutes = 90,
    Set<String> routeFilter = const {},
  }) async {
    final all = await _fetchBoard(
      stationId: stationId,
      start: DateTime.now(),
      maxJourneys: routeFilter.isEmpty ? maxJourneys : 80,
      durationMinutes: durationMinutes,
    );
    final result = all
        .where(
          (d) =>
              routeFilter.isEmpty || routeFilter.contains(BusRoute.of(d).key),
        )
        .take(maxJourneys)
        .toList();
    _cache = _CachedBoard(
      filterKey: _filterKey(routeFilter),
      departures: result,
      fetchedAt: DateTime.now(),
    );
    return result;
  }

  List<Departure>? cachedDepartures({Set<String> routeFilter = const {}}) {
    final cache = _cache;
    if (cache == null || cache.filterKey != _filterKey(routeFilter)) {
      return null;
    }
    final now = DateTime.now();
    if (now.difference(cache.fetchedAt) > _cacheMaxAge) return null;
    return cache.departures.where((d) => d.expectedTime.isAfter(now)).toList();
  }

  static String _filterKey(Set<String> filter) =>
      (filter.toList()..sort()).join(',');

  _CachedBoard? _cache;
  Future<List<BusRoute>> fetchRoutes({
    String stationId = campusStationId,
  }) async {
    var day = DateTime.now().add(const Duration(days: 1));
    while (day.weekday > 5) {
      day = day.add(const Duration(days: 1));
    }
    final departures = await _fetchBoard(
      stationId: stationId,
      start: DateTime(day.year, day.month, day.day, 6),
      maxJourneys: 300,
      durationMinutes: 16 * 60,
    );
    final routes = {for (final d in departures) BusRoute.of(d)}.toList()
      ..sort();
    return routes;
  }

  Future<List<Departure>> _fetchBoard({
    required String stationId,
    required DateTime start,
    required int maxJourneys,
    required int durationMinutes,
  }) async {
    final body = {
      ..._requestBase,
      'svcReqL': [
        {
          'meth': 'StationBoard',
          'req': {
            'type': 'DEP',
            'date': _fmtDate(start),
            'time': _fmtTime(start),
            'stbLoc': {'type': 'S', 'lid': 'A=1@L=$stationId@'},
            'maxJny': maxJourneys,
            'dur': durationMinutes,
            'jnyFltrL': [
              {'type': 'PROD', 'mode': 'INC', 'value': '$_busProductMask'},
            ],
          },
        },
      ],
    };

    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(_endpoint, data: body);
    } on DioException catch (e) {
      throw Exception(
        'Abfahrten konnten nicht geladen werden (${e.type.name}).',
      );
    }

    final data = response.data;
    if (data == null) throw Exception('Leere Antwort vom Fahrplanserver.');
    return parseResponse(data);
  }

  @visibleForTesting
  List<Departure> parseResponse(Map<String, dynamic> data) {
    if (data['err'] != null && data['err'] != 'OK') {
      throw Exception('Fahrplanserver meldet Fehler: ${data['err']}');
    }
    final svc = (data['svcResL'] as List?)?.firstOrNull as Map?;
    if (svc == null) throw Exception('Unerwartete Antwort vom Fahrplanserver.');
    if (svc['err'] != 'OK') {
      throw Exception('Fahrplanserver meldet Fehler: ${svc['err']}');
    }

    final res = svc['res'] as Map<String, dynamic>;
    final common = (res['common'] as Map<String, dynamic>?) ?? const {};
    final locations = (common['locL'] as List?) ?? const [];
    final products = (common['prodL'] as List?) ?? const [];
    final journeys = (res['jnyL'] as List?) ?? const [];

    final departures = <Departure>[];
    for (final raw in journeys) {
      final jny = raw as Map<String, dynamic>;
      final stop = jny['stbStop'] as Map<String, dynamic>?;
      final date = jny['date'] as String?;
      if (stop == null || date == null) continue;

      final tzOffset = (stop['dTZOffset'] as num?)?.toInt();
      final planned = _parseTime(date, stop['dTimeS'] as String?, tzOffset);
      if (planned == null) continue;
      final realtime = _parseTime(date, stop['dTimeR'] as String?, tzOffset);

      final product = _at(products, jny['prodX']);
      final productCtx = product?['prodCtx'] as Map?;
      final line =
          (productCtx?['line'] as String?) ??
          (product?['number'] as String?) ??
          (product?['name'] as String?) ??
          '?';

      final location = _at(locations, stop['locX']);
      final platform =
          (stop['dPltfR'] as Map?)?['txt'] ??
          (stop['dPltfS'] as Map?)?['txt'] ??
          stop['dPlatfR'] ??
          stop['dPlatfS'];

      departures.add(
        Departure(
          line: line.trim(),
          direction: (jny['dirTxt'] as String?)?.trim() ?? '?',
          plannedTime: planned,
          realtimeTime: realtime,
          cancelled: stop['dCncl'] == true || jny['isCncl'] == true,
          platform: platform as String?,
          stopName: location?['name'] as String?,
        ),
      );
    }

    departures.sort((a, b) => a.expectedTime.compareTo(b.expectedTime));
    return departures;
  }

  static Map? _at(List list, Object? index) {
    if (index is! int || index < 0 || index >= list.length) return null;
    return list[index] as Map?;
  }

  static DateTime? _parseTime(String date, String? time, int? tzOffsetMinutes) {
    if (time == null || time.length < 6 || date.length != 8) return null;
    final dayOffset = time.length > 6
        ? int.parse(time.substring(0, time.length - 6))
        : 0;
    final t = time.substring(time.length - 6);
    final y = int.parse(date.substring(0, 4));
    final mo = int.parse(date.substring(4, 6));
    final d = int.parse(date.substring(6, 8)) + dayOffset;
    final h = int.parse(t.substring(0, 2));
    final mi = int.parse(t.substring(2, 4));
    final s = int.parse(t.substring(4, 6));

    if (tzOffsetMinutes == null) return DateTime(y, mo, d, h, mi, s);
    return DateTime.utc(
      y,
      mo,
      d,
      h,
      mi,
      s,
    ).subtract(Duration(minutes: tzOffsetMinutes)).toLocal();
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}${_two(d.month)}${_two(d.day)}';

  static String _fmtTime(DateTime d) =>
      '${_two(d.hour)}${_two(d.minute)}${_two(d.second)}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}

class _CachedBoard {
  final String filterKey;
  final List<Departure> departures;
  final DateTime fetchedAt;

  const _CachedBoard({
    required this.filterKey,
    required this.departures,
    required this.fetchedAt,
  });
}
