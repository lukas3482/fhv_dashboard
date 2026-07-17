import 'package:flutter/material.dart';

import '../models/room_availability.dart';
import '../models/timetable_event.dart';
import '../services/room_search_service.dart';
import '../widgets/room_search/free_room_controls.dart';
import '../widgets/room_search/room_card.dart';
import '../widgets/room_search/room_event_card.dart';
import '../widgets/room_search/room_schedule_controls.dart';

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
          FreeRoomControls(
            hours: _hours,
            hourOptions: _hourOptions,
            onHoursChanged: (h) => setState(() => _hours = h),
            onSearch: _search,
          )
        else
          RoomScheduleControls(
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
            child: RoomCard(room: rooms[i], requestedHours: _hours),
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
            child: RoomEventCard(event: events[i]),
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
