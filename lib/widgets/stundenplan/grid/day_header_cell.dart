import 'package:flutter/material.dart';

class DayHeaderCell extends StatelessWidget {
  const DayHeaderCell(this.day, {super.key});

  final DateTime day;

  static const _weekdayShort = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    final color = isToday ? Theme.of(context).colorScheme.primary : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _weekdayShort[day.weekday - 1],
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
        Text(
          '${day.day}.${day.month}.',
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
