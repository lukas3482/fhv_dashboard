import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoDialog extends StatelessWidget {
  const InfoDialog({super.key});

  static const _githubUrl = 'https://github.com/lukas3482/fhv_dashboard';

  Future<void> _openGithub(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(_githubUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konnte den Link nicht öffnen.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: const Icon(Icons.info_outline),
      title: const Text('Über diese App'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diese App ist eine inoffizielle Anwedung und steht in '
            'keinerlei Verbindung zur Fachhochschule Vorarlberg. '
            'Die bereitgestellten Informationen, Inhalte und Funktionen'
            'dieser App wurde von unabhängigen Entwicklern erstellt.',
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _openGithub(context),
            child: Row(
              children: [
                Icon(Icons.code, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _githubUrl,
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Schließen'),
        ),
      ],
    );
  }
}
