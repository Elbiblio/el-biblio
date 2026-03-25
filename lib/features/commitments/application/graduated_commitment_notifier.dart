import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/xp_service.dart';
import '../data/commitment_catalog.dart';
import '../data/graduated_commitment_repository.dart';
import '../domain/models/commitment_progress.dart';
import '../domain/models/graduated_commitment.dart';

/// State for the graduated commitment feature.
class GraduatedCommitmentState {
  const GraduatedCommitmentState({
    this.progress = const CommitmentProgress(),
    this.activeCommitment,
    this.remainingSeconds = 0,
    this.elapsedSeconds = 0,
    this.isLoading = false,
    this.error,
    this.justCompleted = false,
    this.justFailed = false,
  });

  final CommitmentProgress progress;
  final GraduatedCommitment? activeCommitment;
  final int remainingSeconds;
  final int elapsedSeconds;
  final bool isLoading;
  final String? error;
  final bool justCompleted;
  final bool justFailed;

  int get totalDurationSeconds =>
      (activeCommitment?.durationMinutes ?? 0) * 60;

  double get timerProgress {
    if (totalDurationSeconds == 0) return 0;
    return (elapsedSeconds / totalDurationSeconds).clamp(0.0, 1.0);
  }

  bool get canComplete =>
      activeCommitment != null &&
      progress.activeStatus == CommitmentStatus.active &&
      elapsedSeconds >= (totalDurationSeconds * 0.8).round();

  String get remainingFormatted {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final rm = m % 60;
      return '${h}h ${rm}m';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  String get elapsedFormatted {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final rm = m % 60;
      return '${h}h ${rm}m';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  GraduatedCommitmentState copyWith({
    CommitmentProgress? progress,
    GraduatedCommitment? activeCommitment,
    int? remainingSeconds,
    int? elapsedSeconds,
    bool? isLoading,
    String? error,
    bool? justCompleted,
    bool? justFailed,
    bool clearActiveCommitment = false,
    bool clearError = false,
  }) {
    return GraduatedCommitmentState(
      progress: progress ?? this.progress,
      activeCommitment:
          clearActiveCommitment ? null : (activeCommitment ?? this.activeCommitment),
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      justCompleted: justCompleted ?? this.justCompleted,
      justFailed: justFailed ?? this.justFailed,
    );
  }
}

/// Manages graduated commitment state, timer, and XP rewards.
class GraduatedCommitmentNotifier
    extends StateNotifier<GraduatedCommitmentState> {
  GraduatedCommitmentNotifier({
    required this.repository,
    required this.xpService,
  }) : super(const GraduatedCommitmentState()) {
    loadProgress();
  }

  final GraduatedCommitmentRepository repository;
  final XPService xpService;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final progress = await repository.getProgress();
      final active = await repository.getCurrentCommitment();

      int elapsed = 0;
      int remaining = 0;

      if (active != null && progress.activeCommitmentStartedAt != null) {
        elapsed =
            DateTime.now().difference(progress.activeCommitmentStartedAt!).inSeconds;
        remaining = (active.durationMinutes * 60) - elapsed;
        if (remaining < 0) remaining = 0;
      }

      state = state.copyWith(
        progress: progress,
        activeCommitment: active,
        elapsedSeconds: elapsed,
        remainingSeconds: remaining,
        isLoading: false,
      );

      if (progress.hasActiveCommitment && active != null) {
        _startTimer();
        // Also check for expiration
        await _checkExpiration();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Starting a commitment
  // ---------------------------------------------------------------------------

  Future<void> startCommitment(int level) async {
    state = state.copyWith(isLoading: true, justCompleted: false, justFailed: false);
    try {
      final commitment = await repository.startCommitment(level);
      final progress = await repository.getProgress();

      state = state.copyWith(
        progress: progress,
        activeCommitment: commitment,
        elapsedSeconds: 0,
        remainingSeconds: commitment.durationMinutes * 60,
        isLoading: false,
      );

      _startTimer();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Start the next available commitment level.
  Future<void> startNextCommitment() async {
    await startCommitment(state.progress.currentLevel);
  }

  // ---------------------------------------------------------------------------
  // Completing
  // ---------------------------------------------------------------------------

  Future<void> completeCommitment() async {
    final active = state.activeCommitment;
    if (active == null) return;

    _timer?.cancel();

    state = state.copyWith(isLoading: true);
    try {
      await repository.completeCommitment(active.id);

      // Award XP via the existing XP system
      await xpService.addXP(
        type: XPActivityType.commitment,
        description:
            'Completed commitment level ${active.level}: ${active.title}',
        metadata: {
          'commitmentLevel': active.level,
          'tier': active.tier.label,
          'xpReward': active.xpReward,
        },
      );

      final progress = await repository.getProgress();

      state = state.copyWith(
        progress: progress,
        clearActiveCommitment: true,
        elapsedSeconds: 0,
        remainingSeconds: 0,
        isLoading: false,
        justCompleted: true,
        justFailed: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Failing / restarting
  // ---------------------------------------------------------------------------

  Future<void> failCommitment() async {
    final active = state.activeCommitment;
    if (active == null) return;

    _timer?.cancel();

    state = state.copyWith(isLoading: true);
    try {
      await repository.failCommitment(active.id);
      final progress = await repository.getProgress();

      state = state.copyWith(
        progress: progress,
        clearActiveCommitment: true,
        elapsedSeconds: 0,
        remainingSeconds: 0,
        isLoading: false,
        justFailed: true,
        justCompleted: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Acknowledgements (clear just-completed / just-failed flags)
  // ---------------------------------------------------------------------------

  void acknowledgeCompletion() {
    state = state.copyWith(justCompleted: false);
  }

  void acknowledgeFailure() {
    state = state.copyWith(justFailed: false);
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }

      final newElapsed = state.elapsedSeconds + 1;
      final totalSeconds = state.totalDurationSeconds;
      final newRemaining = (totalSeconds - newElapsed).clamp(0, totalSeconds);

      state = state.copyWith(
        elapsedSeconds: newElapsed,
        remainingSeconds: newRemaining,
      );
    });
  }

  Future<void> _checkExpiration() async {
    final expired = await repository.checkExpiredCommitments();
    if (expired) {
      _timer?.cancel();
      final progress = await repository.getProgress();
      state = state.copyWith(
        progress: progress,
        clearActiveCommitment: true,
        elapsedSeconds: 0,
        remainingSeconds: 0,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  GraduatedCommitment getCommitmentForLevel(int level) {
    return CommitmentCatalog.getByLevel(level);
  }

  List<GraduatedCommitment> get allCommitments => CommitmentCatalog.all;
}
