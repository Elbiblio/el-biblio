enum MissionFocusType {
  service,
  faithSharing,
  encouragement,
}

extension MissionFocusTypeX on MissionFocusType {
  static String normalizeStorageValue(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return MissionFocusType.service.name;
    }

    switch (normalized.toLowerCase()) {
      case 'service':
      case 'acts of service':
      case 'general service':
      case 'service & stewardship':
      case 'care & compassion':
        return MissionFocusType.service.name;
      case 'faithsharing':
      case 'faithsharing ': 
        return MissionFocusType.faithSharing.name;
      case 'faith sharing':
      case 'teaching & discipleship':
      case 'justice & protection':
        return MissionFocusType.faithSharing.name;
      case 'encouragement':
      case 'creative expression':
      case 'leadership & guidance':
        return MissionFocusType.encouragement.name;
      default:
        return MissionFocusType.values.any((item) => item.name == normalized)
            ? normalized
            : MissionFocusType.service.name;
    }
  }

  static MissionFocusType fromStorage(String? value) {
    final normalized = normalizeStorageValue(value);
    for (final item in MissionFocusType.values) {
      if (item.name == normalized) {
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
