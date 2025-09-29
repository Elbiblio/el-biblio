import React, { memo, useCallback, useMemo, useRef } from 'react';
import { Dimensions, GestureResponderEvent, Pressable, StyleSheet, Text, ViewStyle } from 'react-native';
import Animated, {
  runOnJS,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
} from 'react-native-reanimated';
import { useTheme } from '@/contexts/ThemeContext';
import type { Theme } from '@/theme';

const { width: SCREEN_WIDTH } = Dimensions.get('window');
export const WORD_TILE_SIZE = Math.max(56, Math.floor(SCREEN_WIDTH / 7));

export type WordTileVariant = 'pool' | 'arranged';

export interface WordTileProps {
  word: string;
  onPress: (word: string) => boolean | Promise<boolean | void> | void;
  disabled?: boolean;
  isPrefilled?: boolean;
  variant?: WordTileVariant;
  highlightSuccess?: boolean;
  compact?: boolean;
}

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

const __wordColorCache: Record<string, string> = Object.create(null);
const articlePrepositions = new Set([
  'a', 'an', 'the', 'in', 'on', 'at', 'by', 'for', 'with', 'to', 'from',
  'of', 'and', 'but', 'or', 'as', 'if', 'when', 'than', 'because',
  'while', 'before', 'after', 'since', 'until', 'about', 'like', 'through',
]);

export const getWordColor = (word: string) => {
  const lowerWord = word.toLowerCase().replace(/[.,;:!?"']+/g, '');
  if (articlePrepositions.has(lowerWord)) return '#34495E';
  const cached = __wordColorCache[word];
  if (cached) return cached;
  const hash = word.split('').reduce((a, b) => a + b.charCodeAt(0), 0);
  const colors = [
    '#E74C3C', '#3498DB', '#9B59B6', '#E67E22', '#F39C12',
    '#1ABC9C', '#2ECC71', '#8E44AD', '#34495E', '#16A085',
    '#27AE60', '#2980B9', '#F1C40F', '#FF6F61', '#9C27B0',
  ];
  const color = colors[hash % colors.length];
  __wordColorCache[word] = color;
  return color;
};

const VerseBuilderWordTile: React.FC<WordTileProps> = memo(({ word, onPress, disabled, isPrefilled, variant = 'pool', highlightSuccess, compact = false }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const pressScale = useSharedValue(1);
  const glow = useSharedValue(0);
  const exitProgress = useSharedValue(0);
  const isAnimatingOut = useRef(false);
  const localDisabled = useRef(false);

  const animatedContainerStyle = useAnimatedStyle(() => ({
    transform: [
      { scale: pressScale.value * (1 - exitProgress.value * 0.18) },
    ],
    opacity: 1 - exitProgress.value,
    shadowOpacity: glow.value * 0.35,
    shadowRadius: 4 + glow.value * 3,
    elevation: 1 + glow.value * 2,
  }));

  const animatedPressableStyle = useAnimatedStyle(() => ({
    transform: [{ scale: pressScale.value }],
  }));

  const resetPressFeedback = useCallback(() => {
    pressScale.value = withSpring(1, { damping: 18, stiffness: 240 });
    glow.value = withTiming(0, { duration: 160 });
  }, [glow, pressScale]);

  const handlePressIn = useCallback(() => {
    if (disabled || localDisabled.current) return;
    pressScale.value = withSpring(0.94, { damping: 22, stiffness: 420 });
    glow.value = withTiming(1, { duration: 90 });
  }, [disabled, glow, pressScale]);

  const handlePressOut = useCallback(() => {
    if (isAnimatingOut.current) return;
    resetPressFeedback();
  }, [resetPressFeedback]);

  const finishInteraction = useCallback(() => {
    localDisabled.current = false;
    isAnimatingOut.current = false;
    exitProgress.value = 0;
  }, [exitProgress]);

  const handlePress = useCallback(async (event?: GestureResponderEvent) => {
    event?.preventDefault?.();
    event?.stopPropagation?.();

    if (disabled || localDisabled.current) {
      return;
    }

    localDisabled.current = true;
    const result = await Promise.resolve(onPress(word) as any);
    const accepted = result !== false;

    if (variant === 'pool') {
      if (accepted) {
        isAnimatingOut.current = true;
        exitProgress.value = withTiming(1, { duration: 140 }, () => {
          runOnJS(finishInteraction)();
        });
      } else {
        runOnJS(finishInteraction)();
        resetPressFeedback();
      }
    } else {
      resetPressFeedback();
      runOnJS(() => {
        setTimeout(finishInteraction, 120);
      })();
    }
  }, [disabled, exitProgress, finishInteraction, onPress, resetPressFeedback, variant, word]);

  const tileBackgroundStyle = useMemo<ViewStyle>(() => {
    return StyleSheet.flatten([
      styles.tile,
      variant === 'pool' ? { backgroundColor: getWordColor(word) } : styles.arrangedTile,
      isPrefilled ? styles.prefilledTile : null,
      highlightSuccess ? styles.highlightTile : null,
      compact && variant === 'pool' ? styles.compactTile : null,
    ]) as ViewStyle;
  }, [compact, highlightSuccess, isPrefilled, styles.arrangedTile, styles.compactTile, styles.highlightTile, styles.prefilledTile, styles.tile, variant, word]);

  const textStyle = useMemo(() => {
    if (variant === 'arranged') return styles.arrangedText;
    return compact ? styles.tileTextCompact : styles.tileText;
  }, [compact, styles.arrangedText, styles.tileText, styles.tileTextCompact, variant]);

  return (
    <Animated.View style={[tileBackgroundStyle, animatedContainerStyle]} pointerEvents={localDisabled.current ? 'none' : 'auto'}>
      <AnimatedPressable
        android_disableSound
        style={[styles.pressable, animatedPressableStyle]}
        hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
        pressRetentionOffset={{ top: 4, bottom: 4, left: 4, right: 4 }}
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        onPress={handlePress}
        disabled={disabled}
      >
        <Text
          style={textStyle}
          numberOfLines={1}
          adjustsFontSizeToFit
          minimumFontScale={compact && variant === 'pool' ? 0.75 : 0.9}
        >
          {word}
        </Text>
      </AnimatedPressable>
    </Animated.View>
  );
});

VerseBuilderWordTile.displayName = 'VerseBuilderWordTile';

const createStyles = (theme: Theme) =>
  StyleSheet.create({
    tile: {
      minWidth: WORD_TILE_SIZE,
      maxWidth: '100%',
      paddingVertical: 10,
      paddingHorizontal: theme.spacing?.md ?? 12,
      borderRadius: theme.borderRadius?.lg ?? 16,
      justifyContent: 'center',
      alignItems: 'center',
      marginHorizontal: theme.spacing?.xs ?? 6,
      flexShrink: 1,
      borderWidth: 1,
      borderColor: 'rgba(255,255,255,0.2)',
      shadowColor: '#000',
      shadowOpacity: 0.2,
      shadowRadius: 6,
      shadowOffset: { width: 0, height: 3 },
      elevation: 4,
      backgroundColor: '#5566CC',
    },
    arrangedTile: {
      backgroundColor: `${theme.colors.surface}E6`,
      borderColor: `${theme.colors.text.secondary}26`,
    },
    highlightTile: {
      shadowColor: theme.colors.secondary,
      shadowOpacity: 0.35,
      shadowRadius: 12,
      borderColor: theme.colors.secondary,
      borderWidth: 2,
    },
    compactTile: {
      paddingHorizontal: Math.max(8, (theme.spacing?.sm ?? 8)),
      paddingVertical: 8,
      marginHorizontal: Math.max(4, (theme.spacing?.xs ?? 6) * 0.75),
    },
    prefilledTile: {
      opacity: 0.82,
      borderWidth: 2,
      borderColor: theme.colors.primary,
      shadowColor: theme.colors.primary,
      shadowOpacity: 0.28,
    },
    tileText: {
      color: '#FFFFFF',
      fontSize: 15,
      fontWeight: '700',
      textAlign: 'center',
      textShadowColor: 'rgba(0,0,0,0.3)',
      textShadowOffset: { width: 0, height: 1 },
      textShadowRadius: 2,
    },
    tileTextCompact: {
      color: '#FFFFFF',
      fontSize: 13,
      fontWeight: '700',
      textAlign: 'center',
      textShadowColor: 'rgba(0,0,0,0.25)',
      textShadowOffset: { width: 0, height: 1 },
      textShadowRadius: 1,
    },
    arrangedText: {
      color: theme.colors.text.primary,
      fontSize: 15,
      fontWeight: '700',
      textAlign: 'center',
    },
    pressable: {
      width: '100%',
      alignItems: 'center',
      justifyContent: 'center',
    },
  });

export default VerseBuilderWordTile;
