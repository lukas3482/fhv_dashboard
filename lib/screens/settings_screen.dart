import 'package:flutter/material.dart';

import '../services/background_service.dart';
import '../services/settings_service.dart';
import 'dashboard_customize_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _intervalOptions = [15, 30, 60, 120];

  Future<void> _setInterval(int minutes) async {
    await SettingsService().setRefreshIntervalMinutes(minutes);
    await BackgroundService.updateFrequency(Duration(minutes: minutes));
  }

  Future<void> _editTargetEcts(BuildContext context, int current) async {
    final controller = TextEditingController(text: current.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ziel-ECTS'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(suffixText: 'ECTS'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, int.tryParse(controller.text.trim()));
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      await SettingsService().setTargetEcts(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          const _SectionHeader('Startseite'),
          ListTile(
            title: const Text('Dashboard anpassen'),
            subtitle: const Text(
              'Karten auf der Startseite ein-/ausblenden und sortieren.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DashboardCustomizeScreen(),
              ),
            ),
          ),
          const Divider(height: 1),
          const _SectionHeader('Darstellung'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: settings.themeMode,
            builder: (context, mode, _) => RadioGroup<ThemeMode>(
              groupValue: mode,
              onChanged: (m) => settings.setThemeMode(m!),
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text('System'),
                    value: ThemeMode.system,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Hell'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Dunkel'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          const _SectionHeader('Studienfortschritt'),
          ValueListenableBuilder<int>(
            valueListenable: settings.targetEcts,
            builder: (context, target, _) => ListTile(
              title: const Text('Ziel-ECTS'),
              subtitle: const Text(
                'Fallback für den Fortschrittsbalken, falls die FHV-Seite '
                'kein Ziel liefert.',
              ),
              trailing: Text(
                '$target',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              onTap: () => _editTargetEcts(context, target),
            ),
          ),
          const Divider(height: 1),
          const _SectionHeader('Benachrichtigungen'),
          ValueListenableBuilder<bool>(
            valueListenable: settings.notificationsEnabled,
            builder: (context, enabled, _) => SwitchListTile(
              title: const Text('Notenänderungen benachrichtigen'),
              subtitle: const Text(
                'System-Benachrichtigung bei neuen oder geänderten Noten.',
              ),
              value: enabled,
              onChanged: settings.setNotificationsEnabled,
            ),
          ),
          const Divider(height: 1),
          const _SectionHeader('Hintergrund-Aktualisierung'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Wie oft die Noten im Hintergrund geprüft werden.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: settings.refreshIntervalMinutes,
            builder: (context, minutes, _) => RadioGroup<int>(
              groupValue: minutes,
              onChanged: (v) => _setInterval(v!),
              child: Column(
                children: [
                  for (final option in _intervalOptions)
                    RadioListTile<int>(
                      title: Text(_formatInterval(option)),
                      value: option,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatInterval(int minutes) {
    if (minutes < 60) return '$minutes Minuten';
    final hours = minutes ~/ 60;
    return '$hours Stunde${hours == 1 ? '' : 'n'}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
