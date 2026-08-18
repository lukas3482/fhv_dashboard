class MensaMenuItem {
  final String category;
  final String title;
  final String description;
  final List<String> allergens;

  const MensaMenuItem({
    required this.category,
    required this.title,
    required this.description,
    required this.allergens,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'title': title,
    'description': description,
    'allergens': allergens,
  };

  factory MensaMenuItem.fromJson(Map<String, dynamic> json) => MensaMenuItem(
    category: json['category'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    allergens:
        (json['allergens'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
  );
}

class MensaDayMenu {
  final String day;
  final List<MensaMenuItem> items;

  const MensaDayMenu({required this.day, required this.items});

  Map<String, dynamic> toJson() => {
    'day': day,
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory MensaDayMenu.fromJson(Map<String, dynamic> json) => MensaDayMenu(
    day: json['day'] as String? ?? '',
    items:
        (json['items'] as List?)
            ?.map((e) => MensaMenuItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}

class MensaWeekMenu {
  final int week;
  final String? dateRangeLabel;
  final List<MensaDayMenu> days;
  final String rawText;
  final DateTime fetchedAt;

  const MensaWeekMenu({
    required this.week,
    required this.dateRangeLabel,
    required this.days,
    required this.rawText,
    required this.fetchedAt,
  });

  bool get isEmpty => days.every((d) => d.items.isEmpty);

  Map<String, dynamic> toJson() => {
    'week': week,
    'dateRangeLabel': dateRangeLabel,
    'days': days.map((d) => d.toJson()).toList(),
    'rawText': rawText,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory MensaWeekMenu.fromJson(Map<String, dynamic> json) => MensaWeekMenu(
    week: json['week'] as int? ?? 0,
    dateRangeLabel: json['dateRangeLabel'] as String?,
    days:
        (json['days'] as List?)
            ?.map((e) => MensaDayMenu.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    rawText: json['rawText'] as String? ?? '',
    fetchedAt:
        DateTime.tryParse(json['fetchedAt'] as String? ?? '') ?? DateTime.now(),
  );
}
