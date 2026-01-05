import React, { useEffect, useState, useRef } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Platform,
  ActivityIndicator,
  Dimensions,
  LayoutChangeEvent,
  findNodeHandle,
  type LayoutRectangle,
  Clipboard,
} from 'react-native';
import { BlurView } from 'expo-blur';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
} from 'react-native-reanimated';
import { Copy, ChevronDown, X } from '@/components/Icons';
import { useTheme } from '@/contexts/ThemeContext';
import * as Haptics from 'expo-haptics';
import { Theme } from '@/theme';

const SCREEN_WIDTH = Dimensions.get('window').width;
const SCREEN_HEIGHT = Dimensions.get('window').height;
const TOOLTIP_WIDTH = Math.min(400, SCREEN_WIDTH * 0.9);
const MARGIN = 16;

interface BibleVerse {
  book: string;
  chapter: number;
  verse: number;
  text: string;
}

interface VerseTooltipProps {
  verseRef: string; // Format: "John 3:16"
  targetRef: React.RefObject<View | null> | React.MutableRefObject<View | null>;
  onClose: () => void;
}

const TRANSLATIONS = [
  { id: 'en-asv', name: 'American Standard Version' },
  { id: 'en-kjv', name: 'King James Version' },
] as const;

type TranslationType = typeof TRANSLATIONS[number]['id'];

// Helper to measure a component's position on screen
const measureComponent = (
  ref: React.RefObject<View | null> | React.MutableRefObject<View | null>
): Promise<LayoutRectangle> => {
  return new Promise((resolve) => {
    const node = findNodeHandle(ref.current);
    if (!node) {
      resolve({ x: 0, y: 0, width: 0, height: 0 });
      return;
    }

    ref.current?.measureInWindow((x, y, width, height) => {
      resolve({ x, y, width, height });
    });
  });
};

// Tooltip positioning helper
const calculateTooltipPosition = (
  targetLayout: LayoutRectangle,
  tooltipLayout: LayoutRectangle
) => {
  let x = targetLayout.x + (targetLayout.width - TOOLTIP_WIDTH) / 2; // Center align
  let y = targetLayout.y + targetLayout.height + 10; // 10px gap

  // Horizontal positioning
  if (x + TOOLTIP_WIDTH > SCREEN_WIDTH - MARGIN) {
    x = SCREEN_WIDTH - TOOLTIP_WIDTH - MARGIN;
  }
  if (x < MARGIN) {
    x = MARGIN;
  }

  // Vertical positioning
  if (y + tooltipLayout.height > SCREEN_HEIGHT - MARGIN) {
    // Show above the target if there's not enough space below
    y = targetLayout.y - tooltipLayout.height - 10;
  }

  return { x, y };
};

const VerseTooltip: React.FC<VerseTooltipProps> = ({
  verseRef,
  targetRef,
  onClose,
}) => {
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const tooltipRef = useRef<View>(null);
  
  // Animation and position values
  const opacity = useSharedValue(0);
  const scale = useSharedValue(0.95);
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const [tooltipLayout, setTooltipLayout] = useState<LayoutRectangle | null>(null);

  // Content states
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [verse, setVerse] = useState<BibleVerse | null>(null);
  const [translation, setTranslation] = useState<TranslationType>('en-kjv');
  const [showTranslations, setShowTranslations] = useState(false);

  // Position calculation effect
  useEffect(() => {
    const calculatePosition = async () => {
      const targetLayout = await measureComponent(targetRef);
      
      if (tooltipLayout) {
        const newPosition = calculateTooltipPosition(targetLayout, tooltipLayout);
        setPosition(newPosition);
        // Start entrance animation after positioning
        opacity.value = withTiming(1, { duration: 200 });
        scale.value = withSpring(1, {
          damping: 15,
          stiffness: 150,
        });
      }
    };

    calculatePosition();
  }, [tooltipLayout, targetRef]);

  // Parse verse reference and fetch verse data
  useEffect(() => {
    const fetchVerse = async () => {
      try {
        setLoading(true);
        setError(null);

        const { book, chapter, verse } = parseVerseReference(verseRef);
        const response = await fetch(
          `https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles/${translation}/books/${book}/chapters/${chapter}/verses/${verse}.json`
        );

        if (!response.ok) throw new Error('Failed to fetch verse');
        
        const data = await response.json();
        setVerse(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load verse');
      } finally {
        setLoading(false);
      }
    };

    fetchVerse();
  }, [verseRef, translation]);

  const parseVerseReference = (ref: string) => {
    const match = ref.match(/^(\d?\s*\w+)\s*(\d+):(\d+)$/);
    if (!match) throw new Error('Invalid verse reference format');
    
    const [, book, chapter, verse] = match;
    return {
      book: book.toLowerCase().replace(/\s+/g, ''),
      chapter: parseInt(chapter),
      verse: parseInt(verse)
    };
  };

  const handleLayout = (event: LayoutChangeEvent) => {
    setTooltipLayout(event.nativeEvent.layout);
  };

  const handleClose = () => {
    opacity.value = withTiming(0, { duration: 150 });
    scale.value = withSpring(0.95);
    setTimeout(onClose, 150);
  };

  const handleCopy = async () => {
    if (verse) {
      const textToCopy = `${verse.text} (${verseRef} ${translation})`;
      await Clipboard.setString(textToCopy);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    }
  };

  const handleTranslationChange = (newTranslation: TranslationType) => {
    setTranslation(newTranslation);
    setShowTranslations(false);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  };

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [{ scale: scale.value }],
    left: position.x,
    top: position.y,
  }));

  return (
    <View style={StyleSheet.absoluteFill}>
      <TouchableOpacity 
        style={styles.backdrop} 
        activeOpacity={1} 
        onPress={handleClose}
      />
      <Animated.View
        ref={tooltipRef}
        onLayout={handleLayout}
        style={[styles.container, animatedStyle]}
      >
        <BlurView intensity={15} style={StyleSheet.absoluteFill} pointerEvents="none" />
        <View style={styles.content}>
          {/* Header */}
          <View style={styles.header}>
            <View style={styles.titleContainer}>
              <Text style={styles.verseRef}>{verseRef}</Text>
              <TouchableOpacity 
                style={styles.translationButton}
                onPress={() => setShowTranslations(!showTranslations)}
              >
                <Text style={styles.translationText}>
                  {TRANSLATIONS.find(t => t.id === translation)?.name}
                </Text>
                <ChevronDown 
                  size={16} 
                  color={theme.colors.text.secondary}
                  style={{ 
                    transform: [{ 
                      rotate: showTranslations ? '180deg' : '0deg' 
                    }]
                  }}
                />
              </TouchableOpacity>
            </View>
            <TouchableOpacity 
              onPress={handleClose}
              hitSlop={{ top: 10, right: 10, bottom: 10, left: 10 }}
            >
              <X size={20} color={theme.colors.text.secondary} />
            </TouchableOpacity>
          </View>

          {/* Translation Selector */}
          {showTranslations && (
            <View style={styles.translationsList}>
              {TRANSLATIONS.map((t) => (
                <TouchableOpacity
                  key={t.id}
                  style={[
                    styles.translationOption,
                    translation === t.id && styles.activeTranslation
                  ]}
                  onPress={() => handleTranslationChange(t.id)}
                >
                  <Text style={[
                    styles.translationOptionText,
                    translation === t.id && styles.activeTranslationText
                  ]}>
                    {t.name}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          )}

          {/* Verse Content */}
          <View style={styles.verseContainer}>
            {loading ? (
              <ActivityIndicator color={theme.colors.primary} />
            ) : error ? (
              <Text style={styles.errorText}>{error}</Text>
            ) : verse ? (
              <Text style={styles.verseText}>{verse.text}</Text>
            ) : null}
          </View>

          {/* Actions */}
          <View style={styles.actions}>
            <TouchableOpacity
              style={styles.copyButton}
              onPress={handleCopy}
              disabled={!verse}
            >
              <Copy size={16} color={theme.colors.primary} />
              <Text style={styles.copyText}>Copy Verse</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Animated.View>
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  backdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0, 0, 0, 0.3)',
  },
  container: {
    position: 'absolute',
    width: TOOLTIP_WIDTH,
    borderRadius: theme.borderRadius.lg,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: `${theme.colors.primary}15`,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.15,
        shadowRadius: 12,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  content: {
    backgroundColor: `${theme.colors.background}F2`,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    padding: theme.spacing.md,
    paddingBottom: theme.spacing.sm,
  },
  titleContainer: {
    flex: 1,
    marginRight: theme.spacing.md,
  },
  verseRef: {
    ...theme.typography.verse.emphasis,
    color: theme.colors.primary,
    fontSize: 18,
    marginBottom: 4,
  },
  translationButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  translationText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    fontSize: 13,
  },
  translationsList: {
    marginHorizontal: theme.spacing.md,
    marginBottom: theme.spacing.sm,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.md,
    overflow: 'hidden',
  },
  translationOption: {
    padding: theme.spacing.sm,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: theme.colors.border,
  },
  activeTranslation: {
    backgroundColor: `${theme.colors.primary}10`,
  },
  translationOptionText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  activeTranslationText: {
    color: theme.colors.primary,
    fontWeight: '600',
  },
  verseContainer: {
    minHeight: 60,
    padding: theme.spacing.md,
    paddingTop: 0,
  },
  verseText: {
    ...theme.typography.verse.regular,
    color: theme.colors.text.primary,
    fontSize: 16,
    lineHeight: 24,
  },
  errorText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.error,
    textAlign: 'center',
  },
  actions: {
    flexDirection: 'row',
    padding: theme.spacing.md,
    paddingTop: theme.spacing.sm,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: theme.colors.border,
  },
  copyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: `${theme.colors.primary}15`,
  },
  copyText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontSize: 12,
    fontWeight: '600',
  },
});

export default VerseTooltip;