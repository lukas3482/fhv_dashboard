import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dashboard_card_frame.dart';

class PlatformLink {
  final String label;
  final String url;
  final IconData icon;

  const PlatformLink(this.label, this.url, this.icon);
}

const _platformLinks = [
  PlatformLink('Ilias', 'https://ilias.fhv.at', Icons.school_outlined),
  PlatformLink('Inside FHV', 'https://inside.fhv.at', Icons.newspaper_outlined),
  PlatformLink('Outlook', 'https://outlook.fhv.at', Icons.mail_outline),
  PlatformLink('FHV-A5', 'https://a5.fhv.at/', Icons.grade),
  PlatformLink(
    'Mensa',
    'https://laendlegastronomie.at/menue.html#menue_fhmensa',
    Icons.restaurant_menu,
  ),
];

class PlatformLinksCard extends StatelessWidget {
  const PlatformLinksCard({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Konnte $url nicht öffnen.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCardFrame(
      icon: Icons.link,
      title: 'FHV-Links',
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (final link in _platformLinks)
            ListTile(
              dense: true,
              leading: Icon(link.icon),
              title: Text(link.label, style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open(context, link.url),
            ),
        ],
      ),
    );
  }
}
