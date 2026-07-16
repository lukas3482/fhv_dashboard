enum DashboardCardType { nextEvent, ectsProgress, profile, platforms }

extension DashboardCardTypeLabel on DashboardCardType {
  String get label {
    switch (this) {
      case DashboardCardType.nextEvent:
        return 'Nächste Veranstaltung';
      case DashboardCardType.ectsProgress:
        return 'Studienfortschritt';
      case DashboardCardType.profile:
        return 'Profil';
      case DashboardCardType.platforms:
        return 'FHV-Plattformen';
    }
  }
}

class DashboardCardConfig {
  final DashboardCardType type;
  final bool visible;

  const DashboardCardConfig({required this.type, required this.visible});

  DashboardCardConfig copyWith({bool? visible}) =>
      DashboardCardConfig(type: type, visible: visible ?? this.visible);
}
