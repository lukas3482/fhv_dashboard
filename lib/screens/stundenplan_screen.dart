import 'package:flutter/material.dart';

import '../models/timetable_event.dart';
import '../services/timetable_service.dart';

class StundenplanScreen extends StatefulWidget {
  const StundenplanScreen({super.key});

  @override
  State<StundenplanScreen> createState() => _StundenplanScreenState();
}

class _StundenplanScreenState extends State<StundenplanScreen> {
  late DateTime _start;
  late Future<Map<DateTime, List<TimetableEvent>>> _future;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _start = _today;
    _load();
  }

  void _load() {
    setState(() {
      _future = TimetableService().fetchWeek(_start);
    });
  }

  void _shift(int delta) {
    _start = _start.add(Duration(days: 7 * delta));
    _load();
  }

  void _goToToday() {
    _start = _today;
    _load();
  }

  bool get _isToday => _start == _today;

  @override
  Widget build(BuildContext context) {
    final end = _start.add(const Duration(days: 6));

    return Column(
      children: [
        _WeekHeader(
          start: _start,
          end: end,
          isToday: _isToday,
          onPrev: () => _shift(-1),
          onNext: () => _shift(1),
          onToday: _goToToday,
        ),
        Expanded(
          child: FutureBuilder<Map<DateTime, List<TimetableEvent>>>(
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
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(snapshot.error.toString(),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                          onPressed: _load,
                          child: const Text('Erneut versuchen')),
                    ],
                  ),
                );
              }

              final grouped = snapshot.data!;
              if (grouped.isEmpty) {
                return const Center(
                    child: Text('Keine Veranstaltungen diese Woche.'));
              }

              final days = grouped.keys.toList()..sort();

              return RefreshIndicator(
                onRefresh: () async => _load(),
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: days.length,
                  itemBuilder: (context, i) {
                    final day = days[i];
                    final events = grouped[day]!;
                    return _DaySection(day: day, events: events);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Week navigation header ────────────────────────────────────────────────────

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.start,
    required this.end,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final DateTime start;
  final DateTime end;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Expanded(
            child: Text(
              '${_fmtDay(start)} – ${_fmtDay(end)} ${end.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (!isToday)
            TextButton(
              onPressed: onToday,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Heute'),
            )
          else
            const SizedBox(width: 48),
          IconButton(
              icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }

  static String _fmtDay(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return '${d.day}. ${months[d.month - 1]}';
  }
}

// ── Day section ───────────────────────────────────────────────────────────────

class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.events});

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
        ...events.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _EventCard(event: e),
            )),
      ],
    );
  }

  static String _fmtHeader(DateTime d) {
    const weekdays = [
      'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag',
      'Freitag', 'Samstag', 'Sonntag'
    ];
    const months = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]}';
  }
}

// ── Event card ────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final TimetableEvent event;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${_t(event.startDate)} – ${_t(event.endDate)}';

    return Card(
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color bar
            Container(width: 5, color: event.color),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time + occasion chip
                    Row(
                      children: [
                        Text(timeStr,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        if (event.occasion.isNotEmpty)
                          _Chip(event.occasion, event.color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Subject
                    Text(
                      event.eventName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    // Room + building
                    if (event.rooms.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.room_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [event.rooms, if (event.buildings.isNotEmpty) event.buildings]
                                .join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ]),
                    ],
                    // Lecturer
                    if (event.lecturers.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(event.lecturers,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ]),
                    ],
                    // Exam parts
                    if (event.examParts.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: event.examParts
                            .map((p) => _Chip(p, Colors.grey))
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
    );
  }

  static String _t(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color == Colors.grey
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : color,
        ),
      ),
    );
  }
}
