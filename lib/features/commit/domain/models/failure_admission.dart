class FailureAdmission {
  final String id;
  final int commitmentId;
  final String habitId;
  final String habitName;
  final int missedDay;
  final DateTime missedDate;
  final String admittedTo;
  final DateTime admittedAt;
  final bool responseReceived;
  final String? responseContent;
  final bool commitmentAdjusted;
  final int? newLoad;
  final int gracePointsRestored;

  const FailureAdmission({
    required this.id,
    required this.commitmentId,
    required this.habitId,
    required this.habitName,
    required this.missedDay,
    required this.missedDate,
    required this.admittedTo,
    required this.admittedAt,
    this.responseReceived = false,
    this.responseContent,
    this.commitmentAdjusted = false,
    this.newLoad,
    this.gracePointsRestored = 0,
  });

  FailureAdmission copyWith({
    bool? responseReceived,
    String? responseContent,
    bool? commitmentAdjusted,
    int? newLoad,
    int? gracePointsRestored,
  }) {
    return FailureAdmission(
      id: id,
      commitmentId: commitmentId,
      habitId: habitId,
      habitName: habitName,
      missedDay: missedDay,
      missedDate: missedDate,
      admittedTo: admittedTo,
      admittedAt: admittedAt,
      responseReceived: responseReceived ?? this.responseReceived,
      responseContent: responseContent ?? this.responseContent,
      commitmentAdjusted: commitmentAdjusted ?? this.commitmentAdjusted,
      newLoad: newLoad ?? this.newLoad,
      gracePointsRestored: gracePointsRestored ?? this.gracePointsRestored,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'commitmentId': commitmentId,
    'habitId': habitId,
    'habitName': habitName,
    'missedDay': missedDay,
    'missedDate': missedDate.toIso8601String(),
    'admittedTo': admittedTo,
    'admittedAt': admittedAt.toIso8601String(),
    'responseReceived': responseReceived,
    'responseContent': responseContent,
    'commitmentAdjusted': commitmentAdjusted,
    'newLoad': newLoad,
    'gracePointsRestored': gracePointsRestored,
  };

  factory FailureAdmission.fromJson(Map<String, dynamic> json) {
    return FailureAdmission(
      id: json['id'] as String? ?? '',
      commitmentId: json['commitmentId'] as int? ?? 0,
      habitId: json['habitId'] as String? ?? '',
      habitName: json['habitName'] as String? ?? '',
      missedDay: json['missedDay'] as int? ?? 0,
      missedDate: DateTime.tryParse(json['missedDate']?.toString() ?? '') ?? DateTime.now(),
      admittedTo: json['admittedTo'] as String? ?? 'prayer',
      admittedAt: DateTime.tryParse(json['admittedAt']?.toString() ?? '') ?? DateTime.now(),
      responseReceived: json['responseReceived'] as bool? ?? false,
      responseContent: json['responseContent'] as String?,
      commitmentAdjusted: json['commitmentAdjusted'] as bool? ?? false,
      newLoad: json['newLoad'] as int?,
      gracePointsRestored: json['gracePointsRestored'] as int? ?? 0,
    );
  }
}
