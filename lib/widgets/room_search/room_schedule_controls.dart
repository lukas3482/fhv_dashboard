import 'package:flutter/material.dart';

import '../../services/room_search_service.dart';

class RoomScheduleControls extends StatelessWidget {
  const RoomScheduleControls({
    required this.selectedRoom,
    required this.onRoomSelected,
    required this.onSearch,
    super.key,
  });

  final RoomInfo? selectedRoom;
  final ValueChanged<RoomInfo> onRoomSelected;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Autocomplete<RoomInfo>(
            displayStringForOption: (r) => r.name,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              if (query.isEmpty) return const Iterable<RoomInfo>.empty();
              return kUBuildingRooms.where(
                (r) => r.name.toLowerCase().contains(query),
              );
            },
            onSelected: onRoomSelected,
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Raum',
                  hintText: 'z. B. U304',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: selectedRoom == null ? null : onSearch,
              icon: const Icon(Icons.event_note_outlined),
              label: const Text('Anzeigen'),
            ),
          ),
        ],
      ),
    );
  }
}
