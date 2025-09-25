import React, { useEffect } from 'react';
import { View, StyleSheet, ViewStyle } from 'react-native';
import Svg, {
  Path,
  Defs,
  LinearGradient,
  Stop,
  Filter,
  FeDropShadow,
  
  G,
  Circle,
} from 'react-native-svg';
import { useTheme } from '@/contexts/ThemeContext';
import Animated, { useSharedValue, useAnimatedProps, withRepeat, withSequence, withTiming } from 'react-native-reanimated';

// Define the types for the component's props
type WordCradleProps = {
  width?: number;
  height?: number;
  colorLight?: string;
  colorMid?: string;
  colorDark?: string;
  style?: ViewStyle;
  pointerEvents?: 'none' | 'auto';
  slotCount?: number;
  highlightIndex?: number;
};

/**
 * A dynamic, premium SVG component that serves as a 'cradle' for words.
 * It uses advanced SVG filters to simulate a natural wood or stone texture.
 *
 * @param {WordCradleProps} props - The component props.
 * @returns {JSX.Element} The WordCradle component.
 */
const WordCradle: React.FC<WordCradleProps> = ({
  width = 380,
  height = 200,
  colorLight,
  colorMid,
  colorDark,
  style,
  pointerEvents = 'none',
  slotCount = 6,
  highlightIndex = 0,
}) => {
  const theme = useTheme();
  const light = colorLight || `${theme.colors.surface}`;
  const mid = colorMid || `${theme.colors.text.secondary}1A`; // subtle tint overlay
  const dark = colorDark || `${theme.colors.text.secondary}33`;

  // Pulse animation for next-slot glow
  const pulse = useSharedValue(0.2);
  useEffect(() => {
    pulse.value = withRepeat(
      withSequence(
        withTiming(0.45, { duration: 900 }),
        withTiming(0.2, { duration: 900 })
      ),
      -1,
      true
    );
  }, [pulse]);

  const AnimatedCircle = Animated.createAnimatedComponent(Circle);
  const animatedProps = useAnimatedProps(() => ({ opacity: pulse.value }));

  // A more complex and organic path for a natural, hand-carved look.
  const pathData = `
    M 0,22
    C ${width * 0.15},5 ${width * 0.35},45 ${width * 0.5},25
    S ${width * 0.7},-5 ${width},30
    L ${width},${height - 35}
    C ${width * 0.8},${height} ${width * 0.65},${height - 45} ${width * 0.5},${height - 28}
    S ${width * 0.2},${height + 5} 0,${height - 25}
    Z
  `;

  return (
    <View style={[styles.container, style]} pointerEvents={pointerEvents}>
      <Svg width={width} height={height} viewBox={`0 0 ${width} ${height}`}>
        <Defs>

          {/* Filter 1: A softer, more realistic drop shadow */}
          <Filter id="shadow" x={-0.2} y={-0.2} width={1.4} height={1.4}>
            <FeDropShadow dx={0} dy={6} stdDeviation={12} />
          </Filter>

          {/* Note: removed complex texture filter to ensure type compatibility on RN-SVG */}

          {/* A richer, three-stop gradient for the base color */}
          <LinearGradient id="grad" x1="0%" y1="0%" x2="0%" y2="100%">
            <Stop offset="0" stopColor={light} />
            <Stop offset="0.5" stopColor={mid} />
            <Stop offset="1" stopColor={dark} />
          </LinearGradient>
        </Defs>

        {/* Layer 1: The base shape with the shadow and gradient */}
        <Path d={pathData} fill="url(#grad)" filter="url(#shadow)" />

        {/* Optional texture layer removed for compatibility */}

        {/* Slot guides and next-slot highlight */}
        {slotCount > 0 && (
          <G>
            {Array.from({ length: slotCount }).map((_, idx) => {
              const x = (width * (idx + 0.5)) / slotCount;
              const y = height * 0.56; // closer to chip baseline
              const isNext = idx === Math.max(0, Math.min(slotCount - 1, highlightIndex));
              return (
                <G key={`guide-${idx}`}>
                  {/* connector line to next slot for a sentence-like cluster */}
                  {idx < slotCount - 1 && (
                    <Path
                      d={`M ${x+3} ${y} Q ${(x + (width * (idx + 1.5)) / slotCount) / 2} ${y + 4} ${(width * (idx + 1.5)) / slotCount - 3} ${y}`}
                      stroke={`${theme.colors.text.secondary}40`}
                      strokeWidth={1}
                      strokeDasharray="4,2"
                    />
                  )}
                  <Circle cx={x} cy={y} r={3.5} stroke={`${theme.colors.text.secondary}66`} strokeWidth={1} fill="none" />
                  {isNext && (
                    <>
                      <AnimatedCircle cx={x} cy={y} r={7} stroke={theme.colors.primary} strokeWidth={1.5} fill="none" animatedProps={animatedProps as any} />
                      <AnimatedCircle cx={x} cy={y} r={10} stroke={theme.colors.primary} strokeWidth={1} fill="none" animatedProps={animatedProps as any} />
                    </>
                  )}
                </G>
              );
            })}
          </G>
        )}
      </Svg>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignSelf: 'stretch',
  },
});

export default WordCradle;