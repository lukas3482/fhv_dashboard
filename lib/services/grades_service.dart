import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' as html_parser;
import 'package:path_provider/path_provider.dart';

import '../models/grade.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class GradesService {
  static const _notenUrl = 'https://a5.fhv.at/de/noten.php';
  static const _cacheFileName = 'grades_cache.json';

  static final GradesService _instance = GradesService._internal();
  factory GradesService() => _instance;
  GradesService._internal();

  Future<File> get _cacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<GradesResult?> loadCached() async {
    try {
      final file = await _cacheFile;
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return GradesResult.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      final file = await _cacheFile;
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _saveCache(GradesResult result) async {
    try {
      final file = await _cacheFile;
      await file.writeAsString(jsonEncode(result.toJson()));
    } catch (_) {}
  }

  Future<GradesResult> fetchGrades() async {
    final (result, _) = await fetchGradesDetailed();
    return result;
  }

  Future<(GradesResult, List<GradeChange>)> fetchGradesDetailed() async {
    final oldCached = await loadCached();

    final response = await AuthService().dio.get(_notenUrl);
    if (response.statusCode != 200) {
      throw Exception(
        'Notenseite konnte nicht geladen werden (${response.statusCode})',
      );
    }

    final result = _parseHtml(response.data.toString());
    final changes = oldCached == null
        ? const <GradeChange>[]
        : _diffGrades(oldCached.grades, result.grades);

    await _saveCache(result);
    if (changes.isNotEmpty) {
      await NotificationService().showGradeChanges(changes);
    }

    return (result, changes);
  }

  List<GradeChange> _diffGrades(List<Grade> oldGrades, List<Grade> newGrades) {
    final oldByModul = {for (final g in oldGrades) g.modul: g};
    final changes = <GradeChange>[];

    for (final grade in newGrades) {
      final newNote = _effectiveNote(grade);
      if (newNote.isEmpty) continue;

      final old = oldByModul[grade.modul];
      if (old == null) {
        changes.add(
          GradeChange(
            modul: grade.modul,
            oldNote: null,
            newNote: newNote,
            isNew: true,
          ),
        );
        continue;
      }

      final oldNote = _effectiveNote(old);
      if (oldNote != newNote) {
        changes.add(
          GradeChange(
            modul: grade.modul,
            oldNote: oldNote.isEmpty ? null : oldNote,
            newNote: newNote,
            isNew: false,
          ),
        );
      }
    }

    return changes;
  }

  String _effectiveNote(Grade grade) {
    if (grade.note.isNotEmpty) return grade.note;
    if (grade.bewertung.isNotEmpty &&
        grade.bewertung != '-' &&
        !grade.bewertung.toLowerCase().contains('folgt')) {
      return grade.bewertung;
    }
    return '';
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
