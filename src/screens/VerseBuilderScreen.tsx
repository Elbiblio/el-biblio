import React, { useEffect, useCallback, useRef, memo, useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  ActivityIndicator,
  FlatList,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  useAnimatedProps,
  withTiming,
  interpolate,
  Extrapolation,
  runOnJS,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { observer } from 'mobx-react-lite';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { useVerseBuilderStore } from '@/stores/StoreProvider';
import { Clock, Sparkle, Trophy, ArrowCounterClockwise } from '../components/Icons';
import { PowerUpType } from '@/types';
import { Audio } from 'expo-av';
import { PIConfetti } from 'react-native-fast-confetti';
import * as Haptics from 'expo-haptics';

const { width: SCREEN_WIDTH } = Dimensions.get('window');
const WORD_SIZE = SCREEN_WIDTH / 5;

const VerseBuilderScreen = observer(() => {
  const theme = useTheme();
  const styles = createStyles(theme);
  const verseBuilderStore = useVerseBuilderStore();
  // Public store API and safe state access via currentState
  const {
    isLoading,
    error,
    initialize,
    selectWordFromPool,
    returnWordToPool,
    usePowerUp,
    retry,
    startNewRound,
    decrementTime,
    completeTransition,
    undoLastWord,
    setVersion,
  } = verseBuilderStore;

  const {
    availableVersions,
    selectedVersion,
    gameState,
    score,
    highScore,
    powerUps,
    isPlaying,
    timeLeft,
    streak,
    showSuccess,
    showCorrectAnswer,
    isTransitioning,
    initialGameTime,
  } = verseBuilderStore.state;

  // Animation Values
  const progressWidth = useSharedValue(100);
  const timerColorAnim = useSharedValue(0);
  const scaleAnim = useSharedValue(1);
  const successOpacity = useSharedValue(0);
  const fadeAnim = useSharedValue(1);
  const warnScale = useSharedValue(1);
  const scoreScale = useSharedValue(1);
  const animatedScore = useSharedValue(0);
  const pointsOpacity = useSharedValue(0);
  const pointsTranslateY = useSharedValue(0);
  const levelUpSlide = useSharedValue(-60);
  // PR1 additions
  const flameScale = useSharedValue(1);
  const shineX = useSharedValue(-100);
  const wrongShake = useSharedValue(0);

  // Calming UX state
  const [isPaused, setIsPaused] = useState(false);
  const [calmMode, setCalmMode] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [sessionXp, setSessionXp] = useState(0);
  const sessionGoal = 100;

  // Refs
  const soundsRef = useRef<{
    [key: string]: Audio.Sound | null;
  }>({});
  const confettiRef = useRef<any>(null);

  useEffect(() => {
    const loadSounds = async () => {
      const soundObjects: { [key: string]: Audio.Sound } = {};
      const soundFiles = {
        tickTock: require('../../assets/sounds/tick-tock.wav'),
        timeout: require('../../assets/sounds/timeout.mp3'),
        correct: require('../../assets/sounds/correct.mp3'),
        streak: require('../../assets/sounds/streak.wav'),
        retry: require('../../assets/sounds/chime.wav'),
        cheers: require('../../assets/sounds/cheers.mp3'),
      };

      for (const key in soundFiles) {
        const { sound } = await Audio.Sound.createAsync(soundFiles[key as keyof typeof soundFiles]);
        soundObjects[key] = sound;
      }
      soundsRef.current = soundObjects;
    };

    loadSounds();

    return () => {
      if (soundsRef.current) {
        Object.values(soundsRef.current).forEach(sound => sound?.unloadAsync());
      }
    };
  }, []);

  useEffect(() => {
    initialize();
    (async () => {
      try {
        const seen = await AsyncStorage.getItem('vb_onboarded');
        if (!seen) setShowOnboarding(true);
      } catch {}
    })();
  }, [initialize]);

  // Timer Logic
  useEffect(() => {
    if (!isPlaying) return;
    const interval = setInterval(() => {
      if (!isPaused) {
        decrementTime();
      }
    }, 1000);
    return () => clearInterval(interval);
  }, [isPlaying, isPaused, decrementTime]);

  useEffect(() => {
    if (initialGameTime > 0) {
      progressWidth.value = withTiming((timeLeft / initialGameTime) * 100, { duration: 1000 });
      timerColorAnim.value = withTiming(1 - timeLeft / initialGameTime, { duration: 1000 });
    }

    const warnThreshold = calmMode ? 5 : 10;
    if (timeLeft > 0 && timeLeft <= warnThreshold) {
      // In calm mode, avoid tick-tock to reduce stress
      if (!calmMode) {
        soundsRef.current?.tickTock?.setPositionAsync(0).then(() => soundsRef.current?.tickTock?.playAsync());
      }
      // subtle pulse on low time (reduced intensity in calm mode)
      const up = calmMode ? 1.03 : 1.06;
      const d1 = calmMode ? 140 : 120;
      const d2 = calmMode ? 180 : 160;
      warnScale.value = withTiming(up, { duration: d1 }, () => {
        warnScale.value = withTiming(1, { duration: d2 });
      });
    }
    if (timeLeft <= 0) {
      soundsRef.current?.timeout?.setPositionAsync(0).then(() => soundsRef.current?.timeout?.playAsync());
    }
  }, [timeLeft, initialGameTime, progressWidth, timerColorAnim]);

  // Transition animation
  useEffect(() => {
    if (isTransitioning) {
      fadeAnim.value = withTiming(0, { duration: 300 }, () => {
        runOnJS(completeTransition)();
      });
    } else {
      fadeAnim.value = withTiming(1, { duration: 300 });
    }
  }, [isTransitioning, fadeAnim, completeTransition]);

  // Success Animation & Sounds
  useEffect(() => {
    if (showSuccess) {
      successOpacity.value = withTiming(1, { duration: 300 });
      // Confetti micro-burst on success
      confettiRef.current?.restart?.();
      soundsRef.current?.correct?.setPositionAsync(0).then(() => soundsRef.current?.correct?.playAsync());
      // Floating +points bubble
      pointsOpacity.value = 0;
      pointsTranslateY.value = 0;
      pointsOpacity.value = withTiming(1, { duration: 120 });
      pointsTranslateY.value = withTiming(-20, { duration: 450 }, () => {
        pointsOpacity.value = withTiming(0, { duration: 220 });
      });
      // Increment XP and possibly level-up
      setSessionXp(prev => {
        const next = prev + 10;
        if (next >= sessionGoal) {
          levelUpSlide.value = withTiming(0, { duration: 300 }, () => {
            setTimeout(() => {
              levelUpSlide.value = withTiming(-60, { duration: 300 });
            }, 1600);
          });
          return next - sessionGoal;
        }
        return next;
      });
      if (score > highScore) {
        soundsRef.current?.cheers?.setPositionAsync(0).then(() => soundsRef.current?.cheers?.playAsync());
        // Extra confetti on new high score
        confettiRef.current?.restart?.();
      }
      if (streak > 1 && streak % 5 === 0) {
        soundsRef.current?.streak?.setPositionAsync(0).then(() => soundsRef.current?.streak?.playAsync());
        // Celebrate streak milestones
        confettiRef.current?.restart?.();
      }
      setTimeout(() => (successOpacity.value = withTiming(0, { duration: 300 })), 3500);
    }
  }, [showSuccess, successOpacity, score, highScore, streak]);

  // Animate score number and pop
  useEffect(() => {
    // number tween
    animatedScore.value = withTiming(score, { duration: 350 });
    // pop
    scoreScale.value = withTiming(1.15, { duration: 100 }, () => {
      scoreScale.value = withTiming(1, { duration: 150 });
    });
  }, [score]);

  // PR1: Flame pulse loop when streak > 1
  useEffect(() => {
    if (streak > 1) {
      flameScale.value = withTiming(1.12, { duration: 700 }, () => {
        flameScale.value = withTiming(1, { duration: 700 }, () => {
          // repeat
        });
      });
    } else {
      flameScale.value = withTiming(1, { duration: 200 });
    }
  }, [streak]);

  // PR1: Trigger high score shine when beating high score
  useEffect(() => {
    // When current score exceeds highScore, run a shine sweep across the badge
    if (score > highScore) {
      shineX.value = -100;
      shineX.value = withTiming(120, { duration: 900 }, () => {
        shineX.value = -100;
      });
    }
  }, [score, highScore]);

  const scoreAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scoreScale.value }],
  }));

  const scoreAnimatedProps = useAnimatedProps(() => ({
    text: `${Math.round(animatedScore.value)}`,
  }) as any);

  // PR1: Animated styles
  const flameStyle = useAnimatedStyle(() => ({
    transform: [{ scale: flameScale.value }],
  }));

  const shineStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: shineX.value }],
    opacity: 0.6,
  }));

  const wrongShakeStyle = useAnimatedStyle(() => ({
    transform: [
      {
        translateX: interpolate(wrongShake.value, [0, 1, 2, 3, 4], [0, -6, 6, -3, 0], Extrapolation.CLAMP),
      },
    ],
  }));

  const handleSelectWord = (word: string) => {
    scaleAnim.value = withTiming(1.05, { duration: 100 }, () => {
      scaleAnim.value = withTiming(1, { duration: 100 });
    });
    selectWordFromPool(word);
  };

  const handleReturnWord = (word: string, index: number) => {
    scaleAnim.value = withTiming(1.05, { duration: 100 }, () => {
      scaleAnim.value = withTiming(1, { duration: 100 });
    });
    Haptics.selectionAsync();
    returnWordToPool(word, index);
  };

  const handleRetry = () => {
    retry();
    soundsRef.current?.retry?.setPositionAsync(0).then(() => soundsRef.current?.retry?.playAsync());
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
  };

  // Animated Styles
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

  const fadeStyle = useAnimatedStyle(() => ({
    opacity: fadeAnim.value,
  }));

  const timerWarnStyle = useAnimatedStyle(() => ({
    transform: [{ scale: warnScale.value }],
  }));

  const WordTile = ({ word, onPress, disabled, isPrefilled }: { word: string; onPress: () => void; disabled: boolean; isPrefilled?: boolean }) => (
    <TouchableOpacity
      style={[styles.wordTile, { backgroundColor: getWordColor(word) }, isPrefilled && styles.prefilledWord]}
      onPress={onPress}
      disabled={disabled}
    >
      <Text style={styles.wordText}>{word}</Text>
    </TouchableOpacity>
  );

  const renderPoolWord = useCallback(
    ({ item }: { item: string }) => (
      <WordTile
        word={item}
        onPress={() => handleSelectWord(item)}
        disabled={!isPlaying}
      />
    ),
    [handleSelectWord, isPlaying]
  );

  const renderArrangedWords = useCallback(() => {
    if (!gameState) return null;
    const canUndo = gameState.arrangedWords.length > gameState.prefilledCount && isPlaying;
    return (
      <View style={styles.arrangementContainer}>
        <View style={styles.arrangementHeader}>
          <Text style={styles.sectionTitle}>Arrange the Verse:</Text>
          <TouchableOpacity
            style={[styles.undoButton, !canUndo && styles.undoButtonDisabled]}
            onPress={() => { Haptics.selectionAsync(); undoLastWord(); }}
            disabled={!canUndo}
          >
            <ArrowCounterClockwise
              size={18}
              color={!canUndo ? `${theme.colors.text.secondary}50` : theme.colors.text.secondary}
            />
          </TouchableOpacity>
        </View>
        <View style={styles.arrangementContent}>
          {gameState.arrangedWords.length === 0 ? (
            <Text style={styles.emptyText}>Start arranging words here</Text>
          ) : (
            gameState.arrangedWords.map((word: string, index: number) => (
              <WordTile
                key={`arranged-${word}-${index}`}
                word={word}
                onPress={() => index >= gameState.prefilledCount && handleReturnWord(word, index)}
                disabled={index < gameState.prefilledCount || !isPlaying}
                isPrefilled={index < gameState.prefilledCount}
              />
            ))
          )}
        </View>
      </View>
    );
  }, [gameState, handleReturnWord, isPlaying, undoLastWord]);

  const renderErrorState = useCallback(
    () =>
      error ? (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={startNewRound}>
            <Text style={styles.retryButtonText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      ) : null,
    [error, startNewRound]
  );

  const renderVersionSelector = useCallback(() => (
    <View style={styles.versionSelector}>
      {availableVersions.map((version: string) => (
        <TouchableOpacity
          key={version}
          style={[styles.versionButton, selectedVersion === version && styles.versionButtonSelected]}
          onPress={() => setVersion(version)}
        >
          <Text style={[styles.versionText, selectedVersion === version && styles.versionTextSelected]}>
            {version}
          </Text>
        </TouchableOpacity>
      ))}
    </View>
  ), [availableVersions, selectedVersion, setVersion]);

  const renderCalmControls = () => (
    <View style={styles.calmControls}>
      <TouchableOpacity
        style={[styles.calmToggle, calmMode && styles.calmToggleActive]}
        onPress={() => setCalmMode(v => !v)}
      >
        <Text style={[styles.calmToggleText, calmMode && styles.calmToggleTextActive]}>
          {calmMode ? 'Calm Mode: On' : 'Calm Mode'}
        </Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={styles.pauseButton}
        onPress={() => setIsPaused(true)}
        disabled={!isPlaying}
      >
        <Text style={styles.pauseButtonText}>Pause</Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <View style={styles.container}>
      <PIConfetti
        ref={confettiRef}
        count={120}
        fadeOutOnEnd
        colors={[ '#FFD700', '#FF6347', '#4169E1', '#32CD32', '#FF69B4', '#BA55D3' ]}
      />
      {isLoading && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="large" color={theme.colors.primary} />
          <Text style={styles.loadingText}>Setting up a verse for you...</Text>
          <View style={styles.skeletonContainer}>
            <View style={styles.skeletonBar} />
            <View style={styles.skeletonRow}>
              {[...Array(4)].map((_, i) => (
                <View key={`sk-${i}`} style={styles.skeletonTile} />
              ))}
            </View>
            <View style={styles.skeletonRow}>
              {[...Array(4)].map((_, i) => (
                <View key={`sk2-${i}`} style={styles.skeletonTileSmall} />
              ))}
            </View>
          </View>
        </View>
      )}
      {renderErrorState()}
      {renderVersionSelector()}
      {renderCalmControls()}
      <View style={styles.header}>
        <View style={styles.scoreContainer}>
          <Trophy color={theme.colors.primary} size={24} />
          <Animated.Text
            style={[styles.scoreText, scoreAnimatedStyle]}
            // @ts-ignore reanimated animated text
            animatedProps={scoreAnimatedProps}
          >
            {score}
          </Animated.Text>
          <View style={styles.highScoreBadge}>
            <Text style={styles.highScoreText}>High: {highScore}</Text>
            <Animated.View pointerEvents="none" style={[styles.shine, shineStyle]} />
          </View>
        </View>
        <View style={styles.sessionXpWrap}>
          <View style={styles.sessionXpTrack}>
            {/* Tick marks */}
            {[20,40,60,80].map((t)=> (
              <View key={t} style={[styles.sessionXpTick, { left: `${t}%` }]} />
            ))}
            <View style={[styles.sessionXpFill, { width: `${Math.min(100, (sessionXp / sessionGoal) * 100)}%` }]} />
          </View>
          <Text style={styles.sessionXpText}>{sessionXp}/{sessionGoal}</Text>
        </View>
        <View style={styles.powerUps}>
          <TouchableOpacity onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); usePowerUp('grace'); }} disabled={powerUps.grace <= 0 || !isPlaying}>
            <Text style={[styles.powerUpText, powerUps.grace <= 0 && styles.powerUpDisabled]}>🕊️×{powerUps.grace}</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); usePowerUp('discernment'); }} disabled={powerUps.discernment <= 0 || !isPlaying}>
            <Text style={[styles.powerUpText, powerUps.discernment <= 0 && styles.powerUpDisabled]}>🔍×{powerUps.discernment}</Text>
          </TouchableOpacity>
        </View>
      </View>
      {/* PR1: Streak flame and Hearts row */}
      <View style={styles.statusRow}>
        {streak > 1 ? (
          <Animated.View style={[styles.streakBadge, flameStyle]}>
            <Text style={styles.streakEmoji}>🔥</Text>
            <Text style={styles.streakBadgeText}>Streak {streak}x</Text>
          </Animated.View>
        ) : (
          <View style={styles.streakBadgeMuted}>
            <Text style={styles.streakBadgeTextMuted}>Build your streak</Text>
          </View>
        )}
        <View style={styles.heartsRow}>
          {(() => {
            const maxLives = (verseBuilderStore.state as any).maxLives ?? 3;
            const lives = typeof (verseBuilderStore.state as any).lives === 'number' ? (verseBuilderStore.state as any).lives : maxLives;
            return Array.from({ length: maxLives }).map((_, i) => {
              const filled = i < lives;
              return (
                <Text key={`heart-${i}`} style={[styles.heart, !filled && styles.heartEmpty]}>{filled ? '❤️' : '🤍'}</Text>
              );
            });
          })()}
        </View>
      </View>
      <View style={styles.timerContainer}>
        <Animated.View style={[styles.timerLabel, timerWarnStyle]}>
          <Clock color={theme.colors.text.primary} size={20} />
          <Text style={styles.timerText}>{timeLeft}s</Text>
        </Animated.View>
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
          <Animated.View style={[styles.pointsBubble, { opacity: pointsOpacity, transform: [{ translateY: pointsTranslateY }] } as any]}>
            <Text style={styles.pointsBubbleText}>+10</Text>
          </Animated.View>
        </Animated.View>
      )}
      <Animated.View style={[styles.levelUpBanner, { transform: [{ translateY: levelUpSlide }] }] }>
        <Text style={styles.levelUpText}>Level up! Keep it going 🚀</Text>
      </Animated.View>
      {timeLeft <= 0 && !isPlaying && (
        <BlurView intensity={20} style={styles.overlay}>
          <View style={styles.gameOverContainer}>
            <Text style={styles.gameOverText}>Game Over!</Text>
            <Text style={styles.finalScore}>Score: {score}</Text>
            <TouchableOpacity style={styles.retryButton} onPress={handleRetry}>
              <Text style={styles.retryButtonText}>Retry</Text>
            </TouchableOpacity>
          </View>
        </BlurView>
      )}

      {isPaused && (
        <BlurView intensity={20} style={styles.overlay}>
          <View style={styles.pauseContainer}>
            <Text style={styles.pauseTitle}>Paused</Text>
            <Text style={styles.pauseSubtitle}>Take a breath. Resume when ready.</Text>
            <TouchableOpacity style={styles.retryButton} onPress={() => setIsPaused(false)}>
              <Text style={styles.retryButtonText}>Resume</Text>
            </TouchableOpacity>
          </View>
        </BlurView>
      )}

      {showOnboarding && (
        <BlurView intensity={20} style={styles.overlay}>
          <View style={styles.onboardingCard}>
            <Text style={styles.onboardingTitle}>How to play</Text>
            <Text style={styles.onboardingText}>
              Tap words to arrange the verse. Use Grace to add time and Discernment to reveal hints. You can enable Calm Mode to reduce time pressure.
            </Text>
            <TouchableOpacity
              style={styles.retryButton}
              onPress={async () => {
                setShowOnboarding(false);
                try { await AsyncStorage.setItem('vb_onboarded', '1'); } catch {}
              }}
            >
              <Text style={styles.retryButtonText}>Got it</Text>
            </TouchableOpacity>
          </View>
        </BlurView>
      )}
    </View>
  );
});

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
    // PR1: High score badge with shine
    highScoreBadge: { position: 'relative', overflow: 'hidden', borderRadius: theme.borderRadius.full, paddingHorizontal: theme.spacing.xs, paddingVertical: 2 },
    shine: { position: 'absolute', top: 0, bottom: 0, width: 36, backgroundColor: '#FFFFFF33', transform: [{ translateX: -100 }] },
    timerContainer: { marginBottom: theme.spacing.md },
    timerLabel: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', marginBottom: theme.spacing.xs },
    progressBarContainer: { height: 4, width: '100%', backgroundColor: `${theme.colors.text.secondary}20`, borderRadius: theme.borderRadius.full, overflow: 'hidden' },
    progressBar: { height: '100%', borderRadius: theme.borderRadius.full },
    timerText: { marginLeft: theme.spacing.xs, color: theme.colors.text.primary, fontWeight: '600' },
    calmControls: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', gap: theme.spacing.md, marginBottom: theme.spacing.sm },
    calmToggle: { paddingVertical: 6, paddingHorizontal: theme.spacing.md, borderRadius: theme.borderRadius.full, backgroundColor: `${theme.colors.text.secondary}10` },
    calmToggleActive: { backgroundColor: `${theme.colors.primary}20`, borderWidth: 1, borderColor: `${theme.colors.primary}40` },
    calmToggleText: { color: theme.colors.text.secondary, fontWeight: '600' },
    calmToggleTextActive: { color: theme.colors.primary },
    pauseButton: { paddingVertical: 6, paddingHorizontal: theme.spacing.md, borderRadius: theme.borderRadius.full, backgroundColor: `${theme.colors.text.secondary}10` },
    pauseButtonText: { color: theme.colors.text.secondary, fontWeight: '600' },
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
    pauseContainer: { backgroundColor: theme.colors.background, padding: theme.spacing.xl, borderRadius: theme.borderRadius.lg, alignItems: 'center' },
    pauseTitle: { fontSize: 22, color: theme.colors.primary, marginBottom: theme.spacing.xs, fontWeight: '700' },
    pauseSubtitle: { fontSize: 14, color: theme.colors.text.secondary, marginBottom: theme.spacing.lg, textAlign: 'center' },
    onboardingCard: { backgroundColor: theme.colors.surface, padding: theme.spacing.lg, borderRadius: theme.borderRadius.lg, alignItems: 'center', marginHorizontal: theme.spacing.lg },
    onboardingTitle: { fontSize: 18, color: theme.colors.text.primary, fontWeight: '700', marginBottom: theme.spacing.sm },
    onboardingText: { color: theme.colors.text.secondary, textAlign: 'center', lineHeight: 20, marginBottom: theme.spacing.md },
    loadingOverlay: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', alignItems: 'center', zIndex: 10 },
    loadingText: { color: theme.colors.primary, marginTop: theme.spacing.sm },
    skeletonContainer: { marginTop: theme.spacing.md, width: '90%', maxWidth: 520 },
    skeletonBar: { height: 10, backgroundColor: `${theme.colors.text.secondary}20`, borderRadius: theme.borderRadius.full, marginBottom: theme.spacing.md },
    skeletonRow: { flexDirection: 'row', justifyContent: 'center', gap: theme.spacing.sm, marginBottom: theme.spacing.sm },
    skeletonTile: { width: 72, height: 28, backgroundColor: `${theme.colors.text.secondary}15`, borderRadius: theme.borderRadius.md },
    skeletonTileSmall: { width: 56, height: 24, backgroundColor: `${theme.colors.text.secondary}15`, borderRadius: theme.borderRadius.md },
    errorContainer: { padding: theme.spacing.md, backgroundColor: `${theme.colors.error}20`, borderRadius: theme.borderRadius.md, marginBottom: theme.spacing.md, alignItems: 'center' },
    errorText: { color: theme.colors.error, marginBottom: theme.spacing.sm },
    correctAnswerContainer: { padding: theme.spacing.md, backgroundColor: `${theme.colors.error}10`, borderRadius: theme.borderRadius.md, marginBottom: theme.spacing.lg, alignItems: 'center' },
    correctAnswerText: { color: theme.colors.text.primary, marginBottom: theme.spacing.md, textAlign: 'center', lineHeight: 22 },
    // Session XP progress
    sessionXpWrap: { alignItems: 'flex-end', justifyContent: 'center' },
    sessionXpTrack: { position: 'relative', height: 6, width: 120, backgroundColor: `${theme.colors.text.secondary}20`, borderRadius: theme.borderRadius.full, overflow: 'hidden' },
    sessionXpFill: { height: '100%', backgroundColor: theme.colors.secondary, borderRadius: theme.borderRadius.full },
    sessionXpText: { fontSize: 12, color: theme.colors.text.secondary, marginTop: 4 },
    sessionXpTick: { position: 'absolute', top: 0, bottom: 0, width: 1, backgroundColor: `${theme.colors.text.secondary}50` },
    // PR1: Status row (streak + hearts)
    statusRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: theme.spacing.sm },
    streakBadge: { flexDirection: 'row', alignItems: 'center', gap: theme.spacing.xs, backgroundColor: `${theme.colors.secondary}20`, paddingVertical: 4, paddingHorizontal: theme.spacing.sm, borderRadius: theme.borderRadius.full },
    streakEmoji: { fontSize: 16 },
    streakBadgeText: { color: theme.colors.secondary, fontWeight: '600' },
    streakBadgeMuted: { paddingVertical: 4, paddingHorizontal: theme.spacing.sm, borderRadius: theme.borderRadius.full, backgroundColor: `${theme.colors.text.secondary}10` },
    streakBadgeTextMuted: { color: theme.colors.text.secondary },
    heartsRow: { flexDirection: 'row', alignItems: 'center', gap: theme.spacing.xs },
    heart: { fontSize: 18 },
    heartEmpty: { opacity: 0.5 },
    // Floating +points bubble
    pointsBubble: { position: 'absolute', bottom: '35%', alignSelf: 'center', paddingVertical: 4, paddingHorizontal: 10, borderRadius: theme.borderRadius.full, backgroundColor: `${theme.colors.primary}20` },
    pointsBubbleText: { color: theme.colors.primary, fontWeight: '700' },
    // Level-up banner
    levelUpBanner: { position: 'absolute', top: 0, left: 0, right: 0, height: 48, alignItems: 'center', justifyContent: 'center', backgroundColor: `${theme.colors.secondary}20` },
    levelUpText: { color: theme.colors.secondary, fontWeight: '700' },
  });

export default VerseBuilderScreen;