import '../domain/models/note.dart';

class JournalState {
  const JournalState({
    this.notes = const [],
    this.filteredNotes = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.isGridView = true,
    this.showPublicNotes = false, // Default to private/personal notes
    this.showFeaturedOnly = false,
    this.selectedVirtues = const [],
  });

  final List<Note> notes;
  final List<Note> filteredNotes;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final bool isGridView;
  final bool showPublicNotes;
  final bool showFeaturedOnly;
  final List<String> selectedVirtues;

  List<Note> get pinnedNotes => filteredNotes.where((n) => n.isPinned).toList();
  List<Note> get unpinnedNotes => filteredNotes.where((n) => !n.isPinned).toList();

  JournalState copyWith({
    List<Note>? notes,
    List<Note>? filteredNotes,
    bool? isLoading,
    String? error,
    String? searchQuery,
    bool? isGridView,
    bool? showPublicNotes,
    bool? showFeaturedOnly,
    List<String>? selectedVirtues,
  }) {
    return JournalState(
      notes: notes ?? this.notes,
      filteredNotes: filteredNotes ?? this.filteredNotes,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Clear error on new state unless explicitly provided (or keep it? usually clear)
      searchQuery: searchQuery ?? this.searchQuery,
      isGridView: isGridView ?? this.isGridView,
      showPublicNotes: showPublicNotes ?? this.showPublicNotes,
      showFeaturedOnly: showFeaturedOnly ?? this.showFeaturedOnly,
      selectedVirtues: selectedVirtues ?? this.selectedVirtues,
    );
  }
}
