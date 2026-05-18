import 'dart:async';

import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/features/auth/domain/models/auth_models.dart';
import 'package:elbiblio/features/bible/domain/models/verse.dart';
import 'package:elbiblio/features/vision/application/daily_verse_social_notifier.dart';
import 'package:elbiblio/features/vision/data/daily_verse_social_repository.dart';
import 'package:elbiblio/features/vision/domain/daily_verse_social_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  test('postResponse inserts a pending response then resolves it', () async {
    final repository = _FakeDailyVerseSocialRepository();
    final notifier = DailyVerseSocialNotifier(repository);
    await notifier.load();

    final postFuture = notifier.postResponse(
      user: _user,
      content: ' Grace is asking me to slow down. ',
    );

    expect(notifier.state.reflections.single.isPending, isTrue);
    expect(
      notifier.state.reflections.single.content,
      'Grace is asking me to slow down.',
    );

    repository.completePost(
      const DailyVerseReflection(
        id: 90,
        verseId: 15,
        content: 'Grace is asking me to slow down.',
        author: DailyVerseAuthor(displayName: 'Server Name'),
      ),
    );

    expect(await postFuture, isTrue);
    expect(notifier.state.reflections.single.id, 90);
    expect(notifier.state.reflections.single.isPending, isFalse);
    expect(notifier.state.reflections.single.author.displayName, 'Server Name');
  });

  test('postResponse removes optimistic response when backend fails', () async {
    final repository = _FakeDailyVerseSocialRepository();
    final notifier = DailyVerseSocialNotifier(repository);
    await notifier.load();

    repository.failPost(StateError('offline'));
    final posted = await notifier.postResponse(
      user: _user,
      content: 'This should roll back.',
    );

    expect(posted, isFalse);
    expect(notifier.state.reflections, isEmpty);
    expect(notifier.state.actionError, contains('offline'));
  });
}

const _user = User(
  id: '42',
  email: 'quiet@example.com',
  firstName: 'Quiet',
  lastName: 'Walker',
);

final _verse = Verse(
  id: 15,
  text: 'Let all that you do be done in love.',
  reference: '1 Corinthians 16:14',
  referenceDisplay: '1 Corinthians 16:14',
  translation: 'WEB',
  book: '1 Corinthians',
  chapter: 16,
  verseNumber: 14,
  createdAt: DateTime(2026, 5, 18),
);

class _FakeDailyVerseSocialRepository extends DailyVerseSocialRepository {
  _FakeDailyVerseSocialRepository()
    : super(_NoopDioClient(), Logger(level: Level.off));

  Completer<DailyVerseReflection>? _postCompleter;
  Object? _postError;

  @override
  Future<Verse?> todayVerse() async => _verse;

  @override
  Future<List<DailyVerseReflection>> reflectionsForVerse(
    int verseId, {
    int perPage = 20,
  }) async {
    return const [];
  }

  @override
  Future<DailyVerseReflection> postReflection({
    required int userId,
    required int verseId,
    required String content,
  }) {
    final error = _postError;
    if (error != null) return Future.error(error);
    _postCompleter = Completer<DailyVerseReflection>();
    return _postCompleter!.future;
  }

  void completePost(DailyVerseReflection reflection) {
    _postCompleter?.complete(reflection);
  }

  void failPost(Object error) {
    _postError = error;
  }
}

class _NoopDioClient extends DioClient {
  _NoopDioClient() : super(Logger(level: Level.off));
}
