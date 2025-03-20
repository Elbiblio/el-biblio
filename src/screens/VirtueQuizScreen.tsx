import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Platform,
  ActivityIndicator,
  Dimensions,
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
  withTiming,
  withSequence,
  withSpring,
  interpolate,
  Extrapolation,
  runOnJS
} from 'react-native-reanimated';
import { useTheme } from '@/contexts/ThemeContext';
import { useAuth } from '@/stores/auth';
import { Theme } from '@/theme';
import ConfettiCannon from 'react-native-confetti-cannon';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

type QuizQuestion = {
  id: string;
  question: string;
  type: 'true_false' | 'multiple_choice';
  options?: string[];
  correctAnswer: string | number;
  explanation: string;
  scriptureReference?: string;
  virtue: string;
  level: number;
};

type Virtue = {
  id: string;
  name: string;
  description: string;
  icon: React.ComponentType<any>;
  color: string;
  levels: number;
  userProgress: number;
};

const VIRTUES: Virtue[] = [
  {
    id: 'patience',
    name: 'Patience',
    description: 'The capacity to accept or tolerate delay, trouble, or suffering without getting angry or upset.',
    icon: Clock,
    color: '#4CAF50',
    levels: 3,
    userProgress: 2,
  },
  {
    id: 'kindness',
    name: 'Kindness',
    description: 'The quality of being friendly, generous, and considerate.',
    icon: Heart,
    color: '#E91E63',
    levels: 3,
    userProgress: 1,
  },
  {
    id: 'humility',
    name: 'Humility',
    description: 'Freedom from pride or arrogance; the quality of being humble.',
    icon: Star,
    color: '#9C27B0',
    levels: 3,
    userProgress: 0,
  },
  {
    id: 'wisdom',
    name: 'Wisdom',
    description: 'The quality of having experience, knowledge, and good judgment.',
    icon: Lightbulb,
    color: '#FF9800',
    levels: 3,
    userProgress: 1,
  },
];

// Sample quiz questions
const QUIZ_QUESTIONS: QuizQuestion[] = [
  {
    id: '1',
    question: 'Patience means never feeling frustrated.',
    type: 'true_false',
    correctAnswer: 'false',
    explanation: "Patience isn't about never feeling frustrated, but about how you respond to frustration. It's normal to feel frustrated, but patience helps us manage those feelings constructively.",
    scriptureReference: 'Romans 12:12',
    virtue: 'patience',
    level: 1,
  },
  {
    id: '2',
    question: 'Which of these is NOT an example of patience?',
    type: 'multiple_choice',
    options: [
      'Waiting calmly in a long line',
      'Listening fully to someone who speaks slowly',
      'Demanding immediate results from a new project',
      'Taking time to understand a complex problem'
    ],
    correctAnswer: 2,
    explanation: 'Demanding immediate results shows impatience. Patience involves accepting that worthwhile things often take time and managing our expectations accordingly.',
    scriptureReference: 'Galatians 5:22-23',
    virtue: 'patience',
    level: 1,
  },
  {
    id: '3',
    question: 'Patience is primarily about:',
    type: 'multiple_choice',
    options: [
      'Never taking action',
      'Enduring difficult circumstances with calmness',
      'Avoiding challenging situations',
      'Giving up when things get hard'
    ],
    correctAnswer: 1,
    explanation: 'Patience is about enduring difficult circumstances with calmness and self-control, not about inaction or avoidance.',
    scriptureReference: 'James 1:2-4',
    virtue: 'patience',
    level: 2,
  },
  {
    id: '4',
    question: "True patience requires understanding others' perspectives.",
    type: 'true_false',
    correctAnswer: 'true',
    explanation: "True patience involves empathy and understanding others' perspectives, which helps us respond with compassion rather than frustration.",
    scriptureReference: 'Ephesians 4:2',
    virtue: 'patience',
    level: 2,
  },
  {
    id: '5',
    question: 'Kindness always expects something in return.',
    type: 'true_false',
    correctAnswer: 'false',
    explanation: "True kindness is given freely without expectation of reward or return. It's motivated by genuine care for others, not by what we might gain.",
    scriptureReference: 'Luke 6:35',
    virtue: 'kindness',
    level: 1,
  },
  {
    id: '6',
    question: 'Which of these best exemplifies kindness?',
    type: 'multiple_choice',
    options: [
      'Helping someone only when others are watching',
      'Doing a favor but reminding the person repeatedly',
      'Noticing someone in need and quietly helping them',
      'Being nice only to people who can benefit you'
    ],
    correctAnswer: 2,
    explanation: 'Noticing someone in need and quietly helping them demonstrates genuine kindness that comes from compassion rather than self-interest.',
    scriptureReference: 'Colossians 3:12',
    virtue: 'kindness',
    level: 1,
  },
  {
    id: '7',
    question: 'Humility means thinking less of yourself.',
    type: 'true_false',
    correctAnswer: 'false',
    explanation: "Humility isn't about thinking less of yourself, but thinking of yourself less. It's about having an accurate view of your strengths and weaknesses, not diminishing your worth.",
    scriptureReference: 'Philippians 2:3-4',
    virtue: 'humility',
    level: 1,
  },
  {
    id: '8',
    question: 'Wisdom is primarily about:',
    type: 'multiple_choice',
    options: [
      'Having extensive knowledge',
      'Being able to apply knowledge appropriately',
      'Being older than others',
      'Having formal education'
    ],
    correctAnswer: 1,
    explanation: "While knowledge is important, wisdom is about applying that knowledge appropriately in different situations. It involves discernment and good judgment.",
    scriptureReference: 'Proverbs 4:7',
    virtue: 'wisdom',
    level: 1,
  },
];

const VirtueQuizScreen = ({ navigation, route }: NativeStackScreenProps<RootStackParamList, 'VirtueQuizScreen'>) => {
  const insets = useSafeAreaInsets();
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const { user } = useAuth();
  
  const [selectedVirtue, setSelectedVirtue] = useState<Virtue | null>(null);
  const [selectedLevel, setSelectedLevel] = useState<number | null>(null);
  const [quizStarted, setQuizStarted] = useState(false);
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [questions, setQuestions] = useState<QuizQuestion[]>([]);
  const [selectedAnswer, setSelectedAnswer] = useState<string | number | null>(null);
  const [isAnswerCorrect, setIsAnswerCorrect] = useState<boolean | null>(null);
  const [showExplanation, setShowExplanation] = useState(false);
  const [quizCompleted, setQuizCompleted] = useState(false);
  const [score, setScore] = useState(0);
  const [loading, setLoading] = useState(false);
  
  // Animation values
  const cardScale = useSharedValue(1);
  const optionScale = useSharedValue(1);
  const progressWidth = useSharedValue(0);
  const explanationHeight = useSharedValue(0);
  
  // Confetti ref
  const confettiRef = useRef<any>(null);
  
  useEffect(() => {
    // Check if virtue and level were passed as params
    if (route.params?.virtueId) {
      const virtue = VIRTUES.find(v => v.id === route.params?.virtueId);
      if (virtue) {
        setSelectedVirtue(virtue);
        if (route.params?.level && route.params.level <= virtue.levels) {
          setSelectedLevel(route.params.level);
          loadQuestions(virtue.id, route.params.level);
        }
      }
    }
  }, [route.params]);
  
  useEffect(() => {
    if (selectedVirtue && selectedLevel) {
      loadQuestions(selectedVirtue.id, selectedLevel);
    }
  }, [selectedVirtue, selectedLevel]);
  
  useEffect(() => {
    if (quizStarted && questions.length > 0) {
      // Update progress bar
      progressWidth.value = withTiming(
        ((currentQuestionIndex + 1) / questions.length) * 100,
        { duration: 300 }
      );
    }
  }, [currentQuestionIndex, quizStarted, questions.length]);
  
  const loadQuestions = (virtueId: string, level: number) => {
    setLoading(true);
    
    // In a real app, this would be an API call
    // For now, we'll filter the sample questions
    setTimeout(() => {
      const filteredQuestions = QUIZ_QUESTIONS.filter(
        q => q.virtue === virtueId && q.level === level
      );
      
      // Shuffle questions
      const shuffled = [...filteredQuestions].sort(() => 0.5 - Math.random());
      setQuestions(shuffled.slice(0, 5)); // Take 5 random questions
      setLoading(false);
    }, 1000);
  };
  
  const startQuiz = () => {
    if (!selectedVirtue || !selectedLevel) {
      Alert.alert('Selection Required', 'Please select a virtue and level to start the quiz.');
      return;
    }
    
    setQuizStarted(true);
    setCurrentQuestionIndex(0);
    setScore(0);
    setQuizCompleted(false);
    setShowExplanation(false);
    setIsAnswerCorrect(null);
    setSelectedAnswer(null);
    
    // Animate card
    cardScale.value = withSequence(
      withTiming(0.95, { duration: 100 }),
      withTiming(1, { duration: 300 })
    );
  };
  
  const handleAnswerSelection = (answer: string | number) => {
    if (selectedAnswer !== null) return; // Prevent multiple selections
    
    setSelectedAnswer(answer);
    const currentQuestion = questions[currentQuestionIndex];
    const correct = answer === currentQuestion.correctAnswer;
    setIsAnswerCorrect(correct);
    
    if (correct) {
      setScore(prev => prev + 1);
    }
    
    // Animate option
    optionScale.value = withSequence(
      withTiming(0.95, { duration: 100 }),
      withTiming(1, { duration: 200 })
    );
    
    // Show explanation after a short delay
    setTimeout(() => {
      setShowExplanation(true);
      explanationHeight.value = withTiming(1, { duration: 500 });
    }, 500);
  };
  
  const goToNextQuestion = () => {
    if (currentQuestionIndex < questions.length - 1) {
      // Reset for next question
      setSelectedAnswer(null);
      setIsAnswerCorrect(null);
      setShowExplanation(false);
      explanationHeight.value = 0;
      
      // Move to next question with animation
      cardScale.value = withSequence(
        withTiming(0.9, { duration: 150 }),
        withTiming(1, { duration: 300 })
      );
      
      setCurrentQuestionIndex(prev => prev + 1);
    } else {
      // Quiz completed
      setQuizCompleted(true);
      
      // Show confetti for good scores
      if (score / questions.length >= 0.6) {
        setTimeout(() => {
          confettiRef.current?.start();
        }, 500);
      }
    }
  };
  
  const restartQuiz = () => {
    setQuizStarted(false);
    setQuizCompleted(false);
    setCurrentQuestionIndex(0);
    setScore(0);
    setSelectedAnswer(null);
    setIsAnswerCorrect(null);
    setShowExplanation(false);
    progressWidth.value = 0;
  };
  
  const selectDifferentVirtue = () => {
    setSelectedVirtue(null);
    setSelectedLevel(null);
    restartQuiz();
  };
  
  // Animated styles
  const cardAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: cardScale.value }]
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
  
  // Render functions
  const renderVirtueSelection = () => (
    <View style={styles.selectionContainer}>
      <Text style={styles.selectionTitle}>Select a Virtue</Text>
      <ScrollView 
        horizontal 
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.virtuesScrollContent}
      >
        {VIRTUES.map(virtue => (
          <TouchableOpacity
            key={virtue.id}
            style={[
              styles.virtueCard,
              selectedVirtue?.id === virtue.id && styles.selectedVirtueCard
            ]}
            onPress={() => {
              setSelectedVirtue(virtue);
              setSelectedLevel(null);
              cardScale.value = withSequence(
                withTiming(0.95, { duration: 100 }),
                withTiming(1, { duration: 200 })
              );
            }}
          >
            <LinearGradient
              colors={[`${virtue.color}20`, `${virtue.color}05`]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={styles.virtueGradient}
            />
            <View style={[styles.virtueIconContainer, { backgroundColor: `${virtue.color}15` }]}>
              <virtue.icon size={24} color={virtue.color} />
            </View>
            <Text style={styles.virtueName}>{virtue.name}</Text>
            <View style={styles.progressContainer}>
              <View style={styles.progressBar}>
                <View 
                  style={[
                    styles.progressFill, 
                    { 
                      width: `${(virtue.userProgress / virtue.levels) * 100}%`,
                      backgroundColor: virtue.color 
                    }
                  ]} 
                />
              </View>
              <Text style={styles.progressText}>
                Level {virtue.userProgress}/{virtue.levels}
              </Text>
            </View>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </View>
  );
  
  const renderLevelSelection = () => {
    if (!selectedVirtue) return null;
    
    return (
      <Animated.View style={[styles.selectionContainer, cardAnimatedStyle]}>
        <Text style={styles.selectionTitle}>Select Difficulty Level</Text>
        <View style={styles.levelsContainer}>
          {Array.from({ length: selectedVirtue.levels }, (_, i) => i + 1).map(level => (
            <TouchableOpacity
              key={`level-${level}`}
              style={[
                styles.levelCard,
                selectedLevel === level && styles.selectedLevelCard,
                level > selectedVirtue!.userProgress + 1 && styles.lockedLevelCard
              ]}
              disabled={level > selectedVirtue.userProgress + 1}
              onPress={() => {
                setSelectedLevel(level);
                optionScale.value = withSequence(
                  withTiming(0.95, { duration: 100 }),
                  withTiming(1, { duration: 200 })
                );
              }}
            >
              <LinearGradient
                colors={[
                  level <= selectedVirtue.userProgress + 1 
                    ? `${selectedVirtue.color}20` 
                    : '#00000010',
                  level <= selectedVirtue.userProgress + 1 
                    ? `${selectedVirtue.color}05` 
                    : '#00000005'
                ]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.levelGradient}
              />
              {level > selectedVirtue.userProgress + 1 ? (
                <View style={styles.lockedIconContainer}>
                  <Lock size={20} color={theme?.colors.text.secondary} />
                </View>
              ) : (
                <Text style={[
                  styles.levelNumber,
                  { color: selectedVirtue.color }
                ]}>
                  {level}
                </Text>
              )}
              <Text style={[
                styles.levelLabel,
                level > selectedVirtue.userProgress + 1 && styles.lockedLevelLabel
              ]}>
                {level === 1 ? 'Beginner' : level === 2 ? 'Intermediate' : 'Advanced'}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
        
        <TouchableOpacity
          style={[
            styles.startButton,
            { backgroundColor: selectedVirtue.color }
          ]}
          onPress={startQuiz}
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
    
    const currentQuestion = questions[currentQuestionIndex];
    
    return (
      <View style={styles.quizContainer}>
        <View style={styles.progressBarContainer}>
          <Animated.View style={[styles.progressBarFill, progressAnimatedStyle]} />
        </View>
        
        <Text style={styles.questionCounter}>
          Question {currentQuestionIndex + 1} of {questions.length}
        </Text>
        
        <Animated.View style={[styles.questionCard, cardAnimatedStyle]}>
          <LinearGradient
            colors={[`${selectedVirtue?.color}10`, `${selectedVirtue?.color}02`]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.questionGradient}
          />
          
          <Text style={styles.questionText}>{currentQuestion.question}</Text>
          
          {currentQuestion.type === 'true_false' ? (
            <View style={styles.optionsContainer}>
              {['true', 'false'].map((option) => (
                <TouchableOpacity
                  key={option}
                  style={[
                    styles.optionButton,
                    selectedAnswer === option && styles.selectedOptionButton,
                    selectedAnswer === option && isAnswerCorrect && styles.correctOptionButton,
                    selectedAnswer === option && !isAnswerCorrect && styles.incorrectOptionButton,
                    selectedAnswer !== null && 
                      option === currentQuestion.correctAnswer && 
                      styles.correctOptionButton
                  ]}
                  disabled={selectedAnswer !== null}
                  onPress={() => handleAnswerSelection(option)}
                >
                  <Text style={[
                    styles.optionText,
                    selectedAnswer === option && isAnswerCorrect && styles.correctOptionText,
                    selectedAnswer === option && !isAnswerCorrect && styles.incorrectOptionText,
                    selectedAnswer !== null && 
                      option === currentQuestion.correctAnswer && 
                      styles.correctOptionText
                  ]}>
                    {option === 'true' ? 'True' : 'False'}
                  </Text>
                  
                  {selectedAnswer === option && isAnswerCorrect && (
                    <Check size={20} color="#4CAF50" />
                  )}
                  {selectedAnswer === option && !isAnswerCorrect && (
                    <X size={20} color="#F44336" />
                  )}
                  {selectedAnswer !== null && 
                    option === currentQuestion.correctAnswer && 
                    selectedAnswer !== option && (
                    <Check size={20} color="#4CAF50" />
                  )}
                </TouchableOpacity>
              ))}
            </View>
          ) : (
            <View style={styles.optionsContainer}>
              {currentQuestion.options?.map((option, index) => (
                <TouchableOpacity
                  key={index}
                  style={[
                    styles.optionButton,
                    selectedAnswer === index && styles.selectedOptionButton,
                    selectedAnswer === index && isAnswerCorrect && styles.correctOptionButton,
                    selectedAnswer === index && !isAnswerCorrect && styles.incorrectOptionButton,
                    selectedAnswer !== null && 
                      index === currentQuestion.correctAnswer && 
                      styles.correctOptionButton
                  ]}
                  disabled={selectedAnswer !== null}
                  onPress={() => handleAnswerSelection(index)}
                >
                  <Text style={[
                    styles.optionText,
                    selectedAnswer === index && isAnswerCorrect && styles.correctOptionText,
                    selectedAnswer === index && !isAnswerCorrect && styles.incorrectOptionText,
                    selectedAnswer !== null && 
                      index === currentQuestion.correctAnswer && 
                      styles.correctOptionText
                  ]}>
                    {String.fromCharCode(65 + index)}. {option}
                  </Text>
                  
                  {selectedAnswer === index && isAnswerCorrect && (
                    <Check size={20} color="#4CAF50" />
                  )}
                  {selectedAnswer === index && !isAnswerCorrect && (
                    <X size={20} color="#F44336" />
                  )}
                  {selectedAnswer !== null && 
                    index === currentQuestion.correctAnswer && 
                    selectedAnswer !== index && (
                    <Check size={20} color="#4CAF50" />
                  )}
                </TouchableOpacity>
              ))}
            </View>
          )}
          
          {showExplanation && (
            <Animated.View style={[styles.explanationContainer, explanationAnimatedStyle]}>
              <Text style={styles.explanationTitle}>
                {isAnswerCorrect ? 'Correct!' : 'Not quite right'}
              </Text>
              <Text style={styles.explanationText}>{currentQuestion.explanation}</Text>
              
              {currentQuestion.scriptureReference && (
                <View style={styles.scriptureContainer}>
                  <BookOpen size={16} color={theme?.colors.text.secondary} />
                  <Text style={styles.scriptureText}>{currentQuestion.scriptureReference}</Text>
                </View>
              )}
              
              <TouchableOpacity
                style={[styles.nextButton, { backgroundColor: selectedVirtue?.color }]}
                onPress={goToNextQuestion}
              >
                <Text style={styles.nextButtonText}>
                  {currentQuestionIndex < questions.length - 1 ? 'Next Question' : 'See Results'}
                </Text>
                <CaretRight size={16} color="#FFF" />
              </TouchableOpacity>
            </Animated.View>
          )}
        </Animated.View>
      </View>
    );
  };
  
  const renderQuizResults = () => {
    const percentage = (score / questions.length) * 100;
    const passed = percentage >= 60;
    
    return (
      <View style={styles.resultsContainer}>
        <ConfettiCannon
          ref={confettiRef}
          count={200}
          origin={{ x: SCREEN_WIDTH / 2, y: 0 }}
          autoStart={false}
          fadeOut
        />
        
        <Animated.View style={[styles.resultsCard, cardAnimatedStyle]}>
          <LinearGradient
            colors={[
              passed ? `${selectedVirtue?.color}20` : '#F4433610',
              passed ? `${selectedVirtue?.color}05` : '#F4433605'
            ]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.resultsGradient}
          />
          
          <View style={styles.scoreContainer}>
            <View style={[
              styles.scoreCircle,
              { borderColor: passed ? selectedVirtue?.color : '#F44336' }
            ]}>
              <Text style={[
                styles.scoreText,
                { color: passed ? selectedVirtue?.color : '#F44336' }
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
              onPress={restartQuiz}
            >
              <Text style={styles.secondaryButtonText}>Try Again</Text>
            </TouchableOpacity>
            
            <TouchableOpacity
              style={[
                styles.actionButton, 
                styles.primaryButton,
                { backgroundColor: selectedVirtue?.color }
              ]}
              onPress={selectDifferentVirtue}
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
          {quizStarted 
            ? `${selectedVirtue?.name} Quiz` 
            : 'Virtue Quiz'}
        </Text>
        
        <View style={{ width: 24 }} />
      </View>
      
      <ScrollView 
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {loading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color={theme?.colors.primary} />
            <Text style={styles.loadingText}>Loading questions...</Text>
          </View>
        ) : (
          <>
            {!quizStarted && !selectedVirtue && renderVirtueSelection()}
            {!quizStarted && selectedVirtue && renderLevelSelection()}
            {renderQuizQuestion()}
          </>
        )}
      </ScrollView>
    </View>
  );
};

const createStyles = (theme: Theme, selectedVirtue?: Virtue | null) => StyleSheet.create({
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
    borderColor: selectedVirtue?.color || theme?.colors.primary,
    borderWidth: 2,
    backgroundColor: `${selectedVirtue?.color || theme?.colors.primary}05`,
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
    borderColor: selectedVirtue?.color || theme?.colors.primary,
    borderWidth: 2,
    backgroundColor: `${selectedVirtue?.color || theme?.colors.primary}05`,
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
    backgroundColor: selectedVirtue?.color || theme?.colors.primary,
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
    borderColor: selectedVirtue?.color || theme?.colors.primary,
    backgroundColor: `${selectedVirtue?.color || theme?.colors.primary}10`,
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
    borderLeftColor: selectedVirtue?.color || theme?.colors.primary,
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