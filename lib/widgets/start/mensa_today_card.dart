import 'package:flutter/material.dart';

import '../../models/mensa_menu.dart';
import '../../utils/mensa_category_style.dart';
import 'dashboard_card_frame.dart';

class MensaTodayCard extends StatelessWidget {
  const MensaTodayCard({required this.day, required this.onTap, super.key});

  final MensaDayMenu? day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasData = day != null;

    return DashboardCardFrame(
      icon: Icons.restaurant_outlined,
      title: 'Mensa heute',
      onTap: onTap,
      muted: !hasData,
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
