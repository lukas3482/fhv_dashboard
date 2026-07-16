class ExamAppointment {
  final String name;
  final DateTime? date;
  final String dateStr;
  final String timeStr;
  final String room;
  final String lecturer;
  final String appendix;
  final String comment;
  final bool isRegistered;
  final bool hasSubParts;

  const ExamAppointment({
    required this.name,
    required this.date,
    required this.dateStr,
    required this.timeStr,
    required this.room,
    required this.lecturer,
    required this.appendix,
    required this.comment,
    required this.isRegistered,
    required this.hasSubParts,
  });

  bool get isPast {
    if (date == null) return false;
    return date!.isBefore(DateTime.now());
  }
}
