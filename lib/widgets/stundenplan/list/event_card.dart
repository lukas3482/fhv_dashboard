import 'package:flutter/material.dart';

import '../../../models/timetable_event.dart';
import '../event_detail_sheet.dart';
import 'label_chip.dart';

class EventCard extends StatelessWidget {
  const EventCard({required this.event, super.key});

  final TimetableEvent event;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${formatTime(event.startDate)} – ${formatTime(event.endDate)}';

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => showEventDetails(context, event),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: event.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            timeStr,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          if (event.occasion.isNotEmpty)
                            LabelChip(event.occasion, event.color),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.eventName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (event.rooms.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.room_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                [event.rooms].join(' · '),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (event.lecturers.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.lecturers,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (event.examParts.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: event.examParts
                              .map((p) => LabelChip(p, Colors.grey))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
