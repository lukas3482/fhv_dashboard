class PartialGrade {
  final String bezeichnung;
  final String gewichtung;
  final String bewertung;
  final String teilbewertung;
  final String note;

  const PartialGrade({
    required this.bezeichnung,
    required this.gewichtung,
    required this.bewertung,
    required this.teilbewertung,
    required this.note,
  });
}

class Grade {
  final String modul;
  final String status;
  final String note;
  final String bewertung;
  final String teilbewertung;
  final String credits;
  final String versuch;
  final String datum;
  final String semester;
  final String durchschnitt;
  final String anerkennung;
  final List<PartialGrade> teilnoten;

  const Grade({
    required this.modul,
    required this.status,
    required this.note,
    required this.bewertung,
    required this.teilbewertung,
    required this.credits,
    required this.versuch,
    required this.datum,
    required this.semester,
    required this.durchschnitt,
    required this.anerkennung,
    this.teilnoten = const [],
  });

  bool get hasPassed =>
      bewertung.isNotEmpty &&
      !bewertung.contains('Nicht') &&
      bewertung != '-' &&
      !bewertung.toLowerCase().contains('folgt');
}

class GradesResult {
  final List<Grade> grades;
  final int earnedCredits;
  final int? totalCredits;
  final double? gradeAverage;

  const GradesResult({
    required this.grades,
    required this.earnedCredits,
    this.totalCredits,
    this.gradeAverage,
  });
}
