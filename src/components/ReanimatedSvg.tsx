import React from 'react';
import Animated from 'react-native-reanimated';
import { Circle, Path } from 'react-native-svg';

export const ReanimatedPath = Animated.createAnimatedComponent(Path);
export const ReanimatedCircle = Animated.createAnimatedComponent(Circle); 