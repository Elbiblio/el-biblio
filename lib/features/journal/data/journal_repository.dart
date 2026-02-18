import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';
import '../domain/models/note.dart';

class JournalRepository extends BaseRepository {
  JournalRepository(this._client, Logger logger) : super(logger);

  final DioClient _client;

  Future<List<Note>> getNotes() {
    return guard(() async {
      final response = await _client.get('/notes');
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Note.fromJson(json)).toList();
    }, operation: 'get_notes');
  }

  Future<Note> createNote({
    required String title,
    required String text,
    bool isPublic = false,
    bool isPinned = false,
    List<String> virtues = const [],
  }) {
    return guard(() async {
      final response = await _client.raw.post(
        '/notes',
        data: {
          'title': title,
          'text': text,
          'is_public': isPublic,
          'is_pinned': isPinned,
          'virtues': virtues,
        },
      );
      final data = response.data['data'] ?? response.data;
      return Note.fromJson(data);
    }, operation: 'create_note');
  }

  Future<Note> updateNote(int id, {
    String? title,
    String? text,
    bool? isPublic,
    bool? isPinned,
    List<String>? virtues,
  }) {
    return guard(() async {
      final response = await _client.raw.put(
        '/notes/$id',
        data: {
          if (title != null) 'title': title,
          if (text != null) 'text': text,
          if (isPublic != null) 'is_public': isPublic,
          if (isPinned != null) 'is_pinned': isPinned,
          if (virtues != null) 'virtues': virtues,
        },
      );
      final data = response.data['data'] ?? response.data;
      return Note.fromJson(data);
    }, operation: 'update_note');
  }

  Future<bool> deleteNote(int id) {
    return guard(() async {
      await _client.raw.delete('/notes/$id');
      return true;
    }, operation: 'delete_note');
  }
}
