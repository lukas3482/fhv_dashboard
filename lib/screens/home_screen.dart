import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/background_service.dart';
import '../services/notification_service.dart';
import '../widgets/home/info_dialog.dart';
import 'grades_screen.dart';
import 'login_screen.dart';
import 'mensa_screen.dart';
import 'pruefungstermine_screen.dart';
import 'room_search_screen.dart';
import 'settings_screen.dart';
import 'start_screen.dart';
import 'stundenplan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _stundenplanTabIndex = 1;
  static const _mensaTabIndex = 4;
  // Not a bottom-nav destination — reached via an action button while on
  // the Stundenplan tab. Kept in the same _currentIndex/AppBar/body
  // machinery as the real tabs so the bottom nav stays visible instead of
  // being replaced by a bare pushed route.
  static const _pruefungstermineIndex = 5;

  int _currentIndex = 0;

  // Pages for tabs 1..4; tab 0 (Start) is built separately since it needs
  // the onOpenMensa callback below.
  static const _otherPages = [
    StundenplanScreen(),
    GradesScreen(),
    RoomSearchScreen(),
    MensaScreen(),
  ];

  static const _titles = ['Start', 'Stundenplan', 'Noten', 'Räume', 'Mensa'];

  @override
  void initState() {
    super.initState();
    NotificationService().requestPermission();
    BackgroundService.initialize();
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showInfoDialog() {
    showDialog(context: context, builder: (context) => const InfoDialog());
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openPruefungstermine() {
    setState(() => _currentIndex = _pruefungstermineIndex);
  }

  void _closePruefungstermine() {
    setState(() => _currentIndex = _stundenplanTabIndex);
  }

  String get _title => _currentIndex == _pruefungstermineIndex
      ? 'Prüfungstermine'
      : _titles[_currentIndex];

  Widget _buildBody() {
    if (_currentIndex == _pruefungstermineIndex) {
      return const PruefungstermineScreen();
    }
    if (_currentIndex == 0) {
      return StartScreen(
        onOpenMensa: () => setState(() => _currentIndex = _mensaTabIndex),
      );
    }
    return _otherPages[_currentIndex - 1];
  }

  @override
  Widget build(BuildContext context) {
    final showingExams = _currentIndex == _pruefungstermineIndex;

    return Scaffold(
      appBar: AppBar(
        leading: showingExams
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Zurück',
                onPressed: _closePruefungstermine,
              )
            : null,
        title: Text(_title),
        actions: [
          if (_currentIndex == _stundenplanTabIndex)
            IconButton(
              icon: const Icon(Icons.assignment_outlined),
              tooltip: 'Prüfungstermine',
              onPressed: _openPruefungstermine,
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Über diese App',
            onPressed: _showInfoDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: showingExams ? _stundenplanTabIndex : _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Stundenplan',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Noten',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Räume',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Mensa',
          ),
        ],
      ),
    );
  }
}
