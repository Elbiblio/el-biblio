import React, { useMemo } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, FlatList, ActivityIndicator } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { useJourneyStore } from '@/stores/StoreProvider';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RootStackParamList, Activity as JourneyActivity } from '@/types';
import { ArrowLeft, Check, Lock, User } from '@/components/Icons';

const QUESTIONS_PER_ROW = 2;

const MyJourneyScreen = observer(() => {
  const insets = useSafeAreaInsets();
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const journeyStore = useJourneyStore();
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();

  React.useEffect(() => {
    journeyStore.fetchActivities();
  }, [journeyStore]);

  const activeQuizQuestion = journeyStore.quizState.questions[journeyStore.quizState.currentIndex];
  const activities = Array.isArray(journeyStore.activities) ? journeyStore.activities : [];

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}> 
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>My Journey</Text>
        <TouchableOpacity
          onPress={() => navigation.navigate('ProfileScreen')}
          style={styles.profileButton}
          accessibilityLabel="View profile"
        >
          <User size={22} color={theme.colors.text.primary} />
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.hero}>
          <Text style={styles.heroTitle}>Grow intentionally</Text>
          <Text style={styles.heroSubtitle}>Progress through each phase, complete quizzes to unlock more of the community.</Text>
        </View>

        <Text style={styles.sectionTitle}>Phases</Text>
        <View style={styles.phasesGrid}>
          {journeyStore.journeyPhases.map(phase => {
            const status = phase.status;
            const isActive = journeyStore.quizState.activePhaseId === phase.id && !journeyStore.quizState.isComplete;
            const isCompleted = status === 'completed';
            const isLocked = status === 'locked';
            return (
              <View key={phase.id} style={[styles.phaseCard, isActive && styles.phaseCardActive, isLocked && styles.phaseCardLocked]}>
                <View style={styles.phaseHeader}>
                  <Text style={styles.phaseNumber}>Phase {phase.order}</Text>
                  {isCompleted ? (
                    <Check size={18} color={theme.colors.success} />
                  ) : (
                    isLocked ? <Lock size={18} color={theme.colors.text.secondary} /> : null
                  )}
                </View>
                <Text style={styles.phaseTitle}>{phase.title}</Text>
                <Text style={styles.phaseSummary}>{phase.summary}</Text>
                <TouchableOpacity
                  style={[styles.phaseAction, (isLocked || isActive) && styles.phaseActionDisabled]}
                  disabled={isLocked || isActive}
                  onPress={() => journeyStore.startPhaseQuiz(phase.id)}
                >
                  <Text style={[styles.phaseActionText, (isLocked || isActive) && styles.phaseActionTextDisabled]}>
                    {isLocked ? 'Locked' : isCompleted ? 'Retake Quiz' : 'Start Quiz'}
                  </Text>
                </TouchableOpacity>
              </View>
            );
          })}
        </View>

        {journeyStore.quizState.activePhaseId && !journeyStore.quizState.isComplete && activeQuizQuestion && (
          <View style={styles.quizCard}>
            <Text style={styles.quizTitle}>Quiz: {journeyStore.currentPhase?.title}</Text>
            <Text style={styles.quizProgress}>
              Question {journeyStore.quizState.currentIndex + 1} of {journeyStore.quizState.questions.length}
            </Text>
            <Text style={styles.quizPrompt}>{activeQuizQuestion.prompt}</Text>
            <View style={styles.quizOptions}>
              {activeQuizQuestion.options.map((option, index) => (
                <TouchableOpacity
                  key={option}
                  style={styles.quizOption}
                  onPress={() => journeyStore.submitAnswer(index)}
                >
                  <Text style={styles.quizOptionText}>{option}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        )}

        {journeyStore.quizState.isComplete && (
          <View style={styles.quizResultCard}>
            <Text style={styles.quizResultTitle}>
              {journeyStore.quizState.result === 'pass' ? 'Great job!' : 'Keep going'}
            </Text>
            <Text style={styles.quizResultSummary}>
              You answered {journeyStore.quizState.correctCount} of {journeyStore.quizState.questions.length} questions correctly.
            </Text>
            <View style={styles.quizResultActions}>
              <TouchableOpacity style={styles.resultPrimary} onPress={() => journeyStore.resetQuiz()}>
                <Text style={styles.resultPrimaryText}>Close Quiz</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        <Text style={styles.sectionTitle}>Your activity</Text>
        {journeyStore.isActivitiesLoading ? (
          <View style={styles.loadingRow}>
            <ActivityIndicator color={theme.colors.primary} />
            <Text style={styles.loadingText}>Loading recent activity...</Text>
          </View>
        ) : activities.length === 0 ? (
          <View style={styles.emptyActivity}>
            <Text style={styles.emptyActivityText}>Activity will appear here as you engage.</Text>
          </View>
        ) : (
          <FlatList
            data={activities}
            keyExtractor={item => item.id}
            scrollEnabled={false}
            contentContainerStyle={styles.activityList}
            renderItem={({ item }) => (
              <View style={styles.activityItem}>
                <View style={styles.activityDot} />
                <View style={styles.activityContent}>
                  <Text style={styles.activityTitle}>{formatActivityTitle(item)}</Text>
                  <Text style={styles.activityMeta}>{formatRelativeDate(item.created_at)}</Text>
                </View>
              </View>
            )}
          />
        )}
      </ScrollView>
    </View>
  );
});

const formatActivityTitle = (activity: JourneyActivity): string => {
  if (!activity) return 'Activity';
  const typeText = activity.type ? String(activity.type) : 'Activity';
  const subject = activity.metadata?.title || activity.subject_type || '';
  return subject ? `${typeText}: ${subject}` : typeText;
};

const formatRelativeDate = (iso: string): string => {
  if (!iso) return '';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '';
  const now = Date.now();
  const diff = now - date.getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return 'Just now';
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} hr${hours > 1 ? 's' : ''} ago`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days} day${days > 1 ? 's' : ''} ago`;
  return date.toLocaleDateString();
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  profileButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  title: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  content: {
    paddingHorizontal: theme.spacing.md,
    paddingBottom: theme.spacing.xxl,
    gap: theme.spacing.lg,
  },
  hero: {
    backgroundColor: `${theme.colors.primary}10`,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    gap: theme.spacing.sm,
  },
  heroTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    fontWeight: '700',
  },
  heroSubtitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  sectionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginTop: theme.spacing.sm,
  },
  phasesGrid: {
    gap: theme.spacing.md,
  },
  phaseCard: {
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.surface,
    padding: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  phaseCardActive: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}08`,
  },
  phaseCardLocked: {
    opacity: 0.6,
  },
  phaseHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  phaseNumber: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },
  phaseTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  phaseSummary: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  phaseAction: {
    alignSelf: 'flex-start',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.primary,
  },
  phaseActionDisabled: {
    backgroundColor: theme.colors.border,
  },
  phaseActionText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  phaseActionTextDisabled: {
    color: theme.colors.text.secondary,
  },
  quizCard: {
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}30`,
    backgroundColor: `${theme.colors.primary}08`,
    padding: theme.spacing.lg,
    gap: theme.spacing.md,
  },
  quizTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.primary,
    fontWeight: '700',
  },
  quizProgress: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  quizPrompt: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  quizOptions: {
    flexDirection: 'column',
    gap: theme.spacing.sm,
  },
  quizOption: {
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.surface,
  },
  quizOptionText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  quizResultCard: {
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.surface,
    padding: theme.spacing.lg,
    gap: theme.spacing.sm,
  },
  quizResultTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    fontWeight: '700',
  },
  quizResultSummary: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  quizResultActions: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
  },
  resultPrimary: {
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.primary,
  },
  resultPrimaryText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  loadingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  loadingText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  emptyActivity: {
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: theme.spacing.lg,
    alignItems: 'center',
  },
  emptyActivityText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  activityList: {
    gap: theme.spacing.sm,
  },
  activityItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
  },
  activityDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: theme.colors.primary,
    marginTop: theme.spacing.xs,
  },
  activityContent: {
    flex: 1,
    gap: theme.spacing.xs,
  },
  activityTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  activityMeta: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
});

export default MyJourneyScreen;
