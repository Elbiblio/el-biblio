// verseGame.tsx
import React, { useState, useEffect, useCallback, useRef, memo } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Alert,
  Dimensions,
  ActivityIndicator,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSpring,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { Heart, Clock, Sparkle, Trophy } from '../components/Icons';
import { FlatList } from 'react-native';
import { VerseMastery, VerseResult, UserLevel } from '@/types';
import { bibleBooks } from '@/constants/bibleBooks';
import { parseVPLId } from '@/utils/database';
import BibleDBService from '@/utils/database';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { shuffleArray } from '@/utils/helpers';
import { Audio } from 'expo-av';

const { width: SCREEN_WIDTH } = Dimensions.get('window');
const WORD_SIZE = SCREEN_WIDTH / 5;
const INITIAL_TIME = 45;
const MAX_ATTEMPTS = 4;
const REVIEW_PERIOD = 6 * 30 * 24 * 60 * 60 * 1000;

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
  const [selectedVersion, setSelectedVersion] = useState('');
  const [gameState, setGameState] = useState<VerseGame | null>(null);
  const [timeLeft, setTimeLeft] = useState(INITIAL_TIME);
  const [score, setScore] = useState(0);
  const [powerUps, setPowerUps] = useState({ grace: 3, discernment: 2 });
  const [masteredVerses, setMasteredVerses] = useState<VerseMastery[]>([]);
  const [isPlaying, setIsPlaying] = useState(false);
  const [streak, setStreak] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const [userLevel, setUserLevel] = useState<UserLevel>('beginner');
  const [showSuccess, setShowSuccess] = useState(false);
  const [showCorrectAnswer, setShowCorrectAnswer] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Animation Values
  const progressWidth = useSharedValue(100);
  const timerColorAnim = useSharedValue(0);
  const scaleAnim = useSharedValue(1);
  const successOpacity = useSharedValue(0);

  // Refs
  const timeLeftRef = useRef(timeLeft);
  const verseQueueRef = useRef<VerseGame[]>([]);
  const tickTockSound = useRef<Audio.Sound | null>(null);
  const timeoutSound = useRef<Audio.Sound | null>(null);
  const gameOverSound = useRef<Audio.Sound | null>(null);
  const retrySound = useRef<Audio.Sound | null>(null);
  const correctSound = useRef<Audio.Sound | null>(null);
  const streakSound = useRef<Audio.Sound | null>(null);
  const cheersSound = useRef<Audio.Sound | null>(null);

  useEffect(() => {
    timeLeftRef.current = timeLeft;
  }, [timeLeft]);

  // Load Sounds
  useEffect(() => {
    const loadSounds = async () => {
      try {
        const sounds = [
          { ref: tickTockSound, path: require('../../assets/sounds/tick-tock.wav') },
          { ref: cheersSound, path: require('../../assets/sounds/cheers.mp3') },
          { ref: timeoutSound, path: require('../../assets/sounds/timeout.mp3') },
          { ref: gameOverSound, path: require('../../assets/sounds/game-over.mp3') },
          { ref: retrySound, path: require('../../assets/sounds/game-over.mp3') },
          { ref: correctSound, path: require('../../assets/sounds/correct.mp3') },
          { ref: streakSound, path: require('../../assets/sounds/streak.wav') },
        ];
        for (const { ref, path } of sounds) {
          const sound = new Audio.Sound();
          await sound.loadAsync(path);
          ref.current = sound;
        }
      } catch (error) {
        console.error('Failed to load sounds:', error);
      }
    };
    loadSounds();

    return () => {
      [tickTockSound, timeoutSound, gameOverSound, correctSound, streakSound, cheersSound, retrySound].forEach(
        async (ref) => ref.current && (await ref.current.unloadAsync())
      );
    };
  }, []);

  // Play Tick-Tock Sound
  useEffect(() => {
    const playTickTock = async () => {
      if (timeLeft <= 10 && timeLeft > 0 && isPlaying && tickTockSound.current) {
        try {
          await tickTockSound.current.setPositionAsync(0);
          await tickTockSound.current.playAsync();
        } catch (error) {
          console.error('Failed to play tick-tock sound:', error);
        }
      }
    };
    playTickTock();
  }, [timeLeft, isPlaying]);

  // Load Mastery Data
  useEffect(() => {
    const loadMastery = async () => {
      try {
        const stored = await AsyncStorage.getItem('verseMastery');
        if (stored) setMasteredVerses(JSON.parse(stored));
      } catch (error) {
        console.error('Failed to load mastery data:', error);
      }
    };
    loadMastery();
  }, []);

  // Load available Bible versions
  useEffect(() => {
    const loadVersions = async () => {
      try {
        const versions = await BibleDBService.getInstalledVersions();
        setAvailableVersions(versions);
        
        // Set default version (use first available or keep current if it's valid)
        if (versions.length > 0) {
          if (!selectedVersion || !versions.includes(selectedVersion)) {
            setSelectedVersion(versions[0]);
          }
        }
      } catch (error) {
        console.error('Failed to load Bible versions:', error);
        setError('Failed to load Bible versions. Please restart the app.');
      }
    };
    
    loadVersions();
  }, []);

  // Process Verse
  const processVerse = useCallback(
    (verse: any): VerseGame | null => {
      try {
        if (!verse) return null;
        const { bookAbbr, chapter, verse: v } = parseVPLId(verse.verseID);
        const book = bibleBooks.find((b) => b.abbreviation === bookAbbr);
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
          reference: `${book?.name} ${chapter}:${v}`,
          originalWords: words,
          poolWords: [],
          arrangedWords: [],
          mastery,
          prefilledCount: 0,
        };
      } catch (error) {
        console.error('processVerse error:', error);
        return null;
      }
    },
    [masteredVerses]
  );

  // Prefetch Verses
  const prefetchVerses = useCallback(
    async (count: number = 5, version: string) => {
      try {
        const fetchPromises = Array(count)
          .fill(null)
          .map(() => BibleDBService.getRandomVerse(version).then(processVerse).catch(() => null));
        const verses = await Promise.all(fetchPromises);
        verseQueueRef.current = verses.filter(Boolean) as VerseGame[];
      } catch (error) {
        console.error('Error prefetching verses:', error);
      }
    },
    [processVerse]
  );

  // Get Next Verse
  const getNextVerse = useCallback(
    async (version: string): Promise<VerseGame | null> => {
      try {
        if (verseQueueRef.current.length > 0) {
          const verse = verseQueueRef.current.shift();
          if (verseQueueRef.current.length < 3) {
            prefetchVerses(3, version).catch(console.error);
          }
          return verse || null;
        }
        const verse = await BibleDBService.getRandomVerse(version);
        return processVerse(verse);
      } catch (error) {
        console.error('getNextVerse error:', error);
        return null;
      }
    },
    [prefetchVerses, processVerse]
  );

  // Initialize Game
  useEffect(() => {
    const initialize = async () => {
      setIsLoading(true);
      try {
        const userProgressData = await AsyncStorage.getItem('userProgress');
        const userProgress = userProgressData ? JSON.parse(userProgressData) : { level: 'beginner' };
        setUserLevel(userProgress.level || 'beginner');
        await prefetchVerses(5, selectedVersion);
      } catch (error) {
        console.error('Initialization error:', error);
      } finally {
        setIsLoading(false);
      }
    };
    initialize();
  }, [prefetchVerses, selectedVersion]);

  // Update fetchRandomVerse to handle errors properly
  const fetchRandomVerse = useCallback(async (): Promise<VerseResult | null> => {
    if (!selectedVersion) return null;
    
    try {
      setIsLoading(true);
      setError(null);
      const result = await BibleDBService.getRandomVerse(selectedVersion);
      return result;
    } catch (error) {
      console.error('Error fetching random verse:', error);
      setError('Failed to fetch a verse. Please try again.');
      return null;
    } finally {
      setIsLoading(false);
    }
  }, [selectedVersion]);

  // Modify startNewRound to handle errors
  const startNewRound = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);
      
      // Get verse from queue or fetch new one
      const verseResult = verseQueueRef.current.length > 0 
        ? verseQueueRef.current.shift() 
        : processVerse(await fetchRandomVerse());
      
      if (!verseResult) {
        setError('No verse available. Please try again.');
        return;
      }

      // Process verse and update game state
      const { id: verseID, text: verseText } = verseResult;
      const { bookAbbr, chapter, verse } = parseVPLId(verseID);
      const book = bibleBooks.find(b => b.abbreviation === bookAbbr);
      
      if (!book) {
        setError(`Unknown book: ${bookAbbr}`);
        return;
      }
      
      const words = verseText.split(' ').filter((w: string) => w.length > 0);
      const mastery =
        masteredVerses.find((m) => m.verseId === verseID) || {
          verseId: verseID,
          attempts: 0,
          correct: 0,
          lastAttempt: 0,
          needsReview: true,
        };
      
      const totalWords = words.length;
      const wordsToLeaveMap: Record<UserLevel, number> = {
        novice: 3,
        beginner: 5,
        intermediate: 7,
        advanced: 10,
        expert: 10,
      };
      
      const leaveCount = Math.min(wordsToLeaveMap[userLevel], totalWords);
      const prefillCount = totalWords - leaveCount;
      const arrangedWords = words.slice(0, prefillCount);
      const poolWords = shuffleArray(words.slice(prefillCount));
      
      setGameState({
        id: verseID,
        text: verseText,
        reference: `${book?.name} ${chapter}:${verse}`,
        originalWords: words,
        poolWords: poolWords as string[],
        arrangedWords,
        mastery,
        prefilledCount: prefillCount > 0 ? prefillCount : 0,
      });
      
      setTimeLeft(INITIAL_TIME);
      progressWidth.value = 100;
      timerColorAnim.value = 0;
      setIsPlaying(true);
    } catch (error) {
      console.error('Error starting new round:', error);
      setError('Failed to start a new round. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }, [fetchRandomVerse, masteredVerses, userLevel, progressWidth, timerColorAnim, selectedVersion]);

  // Update Mastery (Non-blocking)
  const updateMastery = useCallback(async (verseId: string, correct: boolean) => {
    const updated = masteredVerses.map((m) =>
      m.verseId === verseId
        ? {
            ...m,
            attempts: m.attempts + 1,
            correct: m.correct + (correct ? 1 : 0),
            lastAttempt: Date.now(),
            needsReview: m.attempts < MAX_ATTEMPTS || Date.now() - (m.lastAttempt || 0) > REVIEW_PERIOD,
          }
        : m
    );
    if (!updated.find((m) => m.verseId === verseId)) {
      updated.push({
        verseId,
        attempts: 1,
        correct: correct ? 1 : 0,
        lastAttempt: Date.now(),
        needsReview: true,
      });
    }
    setMasteredVerses(updated);
    AsyncStorage.setItem('verseMastery', JSON.stringify(updated)).catch((error) =>
      console.error('Failed to save mastery data:', error)
    );
  }, [masteredVerses]);

  // Check Answer (Simplified)
  const checkAnswer = useCallback(async (forceCheck = false) => {
    if (!gameState || !isPlaying) return;
    if (!forceCheck && gameState.poolWords.length > 0) {
      Alert.alert('Incomplete', 'Please arrange all words before checking.');
      return;
    }

    scaleAnim.value = withSpring(1.05, { damping: 6, stiffness: 200 });
    setTimeout(() => (scaleAnim.value = withSpring(1, { damping: 8, stiffness: 180 })), 400);

    // Simplified check: Compare arrays directly for exact order
    const isCorrect = JSON.stringify(gameState.arrangedWords) === JSON.stringify(gameState.originalWords);
    updateMastery(gameState.id, isCorrect); // Non-blocking

    if (isCorrect) {
      try {
        if (correctSound.current) {
          await correctSound.current.setPositionAsync(0);
          await correctSound.current.playAsync();
        }
      } catch (error) {
        console.error('Failed to play correct sound:', error);
      }

      const newStreak = streak + 1;
      setStreak(newStreak);
      if (newStreak > 1 && streakSound.current) {
        try {
          await streakSound.current.setPositionAsync(0);
          await streakSound.current.playAsync();
        } catch (error) {
          console.error('Failed to play streak sound:', error);
        }
      }

      const timeBonus = Math.floor(timeLeft * 2);
      setScore((s) => s + 100 + timeBonus);
      setShowSuccess(true);
      setShowCorrectAnswer(false);

      setTimeout(() => {
        setShowSuccess(false);
        startNewRound();
      }, 2000);
    } else {
      setStreak(0);
      setShowCorrectAnswer(true);
    }
  }, [gameState, isPlaying, scaleAnim, streak, timeLeft, startNewRound, updateMastery]);

  // Select Word from Pool
  const selectWordFromPool = useCallback(
    (word: string) => {
      if (!gameState || !isPlaying) return;
      scaleAnim.value = withTiming(1.05, { duration: 50 });
      setTimeout(() => (scaleAnim.value = withTiming(1, { duration: 50 })), 50);

      const isLastWord = gameState.poolWords.length === 1 && gameState.poolWords[0] === word;

      setGameState((prev) => {
        if (!prev) return null;
        const newArrangedWords = [...prev.arrangedWords, word];
        const newPoolWords = prev.poolWords.filter((w) => w !== word);

        return {
          ...prev,
          poolWords: newPoolWords,
          arrangedWords: newArrangedWords,
        };
      });

      if (isLastWord) {
        setTimeout(() => checkAnswer(true), 300);
      }
    },
    [gameState, scaleAnim, isPlaying, checkAnswer]
  );

  // Return Word to Pool
  const returnWordToPool = useCallback(
    (word: string, index: number) => {
      if (!gameState || !isPlaying) return;
      scaleAnim.value = withTiming(1.05, { duration: 50 });
      setTimeout(() => (scaleAnim.value = withTiming(1, { duration: 50 })), 50);
      setGameState((prev) => {
        if (!prev) return null;
        const newArranged = [...prev.arrangedWords];
        newArranged.splice(index, 1);
        return {
          ...prev,
          arrangedWords: newArranged,
          poolWords: [...prev.poolWords, word],
        };
      });
    },
    [gameState, scaleAnim, isPlaying]
  );

  // Use Power-Up
  const usePowerUp = useCallback(
    (type: PowerUpType) => {
      if (powerUps[type] <= 0 || !gameState || !isPlaying) return;
      setPowerUps((p) => ({ ...p, [type]: p[type] - 1 }));
      switch (type) {
        case 'grace':
          setTimeLeft((t) => Math.min(t + 15, INITIAL_TIME));
          break;
        case 'discernment':
          if (gameState.poolWords.length > 0) {
            const nextCorrectWord = gameState.originalWords[gameState.arrangedWords.length];
            if (nextCorrectWord && gameState.poolWords.includes(nextCorrectWord)) {
              setGameState((prev) => ({
                ...prev!,
                poolWords: prev!.poolWords.filter((w) => w !== nextCorrectWord),
                arrangedWords: [...prev!.arrangedWords, nextCorrectWord],
              }));
            }
          }
          break;
      }
    },
    [powerUps, gameState, isPlaying]
  );

  // Timer Logic
  useEffect(() => {
    if (!isPlaying || timeLeftRef.current <= 0) return;
    const interval = setInterval(() => {
      const newTime = timeLeftRef.current - 1;
      progressWidth.value = withTiming((newTime / INITIAL_TIME) * 100, { duration: 1000 });
      timerColorAnim.value = withTiming(1 - newTime / INITIAL_TIME, { duration: 1000 });
      if (newTime <= 0) {
        clearInterval(interval);
        setIsPlaying(false);
        timeoutSound.current?.setPositionAsync(0).then(() => timeoutSound.current?.playAsync());
      }
      setTimeLeft(newTime);
    }, 1000);
    return () => clearInterval(interval);
  }, [isPlaying, progressWidth, timerColorAnim]);

  // Start First Round
  useEffect(() => {
    if (!isLoading && !gameState) startNewRound();
  }, [isLoading, gameState, startNewRound]);

  // Success Animation
  useEffect(() => {
    if (showSuccess) {
      successOpacity.value = withTiming(1, { duration: 300 });
      setTimeout(() => (successOpacity.value = withTiming(0, { duration: 300 })), 1700);
    }
  }, [showSuccess, successOpacity]);

  // Animated Styles
  const timerStyle = useAnimatedStyle(() => {
    const color = interpolate(timerColorAnim.value, [0, 0.6, 1], [0, 1, 2], Extrapolation.CLAMP);
    const [backgroundColor, borderColor] =
      color <= 0.5
        ? [`${theme.colors.success}30`, theme.colors.success]
        : color <= 1.5
          ? [`${theme.colors.warning}30`, theme.colors.warning]
          : [`${theme.colors.error}30`, theme.colors.error];
    return { backgroundColor, borderColor, borderWidth: 1, borderRadius: theme.borderRadius.md, overflow: 'hidden' };
  });

  const progressBarStyle = useAnimatedStyle(() => {
    const color = interpolate(timerColorAnim.value, [0, 0.6, 1], [0, 1, 2], Extrapolation.CLAMP);
    const backgroundColor =
      color <= 0.5 ? theme.colors.success : color <= 1.5 ? theme.colors.warning : theme.colors.error;
    return { position: 'absolute', left: 0, top: 0, bottom: 0, width: `${progressWidth.value}%`, backgroundColor };
  });

  const gameAreaStyle = useAnimatedStyle(() => ({
    flex: 1,
    marginTop: theme.spacing.lg,
    transform: [{ scale: scaleAnim.value }],
  }));

  const successOverlayStyle = useAnimatedStyle(() => ({
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(0,0,0,0.5)',
    opacity: successOpacity.value,
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

  // Render Words
  const renderPoolWord = useCallback(
    ({ item }: { item: string }) => <WordTile word={item} onPress={() => selectWordFromPool(item)} disabled={!isPlaying} />,
    [selectWordFromPool, isPlaying]
  );

  const renderArrangedWords = useCallback(() => {
    if (!gameState) return null;
    return (
      <View style={styles.arrangementContainer}>
        <Text style={styles.sectionTitle}>Arrange the Verse:</Text>
        <View style={styles.arrangementContent}>
          {gameState.arrangedWords.length === 0 ? (
            <Text style={styles.emptyText}>Start arranging words here</Text>
          ) : (
            <View style={styles.verseTextContainer}>
              {gameState.arrangedWords.map((word, index) => {
                const isPrefilled = index < gameState.prefilledCount;
                return (
                  <TouchableOpacity
                    key={`arranged-${word}-${index}`}
                    onPress={() => !isPrefilled && isPlaying && returnWordToPool(word, index)}
                    disabled={isPrefilled || !isPlaying}
                    style={styles.arrangedWordContainer}
                  >
                    <Text style={[
                      styles.arrangedWordText,
                      isPrefilled && styles.prefilledWordText
                    ]}>
                      {word}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          )}
        </View>
      </View>
    );
  }, [gameState, returnWordToPool, isPlaying]);

  // Remove Last Word function
  const removeLastWord = useCallback(() => {
    if (!gameState || !isPlaying) return;
    
    setGameState((prev) => {
      if (!prev) return null;
      const arrangedLength = prev.arrangedWords.length;
      
      if (arrangedLength <= prev.prefilledCount) return prev;
      
      const lastWord = prev.arrangedWords[arrangedLength - 1];
      const newArranged = [...prev.arrangedWords];
      newArranged.pop();
      
      return {
        ...prev,
        arrangedWords: newArranged,
        poolWords: [...prev.poolWords, lastWord],
      };
    });
  }, [gameState, isPlaying]);

  // Correct Answer Display Component
  const CorrectAnswerDisplay = useCallback(() => {
    if (!gameState || !showCorrectAnswer) return null;
    
    return (
      <View style={styles.correctAnswerContainer}>
        <Text style={styles.correctAnswerLabel}>Correct verse:</Text>
        <Text style={styles.correctAnswerText}>{gameState.originalWords.join(' ')}</Text>
        <TouchableOpacity 
          style={styles.tryAgainButton} 
          onPress={() => {
            const poolWords = shuffleArray(gameState.originalWords.slice(gameState.prefilledCount));
            setGameState(prev => ({
              ...prev!,
              arrangedWords: prev!.originalWords.slice(0, prev!.prefilledCount),
              poolWords,
            }));
            setShowCorrectAnswer(false);
          }}
        >
          <Text style={styles.tryAgainText}>Try Again</Text>
        </TouchableOpacity>
      </View>
    );
  }, [gameState, showCorrectAnswer]);

  // Add a retry button in the UI
  const renderErrorState = () => {
    if (!error) return null;
    
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity 
          style={styles.retryButton}
          onPress={() => {
            setError(null);
            startNewRound();
          }}
        >
          <Text style={styles.retryButtonText}>Try Again</Text>
        </TouchableOpacity>
      </View>
    );
  };

  // Version selector with more error handling
  const renderVersionSelector = useCallback(() => {
    if (availableVersions.length === 0) {
      return (
        <View style={styles.noVersionsContainer}>
          <Text style={styles.noVersionsText}>No Bible versions available</Text>
        </View>
      );
    }
    
    return (
      <View style={styles.versionSelector}>
        {availableVersions.map(version => {
          // Extract readable name from version ID (e.g., 'eng_kjv_vpl' -> 'KJV')
          const versionName = version.split('_')[1]?.toUpperCase() || version;
          
          return (
            <TouchableOpacity
              key={version}
              style={[
                styles.versionButton, 
                selectedVersion === version && styles.versionButtonSelected
              ]}
              onPress={() => {
                setSelectedVersion(version);
                verseQueueRef.current = [];
                startNewRound();
              }}
            >
              <Text 
                style={[
                  styles.versionText, 
                  selectedVersion === version && styles.versionTextSelected
                ]}
              >
                {versionName}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>
    );
  }, [availableVersions, selectedVersion, styles, startNewRound]);

  // Render
  return (
    <View style={styles.container}>
      {isLoading && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="large" color={theme.colors.primary} />
          <Text style={styles.loadingText}>Loading verses...</Text>
        </View>
      )}

      {/* Error State */}
      {renderErrorState()}

      {/* Version Selector */}
      {renderVersionSelector()}

      {/* Header */}
      <View style={styles.header}>
        <View style={styles.scoreContainer}>
          <Trophy color={theme.colors.primary} size={24} />
          <Text style={styles.scoreText}>{score}</Text>
        </View>
        <Animated.View style={[styles.timer, timerStyle]}>
          <Animated.View style={progressBarStyle} />
          <View style={styles.timerContent}>
            <Clock color={theme.colors.text.primary} size={20} />
            <Text style={styles.timerText}>{timeLeft}s</Text>
          </View>
        </Animated.View>
        <View style={styles.powerUps}>
          <TouchableOpacity onPress={() => usePowerUp('grace')} disabled={powerUps.grace <= 0 || !isPlaying} style={styles.powerUp}>
            <Text style={[styles.powerUpText, powerUps.grace <= 0 && styles.powerUpDisabled]}>🕊️×{powerUps.grace}</Text>
            <Text style={[styles.powerUpLabel, powerUps.grace <= 0 && styles.powerUpDisabled]}>Grace</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => usePowerUp('discernment')} disabled={powerUps.discernment <= 0 || !isPlaying} style={styles.powerUp}>
            <Text style={[styles.powerUpText, powerUps.discernment <= 0 && styles.powerUpDisabled]}>🔍×{powerUps.discernment}</Text>
            <Text style={[styles.powerUpLabel, powerUps.discernment <= 0 && styles.powerUpDisabled]}>Discernment</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Streak */}
      {streak > 1 && (
        <View style={styles.streakContainer}>
          <Sparkle color={theme.colors.secondary} size={16} />
          <Text style={styles.streakText}>Streak: {streak}x</Text>
        </View>
      )}

      {/* Game Area */}
      {gameState && (
        <Animated.View style={gameAreaStyle}>
          <Text style={styles.reference}>{gameState.reference} 📖</Text>
          {renderArrangedWords()}
          
          {/* Correct Answer Display */}
          <CorrectAnswerDisplay />
          
          {!showCorrectAnswer && gameState.poolWords.length > 0 && (
            <>
              <View style={styles.poolContainer}>
                <Text style={styles.sectionTitle}>Available Words:</Text>
                <FlatList
                  data={gameState.poolWords}
                  renderItem={renderPoolWord}
                  keyExtractor={(item, index) => `pool-${item}-${index}`}
                  numColumns={3}
                  contentContainerStyle={styles.poolContent}
                />
              </View>
              
              {gameState.arrangedWords.length > gameState.prefilledCount && (
                <TouchableOpacity style={styles.removeLastWordButton} onPress={removeLastWord}>
                  <Text style={styles.removeLastWordText}>↩️ Remove Last Word</Text>
                </TouchableOpacity>
              )}
            </>
          )}
        </Animated.View>
      )}

      {/* Success Overlay */}
      {showSuccess && (
        <Animated.View style={successOverlayStyle}>
          <Text style={styles.successText}>Correct! 🎉</Text>
        </Animated.View>
      )}

      {/* Game Over */}
      {timeLeft <= 0 && !isPlaying && (
        <BlurView intensity={20} style={styles.overlay}>
          <View style={styles.gameOverContainer}>
            <Text style={styles.gameOverText}>🎯 Game Over!</Text>
            <Text style={styles.finalScore}>Final Score: {score} ✨</Text>
            <TouchableOpacity
              style={styles.retryButton}
              onPress={() => {
                setScore(0);
                setStreak(0);
                startNewRound();
                retrySound.current?.setPositionAsync(0).then(() => retrySound.current?.playAsync());
              }}
            >
              <Text style={styles.retryText}>🔄 Try Again</Text>
            </TouchableOpacity>
          </View>
        </BlurView>
      )}
    </View>
  );
};

// Helper Functions
const getWordColor = (word: string) => {
  const colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEEAD'];
  const hash = word.split('').reduce((a, b) => a + b.charCodeAt(0), 0);
  return colors[hash % colors.length];
};

// Styles
const createStyles = (theme: Theme) =>
  StyleSheet.create({
    container: { flex: 1, padding: theme.spacing.lg, backgroundColor: theme.colors.background },
    versionSelector: { flexDirection: 'row', justifyContent: 'center', marginBottom: theme.spacing.md },
    versionButton: { padding: theme.spacing.sm, marginHorizontal: theme.spacing.sm, borderRadius: theme.borderRadius.md, backgroundColor: theme.colors.background },
    versionButtonSelected: { backgroundColor: theme.colors.primary },
    versionText: { color: theme.colors.text.primary },
    versionTextSelected: { color: '#FFF' },
    header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: theme.spacing.md },
    scoreContainer: { flexDirection: 'row', alignItems: 'center', gap: theme.spacing.xs },
    scoreText: { ...theme.typography.heading.small, color: theme.colors.primary },
    timer: { width: 100, height: 36, justifyContent: 'center', position: 'relative' },
    timerContent: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: theme.spacing.xs, zIndex: 1 },
    timerText: { ...theme.typography.caption.primary, color: theme.colors.text.primary, fontWeight: '600' },
    powerUps: { flexDirection: 'row', gap: theme.spacing.sm },
    powerUp: { alignItems: 'center', padding: theme.spacing.sm, borderRadius: theme.borderRadius.md, backgroundColor: `${theme.colors.primary}10` },
    powerUpText: { ...theme.typography.caption.primary, color: theme.colors.primary },
    powerUpLabel: { ...theme.typography.caption.secondary, fontSize: 10 },
    powerUpDisabled: { opacity: 0.5 },
    streakContainer: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: `${theme.colors.secondary}15`,
      paddingVertical: theme.spacing.xs,
      paddingHorizontal: theme.spacing.md,
      borderRadius: theme.borderRadius.full,
      alignSelf: 'center',
      marginBottom: theme.spacing.md,
    },
    streakText: { ...theme.typography.caption.primary, color: theme.colors.secondary, marginLeft: theme.spacing.xs, fontWeight: '600' },
    reference: { ...theme.typography.heading.small, textAlign: 'center', color: theme.colors.text.secondary, marginBottom: theme.spacing.xl },
    arrangementContainer: { minHeight: 120, backgroundColor: `${theme.colors.background}80`, borderRadius: theme.borderRadius.lg, padding: theme.spacing.md, marginBottom: theme.spacing.lg },
    arrangementContent: { flexDirection: 'row', flexWrap: 'wrap', gap: theme.spacing.xs },
    poolContainer: { flex: 1 },
    poolContent: { flexDirection: 'row', flexWrap: 'wrap', gap: theme.spacing.xs },
    sectionTitle: { ...theme.typography.body.sans, color: theme.colors.text.secondary, marginBottom: theme.spacing.sm },
    wordTile: {
      width: WORD_SIZE,
      height: WORD_SIZE,
      margin: theme.spacing.xs,
      justifyContent: 'center',
      alignItems: 'center',
      minWidth: WORD_SIZE,
      paddingHorizontal: theme.spacing.sm,
      borderRadius: theme.borderRadius.md,
      ...theme.shadows.md,
    },
    prefilledWord: { opacity: 0.7, borderWidth: 1, borderColor: theme.colors.primary },
    wordText: {
      ...theme.typography.body.sans,
      color: '#FFF',
      textShadowColor: 'rgba(0,0,0,0.2)',
      textShadowOffset: { width: 1, height: 1 },
      textShadowRadius: 2,
      textAlign: 'center',
    },
    emptyText: { ...theme.typography.caption.secondary, color: theme.colors.text.secondary, textAlign: 'center', flex: 1 },
    overlay: { ...StyleSheet.absoluteFillObject, justifyContent: 'center', alignItems: 'center' },
    gameOverContainer: {
      backgroundColor: theme.colors.background,
      padding: theme.spacing.xl,
      borderRadius: theme.borderRadius.lg,
      alignItems: 'center',
    },
    gameOverText: { ...theme.typography.heading.large, color: theme.colors.primary, marginBottom: theme.spacing.md },
    finalScore: { ...theme.typography.heading.medium, color: theme.colors.text.primary, marginBottom: theme.spacing.xl },
    
    retryButton: { backgroundColor: theme.colors.primary, padding: theme.spacing.lg, borderRadius: theme.borderRadius.full, ...theme.shadows.md },
    retryText: { ...theme.typography.caption.primary, color: '#FFF' },
    successText: { fontSize: 24, color: 'white', fontWeight: 'bold' },
    loadingOverlay: { ...StyleSheet.absoluteFillObject, backgroundColor: `${theme.colors.background}CC`, alignItems: 'center', justifyContent: 'center', zIndex: 10 },
    loadingText: { ...theme.typography.body.sans, color: theme.colors.primary },
    verseTextContainer: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      alignItems: 'center',
      padding: theme.spacing.sm,
      backgroundColor: `${theme.colors.background}80`,
      borderRadius: theme.borderRadius.md,
    },
    arrangedWordContainer: {
      marginHorizontal: 2,
      marginVertical: 4,
    },
    arrangedWordText: {
      ...theme.typography.body.sans,
      color: theme.colors.text.primary,
      fontWeight: '500',
    },
    prefilledWordText: {
      color: theme.colors.text.secondary,
      fontWeight: '400',
    },
    removeLastWordButton: {
      backgroundColor: `${theme.colors.secondary}20`,
      paddingVertical: theme.spacing.sm,
      paddingHorizontal: theme.spacing.lg,
      borderRadius: theme.borderRadius.full,
      alignItems: 'center',
      justifyContent: 'center',
      marginTop: theme.spacing.xl,
      alignSelf: 'center',
    },
    removeLastWordText: { 
      ...theme.typography.body.sans, 
      color: theme.colors.secondary, 
      fontWeight: '500' 
    },
    correctAnswerContainer: {
      marginTop: theme.spacing.md,
      marginBottom: theme.spacing.lg,
      padding: theme.spacing.md,
      backgroundColor: `${theme.colors.error}15`,
      borderRadius: theme.borderRadius.md,
      borderLeftWidth: 4,
      borderLeftColor: theme.colors.error,
    },
    correctAnswerLabel: {
      ...theme.typography.caption.primary,
      color: theme.colors.error,
      marginBottom: theme.spacing.xs,
    },
    correctAnswerText: {
      ...theme.typography.verse.regular,
      color: theme.colors.text.primary,
      marginBottom: theme.spacing.md,
    },
    tryAgainButton: {
      alignSelf: 'center',
      paddingVertical: theme.spacing.sm,
      paddingHorizontal: theme.spacing.lg,
      backgroundColor: theme.colors.primary,
      borderRadius: theme.borderRadius.full,
    },
    tryAgainText: {
      ...theme.typography.button.primary,
      color: '#FFFFFF',
    },
    errorContainer: {
      padding: theme.spacing.md,
      margin: theme.spacing.md,
      backgroundColor: `${theme.colors.error}20`,
      borderRadius: theme.borderRadius.md,
      alignItems: 'center',
    },
    errorText: {
      ...theme.typography.body.sans,
      color: theme.colors.error,
      marginBottom: theme.spacing.md,
      textAlign: 'center',
    },
    retryButtonText: {
      ...theme.typography.button,
      color: theme.colors.primaryLight,
    },
    noVersionsContainer: {
      padding: theme.spacing.md,
      margin: theme.spacing.md,
      backgroundColor: theme.colors.surface,
      borderRadius: theme.borderRadius.md,
      alignItems: 'center',
    },
    noVersionsText: {
      ...theme.typography.body.sans,
      color: theme.colors.text.secondary,
    }
  });

export default VerseBuilderGame;