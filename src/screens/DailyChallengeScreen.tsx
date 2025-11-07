import React, { useState, useEffect, useCallback, useMemo, memo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  FlatList,
  TouchableOpacity,
  Platform,
  TextInput,
  Alert,
  RefreshControl,
  ActivityIndicator
} from 'react-native';
import { Modal } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRoute } from '@react-navigation/native';
import {
  ArrowLeft,
  X,
  Clock,
  Trophy,
  Star,
  Sparkle,
  Check
} from '@/components/Icons';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  interpolate,
  Extrapolation
} from 'react-native-reanimated';
import { format, isToday, parseISO, differenceInHours, addDays } from 'date-fns';
import AvatarStack from '@/components/AvatarStack';
import { useTheme } from '@/contexts/ThemeContext';
import {
  useAuthStore,
  useChallengeStore,
  useVirtueStore,
  useDailyPathStore,
} from '@/stores/StoreProvider';
import { Theme } from '@/theme';
import { Challenge, ChallengeType } from '@/types/challenges';
import * as Haptics from 'expo-haptics';
import EmptyState from '@/components/EmptyState';
import SmartPickCard from '@/components/SmartPickCard';
import { observer } from 'mobx-react-lite';
import { RouteProp } from '@react-navigation/native';
import type { RootStackParamList } from '@/types';
import { toast } from 'sonner-native';

type DailyChallengesProps = {
  navigation: any;
};

type DailyChallengeRoute = RouteProp<RootStackParamList, 'DailyChallengeScreen'>;

const CHALLENGE_CATEGORIES = [
  { id: 'personal', label: 'Joined' },
  { id: 'community', label: 'Community' },
  { id: 'suggested', label: 'Suggested' },
];

const CHALLENGE_TYPES = [
  { id: 'virtue', label: 'Develop Virtue', icon: Star, color: '#4CAF50' },
  { id: 'vice', label: 'Reduce Vice', icon: X, color: '#F44336' },
];

const DailyChallengesScreen = observer(({ navigation }: DailyChallengesProps) => {
  const insets = useSafeAreaInsets();
  const route = useRoute<DailyChallengeRoute>();
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const { currentGoalVirtueId, virtues: allVirtues } = useVirtueStore();
  const { user } = useAuthStore();
  const dailyPathStore = useDailyPathStore();
  const challengeStore = useChallengeStore();
  const userPoints = user?.points ?? 0;
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
    addSuggestedToPersonal,
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
  const [hasAttemptedAutoJoin, setHasAttemptedAutoJoin] = useState(false);
  const [autoJoinError, setAutoJoinError] = useState<string | null>(null);
  
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
    if (!isOnboarding || hasAttemptedAutoJoin) {
      return;
    }

    const tryAutoJoin = async () => {
      setHasAttemptedAutoJoin(true);
      setAutoJoinError(null);
      try {
        // prefer existing joined challenge
        const joined = (personalChallenges || []).find(challenge => challenge.hasJoined);
        if (joined) {
          dailyPathStore.setChallengeOnboardingCompleted(true);
          setIsOnboarding(false);
          return;
        }

        // fallback: take first suggested or community challenge
        const candidate = (suggestedChallenges && suggestedChallenges[0])
          || (communityChallenges && communityChallenges[0]);
        if (!candidate) {
          setAutoJoinError('No challenges available right now. Pull to refresh and try again.');
          return;
        }

        await joinChallenge(candidate.id);
        toast.success('Challenge joined. Let’s get started!');
        dailyPathStore.setChallengeOnboardingCompleted(true);
        setActiveCategory('personal');
        setIsOnboarding(false);
      } catch (error) {
        console.error('[DailyChallengeScreen] auto-join failed', error);
        setAutoJoinError('Could not join a challenge automatically. Please pick one manually.');
      }
    };

    tryAutoJoin();
  }, [isOnboarding, hasAttemptedAutoJoin, personalChallenges, suggestedChallenges, communityChallenges, joinChallenge, dailyPathStore, setActiveCategory]);

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
    if (showNewChallengeForm) {
      formHeight.value = withTiming(0, { duration: 300 });
      setTimeout(() => setShowNewChallengeForm(false), 300);
    } else {
      setShowNewChallengeForm(true);
      setTimeout(() => formHeight.value = withTiming(400, { duration: 300 }), 10);
    }
  };
  
  const handleCreateChallenge = async () => {
    if (!newChallenge.title.trim()) {
      Alert.alert('Error', 'Please enter a challenge title');
      return;
    }
    
    // Determine category based on active tab
    const category = activeCategory === 'community' ? 'community' : 'suggested';
    
    const result = await createChallenge({
      title: newChallenge.title,
      description: newChallenge.description || 'No description provided',
      type: newChallenge.type,
      category: category,
      endTime: newChallenge.endTime,
      isPublic: category === 'community', // Community challenges are public
    });
    
    if (result) {
      // Reset form
      setNewChallenge({
        title: '',
        type: 'virtue',
        endTime: '21:00',
        description: '',
      });
      
      toggleNewChallengeForm();
      Alert.alert('Success', 'Challenge created successfully!');
    }
  };
  
  // const handleCompleteChallenge = async (challenge: Challenge, isCompleted: boolean) => {
  //   const success = await completeChallenge(challenge.id, isCompleted);
    
  //   if (success) {
  //     Haptics.notificationAsync(
  //       isCompleted 
  //         ? Haptics.NotificationFeedbackType.Success 
  //         : Haptics.NotificationFeedbackType.Warning
  //     );
  //   }
  // };
  
  // const handleJoinChallenge = async (challenge: Challenge) => {
  //   if (isJoiningLoading) return; // Prevent multiple clicks
    
  //   const success = await (challenge.hasJoined 
  //     ? leaveChallenge(challenge.id)
  //     : joinChallenge(challenge.id)
  //   );
    
  //   if (success) {
  //     Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  //   }
  // };
  
  // const handleUpvoteChallenge = async (challenge: Challenge) => {
  //   if (isUpvotingLoading) return; // Prevent multiple clicks
    
  //   const success = await upvoteChallenge(challenge.id);
    
  //   if (success) {
  //     Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  //   }
  // };
  
  // const handleAddSuggestedChallenge = async (challenge: Challenge) => {
  //   if (isCreatingLoading) return; // Prevent multiple clicks
    
  //   const success = await addSuggestedToPersonal(challenge.id);
    
  //   if (success) {
  //     Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  //   }
  // };
  
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
    
    if (!user || (user.points || 0) < 100) {
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
  }, [newChallenge, user, createChallenge]);

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
  
  const getTimeRemaining = (endTime: string) => {
    try {
      const [hours, minutes] = endTime.split(':').map(Number);
      const now = new Date();
      const target = new Date();
      target.setHours(hours, minutes, 0, 0);

      if (target <= now) {
        return 'Expired';
      }

      const minutesDiff = Math.max(0, Math.floor((target.getTime() - now.getTime()) / (1000 * 60)));
      if (minutesDiff < 90) {
        const displayMinutes = Math.max(1, minutesDiff);
        return `Ends in ${displayMinutes} min`;
      }

      if (minutesDiff < 12 * 60) {
        const hoursLeft = Math.floor(minutesDiff / 60);
        const remainingMinutes = minutesDiff % 60;
        return `Ends in ${hoursLeft}h${remainingMinutes ? ` ${remainingMinutes}m` : ''}`;
      }

      return `Ends at ${format(target, 'h:mm a')}`;
    } catch {
      return 'Ends soon';
    }
  };
  
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

  // Memoized challenge card component for better performance
  const renderChallengeCard = useCallback((challenge: Challenge) => {
    const isVirtue = challenge.type === 'virtue';
    const color = isVirtue ? theme?.colors.success : theme?.colors.error;
    const CIcon = isVirtue ? Star : X;
    const timeRemaining = getTimeRemaining(challenge.endTime);
    const isExpired = timeRemaining === 'Expired';
    const isJoined = Boolean((challenge as any)?.hasJoined);
    const actionInProgress = activeCategory === 'suggested' ? isCreatingLoading : isJoiningLoading;

    const handlePrimaryAction = async () => {
      if (actionInProgress) return;
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      if (activeCategory === 'suggested') {
        const success = await addSuggestedToPersonal(challenge.id);
        if (success) {
          toast.success('Challenge added to your list');
        }
        return;
      }

      if (isJoined) {
        const success = await leaveChallenge(challenge.id);
        if (success) {
          toast.success('Challenge left');
        }
      } else {
        const success = await joinChallenge(challenge.id);
        if (success) {
          toast.success('Challenge joined');
        }
      }
    };

    const primaryLabel = activeCategory === 'suggested'
      ? 'Add to my challenges'
      : isJoined
        ? 'Leave'
        : 'Join';

    const createdAt = new Date(challenge.createdAt);
    const now = new Date();
    const ms3days = 3 * 24 * 60 * 60 * 1000;
    const withinWindow = now.getTime() - createdAt.getTime() < ms3days;
    const belowCap = (challenge.upvotes || 0) < 100;
    const canVote = !challenge.hasUpvoted && withinWindow && belowCap;

    return (
      <TouchableOpacity style={styles.challengeCard} key={challenge.id} onPress={() => navigation.navigate('ChallengeDetail', { id: challenge.id })}>
        <LinearGradient
          colors={[`${color}10`, `${color}02`]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.cardGradient}
        />

        <View style={styles.challengeHeader}>
          <View style={[styles.typeTag, { backgroundColor: `${color}15` }]}>
            <CIcon size={14} color={color} />
            <Text style={[styles.typeText, { color }]}>
              {isVirtue ? 'Virtue' : 'Vice'}
            </Text>
          </View>
          {challenge.hasJoined && (
            <View style={[styles.badge, { backgroundColor: `${theme?.colors.success}15` }]}>
              <Check size={12} color={theme?.colors.success} />
              <Text style={[styles.badgeText, { color: theme?.colors.success }]}>Joined</Text>
            </View>
          )}
          <View style={styles.timeContainer}>
            <Clock size={14} color={isExpired ? theme?.colors.error : theme?.colors.text.secondary} />
            <Text style={[
              styles.timeText, 
              isExpired && { color: theme?.colors.error }
            ]}>
              {timeRemaining}
            </Text>
          </View>
        </View>

        <Text style={styles.challengeTitle}>{challenge.title}</Text>
        {!!challenge.description && (
          <Text style={styles.challengeDescription} numberOfLines={2}>
            {challenge.description}
          </Text>
        )}

        {/* Community: show suggested tier/points if available and Vote button */}
        <View style={styles.actionContainer}>
          {(!!(challenge as any)?.tier || !!(challenge as any)?.points) && activeCategory === 'community' && (
            <View style={[styles.badge, { backgroundColor: `${theme?.colors.primary}10`, marginRight: 'auto' }]}> 
              <Star size={14} color={theme?.colors.primary} />
              <Text style={[styles.badgeText, { color: theme?.colors.primary }]}>
                {(challenge as any)?.tier ? `Tier ${(challenge as any).tier}` : `${(challenge as any).points} pts`}
              </Text>
            </View>
          )}

          <TouchableOpacity
            style={[styles.primaryActionButton, { backgroundColor: `${theme?.colors.primary}12` }]}
            onPress={handlePrimaryAction}
            disabled={actionInProgress || (activeCategory === 'suggested' && isJoined)}
            activeOpacity={0.8}
          >
            <Text style={[styles.primaryActionText, actionInProgress && { opacity: 0.6 }]}>
              {actionInProgress ? 'Please wait…' : primaryLabel}
            </Text>
          </TouchableOpacity>

          {activeCategory === 'community' && canVote ? (
            <TouchableOpacity
              style={[styles.actionButton, { backgroundColor: `${theme?.colors.primary}15` }]}
              onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); openVoteModal(challenge.id); }}
              disabled={isUpvotingLoading}
            >
              <Star size={16} color={theme?.colors.primary} />
              <Text style={[styles.actionText, { color: theme?.colors.primary }]}>Vote</Text>
            </TouchableOpacity>
          ) : null}
        </View>

        {/* Compact insights: time-left and vote cap progress */}
        {activeCategory === 'community' && (
          <View style={styles.compactInfoRow}>
            <Text style={styles.compactInfoText}>
              {Math.max(0, Math.ceil((ms3days - (now.getTime() - createdAt.getTime()))/(24*60*60*1000)))}d window · {(challenge.upvotes||0)}/100 votes
            </Text>
          </View>
        )}
      </TouchableOpacity>
    );
  }, [theme?.colors, activeCategory, navigation]);

  const renderItem = useCallback(({ item }: { item: Challenge }) => renderChallengeCard(item), [renderChallengeCard]);

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
    const success = await joinChallenge(challenge.id);
    if (success) {
      setSmartPickDismissed(true);
      toast.success('Challenge joined. Let’s get started!');
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    }
  }, [joinChallenge]);

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

  const renderOnboardingOverlay = () => {
    if (!isOnboarding) {
      return null;
    }

    const hasJoinedChallenge = (personalChallenges || []).some((challenge) => challenge.hasJoined);

    return (
      <View style={styles.onboardingOverlay} pointerEvents="auto">
        <View style={styles.onboardingCard}>
          <Text style={styles.onboardingTitle}>Join a Daily Challenge</Text>
          <Text style={styles.onboardingBody}>
            Pick a challenge to stay consistent. We’ll guide you with reminders and track your progress.
          </Text>
          {autoJoinError ? (
            <Text style={styles.onboardingError}>{autoJoinError}</Text>
          ) : null}
          {!hasAttemptedAutoJoin && !hasJoinedChallenge ? (
            <Text style={styles.onboardingSubtle}>Looking for a daily challenge that fits…</Text>
          ) : null}
          <TouchableOpacity
            style={styles.onboardingPrimary}
            onPress={() => {
              if (hasJoinedChallenge) {
                dailyPathStore.setChallengeOnboardingCompleted(true);
                setActiveCategory('personal');
                setIsOnboarding(false);
                return;
              }
              setAutoJoinError(null);
              setHasAttemptedAutoJoin(false);
              void loadChallenges();
            }}
          >
            <Text style={styles.onboardingPrimaryText}>
              {hasJoinedChallenge ? 'Go to my challenge' : 'Try again'}
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.onboardingSecondary}
            onPress={() => {
              dailyPathStore.setChallengeOnboardingCompleted(true);
              setIsOnboarding(false);
            }}
          >
            <Text style={styles.onboardingSecondaryText}>Skip for now</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

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

      {/* Suggest Community Challenge Modal */}
      <Modal visible={showSuggestModal} animationType="fade" transparent onRequestClose={() => setShowSuggestModal(false)}>
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>Suggest a Community Challenge</Text>
            <TextInput
              style={styles.input}
              placeholder="Title"
              value={newChallenge.title}
              onChangeText={(t) => setNewChallenge({ ...newChallenge, title: t })}
            />
            <TextInput
              style={[styles.input, styles.textArea]}
              placeholder="Description (optional)"
              value={newChallenge.description}
              onChangeText={(t) => setNewChallenge({ ...newChallenge, description: t })}
              multiline
            />
            <View style={styles.formActions}>
              <TouchableOpacity style={[styles.formButton, styles.cancelButton]} onPress={() => setShowSuggestModal(false)}>
                <Text style={styles.cancelButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.formButton, styles.createButton]} onPress={handleSubmitSuggestion}>
                <Text style={styles.createButtonText}>Submit</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* Vote Modal */}
      <Modal visible={showVoteModal} animationType="fade" transparent onRequestClose={() => setShowVoteModal(false)}>
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>Rate this Suggestion</Text>
            {/* Show existing suggested tier/points if present on the challenge */}
            {(() => {
              const all = [...(personalChallenges||[]), ...(communityChallenges||[]), ...(suggestedChallenges||[])];
              const target = all.find(c => c.id === voteTargetId);
              const tier = (target as any)?.tier;
              const points = (target as any)?.points;
              const createdAt = target ? new Date((target as any).createdAt || new Date()) : new Date();
              const now = new Date();
              const remainingMs = Math.max(0, (createdAt.getTime() + 3*24*60*60*1000) - now.getTime());
              const remainingDays = Math.floor(remainingMs / (24*60*60*1000));
              const remainingHours = Math.floor((remainingMs % (24*60*60*1000)) / (60*60*1000));
              const votes = (target?.upvotes || 0);
              if (!tier && !points) return (
                <></>
              );
              return (
                <View style={{ marginBottom: theme?.spacing.md }}>
                  {!!tier && (
                    <View style={[styles.badge, { alignSelf: 'flex-start', backgroundColor: `${theme?.colors.primary}10` }]}> 
                      <Star size={14} color={theme?.colors.primary} />
                      <Text style={[styles.badgeText, { color: theme?.colors.primary }]}>Community suggested tier: {tier}</Text>
                    </View>
                  )}
                  {!!points && !tier && (
                    <View style={[styles.badge, { alignSelf: 'flex-start', backgroundColor: `${theme?.colors.primary}10` }]}> 
                      <Star size={14} color={theme?.colors.primary} />
                      <Text style={[styles.badgeText, { color: theme?.colors.primary }]}>Community suggested points: {points}</Text>
                    </View>
                  )}
                  <Text style={[styles.voteWindowText, { marginTop: theme?.spacing.sm }]}>
                    Voting is open for 3 days or until 100 votes are reached · {votes}/100
                  </Text>
                  {!!remainingMs && (
                    <Text style={[styles.voteWindowText, { opacity: 0.8 }]}>Time left: {remainingDays}d {remainingHours}h</Text>
                  )}
                </View>
              );
            })()}
            <Text style={styles.voteLabel}>Spiritual Value / Growth</Text>
            <View style={styles.pillRow}>
              {[1,2,3,4,5].map((n) => (
                <TouchableOpacity key={n} style={[styles.pill, voteSpiritual === n && styles.pillActive]} onPress={() => setVoteSpiritual(n)}>
                  <Text style={[styles.pillText, voteSpiritual === n && styles.pillTextActive]}>{n}</Text>
                </TouchableOpacity>
              ))}
            </View>
            <Text style={[styles.voteLabel, { marginTop: theme?.spacing.md }]}>Effort Required</Text>
            <View style={styles.pillRow}>
              {[1,2,3,4,5].map((n) => (
                <TouchableOpacity key={n} style={[styles.pill, voteEffort === n && styles.pillActive]} onPress={() => setVoteEffort(n)}>
                  <Text style={[styles.pillText, voteEffort === n && styles.pillTextActive]}>{n}</Text>
                </TouchableOpacity>
              ))}
            </View>
            <View style={[styles.formActions, { marginTop: theme?.spacing.md }]}> 
              <TouchableOpacity style={[styles.formButton, styles.cancelButton]} onPress={() => setShowVoteModal(false)}>
                <Text style={styles.cancelButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.formButton, styles.createButton]} onPress={submitVote}>
                <Text style={styles.createButtonText}>Submit Vote</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
      {renderOnboardingOverlay()}
    </View>
  );
});

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme?.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme?.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme?.colors.border,
    backgroundColor: theme?.colors.background,
  },
  backButton: {
    padding: theme?.spacing.sm,
    marginLeft: -theme?.spacing.sm,
  },
  headerTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
  },
  suggestButton: {
    padding: theme?.spacing.sm,
    marginRight: -theme?.spacing.sm,
  },
  categoryTabs: {
    flexDirection: 'row',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: theme?.colors.border,
  },
  categoryTab: {
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    marginRight: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
  },
  activeTab: {
    backgroundColor: `${theme?.colors.primary}15`,
  },
  categoryText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
  },
  activeTabText: {
    color: theme?.colors.primary,
  },
  content: {
    flex: 1,
  },
  scrollContent: {
    padding: theme?.spacing.md,
  },
  listFooter: {
    paddingVertical: theme?.spacing.lg,
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme?.spacing.sm,
  },
  suggestYourOwnButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.lg,
    borderRadius: theme?.borderRadius.full,
    backgroundColor: `${theme?.colors.primary}12`,
    borderWidth: 1,
    borderColor: `${theme?.colors.primary}25`,
    gap: theme?.spacing.sm,
  },
  suggestYourOwnText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.primary,
    fontWeight: '600',
  },
  onboardingOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0,0,0,0.4)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme?.spacing.lg,
  },
  onboardingCard: {
    width: '100%',
    borderRadius: theme?.borderRadius.xl,
    backgroundColor: theme?.colors.surface,
    padding: theme?.spacing.lg,
    gap: theme?.spacing.md,
    borderWidth: 1,
    borderColor: `${theme?.colors.border}80`,
  },
  onboardingTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
  },
  onboardingBody: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
  },
  onboardingError: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.error,
  },
  onboardingSubtle: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    opacity: 0.8,
  },
  onboardingPrimary: {
    borderRadius: theme?.borderRadius.lg,
    paddingVertical: theme?.spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme?.colors.primary,
  },
  onboardingPrimaryText: {
    ...theme?.typography.button,
    color: theme?.colors.text.inverse,
  },
  onboardingSecondary: {
    borderRadius: theme?.borderRadius.lg,
    paddingVertical: theme?.spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: theme?.colors.border,
    backgroundColor: theme?.colors.surface,
  },
  onboardingSecondaryText: {
    ...theme?.typography.button,
    color: theme?.colors.text.primary,
  },
  addChallengeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme?.spacing.md,
    backgroundColor: `${theme?.colors.primary}10`,
    borderRadius: theme?.borderRadius.lg,
    marginBottom: theme?.spacing.md,
    borderWidth: 1,
    borderColor: `${theme?.colors.primary}20`,
    borderStyle: 'dashed',
  },
  addChallengeText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.primary,
    fontWeight: '600',
    marginLeft: theme?.spacing.sm,
  },
  formContainer: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    overflow: 'hidden',
  },
  formTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.md,
  },
  typeSelector: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme?.spacing.md,
  },
  smartPickWrapper: {
    marginBottom: theme?.spacing.lg,
  },
  typeButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme?.spacing.md,
    borderRadius: theme?.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    marginRight: theme?.spacing.sm,
  },
  typeButtonText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    marginLeft: theme?.spacing.xs,
  },
  input: {
    backgroundColor: theme?.colors.background,
    borderRadius: theme?.borderRadius.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    padding: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
  },
  textArea: {
    minHeight: 80,
    textAlignVertical: 'top',
  },
  timePickerContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme?.spacing.md,
  },
  timePickerLabel: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    marginRight: theme?.spacing.md,
  },
  timePicker: {
    flex: 1,
    backgroundColor: theme?.colors.background,
    borderRadius: theme?.borderRadius.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    padding: theme?.spacing.md,
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
  },
  formActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  formButton: {
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.lg,
    borderRadius: theme?.borderRadius.full,
    marginLeft: theme?.spacing.sm,
  },
  cancelButton: {
    backgroundColor: `${theme?.colors.text.secondary}10`,
  },
  cancelButtonText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
  },
  createButton: {
    backgroundColor: theme?.colors.primary,
  },
  createButtonText: {
    ...theme?.typography.body.sans,
    color: '#FFF',
    fontWeight: '600',
  },
  emptyContainer: {
    padding: theme?.spacing.xl,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    textAlign: 'center',
  },
  challengeCard: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    marginBottom: theme?.spacing.md,
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
  cardGradient: {
    ...StyleSheet.absoluteFillObject,
  },
  challengeHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: theme?.spacing.md,
  },
  typeTag: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme?.spacing.xs,
    paddingHorizontal: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
  },
  typeText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
    marginLeft: theme?.spacing.xs,
  },
  timeContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  timeText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginLeft: theme?.spacing.xs,
  },
  challengeTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
    paddingHorizontal: theme?.spacing.md,
    marginBottom: theme?.spacing.sm,
  },
  challengeDescription: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    paddingHorizontal: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
  },
  progressContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
  },
  progressBar: {
    flex: 1,
    height: 8,
    backgroundColor: `${theme?.colors.text.secondary}15`,
    borderRadius: theme?.borderRadius.full,
    marginRight: theme?.spacing.sm,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: theme?.borderRadius.full,
  },
  progressText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
  },
  actionContainer: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    padding: theme?.spacing.md,
    borderTopWidth: 1,
    borderTopColor: theme?.colors.border,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.full,
    marginLeft: theme?.spacing.sm,
  },
  primaryActionButton: {
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.lg,
    borderRadius: theme?.borderRadius.full,
    marginLeft: theme?.spacing.sm,
  },
  actionText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
    marginLeft: theme?.spacing.xs,
  },
  primaryActionText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
    color: theme?.colors.primary,
    textAlign: 'center',
  },
  communityContainer: {
    padding: theme?.spacing.md,
    borderTopWidth: 1,
    borderTopColor: theme?.colors.border,
  },
  participantsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme?.spacing.md,
  },
  participantsText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginLeft: theme?.spacing.sm,
  },
  communityActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  communityButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.full,
    marginLeft: theme?.spacing.sm,
  },
  communityButtonText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
  },
  suggestedContainer: {
    padding: theme?.spacing.md,
    borderTopWidth: 1,
    borderTopColor: theme?.colors.border,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  upvoteContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  upvoteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme?.spacing.xs,
    paddingHorizontal: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
  },
  upvoteText: {
    ...theme?.typography.caption.primary,
    marginLeft: theme?.spacing.xs,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.full,
    backgroundColor: `${theme?.colors.primary}15`,
  },
  addButtonText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.primary,
    fontWeight: '600',
    marginLeft: theme?.spacing.xs,
  },
  
  // Loading and error states
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: theme?.spacing.xl,
  },
  loadingText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    marginTop: theme?.spacing.md,
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: theme?.spacing.xl,
  },
  errorText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.error,
    textAlign: 'center',
    marginBottom: theme?.spacing.md,
  },
  retryButton: {
    backgroundColor: theme?.colors.primary,
    paddingHorizontal: theme?.spacing.lg,
    paddingVertical: theme?.spacing.md,
    borderRadius: 8,
  },
  retryButtonText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.inverse,
    fontWeight: '600',
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.3)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme?.spacing.md,
  },
  modalCard: {
    width: '100%',
    maxWidth: 520,
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.lg,
    borderWidth: 1,
    borderColor: theme?.colors.border,
  },
  modalTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.md,
  },
  voteLabel: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.secondary,
    marginBottom: theme?.spacing.xs,
  },
  pillRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  pill: {
    flex: 1,
    marginHorizontal: 4,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    alignItems: 'center',
  },
  pillActive: {
    backgroundColor: `${theme?.colors.primary}15`,
    borderColor: `${theme?.colors.primary}40`,
  },
  pillText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
  },
  pillTextActive: {
    color: theme?.colors.primary,
  },
  voteWindowText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontSize: 12,
  },
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: 6,
    borderRadius: theme?.borderRadius.full,
    gap: 6,
  },
  badgeText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
  },
  pendingText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontStyle: 'italic',
    marginLeft: theme?.spacing.sm,
  },
  compactInfoRow: {
    marginTop: 4,
    paddingHorizontal: theme?.spacing.md,
    paddingBottom: theme?.spacing.sm,
  },
  compactInfoText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontSize: 12,
  },
});

export default DailyChallengesScreen;