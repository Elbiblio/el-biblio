import React, { useState, useEffect, useCallback, useRef } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';
import { ActivityIndicator } from 'react-native';
import { Star, Trophy, Sparkle, Clock } from '../components/Icons';
import { UserLevel, VerseResult } from '@/types';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { observer } from 'mobx-react-lite';
import { useVirtueStore, useGameStore } from '@/stores/StoreProvider';
import { Audio } from 'expo-av';

import { shuffleArray } from '@/utils/helpers';
import BibleDBService, { parseVPLId } from '@/utils/database';
import { bibleBooks } from '@/constants/bibleBooks';
import { ScrollView } from 'react-native-gesture-handler';
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

// Timer settings by level
const timerSettings: Record<UserLevel, number> = {
  novice: 35,
  beginner: 30,
  intermediate: 25,
  advanced: 20,
  expert: 15
};

const VirtueTriviaScreen = () => {
  const theme = useTheme();
  const styles = createStyles(theme);
  const gameStore = useGameStore();

  // Virtue store
  const { virtues, userProgress, fetchVirtues, fetchUserProgress } = useVirtueStore();

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
  const [selectedVirtue, setSelectedVirtue] = useState<string>('');
  const [showVirtueSelector, setShowVirtueSelector] = useState(true);
  const [timeLeft, setTimeLeft] = useState(15);
  const [highScore, setHighScore] = useState(0);
  const [userLevel, setUserLevel] = useState<UserLevel>('novice');
  const [showSuccess, setShowSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Animation Values
  const progressWidth = useSharedValue(100);
  const timerColorAnim = useSharedValue(0);
  const successOpacity = useSharedValue(0);

  // Refs
  const timeLeftRef = useRef(timeLeft);
  const soundsRef = useRef({
    tickTock: null as Audio.Sound | null,
    timeout: null as Audio.Sound | null,
    correct: null as Audio.Sound | null,
    streak: null as Audio.Sound | null,
    wrong: null as Audio.Sound | null,
    gameOver: null as Audio.Sound | null,
    cheers: null as Audio.Sound | null,
  });
  const hasInitialized = useRef(false);
  const minimumQuestionsToPass = 7; // 70% correct answers to complete a virtue

  // Update timeLeftRef when timeLeft changes
  useEffect(() => {
    timeLeftRef.current = timeLeft;
  }, [timeLeft]);

  // Fetch virtues on mount
  useEffect(() => {
    fetchVirtues();
    fetchUserProgress();
  }, [fetchVirtues, fetchUserProgress]);

  // Initialize App
  useEffect(() => {
    const initializeApp = async () => {
      if (hasInitialized.current) return;
      hasInitialized.current = true;
      setIsLoading(true);

      try {
        // Load sound effects
        const soundPaths = {
          tickTock: require('../../assets/sounds/tick-tock.wav'),
          timeout: require('../../assets/sounds/timeout.mp3'),
          correct: require('../../assets/sounds/correct.mp3'),
          streak: require('../../assets/sounds/streak.wav'),
          wrong: require('../../assets/sounds/wrong.mp3'),
          gameOver: require('../../assets/sounds/game-over.mp3'),
          cheers: require('../../assets/sounds/cheers.mp3'),
        };
        
        for (const [key, path] of Object.entries(soundPaths)) {
          const sound = new Audio.Sound();
          await sound.loadAsync(path);
          soundsRef.current[key as keyof typeof soundsRef.current] = sound;
        }

        // Load user data from API
        // await fetchVirtues(); // This is now handled by the useEffect above
        
        // Set default timer
        setTimeLeft(timerSettings.novice);
      } catch (err) {
        console.error('Initialization error:', err);
        setError('Failed to initialize app. Please restart.');
      } finally {
        setIsLoading(false);
      }
    };
    
    initializeApp();

    return () => {
      Object.values(soundsRef.current).forEach(sound => 
        sound?.unloadAsync().catch(console.error)
      );
    };
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
      
      // Use getVersesByVirtue to find related verses
      const results = await BibleDBService.getVersesByVirtue(version, virtue, MAX_QUESTIONS);
      
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
  }, [userLevel, processVerses]);

  // Handle answer selection
  const handleAnswerSelect = useCallback(async (answer: string) => {
    if (gameState.answered) return;
    
    const isCorrect = answer === gameState.correctAnswer;
    // const currentQuestion = gameState.questions[gameState.currentQuestionIndex];


    
    // Play sound
    if (isCorrect) {
      soundsRef.current.correct?.setPositionAsync(0).then(() => 
        soundsRef.current.correct?.playAsync()
      );
    } else {
      soundsRef.current.wrong?.setPositionAsync(0).then(() => 
        soundsRef.current.wrong?.playAsync()
      );
    }
    
    // Update streak
    const newStreak = isCorrect ? gameState.streak + 1 : 0;
    
    // Play streak sound on multiples of 5
    if (isCorrect && newStreak > 1 && newStreak % 5 === 0) {
      soundsRef.current.streak?.setPositionAsync(0).then(() => 
        soundsRef.current.streak?.playAsync()
      );
    }
    
    // Calculate score
    const timeBonus = Math.floor(timeLeft * 2);
    const questionScore = isCorrect ? 100 + timeBonus : 0;
    const newScore = gameState.score + questionScore;
    
    // Update high score if needed
    if (newScore > highScore) {
      setHighScore(newScore);
      // AsyncStorage.setItem('VirtueTriviaScreenHighScore', newScore.toString()); // Removed
    }
    
    // Update correctAnswersCount if answer is correct
    const newCorrectAnswersCount = isCorrect ? 
      gameState.correctAnswersCount + 1 : 
      gameState.correctAnswersCount;
    
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
    
    // Move to next question after delay
    setTimeout(async () => {
      const nextIndex = gameState.currentQuestionIndex + 1;
      
      if (nextIndex >= gameState.questions.length) {
        // Game over logic
        const correctAnswers = isCorrect ? 
          gameState.correctAnswersCount + 1 : 
          gameState.correctAnswersCount;
        
        const virtuePassed = correctAnswers >= minimumQuestionsToPass;
        
        // Check for perfect score and play cheers
        if (correctAnswers === gameState.questions.length) {
          soundsRef.current.cheers?.setPositionAsync(0).then(() => 
            soundsRef.current.cheers?.playAsync()
          );
        } else {
          // Play regular game over sound
          soundsRef.current.gameOver?.setPositionAsync(0).then(() => 
            soundsRef.current.gameOver?.playAsync()
          );
        }

        gameStore.submitScore('virtue_trivia', newScore);
        
        // Update virtues progress
        // This logic needs to be adapted to use userProgress from the store
        // For now, we'll just update the local state, which will be persisted by the store
        // The store will handle the actual progress update and level up logic
        // setVirtuesProgress(prev => {
        //   const updated = { 
        //     ...prev, 
        //     [selectedVirtue]: {
        //       completed: virtuePassed || prev[selectedVirtue]?.completed || false,
        //       highScore: Math.max(newScore, prev[selectedVirtue]?.highScore || 0),
        //       attempts: prev[selectedVirtue]?.attempts || 1
        //     }
        //   };
          
        //   AsyncStorage.setItem('VirtueTriviaProgress', JSON.stringify(updated));
          
        //   // Check if ready to level up (4 or more virtues completed)
        //   const completedVirtues = Object.values(updated).filter(v => v.completed).length;
          
        //   if (completedVirtues >= VIRTUES_TO_LEVEL_UP) {
        //     // Level up
        //     const nextLevels: Record<UserLevel, UserLevel> = {
        //       novice: 'beginner',
        //       beginner: 'intermediate',
        //       intermediate: 'advanced',
        //       advanced: 'expert',
        //       expert: 'expert'
        //     };
            
        //     const nextLevel = nextLevels[userLevel];
            
        //     if (nextLevel !== userLevel) {
        //       AsyncStorage.getItem('userProgress').then(data => {
        //         const userData = data ? JSON.parse(data) : {};
        //         userData.level = nextLevel;
        //         AsyncStorage.setItem('userProgress', JSON.stringify(userData));
        //         setUserLevel(nextLevel);
        //       });
              
        //       // Reset virtues progress for next level
        //       const resetProgress = virtues.reduce((acc, virtue) => {
        //         acc[virtue] = { completed: false, highScore: 0, attempts: 0 };
        //         return acc;
        //       }, {} as VirtueProgress);
              

        
        setGameState(prev => ({ 
          ...prev, 
          gameOver: true,
          correctAnswersCount: correctAnswers // ensure final value is set
        }));
      } else {
        // Next question
        setGameState(prev => ({
          ...prev,
          currentQuestionIndex: nextIndex,
          answered: false,
          selectedAnswer: null,
          correctAnswer: prev.questions[nextIndex].correctAnswer
        }));
        
        // Reset timer
        setTimeLeft(timerSettings[userLevel]);
        progressWidth.value = 100;
        timerColorAnim.value = 0;
      }
    }, 1500);
  }, [gameState, timeLeft, highScore, userLevel, successOpacity, selectedVirtue, minimumQuestionsToPass]);

  // Timer logic
  useEffect(() => {
    if (showVirtueSelector || gameState.answered || gameState.gameOver) return;
    
    const interval = setInterval(() => {
      const newTime = timeLeftRef.current - 1;
      progressWidth.value = withTiming((newTime / timerSettings[userLevel]) * 100, { duration: 1000 });
      timerColorAnim.value = withTiming(1 - newTime / timerSettings[userLevel], { duration: 1000 });
      setTimeLeft(newTime);
      
      if (newTime <= 3) {
        soundsRef.current.tickTock?.setPositionAsync(0).then(() => 
          soundsRef.current.tickTock?.playAsync()
        );
      }
      
      if (newTime <= 0) {
        clearInterval(interval);
        handleAnswerSelect(''); // Force incorrect answer
        soundsRef.current.timeout?.setPositionAsync(0).then(() => 
          soundsRef.current.timeout?.playAsync()
        );
      }
    }, 1000);
    
    return () => clearInterval(interval);
  }, [showVirtueSelector, gameState.answered, gameState.gameOver, userLevel, handleAnswerSelect]);

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
      (progress: any) => progress.current_level > 0
    ).length;
    return completedCount;
  };

  // Animated Styles
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

  // Render virtue selector
  const renderVirtueSelector = useCallback(() => {
    const { completedCount, remainingCount, progressPercent } = calculateLevelProgress();
    
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
          {virtues.map(virtue => {
            const virtueData = userProgress[virtue.id] || { current_level: 0, total_levels: 3 };
            const isCompleted = virtueData.current_level >= virtueData.total_levels;
            
            return (
              <TouchableOpacity
                key={virtue.id}
                style={[
                  styles.virtueButton,
                  isCompleted && styles.completedVirtueButton
                ]}
                onPress={() => searchVirtueVerses(virtue.id)}
              >
                <Text style={[
                  styles.virtueButtonText,
                  isCompleted && styles.completedVirtueText
                ]}>
                  {virtue.name.charAt(0).toUpperCase() + virtue.name.slice(1)}
                </Text>
                {isCompleted && (
                  <View style={styles.completedBadge}>
                    <Text style={styles.completedBadgeText}>✓</Text>
                  </View>
                )}
                {/* Removed virtueScoreText as it's not in VirtueProgress type */}
              </TouchableOpacity>
            );
          })}
        </View>
      </ScrollView>
    );
  }, [searchVirtueVerses, styles, userLevel, userProgress, calculateLevelProgress]);

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
            <TouchableOpacity
              key={index}
              style={[
                styles.optionButton,
                gameState.answered && option === currentQuestion.correctAnswer && styles.correctOption,
                gameState.answered && 
                option === gameState.selectedAnswer && 
                option !== currentQuestion.correctAnswer && 
                styles.incorrectOption
              ]}
              onPress={() => handleAnswerSelect(option)}
              disabled={gameState.answered}
            >
              <Text 
                style={[
                  styles.optionText,
                  gameState.answered && option === currentQuestion.correctAnswer && styles.correctOptionText,
                  gameState.answered && 
                  option === gameState.selectedAnswer && 
                  option !== currentQuestion.correctAnswer && 
                  styles.incorrectOptionText
                ]}
              >
                {option}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
        
        {gameState.answered && gameState.selectedAnswer !== currentQuestion.correctAnswer && (
          <Text style={styles.correctAnswerText}>
            Correct answer: {currentQuestion.correctAnswer}
          </Text>
        )}
      </View>
    );
  }, [gameState, userLevel, handleAnswerSelect, styles]);

  // Render game over screen
  const renderGameOver = useCallback(() => {
    const correctAnswers = gameState.correctAnswersCount;
    const totalAnswered = gameState.questions.length;
    const percentCorrect = Math.round((correctAnswers / totalAnswered) * 100) || 0;
    const virtuePassed = correctAnswers >= minimumQuestionsToPass;
    const virtueStatus = userProgress[selectedVirtue];
    
    const isPerfectScore = correctAnswers === totalAnswered;
    const isHighScore = gameState.score > highScore;
    
    // Update high score if needed
    if (isHighScore) {
      setHighScore(gameState.score);
      // AsyncStorage.setItem('VirtueTriviaScreenHighScore', gameState.score.toString()); // Removed
    }

    const { completedCount, remainingCount } = calculateLevelProgress();
    
    return (
      <View style={styles.gameOverContainer}>
        <Text style={styles.gameOverTitle}>
          {isPerfectScore ? 'Perfect Score! 🎉' : 'Quiz Complete!'}
        </Text>
        
        <View style={styles.resultsSummary}>
          <Text style={styles.virtueResultText}>
            Virtue: <Text style={styles.highlightText}>{selectedVirtue.charAt(0).toUpperCase() + selectedVirtue.slice(1)}</Text>
          </Text>
          
          <Text style={styles.finalScoreText}>Final Score: {gameState.score}</Text>
          
          <View style={styles.correctnessContainer}>
            <Text style={styles.correctnessText}>
              {correctAnswers} of {totalAnswered} correct ({percentCorrect}%)
            </Text>
            <View style={styles.correctnessBar}>
              <View style={[styles.correctnessProgress, { width: `${percentCorrect}%` }]} />
            </View>
          </View>
          
          {virtuePassed ? (
            <View style={styles.passedContainer}>
              <Text style={styles.passedText}>Virtue Mastered! ✓</Text>
            </View>
          ) : (
            <View style={styles.failedContainer}>
              <Text style={styles.failedText}>
                Need {minimumQuestionsToPass - correctAnswers} more correct to master
              </Text>
            </View>
          )}
        </View>
        
        <View style={styles.statsContainer}>
          <Text style={styles.statsText}>High Score: {highScore}</Text>
          <Text style={styles.statsText}>Current Level: {virtueStatus?.current_level || 0}</Text>
          <Text style={styles.statsText}>Total Levels: {virtueStatus?.total_levels || 3}</Text>
        </View>
        
        <View style={styles.levelProgressInfoContainer}>
          <Text style={styles.levelProgressInfoText}>
            Level: {userLevel.charAt(0).toUpperCase() + userLevel.slice(1)}
          </Text>
          
          {remainingCount > 0 ? (
            <Text style={styles.levelProgressInfoText}>
              Complete {remainingCount} more {remainingCount === 1 ? 'virtue' : 'virtues'} to level up
            </Text>
          ) : (
            <Text style={styles.levelMaxText}>
              {userLevel === 'expert' ? 'Maximum level reached!' : 'Ready to level up!'}
            </Text>
          )}
        </View>
        
        <TouchableOpacity style={styles.retryButton} onPress={startNewGame}>
          <Text style={styles.retryButtonText}>Play Again</Text>
        </TouchableOpacity>
      </View>
    );
  }, [gameState, highScore, startNewGame, styles, selectedVirtue, userProgress, minimumQuestionsToPass, userLevel, calculateLevelProgress]);

  // Main Render
  return (
    <View style={styles.container}>
      {isLoading && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="large" color={theme.colors.primary} />
          <Text style={styles.loadingText}>Loading...</Text>
        </View>
      )}
      
      {error && (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={startNewGame}>
            <Text style={styles.retryButtonText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      )}
      
      {!error && showVirtueSelector && !isLoading && renderVirtueSelector()}
      
      {!error && !showVirtueSelector && !gameState.gameOver && !isLoading && (
        <>
          <View style={styles.header}>
            <View style={styles.scoreContainer}>
              <Trophy color={theme.colors.primary} size={24} />
              <Text style={styles.currentScoreText}>{gameState.score}</Text>
              <Text style={styles.highScoreText}>High: {highScore}</Text>
            </View>
            
            {gameState.streak > 1 && (
              <View style={styles.streakContainer}>
                <Sparkle color={theme.colors.secondary} size={16} />
                <Text style={styles.streakText}>Streak: {gameState.streak}x</Text>
              </View>
            )}
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
    </View>
  );
};

// Styles
const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
    padding: theme.spacing.md,
  },
  
  // Loading and Error
  loadingOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 10,
  },
  loadingText: {
    color: theme.colors.primary,
    marginTop: theme.spacing.sm,
  },
  errorContainer: {
    padding: theme.spacing.md,
    backgroundColor: `${theme.colors.error}20`,
    borderRadius: theme.borderRadius.md,
    marginVertical: theme.spacing.lg,
    alignItems: 'center',
  },
  errorText: {
    color: theme.colors.error,
    marginBottom: theme.spacing.md,
    textAlign: 'center',
  },
  
  // Virtue Selector
  virtueSelectorContainer: {
    padding: theme.spacing.md,
    alignItems: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.lg,
    textAlign: 'center',
  },
  virtueGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: theme.spacing.sm,
  },
  virtueButton: {
    backgroundColor: theme.colors.surface,
    paddingVertical: theme.spacing.md,
    paddingHorizontal: theme.spacing.lg,
    borderRadius: theme.borderRadius.md,
    margin: theme.spacing.xs,
    minWidth: 120,
    alignItems: 'center',
    position: 'relative',
  },
  virtueButtonText: {
    color: theme.colors.text.primary,
    fontSize: 16,
    fontWeight: '500',
  },
  completedVirtueButton: {
    backgroundColor: `${theme.colors.success}20`,
  },
  completedVirtueText: {
    color: theme.colors.success,
  },
  completedBadge: {
    position: 'absolute',
    top: -5,
    right: -5,
    backgroundColor: theme.colors.success,
    width: 20,
    height: 20,
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
  },
  completedBadgeText: {
    color: '#FFF',
    fontSize: 12,
    fontWeight: 'bold',
  },
  virtueScoreText: {
    fontSize: 12,
    color: theme.colors.text.secondary,
    marginTop: 4,
  },
  
  // Level Info
  levelInfoContainer: {
    width: '100%',
    padding: theme.spacing.md,
    marginBottom: theme.spacing.lg,
    backgroundColor: `${theme.colors.primary}10`,
    borderRadius: theme.borderRadius.md,
    alignItems: 'center',
  },
  levelText: {
    fontSize: 18,
    fontWeight: '600',
    color: theme.colors.primary,
    marginBottom: theme.spacing.sm,
  },
  levelProgressText: {
    fontSize: 14,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.sm,
  },
  levelProgressBarContainer: {
    width: '100%',
    height: 8,
    backgroundColor: `${theme.colors.primary}20`,
    borderRadius: 4,
    overflow: 'hidden',
  },
  levelProgressBar: {
    height: '100%',
    backgroundColor: theme.colors.primary,
  },
  
  // Header
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.md,
  },
  scoreContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  currentScoreText: {
    fontSize: 18,
    color: theme.colors.primary,
    fontWeight: 'bold',
  },
  highScoreText: {
    fontSize: 14,
    color: theme.colors.text.secondary,
    marginLeft: theme.spacing.sm,
  },
  streakContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    backgroundColor: `${theme.colors.secondary}20`,
    borderRadius: theme.borderRadius.full,
  },
  streakText: {
    color: theme.colors.secondary,
    marginLeft: theme.spacing.xs,
    fontWeight: '500',
  },
  
  // Timer
  timerContainer: {
    marginBottom: theme.spacing.md,
  },
  timerLabel: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme.spacing.xs,
  },
  timerText: {
    marginLeft: theme.spacing.xs,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  progressBarContainer: {
    height: 4,
    width: '100%',
    backgroundColor: `${theme.colors.text.secondary}20`,
    borderRadius: theme.borderRadius.full,
    overflow: 'hidden',
  },
  progressBar: {
    height: '100%',
    borderRadius: theme.borderRadius.full,
  },
  
  // Question
  progressHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.md,
  },
  progressText: {
    color: theme.colors.text.secondary,
    fontSize: 14,
  },
  scoreText: {
    color: theme.colors.primary,
    fontWeight: '500',
    fontSize: 14,
  },
  questionContainer: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.md,
    ...theme.shadows.md,
  },
  questionText: {
    fontSize: 18,
    fontWeight: '500',
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
    textAlign: 'center',
  },
  verseContainer: {
    backgroundColor: `${theme.colors.primary}08`,
    borderRadius: theme.borderRadius.md,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.lg,
  },
  verseText: {
    fontSize: 16,
    lineHeight: 24,
    color: theme.colors.text.primary,
    fontStyle: 'italic',
    textAlign: 'center',
  },
  optionsContainer: {
    gap: theme.spacing.sm,
  },
  optionButton: {
    backgroundColor: `${theme.colors.surface}80`,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}30`,
    borderRadius: theme.borderRadius.md,
    padding: theme.spacing.md,
    alignItems: 'center',
  },
  optionText: {
    fontSize: 16,
    color: theme.colors.text.primary,
    fontWeight: '500',
  },
  correctOption: {
    backgroundColor: `${theme.colors.success}20`,
    borderColor: theme.colors.success,
  },
  correctOptionText: {
    color: theme.colors.success,
    fontWeight: 'bold',
  },
  incorrectOption: {
    backgroundColor: `${theme.colors.error}20`,
    borderColor: theme.colors.error,
  },
  incorrectOptionText: {
    color: theme.colors.error,
    fontWeight: 'bold',
  },
  correctAnswerText: {
    marginTop: theme.spacing.md,
    color: theme.colors.success,
    fontWeight: '500',
    textAlign: 'center',
  },
  
  // Success Overlay
  successOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0,0,0,0.3)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 5,
  },
  successContent: {
    ...theme.shadows.md,
    backgroundColor: 'rgba(255,255,255,0.9)',
    paddingVertical: theme.spacing.md,
    paddingHorizontal: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,    
    elevation: 5,
  },
  successText: {
    color: theme.colors.success,
    fontSize: 24,
    fontWeight: 'bold',
  },
  
  // Game Over
  gameOverContainer: {
    flex: 1,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    alignItems: 'center',
    justifyContent: 'space-between',
    shadowColor: theme.colors.shadow,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  gameOverTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: theme.colors.primary,
    marginBottom: theme.spacing.lg,
  },
  resultsSummary: {
    width: '100%',
    alignItems: 'center',
    backgroundColor: `${theme.colors.background}80`,
    borderRadius: theme.borderRadius.md,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.lg,
  },
  virtueResultText: {
    fontSize: 18,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  highlightText: {
    color: theme.colors.primary,
    fontWeight: '600',
  },
  finalScoreText: {
    fontSize: 24,
    fontWeight: 'bold',
    color: theme.colors.primary,
    marginBottom: theme.spacing.md,
  },
  correctnessContainer: {
    width: '100%',
    marginBottom: theme.spacing.md,
  },
  correctnessText: {
    fontSize: 16,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.sm,
    textAlign: 'center',
  },
  correctnessBar: {
    width: '100%',
    height: 8,
    backgroundColor: `${theme.colors.text.secondary}20`,
    borderRadius: 4,
    overflow: 'hidden',
  },
  correctnessProgress: {
    height: '100%',
    backgroundColor: theme.colors.primary,
  },
  passedContainer: {
    padding: theme.spacing.sm,
    backgroundColor: `${theme.colors.success}20`,
    borderRadius: theme.borderRadius.md,
    alignItems: 'center',
    width: '100%',
  },
  passedText: {
    color: theme.colors.success,
    fontWeight: '600',
  },
  failedContainer: {
    padding: theme.spacing.sm,
    backgroundColor: `${theme.colors.warning}20`,
    borderRadius: theme.borderRadius.md,
    alignItems: 'center',
    width: '100%',
  },
  failedText: {
    color: theme.colors.warning,
    fontWeight: '600',
  },
  statsContainer: {
    width: '100%',
    marginVertical: theme.spacing.md,
    alignItems: 'center',
  },
  statsText: {
    fontSize: 16,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.xs,
  },
  levelProgressInfoContainer: {
    width: '100%',
    padding: theme.spacing.md,
    backgroundColor: `${theme.colors.primary}10`,
    borderRadius: theme.borderRadius.md,
    marginBottom: theme.spacing.md,
    alignItems: 'center',
  },
  levelProgressInfoText: {
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
    textAlign: 'center',
  },
  levelMaxText: {
    color: theme.colors.primary,
    fontWeight: '600',
    textAlign: 'center',
  },
  retryButton: {
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.md,
    paddingHorizontal: theme.spacing.lg,
    borderRadius: theme.borderRadius.full,
    marginTop: theme.spacing.md,
  },
  retryButtonText: {
    color: '#FFF',
  },
});

export default observer(VirtueTriviaScreen);