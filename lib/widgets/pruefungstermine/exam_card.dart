import 'package:flutter/material.dart';

import '../../models/exam_appointment.dart';
import 'exam_info_row.dart';
import 'status_badge.dart';

class ExamCard extends StatelessWidget {
  const ExamCard({required this.exam, this.dimmed = false, super.key});
  final ExamAppointment exam;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final registeredColor = Colors.green.shade600;
    final barColor = exam.isRegistered ? registeredColor : Colors.grey;

    return Opacity(
      opacity: dimmed ? 0.55 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          clipBehavior: Clip.hardEdge,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: barColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + registration badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                exam.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              registered: exam.isRegistered,
                              color: barColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Date + time
                        if (exam.dateStr.isNotEmpty)
                          ExamInfoRow(
                            icon: Icons.event_outlined,
                            text: exam.timeStr.isNotEmpty
                                ? '${exam.dateStr}  ·  ${exam.timeStr} Uhr'
                                : exam.dateStr,
                          ),
                        // Room
                        if (exam.room.isNotEmpty)
                          ExamInfoRow(
                            icon: Icons.room_outlined,
                            text: exam.room,
                          ),
                        // Lecturer
                        if (exam.lecturer.isNotEmpty)
                          ExamInfoRow(
                            icon: Icons.person_outline,
                            text: exam.lecturer,
                          ),
                        // Appendix
                        if (exam.appendix.isNotEmpty)
                          ExamInfoRow(
                            icon: Icons.info_outline,
                            text: exam.appendix,
                          ),
                        // Comment
                        if (exam.comment.isNotEmpty)
                          ExamInfoRow(
                            icon: Icons.chat_bubble_outline,
                            text: exam.comment,
                          ),
                        // Sub-parts hint
                        if (exam.hasSubParts) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Enthält Teilprüfungen',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
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
      ),
    );
  }
}
