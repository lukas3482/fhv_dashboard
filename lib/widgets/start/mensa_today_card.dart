import 'package:flutter/material.dart';

import '../../models/mensa_menu.dart';
import '../../utils/mensa_category_style.dart';

class MensaTodayCard extends StatelessWidget {
  const MensaTodayCard({required this.day, required this.onTap, super.key});

  final MensaDayMenu? day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasData = day != null;
    final accent = hasData ? colorScheme.primary : colorScheme.outline;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withValues(alpha: hasData ? 0.4 : 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              color: accent.withValues(alpha: hasData ? 0.12 : 0.06),
              child: Row(
                children: [
                  Icon(Icons.restaurant_outlined, size: 16, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    'Mensa heute',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: hasData
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < day!.items.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _MensaItemRow(item: day!.items[i]),
                        ],
                      ],
                    )
                  : Text(
                      'Kein Mensaplan für heute',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MensaItemRow extends StatelessWidget {
  const _MensaItemRow({required this.item});

  final MensaMenuItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = mensaCategoryStyleFor(item.category, colorScheme);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: style.background,
            shape: BoxShape.circle,
          ),
          child: Icon(style.icon, size: 14, color: style.foreground),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.category,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: style.foreground,
                ),
              ),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
