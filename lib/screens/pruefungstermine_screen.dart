import 'package:flutter/material.dart';

import '../models/exam_appointment.dart';
import '../services/exam_service.dart';

class PruefungstermineScreen extends StatefulWidget {
  const PruefungstermineScreen({super.key});

  @override
  State<PruefungstermineScreen> createState() => _PruefungstermineScreenState();
}

class _PruefungstermineScreenState extends State<PruefungstermineScreen> {
  late Future<List<ExamAppointment>> _future;

  @override
  void initState() {
    super.initState();
    _future = ExamService().fetchExams();
  }

  void _refresh() => setState(() => _future = ExamService().fetchExams());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExamAppointment>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(snapshot.error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: _refresh,
                    child: const Text('Erneut versuchen')),
              ],
            ),
          );
        }

        final all = snapshot.data!;
        if (all.isEmpty) {
          return const Center(child: Text('Keine Prüfungstermine gefunden.'));
        }

        final upcoming = all.where((e) => !e.isPast).toList();
        final past = all.where((e) => e.isPast).toList();

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              if (upcoming.isNotEmpty) ...[
                _SectionHeader('Bevorstehend', upcoming.length),
                ...upcoming.map((e) => _ExamCard(exam: e)),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionHeader('Vergangen', past.length),
                ...past.map((e) => _ExamCard(exam: e, dimmed: true)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, this.count);
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, this.dimmed = false});
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
                        horizontal: 12, vertical: 10),
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
                                    fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(
                                registered: exam.isRegistered,
                                color: barColor),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Date + time
                        if (exam.dateStr.isNotEmpty)
                          _Row(
                            icon: Icons.event_outlined,
                            text: exam.timeStr.isNotEmpty
                                ? '${exam.dateStr}  ·  ${exam.timeStr} Uhr'
                                : exam.dateStr,
                          ),
                        // Room
                        if (exam.room.isNotEmpty)
                          _Row(
                              icon: Icons.room_outlined, text: exam.room),
                        // Lecturer
                        if (exam.lecturer.isNotEmpty)
                          _Row(
                              icon: Icons.person_outline,
                              text: exam.lecturer),
                        // Appendix
                        if (exam.appendix.isNotEmpty)
                          _Row(
                              icon: Icons.info_outline,
                              text: exam.appendix),
                        // Comment
                        if (exam.comment.isNotEmpty)
                          _Row(
                              icon: Icons.chat_bubble_outline,
                              text: exam.comment),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.registered, required this.color});
  final bool registered;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        registered ? 'Angemeldet' : 'Nicht angemeldet',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
