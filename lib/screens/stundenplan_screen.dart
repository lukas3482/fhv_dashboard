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
  Map<DateTime, List<TimetableEvent>>? _grouped;
  String? _error;
  bool _isRefreshing = false;

  int _loadToken = 0;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _anchorFor(StundenplanViewMode mode) {
    final today = _today;
    if (mode == StundenplanViewMode.grid) {
      return DateTime(today.year, today.month, today.day - (today.weekday - 1));
    }
    return today;
  }

  @override
  void initState() {
    super.initState();
    _start = _anchorFor(SettingsService().stundenplanViewMode.value);
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final token = ++_loadToken;
    final requestedStart = _start;

    if (!forceRefresh) {
      setState(() {
        _grouped = null;
        _error = null;
      });

      final cached = await TimetableService().loadCachedWeek(requestedStart);
      if (!mounted || token != _loadToken) return;
      if (cached != null) {
        setState(() => _grouped = cached);
      }
    }

    if (!mounted || token != _loadToken) return;
    setState(() => _isRefreshing = true);

    try {
      final fresh = await TimetableService().fetchWeek(requestedStart);
      if (!mounted || token != _loadToken) return;
      setState(() {
        _grouped = fresh;
        _error = null;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _isRefreshing = false;
        if (_grouped == null) _error = e.toString();
      });
      if (_grouped != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aktualisierung fehlgeschlagen ($e) – zeige zwischengespeicherten Stundenplan.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _refresh() => _load(forceRefresh: true);

  void _shift(int delta) {
    final mode = SettingsService().stundenplanViewMode.value;
    if (mode == StundenplanViewMode.list && _start == _today) {
      final mondayThisWeek = DateTime(
        _today.year,
        _today.month,
        _today.day - (_today.weekday - 1),
      );
      _start = DateTime(
        mondayThisWeek.year,
        mondayThisWeek.month,
        mondayThisWeek.day + 7 * delta,
      );
    } else {
      _start = DateTime(_start.year, _start.month, _start.day + 7 * delta);
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
            if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildBody(viewMode)),
          ],
        );
      },
    );
  }

  Widget _buildBody(StundenplanViewMode viewMode) {
    final grouped = _grouped;

    if (grouped == null && _error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (grouped == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (grouped.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Keine Veranstaltungen diese Woche.')),
          ],
        ),
      );
    }

    if (viewMode == StundenplanViewMode.grid) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: CalendarGridView(start: _start, grouped: grouped),
      );
    }

    final days = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: days.length,
        itemBuilder: (context, i) {
          final day = days[i];
          final events = grouped[day]!;
          return DaySection(day: day, events: events);
        },
      ),
    );
  }
}
