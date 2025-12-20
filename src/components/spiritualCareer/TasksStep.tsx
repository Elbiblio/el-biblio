import React from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { Star, ChevronRight } from '@/components/Icons';
import { useTheme } from '@/contexts/ThemeContext';
import type { CareerGuideState } from '@/screens/SpiritualCareerGuideScreen';
import type { Challenge } from '@/types/challenges';

type Props = {
  state: CareerGuideState;
  onBack: () => void;
  onComplete: () => void;
};

const TasksStep: React.FC<Props> = ({ state, onBack, onComplete }) => {
  const theme = useTheme();
  const styles = createStyles(theme);

  return (
    <View style={styles.contentContainer}>
      <Text style={styles.sectionTitle}>Your Spiritual Career Tasks</Text>
      <Text style={styles.sectionSubtitle}>Personalized challenges based on your archetypes and context</Text>

      {state.isLoading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={theme.colors.primary} />
          <Text style={styles.loadingText}>Finding your perfect challenges...</Text>
        </View>
      ) : (
        <ScrollView showsVerticalScrollIndicator={false} style={styles.tasksContainer}>
          {state.suggestedChallenges.map((challenge: Challenge) => (
            <TouchableOpacity key={challenge.id} style={styles.taskCard}>
              <View style={styles.taskHeader}>
                <Text style={styles.taskTitle}>{challenge.title}</Text>
                <Star size={16} color={theme.colors.primary} />
              </View>
              <Text style={styles.taskDescription} numberOfLines={2}>
                {challenge.description}
              </Text>
              <View style={styles.taskFooter}>
                <Text style={styles.taskCategory}>{challenge.category}</Text>
                <ChevronRight size={16} color={theme.colors.primary} />
              </View>
            </TouchableOpacity>
          ))}
        </ScrollView>
      )}

      <View style={styles.buttonRow}>
        <TouchableOpacity 
          style={[styles.secondaryButton, { flex: 1 }]}
          onPress={onBack}
        >
          <Text style={styles.secondaryButtonText}>Back</Text>
        </TouchableOpacity>
        
        <TouchableOpacity 
          style={[styles.primaryButton, { flex: 2 }]}
          onPress={onComplete}
        >
          <Text style={styles.primaryButtonText}>Complete Guide</Text>
          <ChevronRight size={20} color="#fff" />
        </TouchableOpacity>
      </View>
    </View>
  );
};

const createStyles = (theme: any) => StyleSheet.create({
  contentContainer: {
    flex: 1,
    padding: 20,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: theme.colors.text,
    textAlign: 'center',
    marginBottom: 8,
  },
  sectionSubtitle: {
    fontSize: 16,
    color: theme.colors.textSecondary,
    textAlign: 'center',
    marginBottom: 32,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 40,
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: theme.colors.textSecondary,
  },
  tasksContainer: {
    flex: 1,
    marginBottom: 24,
  },
  taskCard: {
    backgroundColor: theme.colors.surface,
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}20`,
  },
  taskHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  taskTitle: {
    flex: 1,
    fontSize: 16,
    fontWeight: '600',
    color: theme.colors.text,
    marginRight: 8,
  },
  taskDescription: {
    fontSize: 14,
    color: theme.colors.textSecondary,
    lineHeight: 20,
    marginBottom: 12,
  },
  taskFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  taskCategory: {
    fontSize: 12,
    color: theme.colors.textSecondary,
    fontStyle: 'italic',
  },
  buttonRow: {
    flexDirection: 'row',
    marginTop: 24,
  },
  primaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.primary,
    padding: 16,
    borderRadius: 12,
    marginLeft: 8,
  },
  primaryButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    marginRight: 8,
  },
  secondaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: theme.colors.primary,
    padding: 16,
    borderRadius: 12,
  },
  secondaryButtonText: {
    color: theme.colors.primary,
    fontSize: 16,
    fontWeight: '600',
  },
});

export default TasksStep;
