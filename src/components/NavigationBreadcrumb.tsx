import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Animated, {
  useAnimatedStyle,
  withSpring,
  interpolateColor,
} from 'react-native-reanimated';
import { ChevronRight } from './Icons';
import { getCurrentTheme } from '@/stores/theme';

const theme = getCurrentTheme();

interface NavigationBreadcrumbProps {
  steps: string[];
  currentStep: number;
}

export const NavigationBreadcrumb: React.FC<NavigationBreadcrumbProps> = ({
  steps,
  currentStep,
}) => {
  return (
    <View style={styles.container}>
      {steps.map((step, index) => {
        const isActive = index === currentStep;
        const isLast = index === steps.length - 1;

        const stepStyle = useAnimatedStyle(() => ({
          color: interpolateColor(
            withSpring(isActive ? 1 : 0),
            [0, 1],
            [theme.colors.text.secondary, theme.colors.text.primary]
          ),
        }));

        return (
          <React.Fragment key={step}>
            <Animated.Text style={[styles.step, stepStyle]}>
              {step}
            </Animated.Text>
            {!isLast && (
              <ChevronRight
                size={16}
                color={theme.colors.text.secondary}
                style={styles.chevron}
              />
            )}
          </React.Fragment>
        );
      })}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme.spacing.sm,
    marginBottom: theme.spacing.sm,
  },
  step: {
    ...theme.typography.verse.emphasis,
  },
  chevron: {
    marginHorizontal: theme.spacing.xs,
  },
});