import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/analytics/app_analytics_service.dart';
import '../data/journal_repository.dart';
import '../domain/models/note.dart';
import 'journal_state.dart';

class JournalNotifier extends StateNotifier<JournalState> {
  JournalNotifier(this._repository, this._analytics) : super(const JournalState());

  final JournalRepository _repository;
  final AppAnalyticsService _analytics;

  Future<void> loadNotes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notes = await _repository.getNotes();
      
      // Update notes and apply filters in one state update to prevent UI flicker
      final filteredNotes = _filterNotes(notes, state.searchQuery, state.selectedVirtues, state.showPublicNotes, state.showFeaturedOnly);
      
      state = state.copyWith(
        notes: notes,
        filteredNotes: filteredNotes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void toggleGridView() {
    state = state.copyWith(isGridView: !state.isGridView);
  }

  void toggleShowPublicNotes() {
    state = state.copyWith(showPublicNotes: !state.showPublicNotes);
    _applyFilters();
  }

  void toggleShowFeaturedOnly() {
    state = state.copyWith(showFeaturedOnly: !state.showFeaturedOnly);
    _applyFilters();
  }

  void toggleVirtueFilter(String virtue) {
    final current = List<String>.from(state.selectedVirtues);
    if (current.contains(virtue)) {
      current.remove(virtue);
    } else {
      current.add(virtue);
    }
    state = state.copyWith(selectedVirtues: current);
    _applyFilters();
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedVirtues: [],
      showFeaturedOnly: false,
    );
    _applyFilters();
  }

  List<Note> _filterNotes(List<Note> notes, String searchQuery, List<String> selectedVirtues, bool showPublicNotes, bool showFeaturedOnly) {
    final lowerQuery = searchQuery.toLowerCase();
    
    final filtered = notes.where((note) {
      // Filter by visibility
      if (showPublicNotes) {
         if (!note.isPublic) return false;
         if (showFeaturedOnly && !note.isFeatured) return false;
      }
      // For Personal tab, show ALL user notes (both private and public)
      // This ensures users see all their journal entries

      // Search filter
      if (searchQuery.isNotEmpty) {
        final titleMatch = note.title?.toLowerCase().contains(lowerQuery) ?? false;
        final textMatch = note.text?.toLowerCase().contains(lowerQuery) ?? false;
        if (!titleMatch && !textMatch) return false;
      }

      // Virtue filter - match ALL selected virtues
      if (selectedVirtues.isNotEmpty) {
        final noteVirtues = note.virtues;
        for (final v in selectedVirtues) {
          if (!noteVirtues.contains(v)) return false;
        }
      }

      return true;
    }).toList();

    // Sort by updated_at desc
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }

  void _applyFilters() {
    final filteredNotes = _filterNotes(
      state.notes, 
      state.searchQuery, 
      state.selectedVirtues, 
      state.showPublicNotes, 
      state.showFeaturedOnly
    );
    state = state.copyWith(filteredNotes: filteredNotes);
  }

  Future<int?> createNote(String title, String text, {
    bool isPublic = false,
    bool isPinned = false,
    bool isVoiceRecorded = false,
    List<String> virtues = const [],
    String? meditationSessionId,
  }) async {
    try {
      final newNote = await _repository.createNote(
        title: title,
        text: text,
        isPublic: isPublic,
        isPinned: isPinned,
        isVoiceRecorded: isVoiceRecorded,
        virtues: virtues,
        meditationSessionId: meditationSessionId,
      );
      final updatedNotes = [newNote, ...state.notes];
      state = state.copyWith(
        notes: updatedNotes,
      );
      _applyFilters();
      _analytics.track(AppAnalyticsEvent.journalEntryCreated);
      return newNote.id;
    } on GuestUserException {
      // Guest user logic is now handled in repository, but keeping for safety
      final localNote = Note(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        text: text,
        isPublic: false,
        isPinned: isPinned,
        isVoiceRecorded: isVoiceRecorded,
        virtues: virtues,
        meditationSessionId: meditationSessionId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final updatedNotes = [localNote, ...state.notes];
      state = state.copyWith(
        notes: updatedNotes,
      );
      _applyFilters();
      _analytics.track(AppAnalyticsEvent.journalEntryCreated);
      return localNote.id;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Re-throw so UI can handle if needed
      return null;
    }
  }

  /// Create a note with contextual title and pre-filled content
  Future<int?> createNoteWithContext({
    required String context, // 'meditation' or 'daily_verse'
    String? meditationStyle,
    String? virtue,
    int? meditationMinutes,
    String? verseReference,
    String? verseText,
  }) async {
    final now = DateTime.now();
    final dateStr = '${now.month}/${now.day}/${now.year}';
    
    String title;
    String initialText;
    List<String> virtues = [];

    if (context == 'meditation') {
      // Generate meditation-specific title
      final styleLabel = meditationStyle ?? 'Meditation';
      title = '$styleLabel Session - $dateStr';
      
      initialText = 'Reflections from my ${meditationMinutes ?? 0}-minute $styleLabel meditation:\n\n';
      
      if (virtue != null && virtue.isNotEmpty) {
        virtues.add(virtue);
        initialText += 'Focus: $virtue\n\n';
      }
      
      initialText += 'What I noticed:\n\n\nWhat I\'m grateful for:\n\n\nHow I want to carry this forward:\n\n';
      
    } else if (context == 'daily_verse') {
      // Generate daily verse reflection title
      title = 'Daily Verse Reflection - $dateStr';
      
      initialText = '';
      if (verseReference != null && verseReference.isNotEmpty) {
        initialText += '$verseReference\n';
      }
      if (verseText != null && verseText.isNotEmpty) {
        initialText += '"${verseText.trim()}"\n\n';
      }
      
      initialText += 'What this verse means to me:\n\n\nHow I can apply this today:\n\n';
      
    } else {
      // Generic daily check-in
      title = 'Daily Reflection - $dateStr';
      initialText = 'Today I noticed:\n\n\nI\'m grateful for:\n\n\nTomorrow I will:\n\n';
    }

    return createNote(
      title,
      initialText,
      virtues: virtues,
    );
  }

  Future<void> updateNote(int id, {
    String? title,
    String? text,
    bool? isPublic,
    bool? isPinned,
    List<String>? virtues,
  }) async {
    try {
      final updatedNote = await _repository.updateNote(
        id,
        title: title,
        text: text,
        isPublic: isPublic,
        isPinned: isPinned,
        virtues: virtues,
      );
      final updatedNotes = state.notes.map((n) => n.id == id ? updatedNote : n).toList();
      state = state.copyWith(
        notes: updatedNotes,
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _repository.deleteNote(id);
      final updatedNotes = state.notes.where((n) => n.id != id).toList();
      state = state.copyWith(
        notes: updatedNotes,
      );
      _applyFilters();
    } catch (e) {
      debugPrint('Failed to delete note $id: $e');
      state = state.copyWith(error: e.toString());
      rethrow; // Re-throw to let UI handle the error
    }
  }

  /// Delete a local note (one without an ID)
  Future<void> deleteLocalNote(Note note) async {
    try {
      // For local notes, just remove them from the state
      final updatedNotes = state.notes.where((n) => n != note).toList();
      state = state.copyWith(
        notes: updatedNotes,
      );
      _applyFilters();
      debugPrint('Deleted local note: ${note.title ?? 'Untitled'}');
    } catch (e) {
      debugPrint('Failed to delete local note: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}


