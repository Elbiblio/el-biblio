// components/AnimatedCircularProgress.tsx
import React from 'react';
import { View } from 'react-native';
import Svg, { Circle, Path } from 'react-native-svg';
import Animated, { useAnimatedProps } from 'react-native-reanimated';
import { ReanimatedCircle, ReanimatedPath } from './ReanimatedSvg';

type AnimatedCircularProgressProps = {
  size: number;
  width: number;
  fill: Animated.SharedValue<number>;
  tintColor: string;
  backgroundColor?: string;
  rotation?: number;
  lineCap?: 'butt' | 'round' | 'square';
  children?: React.ReactNode;
};

const AnimatedCircularProgress: React.FC<AnimatedCircularProgressProps> = ({
  size,
  width,
  fill,
  tintColor,
  backgroundColor = '#EEE',
  rotation = 0,
  lineCap = 'round',
  children,
}) => {
  const radius = (size - width) / 2;
  const circumference = radius * 2 * Math.PI;
  
  const animatedProps = useAnimatedProps(() => {
    const strokeDashoffset = circumference - (circumference * fill.value) / 100;
    return {
      strokeDashoffset
    };
  });

  return (
    <View style={{ width: size, height: size }}>
      <Svg width={size} height={size} style={{ transform: [{ rotate: `${rotation}deg` }] }}>
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={backgroundColor}
          strokeWidth={width}
          fill="transparent"
        />
        <ReanimatedPath
          animatedProps={animatedProps}
          d={`M ${size / 2} ${width / 2} A ${radius} ${radius} 0 1 1 ${width / 2} ${size / 2}`}
          stroke={tintColor}
          strokeWidth={width}
          strokeLinecap={lineCap}
          fill="transparent"
          strokeDasharray={`${circumference} ${circumference}`}
        />
      </Svg>
      {children && (
        <View style={{
          position: 'absolute',
          width: '100%',
          height: '100%',
          justifyContent: 'center',
          alignItems: 'center',
        }}>
          {children}
        </View>
      )}
    </View>
  );
};

export default React.memo(AnimatedCircularProgress);