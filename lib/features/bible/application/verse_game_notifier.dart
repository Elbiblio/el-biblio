import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/bible_content.dart';
import '../data/bible_repository.dart';
import '../data/static_books.dart';
import '../../../core/di/app_providers.dart';

enum GameState { ready, loading, playing, checking, success, failed, gameOver, sessionComplete }
enum GameMode { arrange, guess }

enum DifficultyLevel { beginner, easy, medium, hard, expert }

class VerseDifficulty {
  final int level;
  final DifficultyLevel category;
  final double complexityScore;
  final int maxWords;
  final int timeLimit;
  final int hintCount;

  VerseDifficulty({
    required this.level,
    required this.category,
    required this.complexityScore,
    required this.maxWords,
    required this.timeLimit,
    this.hintCount = 0,
  });
}

class VerseGameState {
  final BibleVerseContent? verse;
  final GameMode currentMode;
  final List<String> originalWords;
  final List<String> shuffledWords;
  final List<int> selectedIndices;
  
  // Guess mode specific
  final String? missingWord;
  final List<String> guessOptions;
  
  final GameState state;
  final int timeLeft;
  final int currentQuestionIndex;
  final int totalQuestions;
  final int lives;
  final int score;
  final int streak;
  final VerseDifficulty? difficulty;
  final int hintsRemaining;
  final int comboMultiplier;
  final bool isBonusRound;

  VerseGameState({
    this.verse,
    this.currentMode = GameMode.arrange,
    this.originalWords = const [],
    this.shuffledWords = const [],
    this.selectedIndices = const [],
    this.missingWord,
    this.guessOptions = const [],
    this.state = GameState.loading,
    this.timeLeft = 20,
    this.currentQuestionIndex = 1,
    this.totalQuestions = 10,
    this.lives = 3,
    this.score = 0,
    this.streak = 0,
    this.difficulty,
    this.hintsRemaining = 0,
    this.comboMultiplier = 1,
    this.isBonusRound = false,
  });

  VerseGameState copyWith({
    BibleVerseContent? verse,
    GameMode? currentMode,
    List<String>? originalWords,
    List<String>? shuffledWords,
    List<int>? selectedIndices,
    String? missingWord,
    List<String>? guessOptions,
    GameState? state,
    int? timeLeft,
    int? currentQuestionIndex,
    int? totalQuestions,
    int? lives,
    int? score,
    int? streak,
    VerseDifficulty? difficulty,
    int? hintsRemaining,
    int? comboMultiplier,
    bool? isBonusRound,
  }) {
    return VerseGameState(
      verse: verse ?? this.verse,
      currentMode: currentMode ?? this.currentMode,
      originalWords: originalWords ?? this.originalWords,
      shuffledWords: shuffledWords ?? this.shuffledWords,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      missingWord: missingWord ?? this.missingWord,
      guessOptions: guessOptions ?? this.guessOptions,
      state: state ?? this.state,
      timeLeft: timeLeft ?? this.timeLeft,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      lives: lives ?? this.lives,
      score: score ?? this.score,
      streak: streak ?? this.streak,
      difficulty: difficulty ?? this.difficulty,
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      comboMultiplier: comboMultiplier ?? this.comboMultiplier,
      isBonusRound: isBonusRound ?? this.isBonusRound,
    );
  }
}

class VerseGameNotifier extends StateNotifier<VerseGameState> {
  final BibleRepository _repository;
  final Ref _ref;
  final Random _random = Random();
  Timer? _timer;
  List<BibleVerseContent> _sessionQuestions = [];

  // Cross-session tracking for Play Again
  int _difficultyBonus = 0; // Increases when player scores well
  int _lastSessionCorrect = 0;
  int _lastSessionTotal = 0;
  final Set<String> _allSessionUsedVerses = {}; // Persists across Play Again
  
  // Difficulty progression configuration
  static final List<VerseDifficulty> _difficultyLevels = [
    VerseDifficulty(level: 1, category: DifficultyLevel.beginner, complexityScore: 0.0, maxWords: 5, timeLimit: 30, hintCount: 3),
    VerseDifficulty(level: 2, category: DifficultyLevel.beginner, complexityScore: 0.2, maxWords: 6, timeLimit: 28, hintCount: 2),
    VerseDifficulty(level: 3, category: DifficultyLevel.easy, complexityScore: 0.4, maxWords: 7, timeLimit: 25, hintCount: 2),
    VerseDifficulty(level: 4, category: DifficultyLevel.easy, complexityScore: 0.6, maxWords: 8, timeLimit: 23, hintCount: 1),
    VerseDifficulty(level: 5, category: DifficultyLevel.medium, complexityScore: 0.8, maxWords: 10, timeLimit: 20, hintCount: 1),
    VerseDifficulty(level: 6, category: DifficultyLevel.medium, complexityScore: 1.0, maxWords: 12, timeLimit: 18, hintCount: 1),
    VerseDifficulty(level: 7, category: DifficultyLevel.hard, complexityScore: 1.2, maxWords: 15, timeLimit: 16, hintCount: 0),
    VerseDifficulty(level: 8, category: DifficultyLevel.hard, complexityScore: 1.4, maxWords: 18, timeLimit: 14, hintCount: 0),
    VerseDifficulty(level: 9, category: DifficultyLevel.expert, complexityScore: 1.6, maxWords: 20, timeLimit: 12, hintCount: 0),
    VerseDifficulty(level: 10, category: DifficultyLevel.expert, complexityScore: 1.8, maxWords: 25, timeLimit: 10, hintCount: 0),
  ];
  
  // Common biblical words for complexity calculation
  static const Set<String> _commonBiblicalWords = {
    'lord', 'god', 'jesus', 'christ', 'spirit', 'holy', 'father', 'son', 'heaven', 'earth',
    'faith', 'hope', 'love', 'peace', 'grace', 'mercy', 'truth', 'light', 'darkness', 'sin',
    'said', 'shall', 'will', 'come', 'go', 'see', 'know', 'believe', 'trust', 'heart',
    'man', 'woman', 'child', 'people', 'israel', 'jerusalem', 'temple', 'king', 'kingdom'
  };
  
  static const Set<String> _complexWords = {
    'righteousness', 'sanctification', 'redemption', 'justification', 'propitiation',
    'omnipotent', 'omniscient', 'omnipresent', 'immutable', 'infinite', 'eternal',
    'sovereignty', 'providence', 'eschatology', 'hermeneutics', 'exegesis',
    'soteriology', 'hamartiology', 'pneumatology', 'ecclesiology', 'angelology'
  };
  
  // Base popular verses loaded from asset file
  List<Map<String, dynamic>> _baseGameVerses = [];
  static const List<Map<String, dynamic>> _defaultBaseVerses = [
    {'book': 'JOH', 'chapter': 3, 'verse': 16},
    {'book': 'PSA', 'chapter': 23, 'verse': 1},
    {'book': 'PHP', 'chapter': 4, 'verse': 13},
    {'book': 'ROM', 'chapter': 8, 'verse': 28},
    {'book': 'PRO', 'chapter': 3, 'verse': 5},
    {'book': 'JER', 'chapter': 29, 'verse': 11},
    {'book': 'ISA', 'chapter': 41, 'verse': 10},
    {'book': 'MAT', 'chapter': 28, 'verse': 19},
    {'book': '1CO', 'chapter': 13, 'verse': 4},
    {'book': 'EPH', 'chapter': 2, 'verse': 8},
  ];
  
  // Calculate verse complexity score
  double _calculateVerseComplexity(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    double complexity = 0.0;
    
    // Base complexity from word count
    complexity += words.length * 0.02;
    
    // Average word length complexity
    final avgWordLength = words.map((w) => w.length).reduce((a, b) => a + b) / words.length;
    complexity += (avgWordLength - 4) * 0.1;
    
    // Complex words bonus
    final complexWordCount = words.where((w) => _complexWords.contains(w)).length;
    complexity += complexWordCount * 0.3;
    
    // Common words reduction (makes verse easier)
    final commonWordCount = words.where((w) => _commonBiblicalWords.contains(w)).length;
    complexity -= commonWordCount * 0.05;
    
    // Sentence structure complexity (punctuation indicates complex sentences)
    final punctuationCount = text.replaceAll(RegExp(r'\w'), '').length;
    complexity += punctuationCount * 0.1;
    
    return max(0.0, complexity);
  }
  
  // Get appropriate difficulty level based on player progress
  VerseDifficulty _getCurrentDifficulty() {
    final baseLevel = (state.currentQuestionIndex / 2).ceil().clamp(1, 10);

    // Apply difficulty bonus from previous sessions (Play Again level-up)
    int adjustedLevel = min(10, baseLevel + _difficultyBonus);

    // Adjust based on player performance within this session
    if (state.streak >= 3) {
      adjustedLevel = min(10, adjustedLevel + 1);
    } else if (state.streak == 0 && state.currentQuestionIndex > 3) {
      adjustedLevel = max(1, adjustedLevel - 1);
    }

    // Bonus rounds are harder
    if (state.isBonusRound) {
      adjustedLevel = min(10, adjustedLevel + 2);
    }

    return _difficultyLevels[adjustedLevel - 1];
  }
  
  // Check if verse is appropriate for current difficulty
  bool _isVerseAppropriateForDifficulty(BibleVerseContent verse, VerseDifficulty difficulty) {
    final complexity = _calculateVerseComplexity(verse.text);
    final wordCount = verse.text.split(RegExp(r'\s+')).length;
    
    // Verse should be within acceptable range for this difficulty
    final complexityDiff = (complexity - difficulty.complexityScore).abs();
    final wordDiff = (wordCount - difficulty.maxWords).abs();
    
    // Allow some flexibility but prefer closer matches
    return complexityDiff <= 0.5 && wordDiff <= 5;
  }
  

  VerseGameNotifier(this._repository, this._ref) : super(VerseGameState()) {
    _prepareSession();
  }

  /// Prepare session questions without starting the game.
  /// The game stays in `ready` state until the player taps Start.
  Future<void> _prepareSession() async {
    if (_baseGameVerses.isEmpty) {
      await _loadBaseGameVerses();
    }

    state = state.copyWith(
      state: GameState.loading,
      currentQuestionIndex: 1,
      lives: 3,
      score: 0,
      streak: 0,
      comboMultiplier: 1,
      isBonusRound: false,
    );

    _sessionQuestions = await _buildSessionQuestions();

    // Wait in ready state for player to start
    state = state.copyWith(state: GameState.ready);
  }

  /// Called when the player taps the Start button.
  void startGame() {
    if (state.state != GameState.ready) return;
    _loadNextQuestion();
  }

  Future<void> _initSession() async {
    if (_baseGameVerses.isEmpty) {
      await _loadBaseGameVerses();
    }

    state = state.copyWith(
      state: GameState.loading,
      currentQuestionIndex: 1,
      lives: 3,
      score: 0,
      streak: 0,
      comboMultiplier: 1,
      isBonusRound: false,
    );

    _sessionQuestions = await _buildSessionQuestions();

    await _loadNextQuestion();
  }

  Future<List<BibleVerseContent>> _buildSessionQuestions() async {
    final questions = <BibleVerseContent>[];
    final completedRefs = await _loadCompletedChapterRefs();
    // Use the persistent set so verses never repeat across Play Again sessions
    final usedVerses = _allSessionUsedVerses;

    for (int i = 0; i < state.totalQuestions; i++) {
      final targetDifficulty = _difficultyLevels[(i ~/ 2).clamp(0, 9)];
      BibleVerseContent? selectedVerse;
      
      // Try to find verses from completed chapters first
      for (final ref in completedRefs) {
        try {
          final chapterVerses = await _repository.getVerses(
            'eng_rv_vpl',
            ref.bookAbbr,
            ref.chapter,
          );
          
          // Filter verses appropriate for this difficulty and not used yet
          final appropriate = chapterVerses
              .where((v) => !usedVerses.contains(v.reference ?? '${ref.bookAbbr}-${v.chapter}-${v.verse}'))
              .where((v) => v.text.trim().split(RegExp(r'\s+')).length >= 4)
              .where((v) => _isVerseAppropriateForDifficulty(v, targetDifficulty))
              .toList();
          
          if (appropriate.isNotEmpty) {
            appropriate.shuffle(_random);
            selectedVerse = appropriate.first;
            break;
          }
        } catch (_) {
          // skip invalid chapter sources
        }
      }
      
      // Fallback to base verses if needed
      if (selectedVerse == null) {
        final availableFallbacks = _baseGameVerses
            .where((f) => !usedVerses.contains('${f['book']}-${f['chapter']}-${f['verse']}'))
            .toList();
        availableFallbacks.shuffle(_random);

        for (final fallback in availableFallbacks) {
          try {
            final verses = await _repository.getVerses(
              'eng_rv_vpl',
              fallback['book'] as String,
              fallback['chapter'] as int,
            );
            if (verses.isEmpty) continue;
            final picked = verses.firstWhere(
              (v) => v.verse == fallback['verse'],
              orElse: () => verses.first,
            );
            selectedVerse = picked;
            break;
          } catch (_) {
            // ignore fallback misses
          }
        }
      }

      // Final fallback if everything fails (very unlikely)
      if (selectedVerse == null && _baseGameVerses.isNotEmpty) {
         final fallback = _baseGameVerses[_random.nextInt(_baseGameVerses.length)];
         try {
           final verses = await _repository.getVerses('eng_rv_vpl', fallback['book'] as String, fallback['chapter'] as int);
           if (verses.isNotEmpty) {
             selectedVerse = verses.firstWhere((v) => v.verse == fallback['verse'], orElse: () => verses.first);
           }
         } catch (_) {}
      }

      if (selectedVerse != null) {
        questions.add(selectedVerse);
        usedVerses.add(selectedVerse.reference ?? '${selectedVerse.bookId}-${selectedVerse.chapter}-${selectedVerse.verse}');
      }
    }

    // Add bonus rounds every 5 questions
    if (state.totalQuestions >= 5) {
      for (int i = 4; i < state.totalQuestions; i += 5) {
        if (questions.length > i) {
          // Handled via state.currentQuestionIndex % 5 == 0 check in _setupQuestion
        }
      }
    }

    return questions.take(state.totalQuestions).toList();
  }

  Future<void> _loadBaseGameVerses() async {
    try {
      final jsonString = await rootBundle.loadString('assets/game/verse_game_base.json');
      final decoded = json.decode(jsonString);
      if (decoded is List) {
        _baseGameVerses = decoded
            .whereType<Map>()
            .map((entry) => entry.map((key, value) => MapEntry(key.toString(), value)))
            .where((entry) => entry.containsKey('book') && entry.containsKey('chapter') && entry.containsKey('verse'))
            .toList();
      }
    } catch (_) {
      _baseGameVerses = _defaultBaseVerses;
    }

    if (_baseGameVerses.isEmpty) {
      _baseGameVerses = _defaultBaseVerses;
    }
  }

  Future<List<_ChapterRef>> _loadCompletedChapterRefs() async {
    final refs = <_ChapterRef>[];

    try {
      final readingState = _ref.read(bibleReadingProvider);
      if (readingState.history.isEmpty) {
        await _ref.read(bibleReadingProvider.notifier).loadHistory();
      }

      final history = _ref.read(bibleReadingProvider).history;
      for (final activity in history) {
        final metadata = activity.metadata;
        if (metadata == null) continue;
        final chapters = metadata['chapters_read'];
        if (chapters is List) {
          for (final item in chapters) {
            final parsed = _parseChapterRef(item.toString());
            if (parsed != null) refs.add(parsed);
          }
        } else if (chapters is String) {
          final parsed = _parseChapterRef(chapters);
          if (parsed != null) refs.add(parsed);
        }
      }
    } catch (_) {
      // ignore history errors and fallback below
    }

    try {
      final activePlans = _ref.read(readingPlanProvider).activePlans;
      if (activePlans.isNotEmpty) {
        final plan = activePlans.first.plan;
        if (plan != null) {
          for (final day in plan.days) {
            for (final verseRef in day.verses) {
              final parsed = _parseChapterRef(verseRef);
              if (parsed != null) refs.add(parsed);
            }
          }
        }
      }
    } catch (_) {
      // ignore reading plan parse errors
    }

    final unique = <String, _ChapterRef>{};
    for (final ref in refs) {
      unique['${ref.bookAbbr}-${ref.chapter}'] = ref;
    }
    final deduped = unique.values.toList()..shuffle(_random);
    return deduped;
  }

  _ChapterRef? _parseChapterRef(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return null;

    final match = RegExp(r'^([1-3]?\s?[A-Za-z ]+)\s+(\d+)').firstMatch(cleaned);
    if (match == null) return null;

    final rawBook = match.group(1)!.toLowerCase().trim();
    final chapter = int.tryParse(match.group(2)!);
    if (chapter == null || chapter <= 0) return null;

    // Use static_books helper to find book by abbreviation or name
    final bookDef = getBookByAbbreviation(rawBook.toUpperCase());
    if (bookDef != null) {
      return _ChapterRef(bookAbbr: bookDef.abbreviation, chapter: chapter);
    }

    // Try to match by full name (case-insensitive)
    for (final book in standardBibleBooks) {
      if (book.name.toLowerCase() == rawBook) {
        return _ChapterRef(bookAbbr: book.abbreviation, chapter: chapter);
      }
    }

    return null;
  }

  Future<void> _loadNextQuestion() async {
    if (state.lives <= 0) {
      state = state.copyWith(state: GameState.gameOver);
      return;
    }

    if (state.currentQuestionIndex > state.totalQuestions) {
      state = state.copyWith(state: GameState.sessionComplete);
      return;
    }

    state = state.copyWith(state: GameState.loading);
    
    try {
      if (_sessionQuestions.isEmpty) {
        state = state.copyWith(state: GameState.gameOver);
        return;
      }

      final targetVerse =
          _sessionQuestions[(state.currentQuestionIndex - 1) % _sessionQuestions.length];

      // Alternate modes to ensure both are always represented in each session.
      final mode = state.currentQuestionIndex.isOdd
          ? GameMode.arrange
          : GameMode.guess;
      _setupQuestion(targetVerse, mode);
    } catch (e) {
      state = state.copyWith(state: GameState.failed);
    }
  }

  void _setupQuestion(BibleVerseContent verse, GameMode mode) {
    // Check if this is a bonus round (every 5th question)
    final isBonusRound = (state.currentQuestionIndex % 5) == 0;
    
    // Get current difficulty based on progress
    final difficulty = _getCurrentDifficulty();
    
    // Split text keeping punctuation attached to words
    final rawWords = verse.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    // For arrange mode, we might need to group words if there are too many
    // to fit the difficulty's maxWords constraint.
    List<String> gameWords = [];
    if (rawWords.length <= difficulty.maxWords) {
      gameWords = List.from(rawWords);
    } else {
      // Group words together to fit the maxWords constraint
      int targetCount = difficulty.maxWords;
      int wordsPerGroup = (rawWords.length / targetCount).ceil();
      
      for (int i = 0; i < rawWords.length; i += wordsPerGroup) {
        int end = (i + wordsPerGroup < rawWords.length) ? i + wordsPerGroup : rawWords.length;
        gameWords.add(rawWords.sublist(i, end).join(' '));
      }
      
      // If we still have too many groups (due to rounding), merge the last ones
      while (gameWords.length > targetCount) {
        String last = gameWords.removeLast();
        int newLastIndex = gameWords.length - 1;
        gameWords[newLastIndex] = '${gameWords[newLastIndex]} $last';
      }
    }
    
    if (mode == GameMode.arrange) {
      final shuffled = List<String>.from(gameWords)..shuffle(_random);
      
      // Ensure it's actually shuffled (not the same as original)
      if (shuffled.join(' ') == gameWords.join(' ') && gameWords.length > 1) {
         shuffled.shuffle(_random); 
         // If still same, manually swap first two
         if (shuffled.join(' ') == gameWords.join(' ')) {
             final temp = shuffled[0];
             shuffled[0] = shuffled[1];
             shuffled[1] = temp;
         }
      }

      state = state.copyWith(
        verse: verse,
        currentMode: mode,
        originalWords: gameWords,
        shuffledWords: shuffled,
        selectedIndices: [],
        state: GameState.playing,
        timeLeft: difficulty.timeLimit,
        difficulty: difficulty,
        hintsRemaining: difficulty.hintCount,
        isBonusRound: isBonusRound,
        comboMultiplier: isBonusRound ? 2 : 1,
      );
    } else {
      // Guess mode setup
      if (gameWords.isEmpty) return; // Guard against empty verses
      
      // We want to pick a single word for guess mode, not a grouped phrase
      // So we use rawWords instead of gameWords for selecting the missing word
      
      // Pick a random important word to remove (longer than 3 chars if possible)
      // Strip punctuation for length check and the actual missing word string
      final cleanRawWords = rawWords.map((w) => w.replaceAll(RegExp(r'[^\w]'), '')).toList();
      
      final candidateIndices = List<int>.generate(rawWords.length, (i) => i)
          .where((i) => cleanRawWords[i].length > 3)
          .toList();
          
      final removeIndex = candidateIndices.isNotEmpty 
          ? candidateIndices[_random.nextInt(candidateIndices.length)]
          : _random.nextInt(rawWords.length);
          
      final originalWordWithPunc = rawWords[removeIndex];
      final missingWordClean = cleanRawWords[removeIndex];
      
      // Extract punctuation to keep it around the blank
      final RegExp wordRegExp = RegExp(r'\w+');
      final match = wordRegExp.firstMatch(originalWordWithPunc);
      String prefix = '';
      String suffix = '';
      
      if (match != null) {
        prefix = originalWordWithPunc.substring(0, match.start);
        suffix = originalWordWithPunc.substring(match.end);
      }
      
      // Generate some fake options (in a real app, these would come from a biblical corpus)
      final distractors = _generateDistractors(
        correctWord: missingWordClean,
        localWords: cleanRawWords,
      );
      final options = [missingWordClean, ...distractors]..shuffle(_random);
      
      // Create display words with a blank placeholder but keeping punctuation
      final displayWords = List<String>.from(rawWords);
      displayWords[removeIndex] = '${prefix}_____$suffix';
      
      state = state.copyWith(
        verse: verse,
        currentMode: mode,
        originalWords: displayWords, // Using this to hold the text with blank
        missingWord: missingWordClean,
        guessOptions: options,
        state: GameState.playing,
        timeLeft: difficulty.timeLimit,
        difficulty: difficulty,
        hintsRemaining: difficulty.hintCount,
        isBonusRound: isBonusRound,
        comboMultiplier: isBonusRound ? 2 : 1,
      );
    }
    
    _startTimer();
  }
  
  List<String> _generateDistractors({
    required String correctWord,
    required List<String> localWords,
  }) {
    // A simple distractor generator. Ideally, this uses a dictionary of similar biblical words.
    final allFakeWords = <String>[
      'love', 'faith', 'hope', 'peace', 'grace', 'mercy', 'light', 'truth',
      'spirit', 'heart', 'soul', 'mind', 'strength', 'power', 'glory', 'honor',
      'heaven', 'earth', 'water', 'fire', 'bread', 'wine', 'blood', 'body',
      'holy', 'righteous', 'pure', 'good', 'perfect', 'clean', 'just', 'true',
      'believe', 'trust', 'follow', 'obey', 'seek', 'find', 'knock', 'ask',
    ];

    final inVerseDistractors = localWords
        .where((w) =>
            w.toLowerCase() != correctWord.toLowerCase() && w.trim().length >= 3)
        .toSet()
        .toList()
      ..shuffle(_random);

    final distractors = <String>[];
    distractors.addAll(inVerseDistractors.take(2));

    allFakeWords.removeWhere((w) => w.toLowerCase() == correctWord.toLowerCase());
    allFakeWords.shuffle(_random);

    for (final word in allFakeWords) {
      if (distractors.length >= 3) break;
      if (!distractors.contains(word)) {
        distractors.add(word);
      }
    }

    return distractors.take(3).toList();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Only tick when actively playing (not during pause/tutorial/ready)
      if (state.state != GameState.playing) return;
      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
        _ref.read(soundServiceProvider).playGameTick();
      } else {
        timer.cancel();
        _handleTimeUp();
      }
    });
  }

  /// Pause the game timer (e.g. when showing back confirmation dialog)
  void pauseTimer() {
    _timer?.cancel();
  }

  /// Resume the game timer after a pause
  void resumeTimer() {
    if (state.state == GameState.playing) {
      _startTimer();
    }
  }
  
  void _handleTimeUp() {
    final newLives = state.lives - 1;
    
    state = state.copyWith(
      state: GameState.failed,
      lives: newLives,
    );
    
    // Play timeout sound for immediate feedback
    _ref.read(soundServiceProvider).playGameTimeout();
    
    _scheduleNextAfterResult();
  }

  // --- Arrange Mode Actions ---

  void selectArrangeWord(int index) {
    if (state.state != GameState.playing || state.currentMode != GameMode.arrange) return;
    if (state.selectedIndices.contains(index)) return;

    final newSelected = List<int>.from(state.selectedIndices)..add(index);

    state = state.copyWith(
      selectedIndices: newSelected,
    );

    _checkArrangeCompletion();
  }

  void removeArrangeWord(int index) {
    if (state.state != GameState.playing || state.currentMode != GameMode.arrange) return;
    if (!state.selectedIndices.contains(index)) return;

    final newSelected = List<int>.from(state.selectedIndices)..remove(index);

    state = state.copyWith(
      selectedIndices: newSelected,
    );
  }

  void _checkArrangeCompletion() {
    if (state.selectedIndices.length == state.originalWords.length) {
      _timer?.cancel();
      state = state.copyWith(state: GameState.checking);
      
      bool isCorrect = true;
      for (int i = 0; i < state.originalWords.length; i++) {
        final wordIndex = state.selectedIndices[i];
        if (state.shuffledWords[wordIndex] != state.originalWords[i]) {
          isCorrect = false;
          break;
        }
      }

      if (isCorrect) {
        state = state.copyWith(streak: state.streak + 1);
      } else {
        state = state.copyWith(streak: 0);
      }

      _handleResult(isCorrect, scoreDelta: state.timeLeft * 10);
    }
  }
  
  // --- Guess Mode Actions ---
  
  void submitGuess(String guess) {
    if (state.state != GameState.playing || state.currentMode != GameMode.guess) return;
    
    _timer?.cancel();
    state = state.copyWith(state: GameState.checking);
    
    // Strip punctuation for comparison just in case
    final cleanGuess = guess.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
    final cleanMissing = state.missingWord?.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
    
    final isCorrect = cleanGuess == cleanMissing;
    _handleResult(isCorrect, scoreDelta: state.timeLeft * 20);
  }
  
  // --- Hint System ---
  
  void useHint() {
    if (state.state != GameState.playing || state.hintsRemaining <= 0) return;
    
    if (state.currentMode == GameMode.arrange) {
      _useArrangeHint();
    } else {
      _useGuessHint();
    }
    
    state = state.copyWith(hintsRemaining: state.hintsRemaining - 1);
    _ref.read(soundServiceProvider).playGameTap();
  }
  
  void _useArrangeHint() {
    // Find the next correct word that hasn't been selected
    for (int i = 0; i < state.originalWords.length; i++) {
      final targetWord = state.originalWords[i];
      
      // Check if this position is already filled correctly
      if (i < state.selectedIndices.length) {
        final selectedIndex = state.selectedIndices[i];
        if (selectedIndex < state.shuffledWords.length && 
            state.shuffledWords[selectedIndex] == targetWord) {
          continue; // Skip already correct positions
        }
      }
      
      // Find the index of the target word in shuffled words
      for (int j = 0; j < state.shuffledWords.length; j++) {
        if (state.shuffledWords[j] == targetWord && !state.selectedIndices.contains(j)) {
          selectArrangeWord(j);
          break;
        }
      }
      break;
    }
  }
  
  void _useGuessHint() {
    // For guess mode, reveal information about the missing word
    // This could be implemented in the UI to show a hint
    // For now, we'll just reduce the options by removing one distractor
    if (state.guessOptions.length > 2) {
      final nonCorrectOptions = state.guessOptions
          .where((opt) => opt.toLowerCase() != state.missingWord?.toLowerCase())
          .toList();
      
      if (nonCorrectOptions.isNotEmpty) {
        final optionToRemove = nonCorrectOptions[_random.nextInt(nonCorrectOptions.length)];
        final newOptions = state.guessOptions.where((opt) => opt != optionToRemove).toList();
        state = state.copyWith(guessOptions: newOptions);
      }
    }
  }
  
  // --- Power-ups ---
  
  void useTimeBoost() {
    if (state.state != GameState.playing) return;
    
    const bonusTime = 10;
    state = state.copyWith(timeLeft: state.timeLeft + bonusTime);
    _ref.read(soundServiceProvider).playGameLevelUp();
  }
  
  void useRevealWord() {
    if (state.state != GameState.playing || state.currentMode != GameMode.arrange) return;
    
    // Reveal one correct word in the sequence
    _useArrangeHint();
  }
  
  // --- Themed Collections ---
  
  Future<void> startThemedSession(String theme) async {
    // This could be expanded to include different themed verse collections
    // For now, we'll just restart with a flag that could be used for special theming
    state = state.copyWith(
      state: GameState.loading,
      currentQuestionIndex: 1,
      lives: 3,
      score: 0,
      streak: 0,
      comboMultiplier: 1,
      isBonusRound: false,
    );
    
    // In a full implementation, this would load theme-specific verses
    _sessionQuestions = await _buildSessionQuestions();
    await _loadNextQuestion();
  }
  
  void _handleResult(bool isCorrect, {required int scoreDelta}) {
    final finalScore = scoreDelta * state.comboMultiplier;
    
    if (isCorrect) {
      state = state.copyWith(
        state: GameState.success,
        score: state.score + finalScore + 100, // Base points + time bonus * multiplier
      );
      // Play level-up sound for positive reinforcement
      _ref.read(soundServiceProvider).playGameLevelUp();
    } else {
      final newLives = state.lives - 1;
      state = state.copyWith(
        state: GameState.failed,
        lives: newLives,
        comboMultiplier: 1, // Reset combo on failure
      );
      // If lives are exhausted, play game-over sound
      if (newLives <= 0) {
        _ref.read(soundServiceProvider).playGameOver();
      }
    }
    
    _scheduleNextAfterResult();
  }
  
  void _scheduleNextAfterResult() {
    Future.delayed(const Duration(seconds: 2), () {
      if (state.lives <= 0) {
        state = state.copyWith(state: GameState.gameOver);
      } else if (state.currentQuestionIndex < state.totalQuestions) {
        state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
        _loadNextQuestion();
      } else {
        state = state.copyWith(state: GameState.sessionComplete);
      }
    });
  }

  void restartSession() {
    // Track performance from the session that just ended
    _lastSessionCorrect = state.currentQuestionIndex - state.lives.clamp(0, 3);
    // A rough correct count: questions answered minus lives lost from initial 3
    final livesLost = 3 - state.lives.clamp(0, 3);
    final questionsAttempted = state.currentQuestionIndex - 1;
    _lastSessionCorrect = max(0, questionsAttempted - livesLost);
    _lastSessionTotal = questionsAttempted;

    // Level up if player got >= 8/10 (80% correct)
    if (_lastSessionTotal >= 5 && _lastSessionCorrect / _lastSessionTotal >= 0.8) {
      _difficultyBonus = min(5, _difficultyBonus + 1);
    }

    // Don't clear _allSessionUsedVerses — prevents repeats across sessions
    _initSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final verseGameProvider = StateNotifierProvider<VerseGameNotifier, VerseGameState>((ref) {
  final repository = ref.watch(bibleRepositoryProvider);
  return VerseGameNotifier(repository, ref);
});

class _ChapterRef {
  const _ChapterRef({required this.bookAbbr, required this.chapter});

  final String bookAbbr;
  final int chapter;
}
