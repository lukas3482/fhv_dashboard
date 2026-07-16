import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/background_service.dart';
import '../services/notification_service.dart';
import 'grades_screen.dart';
import 'login_screen.dart';
import 'pruefungstermine_screen.dart';
import 'start_screen.dart';
import 'stundenplan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _pages = [
    StartScreen(),
    StundenplanScreen(),
    PruefungstermineScreen(),
    GradesScreen(),
  ];

  static const _titles = ['Start', 'Stundenplan', 'Prüfungstermine', 'Noten'];

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
    showDialog(context: context, builder: (context) => const _InfoDialog());
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
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: _logout,
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Start',
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
        ],
      ),
    );
  }
}

class _InfoDialog extends StatelessWidget {
  const _InfoDialog();

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
            'Diese App ist eine inoffizielle Anwedung und steht in'
            'keinerlei Verbindung zur Fachhochschule Vorarlberg. '
            'Die bereitgestelltenb Informationen, Inhalte und Funktionen'
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
