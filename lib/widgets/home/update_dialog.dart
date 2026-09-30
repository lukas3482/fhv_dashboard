import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo info;

  const UpdateDialog({super.key, required this.info});

  Future<void> _openRelease(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(info.htmlUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konnte den Link nicht öffnen.')),
      );
    }
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.system_update),
      title: const Text('Update verfügbar'),
      content: Text(
        'Eine neue Version der App ist verfügbar (${info.version}). '
        'Du kannst sie von der GitHub-Release-Seite herunterladen.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Später'),
        ),
        FilledButton(
          onPressed: () => _openRelease(context),
          child: const Text('Herunterladen'),
        ),
      ],
    );
  }
}
