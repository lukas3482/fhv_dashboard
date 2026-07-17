import 'package:flutter/material.dart';

import '../models/dashboard_card.dart';
import '../models/grade.dart';
import '../models/profile_info.dart';
import '../models/timetable_event.dart';
import '../services/grades_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../services/timetable_service.dart';
import '../widgets/start/ects_progress_card.dart';
import '../widgets/start/error_card.dart';
import '../widgets/start/next_event_card.dart';
import '../widgets/start/platform_links_card.dart';
import '../widgets/start/profile_card.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  ProfileInfo? _profile;
  String? _error;
  bool _isRefreshing = false;
  TimetableEvent? _nextEvent;
  bool _nextEventChecked = false;
  Future<GradesResult?>? _gradesFuture;

  @override
  void initState() {
    super.initState();
    _load();
    _loadNextEvent();
    _loadGrades();
  }

  Future<void> _loadNextEvent({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await TimetableService().loadCachedNextEvent();
      if (cached != null && mounted) {
        setState(() {
          _nextEvent = cached;
          _nextEventChecked = true;
        });
      }
    }

    try {
      final fresh = await TimetableService().fetchNextEvent();
      if (!mounted) return;
      setState(() {
        _nextEvent = fresh;
        _nextEventChecked = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _nextEventChecked = true);
    }
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
    _loadNextEvent(forceRefresh: true);
    _loadGrades(forceRefresh: true);
    await _load(forceRefresh: true);
  }

  Widget _buildNextEventCard() {
    final event = _nextEvent;
    if (!_nextEventChecked || event == null) return const SizedBox.shrink();
    return NextEventCard(event: event);
  }

  Widget _buildEctsCard() {
    return FutureBuilder<GradesResult?>(
      future: _gradesFuture,
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (result == null) return SizedBox.shrink();
        return EctsProgressCard(result: result);
      },
    );
  }

  Widget _buildProfileCard() {
    if (_profile == null && _error != null) {
      return ErrorCard(message: _error!, onRetry: _refresh);
    }
    if (_profile == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ProfileCard(profile: _profile!);
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
        const PlatformLinksCard(),
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
