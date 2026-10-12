import 'package:flutter/material.dart';

import '../models/departure.dart';
import '../services/departure_service.dart';
import '../services/settings_service.dart';

class BusFilterScreen extends StatefulWidget {
  const BusFilterScreen({super.key});

  @override
  State<BusFilterScreen> createState() => _BusFilterScreenState();
}

class _BusFilterScreenState extends State<BusFilterScreen> {
  late Set<String> _selected;
  late Future<List<BusRoute>> _routesFuture;

  @override
  void initState() {
    super.initState();
    _selected = {...SettingsService().busRouteFilter.value};
    _routesFuture = _loadRoutes();
  }

  Future<List<BusRoute>> _loadRoutes() async {
    final routes = await DepartureService().fetchRoutes();
    final all = {...routes, ..._selected.map(BusRoute.fromKey)}.toList()
      ..sort();
    return all;
  }

  void _retry() => setState(() => _routesFuture = _loadRoutes());

  void _save() => SettingsService().setBusRouteFilter({..._selected});

  void _toggle(Iterable<BusRoute> routes, bool selected) {
    setState(() {
      for (final r in routes) {
        selected ? _selected.add(r.key) : _selected.remove(r.key);
      }
    });
    _save();
  }

  void _clear() {
    setState(_selected.clear);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Busse auswählen'),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(onPressed: _clear, child: const Text('Alle anzeigen')),
        ],
      ),
      body: FutureBuilder<List<BusRoute>>(
        future: _routesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Linien konnten nicht geladen werden.\n'
                      '${snapshot.error.toString().replaceFirst('Exception: ', '')}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildList(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<BusRoute> routes) {
    final byLine = <String, List<BusRoute>>{};
    for (final r in routes) {
      byLine.putIfAbsent(r.line, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            _selected.isEmpty
                ? 'Keine Auswahl – es werden alle Busse ab '
                      '${DepartureService.campusStationName} angezeigt.'
                : 'Auf der Startseite werden nur die ausgewählten Linien '
                      'und Richtungen angezeigt.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final entry in byLine.entries)
          _LineGroup(
            line: entry.key,
            routes: entry.value,
            selected: _selected,
            onToggle: _toggle,
          ),
      ],
    );
  }
}

class _LineGroup extends StatelessWidget {
  const _LineGroup({
    required this.line,
    required this.routes,
    required this.selected,
    required this.onToggle,
  });

  final String line;
  final List<BusRoute> routes;
  final Set<String> selected;
  final void Function(Iterable<BusRoute> routes, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = routes.where((r) => selected.contains(r.key)).length;
    final bool? lineValue = count == 0
        ? false
        : count == routes.length
        ? true
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          CheckboxListTile(
            tristate: true,
            value: lineValue,
            onChanged: (_) => onToggle(routes, lineValue != true),
            title: Row(
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Linie $line',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          for (final r in routes)
            CheckboxListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 32, right: 16),
              value: selected.contains(r.key),
              onChanged: (v) => onToggle([r], v ?? false),
              secondary: const Icon(Icons.arrow_forward, size: 18),
              title: Text(r.direction),
            ),
        ],
      ),
    );
  }
}
