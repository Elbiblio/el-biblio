/// Represents a commitment to help a specific person
/// Tracks ongoing relationships and service to individuals
class PersonCommitment {
  const PersonCommitment({
    required this.id,
    required this.name,
    required this.relationship,
    required this.createdAt,
    this.notes,
    this.needs,
    this.committedActions = const [],
    this.lastContactAt,
    this.nextFollowUpAt,
    this.isActive = true,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String relationship; // e.g., "Neighbor", "Coworker", "Family", "Stranger"
  final DateTime createdAt;
  final String? notes; // Initial context of how we met/why we're helping
  final String? needs; // What they need help with
  final List<String> committedActions; // IDs of MissionActions tied to this person
  final DateTime? lastContactAt; // Last time we reached out/interacted
  final DateTime? nextFollowUpAt; // Scheduled follow-up date
  final bool isActive;
  final List<String> tags; // e.g., ["elderly", "job-seeking", "spiritual-curious"]

  bool get hasScheduledFollowUp => nextFollowUpAt != null;
  bool get needsFollowUp {
    if (nextFollowUpAt == null) return false;
    return DateTime.now().isAfter(nextFollowUpAt!);
  }

  int get completedActionsCount {
    // This will be calculated by the notifier based on action completion status
    return committedActions.length;
  }

  factory PersonCommitment.fromMap(Map<String, dynamic> map) {
    return PersonCommitment(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      relationship: map['relationship'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      notes: map['notes'] as String?,
      needs: map['needs'] as String?,
      committedActions: (map['committedActions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      lastContactAt: map['lastContactAt'] == null
          ? null
          : DateTime.tryParse(map['lastContactAt'] as String),
      nextFollowUpAt: map['nextFollowUpAt'] == null
          ? null
          : DateTime.tryParse(map['nextFollowUpAt'] as String),
      isActive: map['isActive'] as bool? ?? true,
      tags: (map['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'needs': needs,
      'committedActions': committedActions,
      'lastContactAt': lastContactAt?.toIso8601String(),
      'nextFollowUpAt': nextFollowUpAt?.toIso8601String(),
      'isActive': isActive,
      'tags': tags,
    };
  }

  PersonCommitment copyWith({
    String? id,
    String? name,
    String? relationship,
    DateTime? createdAt,
    String? notes,
    String? needs,
    List<String>? committedActions,
    DateTime? lastContactAt,
    DateTime? nextFollowUpAt,
    bool? isActive,
    List<String>? tags,
  }) {
    return PersonCommitment(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      needs: needs ?? this.needs,
      committedActions: committedActions ?? this.committedActions,
      lastContactAt: lastContactAt ?? this.lastContactAt,
      nextFollowUpAt: nextFollowUpAt ?? this.nextFollowUpAt,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
    );
  }
}

/// Represents a generosity/mercy tracking entry
/// For financial giving, time donated, or resources shared
class GenerosityRecord {
  const GenerosityRecord({
    required this.id,
    required this.type,
    required this.description,
    required this.date,
    this.amount,
    this.currency = 'USD',
    this.recipientName,
    this.recipientType, // "person", "organization", "church", "community"
    this.category, // "tithe", "offering", "mercy", "missions", "community"
    this.isRecurring = false,
    this.recurringFrequency, // "weekly", "monthly", "quarterly"
    this.notes,
    this.impactDescription, // What happened as a result
  });

  final String id;
  final GenerosityType type;
  final String description;
  final DateTime date;
  final double? amount; // For financial giving
  final String currency;
  final String? recipientName;
  final String? recipientType;
  final String? category;
  final bool isRecurring;
  final String? recurringFrequency;
  final String? notes;
  final String? impactDescription;

  bool get isFinancial => type == GenerosityType.financial;
  bool get isTime => type == GenerosityType.time;
  bool get isResource => type == GenerosityType.resource;

  factory GenerosityRecord.fromMap(Map<String, dynamic> map) {
    return GenerosityRecord(
      id: map['id'] as String? ?? '',
      type: GenerosityTypeX.fromStorage(map['type'] as String?),
      description: map['description'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      amount: map['amount'] as double?,
      currency: map['currency'] as String? ?? 'USD',
      recipientName: map['recipientName'] as String?,
      recipientType: map['recipientType'] as String?,
      category: map['category'] as String?,
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurringFrequency: map['recurringFrequency'] as String?,
      notes: map['notes'] as String?,
      impactDescription: map['impactDescription'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'date': date.toIso8601String(),
      'amount': amount,
      'currency': currency,
      'recipientName': recipientName,
      'recipientType': recipientType,
      'category': category,
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
      'notes': notes,
      'impactDescription': impactDescription,
    };
  }

  GenerosityRecord copyWith({
    String? id,
    GenerosityType? type,
    String? description,
    DateTime? date,
    double? amount,
    String? currency,
    String? recipientName,
    String? recipientType,
    String? category,
    bool? isRecurring,
    String? recurringFrequency,
    String? notes,
    String? impactDescription,
  }) {
    return GenerosityRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      recipientName: recipientName ?? this.recipientName,
      recipientType: recipientType ?? this.recipientType,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      notes: notes ?? this.notes,
      impactDescription: impactDescription ?? this.impactDescription,
    );
  }
}

/// Types of generosity/mercy actions
enum GenerosityType {
  financial,
  time,
  resource,
}

extension GenerosityTypeX on GenerosityType {
  String get label {
    switch (this) {
      case GenerosityType.financial:
        return 'Financial';
      case GenerosityType.time:
        return 'Time';
      case GenerosityType.resource:
        return 'Resource';
    }
  }

  String get description {
    switch (this) {
      case GenerosityType.financial:
        return 'Money given to support others';
      case GenerosityType.time:
        return 'Hours volunteered or spent helping';
      case GenerosityType.resource:
        return 'Items, space, or resources shared';
    }
  }

  static GenerosityType fromStorage(String? value) {
    switch (value) {
      case 'time':
        return GenerosityType.time;
      case 'resource':
        return GenerosityType.resource;
      case 'financial':
      default:
        return GenerosityType.financial;
    }
  }
}

/// Represents an evangelism conversation with follow-up tracking
class EvangelismConversation {
  const EvangelismConversation({
    required this.id,
    required this.personName,
    required this.date,
    required this.method, // "in-person", "phone", "text", "social-media"
    this.initialContext,
    this.contentShared,
    this.responseType, // "receptive", "neutral", "resistant", "unknown"
    this.notes,
    this.prayerRequests,
    this.followUpDates = const [],
    this.isOngoing = true,
    this.decisionMade,
    this.decisionDate,
  });

  final String id;
  final String personName;
  final DateTime date;
  final String method;
  final String? initialContext; // How we know them, where conversation happened
  final String? contentShared; // What was shared (gospel content, testimony, etc)
  final String? responseType;
  final String? notes;
  final List<String>? prayerRequests;
  final List<DateTime> followUpDates;
  final bool isOngoing;
  final String? decisionMade; // "accepted", "considering", "not-ready", "declined"
  final DateTime? decisionDate;

  bool get hasFollowUpScheduled => followUpDates.isNotEmpty;
  bool get needsFollowUp {
    if (!isOngoing) return false;
    if (followUpDates.isEmpty) return true;
    final lastFollowUp = followUpDates.last;
    return DateTime.now().difference(lastFollowUp).inDays > 7;
  }

  int get daysSinceLastContact {
    final lastDate = followUpDates.isNotEmpty ? followUpDates.last : date;
    return DateTime.now().difference(lastDate).inDays;
  }

  factory EvangelismConversation.fromMap(Map<String, dynamic> map) {
    return EvangelismConversation(
      id: map['id'] as String? ?? '',
      personName: map['personName'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      method: map['method'] as String? ?? 'in-person',
      initialContext: map['initialContext'] as String?,
      contentShared: map['contentShared'] as String?,
      responseType: map['responseType'] as String?,
      notes: map['notes'] as String?,
      prayerRequests: (map['prayerRequests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      followUpDates: (map['followUpDates'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          const [],
      isOngoing: map['isOngoing'] as bool? ?? true,
      decisionMade: map['decisionMade'] as String?,
      decisionDate: map['decisionDate'] == null
          ? null
          : DateTime.tryParse(map['decisionDate'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'date': date.toIso8601String(),
      'method': method,
      'initialContext': initialContext,
      'contentShared': contentShared,
      'responseType': responseType,
      'notes': notes,
      'prayerRequests': prayerRequests,
      'followUpDates': followUpDates.map((d) => d.toIso8601String()).toList(),
      'isOngoing': isOngoing,
      'decisionMade': decisionMade,
      'decisionDate': decisionDate?.toIso8601String(),
    };
  }

  EvangelismConversation copyWith({
    String? id,
    String? personName,
    DateTime? date,
    String? method,
    String? initialContext,
    String? contentShared,
    String? responseType,
    String? notes,
    List<String>? prayerRequests,
    List<DateTime>? followUpDates,
    bool? isOngoing,
    String? decisionMade,
    DateTime? decisionDate,
  }) {
    return EvangelismConversation(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      date: date ?? this.date,
      method: method ?? this.method,
      initialContext: initialContext ?? this.initialContext,
      contentShared: contentShared ?? this.contentShared,
      responseType: responseType ?? this.responseType,
      notes: notes ?? this.notes,
      prayerRequests: prayerRequests ?? this.prayerRequests,
      followUpDates: followUpDates ?? this.followUpDates,
      isOngoing: isOngoing ?? this.isOngoing,
      decisionMade: decisionMade ?? this.decisionMade,
      decisionDate: decisionDate ?? this.decisionDate,
    );
  }
}

/// Represents a service opportunity match score for dynamic matching
class ServiceMatch {
  const ServiceMatch({
    required this.opportunityId,
    required this.title,
    required this.matchScore,
    required this.matchReasons,
    required this.category,
    this.burdenAlignment,
    this.tendencyAlignment,
    this.timeFit,
    this.locationProximity,
  });

  final String opportunityId;
  final String title;
  final double matchScore; // 0.0 to 1.0
  final List<String> matchReasons; // e.g., ["Aligns with your burden for the elderly", "Matches your hospitality tendency"]
  final String category;
  final String? burdenAlignment;
  final String? tendencyAlignment;
  final String? timeFit; // e.g., "Fits your weekend availability"
  final double? locationProximity; // Distance in miles if applicable

  bool get isStrongMatch => matchScore >= 0.8;
  bool get isGoodMatch => matchScore >= 0.6;
}
