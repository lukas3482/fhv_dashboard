import 'package:flutter/material.dart';

import '../models/grade.dart';
import '../services/grades_service.dart';
import '../widgets/grades/changes_banner.dart';
import '../widgets/grades/grade_card.dart';
import '../widgets/grades/semester_header.dart';
import '../widgets/grades/summary_card.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  GradesResult? _result;
  String? _error;
  bool _isRefreshing = false;
  List<GradeChange> _changes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!forceRefresh && _result == null) {
      final cached = await GradesService().loadCached();
      if (cached != null && mounted) {
        setState(() => _result = cached);
      }
    }

    if (!mounted) return;
    setState(() => _isRefreshing = true);

    try {
      final (fresh, changes) = await GradesService().fetchGradesDetailed();
      if (!mounted) return;
      setState(() {
        _result = fresh;
        _error = null;
        _isRefreshing = false;
        if (changes.isNotEmpty) _changes = changes;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        if (_result == null) _error = e.toString();
      });
      if (_result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aktualisierung fehlgeschlagen ($e) – zeige zwischengespeicherte Noten.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _refresh() => _load(forceRefresh: true);

  void _dismissChanges() => setState(() => _changes = []);

  @override
  Widget build(BuildContext context) {
    if (_result == null && _error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _refresh,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    final result = _result;
    if (result == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget body;
    if (result.grades.isEmpty) {
      body = const Center(child: Text('Keine Noten gefunden.'));
    } else {
      final grouped = _groupBySemester(result.grades);
      final semesters = _sortedSemesters(grouped);

      final items = <Object>[
        if (_changes.isNotEmpty) _changes,
        SummaryCard(result: result),
      ];
      for (final semester in semesters) {
        items.add(semester);
        items.addAll(grouped[semester]!);
      }

      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is List<GradeChange>) {
            return ChangesBanner(changes: item, onDismiss: _dismissChanges);
          }
          if (item is SummaryCard) return item;
          if (item is String) return SemesterHeader(semester: item);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GradeCard(grade: item as Grade),
          );
        },
      );
    }

    return Column(
      children: [
        if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(onRefresh: _refresh, child: body),
        ),
      ],
    );
  }
}

int _semesterSortValue(String semester) {
  final s = semester.trim();
  final isWinter = s.startsWith('WS') || s.toLowerCase().startsWith('winter');
  final match = RegExp(r'(\d{4})').firstMatch(s);
  if (match == null) return -1;
  final year = int.parse(match.group(1)!);
  return year * 2 + (isWinter ? 1 : 0);
}

Map<String, List<Grade>> _groupBySemester(List<Grade> grades) {
  final map = <String, List<Grade>>{};
  for (final grade in grades) {
    final key = grade.semester.isEmpty ? 'Unbekannt' : grade.semester;
    map.putIfAbsent(key, () => []).add(grade);
  }
  return map;
}

List<String> _sortedSemesters(Map<String, List<Grade>> grouped) {
  return grouped.keys.toList()
    ..sort((a, b) => _semesterSortValue(b).compareTo(_semesterSortValue(a)));
}
