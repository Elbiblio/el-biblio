import 'package:dio/dio.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/features/vision/data/daily_verse_social_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  test('todayVerse loads today daily verse with theme include', () async {
    final client = _RecordingDioClient(
      getResponses: [
        {
          'success': true,
          'data': [_verseJson],
        },
      ],
    );
    final repository = DailyVerseSocialRepository(
      client,
      Logger(level: Level.off),
    );

    final verse = await repository.todayVerse();

    expect(verse?.id, 15);
    expect(verse?.isVoted, isTrue);
    expect(client.gets.single.path, '/verses/daily');
    expect(client.gets.single.queryParameters, {
      'include': 'theme',
      'date_range': 'today',
    });
  });

  test(
    'reflectionsForVerse uses verse filter and parses users/comments',
    () async {
      final client = _RecordingDioClient(
        getResponses: [
          {
            'success': true,
            'data': [
              {
                'id': '7',
                'verse_id': '15',
                'content': 'This invites patience today.',
                'type': 2,
                'created_at': '2026-05-18 08:30:00',
                'user': {
                  'id': '42',
                  'display_name': 'Mara',
                  'email': 'private@example.com',
                },
                'comments': {
                  'data': [
                    {
                      'id': '9',
                      'reflection_id': '7',
                      'content': 'Amen to this.',
                      'created_at': '2026-05-18 08:40:00',
                      'user': {'first_name': 'Jon'},
                    },
                  ],
                },
              },
            ],
          },
        ],
      );
      final repository = DailyVerseSocialRepository(
        client,
        Logger(level: Level.off),
      );

      final reflections = await repository.reflectionsForVerse(15);

      expect(client.gets.single.path, '/reflections');
      final query = client.gets.single.queryParameters!;
      expect(query['verse_id'], 15);
      expect(query['include'], 'user,comments.user');
      expect(query['_sort_by'], '-created_at');
      expect(reflections.single.author.displayName, 'Mara');
      expect(reflections.single.comments.single.author.displayName, 'Jon');
    },
  );

  test(
    'posting response and reply uses existing reflection/comment endpoints',
    () async {
      final client = _RecordingDioClient(
        postResponses: [
          {
            'success': true,
            'data': {
              'id': '21',
              'verse_id': '15',
              'content': 'I need to receive this slowly.',
              'type': 2,
              'created_at': '2026-05-18 09:00:00',
            },
          },
          {
            'success': true,
            'data': {
              'id': '22',
              'reflection_id': '21',
              'content': 'Same here.',
              'created_at': '2026-05-18 09:02:00',
            },
          },
        ],
      );
      final repository = DailyVerseSocialRepository(
        client,
        Logger(level: Level.off),
      );

      final response = await repository.postReflection(
        userId: 42,
        verseId: 15,
        content: ' I need to receive this slowly. ',
      );
      final reply = await repository.postComment(
        userId: 42,
        reflectionId: 21,
        content: ' Same here. ',
      );

      expect(response.id, 21);
      expect(reply.reflectionId, 21);
      expect(client.posts[0].path, '/reflections');
      expect(client.posts[0].data, {
        'user_id': 42,
        'verse_id': 15,
        'type': 2,
        'content': 'I need to receive this slowly.',
        'is_published': true,
        'icon': 'message-circle',
      });
      expect(client.posts[1].path, '/comments');
      expect(client.posts[1].data, {
        'user_id': 42,
        'reflection_id': 21,
        'content': 'Same here.',
      });
    },
  );

  test('verse social actions use /verses/{id} routes', () async {
    final client = _RecordingDioClient(
      postResponses: [
        {
          'success': true,
          'data': {'liked': true},
        },
        {
          'success': true,
          'data': {'voted': true, 'votes': 8},
        },
        {
          'success': true,
          'data': {'share_url': 'https://api.elbiblio.com/verses/15'},
        },
      ],
    );
    final repository = DailyVerseSocialRepository(
      client,
      Logger(level: Level.off),
    );

    await repository.setVerseLiked(verseId: 15, liked: true);
    final vote = await repository.voteVerse(15);
    await repository.trackShare(verseId: 15, message: 'Shared verse');

    expect(vote.votes, 8);
    expect(client.posts.map((request) => request.path), [
      '/verses/15/like',
      '/verses/15/vote',
      '/verses/15/share',
    ]);
    expect(client.posts.first.data, {'action': 'like'});
    expect(client.posts.last.data, {
      'platform': 'share_sheet',
      'message': 'Shared verse',
    });
  });
}

final _verseJson = {
  'id': '15',
  'created_at': '2026-05-18 08:00:00',
  'reference': '1 Corinthians 16:14',
  'reference_display': '1 Corinthians 16:14',
  'book': '1 Corinthians',
  'chapter': 16,
  'verse': 14,
  'date': '2026-05-18',
  'text': 'Let all that you do be done in love.',
  'votes': 7,
  'likes': 3,
  'shares': 2,
  'translation': 'WEB',
  'isVoted': true,
  'isLiked': false,
  'theme': {
    'id': 4,
    'name': 'love',
    'display_name': 'Love',
    'color_code': '#B66B28',
  },
};

class _RecordingDioClient extends DioClient {
  _RecordingDioClient({
    this.getResponses = const [],
    this.postResponses = const [],
  }) : super(Logger(level: Level.off));

  final List<Map<String, dynamic>> getResponses;
  final List<Map<String, dynamic>> postResponses;
  final gets = <_RecordedRequest>[];
  final posts = <_RecordedRequest>[];

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    gets.add(_RecordedRequest(path, queryParameters, null));
    final data = getResponses.removeAt(0);
    return Response<T>(
      data: data as T,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    posts.add(_RecordedRequest(path, queryParameters, data));
    final response = postResponses.removeAt(0);
    return Response<T>(
      data: response as T,
      requestOptions: RequestOptions(path: path),
    );
  }
}

class _RecordedRequest {
  const _RecordedRequest(this.path, this.queryParameters, this.data);

  final String path;
  final Map<String, dynamic>? queryParameters;
  final dynamic data;
}
