class PersonProfile {
  PersonProfile({
    required this.id,
    required this.name,
    required this.relationship,
    this.contactInfo,
    this.notes,
    this.createdAt,
    this.lastInteractionAt,
  });

  final String id;
  final String name;
  final String relationship;
  final String? contactInfo;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? lastInteractionAt;

  factory PersonProfile.create({
    required String name,
    required String relationship,
    String? contactInfo,
    String? notes,
  }) {
    return PersonProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      relationship: relationship,
      contactInfo: contactInfo,
      notes: notes,
      createdAt: DateTime.now(),
      lastInteractionAt: DateTime.now(),
    );
  }

  PersonProfile copyWith({
    String? id,
    String? name,
    String? relationship,
    String? contactInfo,
    String? notes,
    DateTime? createdAt,
    DateTime? lastInteractionAt,
  }) {
    return PersonProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      contactInfo: contactInfo ?? this.contactInfo,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'contactInfo': contactInfo,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'lastInteractionAt': lastInteractionAt?.toIso8601String(),
    };
  }

  factory PersonProfile.fromMap(Map<String, dynamic> map) {
    return PersonProfile(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      relationship: map['relationship'] as String? ?? '',
      contactInfo: map['contactInfo'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] == null
          ? null
          : DateTime.tryParse(map['createdAt'] as String),
      lastInteractionAt: map['lastInteractionAt'] == null
          ? null
          : DateTime.tryParse(map['lastInteractionAt'] as String),
    );
  }
}
