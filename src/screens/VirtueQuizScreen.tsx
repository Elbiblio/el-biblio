import React, { useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Platform,
  ActivityIndicator,
  Alert
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import {
  ArrowLeft,
  Check,
  X,
  Star,
  Lightning,
  CaretRight,
  CaretLeft,
  Trophy,
  BookOpen,
  Question,
  Lock,
  Heart,
  Lightbulb,
  Clock
} from '../components/Icons';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  useAnimatedProps,
  withTiming,
  withSequence,
  withSpring,
  interpolate,
  Extrapolation,
  runOnJS
} from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';
import { useTheme } from '@/contexts/ThemeContext';
import { useVirtueQuizStore } from '@/stores/StoreProvider';
import { observer } from 'mobx-react-lite';
import { Theme } from '@/theme';
import { PIConfetti, ConfettiMethods } from 'react-native-fast-confetti';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList, AppVirtue, FoundationalVirtue, Virtue } from '@/types';
import { THEMES } from '@/types';

// Removed SCREEN_WIDTH; not needed after confetti migration

// Helper function to map Virtue to AppVirtue
const mapVirtueToAppVirtue = (virtue: Virtue): AppVirtue => {
  const theme = THEMES[virtue.name?.toLowerCase() as FoundationalVirtue] || THEMES[virtue.id?.toLowerCase() as FoundationalVirtue];
  return {
    ...virtue,
    icon: theme?.Icon || Star,
    color_code: virtue.color_code || theme?.color || '#9C27B0',
  };
};

type QuizQuestion = {
  id: string;
  question: string;
  type: 'true_false' | 'multiple_choice';
  options?: string[];
  correctAnswer: string | number;
  explanation: string;
  verseReference?: string;
  virtue: string;
  level: number;
};

const VirtueQuizScreen = observer(({ navigation, route }: NativeStackScreenProps<RootStackParamList, 'VirtueQuizScreen'>) => {
  const insets = useSafeAreaInsets();
  const theme = useTheme();
  const store = useVirtueQuizStore();
  const styles = createStyles(theme, store.selectedVirtue);

  const confettiRef = useRef<any>(null);
  const confettiInlineRef = useRef<any>(null);

  // Animation values
  const cardScale = useSharedValue(0.95);
  const optionScale = useSharedValue(1);
  const optionPressScale = useSharedValue(1);
  const progressWidth = useSharedValue(0);
  const explanationHeight = useSharedValue(0);

  const { 
    selectedVirtue,
    selectedLevel,
    questions,
    currentQuestionIndex,
    score,
    quizCompleted,
    quizStarted,
    isQuizLoading,
    quizError,
    showConfetti,
    virtues,
    virtueProgress,
    selectedAnswer,
    isAnswerCorrect,
    showExplanation,
  } = store;

  // Effects
  useEffect(() => {
    store.loadInitialData();
  }, [store]);

  // If navigated with params, auto-select virtue and level and start quiz
  useEffect(() => {
    const virtueId = (route?.params as any)?.virtueId as string | undefined;
    const level = (route?.params as any)?.level as number | undefined;
    if (!virtueId || !level) return;

    // Wait until virtues are loaded and quiz not started yet
    if (store.quizStarted) return;
    if (!store.virtues || store.virtues.length === 0) return;

    const v = store.virtues.find(v => v.id === virtueId);
    if (!v) return;
    const app = mapVirtueToAppVirtue(v);
    store.selectVirtue(app);
    store.selectLevel(level);
    store.startQuiz();
  }, [route?.params, store.virtues, store.quizStarted]);

  useEffect(() => {
    if (quizStarted) {
      cardScale.value = withSpring(1);
    } else {
      cardScale.value = withTiming(0.95);
    }
  }, [quizStarted, cardScale]);

  useEffect(() => {
    if (showExplanation) {
      explanationHeight.value = withTiming(1);
    } else {
      explanationHeight.value = withTiming(0);
    }
  }, [showExplanation, explanationHeight]);

  useEffect(() => {
    if (quizStarted && questions.length > 0) {
      progressWidth.value = withTiming(((currentQuestionIndex + 1) / questions.length) * 100);
    } else {
      progressWidth.value = withTiming(0);
    }
  }, [currentQuestionIndex, questions.length, quizStarted, progressWidth]);

  useEffect(() => {
    if (showConfetti) {
      confettiRef.current?.restart();
      // The confetti is triggered by the store, and this effect just starts it.
      // The store should be responsible for turning it off if needed.
    }
  }, [showConfetti]);

  // Animated Styles
  const cardAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: cardScale.value }],
    opacity: cardScale.value
  }));


  const progressAnimatedStyle = useAnimatedStyle(() => ({
    width: `${progressWidth.value}%`
  }));
  
  const explanationAnimatedStyle = useAnimatedStyle(() => ({
    opacity: explanationHeight.value,
    transform: [{ translateY: interpolate(
      explanationHeight.value,
      [0, 1],
      [20, 0],
      Extrapolation.CLAMP
    )}]
  }));
  
  // Option press micro-scale
  const optionPressStyle = useAnimatedStyle(() => ({
    transform: [{ scale: optionPressScale.value }],
  }));

  // Haptics on explanation reveal
  useEffect(() => {
    if (showExplanation && selectedAnswer !== null) {
      Haptics.impactAsync(
        isAnswerCorrect ? Haptics.ImpactFeedbackStyle.Light : Haptics.ImpactFeedbackStyle.Medium
      );
      if (isAnswerCorrect) {
        confettiInlineRef.current?.restart?.();
      }
    }
  }, [showExplanation, selectedAnswer, isAnswerCorrect]);
  
  // Render functions
  const renderVirtueSelection = () => (
    <View style={styles.selectionContainer}>
      <Text style={styles.selectionTitle}>Select a Virtue</Text>
      <ScrollView 
        horizontal 
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.virtuesScrollContent}
      >
        {virtues.map((virtue: Virtue) => {
          const appVirtue = mapVirtueToAppVirtue(virtue);
          return (
            <TouchableOpacity
              key={virtue.id}
              style={[
                styles.virtueCard,
                selectedVirtue?.id === virtue.id && styles.selectedVirtueCard,
                { borderColor: appVirtue.color_code }
              ]}
              onPress={() => store.selectVirtue(appVirtue)}
            >
              <LinearGradient
                colors={[
                  selectedVirtue?.id === virtue.id 
                    ? `${appVirtue.color_code}20` 
                    : '#00000010',
                  selectedVirtue?.id === virtue.id 
                    ? `${appVirtue.color_code}05` 
                    : '#00000005'
                ]}
                style={styles.virtueGradient}
              />
              
              <View style={styles.virtueIconContainer}>
                <appVirtue.icon size={24} color={appVirtue.color_code} />
              </View>
              
              <Text style={styles.virtueName}>{appVirtue.name}</Text>
              <Text style={styles.virtueDescription}>{appVirtue.description}</Text>
              
              <View style={styles.progressContainer}>
                <View style={styles.progressBar}>
                  <View 
                    style={[
                      styles.progressFill, 
                      { 
                        width: `${((virtueProgress[virtue.id]?.current_level || 0) / 3) * 100}%`,
                        backgroundColor: appVirtue.color_code 
                      }
                    ]} 
                  />
                </View>
                <Text style={styles.progressText}>
                  Level {virtueProgress[virtue.id]?.current_level || 0}/3
                </Text>
              </View>
            </TouchableOpacity>
          );
        })}
      </ScrollView>
    </View>
  );
  
  const renderLevelSelection = () => {
    if (!selectedVirtue) return null;
    
    return (
      <Animated.View style={[styles.selectionContainer, cardAnimatedStyle]}>
        <Text style={styles.selectionTitle}>Select Difficulty Level</Text>
        <View style={styles.levelsContainer}>
          {Array.from({ length: 3 }, (_, i) => i + 1).map(level => (
            <TouchableOpacity
              key={`level-${level}`}
              style={[
                styles.levelCard,
                selectedLevel === level && styles.selectedLevelCard,
                level > (virtueProgress[selectedVirtue.id]?.current_level || 0) + 1 && styles.lockedLevelCard
              ]}
              disabled={level > (virtueProgress[selectedVirtue.id]?.current_level || 0) + 1}
              onPress={() => {
                store.selectLevel(level);
                optionScale.value = withSequence(
                  withTiming(0.95, { duration: 100 }),
                  withTiming(1, { duration: 200 })
                );
              }}
            >
              <LinearGradient
                colors={[
                  level <= (virtueProgress[selectedVirtue.id]?.current_level || 0) + 1 
                    ? `${selectedVirtue.color_code}20` 
                    : '#00000010',
                  level <= (virtueProgress[selectedVirtue.id]?.current_level || 0) + 1 
                    ? `${selectedVirtue.color_code}05` 
                    : '#00000005'
                ]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.levelGradient}
              />
              {level > (virtueProgress[selectedVirtue.id]?.current_level || 0) + 1 ? (
                <View style={styles.lockedIconContainer}>
                  <Lock size={20} color={theme?.colors.text.secondary} />
                </View>
              ) : (
                <Text style={styles.levelNumber}>{level}</Text>
              )}
              <Text style={[
                styles.levelLabel,
                level > (virtueProgress[selectedVirtue.id]?.current_level || 0) + 1 && styles.lockedLevelLabel
              ]}>
                {level === 1 ? 'Beginner' : level === 2 ? 'Intermediate' : 'Advanced'}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
        
        <TouchableOpacity
          style={[
            styles.startButton,
            { backgroundColor: selectedVirtue?.color_code }
          ]}
          onPress={() => store.startQuiz()}
        >
          <Lightning size={20} color="#FFF" />
          <Text style={styles.startButtonText}>Start Quiz</Text>
        </TouchableOpacity>
      </Animated.View>
    );
  };
  
  const renderQuizQuestion = () => {
    if (!quizStarted || questions.length === 0) return null;
    if (quizCompleted) return renderQuizResults();
    
    const currentQuestion = questions[currentQuestionIndex] as QuizQuestion;
    
    return (
      <View style={styles.quizContainer}>
        <View style={styles.progressBarContainer}>
          <Animated.View 
            style={[
              styles.progressBarFill, progressAnimatedStyle
            ]} 
          />
        </View>
        
        <Text style={styles.questionCounter}>
          Question {currentQuestionIndex + 1} of {questions.length}
        </Text>
        
        <Animated.View style={[styles.questionCard, cardAnimatedStyle]}>
          <LinearGradient
            colors={[`${selectedVirtue?.color_code}10`, `${selectedVirtue?.color_code}02`]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.questionGradient}
          />
          
          <Text style={styles.questionText}>{currentQuestion.question}</Text>
          
          {currentQuestion.verseReference && (
            <View style={styles.scriptureContainer}>
              <BookOpen size={16} color={theme?.colors.text.secondary} />
              <Text style={styles.scriptureText}>
                {currentQuestion.verseReference}
              </Text>
            </View>
          )}
          
          <View style={styles.optionsContainer}>
            {currentQuestion.type === 'true_false' ? (
              <>
                <Animated.View style={optionPressStyle}>
                  <TouchableOpacity
                  style={[
                    styles.optionButton,
                    selectedAnswer === 'true' && styles.selectedOptionButton,
                    selectedAnswer !== null && 'true' === String(currentQuestion.correctAnswer) && styles.correctOptionButton,
                    selectedAnswer === 'true' && selectedAnswer !== String(currentQuestion.correctAnswer) && styles.incorrectOptionButton,
                  ]}
                  onPress={() => {
                    optionPressScale.value = withSequence(
                      withTiming(0.97, { duration: 80 }),
                      withTiming(1, { duration: 120 })
                    );
                    store.handleAnswerSelection('true');
                  }}
                  disabled={selectedAnswer !== null}
                >
                  <Text style={styles.optionText}>True</Text>
                </TouchableOpacity>
                </Animated.View>
                
                <Animated.View style={optionPressStyle}>
                  <TouchableOpacity
                  style={[
                    styles.optionButton,
                    selectedAnswer === 'false' && styles.selectedOptionButton,
                    selectedAnswer !== null && 'false' === String(currentQuestion.correctAnswer) && styles.correctOptionButton,
                    selectedAnswer === 'false' && selectedAnswer !== String(currentQuestion.correctAnswer) && styles.incorrectOptionButton,
                  ]}
                  onPress={() => {
                    optionPressScale.value = withSequence(
                      withTiming(0.97, { duration: 80 }),
                      withTiming(1, { duration: 120 })
                    );
                    store.handleAnswerSelection('false');
                  }}
                  disabled={selectedAnswer !== null}
                >
                  <Text style={styles.optionText}>False</Text>
                </TouchableOpacity>
                </Animated.View>
              </>
            ) : (
              currentQuestion.options?.map((option, index) => (
                <Animated.View style={optionPressStyle}>
                  <TouchableOpacity
                  key={index}
                  style={[
                    styles.optionButton,
                    selectedAnswer === index && styles.selectedOptionButton,
                    selectedAnswer !== null && index === Number(currentQuestion.correctAnswer) && styles.correctOptionButton,
                    selectedAnswer === index && selectedAnswer !== Number(currentQuestion.correctAnswer) && styles.incorrectOptionButton,
                  ]}
                  onPress={() => {
                    optionPressScale.value = withSequence(
                      withTiming(0.97, { duration: 80 }),
                      withTiming(1, { duration: 120 })
                    );
                    store.handleAnswerSelection(index);
                  }}
                  disabled={selectedAnswer !== null}
                >
                  <Text style={styles.optionText}>{option}</Text>
                </TouchableOpacity>
                </Animated.View>
              ))
            )}
          </View>
          
          {showExplanation && (
            <Animated.View style={[styles.explanationContainer, explanationAnimatedStyle]}>
              <Text style={styles.explanationTitle}>
                {isAnswerCorrect ? 'Correct!' : 'Incorrect'}
              </Text>
              <Text style={styles.explanationText}>{currentQuestion.explanation}</Text>
            </Animated.View>
          )}
          
          {showExplanation && (
            <TouchableOpacity
              style={[styles.nextButton, { backgroundColor: selectedVirtue?.color_code }]}
              onPress={() => store.goToNextQuestion()}
            >
              <Text style={styles.nextButtonText}>
                {currentQuestionIndex < questions.length - 1 ? 'Next Question' : 'See Results'}
              </Text>
              <CaretRight size={16} color="#FFF" />
            </TouchableOpacity>
          )}
        </Animated.View>
      </View>
    );
  };
  
  const renderQuizResults = () => {
    if (questions.length === 0) return null;
    const percentage = (score / questions.length) * 100;
    const passed = percentage >= 60;
    
    return (
      <View style={styles.resultsContainer}>
        <PIConfetti
          ref={confettiRef}
          count={200}
          fadeOutOnEnd
          colors={[ '#FFD700', '#FF6347', '#4169E1', '#32CD32', '#FF69B4', '#BA55D3' ]}
        />
        
        <Animated.View style={[styles.resultsCard, cardAnimatedStyle]}>
          <LinearGradient
            colors={[
              passed ? `${selectedVirtue?.color_code}20` : '#F4433610',
              passed ? `${selectedVirtue?.color_code}05` : '#F4433605'
            ]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.resultsGradient}
          />
          
          <View style={styles.scoreContainer}>
            <View style={[
              styles.scoreCircle,
              { borderColor: passed ? selectedVirtue?.color_code : '#F44336' }
            ]}>
              <Text style={[
                styles.scoreText,
                { color: passed ? selectedVirtue?.color_code : '#F44336' }
              ]}>
                {percentage.toFixed(0)}%
              </Text>
            </View>
            <Text style={styles.resultTitle}>
              {passed ? 'Congratulations!' : 'Keep Learning!'}
            </Text>
            <Text style={styles.resultSubtitle}>
              {passed 
                ? `You've mastered ${selectedVirtue?.name} Level ${selectedLevel}!` 
                : `You're making progress on ${selectedVirtue?.name}.`}
            </Text>
          </View>
          
          <View style={styles.statsContainer}>
            <View style={styles.statItem}>
              <Check size={20} color={theme?.colors.success} />
              <Text style={styles.statText}>Correct: {score}</Text>
            </View>
            <View style={styles.statItem}>
              <X size={20} color={theme?.colors.error} />
              <Text style={styles.statText}>Incorrect: {questions.length - score}</Text>
            </View>
          </View>
          
          {passed && (
            <View style={styles.rewardContainer}>
              <Trophy size={24} color="#FFD700" />
              <Text style={styles.rewardText}>
                +{selectedLevel! * 10} Points Earned!
              </Text>
            </View>
          )}
          
          <View style={styles.actionButtonsContainer}>
            <TouchableOpacity
              style={[styles.actionButton, styles.secondaryButton]}
              onPress={() => store.restartQuiz()}
            >
              <Text style={styles.secondaryButtonText}>Try Again</Text>
            </TouchableOpacity>
            
            <TouchableOpacity
              style={[
                styles.actionButton, 
                styles.primaryButton,
                { backgroundColor: selectedVirtue?.color_code }
              ]}
              onPress={() => store.selectDifferentVirtue()}
            >
              <Text style={styles.primaryButtonText}>New Quiz</Text>
            </TouchableOpacity>
          </View>
        </Animated.View>
      </View>
    );
  };
  
  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <PIConfetti
        ref={confettiInlineRef}
        count={90}
        fadeOutOnEnd
        colors={[ '#FFD700', '#FF6347', '#4169E1', '#32CD32', '#FF69B4', '#BA55D3' ]}
      />
      <View style={styles.header}>
        <TouchableOpacity 
          style={styles.backButton}
          onPress={() => {
            if (quizStarted && !quizCompleted) {
              Alert.alert(
                'Quit Quiz?',
                'Your progress will be lost.',
                [
                  { text: 'Cancel', style: 'cancel' },
                  { text: 'Quit', onPress: () => navigation.goBack() }
                ]
              );
            } else {
              navigation.goBack();
            }
          }}
        >
          <ArrowLeft size={24} color={theme?.colors.text.primary} />
        </TouchableOpacity>
        
        <Text style={styles.headerTitle}>
          {quizStarted && selectedVirtue
            ? `${selectedVirtue.name} Quiz` 
            : 'Virtue Quiz'}
        </Text>
        
        <View style={{ width: 24 }} />
      </View>
      
      <ScrollView 
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {isQuizLoading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color={theme?.colors.primary} />
            <Text style={styles.loadingText}>Loading questions...</Text>
          </View>
        ) : (
          <>
            {!quizStarted && renderVirtueSelection()}
            {quizStarted && renderQuizQuestion()}
            {!quizStarted && selectedVirtue && renderLevelSelection()}
          </>
        )}
      </ScrollView>
    </View>
  );
});

const createStyles = (theme: Theme, selectedVirtue?: AppVirtue | null) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme?.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme?.colors.border,
  },
  backButton: {
    padding: theme?.spacing.sm,
    marginLeft: -theme?.spacing.sm,
  },
  headerTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
  },
  scrollContent: {
    flexGrow: 1,
    padding: theme?.spacing.md,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme?.spacing.xl,
  },
  loadingText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    marginTop: theme?.spacing.md,
  },
  
  correctOptionText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.success,
    fontWeight: '600',
  },
  incorrectOptionText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.error,
    fontWeight: '600',
  },
  answerFeedback: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme?.spacing.md,
  },
  feedbackText: {
    ...theme?.typography.body.sans,
    fontWeight: '600',
    marginLeft: theme?.spacing.sm,
  },
  correctFeedbackText: {
    color: theme?.colors.success,
  },
  incorrectFeedbackText: {
    color: theme?.colors.error,
  },
  optionIcon: {
    marginRight: theme?.spacing.sm,
  },
  optionContent: {
    flex: 1,
  },
  optionFeedback: {
    width: 24,
    height: 24,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  correctFeedback: {
    backgroundColor: `${theme?.colors.success}20`,
  },
  incorrectFeedback: {
    backgroundColor: `${theme?.colors.error}20`,
  },
  learnMoreSection: {
    marginTop: theme?.spacing.md,
  },
  learnMoreHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme?.spacing.sm,
  },
  learnMoreHeaderText: {
    ...theme?.typography.body.sans,
    fontWeight: '600',
    color: theme?.colors.text.primary,
    marginLeft: theme?.spacing.sm,
  },
  
  // Virtue Selection Styles
  selectionContainer: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.lg,
    marginBottom: theme?.spacing.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
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
  selectionTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.lg,
    textAlign: 'center',
  },
  virtuesScrollContent: {
    paddingBottom: theme?.spacing.md,
    paddingHorizontal: theme?.spacing.xs,
  },
  virtueCard: {
    width: 160,
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.md,
    marginRight: theme?.spacing.md,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: theme?.colors.border,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  selectedVirtueCard: {
    borderColor: selectedVirtue?.color_code || theme?.colors.primary,
    borderWidth: 2,
    backgroundColor: `${selectedVirtue?.color_code || theme?.colors.primary}05`,
  },
  virtueGradient: {
    ...StyleSheet.absoluteFillObject,
    borderRadius: theme?.borderRadius.lg,
  },
  virtueIconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme?.spacing.sm,
  },
  virtueName: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.xs,
  },
  virtueDescription: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    marginBottom: theme?.spacing.sm,
  },
  progressContainer: {
    marginTop: theme?.spacing.sm,
  },
  progressBar: {
    height: 6,
    backgroundColor: `${theme?.colors.text.secondary}15`,
    borderRadius: theme?.borderRadius.full,
    marginBottom: theme?.spacing.xs,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: theme?.borderRadius.full,
  },
  progressText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  
  // Level Selection Styles
  levelsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme?.spacing.xl,
  },
  levelCard: {
    width: '30%',
    aspectRatio: 0.8,
    backgroundColor: theme?.colors.background,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.md,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: theme?.colors.border,
    overflow: 'hidden',
  },
  selectedLevelCard: {
    borderColor: selectedVirtue?.color_code || theme?.colors.primary,
    borderWidth: 2,
    backgroundColor: `${selectedVirtue?.color_code || theme?.colors.primary}05`,
  },
  lockedLevelCard: {
    opacity: 0.6,
  },
  levelGradient: {
    ...StyleSheet.absoluteFillObject,
    borderRadius: theme?.borderRadius.lg,
  },
  levelNumber: {
    ...theme?.typography.heading.large,
    fontWeight: 'bold',
    marginBottom: theme?.spacing.sm,
  },
  levelLabel: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.primary,
    textAlign: 'center',
  },
  lockedLevelLabel: {
    color: theme?.colors.text.secondary,
  },
  lockedIconContainer: {
    marginBottom: theme?.spacing.sm,
  },
  startButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme?.spacing.md,
    paddingHorizontal: theme?.spacing.lg,
    borderRadius: theme?.borderRadius.full,
  },
  startButtonText: {
    ...theme?.typography.body.sans,
    color: '#FFF',
    fontWeight: '600',
    marginLeft: theme?.spacing.sm,
  },
  
  // Quiz Question Styles
  quizContainer: {
    flex: 1,
  },
  progressBarContainer: {
    height: 6,
    backgroundColor: `${theme?.colors.text.secondary}15`,
    borderRadius: theme?.borderRadius.full,
    marginBottom: theme?.spacing.md,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: selectedVirtue?.color_code || theme?.colors.primary,
    borderRadius: theme?.borderRadius.full,
  },
  questionCounter: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    textAlign: 'center',
    marginBottom: theme?.spacing.md,
  },
  questionCard: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.lg,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: theme?.colors.border,
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
  questionGradient: {
    ...StyleSheet.absoluteFillObject,
  },
  questionText: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.lg,
  },
  optionsContainer: {
    marginBottom: theme?.spacing.md,
  },
  optionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: theme?.spacing.md,
    borderRadius: theme?.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    marginBottom: theme?.spacing.sm,
    backgroundColor: theme?.colors.background,
  },
  selectedOptionButton: {
    borderColor: selectedVirtue?.color_code || theme?.colors.primary,
    backgroundColor: `${selectedVirtue?.color_code || theme?.colors.primary}10`,
  },
  correctOptionButton: {
    borderColor: theme?.colors.success,
    backgroundColor: `${theme?.colors.success}10`,
  },
  incorrectOptionButton: {
    borderColor: theme?.colors.error,
    backgroundColor: `${theme?.colors.error}10`,
  },
  optionText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    flex: 1,
  },
  explanationContainer: {
    padding: theme?.spacing.md,
    borderRadius: theme?.borderRadius.lg,
    backgroundColor: `${theme?.colors.background}80`,
    marginTop: theme?.spacing.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
  },
  explanationTitle: {
    ...theme?.typography.body.sans,
    fontWeight: '600',
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.sm,
  },
  explanationText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    marginBottom: theme?.spacing.md,
  },
  scriptureContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: `${theme?.colors.background}70`,
    borderRadius: theme?.borderRadius.md,
    padding: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
    borderLeftWidth: 3,
    borderLeftColor: selectedVirtue?.color_code || theme?.colors.primary,
  },
  scriptureText: {
    ...theme?.typography.body.serif,
    color: theme?.colors.text.primary,
    fontStyle: 'italic',
    marginLeft: theme?.spacing.sm,
  },
  nextButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme?.spacing.md,
    borderRadius: theme?.borderRadius.full,
    marginTop: theme?.spacing.sm,
  },
  nextButtonText: {
    ...theme?.typography.body.sans,
    color: '#FFF',
    fontWeight: '600',
    marginRight: theme?.spacing.sm,
  },
  
  // Results Styles
  resultsContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme?.spacing.md,
  },
  resultsCard: {
    width: '100%',
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: theme?.colors.border,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.15,
        shadowRadius: 8,
      },
      android: {
        elevation: 5,
      },
    }),
  },
  resultsGradient: {
    ...StyleSheet.absoluteFillObject,
  },
  scoreContainer: {
    alignItems: 'center',
    padding: theme?.spacing.xl,
  },
  scoreCircle: {
    width: 100,
    height: 100,
    borderRadius: 50,
    borderWidth: 4,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme?.spacing.lg,
  },
  scoreText: {
    ...theme?.typography.heading.large,
    fontWeight: 'bold',
  },
  resultTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.sm,
  },
  resultSubtitle: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    textAlign: 'center',
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: theme?.spacing.md,
    borderTopWidth: 1,
    borderTopColor: theme?.colors.border,
    borderBottomWidth: 1,
    borderBottomColor: theme?.colors.border,
  },
  statItem: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    marginLeft: theme?.spacing.xs,
  },
  rewardContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme?.spacing.md,
    backgroundColor: `${theme?.colors.background}50`,
  },
  rewardText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    fontWeight: '600',
    marginLeft: theme?.spacing.sm,
  },
  actionButtonsContainer: {
    flexDirection: 'row',
    padding: theme?.spacing.md,
    justifyContent: 'space-between',
  },
  actionButton: {
    flex: 1,
    paddingVertical: theme?.spacing.md,
    borderRadius: theme?.borderRadius.full,
    alignItems: 'center',
    justifyContent: 'center',
    marginHorizontal: theme?.spacing.xs,
  },
  secondaryButton: {
    backgroundColor: `${theme?.colors.text.secondary}15`,
  },
  secondaryButtonText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
  },
  primaryButton: {
    backgroundColor: theme?.colors.primary,
  },
  primaryButtonText: {
    ...theme?.typography.body.sans,
    color: '#FFF',
    fontWeight: '600',
  },
});

export default VirtueQuizScreen;