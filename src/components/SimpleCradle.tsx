import React, { useEffect, useRef } from 'react';
import { View, StyleSheet, ViewStyle, Animated, DimensionValue } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
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
  height = 160,
  slotCount = 6,
  highlightIndex = 0,
  style,
}) => {
  const theme = useTheme();
  const pulse = useRef(new Animated.Value(0.2)).current;

  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, { toValue: 0.5, duration: 900, useNativeDriver: true }),
        Animated.timing(pulse, { toValue: 0.2, duration: 900, useNativeDriver: true }),
      ])
    ).start();
  }, [pulse]);

  const slots = Array.from({ length: slotCount });

  // Wood color palette
  const woodColors = {
    light: '#D2B48C', // Light wood
    medium: '#CD853F', // Medium wood
    dark: '#8B4513',   // Dark wood
    darkest: '#654321', // Darkest wood
    highlight: '#F4A460', // Wood highlight
    shadow: '#5D4037',    // Wood shadow
  };

  // Derive proportional metrics from height so the bowl fills the area better
  const rimTopH = Math.max(10, Math.round(height * 0.08));
  const rimBottomH = Math.max(6, Math.round(height * 0.05));
  const bowlInset = Math.max(4, Math.round(height * 0.025));
  const bowlTopOffset = Math.max(8, Math.round(height * 0.09));
  const seatTrackH = Math.max(24, Math.round(height * 0.22));
  const seatTrackBottom = Math.max(20, Math.round(height * 0.24));
  const connectorTop = Math.max(12, Math.round(height * 0.095));
  const ringOuter = Math.max(12, Math.round(height * 0.085));
  const ringInner = Math.max(7, Math.round(ringOuter * 0.6));
  const pulseSize = Math.max(ringOuter + 10, Math.round(height * 0.16));

  return (
    <View style={[
      styles.container,
      { width: width as DimensionValue, height },
      style
    ]} pointerEvents="none">
      {/* Main wooden bowl structure */}
      <LinearGradient
        colors={[woodColors.highlight, woodColors.medium, woodColors.dark]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={[styles.bowl, {
          left: bowlInset,
          right: bowlInset,
          bottom: bowlInset,
          top: bowlTopOffset,
          borderRadius: Math.max(16, Math.round(height * 0.12)),
          borderWidth: 2,
        }]}
      >
        {/* Wood grain overlay */}
        <View style={[styles.woodGrain]} />
        
        {/* Inner shadow for depth */}
        <View style={[styles.innerShadow]} />
      </LinearGradient>

      {/* Decorative wood rim */}
      <LinearGradient
        colors={[woodColors.light, woodColors.medium]}
        start={{ x: 0, y: 0 }}
        end={{ x: 0, y: 1 }}
        style={[styles.rimTop, {
          left: bowlInset + 4,
          right: bowlInset + 4,
          top: Math.max(4, Math.round(height * 0.06)),
          height: rimTopH,
          borderTopLeftRadius: Math.max(12, Math.round(height * 0.09)),
          borderTopRightRadius: Math.max(12, Math.round(height * 0.09)),
        }]}
      />

      {/* Bottom rim with darker wood */}
      <LinearGradient
        colors={[woodColors.dark, woodColors.darkest]}
        start={{ x: 0, y: 0 }}
        end={{ x: 0, y: 1 }}
        style={[styles.rimBottom, {
          left: bowlInset + 4,
          right: bowlInset + 4,
          bottom: 0,
          height: rimBottomH,
          borderBottomLeftRadius: Math.max(12, Math.round(height * 0.09)),
          borderBottomRightRadius: Math.max(12, Math.round(height * 0.09)),
        }]}
      />

      {/* Seat track with carved wood effect */}
      <LinearGradient
        colors={[woodColors.darkest, woodColors.dark, woodColors.medium]}
        start={{ x: 0, y: 0 }}
        end={{ x: 0, y: 1 }}
        style={[styles.seatTrack, {
          left: bowlInset + 14,
          right: bowlInset + 14,
          bottom: seatTrackBottom,
          height: seatTrackH,
          borderRadius: Math.max(12, Math.round(height * 0.1)),
          borderWidth: 1,
        }]}
      >
        {/* Inner highlight for carved effect */}
        <View style={[styles.seatTrackHighlight]} />
      </LinearGradient>

      {/* Wood screws/bolts decoration */}
      <View style={[styles.screw, styles.screwTopLeft, { backgroundColor: woodColors.darkest }]} />
      <View style={[styles.screw, styles.screwTopRight, { backgroundColor: woodColors.darkest }]} />
      <View style={[styles.screw, styles.screwBottomLeft, { backgroundColor: woodColors.darkest }]} />
      <View style={[styles.screw, styles.screwBottomRight, { backgroundColor: woodColors.darkest }]} />

      {/* Slot guides */}
      <View style={[styles.slotsRow, { paddingBottom: Math.max(18, Math.round(height * 0.14)) }]}>
        {slots.map((_, idx) => {
          const isNext = idx === Math.max(0, Math.min(slotCount - 1, highlightIndex));
          return (
            <View key={`slot-${idx}`} style={styles.slotWrap}>
              {/* Wood connector */}
              {idx < slotCount - 1 && (
                <LinearGradient
                  colors={[woodColors.dark, woodColors.medium]}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 0, y: 1 }}
                  style={[styles.connector, { top: connectorTop }]}
                />
              )}

              {/* Wooden ring holder */}
              <LinearGradient
                colors={[woodColors.darkest, woodColors.dark]}
                style={[styles.ringOuter, { width: ringOuter, height: ringOuter, borderRadius: ringOuter / 1.4 }]}
              >
                <View style={[styles.ring, { borderColor: woodColors.medium, width: ringInner, height: ringInner, borderRadius: ringInner / 1.3 }]} />
              </LinearGradient>

              {/* Pulse for next slot */}
              {isNext && (
                <Animated.View
                  style={[
                    styles.pulse,
                    {
                      borderColor: '#FFD700', // Golden highlight for wood theme
                      backgroundColor: 'rgba(255, 215, 0, 0.1)',
                      opacity: pulse,
                      width: pulseSize,
                      height: pulseSize,
                      borderRadius: pulseSize / 1.3,
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
    // Add subtle shadow
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  bowl: {
    position: 'absolute',
    left: 4,
    right: 4,
    bottom: 4,
    top: 20,
    borderRadius: 20,
    borderWidth: 2,
    borderColor: '#8B4513',
  },
  woodGrain: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(139, 69, 19, 0.1)',
    borderRadius: 18,
  },
  innerShadow: {
    position: 'absolute',
    top: 2,
    left: 2,
    right: 2,
    bottom: 2,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: 'rgba(0, 0, 0, 0.2)',
  },
  rimTop: {
    position: 'absolute',
    left: 8,
    right: 8,
    top: 16,
    height: 12,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    borderWidth: 1,
    borderColor: '#CD853F',
  },
  rimBottom: {
    position: 'absolute',
    left: 8,
    right: 8,
    bottom: 0,
    height: 8,
    borderBottomLeftRadius: 16,
    borderBottomRightRadius: 16,
  },
  seatTrack: {
    position: 'absolute',
    left: 18,
    right: 18,
    bottom: 40,
    height: 28,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#654321',
  },
  seatTrackHighlight: {
    position: 'absolute',
    top: 2,
    left: 2,
    right: 2,
    height: 2,
    backgroundColor: 'rgba(244, 164, 96, 0.6)',
    borderRadius: 10,
  },
  screw: {
    position: 'absolute',
    width: 6,
    height: 6,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#2F2F2F',
  },
  screwTopLeft: {
    top: 32,
    left: 16,
  },
  screwTopRight: {
    top: 32,
    right: 16,
  },
  screwBottomLeft: {
    bottom: 16,
    left: 16,
  },
  screwBottomRight: {
    bottom: 16,
    right: 16,
  },
  slotsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 18,
    paddingBottom: 24,
  },
  slotWrap: {
    alignItems: 'center',
    justifyContent: 'center',
    minWidth: 32,
  },
  connector: {
    position: 'absolute',
    top: 15,
    left: '50%',
    width: '200%',
    height: 4,
    transform: [{ translateX: 12 }],
    borderRadius: 2,
  },
  ringOuter: {
    width: 14,
    height: 14,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#8B4513',
  },
  ring: {
    width: 8,
    height: 8,
    borderRadius: 6,
    borderWidth: 1,
    backgroundColor: '#654321',
  },
  pulse: {
    position: 'absolute',
    width: 26,
    height: 26,
    borderRadius: 20,
    borderWidth: 2,
  },
});

export default SimpleCradle;