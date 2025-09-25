import React, { useEffect, useCallback, useRef, memo, useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  ActivityIndicator,
  ImageBackground,
  Share,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  useAnimatedProps,
  useAnimatedGestureHandler,
  withTiming,
  withSpring,
  withRepeat,
  withSequence,
  interpolate,
  Extrapolation,
  runOnJS,
} from 'react-native-reanimated';
import { PanGestureHandler } from 'react-native-gesture-handler';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { observer } from 'mobx-react-lite';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { useVerseBuilderStore } from '@/stores/StoreProvider';
import { useBibleStore } from '@/stores/BibleStore';
import { Trophy, ArrowCounterClockwise } from '../components/Icons';
import AnimatedCircularProgress from '@/components/AnimatedCircularProgress';
import { PIConfetti } from 'react-native-fast-confetti';
import * as Haptics from 'expo-haptics';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';
import SimpleCradle from '@/components/SimpleCradle';
import SoundManager from '@/utils/SoundManager';
import SoundSettingsModal from '@/components/SoundSettingsModal';
import { playCue, playMusic, stopMusic } from '@/services/audio';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');
const WORD_SIZE = Math.max(56, Math.floor(SCREEN_WIDTH / 7));

const VerseBuilderScreen = observer(() => {
  const theme = useTheme();
  const styles = createStyles(theme);
  const verseBuilderStore = useVerseBuilderStore();
  const bibleStore = useBibleStore();

  // Store API
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

  // Enhanced Animation Values
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
  const flameScale = useSharedValue(1);
  const shineX = useSharedValue(-100);
  const wrongShake = useSharedValue(0);
  const calmAmp = useSharedValue(1);
  const lastTapRef = useRef<number>(0);

  // New enhanced animations
  const headerGlow = useSharedValue(0);
  const backgroundPulse = useSharedValue(1);
  const starRotation = useSharedValue(0);
  const particleFloat = useSharedValue(0);
  const timerPulse = useSharedValue(1);
  const wordHover = useSharedValue(0);
  const correctWordBounce = useSharedValue(1);
  const powerUpGlow = useSharedValue(0);
  const streakFireAnimation = useSharedValue(0);

  // Game UX state
  const [isPaused, setIsPaused] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [sessionXp, setSessionXp] = useState(0);
  const sessionGoal = 100;
  const [showSoundSettings, setShowSoundSettings] = useState(false);

  // Circular timer fill shared value for AnimatedCircularProgress (0..1)
  const circularFill = useSharedValue(1);

  // Layout capture for DnD
  const [arrangementLayout, setArrangementLayout] = useState<{ x: number; y: number; width: number; height: number } | null>(null);
  const [poolLayout, setPoolLayout] = useState<{ x: number; y: number; width: number; height: number } | null>(null);

  // Refs
  const confettiRef = useRef<any>(null);

  // Remove animated background per new design (no-op)

  // Enhanced Header Glow Animation
  useEffect(() => {
    if (isPlaying) {
      headerGlow.value = withRepeat(
        withSequence(
          withTiming(1, { duration: 2000 }),
          withTiming(0.3, { duration: 2000 })
        ),
        -1,
        true
      );
    } else {
      headerGlow.value = withTiming(0, { duration: 500 });
    }
  }, [isPlaying]);

  // Power-up glow effect
  useEffect(() => {
    if (powerUps.grace > 0 || powerUps.discernment > 0) {
      powerUpGlow.value = withRepeat(
        withSequence(
          withTiming(1, { duration: 1500 }),
          withTiming(0.4, { duration: 1500 })
        ),
        -1,
        true
      );
    }
  }, [powerUps]);

  // Enhanced streak fire animation
  useEffect(() => {
    if (streak > 1) {
      streakFireAnimation.value = withRepeat(
        withSequence(
          withTiming(1.2, { duration: 400 }),
          withTiming(0.9, { duration: 300 }),
          withTiming(1.1, { duration: 350 }),
          withTiming(1, { duration: 250 })
        ),
        -1,
        false
      );
    } else {
      streakFireAnimation.value = withTiming(1, { duration: 200 });
    }
  }, [streak]);

  // No local preloading; centralized audio service handles caching

  // Switch music based on game state via centralized audio service
  useEffect(() => {
    (async () => {
      try {
        if (!isPlaying && timeLeft <= 0) {
          await stopMusic('musicverse');
          await stopMusic('verseplay');
          return;
        }
        if (isPlaying) {
          await stopMusic('musicverse');
          await playMusic('verseplay');
          return;
        }
        // idle/menu state
        await stopMusic('verseplay');
        await playMusic('musicverse');
      } catch {}
    })();
  }, [isPlaying, timeLeft]);

  // Stop music on unmount for safety
  useEffect(() => {
    return () => {
      stopMusic('musicverse');
      stopMusic('verseplay');
    };
  }, []);

  const didInitRef = useRef(false);
  useEffect(() => {
    if (didInitRef.current) return;
    didInitRef.current = true;
    initialize();
    (async () => {
      try {
        const seen = await AsyncStorage.getItem('vb_onboarded');
        if (!seen) setShowOnboarding(true);
      } catch { }
    })();

    try {
      const currentShort = bibleStore?.currentVersion?.shortName;
      if (currentShort && currentShort !== verseBuilderStore.state.selectedVersion) {
        setVersion(currentShort);
      }
    } catch { }

    setTimeout(() => {
      try {
        console.log('[VerseBuilder] post-initialize state', {
          isLoading: verseBuilderStore.isLoading,
          error: verseBuilderStore.error,
          hasGameState: !!verseBuilderStore.state.gameState,
          poolCount: verseBuilderStore.state.gameState?.poolWords?.length,
        });
      } catch { }
    }, 500);
  }, []);

  // Timer Logic with Enhanced Animations
  useEffect(() => {
    if (!isPlaying) return;
    const interval = setInterval(() => {
      decrementTime();
    }, 1000);
    return () => clearInterval(interval);
  }, [isPlaying, decrementTime]);

  // Update circular timer fill whenever timeLeft changes
  useEffect(() => {
    const ratio = initialGameTime > 0 ? Math.max(0, timeLeft) / initialGameTime : 0;
    circularFill.value = withTiming(ratio, { duration: 250 });
  }, [timeLeft, initialGameTime]);

  useEffect(() => {
    if (initialGameTime > 0) {
      progressWidth.value = withTiming((timeLeft / initialGameTime) * 100, { duration: 1000 });
      timerColorAnim.value = withTiming(1 - timeLeft / initialGameTime, { duration: 1000 });
    }

    const warnThreshold = 10;
    if (timeLeft > 0 && timeLeft <= warnThreshold) {
      play('tickTock');

      // Enhanced warning pulse
      timerPulse.value = withSequence(
        withTiming(1.15, { duration: 100 }),
        withTiming(0.95, { duration: 100 }),
        withTiming(1.05, { duration: 100 }),
        withTiming(1, { duration: 100 })
      );

      warnScale.value = withTiming(1.08, { duration: 120 }, () => {
        warnScale.value = withTiming(1, { duration: 160 });
      });
    }
    if (timeLeft <= 0) {
      play('timeout');
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

  // Enhanced Success Animation
  useEffect(() => {
    if (showSuccess) {
      successOpacity.value = withTiming(1, { duration: 400 });

      // Enhanced confetti burst
      confettiRef.current?.restart?.();
      play('correct');

      // Bouncy correct word animation
      correctWordBounce.value = withSequence(
        withTiming(1.3, { duration: 200 }),
        withTiming(0.9, { duration: 150 }),
        withTiming(1.1, { duration: 150 }),
        withTiming(1, { duration: 100 })
      );

      // Enhanced floating points
      pointsOpacity.value = 0;
      pointsTranslateY.value = 0;
      pointsOpacity.value = withSequence(
        withTiming(1, { duration: 200 }),
        withTiming(1, { duration: 800 }),
        withTiming(0, { duration: 300 })
      );
      pointsTranslateY.value = withTiming(-40, { duration: 1300 });

      setSessionXp(prev => {
        const next = prev + 10;
        if (next >= sessionGoal) {
          levelUpSlide.value = withSequence(
            withTiming(0, { duration: 400 }),
            withTiming(0, { duration: 2000 }),
            withTiming(-60, { duration: 400 })
          );
          play('levelup');
          return next - sessionGoal;
        }
        return next;
      });

      if (score > highScore) {
        play('cheers');
        confettiRef.current?.restart?.();
      }
      if (streak > 1 && streak % 5 === 0) {
        play('streak');
        confettiRef.current?.restart?.();
      }
      setTimeout(() => (successOpacity.value = withTiming(0, { duration: 400 })), 3500);
    }
  }, [showSuccess, successOpacity, score, highScore, streak]);

  // Animate score with more flair
  useEffect(() => {
    animatedScore.value = withTiming(score, { duration: 500 });
    scoreScale.value = withSequence(
      withTiming(1.25, { duration: 150 }),
      withTiming(0.95, { duration: 100 }),
      withTiming(1.05, { duration: 100 }),
      withTiming(1, { duration: 150 })
    );
  }, [score]);

  // Enhanced flame animation
  useEffect(() => {
    if (streak > 1) {
      flameScale.value = withRepeat(
        withSequence(
          withTiming(1.15, { duration: 600 }),
          withTiming(0.95, { duration: 400 }),
          withTiming(1.08, { duration: 500 }),
          withTiming(1, { duration: 300 })
        ),
        -1,
        false
      );
    } else {
      flameScale.value = withTiming(1, { duration: 200 });
    }
  }, [streak]);

  useEffect(() => {
    if (score > highScore) {
      shineX.value = -100;
      shineX.value = withSequence(
        withTiming(SCREEN_WIDTH + 50, { duration: 1200 }),
        withTiming(-100, { duration: 0 })
      );
    }
  }, [score, highScore]);

  useEffect(() => {
    calmAmp.value = withTiming(1, { duration: 200 });
  }, []);

  // Enhanced Animated Styles
  const backgroundStyle = useAnimatedStyle(() => ({
    transform: [{ scale: backgroundPulse.value }],
  }));

  const headerGlowStyle = useAnimatedStyle(() => ({
    shadowOpacity: headerGlow.value * 0.3,
    shadowRadius: 15 + headerGlow.value * 10,
    elevation: 5 + headerGlow.value * 5,
  }));

  const scoreAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scoreScale.value }],
  }));

  const scoreAnimatedProps = useAnimatedProps(() => ({
    text: `${Math.round(animatedScore.value)}`,
  }) as any);

  const flameStyle = useAnimatedStyle(() => ({
    transform: [{ scale: flameScale.value * streakFireAnimation.value }],
  }));

  const shineStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: shineX.value }],
    opacity: 0.7,
  }));

  const wrongShakeStyle = useAnimatedStyle(() => ({
    transform: [
      {
        translateX: interpolate(wrongShake.value, [0, 1, 2, 3, 4], [0, -8, 8, -4, 0], Extrapolation.CLAMP) * calmAmp.value,
      },
    ],
  }));

  const timerPulseStyle = useAnimatedStyle(() => ({
    transform: [{ scale: timerPulse.value }],
  }));

  const powerUpGlowStyle = useAnimatedStyle(() => ({
    shadowOpacity: powerUpGlow.value * 0.4,
    shadowRadius: 8 + powerUpGlow.value * 4,
  }));

  const starRotationStyle = useAnimatedStyle(() => ({
    transform: [{ rotate: `${starRotation.value}deg` }],
  }));

  const particleFloatStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: particleFloat.value * 20 }],
    opacity: 0.6 + Math.abs(particleFloat.value) * 0.4,
  }));

  const correctBounceStyle = useAnimatedStyle(() => ({
    transform: [{ scale: correctWordBounce.value }],
  }));

  const triggerWrongFeedback = useCallback(() => {
    wrongShake.value = 0;
    wrongShake.value = withSequence(
      withTiming(1, { duration: 50 }),
      withTiming(2, { duration: 50 }),
      withTiming(3, { duration: 50 }),
      withTiming(4, { duration: 50 })
    );
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
  }, []);

  const handleSelectWord = (word: string) => {
    // Tap cooldown to avoid accidental multi-triggering (short for responsiveness)
    const now = Date.now();
    if (now - (lastTapRef.current || 0) < 60) return;
    lastTapRef.current = now;
    try {
      console.log('[VB] handleSelectWord tapped:', word, {
        hasGameState: !!gameState,
        poolLen: gameState?.poolWords?.length,
        arrangedLen: gameState?.arrangedWords?.length,
        isPlaying,
        showCorrectAnswer
      });
    } catch { }
    if (showCorrectAnswer) return;
    if (isTransitioning) return;
    // Validate next expected word to prevent wrong insertions
    if (gameState) {
      const expected = gameState.originalWords[gameState.arrangedWords.length];
      if (expected && expected !== word) {
        try { console.log('[VB] wrong slot tap', { expected, got: word }); } catch { }
        // Shake and penalize
        wrongShake.value = withSequence(
          withTiming(1, { duration: 50 }),
          withTiming(2, { duration: 50 }),
          withTiming(3, { duration: 50 }),
          withTiming(4, { duration: 50 })
        );
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
        verseBuilderStore.penalizeMistake?.(2);
        return;
      }
    }
    scaleAnim.value = withSequence(
      withTiming(1.1, { duration: 100 }),
      withTiming(0.95, { duration: 80 }),
      withTiming(1, { duration: 100 })
    );
    // Correct path: add 1s grace time to keep round flowing
    verseBuilderStore.addGraceTime?.(1);
    selectWordFromPool(word);
  };

  const handleReturnWord = (word: string, index: number) => {
    scaleAnim.value = withSequence(
      withTiming(1.1, { duration: 100 }),
      withTiming(0.95, { duration: 80 }),
      withTiming(1, { duration: 100 })
    );
    Haptics.selectionAsync();
    returnWordToPool(word, index);
  };

  const play = async (name: 'tickTock' | 'timeout' | 'correct' | 'streak' | 'retry' | 'cheers' | 'powerup' | 'levelup') => {
    await playCue(name as any);
  };

  const handleRetry = () => {
    retry();
    play('retry');
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
      backgroundColor: color <= 0.5 ? '#4CAF50' : color <= 1.5 ? '#FF9800' : '#F44336',
      shadowColor: color <= 0.5 ? '#4CAF50' : color <= 1.5 ? '#FF9800' : '#F44336',
      shadowOpacity: 0.5,
      shadowRadius: 4,
      elevation: 2,
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

  // Enhanced Word Tile Component (memoized)
  const WordTile = memo(({ word, onPress, disabled, isPrefilled, variant = 'pool' }: { word: string; onPress: () => void; disabled: boolean; isPrefilled?: boolean; variant?: 'pool' | 'arranged' }) => {
    const pressScale = useSharedValue(1);
    const glowIntensity = useSharedValue(0);

    const pressStyle = useAnimatedStyle(() => ({
      transform: [{ scale: pressScale.value }],
      shadowOpacity: glowIntensity.value * 0.35,
      shadowRadius: 4 + glowIntensity.value * 3,
      elevation: 1 + glowIntensity.value * 2,
    }));

    const handlePressIn = () => {
      pressScale.value = withTiming(0.93, { duration: 100 });
      glowIntensity.value = withTiming(1, { duration: 150 });
    };

    const handlePressOut = () => {
      pressScale.value = withSpring(1, { damping: 15, stiffness: 200 });
      glowIntensity.value = withTiming(0, { duration: 200 });
    };

    return (
      <Animated.View style={pressStyle}>
        <TouchableOpacity
          style={[
            styles.wordTile,
            variant === 'pool' ? { backgroundColor: getWordColor(word) } : styles.arrangedWordTile,
            isPrefilled && styles.prefilledWord,
            showSuccess && styles.successWordTile
          ]}
          onPress={onPress}
          disabled={disabled}
          onPressIn={handlePressIn}
          onPressOut={handlePressOut}
        >
          <Text style={[styles.wordText, variant === 'arranged' && styles.arrangedWordText]}>{word}</Text>
        </TouchableOpacity>
      </Animated.View>
    );
  }, (prev, next) => prev.word === next.word && prev.disabled === next.disabled && prev.isPrefilled === next.isPrefilled && prev.variant === next.variant && prev.onPress === next.onPress);

  const renderPoolWord = useCallback(
    ({ item }: { item: string }) => (
      <DraggableWordTile
        word={item}
        onTap={() => handleSelectWord(item)}
        disabled={isTransitioning || showCorrectAnswer}
      />
    ),
    [handleSelectWord, isTransitioning, showCorrectAnswer]
  );

  // Enhanced Draggable Word Tile (memoized): unified tap + drag in one handler
  const DraggableWordTile = memo(({ word, onTap, disabled }: { word: string; onTap: () => void; disabled: boolean }) => {
    // Re-enable performant drag with low allocation and thresholds
    const tx = useSharedValue(0);
    const ty = useSharedValue(0);
    const isDragging = useSharedValue(false);
    const hoverGlow = useSharedValue(0);
    const startTS = useSharedValue(0);

    const style = useAnimatedStyle(() => ({
      zIndex: isDragging.value ? 20 : 10,
      transform: [
        { translateX: tx.value },
        { translateY: ty.value },
      ],
      shadowOpacity: isDragging.value ? 0.25 : 0.08,
      shadowRadius: isDragging.value ? 6 : 3,
      elevation: isDragging.value ? 6 : 2,
    }));

    const pressScale = useSharedValue(1);
    const pressStyle = useAnimatedStyle(() => ({
      transform: [{ scale: pressScale.value }],
      shadowOpacity: hoverGlow.value * 0.35,
      shadowRadius: 6 + hoverGlow.value * 4,
      elevation: 2 + hoverGlow.value * 2,
    }));

    const gesture = useAnimatedGestureHandler<any, any>({
      onStart: (_, ctx: any) => {
        isDragging.value = true;
        ctx.startX = tx.value;
        ctx.startY = ty.value;
        startTS.value = Date.now();
        pressScale.value = withTiming(0.96, { duration: 90 });
        hoverGlow.value = withTiming(1, { duration: 120 });
      },
      onActive: (event, ctx: any) => {
        tx.value = ctx.startX + event.translationX;
        ty.value = ctx.startY + event.translationY;
      },
      onEnd: (event) => {
        const dx = event.translationX ?? 0;
        const dy = event.translationY ?? 0;
        const dist = Math.hypot(dx, dy);
        const dur = Math.max(1, Date.now() - startTS.value);

        // Treat as tap if tiny movement and short duration
        if (dist < 6 && dur < 250) {
          runOnJS(onTap)();
          pressScale.value = withTiming(1, { duration: 110 });
          hoverGlow.value = withTiming(0, { duration: 160 });
          isDragging.value = false;
          return;
        }

        if (arrangementLayout && typeof event.absoluteY === 'number') {
          const y = event.absoluteY;
          const withinCradle = y >= arrangementLayout.y && y <= (arrangementLayout.y + arrangementLayout.height);
          if (withinCradle) {
            runOnJS(onTap)();
            tx.value = withSpring(0, { damping: 16, stiffness: 220 });
            ty.value = withSpring(0, { damping: 16, stiffness: 220 }, () => {
              isDragging.value = false;
            });
            runOnJS(Haptics.impactAsync)(Haptics.ImpactFeedbackStyle.Medium);
            return;
          }
        }
        tx.value = withSpring(0, { damping: 14, stiffness: 180 });
        ty.value = withSpring(0, { damping: 14, stiffness: 180 }, () => {
          isDragging.value = false;
        });
        runOnJS(triggerWrongFeedback)();
        pressScale.value = withTiming(1, { duration: 110 });
        hoverGlow.value = withTiming(0, { duration: 160 });
      }
    });

    return (
      <PanGestureHandler
        enabled={!disabled}
        onGestureEvent={gesture}
        activeOffsetX={[-6, 6]}
        activeOffsetY={[-6, 6]}
        failOffsetY={[-300, 300]}
        minPointers={1}
        maxPointers={1}
        shouldCancelWhenOutside={false}
      >
        <Animated.View style={[style]}>
          <Animated.View style={pressStyle}>
            <TouchableOpacity
              style={[styles.wordTile, { backgroundColor: getWordColor(word) }]}
              disabled={disabled}
              onPress={() => {
                onTap();
                Haptics.selectionAsync();
              }}
              hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
              onPressIn={() => {
                pressScale.value = withTiming(0.96, { duration: 90 });
                hoverGlow.value = withTiming(1, { duration: 120 });
              }}
              onPressOut={() => {
                pressScale.value = withTiming(1, { duration: 110 });
                hoverGlow.value = withTiming(0, { duration: 160 });
              }}
            >
              <Text style={styles.wordText}>{word}</Text>
            </TouchableOpacity>
          </Animated.View>
        </Animated.View>
      </PanGestureHandler>
    );
  }, (prev, next) => prev.word === next.word && prev.disabled === next.disabled && prev.onTap === next.onTap);

  const renderArrangedWords = useCallback(() => {
    if (!gameState) return null;
    const canUndo = gameState.arrangedWords.length > gameState.prefilledCount && isPlaying;

    return (
      <Animated.View style={[styles.arrangementContainer, wrongShakeStyle, showSuccess && correctBounceStyle]}
        onLayout={(e) => setArrangementLayout(e.nativeEvent.layout)}
      >
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
        <View style={styles.arrangementInner}>
          <SimpleCradle
            width={SCREEN_WIDTH - theme.spacing.lg * 2}
            height={120}
            slotCount={gameState.originalWords.length}
            highlightIndex={gameState.arrangedWords.length}
            style={styles.arrangementCradle}
          />
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
                  variant="arranged"
                />
              ))
            )}
            {gameState.poolWords.map((_, idx) => (
              <View key={`ph-${idx}`} style={styles.placeholderTile} />
            ))}
          </View>
        </View>
      </Animated.View>
    );
  }, [gameState, handleReturnWord, isPlaying, undoLastWord, showSuccess]);

  // Play power-up sound when using a power-up
  useEffect(() => {
    // No direct event emitted here; the onPress handlers already call usePowerUp.
    // We can intercept by wrapping usePowerUp if needed, but for now add sound in the button handlers below.
  }, []);

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

  // Particles removed for cleaner presentation

  // Choose background asset by theme
  const isDark = (theme as any)?.isDark ?? ((theme as any)?.mode === 'dark');
  const bgSource = isDark
    ? require('../../assets/gamebg.png')
    : require('../../assets/gamelightbg.png');

  return (
    <>
      <ImageBackground source={bgSource} style={styles.bg} resizeMode="cover">
        {/* Gradient overlay for readability */}
        <LinearGradient
          colors={['rgba(0,0,0,0.1)', 'rgba(0,0,0,0.2)', 'rgba(0,0,0,0.35)']}
          locations={[0, 0.5, 1]}
          style={styles.gradientOverlay}
          pointerEvents="none"
        />
        <View style={styles.container}>
          <PIConfetti
            ref={confettiRef}
            count={150}
            fadeOutOnEnd
            colors={['#FFD700', '#FF6347', '#4169E1', '#32CD32', '#FF69B4', '#BA55D3', '#00CED1']}
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

          {/* Verse prompt card */}
          {gameState && (
            <View style={styles.promptCard}>
              <View style={styles.promptHeaderRow}>
                <Icon name="script-text-outline" size={18} color={theme.colors.text.secondary} />
                <Text style={styles.promptTitle}>Arrange the verse</Text>
              </View>
              <Text style={styles.promptReference}>{gameState.reference}</Text>
            </View>
          )}

          {renderErrorState()}
          {/* Compact top strip */}
          <View style={styles.topStrip}>
            <View style={styles.topStripLeft}>
              <View style={styles.topChipIconed}>
                <Trophy size={14} color={theme.colors.primary} />
                <Text style={styles.topChipIconedText}>{highScore}</Text>
              </View>
              <Text style={styles.topChipPrimary}>Score {score}</Text>
              <Text style={styles.topChip}>XP {sessionXp}/{sessionGoal}</Text>
            </View>
            <TouchableOpacity
              style={styles.versionButtonCompact}
              onPress={() => {
                const idx = availableVersions.indexOf(selectedVersion);
                const next = availableVersions[(idx + 1) % availableVersions.length];
                setVersion(next);
              }}
            >
              <Text style={styles.versionButtonCompactText}>{selectedVersion}</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={() => setShowSoundSettings(true)} style={{ marginLeft: 8 }}>
              <Text style={{ color: theme.colors.primary }}>Sound</Text>
            </TouchableOpacity>
          </View>

          {/* Focused verse HUD card with only session XP */}
          <Animated.View style={[styles.gameHeaderCard, headerGlowStyle]}>
            <View style={styles.sessionXpWrap}>
              <View style={styles.sessionXpTrack}>
                {[20, 40, 60, 80].map((t) => (
                  <View key={t} style={[styles.sessionXpTick, { left: `${t}%` }]} />
                ))}
                <View style={[styles.sessionXpFill, { width: `${Math.min(100, (sessionXp / sessionGoal) * 100)}%` }]} />
              </View>
              <Text style={styles.sessionXpText}>{sessionXp}/{sessionGoal}</Text>
            </View>
          </Animated.View>

          {/* Status row: show streak only when active */}
          {streak > 1 && (
            <View style={styles.statusRow}>
              <Animated.View style={[styles.streakBadge, flameStyle]}>
                <Text style={styles.streakEmoji}>🔥</Text>
                <Text style={styles.streakBadgeText}>Streak {streak}x</Text>
              </Animated.View>
            </View>
          )}

          {/* Power-ups as left/right icon buttons under top strip */}
          <View style={styles.powerUpIconBar}>
            <TouchableOpacity
              style={[styles.powerUpIconButton, powerUps.grace <= 0 && styles.powerUpDisabled]}
              onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); play('powerup'); usePowerUp('grace'); }}
              disabled={powerUps.grace <= 0 || !isPlaying}
            >
              <View style={styles.powerUpIconCirclePrimary}>
                <Icon name="hands-pray" size={18} color="#FFF" />
              </View>
              <Text style={styles.powerUpBadge}>×{powerUps.grace}</Text>
            </TouchableOpacity>
            <View style={{ flex: 1 }} />
            <TouchableOpacity
              style={[styles.powerUpIconButton, powerUps.discernment <= 0 && styles.powerUpDisabled]}
              onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); play('powerup'); usePowerUp('discernment'); }}
              disabled={powerUps.discernment <= 0 || !isPlaying}
            >
              <View style={styles.powerUpIconCircleSecondary}>
                <Icon name="magnify" size={18} color="#FFF" />
              </View>
              <Text style={styles.powerUpBadge}>×{powerUps.discernment}</Text>
            </TouchableOpacity>
          </View>

          {/* Circular countdown: show only when verse displayed */}
          {gameState && (
            <View style={styles.circularTimerWrap}>
              <AnimatedCircularProgress
                size={84}
                width={10}
                fill={circularFill}
                backgroundColor={`${theme.colors.text.secondary}25`}
                tintColor={timeLeft > 10 ? theme.colors.primary : timeLeft > 5 ? theme.colors.warning : theme.colors.error}
                lineCap="round"
                innerBackgroundColor={`${theme.colors.background}CC`}
              >
                <Text style={styles.circularTimerText}>{timeLeft}s</Text>
              </AnimatedCircularProgress>
            </View>
          )}

          {gameState && (
            <Animated.View style={[styles.gameArea, gameAreaStyle, fadeStyle]}>
              {/* Pool cloud at the top */}
              {!showCorrectAnswer && gameState.poolWords.length > 0 && (
                <View
                  style={styles.poolCloudContainer}
                  onLayout={(e) => { setPoolLayout(e.nativeEvent.layout); }}
                  pointerEvents="box-none"
                >
                  <View style={styles.poolWrap} pointerEvents="box-none">
                    {gameState.poolWords.map((w, i) => (
                      <View
                        key={`pool-${w}-${i}`}
                        style={{
                          marginHorizontal: theme.spacing.xs,
                          marginVertical: theme.spacing.xs,
                          zIndex: 1 + (i % 3),
                          transform: [{ rotate: `${(i % 5 - 2) * 1.5}deg` }],
                        }}
                        pointerEvents="box-none"
                        onStartShouldSetResponder={() => false}
                      >
                        <DraggableWordTile
                          word={w}
                          onTap={() => handleSelectWord(w)}
                          disabled={!gameState || showCorrectAnswer}
                        />
                      </View>
                    ))}
                  </View>
                </View>
              )}

              {/* Word cradle at the bottom */}
              <View style={{ flex: 1 }} />
              {renderArrangedWords()}

              {showCorrectAnswer && (
                <View style={styles.correctAnswerContainer}>
                  <Text style={styles.correctAnswerText}>{gameState.text}</Text>
                  <TouchableOpacity style={styles.retryButton} onPress={startNewRound}>
                    <Text style={styles.retryButtonText}>Try Again</Text>
                  </TouchableOpacity>
                </View>
              )}
            </Animated.View>
          )}

          {/* Enhanced Success Overlay */}
          {showSuccess && (
            <Animated.View style={[styles.successOverlay, successOverlayStyle]}>
              <View style={styles.successCard}>
                <Text style={styles.successTitle}>Great Job!</Text>
                {gameState?.text && (
                  <Text numberOfLines={2} style={styles.successVerse}>
                    {gameState.text}
                  </Text>
                )}
                <Text style={styles.referenceText}>{gameState?.reference}</Text>
                <View style={styles.successStatsRow}>
                  <View style={styles.successStatChip}>
                    <Text style={styles.successStatText}>🔥 Streak {streak}x</Text>
                  </View>
                  <View style={styles.successStatChip}>
                    <Text style={styles.successStatText}>✨ XP +10</Text>
                  </View>
                </View>
                <View style={{ flexDirection: 'row', gap: 12, marginTop: 8 }}>
                  <TouchableOpacity
                    style={[styles.retryButton, { flex: 1, backgroundColor: '#3b82f6' }]}
                    onPress={async () => {
                      try {
                        await Share.share({
                          message: `I just arranged ${gameState?.reference} in Verse Builder! Score: ${score}. Try it!`,
                        });
                      } catch { }
                    }}
                  >
                    <Text style={styles.retryButtonText}>Share</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={[styles.retryButton, { flex: 1 }]} onPress={startNewRound}>
                    <Text style={styles.retryButtonText}>Next Verse</Text>
                  </TouchableOpacity>
                </View>
              </View>
              <Animated.View style={[styles.pointsBubble, { opacity: pointsOpacity, transform: [{ translateY: pointsTranslateY }] } as any]}>
                <Text style={styles.pointsBubbleText}>+10</Text>
              </Animated.View>
            </Animated.View>
          )}

          {/* Enhanced Level-up banner */}
          <Animated.View style={[styles.levelUpBanner, { transform: [{ translateY: levelUpSlide }] }]}>
            <Text style={styles.levelUpText}>Level up! Keep it going 🚀</Text>
          </Animated.View>

          {/* Game Over Overlay */}
          {timeLeft <= 0 && !isPlaying && (
            <BlurView intensity={30} style={styles.overlay} pointerEvents="box-none">
              <View style={styles.gameOverContainer}>
                <Text style={styles.gameOverText}>Game Over!</Text>
                <Text style={styles.finalScore}>Score: {score}</Text>
                <TouchableOpacity style={styles.retryButton} onPress={handleRetry}>
                  <Text style={styles.retryButtonText}>Retry</Text>
                </TouchableOpacity>
              </View>
            </BlurView>
          )}

          {/* Pause Overlay */}
          {isPaused && (
            <BlurView intensity={25} style={styles.overlay} pointerEvents="box-none">
              <View style={styles.pauseContainer}>
                <Text style={styles.pauseTitle}>Paused</Text>
                <Text style={styles.pauseSubtitle}>Take a breath. Resume when ready.</Text>
                <TouchableOpacity style={styles.retryButton} onPress={() => setIsPaused(false)}>
                  <Text style={styles.retryButtonText}>Resume</Text>
                </TouchableOpacity>
              </View>
            </BlurView>
          )}

          {/* Onboarding Overlay */}
          {showOnboarding && (
            <BlurView intensity={25} style={styles.overlay} pointerEvents="box-none">
              <View style={styles.onboardingCard}>
                <Text style={styles.onboardingTitle}>How to play</Text>
                <Text style={styles.onboardingText}>
                  Tap or drag words to arrange the verse. Use Grace to add time and Discernment to reveal hints.
                </Text>
                <TouchableOpacity
                  style={styles.retryButton}
                  onPress={async () => {
                    setShowOnboarding(false);
                    try { await AsyncStorage.setItem('vb_onboarded', '1'); } catch { }
                  }}
                >
                  <Text style={styles.retryButtonText}>Got it</Text>
                </TouchableOpacity>
              </View>
            </BlurView>
          )}

          {/* Empty state */}
          {!isLoading && !error && !gameState && (
            <View style={styles.emptyState}>
              <Text style={styles.emptyStateTitle}>No verse loaded yet</Text>
              <Text style={styles.emptyStateSubtitle}>Tap below to fetch a verse and start playing.</Text>
              <TouchableOpacity style={styles.retryButton} onPress={startNewRound}>
                <Text style={styles.retryButtonText}>Get Verse</Text>
              </TouchableOpacity>
            </View>
          )}
        </View>
      </ImageBackground>
      <SoundSettingsModal visible={showSoundSettings} onClose={() => setShowSoundSettings(false)} />
    </>
  );
});

// Helper Functions (with caching)
const __wordColorCache: Record<string, string> = Object.create(null);
const getWordColor = (word: string) => {
  const articlePrepositions = new Set([
    'a', 'an', 'the', 'in', 'on', 'at', 'by', 'for', 'with', 'to', 'from',
    'of', 'and', 'but', 'or', 'as', 'if', 'when', 'than', 'because',
    'while', 'before', 'after', 'since', 'until', 'about', 'like', 'through'
  ]);
  const lowerWord = word.toLowerCase().replace(/[.,;:!?"']/g, '');
  if (articlePrepositions.has(lowerWord)) return '#34495E';
  if (__wordColorCache[word]) return __wordColorCache[word];

  const hash = word.split('').reduce((a, b) => a + b.charCodeAt(0), 0);
  const colors = [
    '#E74C3C', '#3498DB', '#9B59B6', '#E67E22', '#F39C12',
    '#1ABC9C', '#2ECC71', '#8E44AD', '#34495E', '#16A085',
    '#27AE60', '#2980B9', '#F1C40F', '#E74C3C', '#9B59B6'
  ];
  const c = colors[hash % colors.length];
  __wordColorCache[word] = c;
  return c;
};

// Enhanced Styles
const createStyles = (theme: Theme) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: 'transparent',
      padding: theme.spacing.md
    },
    bg: {
      flex: 1,
      width: '100%',
      height: '100%'
    },
    gradientOverlay: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
    },
    // Compact top strip
    topStrip: {
      marginTop: theme.spacing.xs,
      marginBottom: theme.spacing.xs,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      backgroundColor: `${theme.colors.surface}B3`,
      paddingHorizontal: theme.spacing.md,
      paddingVertical: 8,
      borderRadius: theme.borderRadius.full,
      borderWidth: 1,
      borderColor: `${theme.colors.text.secondary}20`,
      shadowColor: '#000',
      shadowOpacity: 0.08,
      shadowRadius: 8,
      shadowOffset: { width: 0, height: 3 },
      elevation: 2,
    },
    topStripLeft: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: theme.spacing.sm,
    },
    topChip: {
      paddingVertical: 4,
      paddingHorizontal: theme.spacing.sm,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.text.secondary}15`,
      color: theme.colors.text.primary,
      fontWeight: '700',
      fontSize: 12,
    },
    topChipPrimary: {
      paddingVertical: 4,
      paddingHorizontal: theme.spacing.sm,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.primary}25`,
      color: theme.colors.primary,
      fontWeight: '900',
      fontSize: 12,
    },
    topChipIconed: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 6,
      paddingVertical: 4,
      paddingHorizontal: theme.spacing.sm,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.text.secondary}15`,
    },
    topChipIconedText: {
      color: theme.colors.text.primary,
      fontWeight: '800',
      fontSize: 12,
    },
    versionButtonCompact: {
      paddingVertical: 6,
      paddingHorizontal: theme.spacing.md,
      borderRadius: theme.borderRadius.full,
      backgroundColor: theme.colors.primary,
      shadowColor: theme.colors.primary,
      shadowOpacity: 0.25,
      shadowRadius: 6,
      shadowOffset: { width: 0, height: 2 },
      elevation: 3,
    },
    versionButtonCompactText: {
      color: '#FFF',
      fontWeight: '800',
      fontSize: 12,
    },

    // Floating particles
    particlesContainer: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      zIndex: -1,
    },
    particle: {
      position: 'absolute',
      width: 20,
      height: 20,
      alignItems: 'center',
      justifyContent: 'center',
    },
    particleText: {
      fontSize: 12,
      opacity: 0.6,
    },

    // Version selector
    versionSelector: {
      flexDirection: 'row',
      justifyContent: 'center',
      marginBottom: theme.spacing.md
    },
    versionButton: {
      padding: theme.spacing.sm,
      margin: theme.spacing.xs,
      borderRadius: theme.borderRadius.lg,
      backgroundColor: theme.colors.surface,
      shadowColor: '#000',
      shadowOpacity: 0.1,
      shadowRadius: 4,
      shadowOffset: { width: 0, height: 2 },
      elevation: 2,
    },
    versionButtonSelected: {
      backgroundColor: theme.colors.primary,
      shadowOpacity: 0.3,
      shadowRadius: 8,
      elevation: 4,
    },
    versionText: {
      color: theme.colors.text.primary,
      fontSize: 14,
      fontWeight: '600',
    },
    versionTextSelected: {
      color: '#FFF',
      fontWeight: '700',
    },

    // Enhanced Game Header
    gameHeaderCard: {
      backgroundColor: theme.colors.surface,
      borderRadius: theme.borderRadius.xl,
      paddingVertical: theme.spacing.md,
      paddingHorizontal: theme.spacing.lg,
      marginBottom: theme.spacing.sm,
      shadowColor: theme.colors.primary,
      shadowOpacity: 0.15,
      shadowRadius: 15,
      shadowOffset: { width: 0, height: 6 },
      elevation: 8,
      borderWidth: 1,
      borderColor: `${theme.colors.primary}20`,
    },
    gameHeaderTopRow: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      marginBottom: theme.spacing.md
    },
    gameScoreWrap: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: theme.spacing.sm
    },
    gameScoreText: {
      fontSize: 28,
      color: theme.colors.primary,
      fontWeight: '900',
      textShadowColor: `${theme.colors.primary}40`,
      textShadowOffset: { width: 0, height: 2 },
      textShadowRadius: 4,
    },

    // Enhanced Power-ups
    powerUpChipsRow: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: theme.spacing.md,
      marginTop: theme.spacing.sm,
      marginBottom: theme.spacing.md
    },
    // Icon bar variant under compact header
    powerUpIconBar: {
      flexDirection: 'row',
      alignItems: 'center',
      marginBottom: theme.spacing.sm,
    },
    powerUpIconButton: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 6,
      paddingVertical: 6,
      paddingHorizontal: theme.spacing.md,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.surface}F2`,
      borderWidth: 1,
      borderColor: `${theme.colors.text.secondary}26`,
      shadowColor: '#000',
      shadowOpacity: 0.12,
      shadowRadius: 8,
      shadowOffset: { width: 0, height: 3 },
      elevation: 4,
    },
    powerUpIconCirclePrimary: {
      width: 28,
      height: 28,
      borderRadius: 14,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: theme.colors.primary,
      shadowColor: theme.colors.primary,
      shadowOpacity: 0.25,
      shadowRadius: 6,
      shadowOffset: { width: 0, height: 2 },
    },
    powerUpIconCircleSecondary: {
      width: 28,
      height: 28,
      borderRadius: 14,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: theme.colors.secondary,
      shadowColor: theme.colors.secondary,
      shadowOpacity: 0.25,
      shadowRadius: 6,
      shadowOffset: { width: 0, height: 2 },
    },
    powerUpBadge: {
      color: theme.colors.text.primary,
      fontWeight: '800',
      fontSize: 12,
    },
    powerUpChip: {
      paddingVertical: 8,
      paddingHorizontal: theme.spacing.lg,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.primary}20`,
      borderWidth: 1,
      borderColor: `${theme.colors.primary}40`,
      shadowColor: theme.colors.primary,
      shadowOpacity: 0.2,
      shadowRadius: 6,
      shadowOffset: { width: 0, height: 2 },
      elevation: 3,
    },
    powerUpChipText: {
      color: theme.colors.primary,
      fontWeight: '800',
      fontSize: 13,
    },
    powerUpDisabled: {
      opacity: 0.4,
      shadowOpacity: 0.1,
    },

    // Enhanced High Score Badge
    highScoreBadge: {
      position: 'relative',
      overflow: 'hidden',
      borderRadius: theme.borderRadius.full,
      paddingHorizontal: theme.spacing.sm,
      paddingVertical: 4,
      backgroundColor: `${theme.colors.secondary}15`,
      borderWidth: 1,
      borderColor: `${theme.colors.secondary}30`,
    },
    highScoreText: {
      fontSize: 13,
      color: theme.colors.secondary,
      fontWeight: '700',
    },
    shine: {
      position: 'absolute',
      top: 0,
      bottom: 0,
      width: 60,
      backgroundColor: 'rgba(255,255,255,0.5)',
    },

    // Enhanced Timer
    timerContainer: {
      marginBottom: theme.spacing.lg,
      padding: theme.spacing.sm,
      backgroundColor: `${theme.colors.surface}80`,
      borderRadius: theme.borderRadius.lg,
      shadowColor: '#000',
      shadowOpacity: 0.05,
      shadowRadius: 8,
      shadowOffset: { width: 0, height: 2 },
      elevation: 2,
    },
    timerLabel: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
      marginBottom: theme.spacing.sm
    },
    timerText: {
      marginLeft: theme.spacing.sm,
      color: theme.colors.text.primary,
      fontWeight: '700',
      fontSize: 16,
    },
    progressBarContainer: {
      height: 6,
      width: '100%',
      backgroundColor: `${theme.colors.text.secondary}15`,
      borderRadius: theme.borderRadius.full,
      overflow: 'hidden'
    },
    progressBar: {
      height: '100%',
      borderRadius: theme.borderRadius.full,
    },
    // Circular timer wrap
    circularTimerWrap: {
      alignSelf: 'center',
      marginBottom: theme.spacing.md,
    },
    circularTimerText: {
      color: theme.colors.text.primary,
      fontWeight: '900',
      fontSize: 16,
    },

    // Prompt card
    promptCard: {
      backgroundColor: `${theme.colors.surface}F0`,
      borderRadius: theme.borderRadius.xl,
      paddingHorizontal: theme.spacing.lg,
      paddingVertical: 10,
      marginBottom: theme.spacing.sm,
      borderWidth: 1,
      borderColor: `${theme.colors.text.secondary}20`,
      shadowColor: '#000',
      shadowOpacity: 0.12,
      shadowRadius: 10,
      shadowOffset: { width: 0, height: 4 },
      elevation: 5,
    },
    promptHeaderRow: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 8,
      marginBottom: 4,
    },
    promptTitle: {
      color: theme.colors.text.secondary,
      fontWeight: '800',
      fontSize: 12,
      letterSpacing: 0.3,
      textTransform: 'uppercase',
    },
    promptReference: {
      color: theme.colors.text.primary,
      fontWeight: '900',
      fontSize: 16,
      letterSpacing: 0.2,
      textAlign: 'center',
    },

    // Enhanced Status Row
    statusRow: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginBottom: theme.spacing.md
    },
    streakBadge: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: theme.spacing.xs,
      backgroundColor: `${theme.colors.secondary}25`,
      paddingVertical: 6,
      paddingHorizontal: theme.spacing.md,
      borderRadius: theme.borderRadius.full,
      borderWidth: 2,
      borderColor: `${theme.colors.secondary}50`,
      shadowColor: theme.colors.secondary,
      shadowOpacity: 0.3,
      shadowRadius: 8,
      shadowOffset: { width: 0, height: 2 },
      elevation: 4,
    },
    streakEmoji: {
      fontSize: 18
    },
    streakBadgeText: {
      color: theme.colors.secondary,
      fontWeight: '800',
      fontSize: 14,
    },
    streakBadgeTextMuted: {
      color: theme.colors.text.secondary,
      fontWeight: '600',
      fontSize: 13,
    },
    heartsRow: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: theme.spacing.xs
    },
    heart: {
      fontSize: 20,
      textShadowColor: 'rgba(0,0,0,0.2)',
      textShadowOffset: { width: 0, height: 1 },
      textShadowRadius: 2,
    },
    heartEmpty: {
      opacity: 0.4
    },

    // Enhanced Game Area
    gameArea: {
      flex: 1
    },
    reference: {
      textAlign: 'center',
      color: theme.colors.text.secondary,
      fontSize: 17,
      marginBottom: theme.spacing.lg,
      fontWeight: '600',
      letterSpacing: 0.5,
    },

    // Enhanced Arrangement Container
    arrangementContainer: {
      padding: theme.spacing.md,
      backgroundColor: `${theme.colors.surface}90`,
      borderRadius: theme.borderRadius.xl,
      marginBottom: theme.spacing.lg,
      borderWidth: 2,
      borderColor: `${theme.colors.primary}20`,
      shadowColor: theme.colors.primary,
      shadowOpacity: 0.1,
      shadowRadius: 12,
      shadowOffset: { width: 0, height: 4 },
      elevation: 6,
    },
    // Pool cloud at the top
    poolCloudContainer: {
      paddingVertical: theme.spacing.sm,
      paddingHorizontal: theme.spacing.sm,
      backgroundColor: `${theme.colors.surface}9A`,
      borderRadius: theme.borderRadius.xl,
      borderWidth: 1,
      borderColor: `${theme.colors.text.secondary}1F`,
      shadowColor: '#000',
      shadowOpacity: 0.08,
      shadowRadius: 6,
      shadowOffset: { width: 0, height: 2 },
      elevation: 6,
      position: 'relative',
      zIndex: 50,
      marginBottom: theme.spacing.sm,
    },
    arrangementHeader: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginBottom: theme.spacing.md
    },
    sectionTitle: {
      color: theme.colors.text.primary,
      fontWeight: '700',
      fontSize: 16,
    },
    arrangementContent: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      gap: theme.spacing.xs,
      justifyContent: 'center',
      paddingHorizontal: theme.spacing.sm,
    },
    arrangementInner: {
      position: 'relative',
      justifyContent: 'center',
      alignItems: 'center',
      paddingVertical: theme.spacing.sm,
    },
    arrangementCradle: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      zIndex: 0,
    },
    undoButton: {
      padding: theme.spacing.sm,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.surface}80`,
      shadowColor: '#000',
      shadowOpacity: 0.1,
      shadowRadius: 4,
      shadowOffset: { width: 0, height: 2 },
      elevation: 2,
    },
    undoButtonDisabled: {
      opacity: 0.3
    },

    // Enhanced Word Tiles
    wordTile: {
      paddingVertical: 10,
      paddingHorizontal: theme.spacing.md,
      borderRadius: theme.borderRadius.lg,
      justifyContent: 'center',
      alignItems: 'center',
      minWidth: WORD_SIZE,
      marginHorizontal: theme.spacing.xs,
      shadowColor: '#000',
      shadowOpacity: 0.2,
      shadowRadius: 6,
      shadowOffset: { width: 0, height: 3 },
      elevation: 4,
      borderWidth: 1,
      borderColor: 'rgba(255,255,255,0.2)',
    },
    arrangedWordTile: {
      backgroundColor: `${theme.colors.surface}E6`,
      borderColor: `${theme.colors.text.secondary}26`,
    },
    successWordTile: {
      shadowColor: theme.colors.secondary,
      shadowOpacity: 0.4,
      shadowRadius: 12,
      borderColor: theme.colors.secondary,
      borderWidth: 2,
    },
    prefilledWord: {
      opacity: 0.8,
      borderWidth: 2,
      borderColor: theme.colors.primary,
      shadowColor: theme.colors.primary,
      shadowOpacity: 0.3,
    },
    wordText: {
      color: '#FFFFFF',
      fontSize: 15,
      textAlign: 'center',
      fontWeight: '700',
      textShadowColor: 'rgba(0,0,0,0.3)',
      textShadowOffset: { width: 0, height: 1 },
      textShadowRadius: 2,
    },
    arrangedWordText: {
      color: theme.colors.text.primary,
      textShadowColor: 'transparent',
    },
    emptyText: {
      color: theme.colors.text.secondary,
      flex: 1,
      textAlign: 'center',
      fontStyle: 'italic',
    },

    // Enhanced Placeholder
    placeholderTile: {
      minWidth: WORD_SIZE,
      height: 32,
      marginHorizontal: theme.spacing.xs,
      borderRadius: theme.borderRadius.lg,
      borderWidth: 2,
      borderStyle: 'dashed',
      borderColor: `${theme.colors.primary}40`,
      backgroundColor: `${theme.colors.primary}10`,
    },

    // Pool
    poolContainer: {
      flex: 1,
      backgroundColor: `${theme.colors.surface}60`,
      borderRadius: theme.borderRadius.xl,
      padding: theme.spacing.md,
      shadowColor: '#000',
      shadowOpacity: 0.05,
      shadowRadius: 8,
      shadowOffset: { width: 0, height: 2 },
      elevation: 2,
    },
    poolContent: {
      paddingVertical: theme.spacing.sm
    },
    poolColumn: {
      justifyContent: 'center',
      marginVertical: theme.spacing.xs,
      flexWrap: 'wrap'
    },
    poolWrap: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      justifyContent: 'space-evenly',
      alignItems: 'flex-start',
      paddingHorizontal: theme.spacing.sm,
    },

    // Enhanced Success Overlay
    successOverlay: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: 'rgba(0,0,0,0.8)'
    },
    successContent: {
      padding: theme.spacing.xl,
      backgroundColor: `${theme.colors.surface}F5`,
      borderRadius: theme.borderRadius.xl,
      maxWidth: '90%',
      alignItems: 'center',
      borderWidth: 2,
      borderColor: `${theme.colors.primary}40`,
      shadowColor: theme.colors.primary,
      shadowOpacity: 0.3,
      shadowRadius: 20,
      shadowOffset: { width: 0, height: 8 },
      elevation: 10,
    },
    // Alias styles to match component usage
    successCard: {
      padding: theme.spacing.xl,
      backgroundColor: `${theme.colors.surface}F5`,
      borderRadius: theme.borderRadius.xl,
      maxWidth: '90%',
      alignItems: 'center',
      borderWidth: 2,
      borderColor: `${theme.colors.primary}40`,
      shadowColor: theme.colors.primary,
      shadowOpacity: 0.3,
      shadowRadius: 20,
      shadowOffset: { width: 0, height: 8 },
      elevation: 10,
    },
    successText: {
      fontSize: 28,
      color: theme.colors.primary,
      fontWeight: '900',
      marginBottom: theme.spacing.md,
      textShadowColor: `${theme.colors.primary}40`,
      textShadowOffset: { width: 0, height: 2 },
      textShadowRadius: 4,
    },
    successTitle: {
      fontSize: 28,
      color: theme.colors.primary,
      fontWeight: '900',
      marginBottom: theme.spacing.md,
      textShadowColor: `${theme.colors.primary}40`,
      textShadowOffset: { width: 0, height: 2 },
      textShadowRadius: 4,
    },
    fullVerseText: {
      color: theme.colors.text.primary,
      textAlign: 'center',
      fontSize: 17,
      lineHeight: 26,
      marginBottom: theme.spacing.md,
      fontWeight: '600',
    },
    successVerse: {
      color: theme.colors.text.primary,
      textAlign: 'center',
      fontSize: 17,
      lineHeight: 26,
      marginBottom: theme.spacing.md,
      fontWeight: '600',
    },
    referenceText: {
      color: theme.colors.text.secondary,
      marginTop: theme.spacing.sm,
      fontSize: 15,
      fontWeight: '600',
    },
    successStatsRow: {
      flexDirection: 'row',
      gap: theme.spacing.md,
      marginTop: theme.spacing.md,
      marginBottom: theme.spacing.md
    },
    successStatChip: {
      paddingVertical: 6,
      paddingHorizontal: theme.spacing.md,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.primary}20`,
      borderWidth: 1,
      borderColor: `${theme.colors.primary}40`,
    },
    successStatText: {
      color: theme.colors.primary,
      fontWeight: '700',
      fontSize: 13,
    },

    // Floating Points Bubble
    pointsBubble: {
      position: 'absolute',
      bottom: '35%',
      alignSelf: 'center',
      paddingVertical: 8,
      paddingHorizontal: 16,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.secondary}30`,
      borderWidth: 2,
      borderColor: theme.colors.secondary,
      shadowColor: theme.colors.secondary,
      shadowOpacity: 0.4,
      shadowRadius: 8,
      shadowOffset: { width: 0, height: 2 },
      elevation: 6,
    },
    pointsBubbleText: {
      color: theme.colors.secondary,
      fontWeight: '900',
      fontSize: 16,
    },

    // Level-up Banner
    levelUpBanner: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      height: 60,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: `${theme.colors.secondary}30`,
      borderBottomWidth: 2,
      borderBottomColor: theme.colors.secondary,
    },
    levelUpText: {
      color: theme.colors.secondary,
      fontWeight: '900',
      fontSize: 16,
    },

    // Session XP
    sessionXpWrap: {
      alignItems: 'flex-end',
      justifyContent: 'center'
    },
    sessionXpTrack: {
      position: 'relative',
      height: 8,
      width: 140,
      backgroundColor: `${theme.colors.text.secondary}20`,
      borderRadius: theme.borderRadius.full,
      overflow: 'hidden',
      borderWidth: 1,
      borderColor: `${theme.colors.text.secondary}30`,
    },
    sessionXpFill: {
      height: '100%',
      backgroundColor: theme.colors.secondary,
      borderRadius: theme.borderRadius.full,
      shadowColor: theme.colors.secondary,
      shadowOpacity: 0.4,
      shadowRadius: 4,
      shadowOffset: { width: 0, height: 1 },
    },
    sessionXpText: {
      fontSize: 12,
      color: theme.colors.text.secondary,
      marginTop: 6,
      fontWeight: '600',
    },
    sessionXpTick: {
      position: 'absolute',
      top: 0,
      bottom: 0,
      width: 1,
      backgroundColor: `${theme.colors.text.secondary}60`
    },

    // Overlays
    overlay: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      justifyContent: 'center',
      alignItems: 'center'
    },

    // Game Over
    gameOverContainer: {
      backgroundColor: theme.colors.background,
      padding: theme.spacing.xl,
      borderRadius: theme.borderRadius.xl,
      alignItems: 'center',
      borderWidth: 2,
      borderColor: `${theme.colors.error}40`,
      shadowColor: theme.colors.error,
      shadowOpacity: 0.2,
      shadowRadius: 15,
      shadowOffset: { width: 0, height: 6 },
      elevation: 8,
    },
    gameOverText: {
      fontSize: 26,
      color: theme.colors.error,
      marginBottom: theme.spacing.md,
      fontWeight: '900',
      textShadowColor: `${theme.colors.error}40`,
      textShadowOffset: { width: 0, height: 2 },
      textShadowRadius: 4,
    },
    finalScore: {
      fontSize: 20,
      color: theme.colors.text.primary,
      marginBottom: theme.spacing.lg,
      fontWeight: '700',
    },

    // Pause Container
    pauseContainer: {
      backgroundColor: theme.colors.background,
      padding: theme.spacing.xl,
      borderRadius: theme.borderRadius.xl,
      alignItems: 'center',
      borderWidth: 2,
      borderColor: `${theme.colors.primary}40`,
      shadowColor: theme.colors.primary,
      shadowOpacity: 0.2,
      shadowRadius: 15,
      shadowOffset: { width: 0, height: 6 },
      elevation: 8,
    },
    pauseTitle: {
      fontSize: 24,
      color: theme.colors.primary,
      marginBottom: theme.spacing.xs,
      fontWeight: '900'
    },
    pauseSubtitle: {
      fontSize: 15,
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.lg,
      textAlign: 'center',
      fontWeight: '500',
    },

    // Onboarding
    onboardingCard: {
      backgroundColor: theme.colors.surface,
      padding: theme.spacing.xl,
      borderRadius: theme.borderRadius.xl,
      alignItems: 'center',
      marginHorizontal: theme.spacing.lg,
      borderWidth: 2,
      borderColor: `${theme.colors.primary}30`,
      shadowColor: theme.colors.primary,
      shadowOpacity: 0.15,
      shadowRadius: 15,
      shadowOffset: { width: 0, height: 6 },
      elevation: 8,
    },
    onboardingTitle: {
      fontSize: 20,
      color: theme.colors.text.primary,
      fontWeight: '900',
      marginBottom: theme.spacing.sm
    },
    onboardingText: {
      color: theme.colors.text.secondary,
      textAlign: 'center',
      lineHeight: 22,
      marginBottom: theme.spacing.lg,
      fontSize: 15,
      fontWeight: '500',
    },

    // Retry Button
    retryButton: {
      backgroundColor: theme.colors.primary,
      paddingVertical: theme.spacing.md,
      paddingHorizontal: theme.spacing.xl,
      borderRadius: theme.borderRadius.full,
      shadowColor: theme.colors.primary,
      shadowOpacity: 0.3,
      shadowRadius: 8,
      shadowOffset: { width: 0, height: 4 },
      elevation: 6,
      borderWidth: 1,
      borderColor: `${theme.colors.primary}20`,
    },
    retryButtonText: {
      color: '#FFF',
      fontSize: 16,
      fontWeight: '800',
      textShadowColor: 'rgba(0,0,0,0.3)',
      textShadowOffset: { width: 0, height: 1 },
      textShadowRadius: 2,
    },

    // Loading States
    loadingOverlay: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: 'rgba(0,0,0,0.7)',
      justifyContent: 'center',
      alignItems: 'center',
      zIndex: 10
    },
    loadingText: {
      color: theme.colors.primary,
      marginTop: theme.spacing.md,
      fontSize: 16,
      fontWeight: '600',
    },
    skeletonContainer: {
      marginTop: theme.spacing.lg,
      width: '90%',
      maxWidth: 520
    },
    skeletonBar: {
      height: 12,
      backgroundColor: `${theme.colors.text.secondary}25`,
      borderRadius: theme.borderRadius.full,
      marginBottom: theme.spacing.lg
    },
    skeletonRow: {
      flexDirection: 'row',
      justifyContent: 'center',
      gap: theme.spacing.sm,
      marginBottom: theme.spacing.md
    },
    skeletonTile: {
      width: 80,
      height: 32,
      backgroundColor: `${theme.colors.text.secondary}20`,
      borderRadius: theme.borderRadius.lg
    },
    skeletonTileSmall: {
      width: 64,
      height: 28,
      backgroundColor: `${theme.colors.text.secondary}20`,
      borderRadius: theme.borderRadius.lg
    },

    // Error States
    errorContainer: {
      padding: theme.spacing.lg,
      backgroundColor: `${theme.colors.error}15`,
      borderRadius: theme.borderRadius.lg,
      marginBottom: theme.spacing.md,
      alignItems: 'center',
      borderWidth: 1,
      borderColor: `${theme.colors.error}30`,
    },
    errorText: {
      color: theme.colors.error,
      marginBottom: theme.spacing.md,
      textAlign: 'center',
      fontWeight: '600',
    },
    correctAnswerContainer: {
      padding: theme.spacing.lg,
      backgroundColor: `${theme.colors.error}10`,
      borderRadius: theme.borderRadius.lg,
      marginBottom: theme.spacing.xl,
      alignItems: 'center',
      borderWidth: 2,
      borderColor: `${theme.colors.error}30`,
    },
    correctAnswerText: {
      color: theme.colors.text.primary,
      marginBottom: theme.spacing.lg,
      textAlign: 'center',
      lineHeight: 24,
      fontSize: 16,
      fontWeight: '600',
    },

    // Empty State
    emptyState: {
      alignItems: 'center',
      padding: theme.spacing.xl,
      marginTop: theme.spacing.xl
    },
    emptyStateTitle: {
      fontSize: 20,
      fontWeight: '800',
      color: theme.colors.text.primary,
      marginBottom: theme.spacing.sm
    },
    emptyStateSubtitle: {
      fontSize: 15,
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.lg,
      textAlign: 'center',
      fontWeight: '500',
    },

    // Legacy styles for compatibility
    header: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginBottom: theme.spacing.md
    },
    scoreContainer: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: theme.spacing.xs
    },
    scoreText: {
      fontSize: 18,
      color: theme.colors.primary,
      fontWeight: 'bold'
    },
    calmControls: {
      flexDirection: 'row',
      justifyContent: 'center',
      alignItems: 'center',
      gap: theme.spacing.md,
      marginBottom: theme.spacing.sm
    },
    calmToggle: {
      paddingVertical: 6,
      paddingHorizontal: theme.spacing.md,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.text.secondary}10`
    },
    calmToggleActive: {
      backgroundColor: `${theme.colors.primary}20`,
      borderWidth: 1,
      borderColor: `${theme.colors.primary}40`
    },
    calmToggleText: {
      color: theme.colors.text.secondary,
      fontWeight: '600'
    },
    calmToggleTextActive: {
      color: theme.colors.primary
    },
    pauseButton: {
      paddingVertical: 6,
      paddingHorizontal: theme.spacing.md,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.text.secondary}10`
    },
    pauseButtonText: {
      color: theme.colors.text.secondary,
      fontWeight: '600'
    },
    powerUps: {
      flexDirection: 'row',
      gap: theme.spacing.sm
    },
    powerUpText: {
      fontSize: 16,
      color: theme.colors.primary
    },
    streakContainer: {
      flexDirection: 'row',
      alignItems: 'center',
      alignSelf: 'center',
      paddingVertical: theme.spacing.xs,
      paddingHorizontal: theme.spacing.sm,
      backgroundColor: `${theme.colors.secondary}20`,
      borderRadius: theme.borderRadius.full,
      marginBottom: theme.spacing.sm
    },
    streakText: {
      color: theme.colors.secondary,
      marginLeft: theme.spacing.xs,
      fontWeight: '500'
    },
  });

export default VerseBuilderScreen;