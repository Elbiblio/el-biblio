import React, { useMemo, useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, ActivityIndicator } from 'react-native';
import Animated, {
  FadeInDown,
  FadeIn,
} from 'react-native-reanimated';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useTheme } from '@/contexts/ThemeContext';
import { RootStackParamList } from '@/types';
import { Brain, ChevronRight, ChevronLeft, Trophy, Sparkle, Star, InfoCircle } from '@/components/Icons';
import { useGameStore } from '@/stores/StoreProvider';
import { toast } from 'sonner-native';
import { apiClient, endpoints } from '@/api/client';
import { LinearGradient } from 'expo-linear-gradient';
import * as Haptics from 'expo-haptics';
import { 
  SpiritualCareerDataService,
  type StatusOption,
  type StrengthDefinition,
  type DailyTask,
  type CareerDefinition,
} from '@/services/spiritualCareerData';

type StatusValue = string;

// Will be loaded from data service
let STATUSES: StatusOption[] = [];
let STRENGTH_KEYS: StrengthDefinition[] = [];
let DAILY_TASKS_DATA: Record<string, DailyTask[]> = {};
let CAREER_DEFINITIONS_DATA: Record<string, CareerDefinition[]> = {};

type StrengthMap = Record<string, number>;

const SpiritualCareerScreen = () => {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const gameStore = useGameStore();

  const [step, setStep] = useState<1 | 2 | 3 | 4 | 5>(1);
  const [status, setStatus] = useState<StatusValue | null>(null);
  const [strengths, setStrengths] = useState<StrengthMap>({});
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [hasCompletedAssessment, setHasCompletedAssessment] = useState(false);
  const [hasRevealedCareer, setHasRevealedCareer] = useState(false);
  const [completedTasks, setCompletedTasks] = useState<Set<string>>(new Set());
  const [dailyPoints, setDailyPoints] = useState(0);
  const [monthlyTaskHistory, setMonthlyTaskHistory] = useState<Record<string, string[]>>({});
  const [consistencyStreak, setConsistencyStreak] = useState(0);
  const [initialScores, setInitialScores] = useState<StrengthMap>({});
  const [currentStrengthIndex, setCurrentStrengthIndex] = useState(0);
  const [topStrengthsForQuiz, setTopStrengthsForQuiz] = useState<StrengthDefinition[]>([]);
  const [currentQuizIndex, setCurrentQuizIndex] = useState(0);
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [quizAnswers, setQuizAnswers] = useState<Record<string, number[]>>({});
  const [dataLoaded, setDataLoaded] = useState(false);

  // Calculate comprehensive score (percentage mastery)
  const overallScore = useMemo(() => {
    // Convert 1-10 ratings to percentages (10 = 100%)
    const percentages = Object.values(strengths).map(rating => (rating / 10) * 100);
    const avgPercentage = percentages.reduce((sum, val) => sum + val, 0) / percentages.length;
    
    // Apply status multiplier
    const statusMultiplier = STATUSES.find(s => s.value === status)?.multiplier || 1.0;
    const finalScore = Math.round(avgPercentage * statusMultiplier);
    
    return {
      percentage: Math.min(finalScore, 100),
      byTalent: Object.keys(strengths).reduce((acc, key) => {
        acc[key] = Math.round((strengths[key] / 10) * 100);
        return acc;
      }, {} as Record<string, number>),
    };
  }, [strengths, status]);

  const activeGiftsCount = useMemo(() => Object.values(strengths).filter(v => v >= 6).length, [strengths]);
  
  // Calculate growth for each gift based on monthly consistency
  const calculateGrowthRate = (giftKey: string) => {
    const tasksForGift = monthlyTaskHistory[giftKey] || [];
    const daysInMonth = 30;
    const consistencyRate = tasksForGift.length / daysInMonth;
    
    // Consistency affects growth: 100% consistency = up to 5% monthly growth
    // 50% consistency = up to 2.5% monthly growth
    const potentialGrowth = consistencyRate * 5;
    return Math.round(potentialGrowth * 10) / 10; // Round to 1 decimal
  };
  
  // Apply growth to scores based on monthly consistency
  const applyMonthlyGrowth = () => {
    const updatedStrengths = { ...strengths };
    const updatedScores = { ...overallScore.byTalent };
    
    Object.keys(strengths).forEach(giftKey => {
      const initialScore = initialScores[giftKey] || strengths[giftKey];
      const currentPercentage = (initialScore / 10) * 100;
      const growthRate = calculateGrowthRate(giftKey);
      
      // Calculate new percentage
      const newPercentage = Math.min(currentPercentage + growthRate, 100);
      const newRating = Math.round((newPercentage / 100) * 10);
      
      updatedStrengths[giftKey] = newRating;
      updatedScores[giftKey] = Math.round(newPercentage);
    });
    
    return { updatedStrengths, updatedScores };
  };
  
  // Determine spiritual career based on top strengths
  const spiritualCareer = useMemo(() => {
    const topStrengths = STRENGTH_KEYS
      .map(s => ({ ...s, score: strengths[s.key] }))
      .sort((a, b) => b.score - a.score)
      .slice(0, 3);
    
    const dominantCategory = topStrengths[0]?.category || 'service';
    const score = overallScore.percentage;
    
    // Get career definitions from loaded data
    const careerOptions = CAREER_DEFINITIONS_DATA[dominantCategory] || CAREER_DEFINITIONS_DATA.service || [];
    let selectedCareer;
    
    if (score >= 90) {
      selectedCareer = careerOptions[0]; // Master level
    } else if (score >= 70) {
      selectedCareer = careerOptions[1]; // Advanced level
    } else {
      selectedCareer = careerOptions[2]; // Growing level
    }
    
    return {
      ...selectedCareer,
      topStrengths: topStrengths.slice(0, 3),
      level: score >= 90 ? 'Master' : score >= 70 ? 'Advanced' : score >= 50 ? 'Developing' : 'Emerging',
    };
  }, [strengths, overallScore]);

  // Get relevant daily tasks based on career category
  const dailyTasksForCareer = useMemo(() => {
    if (!hasCompletedAssessment || !dataLoaded) return [];
    
    const topStrengths = STRENGTH_KEYS
      .map(s => ({ ...s, score: strengths[s.key] }))
      .sort((a, b) => b.score - a.score)
      .slice(0, 3);
    
    const dominantCategory = topStrengths[0]?.category || 'service';
    const tasks = DAILY_TASKS_DATA[dominantCategory] || [];
    
    // Also include some tasks from secondary strength
    const secondaryCategory = topStrengths[1]?.category;
    if (secondaryCategory && secondaryCategory !== dominantCategory) {
      const secondaryTasks = DAILY_TASKS_DATA[secondaryCategory]?.slice(0, 2) || [];
      return [...tasks, ...secondaryTasks];
    }
    
    return tasks;
  }, [hasCompletedAssessment, strengths, dataLoaded]);

  // Load data from service on mount
  useEffect(() => {
    const loadData = async () => {
      try {
        // Try to load static config from API first, fallback to local service
        let configData;
        try {
          const configResponse = await apiClient.get(endpoints.spiritualCareer.config);
          if (configResponse.success && configResponse.data) {
            configData = configResponse.data as any;
            console.log('✅ Loaded config from API');
          }
        } catch (error) {
          console.log('⚠️ API config not available, using local service');
        }

        // Use API data if available, otherwise load from local service
        if (configData) {
          STATUSES = configData.statuses || [];
          STRENGTH_KEYS = configData.gifts || [];
          DAILY_TASKS_DATA = configData.dailyTasks || {};
          CAREER_DEFINITIONS_DATA = configData.careers || {};
        } else {
          // Fallback to local service
          const [statuses, strengths, tasks, careers] = await Promise.all([
            SpiritualCareerDataService.getStatusOptions(),
            SpiritualCareerDataService.getStrengthDefinitions(),
            SpiritualCareerDataService.getAllDailyTasks(),
            SpiritualCareerDataService.getCareerDefinitions(),
          ]);
          
          STATUSES = statuses;
          STRENGTH_KEYS = strengths;
          DAILY_TASKS_DATA = tasks;
          CAREER_DEFINITIONS_DATA = careers;
        }
        
        setDataLoaded(true);
        
        // Load user's saved progress from dedicated API
        const progressResponse = await apiClient.get(endpoints.spiritualCareer.progress);
        
        if (progressResponse.success && progressResponse.data) {
          const savedProgress = progressResponse.data as any;
          
          if (savedProgress.status) setStatus(savedProgress.status);
          if (savedProgress.strengths) {
            setStrengths(savedProgress.strengths);
            setHasCompletedAssessment(true);
            setHasRevealedCareer(true);
            setStep(5); // Go directly to career dashboard
          }
          if (savedProgress.initialScores) setInitialScores(savedProgress.initialScores);
          if (savedProgress.completedTasks) setCompletedTasks(new Set(savedProgress.completedTasks));
          if (savedProgress.dailyPoints) setDailyPoints(savedProgress.dailyPoints);
          if (savedProgress.monthlyTaskHistory) setMonthlyTaskHistory(savedProgress.monthlyTaskHistory);
          if (savedProgress.consistencyStreak) setConsistencyStreak(savedProgress.consistencyStreak);
        }
      } catch (error: any) {
        // 404 is expected if user hasn't completed assessment yet
        if (error?.message !== 'Resource not found.') {
          console.error('Error loading spiritual career data:', error);
        }
      } finally {
        setIsLoading(false);
      }
    };
    loadData();
  }, []);

  const handleRateStrength = (strengthKey: string, rating: number) => {
    setStrengths(prev => ({ ...prev, [strengthKey]: rating }));
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    
    // Auto-advance to next strength
    setTimeout(() => {
      if (currentStrengthIndex < STRENGTH_KEYS.length - 1) {
        setCurrentStrengthIndex(prev => prev + 1);
      } else {
        // Move to quiz step
        handleStartQuiz();
      }
    }, 300);
  };

  const handleStartQuiz = () => {
    // Get top 5 rated strengths
    const sortedStrengths = STRENGTH_KEYS
      .map(s => ({ ...s, score: strengths[s.key] || 0 }))
      .sort((a, b) => b.score - a.score)
      .slice(0, 5);
    
    setTopStrengthsForQuiz(sortedStrengths);
    setCurrentQuizIndex(0);
    setCurrentQuestionIndex(0);
    setStep(3);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  const handleAnswerQuiz = (value: number) => {
    const currentStrength = topStrengthsForQuiz[currentQuizIndex];
    const strengthKey = currentStrength.key;
    
    setQuizAnswers(prev => {
      const answers = prev[strengthKey] || [];
      const newAnswers = [...answers];
      newAnswers[currentQuestionIndex] = value;
      return { ...prev, [strengthKey]: newAnswers };
    });
    
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    
    // Auto-advance
    setTimeout(() => {
      if (currentQuestionIndex < currentStrength.questions.length - 1) {
        // Next question for same strength
        setCurrentQuestionIndex(prev => prev + 1);
      } else if (currentQuizIndex < topStrengthsForQuiz.length - 1) {
        // Next strength
        setCurrentQuizIndex(prev => prev + 1);
        setCurrentQuestionIndex(0);
      } else {
        // All done - calculate final scores
        handleCompleteQuiz();
      }
    }, 300);
  };

  const handleCompleteQuiz = () => {
    // Fine-tune scores based on quiz answers
    const adjustedStrengths = { ...strengths };
    
    topStrengthsForQuiz.forEach(strength => {
      const answers = quizAnswers[strength.key] || [];
      const avgAnswer = answers.reduce((sum, val) => sum + val, 0) / answers.length;
      
      // Adjust the rating based on quiz responses (0-4 scale)
      // If they answered mostly "Always" (4), keep rating
      // If they answered lower, adjust the rating proportionally
      const quizFactor = avgAnswer / 4; // 0 to 1
      const originalRating = strengths[strength.key] || 0;
      adjustedStrengths[strength.key] = Math.round(originalRating * (0.5 + quizFactor * 0.5));
    });
    
    setStrengths(adjustedStrengths);
    // Store initial scores for growth tracking
    setInitialScores({ ...adjustedStrengths });
    setStep(4);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  // Calculate encouragement message based on quiz responses
  const getEncouragementMessage = () => {
    const allAnswers = Object.values(quizAnswers).flat();
    if (allAnswers.length === 0) return '';
    
    const avgAnswer = allAnswers.reduce((sum, val) => sum + val, 0) / allAnswers.length;
    
    // Count frequency of each response type
    const counts = allAnswers.reduce((acc, val) => {
      acc[val] = (acc[val] || 0) + 1;
      return acc;
    }, {} as Record<number, number>);
    
    const mostFrequent = Object.entries(counts).sort((a, b) => b[1] - a[1])[0];
    const dominantResponse = parseInt(mostFrequent[0]);
    
    if (avgAnswer >= 3.5) {
      return "🌟 Excellent! You're consistently living out these strengths. Keep up the great work!";
    } else if (avgAnswer >= 2.5) {
      return "💪 You're on the right track! There's room to grow stronger in these areas.";
    } else if (avgAnswer >= 1.5) {
      return "🌱 You're developing! Focus on small, consistent steps to strengthen these areas.";
    } else {
      return "🔥 Time to ignite! These strengths are waiting to be awakened in your life.";
    }
  };

  const handlePreviousStrength = () => {
    if (currentStrengthIndex > 0) {
      setCurrentStrengthIndex(prev => prev - 1);
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
  };

  const handlePreviousQuiz = () => {
    if (currentQuestionIndex > 0) {
      setCurrentQuestionIndex(prev => prev - 1);
    } else if (currentQuizIndex > 0) {
      setCurrentQuizIndex(prev => prev - 1);
      const prevStrength = topStrengthsForQuiz[currentQuizIndex - 1];
      setCurrentQuestionIndex(prevStrength.questions.length - 1);
    }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  };

  const handleSave = async () => {
    setIsSaving(true);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    try {
      const response = await apiClient.post(endpoints.spiritualCareer.submit, {
        score: overallScore.percentage,
        gameId: 'sp_career',
        meta: {
          status,
          strengths,
          initialScores,
          giftScores: overallScore.byTalent,
          career: {
            title: spiritualCareer.title,
            description: spiritualCareer.description,
            level: spiritualCareer.level,
            icon: spiritualCareer.icon,
          },
          completedTasks: Array.from(completedTasks),
          dailyPoints,
          monthlyTaskHistory,
          consistencyStreak,
          completedAt: new Date().toISOString(),
        },
      });
      
      if (response.success) {
        // Update game personal best so GameScreen shows correct value
        await gameStore.submitScore('sp_career', overallScore.percentage);
        toast.success('✨ Progress saved!');
      } else {
        toast.error(response.message || 'Failed to save progress');
      }
    } catch (error) {
      console.error('Error saving spiritual career data:', error);
      toast.error('Failed to save progress');
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
    } finally {
      setIsSaving(false);
    }
  };


  const handleViewCareer = () => {
    setHasRevealedCareer(true);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  const handleStartDailyTasks = async () => {
    await handleSave();
    setHasCompletedAssessment(true);
    setStep(5);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  // Monthly growth recalculation (can be triggered by backend or scheduled task)
  const handleMonthlyGrowthUpdate = async () => {
    const { updatedStrengths, updatedScores } = applyMonthlyGrowth();
    
    // Update local state
    setStrengths(updatedStrengths);
    
    // Save updated scores to backend
    try {
      const response = await apiClient.post(endpoints.spiritualCareer.submit, {
        score: overallScore.percentage,
        gameId: 'sp_career',
        meta: {
          status,
          strengths: updatedStrengths,
          initialScores,
          giftScores: updatedScores,
          career: {
            title: spiritualCareer.title,
            description: spiritualCareer.description,
            level: spiritualCareer.level,
            icon: spiritualCareer.icon,
          },
          completedTasks: Array.from(completedTasks),
          dailyPoints,
          monthlyTaskHistory,
          consistencyStreak,
          growthApplied: true,
          lastGrowthUpdate: new Date().toISOString(),
          completedAt: new Date().toISOString(),
        },
      });
      
      if (response.success) {
        // Keep personal best in sync when monthly growth recalculates the score
        await gameStore.submitScore('sp_career', overallScore.percentage);
        toast.success('🌱 Monthly growth applied! Your gifts are maturing.');
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      } else {
        toast.error(response.message || 'Failed to apply growth update');
      }
    } catch (error) {
      console.error('Error applying monthly growth:', error);
      toast.error('Failed to apply growth update');
    }
  };

  const handleToggleTask = async (taskId: string, weight: number, category: string) => {
    const newCompleted = new Set(completedTasks);
    let newPoints = dailyPoints;
    const today = new Date().toISOString().split('T')[0];
    
    if (newCompleted.has(taskId)) {
      newCompleted.delete(taskId);
      newPoints -= weight;
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    } else {
      newCompleted.add(taskId);
      newPoints += weight;
      
      // Track task completion for growth calculation
      const newHistory = { ...monthlyTaskHistory };
      if (!newHistory[category]) newHistory[category] = [];
      if (!newHistory[category].includes(today)) {
        newHistory[category].push(today);
      }
      setMonthlyTaskHistory(newHistory);
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success(`+${weight} points! 🌱`);
    }
    
    setCompletedTasks(newCompleted);
    setDailyPoints(newPoints);
    
    // Auto-save progress
    try {
      await apiClient.post(endpoints.spiritualCareer.submit, {
        score: overallScore.percentage,
        gameId: 'sp_career',
        meta: {
          status,
          strengths,
          initialScores,
          career: {
            title: spiritualCareer.title,
            description: spiritualCareer.description,
            level: spiritualCareer.level,
            icon: spiritualCareer.icon,
          },
          completedTasks: Array.from(newCompleted),
          dailyPoints: newPoints,
          monthlyTaskHistory,
          consistencyStreak,
          giftScores: overallScore.byTalent,
          completedAt: new Date().toISOString(),
        },
      });
    } catch (error) {
      console.error('Error auto-saving task progress:', error);
    }
  };

  const handleRetakeAssessment = () => {
    setStep(1);
    setStatus(null);
    setStrengths({});
    setInitialScores({});
    setCompletedTasks(new Set());
    setDailyPoints(0);
    setMonthlyTaskHistory({});
    setConsistencyStreak(0);
    setCurrentStrengthIndex(0);
    setTopStrengthsForQuiz([]);
    setCurrentQuizIndex(0);
    setCurrentQuestionIndex(0);
    setQuizAnswers({});
    setHasRevealedCareer(false);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
  };

  if (isLoading || !dataLoaded) {
    return (
      <View style={[styles.container, { justifyContent: 'center', alignItems: 'center' }]}>
        <Brain size={48} color={theme?.colors.primary} />
        <ActivityIndicator size="large" color={theme?.colors.primary} style={{ marginTop: 16 }} />
        <Text style={[styles.subtitle, { marginTop: 12 }]}>Loading your progress...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.headerRow}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}>
          <ChevronLeft size={20} color={theme?.colors.text.primary} />
        </TouchableOpacity>
        <View style={styles.titleRow}>
          <Brain size={20} color={theme?.colors.primary} />
          <Text style={styles.title}>Kingdom Calling</Text>
        </View>
      </View>

      {/* Disclaimer - Always visible */}
      <Animated.View entering={FadeIn.duration(600)} style={styles.disclaimerBox}>
        <View style={styles.disclaimerHeader}>
          <InfoCircle size={20} color={theme?.colors.warning || theme?.colors.primary} />
          <Text style={styles.disclaimerTitle}>Spiritual Exercise</Text>
        </View>
        <Text style={styles.disclaimerText}>
          Discover your Kingdom calling and bear fruit daily. Your gifts are from God - steward them well for His glory and the advancement of His Kingdom.
        </Text>
      </Animated.View>

      {/* Step indicator */}
      <View style={styles.stepsRow}>
        <StepPill active={step === 1} label="1. Status" />
        <StepPill active={step === 2} label="2. Rate" />
        <StepPill active={step === 3} label="3. Quiz" />
        <StepPill active={step === 4} label="4. Score" />
        <StepPill active={step === 5} label="5. Career" />
      </View>

      {step === 1 && (
        <Animated.View entering={FadeInDown.duration(400)} style={styles.card}>
          <LinearGradient
            colors={[`${theme?.colors.primary}05`, 'transparent']}
            style={styles.cardGradient}
          />
          <View style={styles.cardHeader}>
            <View style={styles.iconBadge}>
              <Brain size={24} color={theme?.colors.primary} />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.cardTitle}>What's your current season?</Text>
              <Text style={styles.subtitle}>Your life season shapes how your gifts bear fruit.</Text>
            </View>
          </View>
          <View style={styles.chipsWrap}>
            {STATUSES.map((s, idx) => (
              <Animated.View key={s.value} entering={FadeInDown.delay(idx * 50).duration(300)}>
                <TouchableOpacity
                  style={[styles.chip, status === s.value && styles.chipActive]}
                  onPress={() => {
                    setStatus(s.value);
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
                  }}
                  activeOpacity={0.7}
                >
                  <Text style={styles.statusEmoji}>{s.emoji}</Text>
                  <Text style={[styles.chipText, status === s.value && styles.chipTextActive]}>{s.label}</Text>
                </TouchableOpacity>
              </Animated.View>
            ))}
          </View>
          <TouchableOpacity
            disabled={!status}
            onPress={() => {
              setStep(2);
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
            }}
            style={[styles.primaryBtn, !status && { opacity: 0.5 }]}
          >
            <Text style={styles.primaryBtnText}>Continue</Text>
            <ChevronRight size={16} color={'#fff'} />
          </TouchableOpacity>
        </Animated.View>
      )}

      {step === 2 && (
        <Animated.View entering={FadeInDown.duration(400)} style={styles.card}>
          <LinearGradient
            colors={[`${theme?.colors.primary}05`, 'transparent']}
            style={styles.cardGradient}
          />
          <View style={styles.cardHeader}>
            <View style={styles.iconBadge}>
              <Text style={{ fontSize: 24 }}>{STRENGTH_KEYS[currentStrengthIndex].icon}</Text>
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.cardTitle}>{STRENGTH_KEYS[currentStrengthIndex].label}</Text>
              <Text style={styles.subtitle}>Gift {currentStrengthIndex + 1} of {STRENGTH_KEYS.length}</Text>
            </View>
          </View>

          {/* Progress bar */}
          <View style={styles.progressBarContainer}>
            <View style={[styles.progressBarFill, { width: `${((currentStrengthIndex + 1) / STRENGTH_KEYS.length) * 100}%` }]} />
          </View>

          {/* Description */}
          <Text style={styles.strengthDescription}>{STRENGTH_KEYS[currentStrengthIndex].description}</Text>

          {/* Rating scale */}
          <Text style={styles.ratingLabel}>How developed is this gift in your life? (1-10)</Text>
          <View style={styles.ratingRow}>
            {Array.from({ length: 10 }).map((_, i) => {
              const rating = i + 1;
              const isSelected = strengths[STRENGTH_KEYS[currentStrengthIndex].key] === rating;
              return (
                <TouchableOpacity
                  key={rating}
                  style={[styles.ratingButton, isSelected && styles.ratingButtonActive]}
                  onPress={() => handleRateStrength(STRENGTH_KEYS[currentStrengthIndex].key, rating)}
                  activeOpacity={0.7}
                >
                  <Text style={[styles.ratingButtonText, isSelected && styles.ratingButtonTextActive]}>{rating}</Text>
                </TouchableOpacity>
              );
            })}
          </View>

          {/* Navigation */}
          {currentStrengthIndex > 0 && (
            <TouchableOpacity
              onPress={handlePreviousStrength}
              style={styles.secondaryBtn}
            >
              <ChevronLeft size={16} color={theme?.colors.primary} />
              <Text style={styles.secondaryBtnText}>Previous</Text>
            </TouchableOpacity>
          )}
        </Animated.View>
      )}

      {step === 3 && topStrengthsForQuiz.length > 0 && (
        <Animated.View entering={FadeInDown.duration(400)} style={styles.card}>
          <LinearGradient
            colors={[`${theme?.colors.primary}08`, `${theme?.colors.success}05`, 'transparent']}
            style={styles.cardGradient}
          />
          <View style={styles.cardHeader}>
            <View style={styles.iconBadge}>
              <Sparkle size={24} color={theme?.colors.primary} />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.cardTitle}>Quick Quiz</Text>
              <Text style={styles.subtitle}>
                Question {(currentQuizIndex * 4) + currentQuestionIndex + 1} of {topStrengthsForQuiz.length * 4}
              </Text>
            </View>
          </View>

          {/* Progress bar */}
          <View style={styles.progressBarContainer}>
            <View style={[styles.progressBarFill, { 
              width: `${((currentQuizIndex * 4 + currentQuestionIndex + 1) / (topStrengthsForQuiz.length * 4)) * 100}%` 
            }]} />
          </View>

          {/* Question */}
          <Animated.View entering={FadeIn.duration(300)} style={styles.questionCard}>
            <Text style={styles.questionText}>
              {topStrengthsForQuiz[currentQuizIndex].questions[currentQuestionIndex].question}
            </Text>
            <View style={styles.answerRow}>
              {[
                { value: 0, label: 'Not at all', emoji: '❌' },
                { value: 1, label: 'Rarely', emoji: '😐' },
                { value: 2, label: 'Sometimes', emoji: '🙂' },
                { value: 3, label: 'Often', emoji: '😊' },
                { value: 4, label: 'Always', emoji: '✨' },
              ].map((option) => {
                const currentAnswers = quizAnswers[topStrengthsForQuiz[currentQuizIndex].key] || [];
                const isSelected = currentAnswers[currentQuestionIndex] === option.value;
                return (
                  <TouchableOpacity
                    key={option.value}
                    style={[
                      styles.answerOption,
                      isSelected && styles.answerOptionSelected,
                    ]}
                    onPress={() => handleAnswerQuiz(option.value)}
                    activeOpacity={0.7}
                  >
                    <Text style={styles.answerEmoji}>{option.emoji}</Text>
                    <Text style={[
                      styles.answerLabel,
                      isSelected && styles.answerLabelSelected,
                    ]}>{option.label}</Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </Animated.View>

          {/* Navigation */}
          {(currentQuizIndex > 0 || currentQuestionIndex > 0) && (
            <TouchableOpacity
              onPress={handlePreviousQuiz}
              style={styles.secondaryBtn}
            >
              <ChevronLeft size={16} color={theme?.colors.primary} />
              <Text style={styles.secondaryBtnText}>Previous</Text>
            </TouchableOpacity>
          )}
        </Animated.View>
      )}

      {step === 4 && (
        <Animated.View entering={FadeInDown.duration(400)} style={styles.card}>
          <LinearGradient
            colors={[`${theme?.colors.primary}08`, `${theme?.colors.success}05`, 'transparent']}
            style={styles.cardGradient}
          />
          <View style={styles.cardHeader}>
            <View style={styles.iconBadge}>
              <Trophy size={24} color={theme?.colors.primary} />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.cardTitle}>Your Kingdom Profile</Text>
              <Text style={styles.subtitle}>Gifts identified for Kingdom impact</Text>
            </View>
          </View>

          {/* Score Display */}
          <Animated.View entering={FadeIn.delay(200)} style={styles.scoreCard}>
            <LinearGradient
              colors={[`${theme?.colors.primary}15`, `${theme?.colors.success}10`]}
              style={styles.resultGradient}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
            />
            <View style={styles.scoreContent}>
              <Text style={styles.scoreLabel}>Overall Mastery</Text>
              <Text style={styles.scoreValue}>{overallScore.percentage}%</Text>
              <View style={styles.scoreBar}>
                <View style={[styles.scoreBarFill, { width: `${Math.min(overallScore.percentage, 100)}%` }]} />
              </View>
              <Text style={styles.scoreSubtext}>Overall Mastery • {spiritualCareer.level} Level</Text>
            </View>
          </Animated.View>

          {/* Status Multiplier Info */}
          <Animated.View entering={FadeIn.delay(300)} style={styles.infoCard}>
            <Text style={styles.infoLabel}>Season Multiplier</Text>
            <View style={styles.infoRow}>
              <Text style={styles.infoEmoji}>{STATUSES.find(s => s.value === status)?.emoji}</Text>
              <Text style={styles.infoText}>{STATUSES.find(s => s.value === status)?.label}</Text>
              <View style={styles.multiplierBadge}>
                <Text style={styles.multiplierText}>×{STATUSES.find(s => s.value === status)?.multiplier}</Text>
              </View>
            </View>
          </Animated.View>

          {/* Encouragement Message */}
          <Animated.View entering={FadeIn.delay(300)} style={styles.encouragementCard}>
            <Text style={styles.encouragementText}>{getEncouragementMessage()}</Text>
          </Animated.View>

          {/* Top 3 Gifts */}
          <Text style={styles.sectionTitle}>Your Primary Gifts</Text>
          <View style={{ gap: 10 }}>
            {spiritualCareer.topStrengths.map((strength, idx) => (
              <Animated.View key={strength.key} entering={FadeInDown.delay(400 + idx * 80).duration(300)}>
                <View style={styles.strengthCard}>
                  <Text style={styles.strengthEmoji}>{strength.icon}</Text>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.strengthCardLabel}>{strength.label}</Text>
                    <View style={styles.strengthProgressBar}>
                      <View style={[styles.strengthProgressFill, { width: `${strength.score * 10}%` }]} />
                    </View>
                  </View>
                  <Text style={styles.strengthScore}>{strength.score}/10</Text>
                </View>
              </Animated.View>
            ))}
          </View>

          <TouchableOpacity
            onPress={handleViewCareer}
            style={styles.primaryBtn}
          >
            <Text style={styles.primaryBtnText}>Reveal My Kingdom Calling</Text>
            <Sparkle size={16} color={'#fff'} />
          </TouchableOpacity>
        </Animated.View>
      )}

      {step === 4 && hasRevealedCareer && (
        <Animated.View entering={FadeInDown.duration(400)} style={styles.card}>
          <LinearGradient
            colors={[`${theme?.colors.primary}08`, `${theme?.colors.success}05`, 'transparent']}
            style={styles.cardGradient}
          />
          <View style={styles.cardHeader}>
            <View style={styles.iconBadge}>
              <Trophy size={24} color={theme?.colors.primary} />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.cardTitle}>Your Spiritual Career</Text>
              <Text style={styles.subtitle}>Crafted for your unique calling</Text>
            </View>
          </View>

          {/* Career Title Card */}
          <Animated.View entering={FadeIn.delay(200)} style={styles.careerTitleCard}>
            <LinearGradient
              colors={[`${theme?.colors.primary}20`, `${theme?.colors.success}15`]}
              style={styles.resultGradient}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
            />
            <Text style={styles.careerEmoji}>{spiritualCareer.icon}</Text>
            <Text style={styles.careerTitle}>{spiritualCareer.title}</Text>
            <View style={styles.levelBadge}>
              <Star size={14} color={theme?.colors.primary} filled />
              <Text style={styles.levelText}>{spiritualCareer.level} Level</Text>
            </View>
          </Animated.View>

          {/* Job Description */}
          <Animated.View entering={FadeIn.delay(300)} style={styles.descriptionCard}>
            <Text style={styles.descriptionLabel}>Your Calling</Text>
            <Text style={styles.descriptionText}>{spiritualCareer.description}</Text>
          </Animated.View>

          <Text style={styles.sectionTitle}>Core Gifts</Text>
          <View style={styles.chipsWrap}>
            {spiritualCareer.topStrengths.map((strength, idx) => (
              <Animated.View key={strength.key} entering={FadeInDown.delay(400 + idx * 50).duration(300)}>
                <View style={[styles.chip, styles.chipActive]}> 
                  <Text style={styles.statusEmoji}>{strength.icon}</Text>
                  <Text style={styles.chipTextActive}>{strength.label}</Text>
                  <Text style={styles.chipScore}>{strength.score}</Text>
                </View>
              </Animated.View>
            ))}
          </View>

          <TouchableOpacity
            onPress={handleStartDailyTasks}
            style={styles.primaryBtn}
            disabled={isSaving}
          >
            {isSaving ? (
              <ActivityIndicator size="small" color="#fff" />
            ) : (
              <>
                <Text style={styles.primaryBtnText}>Begin Bearing Fruit</Text>
                <ChevronRight size={16} color={'#fff'} />
              </>
            )}
          </TouchableOpacity>
        </Animated.View>
      )}

      {step === 5 && (
        <Animated.View entering={FadeInDown.duration(400)} style={styles.card}>
          <LinearGradient
            colors={[`${theme?.colors.primary}08`, `${theme?.colors.success}05`, 'transparent']}
            style={styles.cardGradient}
          />
          <View style={styles.cardHeader}>
            <View style={styles.iconBadge}>
              <Trophy size={24} color={theme?.colors.primary} />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.cardTitle}>Your Spiritual Career</Text>
              <Text style={styles.subtitle}>Crafted for your unique calling</Text>
            </View>
          </View>

          {/* Career Title Card */}
          <Animated.View entering={FadeIn.delay(200)} style={styles.careerTitleCard}>
            <LinearGradient
              colors={[`${theme?.colors.primary}20`, `${theme?.colors.success}15`]}
              style={styles.resultGradient}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
            />
            <Text style={styles.careerEmoji}>{spiritualCareer.icon}</Text>
            <Text style={styles.careerTitle}>{spiritualCareer.title}</Text>
            <View style={styles.levelBadge}>
              <Star size={14} color={theme?.colors.primary} filled />
              <Text style={styles.levelText}>{spiritualCareer.level} Level</Text>
            </View>
          </Animated.View>

          {/* Job Description */}
          <Animated.View entering={FadeIn.delay(300)} style={styles.descriptionCard}>
            <Text style={styles.descriptionLabel}>Your Calling</Text>
            <Text style={styles.descriptionText}>{spiritualCareer.description}</Text>
          </Animated.View>

          <Text style={styles.sectionTitle}>Core Gifts</Text>
          <View style={styles.chipsWrap}>
            {spiritualCareer.topStrengths.map((strength, idx) => (
              <Animated.View key={strength.key} entering={FadeInDown.delay(400 + idx * 50).duration(300)}>
                <View style={[styles.chip, styles.chipActive]}> 
                  <Text style={styles.statusEmoji}>{strength.icon}</Text>
                  <Text style={styles.chipTextActive}>{strength.label}</Text>
                  <Text style={styles.chipScore}>{strength.score}</Text>
                </View>
              </Animated.View>
            ))}
          </View>

          {/* Daily Score Card */}
          <Animated.View entering={FadeIn.delay(500)} style={styles.dailyScoreCard}>
            <View style={styles.dailyScoreHeader}>
              <Text style={styles.dailyScoreLabel}>Today's Fruit</Text>
              <View style={styles.dailyScoreBadge}>
                <Trophy size={14} color={'#fff'} />
                <Text style={styles.dailyScoreValue}>+{dailyPoints}</Text>
              </View>
            </View>
            <Text style={styles.dailyScoreSubtext}>{completedTasks.size} of {dailyTasksForCareer.length} tasks completed</Text>
          </Animated.View>

          <Text style={styles.sectionTitle}>Daily Fruit-Bearing Tasks</Text>
          <Text style={styles.subtitle}>Complete tasks to bear fruit and develop your gifts</Text>
          <View style={{ gap: 10 }}>
            {dailyTasksForCareer.map((task, idx) => {
              const isCompleted = completedTasks.has(task.id);
              return (
                <Animated.View key={task.id} entering={FadeInDown.delay(600 + idx * 60).duration(300)}>
                  <TouchableOpacity
                    style={[styles.taskCard, isCompleted && styles.taskCardCompleted]}
                    onPress={() => handleToggleTask(task.id, task.weight, task.category)}
                    activeOpacity={0.7}
                  >
                    <View style={[styles.taskCheckbox, isCompleted && styles.taskCheckboxCompleted]}>
                      {isCompleted && <Star size={16} color={'#fff'} filled />}
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text style={[styles.taskText, isCompleted && styles.taskTextCompleted]}>{task.text}</Text>
                    </View>
                    <View style={styles.taskWeightBadge}>
                      <Text style={styles.taskWeightText}>{task.weight}pt</Text>
                    </View>
                  </TouchableOpacity>
                </Animated.View>
              );
            })}
          </View>

          {/* Action buttons */}
          <View style={{ gap: 8, marginTop: 16 }}>
            <TouchableOpacity 
              onPress={handleRetakeAssessment} 
              style={styles.secondaryBtn}
            >
              <Text style={styles.secondaryBtnText}>Retake Assessment</Text>
            </TouchableOpacity>
            <TouchableOpacity 
              onPress={() => navigation.navigate('GameScreen')} 
              style={[styles.primaryBtn, { marginTop: 0 }]}
            >
              <Text style={styles.primaryBtnText}>Back to Games</Text>
              <ChevronRight size={16} color={'#fff'} />
            </TouchableOpacity>
          </View>
        </Animated.View>
      )}
    </ScrollView>
  );
};

const StepPill = ({ active, label }: { active: boolean; label: string }) => {
  const theme = useTheme();
  return (
    <View style={[{
      paddingVertical: 6,
      paddingHorizontal: 10,
      borderRadius: 999,
      borderWidth: 1,
      borderColor: active ? theme?.colors.primary : theme?.colors.border,
      backgroundColor: active ? `${theme?.colors.primary}16` : 'transparent',
    }]}
    >
      <Text style={{ color: active ? theme?.colors.primary : theme?.colors.text.secondary, fontSize: 12, fontWeight: '600' }}>{label}</Text>
    </View>
  );
};

const createStyles = (theme: any) => StyleSheet.create({
  container: { flex: 1, backgroundColor: theme?.colors.background },
  content: { padding: theme?.spacing.md, paddingBottom: theme?.spacing.xl },
  headerRow: { flexDirection: 'row', alignItems: 'center', marginBottom: theme?.spacing.sm },
  backBtn: { padding: 6, marginRight: 6 },
  titleRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  title: { fontSize: 20, fontWeight: '800', color: theme?.colors.text.primary },
  stepsRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginVertical: theme?.spacing.sm },

  card: { backgroundColor: theme?.colors.card, borderRadius: 16, padding: 18, borderWidth: 1, borderColor: theme?.colors.border, gap: 16, overflow: 'hidden', position: 'relative' },
  cardGradient: { ...StyleSheet.absoluteFillObject, borderRadius: 16 },
  cardHeader: { flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  iconBadge: { width: 48, height: 48, borderRadius: 24, backgroundColor: `${theme?.colors.primary}15`, alignItems: 'center', justifyContent: 'center' },
  cardTitle: { fontSize: 18, fontWeight: '800', color: theme?.colors.text.primary, marginBottom: 4 },
  subtitle: { fontSize: 13, color: theme?.colors.text.secondary, lineHeight: 18 },

  chipsWrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  chip: { paddingVertical: 8, paddingHorizontal: 14, borderRadius: 999, borderWidth: 1.5, borderColor: theme?.colors.border, backgroundColor: theme?.colors.background, flexDirection: 'row', alignItems: 'center', gap: 6 },
  chipActive: { backgroundColor: `${theme?.colors.primary}15`, borderColor: theme?.colors.primary },
  chipText: { fontSize: 13, color: theme?.colors.text.secondary, fontWeight: '600' },
  chipTextActive: { color: theme?.colors.primary },

  strengthRow: { gap: 10 },
  strengthHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 },
  strengthLabel: { fontSize: 14, fontWeight: '700', color: theme?.colors.text.primary },
  ratingBadge: { backgroundColor: `${theme?.colors.primary}20`, paddingHorizontal: 10, paddingVertical: 4, borderRadius: 12 },
  ratingBadgeText: { fontSize: 13, fontWeight: '800', color: theme?.colors.primary },
  scaleRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  scaleDot: { paddingVertical: 8, paddingHorizontal: 10, borderRadius: 10, backgroundColor: `${theme?.colors.text.secondary}10`, minWidth: 36, alignItems: 'center' },
  scaleDotActive: { backgroundColor: theme?.colors.primary, transform: [{ scale: 1.1 }] },
  scaleText: { fontSize: 12, color: theme?.colors.text.secondary, fontWeight: '700' },
  scaleTextActive: { color: '#fff' },

  primaryBtn: { marginTop: 8, backgroundColor: theme?.colors.primary, paddingVertical: 12, borderRadius: 12, alignItems: 'center', flexDirection: 'row', justifyContent: 'center', gap: 6, shadowColor: theme?.colors.primary, shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.3, shadowRadius: 8, elevation: 4 },
  primaryBtnText: { color: '#fff', fontWeight: '700', fontSize: 15 },
  secondaryBtn: { marginTop: 8, backgroundColor: 'transparent', paddingVertical: 12, borderRadius: 12, alignItems: 'center', flexDirection: 'row', justifyContent: 'center', gap: 6, borderWidth: 1.5, borderColor: theme?.colors.primary },
  secondaryBtnText: { color: theme?.colors.primary, fontWeight: '700', fontSize: 15 },

  sectionTitle: { fontSize: 15, fontWeight: '800', color: theme?.colors.text.primary, marginTop: 8, marginBottom: 12 },
  
  resultCard: { borderRadius: 16, overflow: 'hidden', borderWidth: 1, borderColor: theme?.colors.primary, marginVertical: 8 },
  resultGradient: { ...StyleSheet.absoluteFillObject },
  resultContent: { flexDirection: 'row', alignItems: 'center', gap: 16, padding: 16 },
  resultLabel: { fontSize: 13, color: theme?.colors.text.secondary, fontWeight: '600', marginBottom: 4 },
  resultValue: { fontSize: 32, fontWeight: '800', color: theme?.colors.primary },

  challengeCard: { flexDirection: 'row', alignItems: 'flex-start', gap: 12, backgroundColor: `${theme?.colors.primary}05`, padding: 14, borderRadius: 12, borderWidth: 1, borderColor: `${theme?.colors.primary}20` },
  challengeNumber: { width: 28, height: 28, borderRadius: 14, backgroundColor: theme?.colors.primary, alignItems: 'center', justifyContent: 'center', marginTop: 2 },
  challengeNumberText: { color: '#fff', fontSize: 13, fontWeight: '800' },
  challengeText: { flex: 1, color: theme?.colors.text.primary, fontSize: 14, lineHeight: 20 },

  disclaimerBox: { marginBottom: 16, padding: 16, borderRadius: 12, backgroundColor: `${theme?.colors.warning || theme?.colors.primary}10`, borderWidth: 1.5, borderColor: `${theme?.colors.warning || theme?.colors.primary}30` },
  disclaimerHeader: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 8 },
  disclaimerTitle: { fontWeight: '800', color: theme?.colors.text.primary, fontSize: 15 },
  disclaimerText: { color: theme?.colors.text.secondary, fontSize: 13, lineHeight: 20 },

  // New game-like styles
  statusEmoji: { fontSize: 20, marginRight: 6 },
  
  scoreCard: { borderRadius: 16, overflow: 'hidden', borderWidth: 2, borderColor: theme?.colors.primary, marginVertical: 12 },
  scoreContent: { padding: 20, alignItems: 'center' },
  scoreLabel: { fontSize: 14, color: theme?.colors.text.secondary, fontWeight: '600', marginBottom: 8 },
  scoreValue: { fontSize: 64, fontWeight: '900', color: theme?.colors.primary, marginBottom: 12 },
  scoreBar: { width: '100%', height: 8, backgroundColor: `${theme?.colors.text.secondary}15`, borderRadius: 4, overflow: 'hidden', marginBottom: 8 },
  scoreBarFill: { height: '100%', backgroundColor: theme?.colors.primary, borderRadius: 4 },
  scoreSubtext: { fontSize: 13, color: theme?.colors.text.secondary, fontWeight: '600' },

  infoCard: { backgroundColor: `${theme?.colors.primary}08`, padding: 14, borderRadius: 12, borderWidth: 1, borderColor: `${theme?.colors.primary}20` },
  infoLabel: { fontSize: 12, color: theme?.colors.text.secondary, fontWeight: '700', marginBottom: 8, textTransform: 'uppercase' },
  infoRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  infoEmoji: { fontSize: 24 },
  infoText: { flex: 1, fontSize: 14, color: theme?.colors.text.primary, fontWeight: '600' },
  multiplierBadge: { backgroundColor: theme?.colors.primary, paddingHorizontal: 10, paddingVertical: 4, borderRadius: 12 },
  multiplierText: { color: '#fff', fontSize: 13, fontWeight: '800' },

  strengthCard: { flexDirection: 'row', alignItems: 'center', gap: 12, backgroundColor: `${theme?.colors.primary}05`, padding: 14, borderRadius: 12, borderWidth: 1, borderColor: `${theme?.colors.primary}15` },
  strengthEmoji: { fontSize: 28 },
  strengthCardLabel: { fontSize: 14, fontWeight: '700', color: theme?.colors.text.primary, marginBottom: 6 },
  strengthProgressBar: { height: 6, backgroundColor: `${theme?.colors.text.secondary}15`, borderRadius: 3, overflow: 'hidden' },
  strengthProgressFill: { height: '100%', backgroundColor: theme?.colors.primary, borderRadius: 3 },
  strengthScore: { fontSize: 16, fontWeight: '800', color: theme?.colors.primary },

  careerTitleCard: { borderRadius: 20, overflow: 'hidden', borderWidth: 2, borderColor: theme?.colors.primary, padding: 24, alignItems: 'center', marginVertical: 12 },
  careerEmoji: { fontSize: 64, marginBottom: 12 },
  careerTitle: { fontSize: 24, fontWeight: '900', color: theme?.colors.primary, textAlign: 'center', marginBottom: 12 },
  levelBadge: { flexDirection: 'row', alignItems: 'center', gap: 6, backgroundColor: `${theme?.colors.primary}20`, paddingHorizontal: 14, paddingVertical: 6, borderRadius: 999 },
  levelText: { fontSize: 13, fontWeight: '800', color: theme?.colors.primary },

  descriptionCard: { backgroundColor: `${theme?.colors.primary}05`, padding: 16, borderRadius: 12, borderWidth: 1, borderColor: `${theme?.colors.primary}15`, marginBottom: 12 },
  descriptionLabel: { fontSize: 12, color: theme?.colors.text.secondary, fontWeight: '700', marginBottom: 8, textTransform: 'uppercase' },
  descriptionText: { fontSize: 15, color: theme?.colors.text.primary, lineHeight: 22, fontStyle: 'italic' },

  chipScore: { fontSize: 12, fontWeight: '800', color: theme?.colors.primary, marginLeft: 4 },

  // Daily task styles
  dailyScoreCard: { backgroundColor: `${theme?.colors.success}15`, padding: 16, borderRadius: 12, borderWidth: 1.5, borderColor: `${theme?.colors.success}30`, marginBottom: 16 },
  dailyScoreHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 },
  dailyScoreLabel: { fontSize: 14, fontWeight: '700', color: theme?.colors.text.primary },
  dailyScoreBadge: { flexDirection: 'row', alignItems: 'center', gap: 6, backgroundColor: theme?.colors.success, paddingHorizontal: 12, paddingVertical: 6, borderRadius: 999 },
  dailyScoreValue: { color: '#fff', fontSize: 16, fontWeight: '800' },
  dailyScoreSubtext: { fontSize: 12, color: theme?.colors.text.secondary },

  taskCard: { flexDirection: 'row', alignItems: 'center', gap: 12, backgroundColor: theme?.colors.card, padding: 14, borderRadius: 12, borderWidth: 1.5, borderColor: theme?.colors.border },
  taskCardCompleted: { backgroundColor: `${theme?.colors.success}08`, borderColor: `${theme?.colors.success}30` },
  taskCheckbox: { width: 32, height: 32, borderRadius: 16, borderWidth: 2, borderColor: theme?.colors.border, alignItems: 'center', justifyContent: 'center', backgroundColor: theme?.colors.background },
  taskCheckboxCompleted: { backgroundColor: theme?.colors.success, borderColor: theme?.colors.success },
  taskText: { fontSize: 14, color: theme?.colors.text.primary, lineHeight: 20, flex: 1 },
  taskTextCompleted: { color: theme?.colors.text.secondary, textDecorationLine: 'line-through' },
  taskWeightBadge: { backgroundColor: `${theme?.colors.primary}15`, paddingHorizontal: 10, paddingVertical: 4, borderRadius: 8 },
  taskWeightText: { fontSize: 12, fontWeight: '800', color: theme?.colors.primary },

  // Questionnaire styles
  progressBarContainer: { height: 6, backgroundColor: `${theme?.colors.text.secondary}15`, borderRadius: 3, overflow: 'hidden', marginBottom: 16 },
  progressBarFill: { height: '100%', backgroundColor: theme?.colors.primary, borderRadius: 3 },
  
  questionCard: { backgroundColor: `${theme?.colors.primary}05`, padding: 14, borderRadius: 12, borderWidth: 1, borderColor: `${theme?.colors.primary}15` },
  questionText: { fontSize: 14, color: theme?.colors.text.primary, lineHeight: 20, marginBottom: 12, fontWeight: '600' },
  answerRow: { flexDirection: 'row', gap: 8, flexWrap: 'wrap' },
  answerOption: { flex: 1, minWidth: 80, alignItems: 'center', padding: 10, borderRadius: 10, borderWidth: 1.5, borderColor: theme?.colors.border, backgroundColor: theme?.colors.background },
  answerOptionSelected: { borderColor: theme?.colors.primary, backgroundColor: `${theme?.colors.primary}15` },
  answerEmoji: { fontSize: 20, marginBottom: 4 },
  answerLabel: { fontSize: 11, color: theme?.colors.text.secondary, fontWeight: '600', textAlign: 'center' },
  answerLabelSelected: { color: theme?.colors.primary },

  // Rating styles
  strengthDescription: { fontSize: 14, color: theme?.colors.text.secondary, lineHeight: 20, fontStyle: 'italic', marginBottom: 12 },
  ratingLabel: { fontSize: 13, color: theme?.colors.text.secondary, fontWeight: '600', marginBottom: 10, textAlign: 'center' },
  ratingRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, justifyContent: 'center' },
  ratingButton: { width: 44, height: 44, borderRadius: 22, borderWidth: 2, borderColor: theme?.colors.border, backgroundColor: theme?.colors.background, alignItems: 'center', justifyContent: 'center' },
  ratingButtonActive: { borderColor: theme?.colors.primary, backgroundColor: `${theme?.colors.primary}20` },
  ratingButtonText: { fontSize: 16, fontWeight: '700', color: theme?.colors.text.secondary },
  ratingButtonTextActive: { color: theme?.colors.primary },

  // Encouragement styles
  encouragementCard: { backgroundColor: `${theme?.colors.success}10`, padding: 16, borderRadius: 12, borderWidth: 1.5, borderColor: `${theme?.colors.success}30`, marginBottom: 16 },
  encouragementText: { fontSize: 14, color: theme?.colors.text.primary, lineHeight: 20, fontWeight: '600', textAlign: 'center' },
});

export default SpiritualCareerScreen;
