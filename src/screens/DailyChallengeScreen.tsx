import React, { useState, useEffect, useCallback } from 'react';
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
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import {
  ArrowLeft,
  Plus,
  Check,
  X,
  ThumbsUp,
  Users,
  Clock,
  Trophy,
  Star,
  ArrowUp,
  Calendar,
  Sparkle
} from '@/components/Icons';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSequence,
  withSpring,
  interpolate,
  Extrapolation
} from 'react-native-reanimated';
import { format, isToday, parseISO, differenceInHours, addDays } from 'date-fns';
import { AvatarStack } from '@/components/AvatarStack';
import { useTheme } from '@/contexts/ThemeContext';
import { useVirtueStore } from '@/stores/StoreProvider';
import { useAuthStore } from '@/stores/StoreProvider';
import { useChallengeStore } from '@/stores/ChallengeStore';
import { Theme } from '@/theme';
import { Challenge, ChallengeType } from '@/types/challenges';
import * as Haptics from 'expo-haptics';

type DailyChallengesProps = {
  navigation: any;
};

const CHALLENGE_CATEGORIES = [
  { id: 'personal', label: 'Joined' },
  { id: 'community', label: 'Community' },
  { id: 'suggested', label: 'Suggested' },
];

const CHALLENGE_TYPES = [
  { id: 'virtue', label: 'Develop Virtue', icon: Star, color: '#4CAF50' },
  { id: 'vice', label: 'Reduce Vice', icon: X, color: '#F44336' },
];

const DailyChallengesScreen = ({ navigation }: DailyChallengesProps) => {
  const insets = useSafeAreaInsets();
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  
  const { currentGoalVirtueId, virtues: allVirtues } = useVirtueStore();
  const { user } = useAuthStore();
  
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
    
    // State management
    setActiveCategory,
    setShowNewChallengeForm,
    setRefreshing,
    clearErrors,
    refreshAll,
    // expose pagination for infinite scroll
    state,
  } = useChallengeStore();
  
  const [newChallenge, setNewChallenge] = useState({
    title: '',
    type: 'virtue' as ChallengeType,
    endTime: '21:00',
    description: '',
  });
  
  // Animation values
  const headerHeight = useSharedValue(0);
  const formHeight = useSharedValue(0);
  const listOpacity = useSharedValue(0);
  
  useEffect(() => {
    // Animate header and list on mount
    headerHeight.value = withTiming(56, { duration: 500 });
    listOpacity.value = withTiming(1, { duration: 800 });
    
    // Load challenges
    loadChallenges();
  }, []);
  
  const loadChallenges = useCallback(async () => {
    setRefreshing(true);
    try {
      const promises: Promise<any>[] = [];
      if (!personalChallenges || personalChallenges.length === 0) {
        promises.push(fetchPersonalChallenges(1));
      }
      if (!communityChallenges || communityChallenges.length === 0) {
        promises.push(fetchCommunityChallenges(1));
      }
      if (!suggestedChallenges || suggestedChallenges.length === 0) {
        promises.push(fetchSuggestedChallenges(1));
      }
      if (promises.length > 0) {
        await Promise.all(promises);
      }
    } catch (error) {
      console.error('Error loading challenges:', error);
      Alert.alert('Error', 'Failed to load challenges. Please try again.');
    } finally {
      setRefreshing(false);
    }
  }, [personalChallenges, communityChallenges, suggestedChallenges, fetchPersonalChallenges, fetchCommunityChallenges, fetchSuggestedChallenges, setRefreshing]);
  
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
    
    const result = await createChallenge({
      title: newChallenge.title,
      description: newChallenge.description || 'No description provided',
      type: newChallenge.type,
      category: 'personal',
      endTime: newChallenge.endTime,
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
    }
  };
  
  const handleCompleteChallenge = async (challenge: Challenge, isCompleted: boolean) => {
    const success = await completeChallenge(challenge.id, isCompleted);
    
    if (success) {
      Haptics.notificationAsync(
        isCompleted 
          ? Haptics.NotificationFeedbackType.Success 
          : Haptics.NotificationFeedbackType.Warning
      );
    }
  };
  
  const handleJoinChallenge = async (challenge: Challenge) => {
    const success = await (challenge.hasJoined 
      ? leaveChallenge(challenge.id)
      : joinChallenge(challenge.id)
    );
    
    if (success) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    }
  };
  
  const handleUpvoteChallenge = async (challenge: Challenge) => {
    const success = await upvoteChallenge(challenge.id);
    
    if (success) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    }
  };
  
  const handleAddSuggestedChallenge = async (challenge: Challenge) => {
    const success = await addSuggestedToPersonal(challenge.id);
    
    if (success) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    }
  };
  
  const handleSuggestCommunityChallenge = () => {
    if (!user || (user.points || 0) < 200) {
      Alert.alert(
        'Points Required',
        'You need at least 200 points to suggest community challenges.'
      );
      return;
    }
    
    // Navigate to suggest challenge screen or show modal
    Alert.alert(
      'Suggest Challenge',
      'This would open a form to suggest a new community challenge.'
    );
  };
  
  const getTimeRemaining = (endTime: string) => {
    const [hours, minutes] = endTime.split(':').map(Number);
    const today = new Date();
    const target = new Date();
    target.setHours(hours, minutes, 0, 0);
    
    if (target < today) {
      return 'Expired';
    }
    
    const diffHours = differenceInHours(target, today);
    const diffMinutes = Math.floor((target.getTime() - today.getTime()) / (1000 * 60)) % 60;
    
    if (diffHours > 0) {
      return `${diffHours}h ${diffMinutes}m left`;
    }
    return `${diffMinutes}m left`;
  };
  
  // Animated styles
  const headerAnimatedStyle = useAnimatedStyle(() => ({
    height: headerHeight.value,
    opacity: interpolate(headerHeight.value, [0, 56], [0, 1], Extrapolation.CLAMP),
  }));

  // Render a single challenge card
  const renderChallengeCard = (challenge: Challenge) => {
    const isVirtue = challenge.type === 'virtue';
    const color = isVirtue ? theme?.colors.success : theme?.colors.error;
    const CIcon = isVirtue ? Star : X;
    const timeRemaining = getTimeRemaining(challenge.endTime);
    const isExpired = timeRemaining === 'Expired';

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
      </TouchableOpacity>
    );
  };

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
        // Featured or goal-aware suggestions (match virtue name in title/description)
        const goalVirtue = (allVirtues || []).find(v => v.id === currentGoalVirtueId);
        const goalName = goalVirtue?.name?.toLowerCase();
        challenges = (suggestedChallenges || []).filter(c => {
          if (c.isFeatured) return true;
          if (!goalName) return false;
          const hay = `${c.title || ''} ${c.description || ''}`.toLowerCase();
          return hay.includes(goalName);
        });
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
      return (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>
            {activeCategory === 'personal' 
              ? 'You have not joined any challenges yet. Join a challenge to get started.' 
              : activeCategory === 'community'
                ? 'No community challenges available right now.'
                : 'No suggested challenges available right now.'}
          </Text>
        </View>
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
        renderItem={({ item }) => renderChallengeCard(item)}
        onEndReached={loadMore}
        onEndReachedThreshold={0.4}
        ListFooterComponent={state.pagination.hasMore && isLoading ? (
          <View style={{ paddingVertical: 16, alignItems: 'center' }}>
            <ActivityIndicator color={theme?.colors.primary} />
          </View>
        ) : null}
      />
    );
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <Animated.View style={[styles.header, headerAnimatedStyle]}>
        <TouchableOpacity 
          style={styles.backButton}
          onPress={() => navigation.goBack()}
        >
          <ArrowLeft size={24} color={theme?.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Daily Challenges</Text>
        {user && (user.points || 0) >= 200 && activeCategory === 'community' && (
          <TouchableOpacity 
            style={styles.suggestButton}
            onPress={handleSuggestCommunityChallenge}
          >
            <Sparkle size={20} color={theme?.colors.primary} />
          </TouchableOpacity>
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
            onPress={() => setActiveCategory(category.id as 'personal' | 'community' | 'suggested')}
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

      <ScrollView
        style={styles.content}
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {/* For Joined tab, we won't show create form/button */}
        {activeCategory !== 'personal' && renderNewChallengeForm()}

        <Animated.View style={listAnimatedStyle}>
          {renderChallenges()}
        </Animated.View>
      </ScrollView>
    </View>
  );
};

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
  actionText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
    marginLeft: theme?.spacing.xs,
  },
  pendingText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontStyle: 'italic',
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
});

export default DailyChallengesScreen; 