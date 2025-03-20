import React from 'react';
import { View, StyleSheet } from 'react-native';
import Svg, { Circle } from 'react-native-svg';
import { useAnimatedProps } from 'react-native-reanimated';
import { SharedValue } from 'react-native-reanimated';
import { ReanimatedCircle } from './ReanimatedSvg';

interface AnimatedCircularProgressProps {
  size: number;
  width: number;
  fill: SharedValue<number>; // Progress from 0 to 1
  tintColor: string;
  backgroundColor: string;
  rotation?: number;
  lineCap?: 'butt' | 'round' | 'square';
  children?: React.ReactNode;
  innerBackgroundColor?: string;
}

const AnimatedCircularProgress: React.FC<AnimatedCircularProgressProps> = ({
  size,
  width,
  fill,
  tintColor,
  backgroundColor,
  rotation = 0,
  lineCap = 'round',
  children,
  innerBackgroundColor = 'transparent',
}) => {
  const radius = (size - width) / 2;
  const circumference = 2 * Math.PI * radius;

  const animatedProps = useAnimatedProps(() => ({
    strokeDashoffset: circumference * (1 - fill.value),
  }));

  return (
    <View style={{ width: size, height: size, transform: [{ rotate: `${rotation}deg` }] }}>
      <Svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={backgroundColor}
          strokeWidth={width}
        />
        <ReanimatedCircle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={tintColor}
          strokeWidth={width}
          strokeDasharray={circumference}
          strokeLinecap={lineCap}
          animatedProps={animatedProps}
        />
      </Svg>
      {children && (
        <View
          style={[
            styles.childrenContainer,
            {
              width: size - 2 * width,
              height: size - 2 * width,
              top: width,
              left: width,
              borderRadius: (size - 2 * width) / 2,
              backgroundColor: innerBackgroundColor,
            }
          ]}
        >
          {children}
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  childrenContainer: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  }
});

export default AnimatedCircularProgress;