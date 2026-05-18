import '../../bible/domain/models/verse.dart';
import '../domain/daily_verse_social_models.dart';

class DailyVerseSocialState {
  const DailyVerseSocialState({
    this.verse,
    this.reflections = const [],
    this.isLoading = false,
    this.isSubmittingResponse = false,
    this.replyingReflectionIds = const {},
    this.isVoting = false,
    this.isLiking = false,
    this.isTrackingShare = false,
    this.error,
    this.actionError,
  });

  final Verse? verse;
  final List<DailyVerseReflection> reflections;
  final bool isLoading;
  final bool isSubmittingResponse;
  final Set<int> replyingReflectionIds;
  final bool isVoting;
  final bool isLiking;
  final bool isTrackingShare;
  final String? error;
  final String? actionError;

  int get responseCount => reflections.length;

  List<DailyVerseReflection> get previewReflections {
    return reflections.take(3).toList(growable: false);
  }

  DailyVerseSocialState copyWith({
    Verse? verse,
    bool clearVerse = false,
    List<DailyVerseReflection>? reflections,
    bool? isLoading,
    bool? isSubmittingResponse,
    Set<int>? replyingReflectionIds,
    bool? isVoting,
    bool? isLiking,
    bool? isTrackingShare,
    String? error,
    bool clearError = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return DailyVerseSocialState(
      verse: clearVerse ? null : verse ?? this.verse,
      reflections: reflections ?? this.reflections,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingResponse: isSubmittingResponse ?? this.isSubmittingResponse,
      replyingReflectionIds:
          replyingReflectionIds ?? this.replyingReflectionIds,
      isVoting: isVoting ?? this.isVoting,
      isLiking: isLiking ?? this.isLiking,
      isTrackingShare: isTrackingShare ?? this.isTrackingShare,
      error: clearError ? null : error ?? this.error,
      actionError: clearActionError ? null : actionError ?? this.actionError,
    );
  }
}
