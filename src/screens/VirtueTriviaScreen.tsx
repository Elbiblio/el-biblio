import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';

import { View, Text, TouchableOpacity, InteractionManager } from 'react-native';

import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSequence,
  withSpring,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';
import { ActivityIndicator } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Star, Trophy, Sparkle, Clock } from '../components/Icons';
import { UserLevel, VerseResult, VirtueGroups as VirtueGroupsConst, RootStackParamList } from '@/types';

import { useTheme } from '@/contexts/ThemeContext';
import { observer } from 'mobx-react-lite';
import { useVirtueStore, useGameStore } from '@/stores/StoreProvider';
import SoundManager from '@/utils/SoundManager';
import SoundSettingsModal from '@/components/SoundSettingsModal';
import { playCue } from '@/services/audio';
import * as Haptics from 'expo-haptics';

import { shuffleArray } from '@/utils/helpers';
import { PIConfetti } from 'react-native-fast-confetti';
import VirtueTriviaComplete from '@/components/VirtueTriviaComplete';
import BibleDBService, { parseVPLId } from '@/utils/database';
import { bibleBooks } from '@/constants/bibleBooks';
import { ScrollView } from 'react-native-gesture-handler';
import { LinearGradient } from 'expo-linear-gradient';
import createStyles from './VirtueTriviaScreen.styles';

// game store now comes from StoreProvider

// Constants
const MAX_QUESTIONS = 10;
const VIRTUES_TO_LEVEL_UP = 4;

// Type definitions
interface QuizQuestion {
  verseId: string;
  verseText: string;
  reference: string;
  book: string;
  chapter: number;
  verse: number;
  options: string[];
  correctAnswer: string;
}

interface GameState {
  questions: QuizQuestion[];
  currentQuestionIndex: number;
  score: number;
  streak: number;
  answered: boolean;
  selectedAnswer: string | null;
  correctAnswer: string;
  gameOver: boolean;
  correctAnswersCount: number;
}

type AdvanceOptions = {
  isCorrect?: boolean;
  latestScore?: number;
  correctAnswers?: number;
};

// Timer settings by level
const timerSettings: Record<UserLevel, number> = {
  novice: 35,
  beginner: 30,
  intermediate: 20,
  advanced: 15,
  expert: 10
};

const VirtueTriviaScreen = () => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const insets = useSafeAreaInsets();
  const gameStore = useGameStore();
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();

  // Virtue store
  const virtueStore = useVirtueStore();
  const { virtues, userProgress, fetchVirtues, fetchUserProgress } = virtueStore;

  // Build a local fallback list of virtues for offline-first UX
  const fallbackVirtues = useMemo(() => {
    const groups = VirtueGroupsConst;
    const ids = [
      ...groups.foundational.virtues,
      ...groups.derived.virtues,
      ...groups.compound.virtues,
    ] as string[];
    const dedup = Array.from(new Set(ids));
    return dedup.map(id => ({ id, name: id } as any));
  }, []);
  const displayedVirtues = virtues && virtues.length > 0 ? virtues : fallbackVirtues;

  // State
  const [gameState, setGameState] = useState<GameState>({
    questions: [],
    currentQuestionIndex: 0,
    score: 0,
    streak: 0,
    answered: false,
    selectedAnswer: null,
    correctAnswer: '',
    gameOver: false,
    correctAnswersCount: 0
  });

  const [isLoading, setIsLoading] = useState(true);
  const [showSoundSettings, setShowSoundSettings] = useState(false);
  const [selectedVirtue, setSelectedVirtue] = useState<string>('');
  const [showVirtueSelector, setShowVirtueSelector] = useState(true);
  const [timeLeft, setTimeLeft] = useState(15);
  const [userLevel, setUserLevel] = useState<UserLevel>('novice');
  const [showSuccess, setShowSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Animation Values
  const progressWidth = useSharedValue(100);
  const timerColorAnim = useSharedValue(0);
  const successOpacity = useSharedValue(0);
  const optionPressScale = useSharedValue(0.9);
  const scorePulse = useSharedValue(0.9);
  const bestPulse = useSharedValue(0.9);
  const streakPulse = useSharedValue(0.9);

  const optionPressStyle = useAnimatedStyle(() => ({
    transform: [{ scale: optionPressScale.value }],
  }));

  const scoreCardStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scorePulse.value }],
  }));

  const bestCardStyle = useAnimatedStyle(() => ({
    transform: [{ scale: bestPulse.value }],
  }));

  const streakCardStyle = useAnimatedStyle(() => ({
    transform: [{ scale: streakPulse.value }],
  }));

  // Refs
  const timeLeftRef = useRef(timeLeft);
  const confettiRef = useRef<any>(null);
  const hasInitialized = useRef(false);
  const autoAdvanceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const gameStateRef = useRef(gameState);
  const minimumQuestionsToPass = 7; // 70% correct answers to complete a virtue

  const personalBest = gameStore.getPersonalBest('virtue_trivia');
  const displayedHighScore = Math.max(personalBest, gameState.score);
  const isNewHighScore = gameState.score > personalBest;

  // Keep refs synced with latest values
  useEffect(() => {
    timeLeftRef.current = timeLeft;
  }, [timeLeft]);

  useEffect(() => {
    gameStateRef.current = gameState;
  }, [gameState]);

  useEffect(() => {
    return () => {
      if (autoAdvanceRef.current) {
        clearTimeout(autoAdvanceRef.current);
      }
    };
  }, []);

  useEffect(() => {
    if (!gameStore.state.lastSynced && !gameStore.state.isLoading) {
      void gameStore.initialize();
    }
  }, [gameStore.state.lastSynced, gameStore.state.isLoading]);

  // Fetch virtues on mount
  useEffect(() => {
    fetchVirtues();
    fetchUserProgress();
  }, [fetchVirtues, fetchUserProgress]);

  // Defer init so first frame paints (iOS performance)
  useEffect(() => {
    setIsLoading(true);
    const task = InteractionManager.runAfterInteractions(() => {
      if (hasInitialized.current) return;
      hasInitialized.current = true;
      const run = async () => {
        try {
          await SoundManager.init();
          setTimeLeft(timerSettings.novice);
        } catch (err) {
          console.error('Initialization error:', err);
          setError('Failed to initialize app. Please restart.');
        } finally {
          setIsLoading(false);
        }
      };
      run();
    });
    return () => task.cancel();
  }, []);

  // Generate wrong options for book-only quiz
  const generateBookOptions = useCallback((correctBook: string): string[] => {
    const allBooks = bibleBooks.map(book => book.name);
    const otherBooks = allBooks.filter(book => book !== correctBook);
    const wrongOptions = shuffleArray(otherBooks).slice(0, 3);
    const options = shuffleArray([correctBook, ...wrongOptions]);
    return options;
  }, []);

  // Generate wrong options for book+chapter quiz
  const generateBookChapterOptions = useCallback((correctBook: string, correctChapter: number): string[] => {
    const bookObj = bibleBooks.find(b => b.name === correctBook);
    const correctAnswer = `${correctBook} ${correctChapter}`;
    const wrongOptions = [];
    
    // Add same book, different chapter
    if (bookObj && bookObj.chapters > 1) {
      let randomChapter;
      do {
        randomChapter = Math.floor(Math.random() * bookObj.chapters) + 1;
      } while (randomChapter === correctChapter);
      wrongOptions.push(`${correctBook} ${randomChapter}`);
    }
    
    // Add different books
    const otherBooks = bibleBooks.filter(book => book.name !== correctBook);
    for (let i = 0; wrongOptions.length < 3 && i < 10; i++) {
      const randomBook = otherBooks[Math.floor(Math.random() * otherBooks.length)];
      const randomChapter = Math.floor(Math.random() * randomBook.chapters) + 1;
      const option = `${randomBook.name} ${randomChapter}`;
      if (!wrongOptions.includes(option)) {
        wrongOptions.push(option);
      }
    }
    
    // Shuffle and return
    const options = shuffleArray([correctAnswer, ...wrongOptions.slice(0, 3)]);
    return options;
  }, []);

  // Process verse data into quiz questions
  const processVerses = useCallback((verses: VerseResult[]): QuizQuestion[] => {
    return verses.map(verse => {
      try {
        // Parse verse ID to get book, chapter, verse
        const { bookAbbr, chapter, verse: verseNum } = parseVPLId(verse.verseID);
        const bookObj = bibleBooks.find(b => b.abbreviation === bookAbbr);
        
        if (!bookObj) {
          throw new Error(`Book not found for abbreviation: ${bookAbbr}`);
        }
        
        const bookName = bookObj.name;
        const reference = `${bookName} ${chapter}:${verseNum}`;
        const isExpertLevel = userLevel === 'expert';
        
        // Generate options based on level
        let options: string[];
        if (isExpertLevel) {
          // Expert level: book + chapter
          options = generateBookChapterOptions(bookName, chapter);
        } else {
          // Other levels: book only
          options = generateBookOptions(bookName);
        }
        
        return {
          verseId: verse.verseID,
          verseText: verse.verseText,
          reference,
          book: bookName,
          chapter,
          verse: verseNum,
          options,
          correctAnswer: isExpertLevel ? `${bookName} ${chapter}` : bookName,
        };
      } catch (error) {
        console.error('Error processing verse:', error);
        // Return a fallback question
        return {
          verseId: verse.verseID,
          verseText: verse.verseText,
          reference: 'Unknown',
          book: 'Unknown',
          chapter: 1,
          verse: 1,
          options: ['Unknown', 'Unknown', 'Unknown', 'Unknown'],
          correctAnswer: 'Unknown',
        };
      }
    });
  }, [userLevel, generateBookOptions, generateBookChapterOptions]);

  // Search for verses related to virtue using getVersesByVirtue helper
  const searchVirtueVerses = useCallback(async (virtue: string) => {
    setIsLoading(true);
    setError(null);
    setSelectedVirtue(virtue);
    
    try {
      // Get installed versions to use default one
      const versions = await BibleDBService.getInstalledVersions();
      if (!versions || versions.length === 0) {
        throw new Error('No Bible versions installed');
      }
      
      // Use the first available version
      const version = versions[0];
      
      // Map incoming virtue (often an id) to a keyword expected by DB service
      let virtueKey = virtue;
      const v = virtues.find(v => v.id === virtue);
      if (v?.name) virtueKey = v.name.toLowerCase();
      // Use getVersesByVirtue to find related verses; if keywords missing, fallback to random verses
      let results: VerseResult[] = [];
      try {
        results = await BibleDBService.getVersesByVirtue(version, virtueKey, MAX_QUESTIONS);
      } catch (e) {
        // Fallback: random verses if no keywords defined for this virtue
        results = await BibleDBService.getRandomVerses(version, MAX_QUESTIONS);
      }
      
      if (!results || results.length === 0) {
        throw new Error(`No verses found for virtue: ${virtue}`);
      }
      
      // Process verses into quiz questions
      const questions = processVerses(results);
      
      if (questions.length === 0) {
        throw new Error('Failed to process verses into questions');
      }
      
      // Initialize game state
      setGameState({
        questions,
        currentQuestionIndex: 0,
        score: 0,
        streak: 0,
        answered: false,
        selectedAnswer: null,
        correctAnswer: questions[0].correctAnswer,
        gameOver: false,
        correctAnswersCount: 0
      });
      
      // Set timer based on level
      setTimeLeft(timerSettings[userLevel]);
      
      // Hide virtue selector
      setShowVirtueSelector(false);
      
      // Update virtue attempt count - handled by the virtue store
      // The store will handle the actual progress update and level up logic
    } catch (err) {
      console.error('Error searching virtue verses:', err);
      setError(`Failed to load verses: ${(err as Error).message}`);
    } finally {
      setIsLoading(false);
    }
  }, [userLevel, processVerses, virtues]);

  const play = async (name: 'tickTock' | 'timeout' | 'correct' | 'streak' | 'wrong' | 'gameOver' | 'cheers') => {
    await playCue(name);
  };

  useEffect(() => {
    scorePulse.value = withSequence(
      withTiming(1.06, { duration: 140 }),
      withSpring(1, { damping: 6, stiffness: 220 })
    );
  }, [gameState.score, scorePulse]);

  const timerStyle = useAnimatedStyle(() => {
    const color = interpolate(timerColorAnim.value, [0, 0.6, 1], [0, 1, 2], Extrapolation.CLAMP);
    return {
      backgroundColor: color <= 0.5 ? theme.colors.success : color <= 1.5 ? theme.colors.warning : theme.colors.error,
    };
  });

  const progressBarStyle = useAnimatedStyle(() => {
    const color = interpolate(timerColorAnim.value, [0, 0.6, 1], [0, 1, 2], Extrapolation.CLAMP);
    return {
      position: 'absolute',
      left: 0,
      top: 0,
      bottom: 0,
      width: `${progressWidth.value}%`,
      backgroundColor: color <= 0.5 ? theme.colors.success : color <= 1.5 ? theme.colors.warning : theme.colors.error,
    };
  });

  const successOverlayStyle = useAnimatedStyle(() => ({
    opacity: successOpacity.value,
  }));

  // Calculate progress and remaining virtues for level up
  const calculateLevelProgress = useCallback(() => {
    const completedCount = getCompletedCount();
    const remainingCount = VIRTUES_TO_LEVEL_UP - completedCount;
    const progressPercent = Math.min(100, (completedCount / VIRTUES_TO_LEVEL_UP) * 100);
    
    return {
      completedCount,
      remainingCount: Math.max(0, remainingCount),
      progressPercent
    };
  }, [userProgress]);

  const getCompletedCount = () => {
    // Get actual completed count from API
    const virtueProgress = userProgress || {};
    const completedCount = Object.values(virtueProgress).filter(
      (progress: any) => progress.current_level >= 3 // Completed means max level (3)
    ).length;
    return completedCount;
  };

  const advanceToNext = useCallback((options?: AdvanceOptions) => {
    const current = gameStateRef.current;
    const isCorrect = options?.isCorrect ?? (current.selectedAnswer === current.correctAnswer);
    const latestScore = options?.latestScore ?? current.score;
    const correctAnswers = options?.correctAnswers ?? current.correctAnswersCount;
    const nextIndex = current.currentQuestionIndex + 1;

    if (nextIndex >= current.questions.length) {
      const computedCorrectAnswers = isCorrect ? correctAnswers + 1 : correctAnswers;
      if (computedCorrectAnswers === current.questions.length) {
        play('cheers');
        requestAnimationFrame(() => { confettiRef.current?.restart?.(); });
      } else {
        play('gameOver');
      }
      void gameStore.submitScore('virtue_trivia', latestScore);

      if (isCorrect && selectedVirtue) {
        const virtuePassed = computedCorrectAnswers >= minimumQuestionsToPass;
        if (virtuePassed) {
          virtueStore
            .updateUserProgress(selectedVirtue, {
              points: Math.floor(latestScore / 10),
              minutes: 0,
              challenges: 1,
            })
            .catch(error => {
              console.warn('Failed to update virtue progress:', error);
            });
        }
      }

      setGameState(prev => ({
        ...prev,
        gameOver: true,
        correctAnswersCount: computedCorrectAnswers,
      }));
    } else {
      setGameState(prev => ({
        ...prev,
        currentQuestionIndex: nextIndex,
        answered: false,
        selectedAnswer: null,
        correctAnswer: prev.questions[nextIndex].correctAnswer,
      }));
      setTimeLeft(timerSettings[userLevel]);
      progressWidth.value = 100;
      timerColorAnim.value = 0;
    }
  }, [gameStore, minimumQuestionsToPass, progressWidth, selectedVirtue, timerColorAnim, timerSettings, userLevel, virtueStore]);

  const scheduleAdvance = useCallback((options?: AdvanceOptions) => {
    if (autoAdvanceRef.current) {
      clearTimeout(autoAdvanceRef.current);
    }
    autoAdvanceRef.current = setTimeout(() => {
      advanceToNext(options);
    }, 1500);
  }, [advanceToNext]);

  const handleAnswerSelect = useCallback(async (answer: string) => {
    const current = gameStateRef.current;
    if (current.answered) return;

    const isCorrect = answer === current.correctAnswer;

    // Micro interaction
    optionPressScale.value = withTiming(0.97, { duration: 80 }, () => {
      optionPressScale.value = withTiming(1, { duration: 120 });
    });

    // Haptics and sound
    if (isCorrect) {
      requestAnimationFrame(() => { confettiRef.current?.restart?.(); });
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      play('correct');
    } else {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      play('wrong');
    }

    // Update streak
    const newStreak = isCorrect ? current.streak + 1 : 0;

    // Play streak sound on multiples of 5
    if (isCorrect && newStreak > 1 && newStreak % 5 === 0) {
      play('streak');
    }

    // Calculate score
    const remainingTime = timeLeftRef.current;
    const timeBonus = Math.floor(remainingTime * 2);
    const streakBonus = isCorrect ? Math.max(0, newStreak - 1) * 10 : 0; // small streak multiplier
    const questionScore = isCorrect ? 100 + timeBonus + streakBonus : 0;
    const newScore = current.score + questionScore;

    // Update correctAnswersCount if answer is correct
    const newCorrectAnswersCount = isCorrect ? 
      current.correctAnswersCount + 1 : 
      current.correctAnswersCount;

    // Update game state
    setGameState(prev => ({
      ...prev,
      answered: true,
      selectedAnswer: answer,
      score: newScore,
      streak: newStreak,
      correctAnswersCount: newCorrectAnswersCount
    }));

    // Show success animation for correct answers
    if (isCorrect) {
      setShowSuccess(true);
      successOpacity.value = withTiming(1, { duration: 300 });
      setTimeout(() => {
        setShowSuccess(false);
        successOpacity.value = withTiming(0, { duration: 300 });
      }, 1000);
    }

    scheduleAdvance({
      isCorrect,
      latestScore: newScore,
      correctAnswers: newCorrectAnswersCount
    });
  }, [scheduleAdvance, successOpacity]);

  const handleManualAdvance = useCallback(() => {
    const current = gameStateRef.current;
    if (!current.answered) return;

    if (autoAdvanceRef.current) {
      clearTimeout(autoAdvanceRef.current);
      autoAdvanceRef.current = null;
    }

    advanceToNext({
      isCorrect: current.selectedAnswer === current.correctAnswer,
      latestScore: current.score,
      correctAnswers: current.correctAnswersCount,
    });
  }, [advanceToNext]);

  // Start new game
  const startNewGame = useCallback(() => {
    setShowVirtueSelector(true);
    setSelectedVirtue('');
    setGameState({
      questions: [],
      currentQuestionIndex: 0,
      score: 0,
      streak: 0,
      answered: false,
      selectedAnswer: null,
      correctAnswer: '',
      gameOver: false,
      correctAnswersCount: 0
    });
  }, []);

  // Timer logic
  useEffect(() => {
    if (showVirtueSelector || gameState.answered || gameState.gameOver || showSoundSettings) return;

    const interval = setInterval(() => {
      const newTime = timeLeftRef.current - 1;
      progressWidth.value = withTiming((newTime / timerSettings[userLevel]) * 100, { duration: 1000 });
      timerColorAnim.value = withTiming(1 - newTime / timerSettings[userLevel], { duration: 1000 });
      setTimeLeft(newTime);
      
      if (newTime <= 3) {
        play('tickTock');
      }
      
      if (newTime <= 0) {
        clearInterval(interval);
        handleAnswerSelect(''); // Force incorrect answer
        play('timeout');
      }
    }, 1000);
    
    return () => clearInterval(interval);
  }, [showVirtueSelector, gameState.answered, gameState.gameOver, userLevel, handleAnswerSelect, showSoundSettings]);

  useEffect(() => {
    if (isNewHighScore) {
      bestPulse.value = withSequence(
        withTiming(1.1, { duration: 160 }),
        withSpring(1, { damping: 5, stiffness: 240 })
      );
    }
  }, [isNewHighScore, bestPulse]);

  useEffect(() => {
    if (gameState.streak > 1) {
      streakPulse.value = withSequence(
        withTiming(1.1, { duration: 160 }),
        withSpring(1, { damping: 5, stiffness: 240 })
      );
    } else {
      streakPulse.value = withTiming(1);
    }
  }, [gameState.streak, streakPulse]);

  // Render virtue selector
  const renderVirtueSelector = useCallback(() => {
    const { remainingCount, progressPercent } = calculateLevelProgress();

    return (
      <ScrollView contentContainerStyle={styles.virtueSelectorContainer}>
        <Text style={styles.title}>Choose a Virtue</Text>
        <Text style={styles.subtitle}>Select a virtue to find related Bible verses</Text>

        <View style={styles.levelInfoContainer}>
          <Text style={styles.levelText}>Current Level: {userLevel.charAt(0).toUpperCase() + userLevel.slice(1)}</Text>
          {remainingCount > 0 && (
            <Text style={styles.levelProgressText}>
              Complete {remainingCount} more {remainingCount === 1 ? 'virtue' : 'virtues'} to level up
            </Text>
          )}

          <View style={styles.levelProgressBarContainer}>
            <View style={[styles.levelProgressBar, { width: `${progressPercent}%` }]} />
          </View>
        </View>

        <View style={styles.virtueGrid}>
          {displayedVirtues.map(virtue => {
            const virtueData = userProgress[virtue.id] || { current_level: 0, total_levels: 3 };
            const isCompleted = virtueData.current_level >= virtueData.total_levels;

            return (
              <TouchableOpacity
                key={virtue.id}
                style={[
                  styles.virtueButton,
                  isCompleted && styles.completedVirtueButton,
                ]}
                onPress={() => searchVirtueVerses(virtue.id)}
                hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                accessibilityLabel={`Play trivia for ${virtue.name}`}
              >
                <Text
                  style={[
                    styles.virtueButtonText,
                    isCompleted && styles.completedVirtueText,
                  ]}
                >
                  {virtue.name.charAt(0).toUpperCase() + virtue.name.slice(1)}
                </Text>
                {isCompleted && (
                  <View style={styles.completedBadge}>
                    <Text style={styles.completedBadgeText}>✓</Text>
                  </View>
                )}
              </TouchableOpacity>
            );
          })}
        </View>
      </ScrollView>
    );
  }, [calculateLevelProgress, displayedVirtues, searchVirtueVerses, styles, userLevel, userProgress]);

  // Render current question
  const renderQuestion = useCallback(() => {
    if (!gameState.questions.length) return null;

    const currentQuestion = gameState.questions[gameState.currentQuestionIndex];
    const questionNumber = gameState.currentQuestionIndex + 1;
    const totalQuestions = gameState.questions.length;

    return (
      <View style={styles.questionContainer}>
        <View style={styles.progressHeader}>
          <Text style={styles.progressText}>Question {questionNumber}/{totalQuestions}</Text>
          <Text style={styles.scoreText}>Score: {gameState.score}</Text>
        </View>

        <Text style={styles.questionText}>
          Which {userLevel === 'expert' ? 'book and chapter' : 'book'} contains this verse?
        </Text>

        <View style={styles.verseContainer}>
          <Text style={styles.verseText}>"{currentQuestion.verseText}"</Text>
        </View>

        <View style={styles.optionsContainer}>
          {currentQuestion.options.map((option, index) => (
            <Animated.View key={index} style={optionPressStyle}>
              <TouchableOpacity
                style={[
                  styles.optionButton,
                  gameState.answered && option === currentQuestion.correctAnswer && styles.correctOption,
                  gameState.answered &&
                  option === gameState.selectedAnswer &&
                  option !== currentQuestion.correctAnswer &&
                  styles.incorrectOption,
                ]}
                onPress={() => {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
                  handleAnswerSelect(option);
                }}
                disabled={gameState.answered}
                hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                accessibilityLabel={`Answer ${String.fromCharCode(65 + index)}: ${option}`}
              >
                <Text
                  style={[
                    styles.optionText,
                    gameState.answered && option === currentQuestion.correctAnswer && styles.correctOptionText,
                    gameState.answered &&
                    option === gameState.selectedAnswer &&
                    option !== currentQuestion.correctAnswer &&
                    styles.incorrectOptionText,
                  ]}
                >
                  {option}
                </Text>
              </TouchableOpacity>
            </Animated.View>
          ))}
        </View>

        {gameState.answered && gameState.selectedAnswer !== currentQuestion.correctAnswer && (
          <Text style={styles.correctAnswerText}>
            Correct answer: {currentQuestion.correctAnswer}
          </Text>
        )}

        {gameState.answered && (
          <View style={styles.nextButtonRow}>
            <TouchableOpacity
              style={styles.nextButton}
              onPress={handleManualAdvance}
              hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
              accessibilityLabel={gameState.currentQuestionIndex === gameState.questions.length - 1 ? 'Finish quiz' : 'Next question'}
            >
              <Text style={styles.nextButtonText}>
                {gameState.currentQuestionIndex === gameState.questions.length - 1 ? 'Finish' : 'Next'}
              </Text>
            </TouchableOpacity>
          </View>
        )}
      </View>
    );
  }, [gameState, userLevel, handleAnswerSelect, handleManualAdvance, styles]);

  // Render game over screen
  const renderGameOver = useCallback(() => {
    const correctAnswers = gameState.correctAnswersCount;
    const totalAnswered = gameState.questions.length;
    const bestScore = Math.max(personalBest, gameState.score);

    const { remainingCount } = calculateLevelProgress();

    return (
      <VirtueTriviaComplete
        virtueName={selectedVirtue.charAt(0).toUpperCase() + selectedVirtue.slice(1)}
        score={gameState.score}
        highScore={bestScore}
        correctAnswers={correctAnswers}
        totalQuestions={totalAnswered}
        userLevelLabel={userLevel.charAt(0).toUpperCase() + userLevel.slice(1)}
        remainingToLevelUp={remainingCount}
        onPlayAgain={startNewGame}
        onGoBack={() => navigation.goBack()}
      />
    );
  }, [gameState, personalBest, startNewGame, selectedVirtue, userProgress, userLevel, calculateLevelProgress, navigation]);

  // Main Render
  return (
    <View
      style={[
        styles.container,
        {
          paddingTop: theme.spacing.md + (insets.top || 0),
          paddingBottom: theme.spacing.md + (insets.bottom || 0),
        },
      ]}
    >
      <LinearGradient
        colors={[`${theme.colors.primary}26`, `${theme.colors.background}`, `${theme.colors.secondary}18`]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.gradientBg}
        pointerEvents="none"
      />
      {isLoading && (
        <View style={styles.loadingOverlay} accessibilityLabel="Preparing your questions">
          <ActivityIndicator size="large" color={theme.colors.primary} />
          <Text style={styles.loadingText}>Preparing your questions...</Text>
        </View>
      )}

      {error && (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity
            style={styles.retryButton}
            onPress={startNewGame}
            hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
            accessibilityLabel="Try again"
          >
            <Text style={styles.retryButtonText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      )}
      
      {!error && showVirtueSelector && !isLoading && renderVirtueSelector()}
      
      {!error && !showVirtueSelector && !gameState.gameOver && !isLoading && (
        <>
          <View style={styles.header}>
            <View style={styles.headerTopRow}>
              <Text style={styles.headerTitle}>Virtue Trivia</Text>
              <TouchableOpacity
                style={styles.soundButton}
                onPress={() => setShowSoundSettings(true)}
                hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
                accessibilityLabel="Sound settings"
              >
                <Text style={styles.soundButtonText}>Sound</Text>
              </TouchableOpacity>
            </View>
            <View style={styles.metricRow}>
              <Animated.View style={[styles.metricCard, scoreCardStyle]}> 
                <LinearGradient
                  colors={[`${theme.colors.primary}55`, `${theme.colors.primary}10`]}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 1 }}
                  style={styles.metricGradient}
                />
                <Trophy color={'#FFF'} size={18} />
                <Text style={styles.metricLabel}>Score</Text>
                <Text style={styles.metricValue}>{gameState.score}</Text>
              </Animated.View>
              <Animated.View style={[styles.metricCard, bestCardStyle]}>
                <LinearGradient
                  colors={[`${theme.colors.secondary}55`, `${theme.colors.secondary}10`]}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 1 }}
                  style={styles.metricGradient}
                />
                <Star color={'#FFF'} size={18} />
                <Text style={styles.metricLabel}>Best</Text>
                <Text style={styles.metricValue}>{displayedHighScore}</Text>
                {isNewHighScore && (
                  <View style={styles.newBadge}>
                    <Text style={styles.newBadgeText}>NEW</Text>
                  </View>
                )}
              </Animated.View>
              <Animated.View style={[styles.metricCard, streakCardStyle]}>
                <LinearGradient
                  colors={['rgba(255,190,92,0.6)', 'rgba(255,140,0,0.12)']}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 1 }}
                  style={styles.metricGradient}
                />
                <Sparkle color={'#FFF'} size={18} />
                <Text style={styles.metricLabel}>Streak</Text>
                <Text style={styles.metricValue}>{gameState.streak > 1 ? `${gameState.streak}x` : '—'}</Text>
              </Animated.View>
            </View>
          </View>
          
          <View style={styles.timerContainer}>
            <View style={styles.timerLabel}>
              <Clock color={theme.colors.text.primary} size={20} />
              <Text style={styles.timerText}>{timeLeft}s</Text>
            </View>
            <View style={styles.progressBarContainer}>
              <Animated.View style={[styles.progressBar, progressBarStyle]} />
            </View>
          </View>
          
          {renderQuestion()}
          
          {showSuccess && (
            <Animated.View style={[styles.successOverlay, successOverlayStyle]}>
              <View style={styles.successContent}>
                <Text style={styles.successText}>Correct! 🎉</Text>
              </View>
            </Animated.View>
          )}
        </>
      )}
      
      {!error && !showVirtueSelector && gameState.gameOver && !isLoading && renderGameOver()}

      <SoundSettingsModal visible={showSoundSettings} onClose={() => setShowSoundSettings(false)} />
    </View>
  );
};


export default observer(VirtueTriviaScreen);