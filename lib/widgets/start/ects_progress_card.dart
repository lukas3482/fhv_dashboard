import 'package:flutter/material.dart';

import '../../models/grade.dart';
import '../../services/settings_service.dart';
import 'dashboard_card_frame.dart';

class EctsProgressCard extends StatelessWidget {
  const EctsProgressCard({required this.result, super.key});
  final GradesResult result;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: SettingsService().targetEcts,
      builder: (context, targetEcts, _) {
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

    return DashboardCardFrame(
      icon: Icons.school_outlined,
      title: 'Studienfortschritt',
      trailing: Text(
        '$percent %',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
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
    );
  }
}
