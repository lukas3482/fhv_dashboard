import 'package:flutter/material.dart';

import '../models/timetable_event.dart';
import '../services/settings_service.dart';
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

  static DateTime _anchorFor(StundenplanViewMode mode) {
    final today = _today;
    if (mode == StundenplanViewMode.grid) {
      return today.subtract(Duration(days: today.weekday - 1));
    }
    return today;
  }

  @override
  void initState() {
    super.initState();
    _start = _anchorFor(SettingsService().stundenplanViewMode.value);
    _load();
  }

  void _load() {
    setState(() {
      _future = TimetableService().fetchWeek(_start);
    });
  }

  void _shift(int delta) {
    final mode = SettingsService().stundenplanViewMode.value;
    if (mode == StundenplanViewMode.list && _start == _today) {
      final mondayThisWeek = _today.subtract(
        Duration(days: _today.weekday - 1),
      );
      _start = mondayThisWeek.add(Duration(days: 7 * delta));
    } else {
      _start = _start.add(Duration(days: 7 * delta));
    }
    _load();
  }

  void _goToToday() {
    _start = _anchorFor(SettingsService().stundenplanViewMode.value);
    _load();
  }

  void _onViewModeChanged(StundenplanViewMode mode) {
    if (_isTodayFor(SettingsService().stundenplanViewMode.value)) {
      _start = _anchorFor(mode);
    }
    SettingsService().setStundenplanViewMode(mode);
    _load();
  }

  bool _isTodayFor(StundenplanViewMode mode) => _start == _anchorFor(mode);

  @override
  Widget build(BuildContext context) {
    final end = _start.add(const Duration(days: 6));

    return ValueListenableBuilder<StundenplanViewMode>(
      valueListenable: SettingsService().stundenplanViewMode,
      builder: (context, viewMode, _) {
        return Column(
          children: [
            _WeekHeader(
              start: _start,
              end: end,
              isToday: _isTodayFor(viewMode),
              viewMode: viewMode,
              onPrev: () => _shift(-1),
              onNext: () => _shift(1),
              onToday: _goToToday,
              onViewModeChanged: _onViewModeChanged,
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
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Erneut versuchen'),
                          ),
                        ],
                      ),
                    );
                  }

                  final grouped = snapshot.data!;
                  if (grouped.isEmpty) {
                    return const Center(
                      child: Text('Keine Veranstaltungen diese Woche.'),
                    );
                  }

                  if (viewMode == StundenplanViewMode.grid) {
                    return RefreshIndicator(
                      onRefresh: () async => _load(),
                      child: _CalendarGridView(start: _start, grouped: grouped),
                    );
                  }

                  final days = grouped.keys.toList()..sort();

                  return RefreshIndicator(
                    onRefresh: () async => _load(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
      },
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.start,
    required this.end,
    required this.isToday,
    required this.viewMode,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onViewModeChanged,
  });

  final DateTime start;
  final DateTime end;
  final bool isToday;
  final StundenplanViewMode viewMode;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<StundenplanViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: onPrev,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_fmtDay(start)} – ${_fmtDay(end)} ${end.year}',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: isToday ? null : onToday,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Heute'),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onNext,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SegmentedButton<StundenplanViewMode>(
                segments: const [
                  ButtonSegment(
                    value: StundenplanViewMode.list,
                    icon: Icon(Icons.view_agenda_outlined),
                    label: Text('Liste'),
                  ),
                  ButtonSegment(
                    value: StundenplanViewMode.grid,
                    icon: Icon(Icons.calendar_view_week_outlined),
                    label: Text('Raster'),
                  ),
                ],
                selected: {viewMode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => onViewModeChanged(s.first),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDay(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez',
    ];
    return '${d.day}. ${months[d.month - 1]}';
  }
}

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
        ...events.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _EventCard(event: e),
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

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final TimetableEvent event;

  @override
  Widget build(BuildContext context) {
    final timeStr = '${_t(event.startDate)} – ${_t(event.endDate)}';

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _showEventDetails(context, event),
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
                            _Chip(event.occasion, event.color),
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
                      // Lecturer
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

class _CalendarGridView extends StatelessWidget {
  const _CalendarGridView({required this.start, required this.grouped});

  final DateTime start;
  final Map<DateTime, List<TimetableEvent>> grouped;

  static const double _pxPerHour = 60;
  static const double _axisWidth = 40;
  static const double _headerHeight = 44;
  static const int _minStartHour = 8;
  static const int _minEndHour = 18;

  static const _weekdayShort = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

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
              for (final day in days) Expanded(child: _DayHeaderCell(day)),
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
                    child: _HourAxis(
                      startHour: startHour,
                      endHour: endHour,
                      pxPerHour: _pxPerHour,
                    ),
                  ),
                  for (final day in days)
                    Expanded(
                      child: _DayColumn(
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

class _DayHeaderCell extends StatelessWidget {
  const _DayHeaderCell(this.day);

  final DateTime day;

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
          _CalendarGridView._weekdayShort[day.weekday - 1],
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

class _HourAxis extends StatelessWidget {
  const _HourAxis({
    required this.startHour,
    required this.endHour,
    required this.pxPerHour,
  });

  final int startHour;
  final int endHour;
  final double pxPerHour;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var h = startHour; h <= endHour; h++)
          Positioned(
            top: (h - startHour) * pxPerHour - 7,
            left: 0,
            right: 4,
            child: Text(
              '$h:00',
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}

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

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.events,
    required this.startHour,
    required this.pxPerHour,
    required this.height,
  });

  final DateTime day;
  final List<TimetableEvent> events;
  final int startHour;
  final double pxPerHour;
  final double height;

  double get _pxPerMinute => pxPerHour / 60;

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
      child: _GridEventBlock(event: e),
    );
  }
}

class _GridEventBlock extends StatelessWidget {
  const _GridEventBlock({required this.event});

  final TimetableEvent event;

  static const _lineHeight = 15.0;

  @override
  Widget build(BuildContext context) {
    final room = event.rooms.length > 4
        ? event.rooms.substring(0, 4)
        : event.rooms;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showEventDetails(context, event),
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
                      _formatTime(event.startDate),
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

String _formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

void _showEventDetails(BuildContext context, TimetableEvent event) {
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
            '${_formatTime(event.startDate)} – ${_formatTime(event.endDate)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (event.occasion.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Chip(event.occasion, event.color),
          ],
          if (event.rooms.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailRow(Icons.room_outlined, [event.rooms].join(' · ')),
          ],
          if (event.lecturers.isNotEmpty) ...[
            const SizedBox(height: 6),
            _DetailRow(Icons.person_outline, event.lecturers),
          ],
          if (event.examParts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: event.examParts
                  .map((p) => _Chip(p, Colors.grey))
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

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.text);

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
