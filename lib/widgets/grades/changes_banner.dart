import 'package:flutter/material.dart';

import '../../models/grade.dart';

class ChangesBanner extends StatelessWidget {
  const ChangesBanner({
    required this.changes,
    required this.onDismiss,
    super.key,
  });
  final List<GradeChange> changes;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onColor = colorScheme.onTertiaryContainer;

    return Card(
      color: colorScheme.tertiaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active_outlined, color: onColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    changes.length == 1
                        ? 'Notenänderung'
                        : '${changes.length} Notenänderungen',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: onColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: onColor, size: 20),
                  onPressed: onDismiss,
                  tooltip: 'Ausblenden',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            for (final change in changes)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 2),
                child: Text(
                  change.isNew || change.oldNote == null
                      ? '${change.modul}: ${change.newNote}'
                      : '${change.modul}: ${change.oldNote} → ${change.newNote}',
                  style: TextStyle(color: onColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
