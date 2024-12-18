import { Animated, Easing } from 'react-native';

export const createSpringTransition = (
  value: Animated.Value,
  toValue: number,
  config = {}
) => {
  return Animated.spring(value, {
    toValue,
    useNativeDriver: true,
    damping: 15,
    mass: 1,
    stiffness: 90,
    ...config,
  });
};

export const createTimingTransition = (
  value: Animated.Value,
  toValue: number,
  config = {}
) => {
  return Animated.timing(value, {
    toValue,
    useNativeDriver: true,
    duration: 300,
    easing: Easing.inOut(Easing.ease),
    ...config,
  });
};

export const interpolateValue = (
  value: Animated.Value,
  inputRange: number[],
  outputRange: number[] | string[]
) => {
  return value.interpolate({
    inputRange,
    outputRange,
    extrapolate: 'clamp',
  });
};

export const createPulseAnimation = (
  value: Animated.Value,
  config = { scale: 1.2, duration: 200 }
) => {
  return Animated.sequence([
    Animated.timing(value, {
      toValue: config.scale,
      duration: config.duration,
      useNativeDriver: true,
    }),
    Animated.timing(value, {
      toValue: 1,
      duration: config.duration,
      useNativeDriver: true,
    }),
  ]);
};
