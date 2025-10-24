import React, { useEffect, useMemo, useRef } from 'react';
import { observer } from 'mobx-react-lite';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Animated, Easing } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '@/types';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { useJourneyStore } from '@/stores/StoreProvider';
import { ArrowLeft } from '@/components/Icons';

export type JourneyQuizProps = NativeStackScreenProps<RootStackParamList, 'JourneyQuizScreen'>;

function JourneyQuizScreen({ navigation, route }: JourneyQuizProps) {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const journeyStore = useJourneyStore();
  const { phaseId } = route.params;

  useEffect(() => {
    if (journeyStore.quizState.activePhaseId !== phaseId) {
      // Only start if not already active
      journeyStore.startPhaseQuiz(phaseId);
    }
  }, [phaseId]);

  const { questions, currentIndex, isComplete, result, correctCount } = journeyStore.quizState;
  const question = currentIndex < questions.length ? questions[currentIndex] : null;
  const progressPercent = questions.length > 0 ? ((currentIndex + 1) / questions.length) * 100 : 0;

  // Subtle fade/scale when question changes
  const appear = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    appear.setValue(0);
    Animated.timing(appear, {
      toValue: 1,
      duration: 260,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start();
  }, [currentIndex]);
  const animatedStyle = {
    opacity: appear,
    transform: [{ scale: appear.interpolate({ inputRange: [0, 1], outputRange: [0.98, 1] }) }],
  } as const;

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.headerBtn}>
          <ArrowLeft size={22} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Journey Quiz</Text>
        <View style={styles.headerBtn} />
      </View>
      {!isComplete && questions.length > 0 && (
        <View style={styles.progressBarContainer}>
          <View style={[styles.progressBarFill, { width: `${progressPercent}%` }]} />
        </View>
      )}

      {isComplete ? (
        <View style={styles.resultWrap}>
          <Text style={styles.resultTitle}>Phase Complete!</Text>
          <Text style={styles.resultSummary}>
            You've affirmed your readiness for this phase of your spiritual journey.
          </Text>
          <View style={styles.resultActions}>
            <TouchableOpacity style={styles.primary} onPress={() => { journeyStore.resetQuiz(); navigation.goBack(); }}>
              <Text style={styles.primaryText}>Continue</Text>
            </TouchableOpacity>
          </View>
        </View>
      ) : questions.length === 0 ? (
        <View style={styles.resultWrap}>
          <Text style={styles.resultTitle}>Loading questions…</Text>
          <Text style={styles.resultSummary}>If this takes too long, try again.</Text>
          <View style={styles.resultActions}>
            <TouchableOpacity style={styles.primary} onPress={() => journeyStore.startPhaseQuiz(phaseId)}>
              <Text style={styles.primaryText}>Retry</Text>
            </TouchableOpacity>
            <TouchableOpacity style={[styles.primary, { backgroundColor: theme.colors.border }]} onPress={() => navigation.goBack()}>
              <Text style={[styles.primaryText, { color: theme.colors.text.primary }]}>Close</Text>
            </TouchableOpacity>
          </View>
        </View>
      ) : (
        <ScrollView contentContainerStyle={styles.content}>
          <Animated.View style={[styles.card, animatedStyle]}>
            <Text style={styles.progressText}>Question {currentIndex + 1} of {questions.length}</Text>
            <Text style={styles.prompt}>{question?.prompt}</Text>
            <View style={styles.options}>
              {question?.options.map((opt, idx) => (
                <TouchableOpacity key={`${opt}-${idx}`} style={styles.option} activeOpacity={0.85} onPress={() => journeyStore.submitAnswer(idx)}>
                  <Text style={styles.optionText}>{opt}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </Animated.View>
        </ScrollView>
      )}
    </View>
  );
}

const createStyles = (theme: Theme) => StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.background },
  header: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md, paddingVertical: theme.spacing.sm,
    borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: theme.colors.border,
  },
  headerBtn: { width: 36, height: 36, alignItems: 'center', justifyContent: 'center' },
  headerTitle: { ...theme.typography.heading.small, color: theme.colors.text.primary },
  content: { padding: theme.spacing.lg },
  card: {
    gap: theme.spacing.md,
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    shadowColor: '#000',
    shadowOpacity: 0.06,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 2,
  },
  progressBarContainer: {
    height: 4,
    backgroundColor: `${theme.colors.primary}15`,
    width: '100%',
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: theme.colors.primary,
    borderRadius: 2,
  },
  progressText: { ...theme.typography.caption.secondary, color: theme.colors.text.secondary },
  prompt: { ...theme.typography.body.sans, color: theme.colors.text.primary, fontSize: 18, lineHeight: 26 },
  options: { gap: theme.spacing.sm },
  option: {
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: `${theme.colors.surface}`,
  },
  optionText: { ...theme.typography.body.sans, color: theme.colors.text.primary },
  resultWrap: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: theme.spacing.lg, gap: theme.spacing.sm },
  resultTitle: { ...theme.typography.heading.small, color: theme.colors.text.primary, fontWeight: '700' },
  resultSummary: { ...theme.typography.caption.secondary, color: theme.colors.text.secondary, textAlign: 'center' },
  resultActions: { flexDirection: 'row', gap: theme.spacing.sm, marginTop: theme.spacing.md },
  primary: { paddingHorizontal: theme.spacing.lg, paddingVertical: theme.spacing.sm, borderRadius: theme.borderRadius.full, backgroundColor: theme.colors.primary },
  primaryText: { ...theme.typography.caption.primary, color: theme.colors.text.inverse, fontWeight: '600' },
})
;

export default observer(JourneyQuizScreen);
