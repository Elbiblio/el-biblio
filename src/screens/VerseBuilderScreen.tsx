import React, { useEffect, useCallback, useRef, useState, useMemo } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  ActivityIndicator,
  ImageBackground,
  Share,
  FlatList,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  useAnimatedProps,
  withTiming,
  withSpring,
  withRepeat,
  withSequence,
  interpolate,
  Extrapolation,
  runOnJS,
} from 'react-native-reanimated';
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
import VerseBuilderWordTile from '@/components/VerseBuilderWordTile';
import { PIConfetti } from 'react-native-fast-confetti';
import * as Haptics from 'expo-haptics';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';
import SoundSettingsModal from '@/components/SoundSettingsModal';
import { playCue, playMusic, stopMusic } from '@/services/audio';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');
const WORD_SIZE = Math.max(56, Math.floor(SCREEN_WIDTH / 7));
// Cradle should be prominent; scale with screen height but clamp sensibly
const CRADLE_HEIGHT = Math.max(160, Math.min(220, Math.floor(SCREEN_HEIGHT * 0.22)));

const VerseBuilderScreen = observer(() => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
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
    hasPlayed,
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
  const timerPulse = useSharedValue(1);
  const correctWordBounce = useSharedValue(1);
  const powerUpGlow = useSharedValue(0);
  const streakFireAnimation = useSharedValue(0);

  // Game UX state
  const [isPaused, setIsPaused] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [showTips, setShowTips] = useState(false);
  const [sessionXp, setSessionXp] = useState(0);
  const sessionGoal = 100;
  const [showSoundSettings, setShowSoundSettings] = useState(false);
  const [showAllWords, setShowAllWords] = useState(false);

  const poolColumns = useMemo(() => {
    const spacing = theme.spacing?.md ?? 8;
    return Math.max(1, Math.floor(SCREEN_WIDTH / (WORD_SIZE + spacing * 2)));
  }, [theme]);

  const useCompactPoolTiles = useMemo(() => {
    if (!gameState) return false;
    const spacing = (theme.spacing?.md ?? 8) * 2;
    const baseTileWidth = WORD_SIZE + spacing;
    const estimatedWidth = gameState.poolWords.reduce((acc, word) => {
      const charWidth = 7.5;
      const estimatedWordWidth = Math.min(baseTileWidth, word.length * charWidth + spacing + 24);
      return acc + estimatedWordWidth;
    }, 0);
    const threshold = SCREEN_WIDTH * (showAllWords ? 1.4 : 1.05);
    return estimatedWidth > threshold || gameState.poolWords.length > poolColumns * 2;
  }, [gameState, poolColumns, showAllWords, theme]);

  // Circular timer fill shared value for AnimatedCircularProgress (0..1)
  const circularFill = useSharedValue(1);

  // Refs
  const confettiRef = useRef<any>(null);
  const levelConfettiRef = useRef<any>(null);
  const musicStateRef = useRef<'musicverse' | 'verseplay' | 'none'>('none');
  const warningTickRef = useRef<number | null>(null);
  const timeoutPlayedRef = useRef(false);
  const timerIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const play = useCallback(async (name: 'tickTock' | 'timeout' | 'correct' | 'streak' | 'retry' | 'cheers' | 'powerup' | 'levelup' | 'ding') => {
    await playCue(name as any);
  }, []);

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
    } else {
      powerUpGlow.value = withTiming(0, { duration: 400 });
    }
  }, [powerUps]);

  // Calmer streak animation to reduce continuous pulses
  useEffect(() => {
    if (streak > 1) {
      streakFireAnimation.value = withSequence(
        withTiming(1.12, { duration: 220 }),
        withTiming(0.96, { duration: 160 }),
        withTiming(1.04, { duration: 140 }),
        withTiming(1, { duration: 180 })
      );
    } else {
      streakFireAnimation.value = withTiming(1, { duration: 200 });
    }
  }, [streak]);

  // Switch music based on game state via centralized audio service
  useEffect(() => {
    const desired: 'musicverse' | 'verseplay' | 'none' = isPlaying ? 'verseplay' : timeLeft <= 0 ? 'none' : 'musicverse';
    if (musicStateRef.current === desired) {
      return;
    }

    (async () => {
      try {
        if (desired === 'none') {
          await stopMusic('musicverse');
          await stopMusic('verseplay');
        } else if (desired === 'verseplay') {
          await stopMusic('musicverse');
          await playMusic('verseplay');
        } else {
          await stopMusic('verseplay');
          await playMusic('musicverse');
        }
        musicStateRef.current = desired;
      } catch {}
    })();
  }, [isPlaying, timeLeft]);

  // Stop music on unmount for safety
  useEffect(() => {
    return () => {
      if (timerIntervalRef.current) {
        clearInterval(timerIntervalRef.current);
        timerIntervalRef.current = null;
      }
      stopMusic('musicverse');
      stopMusic('verseplay');
      musicStateRef.current = 'none';
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

  }, []);

  // Load persisted tips visibility; default to true if never set
  useEffect(() => {
    (async () => {
      try {
        const tips = await AsyncStorage.getItem('vb_showTips');
        if (tips != null) setShowTips(tips === '1');
      } catch {}
    })();
  }, []);
  // Auto-collapse the word cloud on small screens
  useEffect(() => {
    if (SCREEN_HEIGHT < 700) {
      setShowAllWords(false);
    }
  }, []);

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
    if (timeLeft > warnThreshold) {
      warningTickRef.current = null;
    }

    if (timeLeft > 0 && timeLeft <= warnThreshold) {
      if (warningTickRef.current !== timeLeft) {
        warningTickRef.current = timeLeft;
        play('tickTock');
      }

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
      if (!timeoutPlayedRef.current) {
        timeoutPlayedRef.current = true;
        play('timeout');
      }
    } else {
      timeoutPlayedRef.current = false;
    }
  }, [timeLeft, initialGameTime, progressWidth, timerColorAnim, timerPulse, warnScale, play]);

  useEffect(() => {
    if (!isPlaying || isPaused) {
      if (timerIntervalRef.current) {
        clearInterval(timerIntervalRef.current);
        timerIntervalRef.current = null;
      }
      return;
    }

    timerIntervalRef.current = setInterval(() => {
      decrementTime();
    }, 1000);

    return () => {
      if (timerIntervalRef.current) {
        clearInterval(timerIntervalRef.current);
        timerIntervalRef.current = null;
      }
    };
  }, [decrementTime, isPaused, isPlaying]);

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
          // Big celebration for level completion
          levelConfettiRef.current?.restart?.();
          return next - sessionGoal;
        }
        return next;
      });

      if (score > highScore) {
        play('cheers');
        confettiRef.current?.restart?.(); // small confetti
      }
      if (streak > 1 && streak % 5 === 0) {
        play('streak');
        confettiRef.current?.restart?.(); // small confetti
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

  // Subtler flame animation tied to streak events
  useEffect(() => {
    if (streak > 1) {
      flameScale.value = withSequence(
        withTiming(1.08, { duration: 300 }),
        withTiming(0.98, { duration: 200 }),
        withTiming(1.02, { duration: 200 }),
        withTiming(1, { duration: 240 })
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

  const headerGlowStyle = useAnimatedStyle(() => ({
    shadowOpacity: headerGlow.value * 0.3,
    shadowRadius: 15 + headerGlow.value * 10,
    elevation: 5 + headerGlow.value * 5,
  }));

  const flameStyle = useAnimatedStyle(() => ({
    transform: [{ scale: flameScale.value * streakFireAnimation.value }],
  }));

  const wrongShakeStyle = useAnimatedStyle(() => ({
    transform: [
      {
        translateX: interpolate(wrongShake.value, [0, 1, 2, 3, 4], [0, -8, 8, -4, 0], Extrapolation.CLAMP) * calmAmp.value,
      },
    ],
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
    verseBuilderStore.penalizeMistake?.(5, true);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
  }, [verseBuilderStore]);

  const handleSelectWord = (word: string) => {
    // Tap cooldown to avoid accidental multi-triggering (short for responsiveness)
    const now = Date.now();
    if (now - (lastTapRef.current || 0) < 30) return false;
    lastTapRef.current = now;
    // Auto-hide tips after the first placement to save space
    if (showTips) setShowTips(false);
    if (!isPlaying) return false;
    if (showCorrectAnswer) return false;
    if (isTransitioning) return false;
    if (gameState) {
      const expected = gameState.originalWords[gameState.arrangedWords.length];
      if (expected && expected !== word) {
        triggerWrongFeedback();
        return false;
      }
    }
    scaleAnim.value = withSequence(
      withTiming(1.1, { duration: 100 }),
      withTiming(0.95, { duration: 80 }),
      withTiming(1, { duration: 100 })
    );
    // Correct path: add 1s grace time to keep round flowing
    play('ding');
    verseBuilderStore.addGraceTime?.(1);
    selectWordFromPool(word);
    return true;
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

  const handleRetry = () => {
    retry();
    play('retry');
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
  };

  const gameAreaStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scaleAnim.value }],
  }));

  const successOverlayStyle = useAnimatedStyle(() => ({
    opacity: successOpacity.value,
  }));

  const fadeStyle = useAnimatedStyle(() => ({
    opacity: fadeAnim.value,
  }));

  // Enhanced Word Tile Component (memoized)
  const renderPoolWord = useCallback(
    ({ item, index }: { item: string; index: number }) => (
      <View style={styles.poolItem}>
        <VerseBuilderWordTile
          word={item}
          onPress={handleSelectWord}
          disabled={isTransitioning || showCorrectAnswer}
          variant="pool"
          compact={useCompactPoolTiles}
        />
      </View>
    ),
    [handleSelectWord, isTransitioning, showCorrectAnswer, styles.poolItem, useCompactPoolTiles]
  );

  const poolKeyExtractor = useCallback((item: string, index: number) => `${item}-${index}`, []);

  const renderArrangedWords = useCallback(() => {
    if (!gameState) return null;
    const canUndo = gameState.arrangedWords.length > gameState.prefilledCount && isPlaying;

    return (
      <Animated.View style={[styles.arrangementContainer, wrongShakeStyle, showSuccess && correctBounceStyle]}>
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
          {/* Wooden slot background (scrabble-like), replacing the cradle */}
          <View style={styles.woodSlotsBg} />
          {/* Subtle slot rails to suggest positions */}
          <View style={styles.slotRails} pointerEvents="none">
            {[0, 1, 2].map((i) => (
              <View key={`rail-${i}`} style={styles.slotRail} />
            ))}
          </View>
          <View style={styles.arrangementContent}>
            {gameState.arrangedWords.length === 0 ? (
              <Text style={styles.emptyText}>Start arranging words here</Text>
            ) : (
              gameState.arrangedWords.map((word: string, index: number) => (
                <View
                  key={`arranged-${word}-${index}`}
                  style={{
                    transform: [{ rotate: `${(index % 5 - 2) * 0.8}deg` }],
                  }}
                >
                  <VerseBuilderWordTile
                    word={word}
                    onPress={(selectedWord) => index >= gameState.prefilledCount && handleReturnWord(selectedWord, index)}
                    disabled={index < gameState.prefilledCount || !isPlaying}
                    isPrefilled={index < gameState.prefilledCount}
                    variant="arranged"
                    highlightSuccess={showSuccess}
                  />
                </View>
              ))
            )}
            {gameState.poolWords.map((_, idx) => (
              <View key={`ph-${idx}`} style={[styles.placeholderTile, idx === 0 && styles.nextSlotHighlight]} />
            ))}
          </View>
        </View>
      </Animated.View>
    );
  }, [gameState, handleReturnWord, isPlaying, undoLastWord, showSuccess]);


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

  const renderInstructions = useCallback(() => (
    <View style={styles.instructionCard}>
      <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
        <Text style={styles.instructionTitle}>How to play</Text>
        <TouchableOpacity onPress={async () => { setShowTips(false); try { await AsyncStorage.setItem('vb_showTips', '0'); } catch {} }}>
          <Text style={{ color: theme.colors.primary }}>Hide</Text>
        </TouchableOpacity>
      </View>
      <View style={styles.instructionList}>
        <Text style={styles.instructionStep}>1. Tap a word from the cloud to place it in the cradle.</Text>
        <Text style={styles.instructionStep}>2. Use power-ups for extra time or hints when you’re stuck.</Text>
      </View>
    </View>
  ), [theme.colors.primary]);

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
          {/* Small confetti for correct answers */}
          <PIConfetti
            ref={confettiRef}
            count={60}
            fadeOutOnEnd
            colors={['#FFD700', '#FF6347', '#4169E1', '#32CD32', '#FF69B4', '#BA55D3', '#00CED1']}
          />
          {/* Large confetti for level completion */}
          <PIConfetti
            ref={levelConfettiRef}
            count={260}
            fadeOutOnEnd
            colors={['#FFD700', '#FF8C00', '#1E90FF', '#32CD32', '#FF69B4', '#BA55D3', '#00CED1']}
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
          {/* Compact UI: hide the XP progress card to keep only two top bars */}
          {false && (
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
            <View style={styles.powerUpCenter}>
              {streak > 1 ? (
                <Animated.View style={[styles.streakBadgeCompact, flameStyle]}>
                  <Text style={styles.streakBadgeCompactText}>🔥 {streak}x</Text>
                </Animated.View>
              ) : null}
            </View>
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
              {/* Instructions (collapsible) */}
              {gameState && !showCorrectAnswer && showTips && renderInstructions()}

              {/* Word cloud */}
              {!showCorrectAnswer && gameState.poolWords.length > 0 && (
                <View
                  style={styles.poolCloudContainer}
                  pointerEvents="box-none"
                >
                  <View style={styles.poolHeaderRow}>
                    <Text style={styles.poolHeaderText}>Available Words</Text>
                    <View style={{ flexDirection: 'row', gap: 12 }}>
                      {!showTips && (
                        <TouchableOpacity onPress={async () => { setShowTips(true); try { await AsyncStorage.setItem('vb_showTips', '1'); } catch {} }}>
                          <Text style={{ color: theme.colors.primary }}>Tips</Text>
                        </TouchableOpacity>
                      )}
                      <TouchableOpacity onPress={() => setShowAllWords((s) => !s)}>
                        <Text style={{ color: theme.colors.primary }}>{showAllWords ? 'Less' : 'More'}</Text>
                      </TouchableOpacity>
                    </View>
                  </View>
                  <View style={[styles.poolWrap, !showAllWords && styles.poolCollapsed]} pointerEvents="box-none">
                    <FlatList
                      data={gameState.poolWords}
                      renderItem={renderPoolWord}
                      keyExtractor={poolKeyExtractor}
                      numColumns={poolColumns}
                      initialNumToRender={12}
                      windowSize={5}
                      removeClippedSubviews
                      scrollEnabled={showAllWords}
                      contentContainerStyle={styles.poolListContent}
                      columnWrapperStyle={poolColumns > 1 ? styles.poolColumnWrapper : undefined}
                    />
                  </View>
                </View>
              )}

              {/* Divider between sections */}
              <View style={styles.sectionDivider} />

              {/* Word cradle at the bottom */}
              {renderArrangedWords()}

              {showCorrectAnswer && hasPlayed && (
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
          {showSuccess && hasPlayed && (
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
                <View style={styles.successButtonRow}>
                  <TouchableOpacity
                    style={[styles.successButton, styles.successShareButton]}
                    onPress={async () => {
                      try {
                        await Share.share({
                          message: `I just arranged ${gameState?.reference} in Verse Builder! Score: ${score}. Try it!`,
                        });
                      } catch { }
                    }}
                  >
                    <Text style={styles.successButtonText}>Share</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={[styles.successButton, styles.successNextButton]} onPress={startNewRound}>
                    <Text style={styles.successButtonText}>Next Verse</Text>
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
          {timeLeft <= 0 && !isPlaying && hasPlayed && !showSuccess && (
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
    particle: {
      position: 'absolute',
      width: 20,
      height: 20,
      alignItems: 'center',
      justifyContent: 'center',
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
    powerUpDisabled: {
      opacity: 0.4,
      shadowOpacity: 0.1,
    },

    // Enhanced High Score Badge
    shine: {
      position: 'absolute',
      top: 0,
      bottom: 0,
      width: 60,
      backgroundColor: 'rgba(255,255,255,0.5)',
    },

    // Enhanced Timer
    timerText: {
      marginLeft: theme.spacing.sm,
      color: theme.colors.text.primary,
      fontWeight: '700',
      fontSize: 16,
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
    poolHeaderRow: {
      flexDirection: 'row',
      alignItems: 'center',
      marginTop: theme.spacing.md,
      justifyContent: 'space-between',
      paddingHorizontal: theme.spacing.sm,
      paddingBottom: theme.spacing.xs,
    },
    poolHeaderText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
      letterSpacing: 0.5,
    },
    circularTimerText: {
      color: theme.colors.text.primary,
      fontWeight: '900',
      fontSize: 16,
    },

    // Instruction card and divider
    instructionCard: {
      backgroundColor: `${theme.colors.surface}A6`,
      borderRadius: theme.borderRadius.lg,
      padding: theme.spacing.md,
      marginBottom: theme.spacing.sm,
      borderWidth: 1,
      borderColor: `${theme.colors.text.secondary}1A`,
    },
    instructionTitle: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.primary,
      marginBottom: theme.spacing.xs,
      fontWeight: '700',
    },
    instructionList: {
      gap: 4,
    },
    instructionStep: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
    },
    sectionDivider: {
      height: 1,
      backgroundColor: `${theme.colors.text.secondary}22`,
      marginVertical: theme.spacing.sm,
    },
    promptCard: {
      backgroundColor: `${theme.colors.surface}F0`,
      borderRadius: theme.borderRadius.xl,
      paddingHorizontal: theme.spacing.lg,
      paddingVertical: theme.spacing.sm,
      marginBottom: theme.spacing.sm
    },
    powerUpCenter: {
      flex: 1,
      alignItems: 'center',
      justifyContent: 'center',
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
      alignItems: 'center',
      gap: 6,
      paddingHorizontal: theme.spacing.md,
      paddingVertical: 6,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.error}26`,
      borderWidth: 1,
      borderColor: `${theme.colors.error}35`,
      shadowColor: theme.colors.error,
      shadowOpacity: 0.25,
      shadowRadius: 10,
      shadowOffset: { width: 0, height: 4 },
      elevation: 2,
    },
    streakBadgeCompact: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 4,
      paddingHorizontal: theme.spacing.sm,
      paddingVertical: 4,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.error}20`,
      borderWidth: 1,
      borderColor: `${theme.colors.error}30`,
      shadowColor: theme.colors.error,
      shadowOpacity: 0.18,
      shadowRadius: 6,
      shadowOffset: { width: 0, height: 2 },
      elevation: 2,
    },
    streakEmoji: {
      fontSize: 16,
    },
    streakBadgeText: {
      fontSize: 14,
      fontWeight: '800',
      color: theme.colors.error,
    },
    streakBadgeCompactText: {
      fontSize: 13,
      fontWeight: '800',
      color: theme.colors.error,
    },
    heart: {
      fontSize: 20,
      textShadowColor: 'rgba(0,0,0,0.2)',
      textShadowOffset: { width: 0, height: 1 },
      textShadowRadius: 2,
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
      paddingVertical: theme.spacing.md,
      paddingHorizontal: theme.spacing.md,
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
      marginBottom: theme.spacing.md,
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
      paddingTop: theme.spacing.sm,
    },
    arrangementInner: {
      position: 'relative',
      justifyContent: 'center',
      alignItems: 'center',
      paddingVertical: theme.spacing.sm,
      minHeight: CRADLE_HEIGHT,
    },
    woodSlotsBg: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      borderRadius: theme.borderRadius.xl,
      backgroundColor: '#A86E3B',
      borderWidth: 2,
      borderColor: '#7a4f29',
      shadowColor: '#000',
      shadowOpacity: 0.12,
      shadowRadius: 8,
      shadowOffset: { width: 0, height: 3 },
      elevation: 5,
    },
    // Subtle rails suggesting slots
    slotRails: {
      position: 'absolute',
      top: 10,
      left: 12,
      right: 12,
      bottom: 10,
      justifyContent: 'space-between',
    },
    slotRail: {
      height: 2,
      borderRadius: 1,
      backgroundColor: 'rgba(255,255,255,0.2)',
      marginVertical: 12,
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
    nextSlotHighlight: {
      borderStyle: 'solid',
      borderColor: theme.colors.secondary,
      backgroundColor: `${theme.colors.secondary}14`,
      shadowColor: theme.colors.secondary,
      shadowOpacity: 0.25,
      shadowRadius: 6,
      shadowOffset: { width: 0, height: 2 },
      elevation: 3,
    },

    // Pool
    poolColumn: {
      justifyContent: 'center',
      marginVertical: theme.spacing.xs,
      flexWrap: 'wrap'
    },
    poolWrap: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      justifyContent: 'space-between',
      alignItems: 'flex-start',
      paddingHorizontal: theme.spacing.md,
      rowGap: theme.spacing.xs,
    },
    poolListContent: {
      paddingBottom: theme.spacing.sm,
      alignItems: 'flex-start',
    },
    poolColumnWrapper: {
      justifyContent: 'flex-start',
      gap: theme.spacing.sm,
    },
    poolItem: {
      margin: theme.spacing.xs,
    },
    // Show only ~2 rows by default to keep cradle visible
    poolCollapsed: {
      maxHeight: 92,
      overflow: 'hidden',
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
      backgroundColor: `${theme.colors.primary}18`,
      borderWidth: 1,
      borderColor: `${theme.colors.primary}30`,
    },
    successStatText: {
      color: theme.colors.primary,
      fontWeight: '800',
      fontSize: 12,
    },
    successButtonRow: {
      flexDirection: 'row',
      gap: theme.spacing.md,
      marginTop: theme.spacing.md,
      width: '100%',
    },
    successButton: {
      flex: 1,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
      paddingVertical: 14,
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
    successShareButton: {
      backgroundColor: '#3b82f6',
      borderColor: '#1d4ed8',
    },
    successNextButton: {
      backgroundColor: theme.colors.primary,
      borderColor: `${theme.colors.primary}80`,
    },
    successButtonText: {
      color: '#FFF',
      fontWeight: '800',
      fontSize: 16,
      letterSpacing: 0.3,
    },
    pointsBubble: {
      position: 'absolute',
      bottom: -20,
      right: theme.spacing.lg,
      backgroundColor: `${theme.colors.primary}D9`,
      paddingVertical: 10,
      paddingHorizontal: theme.spacing.lg,
      borderRadius: theme.borderRadius.full,
      shadowColor: theme.colors.primary,
      shadowOpacity: 0.3,
      shadowRadius: 8,
      shadowOffset: { width: 0, height: 4 },
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
      paddingHorizontal: 64,
      paddingVertical: theme.spacing.xl,
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
  });

export default VerseBuilderScreen;