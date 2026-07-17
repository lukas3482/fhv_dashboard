import 'package:flutter/material.dart';

class HourAxis extends StatelessWidget {
  const HourAxis({
    required this.startHour,
    required this.endHour,
    required this.pxPerHour,
    super.key,
  });

  final int startHour;
  final int endHour;
  final double pxPerHour;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var h = startHour; h <= endHour; h++)
          Positioned(
            top: (h - startHour) * pxPerHour - 7,
            left: 0,
            right: 4,
            child: Text(
              '$h:00',
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
