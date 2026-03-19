import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/commitment_repository.dart';
import '../domain/models/commitment.dart';
import '../domain/models/daily_anchors.dart';
import '../data/offline_commitment_data.dart';

class CommitmentNotifier extends StateNotifier<CommitmentState> {
  CommitmentNotifier({
    required this.repository,
  }) : super(const CommitmentState());

  final CommitmentRepository repository;

  Future<void> loadCommitmentsForVirtue(int virtueId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final commitments = await repository.getCommitmentsForVirtue(virtueId);
      
      // Check if we're using offline data (negative IDs indicate offline fallback)
      final isUsingOfflineData = commitments.any((c) => c.id < 0);
      
      state = state.copyWith(
        isLoading: false,
        commitments: commitments,
        error: null,
        isUsingOfflineData: isUsingOfflineData,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isUsingOfflineData: false,
      );
    }
  }

  void selectCommitment(Commitment? commitment) {
    state = state.copyWith(selectedCommitment: commitment);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Retry loading commitments (will attempt API first, then fallback)
  Future<void> retryLoadCommitments(int virtueId) async {
    await loadCommitmentsForVirtue(virtueId);
  }

  /// Get offline commitments directly for a virtue type
  List<Commitment> getOfflineCommitments(VirtueType virtueType, {int? defaultDurationMinutes}) {
    return OfflineCommitmentData.getCommitmentsForVirtue(virtueType, defaultDurationMinutes: defaultDurationMinutes);
  }

  /// Get offline commitments with multiple duration options
  List<Commitment> getOfflineCommitmentsWithDurationOptions(VirtueType virtueType) {
    return OfflineCommitmentData.getCommitmentsWithDurationOptions(virtueType);
  }

  /// Check if offline commitments are available for a virtue
  bool hasOfflineCommitments(VirtueType virtueType) {
    return OfflineCommitmentData.hasOfflineCommitments(virtueType);
  }

  /// Set offline commitments directly (for manual fallback)
  void setOfflineCommitments(VirtueType virtueType, {int? defaultDurationMinutes}) {
    final offlineCommitments = OfflineCommitmentData.getCommitmentsForVirtue(virtueType, defaultDurationMinutes: defaultDurationMinutes);
    state = state.copyWith(
      isLoading: false,
      commitments: offlineCommitments,
      error: null,
      isUsingOfflineData: true,
    );
  }

  /// Set offline commitments with duration options
  void setOfflineCommitmentsWithDurationOptions(VirtueType virtueType) {
    final offlineCommitments = OfflineCommitmentData.getCommitmentsWithDurationOptions(virtueType);
    state = state.copyWith(
      isLoading: false,
      commitments: offlineCommitments,
      error: null,
      isUsingOfflineData: true,
    );
  }
}

class CommitmentState {
  const CommitmentState({
    this.commitments = const [],
    this.selectedCommitment,
    this.isLoading = false,
    this.error,
    this.isUsingOfflineData = false,
  });

  final List<Commitment> commitments;
  final Commitment? selectedCommitment;
  final bool isLoading;
  final String? error;
  final bool isUsingOfflineData;

  CommitmentState copyWith({
    List<Commitment>? commitments,
    Commitment? selectedCommitment,
    bool? isLoading,
    String? error,
    bool? isUsingOfflineData,
  }) {
    return CommitmentState(
      commitments: commitments ?? this.commitments,
      selectedCommitment: selectedCommitment ?? this.selectedCommitment,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isUsingOfflineData: isUsingOfflineData ?? this.isUsingOfflineData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommitmentState &&
        other.commitments == commitments &&
        other.selectedCommitment == selectedCommitment &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.isUsingOfflineData == isUsingOfflineData;
  }

  @override
  int get hashCode {
    return Object.hash(
      commitments,
      selectedCommitment,
      isLoading,
      error,
      isUsingOfflineData,
    );
  }
}
