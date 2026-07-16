import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/profile_info.dart';
import '../services/profile_service.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late Future<ProfileInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = ProfileService().fetchProfile();
  }

  void _refresh() => setState(() => _future = ProfileService().fetchProfile());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        children: [
          FutureBuilder<ProfileInfo>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return _ErrorCard(
                  message: snapshot.error.toString(),
                  onRetry: _refresh,
                );
              }
              return _ProfileCard(profile: snapshot.data!);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'FHV-Plattformen',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const _PlatformLinksCard(),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});
  final ProfileInfo profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.isEmpty ? 'Unbekannt' : profile.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      if (profile.affiliation.isNotEmpty)
                        Text(
                          profile.affiliation,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (profile.matriculationNumber.isNotEmpty) ...[
              const Divider(height: 24),
              _InfoRow('Matrikelnummer', profile.matriculationNumber),
            ],
            if (profile.personKey.isNotEmpty)
              _InfoRow('Personenkennzeichen', profile.personKey),
            if (profile.contacts.isNotEmpty) ...[
              const Divider(height: 24),
              ...profile.contacts.map((c) => _ContactRow(contact: c)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact});
  final ProfileContact contact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            contact.type == 'phone' ? Icons.phone_outlined : Icons.mail_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              contact.value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (contact.isPrimary)
            Icon(
              Icons.star,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformLink {
  final String label;
  final String url;
  final IconData icon;

  const _PlatformLink(this.label, this.url, this.icon);
}

const _platformLinks = [
  _PlatformLink('Ilias', 'https://ilias.fhv.at', Icons.school_outlined),
  _PlatformLink(
    'Inside FHV',
    'https://inside.fhv.at',
    Icons.newspaper_outlined,
  ),
  _PlatformLink('Outlook', 'https://outlook.fhv.at', Icons.mail_outline),
  _PlatformLink('FHV-A5', 'https://a5.fhv.at/', Icons.grade),
  _PlatformLink(
    'Mensa',
    'https://laendlegastronomie.at/menue.html#menue_fhmensa',
    Icons.restaurant_menu,
  ),
];

class _PlatformLinksCard extends StatelessWidget {
  const _PlatformLinksCard();

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
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final link in _platformLinks)
            ListTile(
              leading: Icon(link.icon),
              title: Text(link.label),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open(context, link.url),
            ),
        ],
      ),
    );
  }
}
