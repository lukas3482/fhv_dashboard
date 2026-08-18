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
  static const _mensaTabIndex = 5;

  int _currentIndex = 0;

  static const _otherPages = [
    StundenplanScreen(),
    PruefungstermineScreen(),
    GradesScreen(),
    RoomSearchScreen(),
    MensaScreen(),
  ];

  static const _titles = [
    'Start',
    'Stundenplan',
    'Prüfungstermine',
    'Noten',
    'Räume',
    'Mensa',
  ];

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

  Widget _buildBody() {
    if (_currentIndex == 0) {
      return StartScreen(
        onOpenMensa: () => setState(() => _currentIndex = _mensaTabIndex),
      );
    }
    return _otherPages[_currentIndex - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
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
        selectedIndex: _currentIndex,
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
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Prüfungen',
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
