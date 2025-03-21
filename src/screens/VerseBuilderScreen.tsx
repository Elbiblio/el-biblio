import React, { useState, useEffect, useCallback, useRef, memo } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  ActivityIndicator,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  interpolate,
  Extrapolation,
  runOnJS,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { Clock, Sparkle, Trophy, ArrowCounterClockwise } from '../components/Icons';
import { FlatList } from 'react-native';
import { VerseMastery, UserLevel } from '@/types';
import { bibleBooks } from '@/constants/bibleBooks';
import { parseVPLId } from '@/utils/database';
import BibleDBService from '@/utils/database';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { shuffleArray } from '@/utils/helpers';
import { Audio } from 'expo-av';
import { useGameStore } from '@/stores/game';

const { width: SCREEN_WIDTH } = Dimensions.get('window');
const WORD_SIZE = SCREEN_WIDTH / 5;
const INITIAL_TIME = 16;
const MIN_TIME = 10;
const MAX_ATTEMPTS = 4;
const REVIEW_PERIOD = 6 * 30 * 24 * 60 * 60 * 1000;
const LEVEL_UP_STREAK = 40;

// Define words to fill by level
const WORDS_BY_LEVEL: Record<UserLevel, [number, number]> = {
  novice: [3, 3], // [min, max] words to fill
  beginner: [4, 5],
  intermediate: [6, 7],
  advanced: [7, 8],
  expert: [9, 10]
};

type VerseGame = {
  id: string;
  text: string;
  reference: string;
  originalWords: string[];
  poolWords: string[];
  arrangedWords: string[];
  mastery: VerseMastery;
  prefilledCount: number;
};

type PowerUpType = 'grace' | 'discernment';

const VerseBuilderGame: React.FC = () => {
  const theme = useTheme();
  const styles = createStyles(theme);

  // State
  const [availableVersions, setAvailableVersions] = useState<string[]>([]);
  const [selectedVersion, setSelectedVersion] = useState<string>('');
  const [gameState, setGameState] = useState<VerseGame | null>(null);
  const [timeLeft, setTimeLeft] = useState(INITIAL_TIME);
  const [score, setScore] = useState(0);
  const [highScore, setHighScore] = useState(0);
  const [powerUps, setPowerUps] = useState({ grace: 3, discernment: 2 });
  const [masteredVerses, setMasteredVerses] = useState<VerseMastery[]>([]);
  const [isPlaying, setIsPlaying] = useState(false);
  const [streak, setStreak] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [userLevel, setUserLevel] = useState<UserLevel>('beginner');
  const [showSuccess, setShowSuccess] = useState(false);
  const [showCorrectAnswer, setShowCorrectAnswer] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [initialGameTime, setInitialGameTime] = useState(INITIAL_TIME);
  const [wordsToLeave, setWordsToLeave] = useState(3);
  const [nextGameState, setNextGameState] = useState<VerseGame | null>(null);
  const [isTransitioning, setIsTransitioning] = useState(false);

  // Animation Values
  const progressWidth = useSharedValue(100);
  const timerColorAnim = useSharedValue(0);
  const scaleAnim = useSharedValue(1);
  const successOpacity = useSharedValue(0);
  const fadeAnim = useSharedValue(1);

  // Refs
  const timeLeftRef = useRef(timeLeft);
  const verseQueueRef = useRef<VerseGame[]>([]);
  const hasInitialized = useRef(false);
  const soundsRef = useRef({
    tickTock: null as Audio.Sound | null,
    timeout: null as Audio.Sound | null,
    correct: null as Audio.Sound | null,
    streak: null as Audio.Sound | null,
    retry: null as Audio.Sound | null,
    cheers: null as Audio.Sound | null,
  });

  // Update timeLeftRef when timeLeft changes
  useEffect(() => {
    timeLeftRef.current = timeLeft;
  }, [timeLeft]);

  // Adjust difficulty based on streak and level
  useEffect(() => {
    // Adjust game time - decrease by 1 second for every 5 questions correctly answered
    const timeReduction = Math.floor(streak / 5);
    const newTime = Math.max(INITIAL_TIME - timeReduction, MIN_TIME);
    setInitialGameTime(newTime);
    
    // Set words to leave based on level and streak progression
    const [minWords, maxWords] = WORDS_BY_LEVEL[userLevel];
    
    // For the first 20 questions use min words, then gradually increase
    let wordsToUse = minWords;
    if (streak > 20 && maxWords > minWords) {
      // Gradually increase difficulty as streak approaches 40
      const progressionRatio = (streak - 20) / 20;
      wordsToUse = Math.min(
        minWords + Math.floor(progressionRatio * (maxWords - minWords)),
        maxWords
      );
    }
    
    setWordsToLeave(wordsToUse);
  }, [streak, userLevel]);

  // Process Verse
  const processVerse = useCallback(
    (verse: any): VerseGame | null => {
      if (!verse?.verseID || !verse.verseText) return null;
      try {
        const { bookAbbr, chapter, verse: v } = parseVPLId(verse.verseID);
        const book = bibleBooks.find((b) => b.abbreviation === bookAbbr);
        if (!book) throw new Error(`Invalid book abbreviation: ${bookAbbr}`);
        const words = verse.verseText.split(' ').filter((w: string) => w.length > 0);
        const mastery =
          masteredVerses.find((m) => m.verseId === verse.verseID) || {
            verseId: verse.verseID,
            attempts: 0,
            correct: 0,
            lastAttempt: 0,
            needsReview: true,
          };
        return {
          id: verse.verseID,
          text: verse.verseText,
          reference: `${book.name} ${chapter}:${v}`,
          originalWords: words,
          poolWords: [],
          arrangedWords: [],
          mastery,
          prefilledCount: 0,
        };
      } catch (err) {
        console.error('processVerse error:', err);
        return null;
      }
    },
    [masteredVerses]
  );

  // Load batch of verses for the current level
  const loadVerseBatch = useCallback(async () => {
    if (!selectedVersion) return;
    setIsLoading(true);
    
    try {
      console.log(`Loading batch of verses for ${userLevel} level...`);
      const verses = await BibleDBService.getRandomVerses(selectedVersion, 40);
      const processedVerses = verses
        .map(processVerse)
        .filter(Boolean) as VerseGame[];
      
      verseQueueRef.current = processedVerses;
      console.log(`Loaded ${processedVerses.length} verses for gameplay`);
      
      if (processedVerses.length === 0) {
        throw new Error('No suitable verses found for the current level');
      }
    } catch (err) {
      console.error('Failed to load verse batch:', err);
      setError('Failed to load verses. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }, [selectedVersion, userLevel, processVerse]);

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
          retry: require('../../assets/sounds/game-over.mp3'),
          cheers: require('../../assets/sounds/cheers.mp3'),
        };
        for (const [key, path] of Object.entries(soundPaths)) {
          const sound = new Audio.Sound();
          await sound.loadAsync(path);
          soundsRef.current[key as keyof typeof soundsRef.current] = sound;
        }

        // Get available Bible versions
        const versions = await BibleDBService.getInstalledVersions();
        setAvailableVersions(versions);
        if (versions.length > 0) {
          setSelectedVersion(versions[0]);
        }

        // Load user data
        const [masteryData, progressData, highScoreData] = await Promise.all([
          AsyncStorage.getItem('verseMastery'),
          AsyncStorage.getItem('userProgress'),
          AsyncStorage.getItem('highScore'),
        ]);
        
        if (masteryData) setMasteredVerses(JSON.parse(masteryData));
        if (progressData) {
          const userData = JSON.parse(progressData);
          setUserLevel(userData.level || 'beginner');
        }
        if (highScoreData) setHighScore(parseInt(highScoreData, 10));
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

  // Load initial verses after initialization is complete and version is selected
  useEffect(() => {
    if (!isLoading && selectedVersion && verseQueueRef.current.length === 0) {
      loadVerseBatch();
    }
  }, [isLoading, selectedVersion, loadVerseBatch]);

  // Start new round - updated to preload and use smooth transitions
  const startNewRound = useCallback(async () => {
    if (!selectedVersion) return;
    setError(null);
    
    // Don't show loading indicator during transitions between rounds
    const showLoading = !gameState;
    if (showLoading) setIsLoading(true);

    try {
      // If we're out of verses, load a new batch
      if (verseQueueRef.current.length === 0) {
        await loadVerseBatch();
      }
      
      // Get the next verse
      const verse = verseQueueRef.current.shift();
      if (!verse) {
        throw new Error('Failed to get next verse');
      }

      // Set up words based on difficulty (determined by wordsToLeave)
      const totalWords = verse.originalWords.length;
      const leaveCount = Math.min(wordsToLeave, totalWords - 1);
      const prefillCount = totalWords - leaveCount;
      const arrangedWords = verse.originalWords.slice(0, prefillCount);
      const poolWords = shuffleArray(verse.originalWords.slice(prefillCount));

      const newGameState = {
        ...verse,
        poolWords,
        arrangedWords,
        prefilledCount: prefillCount,
      };
      
      if (!gameState) {
        // First round, just set the state directly
        setGameState(newGameState);
        setTimeLeft(initialGameTime);
        setIsPlaying(true);
        setShowSuccess(false);
        setShowCorrectAnswer(false);
        progressWidth.value = 100;
        timerColorAnim.value = 0;
      } else {
        // Transition to next verse with animation
        setNextGameState(newGameState);
        setIsTransitioning(true);
        
        // Fade out current verse
        fadeAnim.value = withTiming(0, { duration: 300 }, () => {
          runOnJS(completeTransition)(newGameState);
        });
      }
    } catch (err) {
      console.error('Start new round error:', err);
      setError('Failed to start new round. Please try again.');
    } finally {
      if (showLoading) setIsLoading(false);
    }
  }, [selectedVersion, wordsToLeave, initialGameTime, progressWidth, timerColorAnim, loadVerseBatch, gameState, fadeAnim]);

  // Complete the transition to the next verse
  const completeTransition = useCallback((newGameState: VerseGame) => {
    setGameState(newGameState);
    setNextGameState(null);
    setTimeLeft(initialGameTime);
    setIsPlaying(true);
    setShowSuccess(false);
    setShowCorrectAnswer(false);
    progressWidth.value = 100;
    timerColorAnim.value = 0;
    
    // Fade in the new verse
    fadeAnim.value = withTiming(1, { duration: 300 }, () => {
      runOnJS(setIsTransitioning)(false);
    });
  }, [initialGameTime, progressWidth, timerColorAnim, fadeAnim]);

  // Update Mastery
  const updateMastery = useCallback(
    async (verseId: string, correct: boolean) => {
      const updated = [...masteredVerses];
      const existing = updated.find((m) => m.verseId === verseId);
      if (existing) {
        existing.attempts += 1;
        existing.correct += correct ? 1 : 0;
        existing.lastAttempt = Date.now();
        existing.needsReview = existing.attempts < MAX_ATTEMPTS || Date.now() - existing.lastAttempt > REVIEW_PERIOD;
      } else {
        updated.push({
          verseId,
          attempts: 1,
          correct: correct ? 1 : 0,
          lastAttempt: Date.now(),
          needsReview: true,
        });
      }
      setMasteredVerses(updated);
      await AsyncStorage.setItem('verseMastery', JSON.stringify(updated)).catch((err) =>
        console.error('Save mastery error:', err)
      );
    },
    [masteredVerses]
  );

  // Check Answer
  const checkAnswer = useCallback(async () => {
    if (!gameState || !isPlaying || gameState.poolWords.length > 0) return;
  
    const isCorrect = gameState.arrangedWords.join(' ').trim() === gameState.text.trim();
  
    await updateMastery(gameState.id, isCorrect);
  
    if (isCorrect) {
      setIsPlaying(false);
      soundsRef.current.correct?.setPositionAsync(0).then(() => soundsRef.current.correct?.playAsync());
  
      const newStreak = streak + 1;
      setStreak(newStreak);
  
      if (newStreak > 1 && newStreak % 5 === 0) {
        soundsRef.current.streak?.setPositionAsync(0).then(() => soundsRef.current.streak?.playAsync());
      }
  
      const timeBonus = Math.floor(timeLeft * 2);
      const newScore = score + 100 + timeBonus;
      setScore(newScore);
  
      // Submit score to gameStore
      useGameStore.getState().submitScore('verse_builder', newScore);
  
      if (newScore > highScore) {
        setHighScore(newScore);
        await AsyncStorage.setItem('highScore', newScore.toString());
        soundsRef.current.cheers?.setPositionAsync(0).then(() => soundsRef.current.cheers?.playAsync());
      }
  
      setShowSuccess(true);
      setTimeout(() => {
        setShowSuccess(false);
        startNewRound();
      }, 3500);
    } else {
      setStreak(0);
      setShowCorrectAnswer(true);
      setIsPlaying(false);
    }
  }, [gameState, isPlaying, streak, timeLeft, score, highScore, startNewRound, updateMastery]);

  // Select Word from Pool
  const selectWordFromPool = useCallback(
    (word: string) => {
      if (!gameState || !isPlaying) return;
      scaleAnim.value = withTiming(1.05, { duration: 100 }, () => {
        scaleAnim.value = withTiming(1, { duration: 100 });
      });
      setGameState((prev) => {
        if (!prev) return null;
        const newArrangedWords = [...prev.arrangedWords, word];
        const newPoolWords = prev.poolWords.filter((w) => w !== word);
        return { ...prev, poolWords: newPoolWords, arrangedWords: newArrangedWords };
      });
    },
    [gameState, isPlaying, scaleAnim]
  );

  // Auto-check when pool is empty
  useEffect(() => {
    if (isPlaying && gameState?.poolWords.length === 0) {
      setTimeout(checkAnswer, 0);
    }
  }, [gameState, isPlaying, checkAnswer]);

  // Return Word to Pool
  const returnWordToPool = useCallback(
    (word: string, index: number) => {
      if (!gameState || !isPlaying) return;
      scaleAnim.value = withTiming(1.05, { duration: 100 }, () => {
        scaleAnim.value = withTiming(1, { duration: 100 });
      });
      setGameState((prev) => {
        if (!prev) return null;
        const newArranged = [...prev.arrangedWords];
        newArranged.splice(index, 1);
        return { ...prev, arrangedWords: newArranged, poolWords: [...prev.poolWords, word] };
      });
    },
    [gameState, isPlaying, scaleAnim]
  );

  // Use Power-Up
  const usePowerUp = useCallback(
    (type: PowerUpType) => {
      if (powerUps[type] <= 0 || !gameState || !isPlaying) return;
      setPowerUps((prev) => ({ ...prev, [type]: prev[type] - 1 }));
      if (type === 'grace') {
        setTimeLeft((t) => Math.min(t + 15, INITIAL_TIME));
      } else if (type === 'discernment' && gameState.poolWords.length > 0) {
        const nextCorrectWord = gameState.originalWords[gameState.arrangedWords.length];
        if (nextCorrectWord && gameState.poolWords.includes(nextCorrectWord)) {
          selectWordFromPool(nextCorrectWord);
        }
      }
    },
    [powerUps, gameState, isPlaying, selectWordFromPool]
  );

  // Timer Logic
  useEffect(() => {
    if (!isPlaying || timeLeftRef.current <= 0) return;
    const interval = setInterval(() => {
      const newTime = timeLeftRef.current - 1;
      progressWidth.value = withTiming((newTime / INITIAL_TIME) * 100, { duration: 1000 });
      timerColorAnim.value = withTiming(1 - newTime / INITIAL_TIME, { duration: 1000 });
      setTimeLeft(newTime);
      if (newTime <= 10) soundsRef.current.tickTock?.setPositionAsync(0).then(() => soundsRef.current.tickTock?.playAsync());
      if (newTime <= 0) {
        setIsPlaying(false);
        soundsRef.current.timeout?.setPositionAsync(0).then(() => soundsRef.current.timeout?.playAsync());
      }
    }, 1000);
    return () => clearInterval(interval);
  }, [isPlaying, progressWidth, timerColorAnim]);

  // Start Game When Ready
  useEffect(() => {
    if (!isLoading && !gameState && selectedVersion) startNewRound();
  }, [isLoading, gameState, selectedVersion, startNewRound]);

  // Success Animation
  useEffect(() => {
    if (showSuccess) {
      successOpacity.value = withTiming(1, { duration: 300 });
      setTimeout(() => (successOpacity.value = withTiming(0, { duration: 300 })), 1200);
    }
  }, [showSuccess, successOpacity]);

  // Undo Last Word
  const undoLastWord = useCallback(() => {
    if (!gameState || !isPlaying || gameState.arrangedWords.length <= gameState.prefilledCount) return;
    setGameState((prev) => {
      if (!prev) return null;
      const newArranged = [...prev.arrangedWords];
      const lastWord = newArranged.pop() as string;
      return { ...prev, arrangedWords: newArranged, poolWords: [...prev.poolWords, lastWord] };
    });
  }, [gameState, isPlaying]);

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

  const gameAreaStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scaleAnim.value }],
  }));

  const successOverlayStyle = useAnimatedStyle(() => ({
    opacity: successOpacity.value,
  }));

  // Updated animated styles
  const fadeStyle = useAnimatedStyle(() => ({
    opacity: fadeAnim.value,
  }));

  // Memoized WordTile Component
  const WordTile = memo(({ word, onPress, disabled, isPrefilled }: { word: string; onPress: () => void; disabled: boolean; isPrefilled?: boolean }) => (
    <TouchableOpacity
      style={[styles.wordTile, { backgroundColor: getWordColor(word) }, isPrefilled && styles.prefilledWord]}
      onPress={onPress}
      disabled={disabled}
    >
      <Text style={styles.wordText}>{word}</Text>
    </TouchableOpacity>
  ));

  // Render Functions
  const renderPoolWord = useCallback(
    ({ item }: { item: string }) => (
      <WordTile
        word={item}
        onPress={() => selectWordFromPool(item)}
        disabled={!isPlaying}
      />
    ),
    [selectWordFromPool, isPlaying]
  );

  const renderArrangedWords = useCallback(() => {
    if (!gameState) return null;
    return (
      <View style={styles.arrangementContainer}>
        <View style={styles.arrangementHeader}>
          <Text style={styles.sectionTitle}>Arrange the Verse:</Text>
          <TouchableOpacity
            style={[styles.undoButton, (gameState.arrangedWords.length <= gameState.prefilledCount || !isPlaying) && styles.undoButtonDisabled]}
            onPress={undoLastWord}
            disabled={gameState.arrangedWords.length <= gameState.prefilledCount || !isPlaying}
          >
            <ArrowCounterClockwise
              size={18}
              color={gameState.arrangedWords.length <= gameState.prefilledCount || !isPlaying ? `${theme.colors.text.secondary}50` : theme.colors.text.secondary}
            />
          </TouchableOpacity>
        </View>
        <View style={styles.arrangementContent}>
          {gameState.arrangedWords.length === 0 ? (
            <Text style={styles.emptyText}>Start arranging words here</Text>
          ) : (
            gameState.arrangedWords.map((word, index) => (
              <WordTile
                key={`arranged-${word}-${index}`}
                word={word}
                onPress={() => index >= gameState.prefilledCount && returnWordToPool(word, index)}
                disabled={index < gameState.prefilledCount || !isPlaying}
                isPrefilled={index < gameState.prefilledCount}
              />
            ))
          )}
        </View>
      </View>
    );
  }, [gameState, returnWordToPool, isPlaying, undoLastWord]);

  const renderErrorState = useCallback(
    () =>
      error ? (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={() => { setError(null); startNewRound(); }}>
            <Text style={styles.retryButtonText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      ) : null,
    [error, startNewRound]
  );

  // Update version selector to reload verses for the selected version
  const renderVersionSelector = useCallback(() => (
    <View style={styles.versionSelector}>
      {availableVersions.map((version) => (
        <TouchableOpacity
          key={version}
          style={[styles.versionButton, selectedVersion === version && styles.versionButtonSelected]}
          onPress={async () => {
            if (selectedVersion !== version) {
              setSelectedVersion(version);
              verseQueueRef.current = []; // Clear queue
              await loadVerseBatch(); // Load verses for new version
              startNewRound();
            }
          }}
        >
          <Text style={[styles.versionText, selectedVersion === version && styles.versionTextSelected]}>
            {version.split('_')[1]?.toUpperCase() || version}
          </Text>
        </TouchableOpacity>
      ))}
    </View>
  ), [availableVersions, selectedVersion, startNewRound, loadVerseBatch]);

  // Render
  return (
    <View style={styles.container}>
      {isLoading && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="large" color={theme.colors.primary} />
          <Text style={styles.loadingText}>Loading...</Text>
        </View>
      )}
      {renderErrorState()}
      {renderVersionSelector()}
      <View style={styles.header}>
        <View style={styles.scoreContainer}>
          <Trophy color={theme.colors.primary} size={24} />
          <Text style={styles.scoreText}>{score}</Text>
          <Text style={styles.highScoreText}>High: {highScore}</Text>
        </View>
        <View style={styles.powerUps}>
          <TouchableOpacity onPress={() => usePowerUp('grace')} disabled={powerUps.grace <= 0 || !isPlaying}>
            <Text style={[styles.powerUpText, powerUps.grace <= 0 && styles.powerUpDisabled]}>🕊️×{powerUps.grace}</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => usePowerUp('discernment')} disabled={powerUps.discernment <= 0 || !isPlaying}>
            <Text style={[styles.powerUpText, powerUps.discernment <= 0 && styles.powerUpDisabled]}>🔍×{powerUps.discernment}</Text>
          </TouchableOpacity>
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
      {streak > 1 && (
        <View style={styles.streakContainer}>
          <Sparkle color={theme.colors.secondary} size={16} />
          <Text style={styles.streakText}>Streak: {streak}x</Text>
        </View>
      )}
      {gameState && (
        <Animated.View style={[styles.gameArea, gameAreaStyle, fadeStyle]}>
          <Text style={styles.reference}>{gameState.reference}</Text>
          {renderArrangedWords()}
          {showCorrectAnswer && (
            <View style={styles.correctAnswerContainer}>
              <Text style={styles.correctAnswerText}>{gameState.text}</Text>
              <TouchableOpacity style={styles.retryButton} onPress={startNewRound}>
                <Text style={styles.retryButtonText}>Try Again</Text>
              </TouchableOpacity>
            </View>
          )}
          {!showCorrectAnswer && gameState.poolWords.length > 0 && (
            <View style={styles.poolContainer}>
              <FlatList
                data={gameState.poolWords}
                renderItem={renderPoolWord}
                keyExtractor={(item, index) => `pool-${item}-${index}`}
                numColumns={Math.floor(SCREEN_WIDTH / (WORD_SIZE + theme.spacing.xs * 2))}
                columnWrapperStyle={styles.poolColumn}
                contentContainerStyle={styles.poolContent}
              />
            </View>
          )}
        </Animated.View>
      )}
      {showSuccess && (
        <Animated.View style={[styles.successOverlay, successOverlayStyle]}>
          <View style={styles.successContent}>
            <Text style={styles.successText}>Correct! 🎉</Text>
            {gameState && (
              <Text style={styles.fullVerseText}>
                {gameState.text}
              </Text>
            )}
            <Text style={styles.referenceText}>{gameState?.reference}</Text>
          </View>
        </Animated.View>
      )}
      {timeLeft <= 0 && !isPlaying && (
        <BlurView intensity={20} style={styles.overlay}>
          <View style={styles.gameOverContainer}>
            <Text style={styles.gameOverText}>Game Over!</Text>
            <Text style={styles.finalScore}>Score: {score}</Text>
            <TouchableOpacity
              style={styles.retryButton}
              onPress={() => {
                setScore(0);
                setStreak(0);
                startNewRound();
                soundsRef.current.retry?.setPositionAsync(0).then(() => soundsRef.current.retry?.playAsync());
              }}
            >
              <Text style={styles.retryButtonText}>Retry</Text>
            </TouchableOpacity>
          </View>
        </BlurView>
      )}
    </View>
  );
};

// Helper Functions
const getWordColor = (word: string) => {
  const articlePrepositions = new Set([
    'a', 'an', 'the', 'in', 'on', 'at', 'by', 'for', 'with', 'to', 'from',
    'of', 'and', 'but', 'or', 'as', 'if', 'when', 'than', 'because',
    'while', 'before', 'after', 'since', 'until', 'about', 'like', 'through'
  ]);
  const lowerWord = word.toLowerCase().replace(/[.,;:!?'"]/g, '');
  if (articlePrepositions.has(lowerWord)) return '#2C3E50';
  const hash = word.split('').reduce((a, b) => a + b.charCodeAt(0), 0);
  const colors = [
    '#1A365D', '#2D3748', '#3C366B', '#1E3A8A', '#1F2937',
    '#4A5568', '#312E81', '#065F46', '#5B21B6', '#7B341E'
  ];
  return colors[hash % colors.length];
};

// Styles
const createStyles = (theme: Theme) =>
  StyleSheet.create({
    container: { flex: 1, backgroundColor: theme.colors.background, padding: theme.spacing.md },
    versionSelector: { flexDirection: 'row', justifyContent: 'center', marginBottom: theme.spacing.md },
    versionButton: { padding: theme.spacing.sm, margin: theme.spacing.xs, borderRadius: theme.borderRadius.sm, backgroundColor: theme.colors.surface },
    versionButtonSelected: { backgroundColor: theme.colors.primary },
    versionText: { color: theme.colors.text.primary, fontSize: 14 },
    versionTextSelected: { color: '#FFF' },
    header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: theme.spacing.md },
    scoreContainer: { flexDirection: 'row', alignItems: 'center', gap: theme.spacing.xs },
    scoreText: { fontSize: 18, color: theme.colors.primary, fontWeight: 'bold' },
    highScoreText: { fontSize: 14, color: theme.colors.text.secondary, marginLeft: theme.spacing.sm },
    timerContainer: { marginBottom: theme.spacing.md },
    timerLabel: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', marginBottom: theme.spacing.xs },
    progressBarContainer: { height: 4, width: '100%', backgroundColor: `${theme.colors.text.secondary}20`, borderRadius: theme.borderRadius.full, overflow: 'hidden' },
    progressBar: { height: '100%', borderRadius: theme.borderRadius.full },
    timerText: { marginLeft: theme.spacing.xs, color: theme.colors.text.primary, fontWeight: '600' },
    powerUps: { flexDirection: 'row', gap: theme.spacing.sm },
    powerUpText: { fontSize: 16, color: theme.colors.primary },
    powerUpDisabled: { opacity: 0.5 },
    streakContainer: { flexDirection: 'row', alignItems: 'center', alignSelf: 'center', paddingVertical: theme.spacing.xs, paddingHorizontal: theme.spacing.sm, backgroundColor: `${theme.colors.secondary}20`, borderRadius: theme.borderRadius.full, marginBottom: theme.spacing.sm },
    streakText: { color: theme.colors.secondary, marginLeft: theme.spacing.xs, fontWeight: '500' },
    gameArea: { flex: 1 },
    reference: { textAlign: 'center', color: theme.colors.text.secondary, fontSize: 16, marginBottom: theme.spacing.md },
    arrangementContainer: { padding: theme.spacing.md, backgroundColor: `${theme.colors.surface}80`, borderRadius: theme.borderRadius.lg, marginBottom: theme.spacing.lg },
    arrangementHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: theme.spacing.sm },
    arrangementContent: { flexDirection: 'row', flexWrap: 'wrap', gap: theme.spacing.sm, justifyContent: 'center' },
    sectionTitle: { color: theme.colors.text.secondary },
    undoButton: { padding: theme.spacing.xs, borderRadius: theme.borderRadius.full, backgroundColor: `${theme.colors.surface}60` },
    undoButtonDisabled: { opacity: 0.4 },
    wordTile: { padding: theme.spacing.sm, borderRadius: theme.borderRadius.md, justifyContent: 'center', alignItems: 'center', minWidth: WORD_SIZE, marginHorizontal: theme.spacing.xs },
    prefilledWord: { opacity: 0.7, borderWidth: 1, borderColor: theme.colors.primary },
    wordText: { color: '#FFFFFF', fontSize: 14, textAlign: 'center', fontWeight: '500' },
    emptyText: { color: theme.colors.text.secondary, flex: 1, textAlign: 'center' },
    poolContainer: { flex: 1 },
    poolContent: { paddingVertical: theme.spacing.xs },
    poolColumn: { justifyContent: 'center', marginVertical: theme.spacing.xs, flexWrap: 'wrap' },
    successOverlay: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: 'rgba(0,0,0,0.7)'
    },
    successContent: {
      padding: theme.spacing.lg,
      backgroundColor: `${theme.colors.surface}F0`,
      borderRadius: theme.borderRadius.lg,
      maxWidth: '90%',
      alignItems: 'center',
    },
    successText: {
      fontSize: 24,
      color: theme.colors.primary,
      fontWeight: 'bold',
      marginBottom: theme.spacing.md,
    },
    fullVerseText: {
      color: theme.colors.text.primary,
      textAlign: 'center',
      fontSize: 16,
      lineHeight: 24,
      marginBottom: theme.spacing.sm,
      fontWeight: '500',
    },
    referenceText: {
      color: theme.colors.text.secondary,
      marginTop: theme.spacing.xs,
      fontSize: 14,
    },
    overlay: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, justifyContent: 'center', alignItems: 'center' },
    gameOverContainer: { backgroundColor: theme.colors.background, padding: theme.spacing.xl, borderRadius: theme.borderRadius.lg, alignItems: 'center' },
    gameOverText: { fontSize: 24, color: theme.colors.primary, marginBottom: theme.spacing.md },
    finalScore: { fontSize: 18, color: theme.colors.text.primary, marginBottom: theme.spacing.lg },
    retryButton: { backgroundColor: theme.colors.primary, paddingVertical: theme.spacing.sm, paddingHorizontal: theme.spacing.lg, borderRadius: theme.borderRadius.full },
    retryButtonText: { color: '#FFF', fontSize: 16, fontWeight: '600' },
    loadingOverlay: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', alignItems: 'center', zIndex: 10 },
    loadingText: { color: theme.colors.primary, marginTop: theme.spacing.sm },
    errorContainer: { padding: theme.spacing.md, backgroundColor: `${theme.colors.error}20`, borderRadius: theme.borderRadius.md, marginBottom: theme.spacing.md, alignItems: 'center' },
    errorText: { color: theme.colors.error, marginBottom: theme.spacing.sm },
    correctAnswerContainer: { padding: theme.spacing.md, backgroundColor: `${theme.colors.error}10`, borderRadius: theme.borderRadius.md, marginBottom: theme.spacing.lg, alignItems: 'center' },
    correctAnswerText: { color: theme.colors.text.primary, marginBottom: theme.spacing.md, textAlign: 'center', lineHeight: 22 },
  });

export default VerseBuilderGame;