import 'package:flutter/material.dart';

import 'dashboard_card_frame.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
    super.key,
  });
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardCardFrame(
      icon: icon,
      title: title,
      muted: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 32, color: colorScheme.error),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}
