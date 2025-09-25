import React, { memo } from 'react';
import { View, StyleSheet, ViewStyle, DimensionValue } from 'react-native';
import Svg, { Path, Defs, LinearGradient, Stop, Circle, G } from 'react-native-svg';
import { useTheme } from '@/contexts/ThemeContext';

type CradleProps = {
  width?: DimensionValue;
  height?: number;
  slotCount?: number;
  highlightIndex?: number; // which slot to highlight (0-based)
  style?: ViewStyle;
  pointerEvents?: 'none' | 'auto';
};

const Cradle: React.FC<CradleProps> = ({
  width = '100%',
  height = 140,
  slotCount = 6,
  highlightIndex = 0,
  style,
  pointerEvents = 'none',
}) => {
  const theme = useTheme();
  const surface = theme.colors.surface;
  const accent = theme.colors.primary;
  const border = `${theme.colors.text.secondary}25`;

  const viewBoxW = 100;
  const viewBoxH = 40;

  const spacing = viewBoxW / Math.max(1, slotCount);
  const slotY = 26;

  return (
    <View style={[styles.container, { width: width as DimensionValue, height }, style]} pointerEvents={pointerEvents}>
      <Svg height="100%" width="100%" viewBox={`0 0 ${viewBoxW} ${viewBoxH}`}>
        <Defs>
          <LinearGradient id="cradleGrad" x1="0" y1="0" x2="0" y2="1">
            <Stop offset="0" stopColor={surface} stopOpacity={0.92} />
            <Stop offset="1" stopColor={surface} stopOpacity={0.75} />
          </LinearGradient>
        </Defs>

        {/* Main soft cradle shape */}
        <Path
          d={`M0 30 Q20 40 40 30 Q60 40 80 30 Q100 40 100 30 L100 12 Q80 4 60 12 Q40 4 20 12 Q0 4 0 12 Z`}
          fill={'url(#cradleGrad)'}
          stroke={border}
          strokeWidth={0.6}
        />

        {/* Slots with subtle markers */}
        <G opacity={0.75}>
          {Array.from({ length: slotCount }).map((_, idx) => {
            const x = spacing * (idx + 0.5);
            const isNext = idx === highlightIndex;
            return (
              <G key={`slot-${idx}`}>
                {/* baseline arc */}
                <Path
                  d={`M${x - 2} ${slotY} Q${x} ${slotY + 4} ${x + 2} ${slotY}`}
                  fill="none"
                  stroke={border}
                  strokeWidth={0.5}
                  strokeDasharray="1,1"
                />
                {/* glow for next slot */}
                {isNext && (
                  <>
                    <Circle cx={x} cy={slotY - 1} r={3.5} fill="none" stroke={accent} strokeOpacity={0.3} strokeWidth={1.2} />
                    <Circle cx={x} cy={slotY - 1} r={5.5} fill="none" stroke={accent} strokeOpacity={0.18} strokeWidth={0.8} />
                  </>
                )}
              </G>
            );
          })}
        </G>

        {/* Decorative subtle side petals */}
        <Path d="M5 16 Q3 11 5 6 Q7 11 5 16 M5 16 Q7 21 5 26 Q3 21 5 16" fill={accent} opacity={0.10} />
        <Path d="M95 16 Q93 11 95 6 Q97 11 95 16 M95 16 Q97 21 95 26 Q93 21 95 16" fill={accent} opacity={0.10} />
      </Svg>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignSelf: 'stretch',
    justifyContent: 'center',
  },
});

export default memo(Cradle);