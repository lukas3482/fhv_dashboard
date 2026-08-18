import 'package:flutter/material.dart';

import '../../models/mensa_menu.dart';
import '../../utils/mensa_category_style.dart';

class DayMenuCard extends StatelessWidget {
  const DayMenuCard({required this.day, this.isToday = false, super.key});

  final MensaDayMenu day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (day.items.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            Icons.event_busy_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          title: Text(
            day.day,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text('Kein Angebot gefunden.'),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: isToday ? 2 : 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isToday
            ? BorderSide(color: colorScheme.primary, width: 1.5)
            : BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            color: isToday
                ? colorScheme.primary.withValues(alpha: 0.12)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            child: Row(
              children: [
                Text(
                  day.day,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isToday ? colorScheme.primary : null,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Heute',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < day.items.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _MenuItemTile(item: day.items[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({required this.item});

  final MensaMenuItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = mensaCategoryStyleFor(item.category, colorScheme);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: style.background,
            shape: BoxShape.circle,
          ),
          child: Icon(style.icon, size: 18, color: style.foreground),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.category,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: style.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 1.25,
                ),
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (item.allergens.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final code in item.allergens)
                      Tooltip(
                        message: mensaAllergenNames[code] ?? code,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            code,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
