import '../../vision/domain/vision_models.dart';
import '../domain/models/failure_admission.dart';

class FailureProtocolService {
  FailureProtocolService();

  List<FailureAdmission> _admissions = [];

  void setAdmissions(List<FailureAdmission> admissions) {
    _admissions = admissions;
  }

  List<FailureAdmission> get admissions => List.unmodifiable(_admissions);

  int consecutiveMisses(CommitmentSeason commitment) {
    final today = DateTime.now();
    final daysSinceLastCheckIn = commitment.lastCheckInAt != null
        ? today.difference(commitment.lastCheckInAt!).inDays
        : commitment.currentDay;
    return (daysSinceLastCheckIn - 1).clamp(0, 30);
  }

  FailureState evaluate(CommitmentSeason commitment) {
    final misses = consecutiveMisses(commitment);
    final habitAdmissions = _admissions
        .where((a) => a.commitmentId == commitment.plan.id)
        .length;

    return FailureState(
      consecutiveMisses: misses,
      totalAdmissionsForCommitment: habitAdmissions,
      shouldTriggerProtocol: misses >= 1,
      isEscalated: misses >= 3,
      suggestAdjustment: habitAdmissions >= 3,
      level: _levelForMisses(misses),
    );
  }

  FailureLevel _levelForMisses(int misses) {
    return switch (misses) {
      0 => FailureLevel.none,
      1 => FailureLevel.firstMiss,
      2 => FailureLevel.secondMiss,
      3 || 4 => FailureLevel.escalated,
      >= 5 => FailureLevel.urgent,
      _ => FailureLevel.none,
    };
  }

  String messageForLevel(FailureLevel level, String habitName) {
    return switch (level) {
      FailureLevel.none => '',
      FailureLevel.firstMiss => 'That\'s okay. Every saint has a past.',
      FailureLevel.secondMiss => 'You\'re not alone in this struggle.',
      FailureLevel.escalated =>
        'You\'ve missed $habitName for a few days. Who could walk with you through this?',
      FailureLevel.urgent =>
        'Your commitment is at risk. It\'s time to reach out.',
    };
  }

  List<AdmissionOption> admissionOptions() {
    return const [
      AdmissionOption(
        key: 'companion',
        label: 'My companion (AI)',
        description: 'Talk it through with your AI companion',
      ),
      AdmissionOption(
        key: 'partner',
        label: 'My accountability partner',
        description: 'Send a miss notification to your partner',
      ),
      AdmissionOption(
        key: 'circle',
        label: 'My circle',
        description: 'Post anonymously to your circle feed',
      ),
      AdmissionOption(
        key: 'prayer',
        label: 'Pray about it',
        description: 'Open a confession/repentance prayer',
      ),
    ];
  }

  Future<FailureAdmission> recordAdmission({
    required int commitmentId,
    required String habitId,
    required String habitName,
    required int missedDay,
    required DateTime missedDate,
    required String admittedTo,
  }) async {
    final admission = FailureAdmission(
      id: _generateId(commitmentId, _admissions.length + 1),
      commitmentId: commitmentId,
      habitId: habitId,
      habitName: habitName,
      missedDay: missedDay,
      missedDate: missedDate,
      admittedTo: admittedTo,
      admittedAt: DateTime.now(),
      gracePointsRestored: 10,
    );

    _admissions = [..._admissions, admission];
    return admission;
  }

  bool shouldSuggestAdjustment(int commitmentId) {
    return _admissions
            .where((a) => a.commitmentId == commitmentId)
            .length >=
        3;
  }

  String adjustmentSuggestionMessage(String habitName) {
    return 'You\'ve been working on $habitName for a while. '
        'Maybe a different approach would help. '
        'Want to talk it through?';
  }

  String _generateId(int commitmentId, int count) {
    final now = DateTime.now();
    return 'fail_${commitmentId}_${now.millisecondsSinceEpoch}_$count';
  }
}

class FailureState {
  final int consecutiveMisses;
  final int totalAdmissionsForCommitment;
  final bool shouldTriggerProtocol;
  final bool isEscalated;
  final bool suggestAdjustment;
  final FailureLevel level;

  const FailureState({
    required this.consecutiveMisses,
    required this.totalAdmissionsForCommitment,
    required this.shouldTriggerProtocol,
    required this.isEscalated,
    required this.suggestAdjustment,
    required this.level,
  });

  static const empty = FailureState(
    consecutiveMisses: 0,
    totalAdmissionsForCommitment: 0,
    shouldTriggerProtocol: false,
    isEscalated: false,
    suggestAdjustment: false,
    level: FailureLevel.none,
  );
}

enum FailureLevel {
  none,
  firstMiss,
  secondMiss,
  escalated,
  urgent,
}

class AdmissionOption {
  final String key;
  final String label;
  final String description;

  const AdmissionOption({
    required this.key,
    required this.label,
    required this.description,
  });
}
