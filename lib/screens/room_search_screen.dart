import 'package:flutter/material.dart';

import '../models/room_availability.dart';
import '../models/timetable_event.dart';
import '../services/room_search_service.dart';

enum _RoomSearchMode { free, schedule }

class RoomSearchScreen extends StatefulWidget {
  const RoomSearchScreen({super.key});

  @override
  State<RoomSearchScreen> createState() => _RoomSearchScreenState();
}

class _RoomSearchScreenState extends State<RoomSearchScreen> {
  static const _hourOptions = [1, 2, 3, 4, 6];

  _RoomSearchMode _mode = _RoomSearchMode.free;
  DateTime _date = DateTime.now();
  int _hours = 2;
  RoomInfo? _selectedRoom;

  Future<List<RoomAvailability>>? _resultsFuture;
  Future<List<TimetableEvent>>? _scheduleFuture;

  void _search() {
    setState(() {
      _resultsFuture = RoomSearchService().findFreeRooms(
        date: _date,
        hoursToCheck: _hours,
      );
    });
  }

  void _searchSchedule() {
    final room = _selectedRoom;
    if (room == null) return;
    setState(() {
      _scheduleFuture = RoomSearchService().fetchRoomSchedule(
        room: room,
        date: _date,
      );
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<_RoomSearchMode>(
                segments: const [
                  ButtonSegment(
                    value: _RoomSearchMode.free,
                    label: Text('Freie Räume'),
                    icon: Icon(Icons.search),
                  ),
                  ButtonSegment(
                    value: _RoomSearchMode.schedule,
                    label: Text('Raumplan'),
                    icon: Icon(Icons.event_note_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(_fmtDate(_date)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_mode == _RoomSearchMode.free)
          _FreeRoomControls(
            hours: _hours,
            hourOptions: _hourOptions,
            onHoursChanged: (h) => setState(() => _hours = h),
            onSearch: _search,
          )
        else
          _RoomScheduleControls(
            selectedRoom: _selectedRoom,
            onRoomSelected: (r) => setState(() => _selectedRoom = r),
            onSearch: _searchSchedule,
          ),
        const Divider(height: 1),
        Expanded(
          child: _mode == _RoomSearchMode.free
              ? _buildFreeResults()
              : _buildScheduleResults(),
        ),
      ],
    );
  }

  Widget _buildFreeResults() {
    if (_resultsFuture == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Datum und gewünschte Dauer wählen und auf „Räume suchen“ '
            'tippen.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return FutureBuilder<List<RoomAvailability>>(
      future: _resultsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _search,
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          );
        }

        final rooms = snapshot.data!;
        if (rooms.isEmpty) {
          return const Center(child: Text('Keine freien Räume gefunden.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          itemCount: rooms.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RoomCard(room: rooms[i], requestedHours: _hours),
          ),
        );
      },
    );
  }

  Widget _buildScheduleResults() {
    if (_scheduleFuture == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Raum eingeben und auf „Anzeigen“ tippen, um dessen Belegung '
            'zu sehen.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return FutureBuilder<List<TimetableEvent>>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _searchSchedule,
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          );
        }

        final events = snapshot.data!;
        if (events.isEmpty) {
          return const Center(
            child: Text('Keine Termine für diesen Raum an diesem Tag.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          itemCount: events.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RoomEventCard(event: events[i]),
          ),
        );
      },
    );
  }
}

String _fmtDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  if (day == today) return 'Heute';
  if (day == today.add(const Duration(days: 1))) return 'Morgen';
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
  return '${d.day}. ${months[d.month - 1]} ${d.year}';
}

class _FreeRoomControls extends StatelessWidget {
  const _FreeRoomControls({
    required this.hours,
    required this.hourOptions,
    required this.onHoursChanged,
    required this.onSearch,
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

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.requestedHours});
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

class _RoomScheduleControls extends StatelessWidget {
  const _RoomScheduleControls({
    required this.selectedRoom,
    required this.onRoomSelected,
    required this.onSearch,
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

class _RoomEventCard extends StatelessWidget {
  const _RoomEventCard({required this.event});
  final TimetableEvent event;

  @override
  Widget build(BuildContext context) {
    final timeStr = '${_t(event.startDate)} – ${_t(event.endDate)}';

    return Card(
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: event.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (event.occasion.isNotEmpty)
                          _Chip(event.occasion, event.color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.eventName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (event.lecturers.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.lecturers,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _t(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
