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

  factory PartialGrade.fromJson(Map<String, dynamic> json) => PartialGrade(
        bezeichnung: json['bezeichnung'] as String,
        gewichtung: json['gewichtung'] as String,
        bewertung: json['bewertung'] as String,
        teilbewertung: json['teilbewertung'] as String,
        note: json['note'] as String,
      );

  Map<String, dynamic> toJson() => {
        'bezeichnung': bezeichnung,
        'gewichtung': gewichtung,
        'bewertung': bewertung,
        'teilbewertung': teilbewertung,
        'note': note,
      };
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

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        modul: json['modul'] as String,
        status: json['status'] as String,
        note: json['note'] as String,
        bewertung: json['bewertung'] as String,
        teilbewertung: json['teilbewertung'] as String,
        credits: json['credits'] as String,
        versuch: json['versuch'] as String,
        datum: json['datum'] as String,
        semester: json['semester'] as String,
        durchschnitt: json['durchschnitt'] as String,
        anerkennung: json['anerkennung'] as String,
        teilnoten: (json['teilnoten'] as List)
            .map((e) => PartialGrade.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'modul': modul,
        'status': status,
        'note': note,
        'bewertung': bewertung,
        'teilbewertung': teilbewertung,
        'credits': credits,
        'versuch': versuch,
        'datum': datum,
        'semester': semester,
        'durchschnitt': durchschnitt,
        'anerkennung': anerkennung,
        'teilnoten': teilnoten.map((t) => t.toJson()).toList(),
      };
}

/// A detected difference between a previously cached grade and the
/// freshly fetched one — either a brand-new graded module or a module
/// whose assessment changed.
class GradeChange {
  final String modul;
  final String? oldNote;
  final String newNote;
  final bool isNew;

  const GradeChange({
    required this.modul,
    required this.oldNote,
    required this.newNote,
    required this.isNew,
  });
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

  factory GradesResult.fromJson(Map<String, dynamic> json) => GradesResult(
        grades: (json['grades'] as List)
            .map((e) => Grade.fromJson(e as Map<String, dynamic>))
            .toList(),
        earnedCredits: json['earnedCredits'] as int,
        totalCredits: json['totalCredits'] as int?,
        gradeAverage: (json['gradeAverage'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'grades': grades.map((g) => g.toJson()).toList(),
        'earnedCredits': earnedCredits,
        'totalCredits': totalCredits,
        'gradeAverage': gradeAverage,
      };
}
