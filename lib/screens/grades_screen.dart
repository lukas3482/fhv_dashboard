import 'package:flutter/material.dart';

import '../models/grade.dart';
import '../services/grades_service.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  GradesResult? _result;
  String? _error;
  bool _isRefreshing = false;

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
      final fresh = await GradesService().fetchGrades();
      if (!mounted) return;
      setState(() {
        _result = fresh;
        _error = null;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        if (_result == null) _error = e.toString();
      });
      if (_result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aktualisierung fehlgeschlagen – zeige zwischengespeicherte Noten.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _refresh() => _load(forceRefresh: true);

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

      final items = <Object>[_SummaryCard(result: result)];
      for (final semester in semesters) {
        items.add(semester);
        items.addAll(grouped[semester]!);
      }

      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is _SummaryCard) return item;
          if (item is String) return _SemesterHeader(semester: item);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _GradeCard(grade: item as Grade),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result});
  final GradesResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final creditsLabel = result.totalCredits != null
        ? '${result.earnedCredits} / ${result.totalCredits}'
        : '${result.earnedCredits}';
    final avgLabel = result.gradeAverage != null
        ? result.gradeAverage!.toStringAsFixed(2).replaceAll('.', ',')
        : '–';

    return Card(
      color: colorScheme.primaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: _StatColumn(
                value: creditsLabel,
                label: 'Erzielte ECTS',
                valueColor: colorScheme.onPrimaryContainer,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _StatColumn(
                value: avgLabel,
                label: 'Notenschnitt',
                valueColor: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.valueColor,
  });
  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: valueColor.withValues(alpha: 0.75),
          ),
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

class _SemesterHeader extends StatelessWidget {
  const _SemesterHeader({required this.semester});
  final String semester;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        semester,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.grade});
  final Grade grade;

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _GradeDetailSheet(grade: grade),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final noteText = grade.note.isNotEmpty ? grade.note : '–';
    final hasNote = grade.note.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade.modul,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      'Bewertung',
                      grade.bewertung.isEmpty ? '–' : grade.bewertung,
                    ),
                    if (grade.credits.isNotEmpty)
                      _InfoRow('Credits', grade.credits),
                    if (grade.durchschnitt.isNotEmpty)
                      _InfoRow('Ø', grade.durchschnitt),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasNote
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  noteText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: hasNote
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeDetailSheet extends StatelessWidget {
  const _GradeDetailSheet({required this.grade});
  final Grade grade;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final noteText = grade.note.isNotEmpty ? grade.note : '–';
    final hasNote = grade.note.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      grade.modul,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hasNote
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      noteText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: hasNote
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow('Bewertung', grade.bewertung),
              _DetailRow('Status', grade.status),
              _DetailRow('Credits', grade.credits),
              _DetailRow('Durchschnitt', grade.durchschnitt),
              _DetailRow('Versuch', grade.versuch),
              _DetailRow('Datum', grade.datum),
              _DetailRow('Semester', grade.semester),
              _DetailRow('Anerkennung', grade.anerkennung),
              if (grade.teilnoten.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Teilnoten',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...grade.teilnoten.map((t) => _PartialGradeRow(t)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

class _PartialGradeRow extends StatelessWidget {
  const _PartialGradeRow(this.teilnote);
  final PartialGrade teilnote;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              teilnote.gewichtung,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              teilnote.bezeichnung.isEmpty ? '–' : teilnote.bezeichnung,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            teilnote.bewertung.isNotEmpty
                ? teilnote.bewertung
                : teilnote.teilbewertung,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
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
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
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
