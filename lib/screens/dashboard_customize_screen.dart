import 'package:flutter/material.dart';

import '../models/dashboard_card.dart';
import '../services/settings_service.dart';

class DashboardCustomizeScreen extends StatefulWidget {
  const DashboardCustomizeScreen({super.key});

  @override
  State<DashboardCustomizeScreen> createState() =>
      _DashboardCustomizeScreenState();
}

class _DashboardCustomizeScreenState extends State<DashboardCustomizeScreen> {
  late List<DashboardCardConfig> _cards;

  @override
  void initState() {
    super.initState();
    _cards = List.of(SettingsService().dashboardCards.value);
  }

  void _save() => SettingsService().setDashboardCards(_cards);

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _cards.removeAt(oldIndex);
      _cards.insert(newIndex, item);
    });
    _save();
  }

  void _toggleVisible(DashboardCardType type, bool visible) {
    setState(() {
      _cards = [
        for (final c in _cards)
          if (c.type == type) c.copyWith(visible: visible) else c,
      ];
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard anpassen')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Reihenfolge per Ziehen ändern, Sichtbarkeit über den Schalter.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _cards.length,
              onReorderItem: _onReorder,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return Card(
                  key: ValueKey(card.type),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: SwitchListTile(
                    secondary: const Icon(Icons.drag_handle),
                    title: Text(card.type.label),
                    value: card.visible,
                    onChanged: (v) => _toggleVisible(card.type, v),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
