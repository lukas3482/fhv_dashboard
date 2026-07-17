import 'package:flutter/material.dart';

import '../../models/grade.dart';
import '../../services/settings_service.dart';

class EctsProgressCard extends StatelessWidget {
  const EctsProgressCard({required this.result, super.key});
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
