import React, { useEffect, useRef } from 'react';
import { View, StyleSheet, ViewStyle, Animated, DimensionValue } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';

type SimpleCradleProps = {
  width?: DimensionValue;
  height?: number;
  slotCount?: number;
  highlightIndex?: number;
  style?: ViewStyle;
};

const SimpleCradle: React.FC<SimpleCradleProps> = ({
  width = '100%',
  height = 110,
  slotCount = 6,
  highlightIndex = 0,
  style,
}) => {
  const theme = useTheme();
  const pulse = useRef(new Animated.Value(0.2)).current;

  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, { toValue: 0.5, duration: 900, useNativeDriver: false }),
        Animated.timing(pulse, { toValue: 0.2, duration: 900, useNativeDriver: false }),
      ])
    ).start();
  }, [pulse]);

  const slots = Array.from({ length: slotCount });

  return (
    <View style={[
      styles.container,
      { width: width as DimensionValue, height, backgroundColor: `${theme.colors.surface}BF` },
      style
    ]} pointerEvents="none">
      {/* Soft bowl shape using borders and rounded corners */}
      <View style={[styles.bowl, { borderColor: `${theme.colors.text.secondary}26` }]} />

      {/* Inner rim at the top edge to suggest depth */}
      <View
        style={[
          styles.innerRim,
          { backgroundColor: `${theme.colors.text.primary}10` }
        ]}
      />

      {/* Seat track behind the slots */}
      <View
        style={[
          styles.seatTrack,
          { backgroundColor: `${theme.colors.text.secondary}14` }
        ]}
      />

      {/* Slot guides */}
      <View style={styles.slotsRow}>
        {slots.map((_, idx) => {
          const isNext = idx === Math.max(0, Math.min(slotCount - 1, highlightIndex));
          return (
            <View key={`slot-${idx}`} style={styles.slotWrap}>
              {/* connector */}
              {idx < slotCount - 1 && <View style={[styles.connector, { backgroundColor: `${theme.colors.text.secondary}33` }]} />}

              {/* ring */}
              <View style={[styles.ring, { borderColor: `${theme.colors.text.secondary}66` }]} />

              {/* pulse for next slot */}
              {isNext && (
                <Animated.View
                  style={[
                    styles.pulse,
                    {
                      borderColor: theme.colors.primary,
                      opacity: pulse,
                    },
                  ]}
                />
              )}
            </View>
          );
        })}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignSelf: 'stretch',
    borderRadius: 20,
    overflow: 'hidden',
    justifyContent: 'flex-end',
  },
  bowl: {
    position: 'absolute',
    left: 8,
    right: 8,
    bottom: 8,
    top: 24,
    borderWidth: 1,
    borderRadius: 20,
  },
  innerRim: {
    position: 'absolute',
    left: 12,
    right: 12,
    top: 22,
    height: 10,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
  },
  seatTrack: {
    position: 'absolute',
    left: 18,
    right: 18,
    bottom: 28,
    height: 20,
    borderRadius: 12,
  },
  slotsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 18,
    paddingBottom: 16,
  },
  slotWrap: {
    alignItems: 'center',
    justifyContent: 'center',
    minWidth: 24,
  },
  connector: {
    position: 'absolute',
    top: 11,
    left: '50%',
    width: '200%',
    height: 2,
    transform: [{ translateX: 8 }],
  },
  ring: {
    width: 10,
    height: 10,
    borderRadius: 8,
    borderWidth: 1,
  },
  pulse: {
    position: 'absolute',
    width: 22,
    height: 22,
    borderRadius: 16,
    borderWidth: 1.5,
  },
});

export default SimpleCradle;
