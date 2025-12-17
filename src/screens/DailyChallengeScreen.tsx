import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  Alert,
  RefreshControl,
  ActivityIndicator
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRoute } from '@react-navigation/native';
import { ArrowLeft, Trophy, Plus, Sparkle } from '@/components/Icons';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  interpolate,
  Extrapolation
} from 'react-native-reanimated';
import { useTheme } from '@/contexts/ThemeContext';
import {
  useAuthStore,
  useChallengeStore,
  useVirtueStore,
  useDailyPathStore,
  useLeaderboardStore,
} from '@/stores/StoreProvider';
import { Challenge, ChallengeType } from '@/types/challenges';
import * as Haptics from 'expo-haptics';
import * as Notifications from 'expo-notifications';
import EmptyState from '@/components/EmptyState';
import SmartPickCard from '@/components/SmartPickCard';
import { observer } from 'mobx-react-lite';
import { RouteProp } from '@react-navigation/native';
import type { RootStackParamList } from '@/types';
import {
  ensureChallengeReminderChannel,
  upsertStoredReminder,
  cancelChallengeReminder,
  CHALLENGE_REMINDER_CHANNEL_ID,
} from '@/tasks/challengeReminderTask';
import { validateEndTime } from '@/utils/challengeHelpers';
import {
  ChallengeCard,
  CreateChallengeModal,
  JoinReminderModal,
  VoteModal,
  SuggestChallengeModal,
  ChallengeOnboardingOverlay,
} from '@/components/challenges';
import { createStyles } from '../components/challenges/DailyChallengeScreenStyles';

type DailyChallengesProps = {
  navigation: any;
};

type DailyChallengeRoute = RouteProp<RootStackParamList, 'DailyChallengeScreen'>;

const CHALLENGE_CATEGORIES = [
  { id: 'personal', label: 'Joined' },
  { id: 'community', label: 'Community' },
  { id: 'suggested', label: 'Suggested' },
];


const DailyChallengesScreen = observer(({ navigation }: DailyChallengesProps) => {
  const insets = useSafeAreaInsets();
  const route = useRoute<DailyChallengeRoute>();
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const { currentGoalVirtueId, virtues: allVirtues } = useVirtueStore();
  const { user } = useAuthStore();
  const leaderboardStore = useLeaderboardStore();
  const dailyPathStore = useDailyPathStore();
  const challengeStore = useChallengeStore();
  const optimisticDelta = Number((leaderboardStore as any)?.state?.optimisticPointsDelta ?? 0) || 0;
  const userPoints = (leaderboardStore.userStats?.totalPoints ?? (Number(user?.points ?? 0) + optimisticDelta)) || 0;
  const canSuggestCommunity = userPoints >= 100;

  const {
    // State
    activeCategory,
    showNewChallengeForm,
    refreshing,
    personalChallenges,
    communityChallenges,
    suggestedChallenges,
    
    // Loading states
    isCreatingLoading,
    isJoiningLoading,
    isUpvotingLoading,
    isPersonalLoading,
    isCommunityLoading,
    isSuggestedLoading,
    
    // Errors
    personalError,
    communityError,
    suggestedError,
    createError,
    
    // Actions
    fetchPersonalChallenges,
    fetchCommunityChallenges,
    fetchSuggestedChallenges,
    createChallenge,
    joinChallenge,
    leaveChallenge,
    upvoteChallenge,
    completeChallenge,
    voteChallenge,
    
    // State management
    setActiveCategory,
    setShowNewChallengeForm,
    setRefreshing,
    clearErrors,
    refreshAll,
    // expose pagination for infinite scroll
    state,
  } = challengeStore;
  
  const [isOnboarding, setIsOnboarding] = useState<boolean>(() => {
    if (route?.params?.onboarding) {
      return true;
    }
    return !dailyPathStore.hasCompletedChallengeOnboarding;
  });
  
  const [newChallenge, setNewChallenge] = useState({
    title: '',
    type: 'virtue' as ChallengeType,
    endTime: '21:00',
    description: '',
  });

  const [showSuggestModal, setShowSuggestModal] = useState(false);
  const [showVoteModal, setShowVoteModal] = useState(false);
  const [voteTargetId, setVoteTargetId] = useState<string | null>(null);
  const [voteSpiritual, setVoteSpiritual] = useState(3);
  const [voteEffort, setVoteEffort] = useState(3);
  const [smartPickDismissed, setSmartPickDismissed] = useState(false);

  const [showJoinReminderModal, setShowJoinReminderModal] = useState(false);
  const [joinTarget, setJoinTarget] = useState<Challenge | null>(null);
  const [selectedJoinReminderHours, setSelectedJoinReminderHours] = useState<number>(6);
  
  // Animation values
  const headerHeight = useSharedValue(0);
  const formHeight = useSharedValue(0);
  const listOpacity = useSharedValue(0);
  const backScale = useSharedValue(1);
  const suggestScale = useSharedValue(1);
  
  useEffect(() => {
    // Animate header and list on mount
    headerHeight.value = withTiming(56, { duration: 500 });
    listOpacity.value = withTiming(1, { duration: 800 });
    
    // Load challenges
    loadChallenges();
  }, []);

  useEffect(() => {
    if (!isOnboarding) {
      return;
    }
    const joined = (personalChallenges || []).find(challenge => challenge.hasJoined);
    if (joined) {
      dailyPathStore.setChallengeOnboardingCompleted(true);
      setActiveCategory('personal');
      setIsOnboarding(false);
    }
  }, [isOnboarding, personalChallenges, dailyPathStore, setActiveCategory]);
  
  const loadChallenges = useCallback(async () => {
    setRefreshing(true);
    try {
      const promises: Promise<any>[] = [];
      if (!personalChallenges?.length) {
        promises.push(fetchPersonalChallenges(1));
      }
      if (!communityChallenges?.length) {
        promises.push(fetchCommunityChallenges(1));
      }
      if (!suggestedChallenges?.length) {
        promises.push(fetchSuggestedChallenges(1));
      }
      if (promises.length > 0) {
        await Promise.allSettled(promises);
      }
    } catch (error) {
      console.error('Error loading challenges:', error);
    } finally {
      setRefreshing(false);
    }
  }, [personalChallenges?.length, communityChallenges?.length, suggestedChallenges?.length, fetchPersonalChallenges, fetchCommunityChallenges, fetchSuggestedChallenges, setRefreshing]);
  
  const onRefresh = useCallback(() => {
    refreshAll();
  }, [refreshAll]);
  
  const toggleNewChallengeForm = () => {
    setShowNewChallengeForm(!showNewChallengeForm);
  };
  
  const handleCreateChallenge = async () => {
    if (!newChallenge.title.trim()) {
      Alert.alert('Error', 'Please enter a challenge title');
      return;
    }

    const validation = validateEndTime(newChallenge.endTime);
    if (!validation.valid) {
      Alert.alert('Error', validation.error || 'Invalid end time');
      return;
    }
    
    // Determine category based on active tab
    const category = activeCategory === 'community' ? 'community' : 'personal';
    
    const result = await createChallenge({
      title: newChallenge.title,
      description: newChallenge.description || 'No description provided',
      type: newChallenge.type,
      category: category,
      endTime: newChallenge.endTime,
      isPublic: category === 'community' ? true : undefined,
    });
    
    if (result) {
      if (category !== 'community') {
        setActiveCategory('personal');
      }

      if (category === 'personal') {
        try {
          await scheduleJoinReminder(result as any, 6);
        } catch {}
      }
      // Reset form
      setNewChallenge({
        title: '',
        type: 'virtue',
        endTime: '21:00',
        description: '',
      });
      
      setShowNewChallengeForm(false);
      Alert.alert('Success', 'Challenge created successfully!');
    }
  };
  
  const handleSuggestCommunityChallenge = () => {
    if (!canSuggestCommunity) {
      return;
    }
    setShowSuggestModal(true);
  };

  const handleSubmitSuggestion = useCallback(async () => {
    if (!newChallenge.title.trim()) {
      Alert.alert('Error', 'Please enter a challenge title');
      return;
    }
    
    if (!user || userPoints < 100) {
      Alert.alert('Points Required', 'You need at least 100 points to suggest community challenges.');
      setShowSuggestModal(false);
      return;
    }
    
    const result = await createChallenge({
      title: newChallenge.title,
      description: newChallenge.description || '',
      type: newChallenge.type,
      category: 'community',
      endTime: newChallenge.endTime,
      isPublic: true,
    });
    
    if (result) {
      setShowSuggestModal(false);
      setNewChallenge({ title: '', type: 'virtue', endTime: '21:00', description: '' });
      Alert.alert('Success', 'Community challenge suggested successfully!');
    }
  }, [newChallenge, user, userPoints, createChallenge]);

  const openVoteModal = useCallback((challengeId: string) => {
    setVoteTargetId(challengeId);
    setVoteSpiritual(3);
    setVoteEffort(3);
    setShowVoteModal(true);
  }, []);

  const submitVote = useCallback(async () => {
    if (!voteTargetId) return;
    await voteChallenge(voteTargetId, { spiritual: voteSpiritual, effort: voteEffort });
    setShowVoteModal(false);
    setVoteTargetId(null);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  }, [voteTargetId, voteSpiritual, voteEffort, voteChallenge]);

  const scheduleJoinReminder = useCallback(async (challenge: Challenge, hours: number) => {
    try {
      const { status } = await Notifications.getPermissionsAsync();
      if (status !== 'granted') {
        const { status: nextStatus } = await Notifications.requestPermissionsAsync();
        if (nextStatus !== 'granted') {
          return;
        }
      }

      await ensureChallengeReminderChannel();
      await cancelChallengeReminder(challenge.id);

      const now = new Date();
      let challengeEndTime: Date | null = null;
      if (challenge?.expiresAt) {
        const parsed = new Date(String(challenge.expiresAt));
        if (!Number.isNaN(parsed.getTime())) {
          challengeEndTime = parsed;
        }
      }

      const intervalMs = Math.max(1, hours) * 60 * 60 * 1000;
      const triggers: Date[] = [];
      const first = new Date(now.getTime() + intervalMs);
      if (!challengeEndTime || first <= challengeEndTime) {
        triggers.push(first);
      }

      for (let i = 2; i <= 24; i++) {
        const triggerAt = new Date(now.getTime() + i * intervalMs);
        if (challengeEndTime && triggerAt > challengeEndTime) break;
        triggers.push(triggerAt);
      }

      if (triggers.length === 0) {
        await cancelChallengeReminder(challenge.id);
        return;
      }

      const notificationIds: string[] = [];
      for (const triggerAt of triggers) {
        const notificationId = await Notifications.scheduleNotificationAsync({
          content: {
            title: 'Daily Challenge Reminder',
            body: `Don't forget to complete your "${challenge.title}" challenge!`,
            sound: 'default',
            priority: Notifications.AndroidNotificationPriority.HIGH,
          },
          trigger: {
            type: Notifications.SchedulableTriggerInputTypes.DATE,
            date: triggerAt,
            channelId: CHALLENGE_REMINDER_CHANNEL_ID,
          },
        });
        notificationIds.push(notificationId);
      }

      await upsertStoredReminder({
        challengeId: challenge.id,
        challengeTitle: challenge.title,
        reminderHours: hours,
        scheduledFor: now.toISOString(),
        nextReminderDue: triggers[0].toISOString(),
        notificationIds,
      });
    } catch (error) {
      console.error('Error scheduling join reminder:', error);
    }
  }, []);

  const openJoinWithReminder = useCallback((challenge: Challenge) => {
    setJoinTarget(challenge);
    setSelectedJoinReminderHours(6);
    setShowJoinReminderModal(true);
  }, []);

  const confirmJoinWithReminder = useCallback(async () => {
    if (!joinTarget) return;
    try {
      setShowJoinReminderModal(false);
      const joined = await joinChallenge(joinTarget.id);
      const resolved = joined || joinTarget;
      await scheduleJoinReminder(resolved as any, selectedJoinReminderHours);
      if (activeCategory === 'suggested') {
        setActiveCategory('personal');
      }
    } catch (error) {
      setShowJoinReminderModal(false);
    }
  }, [joinTarget, joinChallenge, scheduleJoinReminder, selectedJoinReminderHours, activeCategory, setActiveCategory]);
  
  
  // Animated styles
  const headerAnimatedStyle = useAnimatedStyle(() => ({
    height: headerHeight.value,
    opacity: interpolate(headerHeight.value, [0, 56], [0, 1], Extrapolation.CLAMP),
  }));

  const backAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: backScale.value }],
  }));

  const suggestAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: suggestScale.value }],
  }));

  const renderItem = useCallback(({ item }: { item: Challenge }) => (
    <ChallengeCard
      challenge={item}
      theme={theme}
      activeCategory={activeCategory}
      isCreatingLoading={isCreatingLoading}
      isJoiningLoading={isJoiningLoading}
      isUpvotingLoading={isUpvotingLoading}
      onPress={() => navigation.navigate('ChallengeDetail', { id: item.id })}
      onJoin={() => openJoinWithReminder(item)}
      onLeave={() => leaveChallenge(item.id)}
      onComplete={async () => {
        try {
          await completeChallenge(item.id, true);
        } catch {}
      }}
      onVote={() => openVoteModal(item.id)}
    />
  ), [theme, activeCategory, isCreatingLoading, isJoiningLoading, isUpvotingLoading, navigation, openJoinWithReminder, leaveChallenge, completeChallenge, openVoteModal]);

  // No form for now (and hidden on Joined tab anyway)
  const renderNewChallengeForm = () => null;
  
  const formAnimatedStyle = useAnimatedStyle(() => ({
    height: formHeight.value,
    opacity: interpolate(formHeight.value, [0, 400], [0, 1], Extrapolation.CLAMP),
    marginBottom: formHeight.value > 0 ? 16 : 0,
  }));
  
  const listAnimatedStyle = useAnimatedStyle(() => ({
    opacity: listOpacity.value,
    transform: [
      { translateY: interpolate(listOpacity.value, [0, 1], [20, 0], Extrapolation.CLAMP) }
    ]
  }));

  // Memoize filtered challenges for suggested category
  const filteredSuggestedChallenges = useMemo(() => {
    const goalVirtue = (allVirtues || []).find(v => v.id === currentGoalVirtueId);
    const goalName = goalVirtue?.name?.toLowerCase();
    return (suggestedChallenges || []).filter(c => {
      if (c.isFeatured) return true;
      if (!goalName) return false;
      const hay = `${c.title || ''} ${c.description || ''}`.toLowerCase();
      return hay.includes(goalName);
    });
  }, [suggestedChallenges, allVirtues, currentGoalVirtueId]);

  const goalVirtueName = useMemo(() => {
    const virtue = (allVirtues || []).find(v => v.id === currentGoalVirtueId);
    return virtue?.name ?? null;
  }, [allVirtues, currentGoalVirtueId]);

  const smartPickChallenge = useMemo(() => {
    if (smartPickDismissed) return null;
    return challengeStore.getRecommendedChallenge({
      preferredTheme: goalVirtueName,
      excludeIds: personalChallenges.map(c => c.id),
      allowJoined: false,
    });
  }, [challengeStore, goalVirtueName, personalChallenges, smartPickDismissed]);

  const handleSmartPickJoin = useCallback(async (challenge: Challenge) => {
    try {
      const joined = await joinChallenge(challenge.id);
      const resolved = (joined as any) || challenge;
      await scheduleJoinReminder(resolved as any, 6);
      setSmartPickDismissed(true);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    } catch {}
  }, [joinChallenge, scheduleJoinReminder]);

  const renderChallenges = () => {
    let challenges: Challenge[] = [];
    let isLoading = false;
    let error: string | null = null;

    switch (activeCategory) {
      case 'personal':
        challenges = personalChallenges;
        isLoading = isPersonalLoading;
        error = personalError;
        break;
      case 'community':
        challenges = communityChallenges;
        isLoading = isCommunityLoading;
        error = communityError;
        break;
      case 'suggested':
        challenges = filteredSuggestedChallenges;
        isLoading = isSuggestedLoading;
        error = suggestedError;
        break;
    }

    if (isLoading && challenges.length === 0) {
      return (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={theme?.colors.primary} />
          <Text style={styles.loadingText}>Loading challenges...</Text>
        </View>
      );
    }

    if (error && challenges.length === 0) {
      return (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity 
            style={styles.retryButton}
            onPress={() => {
              switch (activeCategory) {
                case 'personal':
                  fetchPersonalChallenges(1);
                  break;
                case 'community':
                  fetchCommunityChallenges(1);
                  break;
                case 'suggested':
                  fetchSuggestedChallenges(1);
                  break;
              }
            }}
          >
            <Text style={styles.retryButtonText}>Retry</Text>
          </TouchableOpacity>
        </View>
      );
    }

    if (challenges.length === 0) {
      const emptyConfig = (() => {
        if (activeCategory === 'personal') {
          return {
            title: 'No joined challenges yet',
            message: 'Be the first to commit to a daily virtue challenge and grow your habits.',
            ctaText: 'Browse challenges',
            onPress: () => setActiveCategory('community'),
          };
        }
        if (activeCategory === 'community') {
          return {
            title: 'No community challenges found',
            message: 'Start something uplifting for everyone. Suggest a challenge the community can join.',
            ctaText: 'Suggest a challenge',
            onPress: handleSuggestCommunityChallenge,
          };
        }
        return {
          title: 'No suggestions yet',
          message: 'Set your current goal virtue to get personalized daily suggestions.',
          ctaText: 'Set current goal',
          onPress: () => navigation.navigate('VirtueScreen'),
        };
      })();

      return (
        <EmptyState
          title={emptyConfig.title}
          message={emptyConfig.message}
          ctaText={emptyConfig.ctaText}
          onPressCTA={emptyConfig.onPress}
        />
      );
    }

    const loadMore = () => {
      if (isLoading) return; // prevent spamming while loading
      const currentPage = state.pagination.currentPage || 1;
      const nextPage = currentPage + 1;
      if (!state.pagination.hasMore) return;
      switch (activeCategory) {
        case 'personal':
          fetchPersonalChallenges(nextPage);
          break;
        case 'community':
          fetchCommunityChallenges(nextPage);
          break;
        case 'suggested':
          fetchSuggestedChallenges(nextPage);
          break;
      }
    };

    return (
      <FlatList
        data={challenges}
        keyExtractor={(item) => item.id}
        renderItem={renderItem}
        onEndReached={loadMore}
        onEndReachedThreshold={0.4}
        initialNumToRender={8}
        maxToRenderPerBatch={8}
        windowSize={9}
        removeClippedSubviews
        ListFooterComponent={activeCategory === 'suggested' && canSuggestCommunity ? (
          <View style={styles.listFooter}>
            <TouchableOpacity
              style={styles.suggestYourOwnButton}
              onPress={() => {
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                handleSuggestCommunityChallenge();
              }}
            >
              <Sparkle size={18} color={theme?.colors.primary} />
              <Text style={styles.suggestYourOwnText}>Suggest your own challenge</Text>
            </TouchableOpacity>
          </View>
        ) : null}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      />
    );
  };

  const hasJoinedChallenge = useMemo(() => {
    return (personalChallenges || []).some((challenge) => challenge.hasJoined);
  }, [personalChallenges]);

  const voteTargetChallenge = useMemo(() => {
    if (!voteTargetId) return null;
    const all = [...(personalChallenges||[]), ...(communityChallenges||[]), ...(suggestedChallenges||[])];
    return all.find(c => c.id === voteTargetId) || null;
  }, [voteTargetId, personalChallenges, communityChallenges, suggestedChallenges]);

  const handleOnboardingBrowse = useCallback(() => {
    if (hasJoinedChallenge) {
      dailyPathStore.setChallengeOnboardingCompleted(true);
      setActiveCategory('personal');
      setIsOnboarding(false);
      return;
    }
    setActiveCategory('community');
    setIsOnboarding(false);
  }, [hasJoinedChallenge, dailyPathStore, setActiveCategory]);

  const handleOnboardingSkip = useCallback(() => {
    dailyPathStore.setChallengeOnboardingCompleted(true);
    setIsOnboarding(false);
  }, [dailyPathStore]);

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}> 
      <Animated.View style={[styles.header, headerAnimatedStyle]}>
        <Animated.View style={backAnimatedStyle}>
          <TouchableOpacity 
            style={styles.backButton}
            onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); navigation.goBack(); }}
            onPressIn={() => { backScale.value = withTiming(0.96, { duration: 80 }); }}
            onPressOut={() => { backScale.value = withTiming(1, { duration: 120 }); }}
          >
            <ArrowLeft size={24} color={theme?.colors.text.primary} />
          </TouchableOpacity>
        </Animated.View>
        <Text style={styles.headerTitle}>Daily Challenges</Text>
        <View style={{ flexDirection: 'row', alignItems: 'center' }}>
          {activeCategory === 'personal' && (
            <Animated.View style={suggestAnimatedStyle}>
              <TouchableOpacity
                style={styles.suggestButton}
                onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); toggleNewChallengeForm(); }}
                onPressIn={() => { suggestScale.value = withTiming(0.96, { duration: 80 }); }}
                onPressOut={() => { suggestScale.value = withTiming(1, { duration: 120 }); }}
              >
                <Plus size={20} color={theme?.colors.primary} />
              </TouchableOpacity>
            </Animated.View>
          )}
          {user && canSuggestCommunity && activeCategory === 'community' && (
            <Animated.View style={suggestAnimatedStyle}>
              <TouchableOpacity 
                style={styles.suggestButton}
                onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); handleSuggestCommunityChallenge(); }}
                onPressIn={() => { suggestScale.value = withTiming(0.96, { duration: 80 }); }}
                onPressOut={() => { suggestScale.value = withTiming(1, { duration: 120 }); }}
              >
                <Sparkle size={20} color={theme?.colors.primary} />
              </TouchableOpacity>
            </Animated.View>
          )}
        </View>
      </Animated.View>

      <View style={styles.categoryTabs}>
        {CHALLENGE_CATEGORIES.map(category => (
          <TouchableOpacity
            key={category.id}
            style={[
              styles.categoryTab,
              activeCategory === category.id && styles.activeTab
            ]}
            onPress={() => { Haptics.selectionAsync(); setActiveCategory(category.id as 'personal' | 'community' | 'suggested'); }}
          >
            <Text style={[
              styles.categoryText,
              activeCategory === category.id && styles.activeTabText
            ]}>
              {category.label}
            </Text>
          </TouchableOpacity>
        ))}
        <View style={{ flex: 1 }} />
        <TouchableOpacity
          style={[styles.addChallengeButton, { paddingVertical: 8, paddingHorizontal: 12, marginBottom: 0 }]}
          onPress={() => navigation.navigate('VirtueScreen')}
        >
          <Trophy size={16} color={theme?.colors.primary} />
          <Text style={styles.addChallengeText}>Set Current Goal</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.content}>
        {/* For Joined tab, we won't show create form/button */}
        {activeCategory !== 'personal' && renderNewChallengeForm()}

        <Animated.View style={listAnimatedStyle}>
          {!smartPickDismissed && smartPickChallenge && (
            <View style={styles.smartPickWrapper}>
              <SmartPickCard
                challenge={smartPickChallenge}
                onPressJoin={handleSmartPickJoin}
                onPressDismiss={() => setSmartPickDismissed(true)}
                ctaLabel={smartPickChallenge.hasJoined ? 'View challenge' : 'Join challenge'}
              />
            </View>
          )}
          {renderChallenges()}
        </Animated.View>
      </View>

      <SuggestChallengeModal
        visible={showSuggestModal}
        theme={theme}
        title={newChallenge.title}
        description={newChallenge.description}
        isLoading={isCreatingLoading}
        onChangeTitle={(t) => setNewChallenge({ ...newChallenge, title: t })}
        onChangeDescription={(t) => setNewChallenge({ ...newChallenge, description: t })}
        onSubmit={handleSubmitSuggestion}
        onClose={() => setShowSuggestModal(false)}
      />

      <CreateChallengeModal
        visible={showNewChallengeForm}
        theme={theme}
        title={newChallenge.title}
        description={newChallenge.description}
        type={newChallenge.type}
        endTime={newChallenge.endTime}
        isLoading={isCreatingLoading}
        onChangeTitle={(t) => setNewChallenge({ ...newChallenge, title: t })}
        onChangeDescription={(t) => setNewChallenge({ ...newChallenge, description: t })}
        onChangeType={(type) => setNewChallenge({ ...newChallenge, type })}
        onChangeEndTime={(t) => setNewChallenge({ ...newChallenge, endTime: t })}
        onSubmit={handleCreateChallenge}
        onClose={() => setShowNewChallengeForm(false)}
      />

      <JoinReminderModal
        visible={showJoinReminderModal}
        theme={theme}
        selectedHours={selectedJoinReminderHours}
        isLoading={isJoiningLoading}
        onSelectHours={setSelectedJoinReminderHours}
        onConfirm={confirmJoinWithReminder}
        onClose={() => {
          setShowJoinReminderModal(false);
          setJoinTarget(null);
        }}
      />

      <VoteModal
        visible={showVoteModal}
        theme={theme}
        targetChallenge={voteTargetChallenge}
        voteSpiritual={voteSpiritual}
        voteEffort={voteEffort}
        isLoading={isUpvotingLoading}
        onChangeSpiritual={setVoteSpiritual}
        onChangeEffort={setVoteEffort}
        onSubmit={submitVote}
        onClose={() => setShowVoteModal(false)}
      />

      <ChallengeOnboardingOverlay
        visible={isOnboarding}
        theme={theme}
        hasJoinedChallenge={hasJoinedChallenge}
        onBrowse={handleOnboardingBrowse}
        onSkip={handleOnboardingSkip}
      />
    </View>
  );
});

export default DailyChallengesScreen;