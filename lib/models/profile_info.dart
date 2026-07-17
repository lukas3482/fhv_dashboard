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

  factory ProfileContact.fromJson(Map<String, dynamic> json) => ProfileContact(
    type: json['type'] as String,
    label: json['label'] as String,
    value: json['value'] as String,
    isPrimary: json['isPrimary'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'label': label,
    'value': value,
    'isPrimary': isPrimary,
  };
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

  factory ProfileInfo.fromJson(Map<String, dynamic> json) => ProfileInfo(
    name: json['name'] as String,
    affiliation: json['affiliation'] as String,
    matriculationNumber: json['matriculationNumber'] as String,
    personKey: json['personKey'] as String,
    contacts: (json['contacts'] as List)
        .map((e) => ProfileContact.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'affiliation': affiliation,
    'matriculationNumber': matriculationNumber,
    'personKey': personKey,
    'contacts': contacts.map((c) => c.toJson()).toList(),
  };
}
