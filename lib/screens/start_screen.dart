import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/dashboard_card.dart';
import '../models/grade.dart';
import '../models/profile_info.dart';
import '../models/timetable_event.dart';
import '../services/grades_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../services/timetable_service.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  ProfileInfo? _profile;
  String? _error;
  bool _isRefreshing = false;
  Future<TimetableEvent?>? _nextEventFuture;
  Future<GradesResult?>? _gradesFuture;

  @override
  void initState() {
    super.initState();
    _load();
    _loadNextEvent();
    _loadGrades();
  }

  void _loadNextEvent() {
    setState(() {
      _nextEventFuture = TimetableService().fetchNextEvent();
    });
  }

  void _loadGrades({bool forceRefresh = false}) {
    setState(() {
      _gradesFuture = _fetchGradesForProgress(forceRefresh: forceRefresh);
    });
  }

  Future<GradesResult?> _fetchGradesForProgress({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await GradesService().loadCached();
      if (cached != null) return cached;
    }
    try {
      return await GradesService().fetchGrades();
    } catch (_) {
      return null;
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!forceRefresh && _profile == null) {
      final cached = await ProfileService().loadCached();
      if (cached != null && mounted) {
        setState(() => _profile = cached);
      }
    }

    if (!mounted) return;
    setState(() => _isRefreshing = true);

    try {
      final fresh = await ProfileService().fetchProfile();
      if (!mounted) return;
      setState(() {
        _profile = fresh;
        _error = null;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        if (_profile == null) _error = e.toString();
      });
      if (_profile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aktualisierung fehlgeschlagen ($e) – zeige zwischengespeichertes Profil.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _refresh() async {
    _loadNextEvent();
    _loadGrades(forceRefresh: true);
    await _load(forceRefresh: true);
  }

  Widget _buildNextEventCard() {
    return FutureBuilder<TimetableEvent?>(
      future: _nextEventFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            snapshot.data == null) {
          return const SizedBox.shrink();
        }
        return _NextEventCard(event: snapshot.data!);
      },
    );
  }

  Widget _buildEctsCard() {
    return FutureBuilder<GradesResult?>(
      future: _gradesFuture,
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (result == null) return const SizedBox.shrink();
        return _EctsProgressCard(result: result);
      },
    );
  }

  Widget _buildProfileCard() {
    if (_profile == null && _error != null) {
      return _ErrorCard(message: _error!, onRetry: _refresh);
    }
    if (_profile == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return _ProfileCard(profile: _profile!);
  }

  Widget _buildPlatformsCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FHV-Links',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        const _PlatformLinksCard(),
      ],
    );
  }

  Widget _buildCard(BuildContext context, DashboardCardType type) {
    switch (type) {
      case DashboardCardType.nextEvent:
        return _buildNextEventCard();
      case DashboardCardType.ectsProgress:
        return _buildEctsCard();
      case DashboardCardType.profile:
        return _buildProfileCard();
      case DashboardCardType.platforms:
        return _buildPlatformsCard(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ValueListenableBuilder<List<DashboardCardConfig>>(
              valueListenable: SettingsService().dashboardCards,
              builder: (context, cards, _) {
                final visible = cards.where((c) => c.visible).toList();
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: visible.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, i) =>
                      _buildCard(context, visible[i].type),
                );
              },
            ),
          ),
        ),
      ],
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

class _NextEventCard extends StatelessWidget {
  const _NextEventCard({required this.event});
  final TimetableEvent event;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOngoing =
        now.isAfter(event.startDate) && now.isBefore(event.endDate);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: event.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isOngoing
                              ? Icons.play_circle_outline
                              : Icons.schedule_outlined,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOngoing
                              ? 'Läuft gerade'
                              : 'Nächste Veranstaltung — ${_relativeDay(event.startDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.eventName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        Text(
                          '${_t(event.startDate)} – ${_t(event.endDate)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (event.rooms.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.room_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [event.rooms].join(' · '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Text(event.lecturers),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _t(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _relativeDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Heute';
    if (diff == 1) return 'Morgen';

    final monday = today.subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    if (!day.isBefore(monday) && !day.isAfter(sunday)) {
      const weekdays = [
        'Montag',
        'Dienstag',
        'Mittwoch',
        'Donnerstag',
        'Freitag',
        'Samstag',
        'Sonntag',
      ];
      return weekdays[d.weekday - 1];
    }

    return _fmtDate(d);
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez',
    ];
    final base = '${d.day}. ${months[d.month - 1]}';
    return d.year == DateTime.now().year ? base : '$base ${d.year}';
  }
}

class _EctsProgressCard extends StatelessWidget {
  const _EctsProgressCard({required this.result});
  final GradesResult result;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: SettingsService().targetEcts,
      builder: (context, targetEcts, _) {
        // FHV's own "possible credits" total is 0 for some study programs
        // (server-side target isn't configured) — fall back to the
        // user-configured target from Settings in that case.
        final total = result.totalCredits ?? targetEcts;
        return _buildCard(context, total);
      },
    );
  }

  Widget _buildCard(BuildContext context, int total) {
    final colorScheme = Theme.of(context).colorScheme;
    final earned = result.earnedCredits;
    final progress = total > 0 ? (earned / total).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Studienfortschritt',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Text(
                  '$percent %',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$earned / $total ECTS',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
