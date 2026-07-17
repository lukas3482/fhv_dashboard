import 'package:flutter/material.dart';

import '../../../models/timetable_event.dart';
import 'grid_event_block.dart';

class _LaidOutEvent {
  const _LaidOutEvent({
    required this.event,
    required this.columnIndex,
    required this.columnCount,
  });

  final TimetableEvent event;
  final int columnIndex;
  final int columnCount;
}

class DayColumn extends StatelessWidget {
  const DayColumn({
    required this.day,
    required this.events,
    required this.startHour,
    required this.pxPerHour,
    required this.height,
    super.key,
  });

  final DateTime day;
  final List<TimetableEvent> events;
  final int startHour;
  final double pxPerHour;
  final double height;

  double get _pxPerMinute => pxPerHour / 60;

  // Greedy interval-graph column assignment, scoped per overlap cluster:
  // sort by start, put each event in the first column whose last event has
  // already ended. Column count is local to each cluster of mutually
  // overlapping events, not the whole day — so an event with no overlap
  // always gets the full day width, even if other events overlap
  // earlier/later that same day.
  List<_LaidOutEvent> _layout() {
    final timed = events.where((e) => !e.fullDay).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final result = <_LaidOutEvent>[];
    var clusterStart = 0;
    var columnEnds = <DateTime>[];
    var columnOf = <int, int>{};
    DateTime? clusterMaxEnd;

    void finalizeCluster(int endExclusive) {
      final columnCount = columnEnds.isEmpty ? 1 : columnEnds.length;
      for (var i = clusterStart; i < endExclusive; i++) {
        result.add(
          _LaidOutEvent(
            event: timed[i],
            columnIndex: columnOf[i]!,
            columnCount: columnCount,
          ),
        );
      }
    }

    for (var i = 0; i < timed.length; i++) {
      final e = timed[i];
      if (clusterMaxEnd != null && !e.startDate.isBefore(clusterMaxEnd)) {
        finalizeCluster(i);
        clusterStart = i;
        columnEnds = [];
        columnOf = {};
        clusterMaxEnd = null;
      }

      var col = columnEnds.indexWhere((end) => !end.isAfter(e.startDate));
      if (col == -1) {
        columnEnds.add(e.endDate);
        col = columnEnds.length - 1;
      } else {
        columnEnds[col] = e.endDate;
      }
      columnOf[i] = col;
      clusterMaxEnd = clusterMaxEnd == null || e.endDate.isAfter(clusterMaxEnd)
          ? e.endDate
          : clusterMaxEnd;
    }
    finalizeCluster(timed.length);

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final dayStart = DateTime(day.year, day.month, day.day, startHour);
    final laidOut = _layout();

    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            children: [
              for (var h = 0; h * pxPerHour < height; h++)
                Positioned(
                  top: h * pxPerHour,
                  left: 0,
                  right: 0,
                  child: Divider(
                    height: 1,
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.4),
                  ),
                ),
              for (final lo in laidOut)
                _eventBlock(context, lo, dayStart, width),
            ],
          );
        },
      ),
    );
  }

  Widget _eventBlock(
    BuildContext context,
    _LaidOutEvent lo,
    DateTime dayStart,
    double width,
  ) {
    final e = lo.event;
    final top = e.startDate.difference(dayStart).inMinutes * _pxPerMinute;
    final durationMinutes = e.endDate.difference(e.startDate).inMinutes;
    final rawHeight = durationMinutes * _pxPerMinute;
    final blockHeight = rawHeight < 22 ? 22.0 : rawHeight;
    final colWidth = width / lo.columnCount;

    return Positioned(
      top: top,
      left: colWidth * lo.columnIndex,
      width: colWidth,
      height: blockHeight,
      child: GridEventBlock(event: e),
    );
  }
}
