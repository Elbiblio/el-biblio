// components/ProgressIndicator.tsx
import React from 'react';
import { StyleSheet } from 'react-native';
import Animated, { 
  useAnimatedStyle,
  interpolate,
  SharedValue,
  Extrapolation
} from 'react-native-reanimated';
import { SCREEN_DIMENSIONS } from '../constants';
import { useTheme } from '@/contexts/ThemeContext';

interface ProgressIndicatorProps {
  scrollX: SharedValue<number>;
  index: number;
  total: number;
}

const ProgressIndicator: React.FC<ProgressIndicatorProps> = ({
  scrollX,
  index,
  total,
}) => {
  const theme = useTheme();
  const styles = getStyles(theme);
  const animatedStyle = useAnimatedStyle(() => {
    const inputRange = [
      (index - 1) * SCREEN_DIMENSIONS.width,
      index * SCREEN_DIMENSIONS.width,
      (index + 1) * SCREEN_DIMENSIONS.width
    ];

    const scale = interpolate(
      scrollX.value,
      inputRange,
      [1, 3, 1],
      Extrapolation.CLAMP
    );

    const opacity = interpolate(
      scrollX.value,
      inputRange,
      [0.5, 1, 0.5],
      Extrapolation.CLAMP
    );

    const backgroundColor = interpolate(
      scrollX.value,
      inputRange,
      [0, 1, 0],
      Extrapolation.CLAMP
    );

    return {
      opacity,
      transform: [{ scaleX: scale }],
      backgroundColor: backgroundColor === 0 ? theme.colors.border : theme.colors.primary
    };
  });

  return (
    <Animated.View
      style={[
        styles.progressDot,
        animatedStyle
      ]}
    />
  );
};

const getStyles = (theme: any) =>
  StyleSheet.create({
    progressDot: {
      width: 8, // Base width
      height: 4,
      borderRadius: theme.borderRadius.sm,
      backgroundColor: theme.colors.border,
    },
  });

export default ProgressIndicator;