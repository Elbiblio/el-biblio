import React from 'react';
import { StyleSheet, TouchableOpacity, View } from 'react-native';
import { ChevronLeft, ChevronRight } from './Icons';
import Animated, { 
  interpolate, 
  useAnimatedStyle, 
  withSequence, 
  withSpring,
  useSharedValue,
  Extrapolation 
} from 'react-native-reanimated';
import { useTheme } from '@/contexts/ThemeContext';
import { BlurView } from 'expo-blur';

interface ScrollIndicatorProps {
  direction: 'left' | 'right';
  onPress?: () => void;
  visible?: boolean;
}

const ScrollIndicator = ({ direction, onPress, visible = true }: ScrollIndicatorProps) => {
  const theme = useTheme();
  const scale = useSharedValue(1);

  const handlePress = () => {
    scale.value = withSequence(
      withSpring(0.9),
      withSpring(1)
    );
    onPress?.();
  };

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    opacity: visible ? 1 : 0,
  }));

  const Icon = direction === 'left' ? ChevronLeft : ChevronRight;

  return (
    <Animated.View style={[styles.container, animatedStyle, {left: direction === 'left' ? 0 : undefined, right: direction === 'right' ? 0 : undefined}]}>
      <TouchableOpacity
        onPress={handlePress}
        style={[styles.button, { backgroundColor: `${theme.colors.background}`, opacity: 0.7 }]}
      >
        <BlurView intensity={10} style={StyleSheet.absoluteFill} />
        <Icon size={24} color={theme.colors.text.primary} />
      </TouchableOpacity>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    top: '50%',
    transform: [{ translateY: -20 }],
    zIndex: 10,
  },
  button: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: "#000",
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.15,
    shadowRadius: 3.84,
    elevation: 5,
    overflow: 'hidden',
  },
});

export default ScrollIndicator;