import 'package:flutter/material.dart';

import '../../../models/timetable_event.dart';
import '../event_detail_sheet.dart';

class GridEventBlock extends StatelessWidget {
  const GridEventBlock({required this.event, super.key});

  final TimetableEvent event;

  // Rough single-line height (font size + default leading) used to decide
  // how many of subject/time/room fit before the Column would overflow —
  // short events (or a larger system font size) get fewer lines instead of
  // a RenderFlex overflow.
  static const _lineHeight = 15.0;

  @override
  Widget build(BuildContext context) {
    final room = event.rooms.length > 4
        ? event.rooms.substring(0, 4)
        : event.rooms;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showEventDetails(context, event),
      child: Container(
        margin: const EdgeInsets.all(1),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: event.color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableLines = (constraints.maxHeight / _lineHeight)
                  .floor();
              final showTime = availableLines >= 2;
              final showRoom = availableLines >= 3 && room.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.eventName,
                    style: TextStyle(
                      color: event.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showTime)
                    Text(
                      formatTime(event.startDate),
                      style: TextStyle(color: event.textColor, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (showRoom)
                    Text(
                      room,
                      style: TextStyle(color: event.textColor, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
