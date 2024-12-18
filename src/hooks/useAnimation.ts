import { useRef, useCallback } from 'react';
import { Animated } from 'react-native';
import { ANIMATIONS } from '../constants';

export const useAnimation = (initialValue: number = 0) => {
  const animation = useRef(new Animated.Value(initialValue)).current;

  const animate = useCallback((toValue: number, config = {}) => {
    return new Promise<void>(resolve => {
      Animated.spring(animation, {
        toValue,
        useNativeDriver: true,
        ...ANIMATIONS.SPRING_CONFIG,
        ...config,
      }).start(() => resolve());
    });
  }, [animation]);

  const timing = useCallback((toValue: number, config = {}) => {
    return new Promise<void>(resolve => {
      Animated.timing(animation, {
        toValue,
        useNativeDriver: true,
        ...ANIMATIONS.TIMING_CONFIG,
        ...config,
      }).start(() => resolve());
    });
  }, [animation]);

  return {
    value: animation,
    animate,
    timing,
  };
};

export const useSequenceAnimation = () => {
  const sequence = useCallback((animations: Animated.CompositeAnimation[]) => {
    return new Promise<void>(resolve => {
      Animated.sequence(animations).start(() => resolve());
    });
  }, []);

  const parallel = useCallback((animations: Animated.CompositeAnimation[]) => {
    return new Promise<void>(resolve => {
      Animated.parallel(animations).start(() => resolve());
    });
  }, []);

  return {
    sequence,
    parallel,
  };
};
