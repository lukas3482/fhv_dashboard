import 'package:flutter/material.dart';

import '../../models/timetable_event.dart';
import 'list/label_chip.dart';

String formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

void showEventDetails(BuildContext context, TimetableEvent event) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.eventName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatTime(event.startDate)} – ${formatTime(event.endDate)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (event.occasion.isNotEmpty) ...[
            const SizedBox(height: 8),
            LabelChip(event.occasion, event.color),
          ],
          if (event.rooms.isNotEmpty) ...[
            const SizedBox(height: 12),
            DetailRow(Icons.room_outlined, [event.rooms].join(' · ')),
          ],
          if (event.lecturers.isNotEmpty) ...[
            const SizedBox(height: 6),
            DetailRow(Icons.person_outline, event.lecturers),
          ],
          if (event.examParts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: event.examParts
                  .map((p) => LabelChip(p, Colors.grey))
                  .toList(),
            ),
          ],
          if (event.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(event.comment, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    ),
  );
}

class DetailRow extends StatelessWidget {
  const DetailRow(this.icon, this.text, {super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
