import 'package:flutter/material.dart';

import '../models/mensa_menu.dart';
import '../services/mensa_service.dart';
import '../widgets/mensa/day_menu_card.dart';

class MensaScreen extends StatefulWidget {
  const MensaScreen({super.key});

  @override
  State<MensaScreen> createState() => _MensaScreenState();
}

class _MensaScreenState extends State<MensaScreen> {
  static const _minWeekOffset = 0;
  static const _maxWeekOffset = 1;

  int _weekOffset = 0;
  Future<MensaWeekMenu>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load({bool forceRefresh = false}) {
    setState(() {
      _future = _fetch(weekOffset: _weekOffset, forceRefresh: forceRefresh);
    });
  }

  Future<MensaWeekMenu> _fetch({
    required int weekOffset,
    required bool forceRefresh,
  }) async {
    final week = MensaService.isoWeekNumber(
      DateTime.now().add(Duration(days: 7 * weekOffset)),
    );
    if (!forceRefresh) {
      final cached = await MensaService().loadCached(week);
      if (cached != null) return cached;
    }
    return MensaService().fetchWeek(weekOffset: weekOffset);
  }

  void _changeWeek(int delta) {
    if (delta > 0 && _weekOffset >= _maxWeekOffset) return;
    if (delta < 0 && _weekOffset <= _minWeekOffset) return;
    setState(() => _weekOffset += delta);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Vorherige Woche',
                onPressed: _weekOffset <= _minWeekOffset
                    ? null
                    : () => _changeWeek(-1),
              ),
              Expanded(
                child: Center(
                  child: FutureBuilder<MensaWeekMenu>(
                    future: _future,
                    builder: (context, snapshot) {
                      final week =
                          snapshot.data?.week ??
                          MensaService.isoWeekNumber(
                            DateTime.now().add(Duration(days: 7 * _weekOffset)),
                          );
                      final range = snapshot.data?.dateRangeLabel;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.restaurant_outlined, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'KW $week',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            if (range != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  range,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Nächste Woche',
                onPressed: _weekOffset >= _maxWeekOffset
                    ? null
                    : () => _changeWeek(1),
              ),
            ],
          ),
        ),
        if (_weekOffset != _minWeekOffset)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: TextButton.icon(
              onPressed: () {
                setState(() => _weekOffset = _minWeekOffset);
                _load();
              },
              icon: const Icon(Icons.today_outlined, size: 16),
              label: const Text('Zur aktuellen Woche'),
            ),
          ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    return FutureBuilder<MensaWeekMenu>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _load(forceRefresh: true),
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          );
        }

        final menu = snapshot.data!;
        if (menu.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => _load(forceRefresh: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Der Menüplan konnte nicht in Tage/Gerichte zerlegt '
                  'werden. Hier der erkannte Text zur Kontrolle:',
                ),
                const SizedBox(height: 12),
                SelectableText(
                  menu.rawText,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          );
        }

        const weekdayLabels = [
          'Montag',
          'Dienstag',
          'Mittwoch',
          'Donnerstag',
          'Freitag',
        ];
        final weekday = DateTime.now().weekday;
        final today = _weekOffset == 0 && weekday <= 5
            ? weekdayLabels[weekday - 1]
            : null;

        return RefreshIndicator(
          onRefresh: () async => _load(forceRefresh: true),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: menu.days.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (context, i) => DayMenuCard(
              day: menu.days[i],
              isToday: menu.days[i].day == today,
            ),
          ),
        );
      },
    );
  }
}
