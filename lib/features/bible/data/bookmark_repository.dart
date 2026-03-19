import '../../../core/network/dio_client.dart';
import '../domain/models/bookmark.dart';

class BookmarkRepository {
  final DioClient _client;

  BookmarkRepository(this._client);

  Future<List<Bookmark>> getBookmarks() async {
    try {
      final response = await _client.get('/bookmarks');
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Bookmark.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load bookmarks: $e');
    }
  }

  Future<Bookmark> createBookmark({
    required int verseId,
    required String bookName,
    required int chapter,
    required int verse,
    required String text,
    required String reference,
    String? note,
  }) async {
    try {
      final response = await _client.post('/bookmarks', data: {
        'verse_id': verseId,
        'book_name': bookName,
        'chapter': chapter,
        'verse': verse,
        'text': text,
        'reference': reference,
        'note': note,
      });
      return Bookmark.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to create bookmark: $e');
    }
  }

  Future<void> deleteBookmark(int bookmarkId) async {
    try {
      await _client.delete('/bookmarks/$bookmarkId');
    } catch (e) {
      throw Exception('Failed to delete bookmark: $e');
    }
  }

  Future<Bookmark> updateBookmark(int bookmarkId, {String? note}) async {
    try {
      final response = await _client.put('/bookmarks/$bookmarkId', data: {
        if (note != null) 'note': note,
      });
      return Bookmark.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update bookmark: $e');
    }
  }

  Future<bool> isVerseBookmarked(int verseId) async {
    try {
      final response = await _client.get('/bookmarks/check/$verseId');
      return response.data['data']['is_bookmarked'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
