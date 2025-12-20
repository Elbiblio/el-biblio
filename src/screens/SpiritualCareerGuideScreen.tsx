import React, { useState, useEffect, useMemo, useCallback } from 'react';
import {
  View,
  ScrollView,
  StyleSheet,
  Dimensions,
  StatusBar,
  Text,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '@/contexts/ThemeContext';
import { useChallengeStore } from '@/stores/StoreProvider';
import { toast } from 'sonner-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Haptics from 'expo-haptics';
import { observer } from 'mobx-react-lite';
import { ARCHETYPES, INDUSTRIES, ROLE_TYPES, DISTORTION_TAGS } from '@/constants/spiritualCareer';
import type { Challenge } from '@/types/challenges';

// Step components
import WelcomeStep from '@/components/spiritualCareer/WelcomeStep';
import ArchetypeWheelStep from '@/components/spiritualCareer/ArchetypeWheelStep';
import DistortionSelectorStep from '@/components/spiritualCareer/DistortionSelectorStep';
import ContextSelectionStep from '@/components/spiritualCareer/ContextSelectionStep';
import TasksStep from '@/components/spiritualCareer/TasksStep';
import ResultsStep from '@/components/spiritualCareer/ResultsStep';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');
const MAX_SELECTED_ARCHETYPES = 3;
const STORAGE_KEY = 'spiritual_career_guide_progress';

type Props = NativeStackScreenProps<RootStackParamList, 'SpiritualCareerGuideScreen'>;

export type CareerGuideState = {
  selectedArchetypes: string[];
  selectedIndustry: string | null;
  selectedRoleType: string | null;
  currentStep: 'welcome' | 'archetypes' | 'distortions' | 'context' | 'tasks' | 'results';
  isLoading: boolean;
  suggestedChallenges: Challenge[];
  selectedDistortions: string[];
};

const INITIAL_STATE: CareerGuideState = {
  selectedArchetypes: [],
  selectedIndustry: null,
  selectedRoleType: null,
  currentStep: 'welcome',
  isLoading: false,
  suggestedChallenges: [],
  selectedDistortions: [],
};

const NewSpiritualCareerGuideScreen: React.FC<Props> = observer(({ navigation }) => {
  const insets = useSafeAreaInsets();
  const theme = useTheme();
  const styles = createStyles(theme);
  const challengeStore = useChallengeStore();
  const [state, setState] = useState<CareerGuideState>(INITIAL_STATE);

  // Progress tracking
  const stepProgress = useMemo(() => {
    const steps: CareerGuideState['currentStep'][] = ['welcome', 'distortions', 'archetypes', 'context', 'tasks', 'results'];
    const currentIndex = steps.indexOf(state.currentStep);
    return {
      current: currentIndex + 1,
      total: steps.length,
      percentage: ((currentIndex + 1) / steps.length) * 100,
    };
  }, [state.currentStep]);

  // Load saved progress
  useEffect(() => {
    loadSavedProgress();
  }, []);

  const loadSavedProgress = async () => {
    try {
      const saved = await AsyncStorage.getItem(STORAGE_KEY);
      if (saved) {
        const progress = JSON.parse(saved);
        setState((prev: CareerGuideState) => ({ ...prev, ...progress }));
      }
    } catch (error) {
      console.warn('Failed to load career guide progress:', error);
    }
  };

  const saveProgress = async (newState: CareerGuideState) => {
    try {
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(newState));
    } catch (error) {
      console.warn('Failed to save career guide progress:', error);
    }
  };

  const applyStateUpdate = useCallback((updater: (prev: CareerGuideState) => CareerGuideState) => {
    setState((prev: CareerGuideState) => {
      const next = updater(prev);
      saveProgress(next);
      return next;
    });
  }, []);

  const updateState = useCallback((updates: Partial<CareerGuideState>) => {
    applyStateUpdate((prev: CareerGuideState) => ({ ...prev, ...updates }));
  }, [applyStateUpdate]);

  const distortionMap = useMemo(() => {
    const entries = new Map<string, any>();
    DISTORTION_TAGS.forEach(tag => entries.set(tag.id, tag));
    return entries;
  }, []);

  const recommendedArchetypes = useMemo(() => {
    if (!state.selectedDistortions.length) return [];

    const scores = new Map<string, number>();
    state.selectedDistortions.forEach(tagId => {
      const tag = distortionMap.get(tagId);
      if (!tag) return;
      const weight = 1 / tag.archetypes.length;
      tag.archetypes.forEach((name: string) => {
        scores.set(name, (scores.get(name) || 0) + weight);
      });
    });

    return ARCHETYPES
      .filter(archetype => scores.has(archetype.name))
      .sort((a, b) => (scores.get(b.name)! - scores.get(a.name)!))
      .slice(0, 3);
  }, [state.selectedDistortions, distortionMap]);

  // Navigation handlers
  const handleToggleDistortion = useCallback((tagId: string) => {
    applyStateUpdate((prev: CareerGuideState) => {
      const isSelected = prev.selectedDistortions.includes(tagId);
      const newDistortions = isSelected
        ? prev.selectedDistortions.filter(id => id !== tagId)
        : [...prev.selectedDistortions, tagId];
      return { ...prev, selectedDistortions: newDistortions };
    });
  }, [applyStateUpdate]);

  const applyRecommendedArchetypes = useCallback(() => {
    if (!recommendedArchetypes.length) {
      toast.info('Select a few distortions to generate recommendations.');
      return;
    }
    updateState({
      selectedArchetypes: recommendedArchetypes.map(item => item.name),
      currentStep: 'archetypes',
    });
    toast.success('Recommended archetypes applied');
  }, [recommendedArchetypes, updateState]);

  const handleToggleArchetype = useCallback((index: number) => {
    const archetype = ARCHETYPES[index];
    if (!archetype) return;

    applyStateUpdate((prev: CareerGuideState) => {
      const isSelected = prev.selectedArchetypes.includes(archetype.name);
      let newArchetypes: string[];

      if (isSelected) {
        newArchetypes = prev.selectedArchetypes.filter(name => name !== archetype.name);
      } else {
        if (prev.selectedArchetypes.length >= MAX_SELECTED_ARCHETYPES) {
          toast.error(`You can only select up to ${MAX_SELECTED_ARCHETYPES} archetypes`);
          return prev;
        }
        newArchetypes = [...prev.selectedArchetypes, archetype.name];
      }

      return { ...prev, selectedArchetypes: newArchetypes };
    });

    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
  }, [applyStateUpdate]);

  const handleSelectIndustry = useCallback((industry: string) => {
    applyStateUpdate((prev: CareerGuideState) => ({ ...prev, selectedIndustry: industry }));
  }, [applyStateUpdate]);

  const handleSelectRoleType = useCallback((roleType: string) => {
    applyStateUpdate((prev: CareerGuideState) => ({ ...prev, selectedRoleType: roleType }));
  }, [applyStateUpdate]);

  // Load challenges based on selections
  const loadSuggestedChallenges = useCallback(async () => {
    if (!state.selectedIndustry || !state.selectedRoleType || state.selectedArchetypes.length === 0) {
      return;
    }

    updateState({ isLoading: true });
    
    try {
      if (!challengeStore.personalChallenges.length) {
        await challengeStore.fetchPersonalChallenges(1);
      }
      if (!challengeStore.communityChallenges.length) {
        await challengeStore.fetchCommunityChallenges(1);
      }

      const allChallenges = [
        ...challengeStore.personalChallenges,
        ...challengeStore.communityChallenges,
      ];
      const contextNeedle = `${state.selectedIndustry} ${state.selectedRoleType}`.toLowerCase();
      const distortionNeedles = state.selectedDistortions
        .map(id => distortionMap.get(id)?.label.toLowerCase())
        .filter(Boolean) as string[];

      const relevantChallenges = allChallenges.filter(challenge => {
        const searchText = `${challenge.title ?? ''} ${challenge.description ?? ''} ${challenge.theme_name ?? ''}`.toLowerCase();

        const archetypeMatch = state.selectedArchetypes.some(name => searchText.includes(name.toLowerCase()));
        const contextMatch = contextNeedle.trim().length
          ? searchText.includes(state.selectedIndustry!.toLowerCase()) ||
            searchText.includes(state.selectedRoleType!.toLowerCase())
          : true;
        const distortionMatch = distortionNeedles.length
          ? distortionNeedles.some(term => searchText.includes(term))
          : true;

        return archetypeMatch && contextMatch && distortionMatch;
      });

      updateState({ 
        suggestedChallenges: (relevantChallenges.length ? relevantChallenges : allChallenges).slice(0, 6),
        isLoading: false 
      });
    } catch (error) {
      console.error('Failed to load suggested challenges:', error);
      updateState({ isLoading: false });
      toast.error('Failed to load suggested challenges');
    }
  }, [
    state.selectedIndustry,
    state.selectedRoleType,
    state.selectedArchetypes,
    state.selectedDistortions,
    challengeStore,
    distortionMap,
    updateState,
  ]);

  // Navigation step handlers
  const handleNextStep = useCallback(() => {
    const stepOrder: CareerGuideState['currentStep'][] = ['welcome', 'distortions', 'archetypes', 'context', 'tasks', 'results'];
    const currentIndex = stepOrder.indexOf(state.currentStep);
    if (currentIndex < stepOrder.length - 1) {
      updateState({ currentStep: stepOrder[currentIndex + 1] });
    }
  }, [state.currentStep, updateState]);

  const handlePreviousStep = useCallback(() => {
    const stepOrder: CareerGuideState['currentStep'][] = ['welcome', 'distortions', 'archetypes', 'context', 'tasks', 'results'];
    const currentIndex = stepOrder.indexOf(state.currentStep);
    if (currentIndex > 0) {
      updateState({ currentStep: stepOrder[currentIndex - 1] });
    }
  }, [state.currentStep, updateState]);

  const handleGoToDistortions = useCallback(() => {
    updateState({ currentStep: 'distortions' });
  }, [updateState]);

  const handleGoToArchetypes = useCallback(() => {
    updateState({ currentStep: 'archetypes' });
  }, [updateState]);

  const handleGoToContext = useCallback(() => {
    updateState({ currentStep: 'context' });
  }, [updateState]);

  const handleGoToTasks = useCallback(() => {
    updateState({ currentStep: 'tasks' });
  }, [updateState]);

  const handleGoToResults = useCallback(() => {
    updateState({ currentStep: 'results' });
  }, [updateState]);

  const handleViewChallenges = useCallback(() => {
    navigation.navigate('DailyChallengeScreen' as any);
  }, [navigation]);

  const handleBackToHome = useCallback(() => {
    navigation.goBack();
  }, [navigation]);

  // Load challenges when entering tasks step
  useEffect(() => {
    if (state.currentStep === 'tasks' && state.selectedIndustry && state.selectedRoleType && state.selectedArchetypes.length > 0) {
      loadSuggestedChallenges();
    }
  }, [state.currentStep, state.selectedIndustry, state.selectedRoleType, state.selectedArchetypes, loadSuggestedChallenges]);

  // Render current step
  const renderCurrentStep = () => {
    switch (state.currentStep) {
      case 'welcome':
        return (
          <WelcomeStep
            onNext={handleNextStep}
          />
        );
      case 'archetypes':
        return (
          <ArchetypeWheelStep
            state={state}
            onBack={handlePreviousStep}
            onNext={handleGoToContext}
            onToggleArchetype={handleToggleArchetype}
            onGoToDistortions={handleGoToDistortions}
          />
        );
      case 'distortions':
        return (
          <DistortionSelectorStep
            state={state}
            onBack={handlePreviousStep}
            onNext={handleGoToArchetypes}
            onToggleDistortion={handleToggleDistortion}
            onApplyRecommended={applyRecommendedArchetypes}
          />
        );
      case 'context':
        return (
          <ContextSelectionStep
            state={state}
            onBack={handlePreviousStep}
            onNext={handleGoToTasks}
            onSelectIndustry={handleSelectIndustry}
            onSelectRoleType={handleSelectRoleType}
          />
        );
      case 'tasks':
        return (
          <TasksStep
            state={state}
            onBack={handlePreviousStep}
            onComplete={handleGoToResults}
          />
        );
      case 'results':
        return (
          <ResultsStep
            state={state}
            onBack={handleBackToHome}
            onViewChallenges={handleViewChallenges}
          />
        );
      default:
        return null;
    }
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <StatusBar barStyle="dark-content" />
      
      {/* Progress Header */}
      <View style={styles.progressHeader}>
        <View style={styles.progressBar}>
          <View 
            style={[
              styles.progressFill, 
              { width: `${stepProgress.percentage}%` }
            ]} 
          />
        </View>
        <Text style={styles.progressText}>
          Step {stepProgress.current} of {stepProgress.total}
        </Text>
      </View>

      {/* Content */}
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
      >
        {renderCurrentStep()}
      </ScrollView>
    </View>
  );
});

const createStyles = (theme: any) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  progressHeader: {
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 8,
    backgroundColor: theme.colors.background,
    borderBottomWidth: 1,
    borderBottomColor: `${theme.colors.primary}10`,
  },
  progressBar: {
    height: 4,
    backgroundColor: `${theme.colors.primary}20`,
    borderRadius: 2,
    marginBottom: 8,
  },
  progressFill: {
    height: '100%',
    backgroundColor: theme.colors.primary,
    borderRadius: 2,
  },
  progressText: {
    fontSize: 12,
    color: theme.colors.textSecondary,
    textAlign: 'center',
    fontWeight: '500',
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    paddingBottom: 40,
  },
});

export default NewSpiritualCareerGuideScreen;
