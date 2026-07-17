import 'package:flutter/material.dart';

import '../../models/room_availability.dart';

class RoomCard extends StatelessWidget {
  const RoomCard({required this.room, required this.requestedHours, super.key});
  final RoomAvailability room;
  final int requestedHours;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final meetsRequest =
        room.freeFor == null ||
        room.freeFor! >= Duration(hours: requestedHours);

    final String subtitle;
    if (room.busyAgainAt == null) {
      subtitle = 'Ganztägig frei';
    } else {
      final hrs = room.freeFor!.inMinutes / 60.0;
      subtitle =
          'Frei bis ${_t(room.busyAgainAt!)} (~${hrs.toStringAsFixed(1)}h)';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          Icons.meeting_room_outlined,
          color: meetsRequest
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          room.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: meetsRequest
            ? Icon(Icons.check_circle, color: colorScheme.primary)
            : null,
      ),
    );
  }

  static String _t(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
