import 'package:flutter/material.dart';

class TimetableEvent {
  final String id;
  final String eventName;
  final DateTime startDate;
  final DateTime endDate;
  final String rooms;
  final String buildings;
  final String occasion;
  final List<String> examParts;
  final String lecturers;
  final Color color;
  final Color textColor;
  final bool fullDay;
  final String comment;
  final bool isHoliday;

  const TimetableEvent({
    required this.id,
    required this.eventName,
    required this.startDate,
    required this.endDate,
    required this.rooms,
    required this.buildings,
    required this.occasion,
    required this.examParts,
    required this.lecturers,
    required this.color,
    required this.textColor,
    required this.fullDay,
    required this.comment,
    required this.isHoliday,
  });

  factory TimetableEvent.fromJson(
    Map<String, dynamic> json, {
    List<String> extraExamParts = const [],
  }) {
    final examPart = (json['exam_part'] as String? ?? '').trim();
    final parts = [if (examPart.isNotEmpty) examPart, ...extraExamParts];

    return TimetableEvent(
      id: json['id'] as String? ?? '',
      eventName: json['event_subject'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      rooms: json['rooms'] as String? ?? '',
      buildings: json['buildings'] as String? ?? '',
      occasion: json['occasion'] as String? ?? '',
      examParts: parts,
      lecturers: json['lecturers'] as String? ?? '',
      color: _hexColor(json['color'] as String? ?? '', const Color(0xFF3498DB)),
      textColor: _hexColor(
        json['textColor'] as String? ?? '',
        const Color(0xFFFFFFFF),
      ),
      fullDay: json['full_day'] as bool? ?? false,
      comment: json['comment'] as String? ?? '',
      isHoliday: json['is_holiday'] as bool? ?? false,
    );
  }

  static Color _hexColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {}
    return fallback;
  }
}
