import 'graduated_commitment.dart';

/// Tracks the user's overall progress through the 40-level commitment journey.
class CommitmentProgress {
  const CommitmentProgress({
    this.currentLevel = 1,
    this.completedCount = 0,
    this.failedCount = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalXpEarned = 0,
    this.lastCompletedAt,
    this.activeCommitmentStartedAt,
    this.activeCommitmentId,
    this.activeStatus = CommitmentStatus.idle,
    this.levelCompletionMap = const {},
  });

  final int currentLevel; // 1-40
  final int completedCount;
  final int failedCount;
  final int currentStreak;
  final int longestStreak;
  final int totalXpEarned;
  final DateTime? lastCompletedAt;
  final DateTime? activeCommitmentStartedAt;
  final String? activeCommitmentId;
  final CommitmentStatus activeStatus;
  final Map<int, bool> levelCompletionMap; // level -> completed

  double get overallProgress => completedCount / 40.0;
  CommitmentTier get currentTier => CommitmentTier.fromLevel(currentLevel);
  bool get hasActiveCommitment => activeCommitmentId != null && activeStatus == CommitmentStatus.active;
  bool get isJourneyComplete => completedCount >= 40;

  int get tierCompletedCount {
    final tier = currentTier;
    int count = 0;
    final start = (tier.value - 1) * 10 + 1;
    final end = tier.value * 10;
    for (int i = start; i <= end; i++) {
      if (levelCompletionMap[i] == true) count++;
    }
    return count;
  }

  CommitmentProgress copyWith({
    int? currentLevel,
    int? completedCount,
    int? failedCount,
    int? currentStreak,
    int? longestStreak,
    int? totalXpEarned,
    DateTime? lastCompletedAt,
    DateTime? activeCommitmentStartedAt,
    String? activeCommitmentId,
    CommitmentStatus? activeStatus,
    Map<int, bool>? levelCompletionMap,
    bool clearActiveCommitment = false,
    bool clearLastCompleted = false,
  }) {
    return CommitmentProgress(
      currentLevel: currentLevel ?? this.currentLevel,
      completedCount: completedCount ?? this.completedCount,
      failedCount: failedCount ?? this.failedCount,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      lastCompletedAt: clearLastCompleted ? null : (lastCompletedAt ?? this.lastCompletedAt),
      activeCommitmentStartedAt: clearActiveCommitment
          ? null
          : (activeCommitmentStartedAt ?? this.activeCommitmentStartedAt),
      activeCommitmentId: clearActiveCommitment
          ? null
          : (activeCommitmentId ?? this.activeCommitmentId),
      activeStatus: activeStatus ?? this.activeStatus,
      levelCompletionMap: levelCompletionMap ?? this.levelCompletionMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentLevel': currentLevel,
      'completedCount': completedCount,
      'failedCount': failedCount,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalXpEarned': totalXpEarned,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'activeCommitmentStartedAt': activeCommitmentStartedAt?.toIso8601String(),
      'activeCommitmentId': activeCommitmentId,
      'activeStatus': activeStatus.name,
      'levelCompletionMap': levelCompletionMap.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
    };
  }

  factory CommitmentProgress.fromJson(Map<String, dynamic> json) {
    final rawMap = json['levelCompletionMap'] as Map<String, dynamic>? ?? {};
    final levelMap = rawMap.map(
      (k, v) => MapEntry(int.parse(k), v as bool),
    );

    return CommitmentProgress(
      currentLevel: json['currentLevel'] as int? ?? 1,
      completedCount: json['completedCount'] as int? ?? 0,
      failedCount: json['failedCount'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalXpEarned: json['totalXpEarned'] as int? ?? 0,
      lastCompletedAt: json['lastCompletedAt'] != null
          ? DateTime.parse(json['lastCompletedAt'] as String)
          : null,
      activeCommitmentStartedAt: json['activeCommitmentStartedAt'] != null
          ? DateTime.parse(json['activeCommitmentStartedAt'] as String)
          : null,
      activeCommitmentId: json['activeCommitmentId'] as String?,
      activeStatus: CommitmentStatus.values.firstWhere(
        (s) => s.name == (json['activeStatus'] as String? ?? 'idle'),
        orElse: () => CommitmentStatus.idle,
      ),
      levelCompletionMap: levelMap,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommitmentProgress &&
        other.currentLevel == currentLevel &&
        other.completedCount == completedCount &&
        other.activeStatus == activeStatus &&
        other.activeCommitmentId == activeCommitmentId;
  }

  @override
  int get hashCode => Object.hash(currentLevel, completedCount, activeStatus, activeCommitmentId);

  @override
  String toString() =>
      'CommitmentProgress(level: $currentLevel, completed: $completedCount, status: $activeStatus)';
}

/// Status of the currently active commitment.
enum CommitmentStatus { idle, active, completed, failed, expired }
