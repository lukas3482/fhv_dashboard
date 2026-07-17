import 'package:flutter/material.dart';

import '../../../models/timetable_event.dart';
import 'day_column.dart';
import 'day_header_cell.dart';
import 'hour_axis.dart';

class CalendarGridView extends StatelessWidget {
  const CalendarGridView({
    required this.start,
    required this.grouped,
    super.key,
  });

  final DateTime start;
  final Map<DateTime, List<TimetableEvent>> grouped;

  static const double _pxPerHour = 60;
  static const double _axisWidth = 40;
  static const double _headerHeight = 44;
  static const int _minStartHour = 8;
  static const int _minEndHour = 18;

  List<DateTime> get _days {
    final weekdays = List.generate(5, (i) => start.add(Duration(days: i)));
    final weekend = List.generate(
      2,
      (i) => start.add(Duration(days: 5 + i)),
    ).where((d) => (grouped[d] ?? const []).isNotEmpty);
    return [...weekdays, ...weekend];
  }

  List<int> get _hourRange {
    var startHour = _minStartHour;
    var endHour = _minEndHour;
    for (final day in _days) {
      for (final e in grouped[day] ?? const <TimetableEvent>[]) {
        if (e.fullDay) continue;
        if (e.startDate.hour < startHour) startHour = e.startDate.hour;
        final endH = e.endDate.minute > 0 ? e.endDate.hour + 1 : e.endDate.hour;
        if (endH > endHour) endHour = endH;
      }
    }
    return [startHour, endHour];
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;
    final hourRange = _hourRange;
    final startHour = hourRange[0];
    final endHour = hourRange[1];
    final gridHeight = (endHour - startHour) * _pxPerHour;

    return Column(
      children: [
        SizedBox(
          height: _headerHeight,
          child: Row(
            children: [
              const SizedBox(width: _axisWidth),
              for (final day in days) Expanded(child: DayHeaderCell(day)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: gridHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _axisWidth,
                    height: gridHeight,
                    child: HourAxis(
                      startHour: startHour,
                      endHour: endHour,
                      pxPerHour: _pxPerHour,
                    ),
                  ),
                  for (final day in days)
                    Expanded(
                      child: DayColumn(
                        day: day,
                        events: grouped[day] ?? const [],
                        startHour: startHour,
                        pxPerHour: _pxPerHour,
                        height: gridHeight,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
