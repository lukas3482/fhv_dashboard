import 'package:html/parser.dart' as html_parser;

import '../models/grade.dart';
import 'auth_service.dart';

class GradesService {
  static const _notenUrl = 'https://a5.fhv.at/de/noten.php';

  static final GradesService _instance = GradesService._internal();
  factory GradesService() => _instance;
  GradesService._internal();

  Future<GradesResult> fetchGrades() async {
    final response = await AuthService().dio.get(_notenUrl);

    if (response.statusCode != 200) {
      throw Exception(
        'Notenseite konnte nicht geladen werden (${response.statusCode})',
      );
    }

    return _parseHtml(response.data.toString());
  }

  GradesResult _parseHtml(String html) {
    final document = html_parser.parse(html);

    final creditsRaw =
        document.querySelector('#span-possible-credits')?.text.trim() ?? '';
    final creditsParts = creditsRaw.split('/');
    final earned = int.tryParse(creditsParts.first.trim()) ?? 0;
    final total = creditsParts.length > 1
        ? int.tryParse(creditsParts[1].trim())
        : null;

    final avgRaw =
        document.querySelector('#span-average-grade-points')?.text.trim() ?? '';
    final avg = double.tryParse(avgRaw.replaceAll(',', '.'));

    final tables = document
        .querySelectorAll('table.table.table-bordered.table-update')
        .where((t) => !t.classes.contains('pruefungsergebnisse__legend'))
        .toList();

    const keys = [
      'modul',
      'status',
      'note',
      'bewertung',
      'teilbewertung',
      'credits',
      'versuch',
      'datum',
      'semester',
      'durchschnitt',
      'anerkennung',
    ];

    final partialPattern = RegExp(r'^\((\d+%)\)\s*(.*)$');

    final grades = <Grade>[];
    final seen = <String>{};

    for (final table in tables) {
      final tbody = table.querySelector('tbody');
      if (tbody == null) continue;

      Map<String, String>? pendingMain;
      var pendingPartials = <PartialGrade>[];

      void flushPending() {
        final main = pendingMain;
        if (main == null) return;
        final modul = main['modul'] ?? '';
        if (modul.isNotEmpty && seen.add(modul)) {
          final rawBewertung = main['bewertung'] ?? '';
          final rawTeilbewertung = main['teilbewertung'] ?? '';
          final effectiveBewertung = rawBewertung.isNotEmpty
              ? rawBewertung
              : rawTeilbewertung;
          grades.add(
            Grade(
              modul: modul,
              status: main['status'] ?? '',
              note: main['note'] ?? '',
              bewertung: effectiveBewertung.replaceAll('Bewertung folgt', '-'),
              teilbewertung: rawTeilbewertung,
              credits: main['credits'] ?? '',
              versuch: main['versuch'] ?? '',
              datum: main['datum'] ?? '',
              semester: main['semester'] ?? '',
              durchschnitt: main['durchschnitt'] ?? '',
              anerkennung: main['anerkennung'] ?? '',
              teilnoten: pendingPartials,
            ),
          );
        }
        pendingMain = null;
        pendingPartials = <PartialGrade>[];
      }

      for (final row in tbody.querySelectorAll('tr')) {
        final cols = row
            .querySelectorAll('td')
            .map((td) => td.text.trim())
            .toList();
        if (cols.isEmpty) continue;

        final map = <String, String>{};
        for (var i = 0; i < keys.length; i++) {
          map[keys[i]] = i < cols.length ? cols[i] : '';
        }

        final partialMatch = partialPattern.firstMatch(map['modul'] ?? '');
        if (partialMatch != null) {
          if (pendingMain != null) {
            pendingPartials.add(
              PartialGrade(
                gewichtung: partialMatch.group(1)!,
                bezeichnung: partialMatch.group(2)!.trim(),
                bewertung: map['bewertung'] ?? '',
                teilbewertung: map['teilbewertung'] ?? '',
                note: map['note'] ?? '',
              ),
            );
          }
          continue;
        }

        if (cols.length < 2 || cols[1].isEmpty) continue;

        flushPending();
        pendingMain = map;
      }

      flushPending();
    }

    return GradesResult(
      grades: grades,
      earnedCredits: earned,
      totalCredits: total == 0 ? null : total,
      gradeAverage: avg,
    );
  }
}
