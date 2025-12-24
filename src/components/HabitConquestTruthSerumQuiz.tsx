import React, { useState, useMemo, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { getViceStrengthMapping } from '@/modules/habitConquestViceStrengthMapping';
import type { HabitVice } from '@/modules/habitConquestCapsules';
import type { TruthSerumQuestion } from '@/modules/habitConquestTruthSerumQuestions';
import { getDynamicQuestions, getAllQuestionsForVice } from '@/modules/habitConquestTruthSerumQuestions';
import { generateSummary } from '@/modules/truthSerumSummaryGenerator';
import { 
  getAttemptNumber, 
  getPreviousAnswers, 
  saveTruthSerumProgress,
  getAllTruthSerumProgress,
  getAverageGrowth
} from '@/services/truthSerumProgressTracker';

interface TruthSerumQuizProps {
  vice: HabitVice | string | null;
  onComplete: (answers: Record<string, number>) => void;
}

export const HabitConquestTruthSerumQuiz: React.FC<TruthSerumQuizProps> = ({ vice, onComplete }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  
  const mapping = useMemo(() => getViceStrengthMapping(vice), [vice]);
  const [questions, setQuestions] = useState<TruthSerumQuestion[]>([]);
  const [attemptNumber, setAttemptNumber] = useState(1);
  const [previousAnswers, setPreviousAnswers] = useState<Record<string, number> | null>(null);
  const [previousAverage, setPreviousAverage] = useState<number | null>(null);
  const [growth, setGrowth] = useState<number>(0);
  const [loading, setLoading] = useState(true);
  
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [answers, setAnswers] = useState<Record<string, number>>({});
  const [showExplanation, setShowExplanation] = useState(false);
  const [showSummary, setShowSummary] = useState(false);
  const [summary, setSummary] = useState<ReturnType<typeof generateSummary> | null>(null);

  useEffect(() => {
    const loadQuizData = async () => {
      if (!vice) {
        setLoading(false);
        return;
      }
      
      try {
        const attempt = await getAttemptNumber(vice);
        const previous = await getPreviousAnswers(vice);
        const allProgress = await getAllTruthSerumProgress(vice);
        
        setAttemptNumber(attempt + 1);
        setPreviousAnswers(previous);
        
        if (allProgress.length > 0) {
          const latest = allProgress[allProgress.length - 1];
          setPreviousAverage(latest.averageScore);
          
          const avgGrowth = await getAverageGrowth(vice, 30);
          setGrowth(avgGrowth);
        }
        
        const dynamicQuestions = getDynamicQuestions(vice, previous, attempt + 1);
        setQuestions(dynamicQuestions);
      } catch (error) {
        console.warn('[TruthSerumQuiz] Failed to load data:', error);
        const fallbackQuestions = getAllQuestionsForVice(vice).slice(0, 5);
        setQuestions(fallbackQuestions);
      } finally {
        setLoading(false);
      }
    };
    
    void loadQuizData();
  }, [vice]);

  if (!mapping || loading || questions.length === 0) {
    return (
      <View style={styles.container}>
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>Preparing your truth serum...</Text>
        </View>
      </View>
    );
  }

  const currentQuestion = questions[currentQuestionIndex];
  const isLastQuestion = currentQuestionIndex === questions.length - 1;
  const canProceed = answers[currentQuestion.id] !== undefined;

  const handleAnswer = (value: number) => {
    setAnswers(prev => ({ ...prev, [currentQuestion.id]: value }));
  };

  const handleNext = async () => {
    if (isLastQuestion) {
      const generatedSummary = generateSummary(vice, questions, answers);
      setSummary(generatedSummary);
      setShowSummary(true);
    } else {
      setCurrentQuestionIndex(prev => prev + 1);
      setShowExplanation(false);
    }
  };

  const handleProceedFromSummary = async () => {
    if (!summary) return;
    const today = new Date().toISOString().slice(0, 10);
    await saveTruthSerumProgress(vice!, today, answers, questions);
    onComplete(answers);
  };

  const handleBack = () => {
    if (currentQuestionIndex > 0) {
      setCurrentQuestionIndex(prev => prev - 1);
      setShowExplanation(false);
    }
  };

  const getPreviousScore = (questionId: string): number | null => {
    return previousAnswers?.[questionId] ?? null;
  };

  const getScoreChange = (questionId: string): number | null => {
    const current = answers[questionId];
    const previous = getPreviousScore(questionId);
    if (current === undefined || previous === null) return null;
    return current - previous;
  };

  if (showSummary && summary) {
    return (
      <ScrollView style={styles.container} contentContainerStyle={styles.content}>
        <View style={styles.header}>
          <Text style={styles.title}>Your Truth Serum Summary</Text>
          <Text style={styles.subtitle}>Based on your answers</Text>
        </View>

        <View style={styles.summaryCard}>
          <View style={styles.scoreSection}>
            <Text style={styles.scoreLabel}>Overall Score</Text>
            <Text style={styles.scoreValue}>{summary.overallScore.toFixed(1)}/10</Text>
          </View>

          {summary.categoryScores && Object.keys(summary.categoryScores).length > 0 && (
            <View style={styles.categorySection}>
              <Text style={styles.sectionTitle}>By Category</Text>
              {Object.entries(summary.categoryScores).map(([category, score]) => (
                <View key={category} style={styles.categoryRow}>
                  <Text style={styles.categoryLabel}>{category.charAt(0).toUpperCase() + category.slice(1)}</Text>
                  <Text style={styles.categoryScore}>{score.toFixed(1)}/10</Text>
                </View>
              ))}
            </View>
          )}

          <View style={styles.insightsSection}>
            <Text style={styles.sectionTitle}>Insights</Text>
            {summary.insights.map((insight, index) => (
              <View key={index} style={styles.insightItem}>
                <Text style={styles.insightText}>• {insight}</Text>
              </View>
            ))}
          </View>

          {summary.strengths.length > 0 && (
            <View style={styles.strengthsSection}>
              <Text style={styles.sectionTitle}>Your Strengths</Text>
              {summary.strengths.map((strength, index) => (
                <View key={index} style={styles.strengthItem}>
                  <Text style={styles.strengthText}>✓ {strength}</Text>
                </View>
              ))}
            </View>
          )}

          <View style={styles.nextStepsSection}>
            <Text style={styles.sectionTitle}>Next Steps</Text>
            {summary.nextSteps.map((step, index) => (
              <View key={index} style={styles.stepItem}>
                <Text style={styles.stepText}>{index + 1}. {step}</Text>
              </View>
            ))}
          </View>

          <View style={styles.encouragementSection}>
            <Text style={styles.encouragementText}>{summary.encouragement}</Text>
          </View>
        </View>

        <TouchableOpacity
          style={styles.proceedButton}
          onPress={handleProceedFromSummary}
        >
          <Text style={styles.proceedButtonText}>Continue to Session</Text>
        </TouchableOpacity>
      </ScrollView>
    );
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={styles.title}>Truth Serum</Text>
        <Text style={styles.subtitle}>
          {attemptNumber === 1 
            ? 'Understanding Your Vice & Strengths' 
            : `Session ${attemptNumber} • Track Your Growth`}
        </Text>
        {previousAverage !== null && (
          <View style={styles.growthBadge}>
            <Text style={styles.growthText}>
              {growth > 0 ? `↑ +${growth.toFixed(1)}` : growth < 0 ? `↓ ${growth.toFixed(1)}` : '→ 0.0'} 
              {' '}avg growth (30 days)
            </Text>
          </View>
        )}
      </View>

      <View style={styles.progressBar}>
        <View style={[styles.progressFill, { width: `${((currentQuestionIndex + 1) / questions.length) * 100}%` }]} />
      </View>

      <View style={styles.questionCard}>
        <View style={styles.questionHeader}>
          <Text style={styles.questionNumber}>Question {currentQuestionIndex + 1} of {questions.length}</Text>
          <Text style={styles.questionCategory}>{currentQuestion.category.toUpperCase()}</Text>
        </View>
        <Text style={styles.questionText}>{currentQuestion.question}</Text>

        <View style={styles.scaleLabels}>
          <Text style={styles.scaleLabel}>{currentQuestion.scaleLabel.min}</Text>
          <Text style={styles.scaleLabel}>{currentQuestion.scaleLabel.max}</Text>
        </View>

        <View style={styles.scaleContainer}>
          {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(value => {
            const isSelected = answers[currentQuestion.id] === value;
            const previousScore = getPreviousScore(currentQuestion.id);
            const hasPrevious = previousScore !== null;
            const isImproved = hasPrevious && value > previousScore;
            const isDeclined = hasPrevious && value < previousScore;
            
            return (
              <TouchableOpacity
                key={value}
                style={[
                  styles.scaleButton,
                  isSelected && styles.scaleButtonSelected,
                  hasPrevious && value === previousScore && styles.scaleButtonPrevious,
                ]}
                onPress={() => handleAnswer(value)}
              >
                <Text style={[
                  styles.scaleButtonText,
                  isSelected && styles.scaleButtonTextSelected,
                  hasPrevious && value === previousScore && styles.scaleButtonTextPrevious,
                ]}>
                  {value}
                </Text>
                {hasPrevious && value === previousScore && (
                  <View style={styles.previousIndicator} />
                )}
              </TouchableOpacity>
            );
          })}
        </View>

        {answers[currentQuestion.id] !== undefined && (
          <View style={styles.scoreInfo}>
            <Text style={styles.scoreText}>
              Your answer: <Text style={styles.scoreValue}>{answers[currentQuestion.id]}/10</Text>
            </Text>
            {getPreviousScore(currentQuestion.id) !== null && (
              <Text style={styles.comparisonText}>
                Previous: {getPreviousScore(currentQuestion.id)}/10
                {getScoreChange(currentQuestion.id) !== null && (
                  <Text style={[
                    styles.changeText,
                    (getScoreChange(currentQuestion.id) ?? 0) > 0 ? styles.changeTextPositive : 
                    (getScoreChange(currentQuestion.id) ?? 0) < 0 ? styles.changeTextNegative : null
                  ]}>
                    {' '}({(getScoreChange(currentQuestion.id) ?? 0) > 0 ? '+' : ''}{getScoreChange(currentQuestion.id)})
                  </Text>
                )}
              </Text>
            )}
          </View>
        )}

        {canProceed && (
          <TouchableOpacity
            style={styles.explanationButton}
            onPress={() => setShowExplanation(!showExplanation)}
          >
            <Text style={styles.explanationButtonText}>
              {showExplanation ? 'Hide' : 'Show'} Insight
            </Text>
          </TouchableOpacity>
        )}

        {showExplanation && canProceed && currentQuestion.insight && (
          <View style={styles.explanationCard}>
            <Text style={styles.explanationTitle}>Insight</Text>
            <Text style={styles.explanationText}>{currentQuestion.insight}</Text>
            {currentQuestion.relatedStrength && (
              <Text style={styles.explanationText}>
                <Text style={styles.bold}>Related Strength:</Text> {currentQuestion.relatedStrength}
              </Text>
            )}
          </View>
        )}
      </View>

      <View style={styles.actions}>
        {currentQuestionIndex > 0 && (
          <TouchableOpacity style={styles.backButton} onPress={handleBack}>
            <Text style={styles.backButtonText}>Back</Text>
          </TouchableOpacity>
        )}
        <TouchableOpacity
          style={[styles.nextButton, !canProceed && styles.nextButtonDisabled]}
          onPress={handleNext}
          disabled={!canProceed}
        >
          <Text style={[styles.nextButtonText, !canProceed && styles.nextButtonTextDisabled]}>
            {isLastQuestion ? 'Complete' : 'Next'}
          </Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const createStyles = (theme: ReturnType<typeof useTheme>) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  content: {
    padding: 16,
    gap: 16,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 40,
  },
  loadingText: {
    fontSize: 16,
    color: theme.colors.text.secondary,
  },
  header: {
    marginBottom: 8,
  },
  title: {
    fontSize: 24,
    fontWeight: '800',
    color: theme.colors.text.primary,
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 14,
    color: theme.colors.text.secondary,
    marginBottom: 8,
  },
  growthBadge: {
    alignSelf: 'flex-start',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
    backgroundColor: theme.colors.surface,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: theme.colors.border,
  },
  growthText: {
    fontSize: 12,
    fontWeight: '600',
    color: theme.colors.text.secondary,
  },
  progressBar: {
    height: 4,
    backgroundColor: theme.colors.surface,
    borderRadius: 2,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: theme.colors.primary,
  },
  questionCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: 16,
    padding: 20,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: theme.colors.border,
    gap: 16,
  },
  questionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  questionNumber: {
    fontSize: 12,
    fontWeight: '600',
    color: theme.colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  questionCategory: {
    fontSize: 10,
    fontWeight: '700',
    color: theme.colors.primary,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  questionText: {
    fontSize: 18,
    fontWeight: '600',
    color: theme.colors.text.primary,
    lineHeight: 26,
  },
  scaleLabels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 8,
  },
  scaleLabel: {
    fontSize: 11,
    color: theme.colors.text.secondary,
    fontWeight: '500',
  },
  scaleContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 4,
    marginTop: 8,
  },
  scaleButton: {
    flex: 1,
    aspectRatio: 1,
    borderRadius: 8,
    backgroundColor: theme.colors.background,
    borderWidth: 2,
    borderColor: theme.colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    minWidth: 32,
  },
  scaleButtonSelected: {
    backgroundColor: `${(theme as any).colors.primary}20`,
    borderColor: theme.colors.primary,
  },
  scaleButtonPrevious: {
    borderColor: theme.colors.text.secondary,
    borderStyle: 'dashed',
  },
  scaleButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: theme.colors.text.secondary,
  },
  scaleButtonTextSelected: {
    color: theme.colors.primary,
    fontWeight: '700',
  },
  scaleButtonTextPrevious: {
    color: theme.colors.text.secondary,
  },
  previousIndicator: {
    position: 'absolute',
    bottom: 2,
    width: 4,
    height: 4,
    borderRadius: 2,
    backgroundColor: theme.colors.text.secondary,
  },
  scoreInfo: {
    marginTop: 12,
    padding: 12,
    backgroundColor: theme.colors.background,
    borderRadius: 8,
    gap: 4,
  },
  scoreText: {
    fontSize: 14,
    color: theme.colors.text.secondary,
  },
  scoreValue: {
    fontWeight: '700',
    color: theme.colors.primary,
  },
  comparisonText: {
    fontSize: 12,
    color: theme.colors.text.secondary,
  },
  changeText: {
    fontWeight: '600',
  },
  changeTextPositive: {
    color: '#4CAF50',
  },
  changeTextNegative: {
    color: '#F44336',
  },
  explanationButton: {
    marginTop: 8,
    paddingVertical: 10,
    alignItems: 'center',
  },
  explanationButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: theme.colors.primary,
  },
  explanationCard: {
    marginTop: 12,
    padding: 16,
    backgroundColor: theme.colors.background,
    borderRadius: 12,
    borderLeftWidth: 3,
    borderLeftColor: theme.colors.primary,
    gap: 12,
  },
  explanationTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: theme.colors.text.primary,
    marginBottom: 4,
  },
  explanationText: {
    fontSize: 14,
    lineHeight: 20,
    color: theme.colors.text.secondary,
  },
  bold: {
    fontWeight: '600',
    color: theme.colors.text.primary,
  },
  actions: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 8,
  },
  backButton: {
    flex: 1,
    paddingVertical: 14,
    borderRadius: 12,
    backgroundColor: theme.colors.surface,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: theme.colors.border,
    alignItems: 'center',
  },
  backButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: theme.colors.text.primary,
  },
  nextButton: {
    flex: 2,
    paddingVertical: 14,
    borderRadius: 12,
    backgroundColor: theme.colors.primary,
    alignItems: 'center',
  },
  nextButtonDisabled: {
    backgroundColor: theme.colors.surface,
    opacity: 0.5,
  },
  nextButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: theme.colors.text.inverse,
  },
  nextButtonTextDisabled: {
    color: theme.colors.text.secondary,
  },
  summaryCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: 16,
    padding: 20,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: theme.colors.border,
    gap: 20,
  },
  scoreSection: {
    alignItems: 'center',
    paddingVertical: 16,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: theme.colors.border,
  },
  scoreLabel: {
    fontSize: 14,
    color: theme.colors.text.secondary,
    marginBottom: 8,
  },
  scoreValue: {
    fontSize: 36,
    fontWeight: '800',
    color: theme.colors.primary,
  },
  categorySection: {
    gap: 12,
  },
  categoryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
  },
  categoryLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: theme.colors.text.primary,
  },
  categoryScore: {
    fontSize: 14,
    fontWeight: '600',
    color: theme.colors.text.secondary,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: theme.colors.text.primary,
    marginBottom: 8,
  },
  insightsSection: {
    gap: 8,
  },
  insightItem: {
    paddingLeft: 8,
  },
  insightText: {
    fontSize: 14,
    lineHeight: 20,
    color: theme.colors.text.secondary,
  },
  strengthsSection: {
    gap: 8,
    padding: 12,
    backgroundColor: `${(theme as any).colors.primary}10`,
    borderRadius: 8,
  },
  strengthItem: {
    paddingLeft: 8,
  },
  strengthText: {
    fontSize: 14,
    lineHeight: 20,
    color: theme.colors.text.primary,
    fontWeight: '500',
  },
  nextStepsSection: {
    gap: 8,
  },
  stepItem: {
    paddingLeft: 8,
  },
  stepText: {
    fontSize: 14,
    lineHeight: 20,
    color: theme.colors.text.secondary,
  },
  encouragementSection: {
    padding: 16,
    backgroundColor: theme.colors.background,
    borderRadius: 12,
    borderLeftWidth: 3,
    borderLeftColor: theme.colors.primary,
  },
  encouragementText: {
    fontSize: 15,
    lineHeight: 22,
    color: theme.colors.text.primary,
    fontWeight: '600',
    fontStyle: 'italic',
  },
  proceedButton: {
    marginTop: 8,
    paddingVertical: 16,
    borderRadius: 12,
    backgroundColor: theme.colors.primary,
    alignItems: 'center',
  },
  proceedButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: theme.colors.text.inverse,
  },
});
