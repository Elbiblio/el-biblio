import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Alert,
  Dimensions,
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
import { LinearGradient } from 'expo-linear-gradient';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { Heart, Clock, Sparkle, Trophy, Cross } from './../components/Icons';
import ConfettiCannon from 'react-native-confetti-cannon';
import { FlatList } from 'react-native';
import { VerseMastery } from '@/types';
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
const REVIEW_PERIOD = 6 * 30 * 24 * 60 * 60 * 1000; // 6 months in ms

type VerseGame = {
  id: string;
  text: string;
  reference: string;
  originalWords: string[];
  poolWords: string[];
  arrangedWords: string[];
  mastery: VerseMastery;
};

type PowerUpType = 'grace' | 'discernment';

const VerseBuilderGame: React.FC = () => {
  const theme = useTheme();
  const styles = createStyles(theme);
  const confettiRef = useRef<ConfettiCannon>(null);

  // Sound refs
  const tickTockSound = useRef<Audio.Sound | null>(null);
  const timeoutSound = useRef<Audio.Sound | null>(null);
  const gameOverSound = useRef<Audio.Sound | null>(null);
  const correctSound = useRef<Audio.Sound | null>(null);
  const streakSound = useRef<Audio.Sound | null>(null);
  const cheersSound = useRef<Audio.Sound | null>(null);

  const [gameState, setGameState] = useState<VerseGame | null>(null);
  const [timeLeft, setTimeLeft] = useState(INITIAL_TIME);
  const [score, setScore] = useState(0);
  const [powerUps, setPowerUps] = useState({ grace: 3, discernment: 2 });
  const [masteredVerses, setMasteredVerses] = useState<VerseMastery[]>([]);
  const [isPlaying, setIsPlaying] = useState(true);
  const [streak, setStreak] = useState(0);
  const progressWidth = useSharedValue(100);
  const timerColorAnim = useSharedValue(0);
  const scaleAnim = useSharedValue(1);

  // **Load Sounds**
  useEffect(() => {
    const loadSounds = async () => {
      try {
        const sounds = [
          { ref: tickTockSound, path: require('@/assets/sounds/tick-tock.wav') },
          { ref: cheersSound, path: require('@/assets/sounds/cheers.mp3') },
          { ref: timeoutSound, path: require('@/assets/sounds/timeout.mp3') },
          { ref: gameOverSound, path: require('@/assets/sounds/game-over.mp3') },
          { ref: correctSound, path: require('@/assets/sounds/correct.mp3') },
          { ref: streakSound, path: require('@/assets/sounds/streak.wav') },
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
      [tickTockSound, timeoutSound, gameOverSound, correctSound, streakSound, cheersSound].forEach(
        async (ref) => {
          if (ref.current) await ref.current.unloadAsync();
        }
      );
    };
  }, []);

  // **Play Tick-Tock Sound**
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

  // **Load Mastery Data**
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

  // **Get Random Verse**
  const getRandomVerse = useCallback(async () => {
    try {
      const verse = await BibleDBService.getRandomVerse();
      if (!verse) throw new Error('No verse returned');
      const { bookAbbr, chapter, verse: v } = parseVPLId(verse.verseID);
      const book = bibleBooks.find((b) => b.abbreviation === bookAbbr);
      const words = verse.verseText.split(' ').filter((w) => w.length > 0);

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
        poolWords: shuffleArray([...words]),
        arrangedWords: [],
        mastery,
      };
    } catch (error) {
      Alert.alert('Error', 'Failed to load verse');
      console.error('getRandomVerse error:', error);
      return null;
    }
  }, [masteredVerses]);

  // **Start New Round**
  const startNewRound = useCallback(async () => {
    const verse = await getRandomVerse();
    if (!verse) return;
    setGameState(verse);
    setTimeLeft(INITIAL_TIME);
    progressWidth.value = 100;
    timerColorAnim.value = 0;
    setIsPlaying(true);
  }, [getRandomVerse]);

  useEffect(() => {
    startNewRound();
  }, [startNewRound]);

  // **Update Mastery**
  const updateMastery = async (verseId: string, correct: boolean) => {
    const updated = masteredVerses.map((m) =>
      m.verseId === verseId
        ? {
          ...m,
          attempts: m.attempts + 1,
          correct: m.correct + (correct ? 1 : 0),
          lastAttempt: Date.now(),
          needsReview:
            m.attempts < MAX_ATTEMPTS ||
            Date.now() - (m.lastAttempt || 0) > REVIEW_PERIOD,
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
    try {
      await AsyncStorage.setItem('verseMastery', JSON.stringify(updated));
    } catch (error) {
      console.error('Failed to save mastery data:', error);
    }
  };

  // **Add animation functions for scale effects**
  const pulseGameArea = useCallback(() => {
    scaleAnim.value = withSpring(1.02, { damping: 8, stiffness: 200 });
    // Return to normal size after a short delay
    setTimeout(() => {
      scaleAnim.value = withSpring(1, { damping: 10, stiffness: 180 });
    }, 300);
  }, [scaleAnim]);
  
  // **Enhanced word selection with animation feedback**
  const selectWordFromPool = useCallback((word: string) => {
    if (!gameState) return;
    pulseGameArea();
    setGameState({
      ...gameState,
      poolWords: gameState.poolWords.filter(w => w !== word),
      arrangedWords: [...gameState.arrangedWords, word],
    });
  }, [gameState, pulseGameArea]);
  
  const returnWordToPool = useCallback((word: string, index: number) => {
    if (!gameState) return;
    pulseGameArea();
    const newArranged = [...gameState.arrangedWords];
    newArranged.splice(index, 1);
    setGameState({
      ...gameState,
      arrangedWords: newArranged,
      poolWords: [...gameState.poolWords, word],
    });
  }, [gameState, pulseGameArea]);
  
  // **Enhanced check answer with animation**
  const checkAnswer = async () => {
    if (!gameState) return;

    if (gameState.poolWords.length > 0) {
      Alert.alert('Incomplete', 'Please arrange all words before checking.');
      return;
    }

    // Animate when checking answer
    scaleAnim.value = withSpring(1.05, { damping: 6, stiffness: 200 });
    setTimeout(() => {
      scaleAnim.value = withSpring(1, { damping: 8, stiffness: 180 });
    }, 400);

    const isCorrect =
      gameState.arrangedWords.join(' ') === gameState.originalWords.join(' ');
    await updateMastery(gameState.id, isCorrect);

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
      confettiRef.current?.start();
      setTimeout(startNewRound, 2000);
    } else {
      setStreak(0);
      // Optionally, add feedback for incorrect answer
    }
  };

  // **Use Power-Up**
  const usePowerUp = (type: PowerUpType) => {
    if (powerUps[type] <= 0 || !gameState) return;

    setPowerUps((p) => ({ ...p, [type]: p[type] - 1 }));

    switch (type) {
      case 'grace':
        setTimeLeft((t) => Math.min(t + 15, INITIAL_TIME));
        break;
      case 'discernment':
        if (gameState.poolWords.length > 0) {
          const nextCorrectWord = gameState.originalWords[gameState.arrangedWords.length];
          if (nextCorrectWord && gameState.poolWords.includes(nextCorrectWord)) {
            setGameState({
              ...gameState,
              poolWords: gameState.poolWords.filter((w) => w !== nextCorrectWord),
              arrangedWords: [...gameState.arrangedWords, nextCorrectWord],
            });
          }
        }
        break;
    }
  };

  // **Timer Logic**
  useEffect(() => {
    if (!isPlaying || timeLeft <= 0) return;

    const interval = setInterval(() => {
      setTimeLeft((prev) => {
        const newTime = prev - 1;
        progressWidth.value = withTiming((newTime / INITIAL_TIME) * 100, { duration: 1000 });
        timerColorAnim.value = withTiming(1 - newTime / INITIAL_TIME, { duration: 1000 });

        if (newTime <= 0) {
          clearInterval(interval);
          setIsPlaying(false);
          if (timeoutSound.current) {
            timeoutSound.current.setPositionAsync(0).then(() => {
              timeoutSound.current?.playAsync().catch((e) => console.error(e));
            });
          }
          return 0;
        }
        return newTime;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [isPlaying, timeLeft]);

  // **Animated Timer Styles**
  const timerStyle = useAnimatedStyle(() => {
    const color = interpolate(timerColorAnim.value, [0, 0.6, 1], [0, 1, 2], Extrapolation.CLAMP);
    const [backgroundColor, borderColor] =
      color <= 0.5
        ? [`${theme.colors.success}30`, theme.colors.success]
        : color <= 1.5
          ? [`${theme.colors.warning}30`, theme.colors.warning]
          : [`${theme.colors.error}30`, theme.colors.error];

    return {
      backgroundColor,
      borderColor,
      borderWidth: 1,
      borderRadius: theme.borderRadius.md,
      overflow: 'hidden',
    };
  });

  const progressBarStyle = useAnimatedStyle(() => {
    const color = interpolate(timerColorAnim.value, [0, 0.6, 1], [0, 1, 2], Extrapolation.CLAMP);
    const backgroundColor =
      color <= 0.5 ? theme.colors.success : color <= 1.5 ? theme.colors.warning : theme.colors.error;

    return {
      position: 'absolute',
      left: 0,
      top: 0,
      bottom: 0,
      width: `${progressWidth.value}%`,
      backgroundColor,
    };
  });

  // **Define the animated game area style**
  const gameAreaStyle = useAnimatedStyle(() => ({
    flex: 1,
    marginTop: theme.spacing.lg,
    transform: [{ scale: scaleAnim.value }],
  }));

  // **Update renderers to use the new callbacks**
  const renderArrangedWord = ({ item, index }: { item: string; index: number }) => (
    <TouchableOpacity
      style={[
        styles.wordTile,
        { backgroundColor: getWordColor(item) },
      ]}
      onPress={() => returnWordToPool(item, index)}
    >
      <Text style={styles.wordText}>{item}</Text>
    </TouchableOpacity>
  );

  const renderPoolWord = ({ item }: { item: string }) => (
    <TouchableOpacity
      style={[styles.wordTile, { backgroundColor: getWordColor(item) }]}
      onPress={() => selectWordFromPool(item)}
    >
      <Text style={styles.wordText}>{item}</Text>
    </TouchableOpacity>
  );

  // **Render**
  return (
    <View style={styles.container}>
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
          <TouchableOpacity
            style={styles.powerUp}
            onPress={() => usePowerUp('grace')}
            disabled={powerUps.grace <= 0}
          >
            <Text style={[styles.powerUpText, powerUps.grace <= 0 && styles.powerUpDisabled]}>
              🕊️×{powerUps.grace}
            </Text>
            <Text style={[styles.powerUpLabel, powerUps.grace <= 0 && styles.powerUpDisabled]}>
              Grace
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.powerUp}
            onPress={() => usePowerUp('discernment')}
            disabled={powerUps.discernment <= 0}
          >
            <Text style={[styles.powerUpText, powerUps.discernment <= 0 && styles.powerUpDisabled]}>
              🔍×{powerUps.discernment}
            </Text>
            <Text style={[styles.powerUpLabel, powerUps.discernment <= 0 && styles.powerUpDisabled]}>
              Discernment
            </Text>
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

          {/* Updated Arrangement Area */}
          <View style={styles.arrangementContainer}>
            <Text style={styles.sectionTitle}>Arrange the Verse:</Text>
            <FlatList
              data={gameState.arrangedWords}
              keyExtractor={(item, index) => `arranged-${item}-${index}`}
              renderItem={renderArrangedWord}
              numColumns={4}
              contentContainerStyle={styles.arrangementContent}
              ListEmptyComponent={
                <Text style={styles.emptyText}>Start arranging words here</Text>
              }
            />
          </View>

          {/* Updated Pool Area */}
          <View style={styles.poolContainer}>
            <Text style={styles.sectionTitle}>Available Words:</Text>
            <FlatList
              data={gameState.poolWords}
              keyExtractor={(item, index) => `pool-${item}-${index}`}
              renderItem={renderPoolWord}
              numColumns={3}
              contentContainerStyle={styles.poolContent}
            />
          </View>
          <TouchableOpacity style={styles.checkButton} onPress={checkAnswer}>
            <Text style={styles.checkButtonText}>Check Answer</Text>
          </TouchableOpacity>
        </Animated.View>
      )}

      {/* Game Over */}
      {!isPlaying && (
        <BlurView intensity={20} style={styles.overlay}>
          <Text style={styles.gameOverText}>🎯 Game Over!</Text>
          <Text style={styles.finalScore}>Final Score: {score} ✨</Text>
          <TouchableOpacity
            style={styles.retryButton}
            onPress={() => {
              setScore(0);
              setStreak(0);
              startNewRound();
              if (gameOverSound.current) {
                gameOverSound.current.setPositionAsync(0).then(() => {
                  gameOverSound.current?.playAsync().catch((e) => console.error(e));
                });
              }
            }}
          >
            <Text style={styles.retryText}>🔄 Try Again</Text>
          </TouchableOpacity>
        </BlurView>
      )}

      <ConfettiCannon ref={confettiRef} count={200} origin={{ x: -10, y: 0 }} />
    </View>
  );
};

// **Helper Functions**
const getWordColor = (word: string) => {
  const colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEEAD'];
  const hash = word.split('').reduce((a, b) => a + b.charCodeAt(0), 0);
  return colors[hash % colors.length];
};

// **Styles**
const createStyles = (theme: Theme) =>
  StyleSheet.create({
    container: {
      flex: 1,
      padding: theme.spacing.lg,
      backgroundColor: theme.colors.background,
    },
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
    scoreText: {
      ...theme.typography.heading.small,
      color: theme.colors.primary,
    },
    timer: {
      width: 100,
      height: 36,
      justifyContent: 'center',
      position: 'relative',
    },
    timerContent: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
      gap: theme.spacing.xs,
      zIndex: 1,
    },
    timerText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.primary,
      fontWeight: '600',
    },
    powerUps: {
      flexDirection: 'row',
      gap: theme.spacing.sm,
    },
    powerUp: {
      alignItems: 'center',
      padding: theme.spacing.sm,
      borderRadius: theme.borderRadius.md,
      backgroundColor: `${theme.colors.primary}10`,
    },
    powerUpText: {
      ...theme.typography.caption.primary,
      color: theme.colors.primary,
    },
    powerUpLabel: {
      ...theme.typography.caption.secondary,
      fontSize: 10,
    },
    powerUpDisabled: {
      opacity: 0.5,
    },
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
    streakText: {
      ...theme.typography.caption.primary,
      color: theme.colors.secondary,
      marginLeft: theme.spacing.xs,
      fontWeight: '600',
    },
    gameArea: {
      flex: 1,
      marginTop: theme.spacing.lg,
    },
    reference: {
      ...theme.typography.heading.small,
      textAlign: 'center',
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.xl,
    },
    arrangementContainer: {
      minHeight: 120,
      backgroundColor: `${theme.colors.background}80`,
      borderRadius: theme.borderRadius.lg,
      padding: theme.spacing.md,
      marginBottom: theme.spacing.lg,
    },
    arrangementContent: {
      justifyContent: 'flex-start',
      gap: theme.spacing.xs,
    },
    poolContent: {
      justifyContent: 'center',
      gap: theme.spacing.xs,
    },
    poolContainer: {
      flex: 1,
    },
    sectionTitle: {
      ...theme.typography.body.sans,
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.sm,
    },
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
    wordText: {
      ...theme.typography.body.sans,
      color: '#FFF',
      textShadowColor: 'rgba(0,0,0,0.2)',
      textShadowOffset: { width: 1, height: 1 },
      textShadowRadius: 2,
      textAlign: 'center',
    },
    emptyText: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
      textAlign: 'center',
      flex: 1,
    },
    checkButton: {
      backgroundColor: theme.colors.primary,
      paddingVertical: theme.spacing.md,
      paddingHorizontal: theme.spacing.lg,
      borderRadius: theme.borderRadius.full,
      alignItems: 'center',
      justifyContent: 'center',
      marginTop: theme.spacing.xl,
      alignSelf: 'center',
      ...theme.shadows.md,
    },
    checkButtonText: {
      ...theme.typography.body.sans,
      color: '#FFF',
      fontWeight: '600',
    },
    overlay: {
      ...StyleSheet.absoluteFillObject,
      justifyContent: 'center',
      alignItems: 'center',
      padding: theme.spacing.xl,
    },
    gameOverText: {
      ...theme.typography.heading.large,
      color: theme.colors.primary,
      marginBottom: theme.spacing.md,
    },
    finalScore: {
      ...theme.typography.heading.medium,
      color: theme.colors.text.primary,
      marginBottom: theme.spacing.xl,
    },
    retryButton: {
      backgroundColor: theme.colors.primary,
      padding: theme.spacing.lg,
      borderRadius: theme.borderRadius.full,
      ...theme.shadows.md,
    },
    retryText: {
      ...theme.typography.caption.primary,
      color: '#FFF',
    },
  });

export default VerseBuilderGame;