import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/models/activity.dart';
import '../data/bible_reading_repository.dart';
import '../../../core/services/xp_service.dart';
import '../../../core/storage/settings_storage.dart';

class BibleReadingState {
  const BibleReadingState({
    this.isLoading = false,
    this.error,
    this.history = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastReadingDate,
    this.totalDays = 0,
  });

  final bool isLoading;
  final String? error;
  final List<Activity> history;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastReadingDate;
  final int totalDays;

  BibleReadingState copyWith({
    bool? isLoading,
    String? error,
    List<Activity>? history,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastReadingDate,
    int? totalDays,
  }) {
    return BibleReadingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      history: history ?? this.history,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastReadingDate: lastReadingDate ?? this.lastReadingDate,
      totalDays: totalDays ?? this.totalDays,
    );
  }
}

class BibleReadingNotifier extends StateNotifier<BibleReadingState> {
  BibleReadingNotifier(this._repository, this._settingsStorage) : super(const BibleReadingState()) {
    // Load data synchronously in constructor to ensure availability
    _initializeData();
  }

  final BibleReadingRepository _repository;
  final SettingsStorage _settingsStorage;
  bool _isInitialized = false;

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    try {
      // Load local history first (synchronously if possible)
      await _loadLocalHistory();
      
      // Load streak data
      await loadStreak();
      
      // Load backend history in background without awaiting
      loadHistory().catchError((e) {
        debugPrint('Background history loading failed: $e');
      });
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing BibleReadingNotifier: $e');
    }
  }

  Future<void> _loadLocalHistory() async {
    try {
      final localHistory = await _settingsStorage.loadReadingHistory();
      if (localHistory.isNotEmpty) {
        state = state.copyWith(history: localHistory);
        debugPrint('Loaded ${localHistory.length} items from local reading history');
      }
    } catch (e) {
      debugPrint('Error loading local history: $e');
    }
  }

  Future<void> loadHistory() async {
    // Don't set loading to true if we already have local history to avoid UI flicker
    final hasLocalHistory = state.history.isNotEmpty;
    if (!hasLocalHistory) {
      state = state.copyWith(isLoading: true, error: null);
    }
    
    try {
      final history = await _repository.getHistory();
      
      // Merge with existing local history, avoiding duplicates
      final mergedHistory = _mergeHistories(state.history, history);
      
      state = state.copyWith(
        history: mergedHistory,
        isLoading: false,
        error: null, // Clear any previous errors
      );
      
      // Save merged history to local storage for persistence
      await _settingsStorage.saveReadingHistory(mergedHistory);
      
      debugPrint('Loaded and merged ${history.length} items from backend history');
    } catch (e) {
      // Don't clear existing local history when backend fails
      if (hasLocalHistory) {
        // Keep local history, just clear loading state
        state = state.copyWith(isLoading: false, error: null);
        debugPrint('Backend history failed, using local history only: $e');
      } else {
        // No local history, set error but don't clear empty history
        state = state.copyWith(isLoading: false, error: e.toString());
        debugPrint('Error loading backend history: $e');
      }
    }
  }

  /// Merge local and backend histories, removing duplicates and keeping most recent first
  List<Activity> _mergeHistories(List<Activity> localHistory, List<Activity> backendHistory) {
    final Set<String> seenKeys = {};
    final List<Activity> merged = [];
    
    // Process backend history first (more authoritative)
    for (final activity in backendHistory) {
      final key = _getActivityKey(activity);
      if (!seenKeys.contains(key)) {
        seenKeys.add(key);
        merged.add(activity);
      }
    }
    
    // Add local history items that aren't in backend
    for (final activity in localHistory) {
      final key = _getActivityKey(activity);
      if (!seenKeys.contains(key)) {
        seenKeys.add(key);
        merged.add(activity);
      }
    }
    
    // Sort by creation time (most recent first)
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Keep only the last 50 items to prevent list from growing too large
    return merged.take(50).toList();
  }

  /// Generate a unique key for an activity to detect duplicates
  String _getActivityKey(Activity activity) {
    final metadata = activity.metadata;
    final book = metadata?['book']?.toString() ?? '';
    final chapter = metadata?['chapter']?.toString() ?? '';
    final type = activity.type;
    return '$type:$book:$chapter';
  }

  Future<void> loadStreak() async {
    // Don't set loading for streak as it might be background
    try {
      final data = await _repository.getStreak();
      state = state.copyWith(
        currentStreak: data['current_streak'] as int? ?? 0,
        longestStreak: data['longest_streak'] as int? ?? 0,
        totalDays: data['total_days'] as int? ?? 0,
        lastReadingDate: data['last_reading_date'] != null 
            ? DateTime.parse(data['last_reading_date']) 
            : null,
      );
    } catch (e) {
      // Silent error for streak
      debugPrint('Error loading streak: $e');
    }
  }

  Future<bool> completeReading({
    required String readingMode,
    String? planName,
    int? durationMinutes,
    List<String>? chaptersRead,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.completeDailyReading(
        readingMode: readingMode,
        planName: planName,
        durationMinutes: durationMinutes,
        chaptersRead: chaptersRead,
        notes: notes,
      );
      
      // Add XP for Bible reading
      await XPService.instance.addXP(
        type: XPActivityType.bibleReading,
        description: 'Completed Bible reading: $readingMode${planName != null ? " ($planName)" : ""}',
        metadata: {
          'reading_mode': readingMode,
          'plan_name': planName,
          'duration_minutes': durationMinutes,
          'chapters_read': chaptersRead ?? [],
        },
      );
      
      // Reload streak and history
      await loadStreak();
      if (state.history.isNotEmpty) {
        await loadHistory();
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Track a reading location when user navigates to a book/chapter
  Future<void> trackReadingLocation({
    required String bookName,
    required int chapter,
    String? testament,
  }) async {
    try {
      // Create a simple activity entry for tracking local history
      // Note: This is a simplified version for local tracking only
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Create a minimal activity-like object for local tracking
      final activity = Activity(
        id: timestamp, // Use timestamp as temporary ID
        userId: 0, // Placeholder - will be filled by backend
        subjectType: 'bible_chapter',
        subjectId: timestamp, // Use timestamp as placeholder
        type: 'bible_reading',
        pointsEarned: 0, // No points for navigation
        isPublic: false,
        createdAt: DateTime.now(),
        metadata: {
          'book': bookName,
          'chapter': chapter,
          'testament': testament,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Add to beginning of history list (most recent first)
      final updatedHistory = [activity, ...state.history];
      
      // Remove any existing entries for the same book/chapter to avoid duplicates
      final deduplicatedHistory = _removeDuplicateLocations(updatedHistory, bookName, chapter);
      
      // Keep only the last 20 items to prevent list from growing too large
      final limitedHistory = deduplicatedHistory.take(20).toList();
      
      state = state.copyWith(history: limitedHistory);
      
      // Save to local storage for persistence
      try {
        await _settingsStorage.saveReadingHistory(limitedHistory);
        debugPrint('Tracked reading location: $bookName $chapter');
      } catch (e) {
        debugPrint('Failed to save reading history locally: $e');
      }
      
      // Also update the backend in background
      try {
        await _repository.completeDailyReading(
          readingMode: 'navigation',
          chaptersRead: ['$bookName $chapter'],
        );
      } catch (e) {
        // Silently fail for background tracking - don't show error to user
        debugPrint('Background tracking failed: $e');
      }
    } catch (e) {
      debugPrint('Error tracking reading location: $e');
    }
  }

  /// Remove duplicate entries for the same book/chapter
  List<Activity> _removeDuplicateLocations(List<Activity> history, String bookName, int chapter) {
    return history.where((activity) {
      final metadata = activity.metadata;
      final activityBook = metadata?['book']?.toString();
      final activityChapter = metadata?['chapter']?.toString();
      
      // Keep the first occurrence (most recent) and remove others
      return !(activityBook == bookName && activityChapter == chapter.toString());
    }).toList();
  }
}
