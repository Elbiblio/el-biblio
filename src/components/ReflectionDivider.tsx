import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Animated, { 
  useAnimatedStyle, 
  interpolate,
  Extrapolation,
  SharedValue 
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { ArrowRight, MessageCircle } from './../components/Icons';
import { useTheme } from '@/contexts/ThemeContext';
import type { Theme } from '@/theme';

interface ReflectionDividerProps {
  currentIndex: number;
  totalReflections: number;
  scrollX: SharedValue<number>;
  previewComment?: {
    author: string;
    content: string;
    likes: number;
  };
}

const ReflectionDivider: React.FC<ReflectionDividerProps> = ({
  currentIndex,
  totalReflections,
  scrollX,
  previewComment
}) => {
  const theme = useTheme();
  const styles = createStyles(theme);

  // Animate the scroll indicator dots
  const renderDots = () => {
    return Array.from({ length: totalReflections }).map((_, index) => {
      const animatedStyle = useAnimatedStyle(() => {
        const width = interpolate(
          scrollX.value,
          [
            (index - 1) * 400,
            index * 400,
            (index + 1) * 400
          ],
          [8, 24, 8],
          Extrapolation.CLAMP
        );

        const opacity = interpolate(
          scrollX.value,
          [
            (index - 1) * 400,
            index * 400,
            (index + 1) * 400
          ],
          [0.3, 1, 0.3],
          Extrapolation.CLAMP
        );

        return {
          width,
          opacity
        };
      });

      return (
        <Animated.View
          key={index}
          style={[styles.dot, animatedStyle]}
        />
      );
    });
  };

  return (
    <View style={styles.container}>
      <BlurView intensity={8} style={styles.dividerContent}>
        {/* Counter and Swipe Hint */}
        <View style={styles.swipeHintContainer}>
          <View style={styles.counterContainer}>
            <Text style={styles.counterText}>
              <Text style={styles.currentIndex}>{currentIndex + 1}</Text>
              <Text style={styles.totalCount}>/{totalReflections}</Text>
            </Text>
            <Text style={styles.swipeText}>Swipe to view more reflections</Text>
          </View>
          <ArrowRight size={20} color={theme.colors.primary} />
        </View>

        {/* Scroll Indicator */}
        <View style={styles.scrollIndicator}>
          {renderDots()}
        </View>

      </BlurView>
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    marginVertical: theme.spacing.md,
  },
  dividerContent: {
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    gap: theme.spacing.md,
    backgroundColor: `${theme.colors.surface}80`,
  },
  swipeHintContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  counterContainer: {
    gap: theme.spacing.xs,
  },
  counterText: {
    ...theme.typography.heading.small,
  },
  currentIndex: {
    color: theme.colors.primary,
  },
  totalCount: {
    color: theme.colors.text.secondary,
  },
  swipeText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  scrollIndicator: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  dot: {
    height: 4,
    backgroundColor: theme.colors.primary,
    borderRadius: theme.borderRadius.sm,
  },
  commentPreview: {
    backgroundColor: `${theme.colors.background}80`,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    gap: theme.spacing.xs,
  },
  commentHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    marginBottom: theme.spacing.xs,
  },
  topCommentText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  commentAuthor: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  commentContent: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    lineHeight: 20,
  },
  commentLikes: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.xs,
  },
});

export default ReflectionDivider;