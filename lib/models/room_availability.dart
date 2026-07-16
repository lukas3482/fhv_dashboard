class RoomAvailability {
  final String name;
  final Duration? freeFor;
  final DateTime? busyAgainAt;

  const RoomAvailability({
    required this.name,
    required this.freeFor,
    required this.busyAgainAt,
  });
}
