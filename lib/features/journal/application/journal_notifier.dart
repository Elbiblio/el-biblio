import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/journal_repository.dart';
import 'journal_state.dart';

class JournalNotifier extends StateNotifier<JournalState> {
  JournalNotifier(this._repository) : super(const JournalState()) {
    loadNotes();
  }

  final JournalRepository _repository;

  Future<void> loadNotes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notes = await _repository.getNotes();
      state = state.copyWith(
        notes: notes,
        isLoading: false,
      );
      _applyFilters();
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

  void _applyFilters() {
    final lowerQuery = state.searchQuery.toLowerCase();
    
    final filtered = state.notes.where((note) {
      // 1. Public/Private filter
      // If showing public notes, we want notes where isPublic is true.
      // If showing private notes (default), we want notes where isPublic is false (or user's own notes, but simpler to assume filtered by API or ID check).
      // Since API returns all notes for user (likely both own and public?), we need to check.
      // Actually, standard behavior: My Notes (private + my public?), Community Notes (all public).
      // Let's assume 'showPublicNotes' means "Community Mode".
      // If !showPublicNotes, we show user's notes.
      // The Note model has userId. We might need currentUserId to filter strictly 'my notes' if API returns everything.
      // For now, let's assume API returns "my notes" by default, and we need a separate call for "community notes" or the list contains mixed.
      // Based on typical repo, getNotes() usually gets "my notes".
      // If we want community notes, we might need a different API call or parameter.
      // The current repo `getNotes` calls `/notes`. Usually that's "index" which is user's notes.
      // To get community notes, we might need `/notes/search?is_public=1`.
      // For now, let's filter what we have locally based on isPublic if we assume we have a mixed list, 
      // BUT if `/notes` only returns MY notes, then `showPublicNotes` might need to trigger a fetch.
      // Let's implement local filtering for now assuming the list has what we need, or we might need to refactor `loadNotes` to fetch correct type.
      // Given constraints, let's assume we filter local list.
      
      // Update: NotesScreen.tsx logic:
      // if (!showPublicNotes) -> matchesSearch && matchesVirtues && !note.is_public
      // if (showPublicNotes) -> matchesSearch && matchesVirtues && note.is_public
      
      // Filter by visibility
      if (state.showPublicNotes) {
         if (!note.isPublic) return false;
         if (state.showFeaturedOnly && !note.isFeatured) return false;
      } else {
         if (note.isPublic) return false; // "My Notes" = private notes only? Or my notes (public or private)?
         // NotesScreen.tsx says: return matchesSearch && matchesVirtues && !note.is_public; 
         // So "My Notes" tab only shows private notes? That's what the logic implies.
         // Or maybe "My Notes" shows MY notes (regardless of visibility). 
         // Let's stick to the React logic: !showPublicNotes => !note.is_public.
      }

      // 2. Search filter
      if (state.searchQuery.isNotEmpty) {
        final titleMatch = note.title?.toLowerCase().contains(lowerQuery) ?? false;
        final textMatch = note.text?.toLowerCase().contains(lowerQuery) ?? false;
        if (!titleMatch && !textMatch) return false;
      }

      // 3. Virtue filter
      if (state.selectedVirtues.isNotEmpty) {
        // match ANY or ALL? React code: virtueFilter.every(v => note.virtues?.includes(v)) -> ALL
        final noteVirtues = note.virtues;
        for (final v in state.selectedVirtues) {
          if (!noteVirtues.contains(v)) return false;
        }
      }

      return true;
    }).toList();

    // Sort: Pinned first, then updated_at desc (or created_at)
    // Note: pinned separation happens in State getter for UI sections.
    // Here just sort by date.
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    state = state.copyWith(filteredNotes: filtered);
  }

  Future<int?> createNote(String title, String text, {
    bool isPublic = false,
    bool isPinned = false,
    List<String> virtues = const [],
  }) async {
    try {
      final newNote = await _repository.createNote(
        title: title,
        text: text,
        isPublic: isPublic,
        isPinned: isPinned,
        virtues: virtues,
      );
      final updatedNotes = [newNote, ...state.notes];
      state = state.copyWith(
        notes: updatedNotes,
      );
      _applyFilters();
      return newNote.id;
    } catch (e) {
      state = state.copyWith(error: e.toString());
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
      state = state.copyWith(error: e.toString());
    }
  }
}


