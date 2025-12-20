import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
} from 'react-native';
import Animated, { FadeInDown } from 'react-native-reanimated';
import { Brain, ChevronRight, Sparkle, Lightbulb, BookOpen } from '@/components/Icons';
import { useTheme } from '@/contexts/ThemeContext';

type Props = {
  onNext: () => void;
};

const WelcomeStep: React.FC<Props> = ({ onNext }) => {
  const theme = useTheme();
  const styles = createStyles(theme);

  return (
    <View style={styles.contentContainer}>
      <Animated.View entering={FadeInDown.duration(600)}>
        <View style={styles.headerSection}>
          <Brain size={48} color={theme.colors.primary} style={styles.headerIcon} />
          <Text style={styles.mainTitle}>Discover Your Spiritual Career</Text>
          <Text style={styles.subtitle}>
            Find how your unique gifts and work fit into God's Kingdom story through this guided journey
          </Text>
        </View>

        <View style={styles.featureList}>
          <View style={styles.featureItem}>
            <Sparkle size={20} color={theme.colors.primary} />
            <Text style={styles.featureText}>Identify your spiritual archetypes</Text>
          </View>
          <View style={styles.featureItem}>
            <Lightbulb size={20} color={theme.colors.primary} />
            <Text style={styles.featureText}>Discover your calling context</Text>
          </View>
          <View style={styles.featureItem}>
            <BookOpen size={20} color={theme.colors.primary} />
            <Text style={styles.featureText}>Get personalized challenge recommendations</Text>
          </View>
        </View>

        <TouchableOpacity 
          style={styles.primaryButton}
          onPress={onNext}
        >
          <Text style={styles.primaryButtonText}>Begin Your Journey</Text>
          <ChevronRight size={20} color="#fff" />
        </TouchableOpacity>
      </Animated.View>
    </View>
  );
};

const createStyles = (theme: any) => StyleSheet.create({
  contentContainer: {
    flex: 1,
    padding: 20,
  },
  headerSection: {
    alignItems: 'center',
    marginBottom: 32,
  },
  headerIcon: {
    marginBottom: 16,
  },
  mainTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: theme.colors.text,
    textAlign: 'center',
    marginBottom: 12,
  },
  subtitle: {
    fontSize: 16,
    color: theme.colors.textSecondary,
    textAlign: 'center',
    lineHeight: 24,
  },
  featureList: {
    marginBottom: 32,
  },
  featureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
    padding: 16,
    backgroundColor: `${theme.colors.primary}10`,
    borderRadius: 12,
  },
  featureText: {
    flex: 1,
    fontSize: 16,
    color: theme.colors.text,
    marginLeft: 12,
  },
  primaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.primary,
    padding: 16,
    borderRadius: 12,
    marginBottom: 16,
  },
  primaryButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    marginRight: 8,
  },
});

export default WelcomeStep;
