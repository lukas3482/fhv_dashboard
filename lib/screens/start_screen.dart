import 'dart:async';

import 'package:flutter/material.dart';

import '../models/dashboard_card.dart';
import '../models/departure.dart';
import '../models/grade.dart';
import '../models/mensa_menu.dart';
import '../models/profile_info.dart';
import '../models/timetable_event.dart';
import '../services/departure_service.dart';
import '../services/grades_service.dart';
import '../services/mensa_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../services/timetable_service.dart';
import '../widgets/start/dashboard_card_frame.dart';
import '../widgets/start/departures_card.dart';
import '../widgets/start/ects_progress_card.dart';
import '../widgets/start/error_card.dart';
import '../widgets/start/mensa_today_card.dart';
import '../widgets/start/next_event_card.dart';
import '../widgets/start/platform_links_card.dart';
import '../widgets/start/profile_card.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({required this.onOpenMensa, super.key});

  final VoidCallback onOpenMensa;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with WidgetsBindingObserver {
  ProfileInfo? _profile;
  String? _error;
  bool _isRefreshing = false;
  TimetableEvent? _nextEvent;
  bool _nextEventChecked = false;
  Future<GradesResult?>? _gradesFuture;
  Future<MensaDayMenu?>? _mensaFuture;
  List<Departure>? _departures;
  String? _departuresError;
  Timer? _departuresTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _loadNextEvent();
    _loadGrades();
    _loadMensa();
    _departures = DepartureService().cachedDepartures(
      routeFilter: SettingsService().busRouteFilter.value,
    );
    _startDeparturesPolling();
    SettingsService().busRouteFilter.addListener(_onBusFilterChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _departuresTimer?.cancel();
    SettingsService().busRouteFilter.removeListener(_onBusFilterChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No point polling while the app isn't visible; catch up on return.
    if (state == AppLifecycleState.resumed) {
      _startDeparturesPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _departuresTimer?.cancel();
      _departuresTimer = null;
    }
  }

  void _startDeparturesPolling() {
    _departuresTimer?.cancel();
    _loadDepartures();
    _departuresTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadDepartures(),
    );
  }

  void _onBusFilterChanged() {
    setState(() {
      _departures = DepartureService().cachedDepartures(
        routeFilter: SettingsService().busRouteFilter.value,
      );
      _departuresError = null;
    });
    _loadDepartures();
  }

  Future<void> _loadDepartures() async {
    final visible = SettingsService().dashboardCards.value.any(
      (c) => c.type == DashboardCardType.departures && c.visible,
    );
    if (!visible) return;
    try {
      final fresh = await DepartureService().fetchDepartures(
        routeFilter: SettingsService().busRouteFilter.value,
      );
      if (!mounted) return;
      setState(() {
        _departures = fresh;
        _departuresError = null;
      });
    } catch (e) {
      if (!mounted) return;
      // Keep showing the last successful result if we have one.
      setState(
        () => _departuresError = e.toString().replaceFirst('Exception: ', ''),
      );
    }
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

  void _loadMensa({bool forceRefresh = false}) {
    setState(() {
      _mensaFuture = _fetchMensaToday(forceRefresh: forceRefresh);
    });
  }

  Future<MensaDayMenu?> _fetchMensaToday({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await MensaService().loadCachedToday();
      if (cached != null) return cached;
    }
    try {
      return await MensaService().fetchToday();
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    _loadNextEvent(forceRefresh: true);
    _loadGrades(forceRefresh: true);
    _loadMensa(forceRefresh: true);
    _loadDepartures();
    await _load(forceRefresh: true);
  }

  Widget _buildNextEventCard() {
    final event = _nextEvent;
    if (!_nextEventChecked || event == null) return const SizedBox.shrink();
    return NextEventCard(event: event);
  }

  Widget _buildMensaCard() {
    return FutureBuilder<MensaDayMenu?>(
      future: _mensaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        return MensaTodayCard(day: snapshot.data, onTap: widget.onOpenMensa);
      },
    );
  }

  Widget _buildDeparturesCard() {
    return DeparturesCard(
      departures: _departures,
      error: _departuresError,
      filtered: SettingsService().busRouteFilter.value.isNotEmpty,
      onRetry: () {
        setState(() => _departuresError = null);
        _loadDepartures();
      },
    );
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
      return ErrorCard(
        icon: Icons.person_outline,
        title: 'Profil',
        message: _error!,
        onRetry: _refresh,
      );
    }
    if (_profile == null) {
      return const DashboardCardFrame(
        icon: Icons.person_outline,
        title: 'Profil',
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ProfileCard(profile: _profile!);
  }

  Widget _buildCard(BuildContext context, DashboardCardType type) {
    switch (type) {
      case DashboardCardType.nextEvent:
        return _buildNextEventCard();
      case DashboardCardType.mensaToday:
        return _buildMensaCard();
      case DashboardCardType.departures:
        return _buildDeparturesCard();
      case DashboardCardType.ectsProgress:
        return _buildEctsCard();
      case DashboardCardType.profile:
        return _buildProfileCard();
      case DashboardCardType.platforms:
        return const PlatformLinksCard();
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
