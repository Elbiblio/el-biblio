import React from 'react';
import { View, Image, Text, StyleSheet } from 'react-native';
import Animated, { 
  useAnimatedStyle,
  withSpring 
} from 'react-native-reanimated';
import { User } from '../types';
import { getCurrentTheme } from '@/theme/store';

interface AvatarGroupProps {
  users: User[];
  maxAvatars?: number;
  size?: number;
  spacing?: number;
  onPress?: () => void;
}

export const AvatarGroup: React.FC<AvatarGroupProps> = ({
  users,
  maxAvatars = 3,
  size = 32,
  spacing = 8,
  onPress,
}) => {
  const theme = getCurrentTheme();
  const displayUsers = users.slice(0, maxAvatars);
  const remainingCount = Math.max(0, users.length - maxAvatars);

  const AnimatedImage = Animated.createAnimatedComponent(Image);

  // Create styles with current theme
  const styles = StyleSheet.create({
    container: {
      flexDirection: 'row',
      alignItems: 'center',
    },
    avatarContainer: {
      borderWidth: 2,
      borderColor: theme.colors.background,
      borderRadius: 999,
    },
    avatar: {
      backgroundColor: theme.colors.surface,
    },
    remainingCount: {
      backgroundColor: theme.colors.surface,
      alignItems: 'center',
      justifyContent: 'center',
      borderWidth: 2,
      borderColor: theme.colors.background,
    },
    remainingCountText: {
      ...theme.typography.verse.emphasis,
      color: theme.colors.text.secondary,
    },
  });

  return (
    <View style={styles.container}>
      {displayUsers.map((user, index) => {
        const animatedStyle = useAnimatedStyle(() => ({
          transform: [{ scale: withSpring(1) }],
        }));

        return (
          <Animated.View
            key={user.id}
            style={[
              styles.avatarContainer,
              {
                width: size,
                height: size,
                marginLeft: index === 0 ? 0 : -spacing,
                zIndex: displayUsers.length - index,
              },
              animatedStyle,
            ]}
          >
            <AnimatedImage
              source={{ uri: user.avatar }}
              style={[
                styles.avatar,
                {
                  width: size,
                  height: size,
                  borderRadius: size / 2,
                },
              ]}
            />
          </Animated.View>
        );
      })}
      {remainingCount > 0 && (
        <View
          style={[
            styles.remainingCount,
            {
              width: size,
              height: size,
              borderRadius: size / 2,
              marginLeft: -spacing,
            },
          ]}
        >
          <Text style={styles.remainingCountText}>+{remainingCount}</Text>
        </View>
      )}
    </View>
  );
};