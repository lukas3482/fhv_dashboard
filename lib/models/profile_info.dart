class ProfileContact {
  final String type; // 'email' or 'phone'
  final String label;
  final String value;
  final bool isPrimary;

  const ProfileContact({
    required this.type,
    required this.label,
    required this.value,
    required this.isPrimary,
  });
}

class ProfileInfo {
  final String name;
  final String affiliation;
  final String matriculationNumber;
  final String personKey;
  final List<ProfileContact> contacts;

  const ProfileInfo({
    required this.name,
    required this.affiliation,
    required this.matriculationNumber,
    required this.personKey,
    required this.contacts,
  });
}
