import 'package:flutter/material.dart';

import '../../services/settings_service.dart';

class WeekHeader extends StatelessWidget {
  const WeekHeader({
    required this.start,
    required this.end,
    required this.isToday,
    required this.viewMode,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onViewModeChanged,
    super.key,
  });

  final DateTime start;
  final DateTime end;
  final bool isToday;
  final StundenplanViewMode viewMode;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<StundenplanViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: onPrev,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_fmtDay(start)} – ${_fmtDay(end)} ${end.year}',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: isToday ? null : onToday,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Heute'),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onNext,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SegmentedButton<StundenplanViewMode>(
                segments: const [
                  ButtonSegment(
                    value: StundenplanViewMode.list,
                    icon: Icon(Icons.view_agenda_outlined),
                    label: Text('Liste'),
                  ),
                  ButtonSegment(
                    value: StundenplanViewMode.grid,
                    icon: Icon(Icons.calendar_view_week_outlined),
                    label: Text('Raster'),
                  ),
                ],
                selected: {viewMode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => onViewModeChanged(s.first),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDay(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez',
    ];
    return '${d.day}. ${months[d.month - 1]}';
  }
}
