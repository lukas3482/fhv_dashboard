import 'package:fhv_dashboard/models/departure.dart';
import 'package:fhv_dashboard/services/departure_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Trimmed real StationBoard response for 893119 (Dornbirn Sägerbrücke/Campus V).
final _sampleResponse = <String, dynamic>{
  'ver': '1.45',
  'err': 'OK',
  'svcResL': [
    {
      'meth': 'StationBoard',
      'err': 'OK',
      'res': {
        'common': {
          'locL': [
            {'name': 'Dornbirn Sägerbrücke/Campus V', 'extId': '893119'},
            {'name': 'Dornbirn Krankenhaus', 'extId': '893130'},
          ],
          'prodL': [
            {
              'name': 'Bus 130',
              'number': '130',
              'prodCtx': {'name': 'Bus 130 ', 'line': '130'},
            },
            {
              'name': 'Bus 206',
              'number': '206',
              'prodCtx': {'name': 'Bus 206 ', 'line': '206'},
            },
          ],
        },
        'jnyL': [
          {
            'date': '20261012',
            'prodX': 0,
            'dirTxt': 'Götzis Bf',
            'stbStop': {
              'locX': 0,
              'dTimeS': '180400',
              'dTimeR': '184200',
              'dTZOffset': 120,
            },
          },
          {
            'date': '20261012',
            'prodX': 1,
            'dirTxt': 'Messeplatz',
            'stbStop': {'locX': 1, 'dTimeS': '181000', 'dTZOffset': 120},
          },
          {
            'date': '20261012',
            'prodX': 0,
            'dirTxt': 'Dornbirn Bf',
            'stbStop': {
              'locX': 0,
              'dTimeS': '01001500',
              'dCncl': true,
              'dTZOffset': 120,
            },
          },
        ],
      },
    },
  ],
};

void main() {
  test('parses StationBoard response sorted by expected time', () {
    final deps = DepartureService().parseResponse(_sampleResponse);
    expect(deps, hasLength(3));

    // 18:10 (schedule only) comes before 18:04 delayed to 18:42.
    expect(deps[0].line, '206');
    expect(deps[0].hasRealtime, isFalse);
    expect(deps[0].stopName, 'Dornbirn Krankenhaus');
    expect(deps[0].plannedTime.toUtc(), DateTime.utc(2026, 10, 12, 16, 10));

    expect(deps[1].line, '130');
    expect(deps[1].direction, 'Götzis Bf');
    expect(deps[1].delayMinutes, 38);

    // "DDHHMMSS" day-offset format → next day 00:15 local.
    expect(deps[2].cancelled, isTrue);
    expect(deps[2].plannedTime.toUtc(), DateTime.utc(2026, 10, 12, 22, 15));
  });

  test('throws on HAFAS error', () {
    expect(
      () => DepartureService().parseResponse({
        'err': 'OK',
        'svcResL': [
          {'meth': 'StationBoard', 'err': 'LOCATION'},
        ],
      }),
      throwsException,
    );
  });

  test('BusRoute sorts numeric lines numerically and round-trips keys', () {
    final routes = [
      const BusRoute(line: 'SK', direction: 'Schulkurs 23'),
      const BusRoute(line: '210', direction: 'Messeplatz'),
      const BusRoute(line: '177', direction: 'Ebnit Heumöser'),
      const BusRoute(line: '177', direction: 'Dornbirn Bf'),
    ]..sort();
    expect(routes.map((r) => r.key), [
      '177|Dornbirn Bf',
      '177|Ebnit Heumöser',
      '210|Messeplatz',
      'SK|Schulkurs 23',
    ]);
    expect(BusRoute.fromKey('177|Dornbirn Bf'), routes.first);
  });
}
