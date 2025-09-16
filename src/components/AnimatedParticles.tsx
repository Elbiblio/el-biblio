// components/AnimatedParticles.tsx
import React, { memo, useMemo } from 'react';
import { View } from 'react-native';
import Svg from 'react-native-svg';
import Animated, { useAnimatedProps, useAnimatedStyle } from 'react-native-reanimated';
import { ReanimatedCircle } from './ReanimatedSvg';

type AnimatedParticlesProps = {
  count: number;
  color: string;
  radius: number;
  speed: number;
  anim: Animated.SharedValue<number>;
  minOpacity?: number;
};

const AnimatedParticles: React.FC<AnimatedParticlesProps> = ({
  count,
  color,
  radius,
  speed,
  anim,
  minOpacity = 0.3,
}) => {
  const particles = useMemo(() => 
    Array.from({ length: count }).map((_, i) => ({
      id: i,
      angle: (Math.PI * 2 * i) / count,
      distance: radius + (Math.random() * radius * 0.5),
      delay: Math.random() * speed * 1000,
      scale: 0.5 + Math.random() * 0.5,
    })), [count, radius, speed]);

  return (
    <View pointerEvents="none">
      <Svg width={radius * 2} height={radius * 2}>
        {particles.map((particle) => {
          const x = radius + Math.cos(particle.angle) * particle.distance;
          const y = radius + Math.sin(particle.angle) * particle.distance;
          
          const animatedProps = useAnimatedProps(() => {
            const opacity = minOpacity + (0.7 - minOpacity) * anim.value;
            const scale = particle.scale * (0.8 + 0.2 * anim.value);
            
            return {
              opacity,
              r: (radius / 8) * scale,
            };
          });

          return (
            <ReanimatedCircle
              key={particle.id}
              cx={x}
              cy={y}
              fill={color}
              animatedProps={animatedProps}
            />
          );
        })}
      </Svg>
    </View>
  );
};

export default AnimatedParticles;