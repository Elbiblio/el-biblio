import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
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
} from '../components/Icons';
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
import { AvatarStack } from '../components/AvatarStack';
import { useTheme } from '@/contexts/ThemeContext';
import { useAuth } from '@/stores/auth';
import { useChallengeStore } from '@/stores/challenge';
import { Theme } from '@/theme';
import { Challenge, ChallengeType } from '@/types/challenges';
import * as Haptics from 'expo-haptics';

type DailyChallengesProps = {
  navigation: any;
};

const CHALLENGE_CATEGORIES = [
  { id: 'personal', label: 'Personal' },
  { id: 'community', label: 'Community' },
  { id: 'suggested', label: 'Suggested' },
];

const CHALLENGE_TYPES = [
  { id: 'virtue', label: 'Develop Virtue', icon: Star, color: '#4CAF50' },
  { id: 'vice', label: 'Reduce Vice', icon: X, color: '#F44336' },
];

const DailyChallengesScreen: React.FC<DailyChallengesProps> = ({ navigation }) => {
  const insets = useSafeAreaInsets();
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const { user } = useAuth();
  
  const {
    // State
    personalChallenges,
    communityChallenges,
    suggestedChallenges,
    activeCategory,
    showNewChallengeForm,
    refreshing,
    
    // Loading states
    isPersonalLoading,
    isCommunityLoading,
    isSuggestedLoading,
    isCreatingLoading,
    isJoiningLoading,
    isUpvotingLoading,
    
    // Error states
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
      await Promise.all([
        fetchPersonalChallenges(1),
        fetchCommunityChallenges(1),
        fetchSuggestedChallenges(1),
      ]);
    } catch (error) {
      console.error('Error loading challenges:', error);
      Alert.alert('Error', 'Failed to load challenges. Please try again.');
    } finally {
      setRefreshing(false);
    }
  }, [fetchPersonalChallenges, fetchCommunityChallenges, fetchSuggestedChallenges, setRefreshing]);
  
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
  
  const renderChallengeCard = (challenge: Challenge) => {
    const isVirtue = challenge.type === 'virtue';
    const color = isVirtue ? theme?.colors.success : theme?.colors.error;
    const CIcon = isVirtue ? Star : X;
    const timeRemaining = getTimeRemaining(challenge.endTime);
    const isExpired = timeRemaining === 'Expired';
    
    return (
      <View style={styles.challengeCard} key={challenge.id}>
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
        
        {challenge.description && (
          <Text style={styles.challengeDescription} numberOfLines={2}>
            {challenge.description}
          </Text>
        )}
        
        {challenge.progress !== undefined && (
          <View style={styles.progressContainer}>
            <View style={styles.progressBar}>
              <View 
                style={[
                  styles.progressFill, 
                  { width: `${challenge.progress}%`, backgroundColor: color }
                ]} 
              />
            </View>
            <Text style={styles.progressText}>{challenge.progress}%</Text>
          </View>
        )}
        
        {challenge.category === 'personal' && (
          <View style={styles.actionContainer}>
            {isExpired ? (
              <>
                <TouchableOpacity 
                  style={[styles.actionButton, { backgroundColor: `${theme?.colors.success}15` }]}
                  onPress={() => handleCompleteChallenge(challenge, true)}
                >
                  <Check size={16} color={theme?.colors.success} />
                  <Text style={[styles.actionText, { color: theme?.colors.success }]}>
                    Mark Complete
                  </Text>
                </TouchableOpacity>
                
                <TouchableOpacity 
                  style={[styles.actionButton, { backgroundColor: `${theme?.colors.error}15` }]}
                  onPress={() => handleCompleteChallenge(challenge, false)}
                >
                  <X size={16} color={theme?.colors.error} />
                  <Text style={[styles.actionText, { color: theme?.colors.error }]}>
                    Mark Incomplete
                  </Text>
                </TouchableOpacity>
              </>
            ) : (
              <Text style={styles.pendingText}>
                Complete by {challenge.endTime}
              </Text>
            )}
          </View>
        )}
        
        {challenge.category === 'community' && (
          <View style={styles.communityContainer}>
            <View style={styles.participantsContainer}>
              {challenge.participantAvatars && (
                <AvatarStack
                  users={challenge.participantAvatars as any}
                  maxAvatars={3}
                  size={24}
                />
              )}
              <Text style={styles.participantsText}>
                {challenge.participants} joined
              </Text>
            </View>
            
            <View style={styles.communityActions}>
              <TouchableOpacity 
                style={[
                  styles.communityButton, 
                  { backgroundColor: challenge.hasUpvoted ? `${theme?.colors.primary}20` : `${theme?.colors.text.secondary}10` }
                ]}
                onPress={() => handleUpvoteChallenge(challenge)}
              >
                <ArrowUp 
                  size={16} 
                  color={challenge.hasUpvoted ? theme?.colors.primary : theme?.colors.text.secondary} 
                />
                <Text 
                  style={[
                    styles.communityButtonText, 
                    { color: challenge.hasUpvoted ? theme?.colors.primary : theme?.colors.text.secondary }
                  ]}
                >
                  {challenge.upvotes}
                </Text>
              </TouchableOpacity>
              
              <TouchableOpacity 
                style={[
                  styles.communityButton, 
                  { 
                    backgroundColor: challenge.hasJoined 
                      ? `${theme?.colors.error}15` 
                      : `${theme?.colors.primary}15` 
                  }
                ]}
                onPress={() => handleJoinChallenge(challenge)}
              >
                <Text 
                  style={[
                    styles.communityButtonText, 
                    { 
                      color: challenge.hasJoined 
                        ? theme?.colors.error 
                        : theme?.colors.primary 
                    }
                  ]}
                >
                  {challenge.hasJoined ? 'Leave' : 'Join'}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
        
        {challenge.category === 'suggested' && (
          <View style={styles.suggestedContainer}>
            <View style={styles.upvoteContainer}>
              <TouchableOpacity 
                style={[
                  styles.upvoteButton, 
                  { backgroundColor: challenge.hasUpvoted ? `${theme?.colors.primary}20` : `${theme?.colors.text.secondary}10` }
                ]}
                onPress={() => handleUpvoteChallenge(challenge)}
              >
                <ArrowUp 
                  size={16} 
                  color={challenge.hasUpvoted ? theme?.colors.primary : theme?.colors.text.secondary} 
                />
                <Text 
                  style={[
                    styles.upvoteText, 
                    { color: challenge.hasUpvoted ? theme?.colors.primary : theme?.colors.text.secondary }
                  ]}
                >
                  {challenge.upvotes}
                </Text>
              </TouchableOpacity>
            </View>
            
            <TouchableOpacity 
              style={styles.addButton}
              onPress={() => handleAddSuggestedChallenge(challenge)}
            >
              <Plus size={16} color={theme?.colors.primary} />
              <Text style={styles.addButtonText}>Add to My Challenges</Text>
            </TouchableOpacity>
          </View>
        )}
      </View>
    );
  };
  
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
        challenges = suggestedChallenges;
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
              ? 'You have no personal challenges yet. Create one!' 
              : activeCategory === 'community'
                ? 'No community challenges available right now.'
                : 'No suggested challenges available right now.'}
          </Text>
        </View>
      );
    }
    
    return challenges.map(renderChallengeCard);
  };
  
  const renderNewChallengeForm = () => {
    if (!showNewChallengeForm) return null;
    
    return (
      <Animated.View style={[styles.formContainer, formAnimatedStyle]}>
        <Text style={styles.formTitle}>Create New Challenge</Text>
        
        <View style={styles.typeSelector}>
          {CHALLENGE_TYPES.map(type => (
            <TouchableOpacity
              key={type.id}
              style={[
                styles.typeButton,
                newChallenge.type === type.id && { 
                  backgroundColor: `${type.color}15`,
                  borderColor: type.color,
                }
              ]}
              onPress={() => setNewChallenge(prev => ({ ...prev, type: type.id as ChallengeType }))}
            >
              <type.icon size={16} color={type.color} />
              <Text style={[
                styles.typeButtonText,
                newChallenge.type === type.id && { color: type.color }
              ]}>
                {type.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
        
        <TextInput
          style={styles.input}
          placeholder="Challenge title"
          value={newChallenge.title}
          onChangeText={text => setNewChallenge(prev => ({ ...prev, title: text }))}
        />
        
        <TextInput
          style={[styles.input, styles.textArea]}
          placeholder="Description (optional)"
          value={newChallenge.description}
          onChangeText={text => setNewChallenge(prev => ({ ...prev, description: text }))}
          multiline
          numberOfLines={3}
        />
        
        <View style={styles.timePickerContainer}>
          <Text style={styles.timePickerLabel}>Complete by:</Text>
          <TextInput
            style={styles.timePicker}
            placeholder="21:00"
            value={newChallenge.endTime}
            onChangeText={text => setNewChallenge(prev => ({ ...prev, endTime: text }))}
            keyboardType="numbers-and-punctuation"
          />
        </View>
        
        {createError && (
          <Text style={styles.errorText}>{createError}</Text>
        )}
        
        <View style={styles.formActions}>
          <TouchableOpacity 
            style={[styles.formButton, styles.cancelButton]}
            onPress={toggleNewChallengeForm}
          >
            <Text style={styles.cancelButtonText}>Cancel</Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.formButton, styles.createButton, isCreatingLoading && { opacity: 0.6 }]}
            onPress={handleCreateChallenge}
            disabled={isCreatingLoading}
          >
            {isCreatingLoading ? (
              <ActivityIndicator size="small" color={theme?.colors.text.inverse} />
            ) : (
              <Text style={styles.createButtonText}>Create Challenge</Text>
            )}
          </TouchableOpacity>
        </View>
      </Animated.View>
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
      </View>
      
      <ScrollView
        style={styles.content}
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {activeCategory === 'personal' && (
          <TouchableOpacity 
            style={styles.addChallengeButton}
            onPress={toggleNewChallengeForm}
          >
            <Plus size={20} color={theme?.colors.primary} />
            <Text style={styles.addChallengeText}>Create New Challenge</Text>
          </TouchableOpacity>
        )}
        
        {renderNewChallengeForm()}
        
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