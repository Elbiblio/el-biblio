import 'package:logger/logger.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';
import '../../../core/storage/hive_boxes.dart';
import '../domain/models/note.dart';

class JournalRepository extends BaseRepository {
  JournalRepository(this._client, Logger logger) : super(logger);

  final DioClient _client;

  Box<Note> get _box => Hive.box<Note>(HiveBoxes.journalEntries);

  Future<List<Note>> getNotes() async {
    final token = _client.currentAuthToken;
    
    // Check if user is guest and return local notes
    if (isGuestToken(token)) {
      logger.i('Returning local notes for guest user');
      return _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    try {
      final response = await _client.get('/notes');
      final List<dynamic> data = response.data['data'] ?? response.data;
      final notes = data.map((json) => Note.fromJson(json)).toList();
      
      // Update local storage
      await _box.clear();
      await _box.addAll(notes);
      
      return notes;
    } catch (e) {
      logger.w('Failed to fetch from API, returning local notes: $e');
      return _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  Future<Note> createNote({
    required String title,
    required String text,
    bool isPublic = false,
    bool isPinned = false,
    bool isVoiceRecorded = false,
    List<String> virtues = const [],
    String? meditationSessionId,
  }) async {
    final token = _client.currentAuthToken;
    final now = DateTime.now();

    // Check if user is guest and create a local-only note
    if (isGuestToken(token)) {
      logger.i('Creating local-only note for guest user');
      final localNote = Note(
        id: now.millisecondsSinceEpoch, // Use timestamp as local ID
        title: title,
        text: text,
        isPublic: false, // Guest notes are never public
        isPinned: isPinned,
        isVoiceRecorded: isVoiceRecorded,
        virtues: virtues,
        meditationSessionId: meditationSessionId,
        createdAt: now,
        updatedAt: now,
      );
      await _box.put(localNote.id, localNote);
      return localNote;
    }

    try {
      final response = await _client.raw.post(
        '/notes',
        data: {
          'title': title,
          'text': text,
          'is_public': isPublic,
          'is_pinned': isPinned,
          'is_voice_recorded': isVoiceRecorded,
          'virtues': virtues,
          if (meditationSessionId != null)
            'meditation_session_id': meditationSessionId,
        },
      );
      final data = response.data['data'] ?? response.data;
      final note = Note.fromJson(data);
      await _box.put(note.id, note);
      return note;
    } catch (e) {
      logger.w('Failed to create via API, saving locally: $e');
      final localNote = Note(
        id: now.millisecondsSinceEpoch, // Use timestamp as local ID
        title: title,
        text: text,
        isPublic: isPublic,
        isPinned: isPinned,
        isVoiceRecorded: isVoiceRecorded,
        virtues: virtues,
        meditationSessionId: meditationSessionId,
        createdAt: now,
        updatedAt: now,
      );
      await _box.put(localNote.id, localNote);
      return localNote;
    }
  }

  Future<Note> updateNote(int id, {
    String? title,
    String? text,
    bool? isPublic,
    bool? isPinned,
    List<String>? virtues,
  }) async {
    final token = _client.currentAuthToken;
    final existingNote = _box.get(id);
    final now = DateTime.now();
    
    if (isGuestToken(token)) {
      logger.i('Updating local-only note for guest user');
      if (existingNote == null) {
        throw GuestUserException('Note not found locally', 'update_note');
      }
      final updatedNote = existingNote.copyWith(
        title: title,
        text: text,
        isPublic: isPublic,
        isPinned: isPinned,
        virtues: virtues,
        updatedAt: now,
      );
      await _box.put(id, updatedNote);
      return updatedNote;
    }
    
    try {
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
      final updatedNote = Note.fromJson(data);
      await _box.put(id, updatedNote);
      return updatedNote;
    } catch (e) {
      logger.w('Failed to update via API, updating locally: $e');
      if (existingNote == null) {
        throw AppException('Note not found locally for offline update', 'update_note');
      }
      final updatedNote = existingNote.copyWith(
        title: title,
        text: text,
        isPublic: isPublic,
        isPinned: isPinned,
        virtues: virtues,
        updatedAt: now,
      );
      await _box.put(id, updatedNote);
      return updatedNote;
    }
  }

  Future<bool> deleteNote(int id) async {
    final token = _client.currentAuthToken;
    
    if (isGuestToken(token)) {
      logger.i('Deleting local-only note for guest user');
      await _box.delete(id);
      return true;
    }
    
    try {
      await _client.raw.delete('/notes/$id');
      await _box.delete(id);
      return true;
    } catch (e) {
      logger.w('Failed to delete via API, deleting locally: $e');
      await _box.delete(id);
      return true;
    }
  }
}
