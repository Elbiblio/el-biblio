import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../domain/models/commitment_progress.dart';
import '../domain/models/graduated_commitment.dart';
import 'commitment_catalog.dart';

/// Hive box name for graduated commitment data.
const String _boxName = 'graduated_commitments';

/// Repository for persisting graduated commitment progress using Hive.
///
/// All data is stored as JSON strings (no type adapters).
class GraduatedCommitmentRepository {
  GraduatedCommitmentRepository(this._logger);

  final Logger _logger;
  Box<String>? _box;

  static const String _progressKey = 'progress';
  static const String _activeCommitmentKey = 'active_commitment';

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  /// Load the user's current commitment progress.
  Future<CommitmentProgress> getProgress() async {
    try {
      final box = await _getBox();
      final raw = box.get(_progressKey);
      if (raw == null) return const CommitmentProgress();
      return CommitmentProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e, st) {
      _logger.e('Failed to load commitment progress', error: e, stackTrace: st);
      return const CommitmentProgress();
    }
  }

  /// Persist the user's commitment progress.
  Future<void> saveProgress(CommitmentProgress progress) async {
    try {
      final box = await _getBox();
      await box.put(_progressKey, jsonEncode(progress.toJson()));
    } catch (e, st) {
      _logger.e('Failed to save commitment progress', error: e, stackTrace: st);
    }
  }

  /// Get the currently active commitment (if any).
  Future<GraduatedCommitment?> getCurrentCommitment() async {
    try {
      final box = await _getBox();
      final raw = box.get(_activeCommitmentKey);
      if (raw == null) return null;
      return GraduatedCommitment.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e, st) {
      _logger.e('Failed to load active commitment', error: e, stackTrace: st);
      return null;
    }
  }

  /// Start a commitment at the given level. Returns the commitment.
  Future<GraduatedCommitment> startCommitment(int level) async {
    final commitment = CommitmentCatalog.getByLevel(level);
    final box = await _getBox();
    await box.put(_activeCommitmentKey, jsonEncode(commitment.toJson()));

    // Update progress to active
    final progress = await getProgress();
    final updated = progress.copyWith(
      activeCommitmentId: commitment.id,
      activeCommitmentStartedAt: DateTime.now(),
      activeStatus: CommitmentStatus.active,
    );
    await saveProgress(updated);

    _logger.i('Started commitment level $level: ${commitment.title}');
    return commitment;
  }

  /// Mark the active commitment as completed.
  Future<void> completeCommitment(String id) async {
    final progress = await getProgress();
    if (progress.activeCommitmentId != id) return;

    final commitment = CommitmentCatalog.getByLevel(progress.currentLevel);
    final newStreak = progress.currentStreak + 1;
    final newLongest =
        newStreak > progress.longestStreak ? newStreak : progress.longestStreak;

    final completionMap = Map<int, bool>.from(progress.levelCompletionMap);
    completionMap[progress.currentLevel] = true;

    final nextLevel =
        progress.currentLevel < 40 ? progress.currentLevel + 1 : 40;

    final updated = progress.copyWith(
      currentLevel: nextLevel,
      completedCount: progress.completedCount + 1,
      currentStreak: newStreak,
      longestStreak: newLongest,
      totalXpEarned: progress.totalXpEarned + commitment.xpReward,
      lastCompletedAt: DateTime.now(),
      activeStatus: CommitmentStatus.completed,
      levelCompletionMap: completionMap,
      clearActiveCommitment: true,
    );
    await saveProgress(updated);

    // Remove active commitment from storage
    final box = await _getBox();
    await box.delete(_activeCommitmentKey);

    _logger.i('Completed commitment: ${commitment.title} (+${commitment.xpReward} XP)');
  }

  /// Mark the active commitment as failed.
  Future<void> failCommitment(String id) async {
    final progress = await getProgress();
    if (progress.activeCommitmentId != id) return;

    final updated = progress.copyWith(
      failedCount: progress.failedCount + 1,
      currentStreak: 0,
      activeStatus: CommitmentStatus.failed,
      clearActiveCommitment: true,
    );
    await saveProgress(updated);

    // Remove active commitment from storage
    final box = await _getBox();
    await box.delete(_activeCommitmentKey);

    _logger.i('Failed commitment level ${progress.currentLevel}');
  }

  /// Check if the active commitment has expired based on its duration.
  Future<bool> checkExpiredCommitments() async {
    final progress = await getProgress();
    if (!progress.hasActiveCommitment) return false;

    final startedAt = progress.activeCommitmentStartedAt;
    if (startedAt == null) return false;

    final commitment = CommitmentCatalog.getByLevel(progress.currentLevel);
    // Allow 50% extra time as grace period before auto-expiring
    final expiresAt = startedAt.add(
      Duration(minutes: (commitment.durationMinutes * 1.5).round()),
    );

    if (DateTime.now().isAfter(expiresAt)) {
      final updated = progress.copyWith(
        activeStatus: CommitmentStatus.expired,
        clearActiveCommitment: true,
      );
      await saveProgress(updated);

      final box = await _getBox();
      await box.delete(_activeCommitmentKey);

      _logger.w('Commitment expired: level ${progress.currentLevel}');
      return true;
    }
    return false;
  }

  /// Reset all progress (for testing / user request).
  Future<void> resetProgress() async {
    final box = await _getBox();
    await box.clear();
    _logger.i('Graduated commitment progress reset');
  }
}
