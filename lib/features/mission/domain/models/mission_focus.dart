enum MissionFocusType {
  service,
  faithSharing,
  encouragement,
}

extension MissionFocusTypeX on MissionFocusType {
  static MissionFocusType fromStorage(String? value) {
    for (final item in MissionFocusType.values) {
      if (item.name == value) {
        return item;
      }
    }
    return MissionFocusType.service;
  }

  String get label {
    return switch (this) {
      MissionFocusType.service => 'Acts of Service',
      MissionFocusType.faithSharing => 'Faith Sharing',
      MissionFocusType.encouragement => 'Encouragement',
    };
  }

  String get description {
    return switch (this) {
      MissionFocusType.service => 'Serve people in practical ways that reflect the love of Christ.',
      MissionFocusType.faithSharing => 'Start or follow up spiritual conversations with courage and gentleness.',
      MissionFocusType.encouragement => 'Strengthen someone with prayer, care, and intentional follow-through.',
    };
  }

  String get shortLabel {
    return switch (this) {
      MissionFocusType.service => 'Serve',
      MissionFocusType.faithSharing => 'Share',
      MissionFocusType.encouragement => 'Encourage',
    };
  }
}
