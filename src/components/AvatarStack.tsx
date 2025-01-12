import React from 'react';
import { View, Image, Text, StyleSheet, Pressable, Platform } from 'react-native';
import Animated, { 
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withSequence,
  withTiming,
  interpolate,
} from 'react-native-reanimated';
import { User } from '../types';
import { getCurrentTheme } from '@/stores/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';

interface AvatarStackProps {
  users: User[];
  maxAvatars?: number;
  size?: number;
  offset?: number;
  onPress?: () => void;
  showRemaining?: boolean;
}

export const AvatarStack: React.FC<AvatarStackProps> = ({
  users,
  maxAvatars = 3,
  size = 32,
  offset = 20,
  onPress,
  showRemaining = true,
}) => {
  const displayUsers = users.slice(0, maxAvatars);
  const remainingCount = Math.max(0, users.length - maxAvatars);
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  // Shared values for hover animations
  const hoveredIndex = useSharedValue(-1);
  const pressed = useSharedValue(-1);

  const Avatar = ({ user, index }: { user: User; index: number }) => {
    const scale = useSharedValue(1);
    const translateX = useSharedValue(0);

    const animatedStyle = useAnimatedStyle(() => {
      const isHovered = hoveredIndex.value >= index;
      const isPressed = pressed.value === index;
      
      const baseTranslate = index * offset;
      const hoverOffset = isHovered ? 10 : 0;
      
      return {
        transform: [
          { 
            translateX: withSpring(baseTranslate + hoverOffset, {
              damping: 15,
              stiffness: 150
            })
          },
          { 
            scale: withSpring(isPressed ? 1.1 : 1, {
              damping: 15,
              stiffness: 150
            })
          }
        ],
        zIndex: isPressed ? 999 : displayUsers.length - index,
      };
    });

    const handlePressIn = () => {
      pressed.value = index;
      hoveredIndex.value = index;
    };

    const handlePressOut = () => {
      pressed.value = -1;
      hoveredIndex.value = -1;
    };

    return (
      <Pressable 
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
      >
        <Animated.View style={[styles.avatarContainer, animatedStyle]}>
          <Image
            source={{ uri: user.avatar }}
            style={[
              styles.avatar,
              {
                width: size,
                height: size,
                borderRadius: size / 2,
              }
            ]}
          />
        </Animated.View>
      </Pressable>
    );
  };

  // Stack container width calculation
  const containerWidth = displayUsers.length * offset + size - offset;

  return (
    <View style={[styles.container, { width: containerWidth }]}>
      {displayUsers.map((user, index) => (
        <Avatar 
          key={user.id} 
          user={user} 
          index={index}
        />
      ))}
      
      {showRemaining && remainingCount > 0 && (
        <Animated.View
          style={[
            styles.remainingContainer,
            {
              width: size,
              height: size,
              borderRadius: size / 2,
              transform: [{ translateX: displayUsers.length * offset }],
            }
          ]}
        >
          <Text style={styles.remainingText}>
            +{remainingCount}
          </Text>
        </Animated.View>
      )}
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    height: 40,
    position: 'relative',
  },
  avatarContainer: {
    position: 'absolute',
    borderWidth: 2,
    borderColor: theme.colors.background,
    borderRadius: 999,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 3,
      },
    }),
  },
  avatar: {
    backgroundColor: theme.colors.surface,
  },
  remainingContainer: {
    position: 'absolute',
    backgroundColor: `${theme.colors.primary}15`,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: theme.colors.background,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 3,
      },
    }),
  },
  remainingText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontSize: 12,
    fontWeight: '600',
  },
});

export default AvatarStack;