import React, { useEffect } from 'react';
import { View, Text, Image, StyleSheet, Animated } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { useAnimation } from '../hooks/useAnimation';
import * as SplashScreen from 'expo-splash-screen';

// Prevent the splash screen from auto-hiding
SplashScreen.preventAutoHideAsync();

const CustomSplash = ({ onAnimationComplete }: { onAnimationComplete?: () => void }) => {
  const theme = useTheme();
  const fadeAnim = useAnimation(0);
  const scaleAnim = useAnimation(0.9);

  useEffect(() => {
    const startAnimations = async () => {
      // Hide the native splash screen
      await SplashScreen.hideAsync();
      
      // Start our custom animations
      await Promise.all([
        fadeAnim.animate(1, { duration: 800 }),
        scaleAnim.animate(1, { duration: 800 }),
      ]);

      // Notify parent component when animations are complete
      onAnimationComplete?.();
    };

    startAnimations();
  }, []);

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.colors.background,
      alignItems: 'center',
      justifyContent: 'center',
    },
    content: {
      alignItems: 'center',
    },
    icon: {
      width: 120,
      height: 120,
      marginBottom: theme.spacing.lg,
    },
    title: {
      ...theme.typography.heading.large,
      color: theme.colors.primary,
      marginBottom: theme.spacing.sm,
    },
    subtitle: {
      ...theme.typography.body.sans,
      color: theme.colors.text.secondary,
    },
  });

  return (
    <View style={styles.container}>
      <Animated.View
        style={[
          styles.content,
          {
            opacity: fadeAnim.value,
            transform: [{ scale: scaleAnim.value }],
          },
        ]}
      >
        <Image
          source={require('../../assets/penheart.png')}
          style={styles.icon}
          resizeMode="cover"
        />
        <Text style={styles.title}>El-Biblio</Text>
        <Text style={styles.subtitle}>Share and grow in your faith journey</Text>
      </Animated.View>
    </View>
  );
};

export default CustomSplash;