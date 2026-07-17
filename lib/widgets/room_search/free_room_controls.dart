import 'package:flutter/material.dart';

class FreeRoomControls extends StatelessWidget {
  const FreeRoomControls({
    required this.hours,
    required this.hourOptions,
    required this.onHoursChanged,
    required this.onSearch,
    super.key,
  });

  final int hours;
  final List<int> hourOptions;
  final ValueChanged<int> onHoursChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mindestens frei für',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final h in hourOptions)
                ChoiceChip(
                  label: Text('${h}h'),
                  selected: hours == h,
                  onSelected: (_) => onHoursChanged(h),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search),
              label: const Text('Räume suchen'),
            ),
          ),
        ],
      ),
    );
  }
}
