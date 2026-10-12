class Departure {
  final String line;
  final String direction;
  final DateTime plannedTime;

  final DateTime? realtimeTime;
  final bool cancelled;
  final String? platform;

  final String? stopName;

  const Departure({
    required this.line,
    required this.direction,
    required this.plannedTime,
    required this.realtimeTime,
    required this.cancelled,
    required this.platform,
    required this.stopName,
  });

  DateTime get expectedTime => realtimeTime ?? plannedTime;

  bool get hasRealtime => realtimeTime != null;

  int get delayMinutes => realtimeTime == null
      ? 0
      : realtimeTime!.difference(plannedTime).inMinutes;
}

class BusRoute implements Comparable<BusRoute> {
  final String line;
  final String direction;

  const BusRoute({required this.line, required this.direction});

  factory BusRoute.of(Departure d) =>
      BusRoute(line: d.line, direction: d.direction);

  factory BusRoute.fromKey(String key) {
    final i = key.indexOf('|');
    return BusRoute(line: key.substring(0, i), direction: key.substring(i + 1));
  }

  String get key => '$line|$direction';

  @override
  bool operator ==(Object other) => other is BusRoute && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  int compareTo(BusRoute other) {
    final a = int.tryParse(line);
    final b = int.tryParse(other.line);
    final byLine = a != null && b != null
        ? a.compareTo(b)
        : a != null
        ? -1
        : b != null
        ? 1
        : line.compareTo(other.line);
    return byLine != 0 ? byLine : direction.compareTo(other.direction);
  }
}
