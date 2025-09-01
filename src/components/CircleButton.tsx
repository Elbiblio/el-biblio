import React from 'react';
import { 
  Platform, 
  Pressable, 
  StyleSheet, 
  ViewStyle 
} from 'react-native';
import Animated, { 
  useAnimatedStyle, 
  withSpring,
  useSharedValue 
} from 'react-native-reanimated';
import { Plus } from './Icons';
import { useTheme } from '@/contexts/ThemeContext';
import type { IconProps } from './Icons';

interface CircleButtonProps {
  size?: number;
  onPress?: () => void;
  Icon?: React.ComponentType<IconProps> | React.ReactElement<IconProps>;
  style?: ViewStyle;
  disabled?: boolean;
}

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

const CircleButton: React.FC<CircleButtonProps> = ({ 
  size = 40,
  onPress,
  Icon: IconProp = Plus,
  style,
  disabled = false
}) => {
  const theme = useTheme();
  const styles = getStyles(theme);
  const scale = useSharedValue(1);

  const handlePress = () => {
    scale.value = withSpring(0.92, {}, () => {
      scale.value = withSpring(1);
    });
    onPress?.();
  };

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }]
  }));

  return (
    <Animated.View style={[animatedStyle, style]}>
      <AnimatedPressable
        onPress={handlePress}
        disabled={disabled}
        style={[
          styles.button,
          {
            width: size,
            height: size,
            borderRadius: size / 2,
            backgroundColor: disabled 
              ? theme.colors.secondary 
              : theme.colors.primary,
          }
        ]}
        android_ripple={{
          color: theme.colors.text.inverse,
          borderless: true,
          foreground: true,
          radius: size / 2,
        }}
      >
        {typeof IconProp === 'function' ? (
          <IconProp size={size * 0.5} color={theme.colors.text.inverse} strokeWidth={2.5} />
        ) : (
          React.cloneElement(IconProp, {
            size: size * 0.5,
            color: theme.colors.text.inverse,
            strokeWidth: 2.5,
          })
        )}
      </AnimatedPressable>
    </Animated.View>
  );
};
const getStyles = (theme: any) =>
  StyleSheet.create({
    button: {
      alignItems: 'center',
      justifyContent: 'center',
      overflow: 'hidden',
      backgroundColor: theme.colors.primary,
      borderWidth: 2,
      borderColor: theme.colors.background,
      ...Platform.select({
        ios: {
          shadowColor: theme.colors.primary,
          shadowOffset: { width: 0, height: 2 },
          shadowOpacity: 0.2,
          shadowRadius: 4,
        },
        android: {
          elevation: 4,
        },
      }),
    },
  });
export default React.memo(CircleButton);