import 'package:flutter/material.dart';

import '../models/timetable_event.dart';
import '../services/settings_service.dart';
import '../services/timetable_service.dart';
import '../widgets/stundenplan/grid/calendar_grid_view.dart';
import '../widgets/stundenplan/list/day_section.dart';
import '../widgets/stundenplan/week_header.dart';

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
      // Leaving the rolling "today .. +6 days" window — from here on,
      // navigate whole Mon–Sun calendar weeks instead.
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
    // Only re-anchor when the mode being left was showing "today" in its
    // own sense (rolling window for list, this week's Monday for grid) —
    // that's the one case where the two modes disagree on what "today"
    // means. Otherwise a navigated-to week is already Monday-aligned in
    // both modes, so _start carries over unchanged.
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
            WeekHeader(
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
                      child: CalendarGridView(start: _start, grouped: grouped),
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
                        return DaySection(day: day, events: events);
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
