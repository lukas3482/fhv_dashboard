import 'package:flutter/material.dart';

import '../../models/grade.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({required this.result, super.key});
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
              child: StatColumn(
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
              child: StatColumn(
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

class StatColumn extends StatelessWidget {
  const StatColumn({
    required this.value,
    required this.label,
    required this.valueColor,
    super.key,
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
