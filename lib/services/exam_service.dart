import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/exam_appointment.dart';
import 'auth_service.dart';

class ExamService {
  static const _url = 'https://a5.fhv.at/de/pruefungen.php';

  static final ExamService _instance = ExamService._internal();
  factory ExamService() => _instance;
  ExamService._internal();

  Future<List<ExamAppointment>> fetchExams() async {
    final response = await AuthService().dio.get(_url);

    if (response.statusCode == 302) throw Exception('Session abgelaufen.');
    if (response.statusCode != 200) {
      throw Exception(
        'Fehler beim Laden der Prüfungstermine (${response.statusCode})',
      );
    }

    return _parseHtml(response.data.toString());
  }

  @visibleForTesting
  List<ExamAppointment> parseHtml(String html) => _parseHtml(html);

  List<ExamAppointment> _parseHtml(String html) {
    final document = html_parser.parse(html);
    final rows = document.querySelectorAll(
      'table.table-bordered.table-update.table-info tr.exam-row',
    );

    final results = <ExamAppointment>[];

    for (final row in rows) {
      final isRegistered = row.classes.contains('info-success');
      final hasSubParts = row.querySelector('i.fa-circle-half-stroke') != null;

      final name =
          row.querySelector('h3.exam-name')?.text.trim() ??
          row.querySelector('[data-exam-name]')?.attributes['data-exam-name'] ??
          '';
      if (name.isEmpty) continue;

      final dateStr = row.querySelector('h3.exam-date')?.text.trim() ?? '';
      final timeRaw = row.querySelector('h3.exam-time')?.text ?? '';
      final timeStr = _normalizeWhitespace(timeRaw);

      final lecturerRaw =
          row.querySelector('[data-column="lecturers"] h3')?.text.trim() ?? '';
      final lecturer = lecturerRaw == 'Nicht zugeordnet' ? '' : lecturerRaw;

      final room =
          row.querySelector('[data-column="room"] h3')?.text.trim() ?? '';
      final appendix = row.querySelector('h3.exam-appendix')?.text.trim() ?? '';
      final comment =
          row.querySelector('[data-column="comment"] h3')?.text.trim() ?? '';

      results.add(
        ExamAppointment(
          name: name,
          date: _parseDate(dateStr, timeStr),
          dateStr: dateStr,
          timeStr: timeStr,
          room: room,
          lecturer: lecturer,
          appendix: appendix,
          comment: comment,
          isRegistered: isRegistered,
          hasSubParts: hasSubParts,
        ),
      );
    }

    results.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return a.date!.compareTo(b.date!);
    });

    return results;
  }

  DateTime? _parseDate(String dateStr, String timeStr) {
    final parts = dateStr.split('.');
    if (parts.length != 3) return null;
    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final timePart = timeStr.split('-').first.trim(); // "12:20"
      final timeParts = timePart.split(':');
      final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
      final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  String _normalizeWhitespace(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ');
}
