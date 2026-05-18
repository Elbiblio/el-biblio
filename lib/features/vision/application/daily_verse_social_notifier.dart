import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/models/auth_models.dart';
import '../data/daily_verse_social_repository.dart';
import '../domain/daily_verse_social_models.dart';
import 'daily_verse_social_state.dart';

class DailyVerseSocialNotifier extends StateNotifier<DailyVerseSocialState> {
  DailyVerseSocialNotifier(this._repository)
    : super(const DailyVerseSocialState());

  final DailyVerseSocialRepository _repository;
  int _temporaryId = -1;

  Future<void> load({bool force = false}) async {
    if (state.isLoading) return;
    if (!force && state.verse != null) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearActionError: true,
    );

    try {
      final verse = await _repository.todayVerse();
      final reflections = verse == null
          ? const <DailyVerseReflection>[]
          : await _repository.reflectionsForVerse(verse.id);
      state = state.copyWith(
        verse: verse,
        clearVerse: verse == null,
        reflections: reflections,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: _friendlyError(error));
    }
  }

  Future<void> refresh() => load(force: true);

  Future<bool> toggleLike() async {
    final verse = state.verse;
    if (verse == null || state.isLiking) return false;

    final nextLiked = !verse.isLiked;
    final nextLikes = (verse.likes + (nextLiked ? 1 : -1))
        .clamp(0, 1 << 30)
        .toInt();
    final previousVerse = verse;
    state = state.copyWith(
      verse: verse.copyWith(isLiked: nextLiked, likes: nextLikes),
      isLiking: true,
      clearActionError: true,
    );

    try {
      final result = await _repository.setVerseLiked(
        verseId: verse.id,
        liked: nextLiked,
      );
      state = state.copyWith(
        verse: state.verse?.copyWith(isLiked: result.liked),
        isLiking: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        verse: previousVerse,
        isLiking: false,
        actionError: _friendlyError(error),
      );
      return false;
    }
  }

  Future<bool> vote() async {
    final verse = state.verse;
    if (verse == null || state.isVoting || verse.isVoted) return false;

    final previousVerse = verse;
    state = state.copyWith(
      verse: verse.copyWith(isVoted: true, votes: verse.votes + 1),
      isVoting: true,
      clearActionError: true,
    );

    try {
      final result = await _repository.voteVerse(verse.id);
      state = state.copyWith(
        verse: state.verse?.copyWith(
          isVoted: result.voted,
          votes: result.votes > 0 ? result.votes : state.verse?.votes,
        ),
        isVoting: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        verse: previousVerse,
        isVoting: false,
        actionError: _friendlyError(error),
      );
      return false;
    }
  }

  Future<bool> trackShare(String message) async {
    final verse = state.verse;
    if (verse == null || state.isTrackingShare) return false;

    state = state.copyWith(isTrackingShare: true, clearActionError: true);
    try {
      await _repository.trackShare(verseId: verse.id, message: message);
      state = state.copyWith(
        verse: state.verse?.copyWith(shares: (state.verse?.shares ?? 0) + 1),
        isTrackingShare: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isTrackingShare: false,
        actionError: _friendlyError(error),
      );
      return false;
    }
  }

  Future<bool> postResponse({
    required User user,
    required String content,
  }) async {
    final verse = state.verse;
    final userId = int.tryParse(user.id);
    final trimmed = content.trim();
    if (verse == null || userId == null || trimmed.isEmpty) return false;
    if (state.isSubmittingResponse) return false;

    final author = DailyVerseAuthor.fromUser(user);
    final temporary = DailyVerseReflection(
      id: _nextTemporaryId(),
      verseId: verse.id,
      content: trimmed,
      createdAt: DateTime.now(),
      author: author,
      isPending: true,
    );

    state = state.copyWith(
      reflections: [temporary, ...state.reflections],
      isSubmittingResponse: true,
      clearActionError: true,
    );

    try {
      final created = await _repository.postReflection(
        userId: userId,
        verseId: verse.id,
        content: trimmed,
      );
      final resolved = created.copyWith(
        author: created.author.isAnonymousFallback ? author : created.author,
        isPending: false,
      );
      state = state.copyWith(
        reflections: state.reflections
            .map((item) => item.id == temporary.id ? resolved : item)
            .toList(),
        isSubmittingResponse: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        reflections: state.reflections
            .where((item) => item.id != temporary.id)
            .toList(),
        isSubmittingResponse: false,
        actionError: _friendlyError(error),
      );
      return false;
    }
  }

  Future<bool> postReply({
    required User user,
    required int reflectionId,
    required String content,
  }) async {
    final userId = int.tryParse(user.id);
    final trimmed = content.trim();
    if (userId == null || trimmed.isEmpty) return false;
    if (state.replyingReflectionIds.contains(reflectionId)) return false;

    final reflection = state.reflections
        .where((item) => item.id == reflectionId)
        .firstOrNull;
    if (reflection == null || reflection.isPending) return false;

    final author = DailyVerseAuthor.fromUser(user);
    final temporary = DailyVerseComment(
      id: _nextTemporaryId(),
      reflectionId: reflectionId,
      content: trimmed,
      createdAt: DateTime.now(),
      author: author,
      isPending: true,
    );

    state = state.copyWith(
      replyingReflectionIds: {...state.replyingReflectionIds, reflectionId},
      reflections: _replaceReflection(
        reflectionId,
        (item) => item.copyWith(comments: [...item.comments, temporary]),
      ),
      clearActionError: true,
    );

    try {
      final created = await _repository.postComment(
        userId: userId,
        reflectionId: reflectionId,
        content: trimmed,
      );
      final resolved = created.copyWith(
        author: created.author.isAnonymousFallback ? author : created.author,
        isPending: false,
      );
      state = state.copyWith(
        replyingReflectionIds: {...state.replyingReflectionIds}
          ..remove(reflectionId),
        reflections: _replaceReflection(
          reflectionId,
          (item) => item.copyWith(
            comments: item.comments
                .map(
                  (comment) => comment.id == temporary.id ? resolved : comment,
                )
                .toList(),
          ),
        ),
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        replyingReflectionIds: {...state.replyingReflectionIds}
          ..remove(reflectionId),
        reflections: _replaceReflection(
          reflectionId,
          (item) => item.copyWith(
            comments: item.comments
                .where((comment) => comment.id != temporary.id)
                .toList(),
          ),
        ),
        actionError: _friendlyError(error),
      );
      return false;
    }
  }

  List<DailyVerseReflection> _replaceReflection(
    int reflectionId,
    DailyVerseReflection Function(DailyVerseReflection item) replace,
  ) {
    return state.reflections
        .map((item) => item.id == reflectionId ? replace(item) : item)
        .toList();
  }

  int _nextTemporaryId() => _temporaryId--;
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

String _friendlyError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '');
  const marker = 'message: ';
  final index = text.indexOf(marker);
  if (index >= 0) {
    final message = text.substring(index + marker.length).split(',').first;
    if (message.trim().isNotEmpty) return message.trim();
  }
  if (text.trim().isNotEmpty && text.length < 140) return text.trim();
  return 'We could not update the community verse. Please try again.';
}
