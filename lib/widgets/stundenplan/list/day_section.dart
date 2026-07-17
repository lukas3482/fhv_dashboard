import 'package:flutter/material.dart';

import '../../../models/timetable_event.dart';
import 'event_card.dart';

class DaySection extends StatelessWidget {
  const DaySection({required this.day, required this.events, super.key});

  final DateTime day;
  final List<TimetableEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Text(
            _fmtHeader(day),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        ...events.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EventCard(event: e),
          ),
        ),
      ],
    );
  }

  static String _fmtHeader(DateTime d) {
    const weekdays = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    const months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]}';
  }
}
