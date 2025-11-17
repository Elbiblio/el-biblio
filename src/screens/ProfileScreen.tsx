import React, { useState, useMemo, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  ActivityIndicator,
  Platform,
  Switch
} from 'react-native';
import { useTheme, useThemeVariant } from '@/contexts/ThemeContext';
import { Theme, ThemeVariant, themeColors } from '@/theme';
import { 
  useAuthStore,
  useReflectionStore,
  useNotesStore,
  useChallengeStore,
  useLeaderboardStore,
  useVirtueStore,
  useMeditationStore,
  usePreferencesStore,
} from '@/stores/StoreProvider';
import AvatarSelectionModal from '@/components/AvatarSelectionModal';
import GuestUpgradeModal from '@/components/GuestUpgradeModal';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AllVirtues, Virtue, VirtueProgress, Reflection, MeditationSession, UserStats, Activity, BackendUserStats } from '@/types';
import * as Haptics from 'expo-haptics';
import { Shield, BookOpen, MessageCircle, FileText, Award, Edit2, Users, ArrowRight, ArrowCounterClockwise, BookmarkSimple, Calendar, Clock } from '@/components/Icons';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RootStackParamList } from '@/types';
import { toast } from 'sonner-native';
import { syncDailyNuggets, disableDailyNuggets } from '@/tasks/dailyNuggetOrchestrator';
import { RefreshControl } from 'react-native';
import { apiClient, endpoints } from '@/api/client';

const ProfileScreen = () => {
  const theme = useTheme();
  const setThemeVariant = useThemeVariant();
  const { user, updateAvatar, isGuest, upgradeGuestAccount, error, isLoading } = useAuthStore();
  const [avatarModalVisible, setAvatarModalVisible] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [showUpgradeModal, setShowUpgradeModal] = useState(false);
  const [isUpgradeSubmitting, setIsUpgradeSubmitting] = useState(false);
  const [upgradeError, setUpgradeError] = useState<string | null>(null);

  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  
  const styles = useMemo(() => createStyles(theme), [theme]);

  // Store hooks
  const reflectionStore = useReflectionStore();
  const { reflections } = reflectionStore.state;
  const { fetchReflectionsByUser } = reflectionStore;

  const notesStore = useNotesStore();
  const { notes } = notesStore.state;
  const { fetchNotes } = notesStore;

  const challengeStore = useChallengeStore();
  const { personalChallenges } = challengeStore.state;
  const { fetchPersonalChallenges } = challengeStore;

  const leaderboardStore = useLeaderboardStore();
  const { globalLeaderboard } = leaderboardStore.state;
  const { fetchGlobalLeaderboard } = leaderboardStore;

  const virtueStore = useVirtueStore();
  const { virtues, userProgress } = virtueStore.state;
  const { fetchVirtues, fetchUserProgress } = virtueStore;

  const meditationStore = useMeditationStore();
  const { sessions } = meditationStore.state;

  const preferencesStore = usePreferencesStore();
  const { showDailyNuggets } = preferencesStore.state;

  // State for user stats and activity
  const [userStats, setUserStats] = useState<UserStats | null>(null);
  const [recentActivity, setRecentActivity] = useState<Activity[]>([]);
  const [isStatsLoading, setIsStatsLoading] = useState(false);
  const [isActivityLoading, setIsActivityLoading] = useState(false);

  // Fetch user stats and activity
  const fetchUserStats = useCallback(async () => {
    if (!user) return;

    setIsStatsLoading(true);
    try {
      const response = await apiClient.get<BackendUserStats>(endpoints.users.stats(user.id));
      const b = response.data;
      const mapped: UserStats = {
        totalPoints: b.total_points ?? user.points ?? 0,
        totalReflections: b.total_reflections ?? 0,
        totalNotes: 0,
        totalChallenges: 0,
        totalBookmarks: b.total_bookmarks ?? 0,
        totalMeditationMinutes: 0,
        totalActiveDays: b.total_active_days ?? 0,
        currentStreak: b.current_streak ?? 0,
        longestStreak: b.longest_streak ?? 0,
        // Optional extended fields
        totalVersesRead: b.total_verses_read,
        totalActivities: b.total_activities,
        totalMeditationSessions: b.total_meditation_sessions,
        totalChallengesCompleted: b.total_challenges_completed,
        totalActiveTime: b.total_active_time,
        rank: b.rank,
        level: b.level,
        favoriteThemes: b.favorite_themes,
        // Not provided by this endpoint
        topVirtues: [],
        recentActivity: [],
      };
      setUserStats(mapped);
    } catch (error) {
      console.error('Error fetching user stats:', error);
    } finally {
      setIsStatsLoading(false);
    }
  }, [user]);

  const fetchRecentActivity = useCallback(async () => {
    if (!user) return;

    setIsActivityLoading(true);
    try {
      const response = await apiClient.get<Activity[]>(
        endpoints.users.activity(user.id),
        { include: ['subject'], per_page: 10 }
      );
      setRecentActivity(response.data);
    } catch (error) {
      console.error('Error fetching recent activity:', error);
    } finally {
      setIsActivityLoading(false);
    }
  }, [user]);

  // Fetch data on mount
  useEffect(() => {
    fetchUserStats();
    fetchRecentActivity();
  }, [fetchUserStats, fetchRecentActivity]);

  // Real user stats from API data
  const userStatsData = React.useMemo(() => {
    const defaultVirtues = [
      { name: 'love' as AllVirtues, progress: 85 },
      { name: 'faith' as AllVirtues, progress: 72 },
      { name: 'wisdom' as AllVirtues, progress: 65 },
      { name: 'perseverance' as AllVirtues, progress: 58 }
    ];
    
    // Use actual virtue progress from API
    const virtueProgress = userProgress || {};
    const topVirtues = Object.entries(virtueProgress)
      .map(([virtueId, progress]) => {
        const virtue = virtues.find((v: Virtue) => v.id === virtueId);
        return {
          name: (virtue?.name || virtueId) as AllVirtues,
          progress: Math.round(((progress as VirtueProgress).current_level / (progress as VirtueProgress).total_levels) * 100)
        };
      })
      .sort((a, b) => b.progress - a.progress)
      .slice(0, 4);
    
    // Use API stats if available, fallback to calculated values
    const stats = userStats;
    
    return {
      totalPoints: stats?.totalPoints || user?.points || 0,
      totalReflections: stats?.totalReflections || (reflections?.length ?? 0),
      totalNotes: stats?.totalNotes || (notes?.length ?? 0),
      totalChallenges: stats?.totalChallenges || (personalChallenges?.length ?? 0),
      totalComments: (reflections ?? []).reduce((acc: number, reflection: Reflection) => acc + (reflection.comments?.length || 0), 0),
      totalBookmarks: stats?.totalBookmarks || 0,
      totalMeditationMinutes: stats?.totalMeditationMinutes || (sessions?.reduce((total: number, session: MeditationSession) => total + (session.duration_minutes || 0), 0) ?? 0),
      totalActiveDays: stats?.totalActiveDays || 0,
      currentStreak: stats?.currentStreak || 0,
      longestStreak: stats?.longestStreak || 0,
      topVirtues: topVirtues.length > 0 ? topVirtues : defaultVirtues,
      recentActivity: recentActivity || []
    };
  }, [user, reflections, notes, virtues, userProgress, personalChallenges, sessions, userStats, recentActivity]);

  const handleAvatarChange = async (avatarUrl: string) => {
    setIsUpdating(true);
    try {
      await updateAvatar(avatarUrl);
      setAvatarModalVisible(false);
    } finally {
      setIsUpdating(false);
    }
  };

  const handleOpenAvatarModal = () => {
    if (isGuest) {
      setUpgradeError(null);
      setShowUpgradeModal(true);
      return;
    }
    setAvatarModalVisible(true);
  };

  const handleThemeChange = (themeVariant: ThemeVariant) => {
    setThemeVariant(themeVariant);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  };

  const handleToggleDailyNuggets = async (enabled: boolean) => {
    try {
      await preferencesStore.setShowDailyNuggets(enabled);
      Haptics.selectionAsync();

      if (enabled) {
        const result = await syncDailyNuggets({ triggerInSeconds: 5 * 60 });
        if (result.scheduled) {
          toast.success('Daily nuggets will show up during your day');
        } else if (result.reason === 'cooldown') {
          toast('Daily nuggets are already queued — watch for today\'s reminder');
        }
      } else {
        await disableDailyNuggets();
        toast.success('Daily nuggets are paused');
      }
    } catch (error) {
      console.error('Failed to toggle daily nuggets preference', error);
      toast.error('Unable to update daily nuggets preference');
    }
  };

  // Load user data on component mount
  React.useEffect(() => {
    if (user?.id) {
      fetchReflectionsByUser(user.id, 1);
      fetchNotes(1);
      fetchPersonalChallenges(1);
      fetchGlobalLeaderboard();
      fetchVirtues();
      fetchUserProgress();
    }
  }, [user?.id, fetchReflectionsByUser, fetchNotes, fetchPersonalChallenges, fetchGlobalLeaderboard, fetchVirtues, fetchUserProgress]);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      if (user?.id) {
        await Promise.all([
          fetchReflectionsByUser(user.id, 1),
          fetchNotes(1),
          fetchPersonalChallenges(1),
          fetchGlobalLeaderboard(),
          fetchUserStats(),
          fetchRecentActivity(),
        ]);
        toast.success('Profile updated');
      }
    } catch (error) {
      console.error('Error refreshing profile:', error);
      toast.error('Failed to refresh profile');
    } finally {
      setIsRefreshing(false);
    }
  };

  const handleStartUpgrade = () => {
    setUpgradeError(null);
    setShowUpgradeModal(true);
  };

  const handleUpgradeSubmit = async ({
    firstName,
    lastName,
    email,
    password,
    avatar,
  }: {
    firstName: string;
    lastName: string;
    email: string;
    password: string;
    avatar?: string;
  }) => {
    setUpgradeError(null);
    setIsUpgradeSubmitting(true);
    const success = await upgradeGuestAccount({
      first_name: firstName,
      last_name: lastName,
      email,
      password,
      avatar,
    });

    if (success) {
      toast.success('Welcome to the full El-biblio experience!');
      setShowUpgradeModal(false);
      await handleRefresh();
    } else {
      setUpgradeError(error || 'We could not upgrade your account. Please try again.');
    }

    setIsUpgradeSubmitting(false);
    return success;
  };

  if (!user) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={theme.colors.primary} />
      </View>
    );
  }

  const getVirtueColor = (virtue: AllVirtues): string => {
    // Different color based on virtue type
    if (['love', 'compassion', 'kindness', 'generosity'].includes(virtue)) {
      return theme.colors.like;
    } else if (['knowledge', 'wisdom', 'discernment'].includes(virtue)) {
      return theme.colors.info;
    } else if (['faith', 'hope', 'perseverance'].includes(virtue)) {
      return theme.colors.primary;
    } else if (['humility', 'patience', 'gentleness'].includes(virtue)) {
      return theme.colors.success;
    }
    return theme.colors.secondary;
  };

  // Determine current theme variant
  const getCurrentThemeVariant = (): ThemeVariant => {
    // Compare theme.colors with themeColors to find the matching variant
    for (const [variant, colors] of Object.entries(themeColors)) {
      if (colors.light.primary === theme.colors.primary || 
          colors.dark.primary === theme.colors.primary) {
        return variant as ThemeVariant;
      }
    }
    return 'sage'; // Default fallback
  };

  const currentThemeVariant = getCurrentThemeVariant();

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <ScrollView 
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={handleRefresh}
            colors={[theme.colors.primary]}
            tintColor={theme.colors.primary}
          />
        }
      >
        {/* Profile Header */}
        <View style={styles.header}>
          {/* Refresh Button */}
          <TouchableOpacity 
            style={styles.refreshButton}
            onPress={handleRefresh}
            disabled={isRefreshing}
          >
            <ArrowCounterClockwise 
              size={20} 
              color={theme.colors.text.secondary} 
            />
          </TouchableOpacity>

          {/* Avatar */}
          <TouchableOpacity 
            style={styles.avatarContainer}
            onPress={handleOpenAvatarModal}
            disabled={isUpdating}
          >
            {isUpdating ? (
              <View style={styles.avatarLoading}>
                <ActivityIndicator color={theme.colors.primary} />
              </View>
            ) : (
              <>
                <Image 
                  source={{ 
                    uri: user.avatar || 'https://api.elbiblio.com/avatars/1.png' 
                  }} 
                  style={styles.avatar} 
                />
                <View style={styles.editIconContainer}>
                  <Edit2 size={16} color={theme.colors.text.inverse} />
                </View>
              </>
            )}
          </TouchableOpacity>

          {/* User Details */}
          <Text style={styles.userName}>
            {user.first_name} {user.last_name}
          </Text>
          
          <View style={styles.pointsContainer}>
            <Award size={20} color={theme.colors.primary} />
            <Text style={styles.pointsText}>{user.points || 0} points</Text>
          </View>

          {isGuest && (
            <View style={styles.guestUpgradeCard}>
              <Text style={styles.guestUpgradeTitle}>Complete your profile</Text>
              <Text style={styles.guestUpgradeSubtitle}>
                Add your details to join community features, share reflections, and track your journey across devices.
              </Text>
              <TouchableOpacity
                style={styles.guestUpgradeButton}
                onPress={handleStartUpgrade}
                disabled={isUpgradeSubmitting || isLoading}
              >
                <Text style={styles.guestUpgradeButtonText}>Upgrade account</Text>
                <ArrowRight size={16} color={theme.colors.text.inverse} />
              </TouchableOpacity>
            </View>
          )}

          {userStatsData.totalPoints >= 200 && (
            <TouchableOpacity
              style={styles.donateButton}
              onPress={() => {
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                navigation.navigate('DonateScreen');
              }}
            >
              <Text style={styles.donateButtonText}>Support ElBiblio</Text>
              <ArrowRight size={16} color={theme.colors.text.inverse} />
            </TouchableOpacity>
          )}
        </View>

        {/* User Ranking */}
        {(globalLeaderboard?.length ?? 0) > 0 && (
          <View style={styles.rankingContainer}>
            <Text style={styles.rankingText}>
              {(() => {
                const idx = (globalLeaderboard ?? []).findIndex(entry => entry.user.id === user.id);
                return `Rank #${idx >= 0 ? idx + 1 : 'N/A'}`;
              })()}
            </Text>
            <Text style={styles.rankingSubtext}>Global Ranking</Text>
          </View>
        )}
        {/* Top Virtues */}
        <View style={styles.sectionContainer}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Top Virtues</Text>
            <Text style={styles.sectionSubtitle}>Learning Progress</Text>
          </View>
          <Text style={styles.sectionDisclaimer}>
            Guidance only: virtue points/progress are not a rank or true measure of spiritual progress.
          </Text>
          <View style={styles.virtuesContainer}>
            {userStatsData.topVirtues.map((virtueData, index) => (
              <View key={index} style={styles.virtueItem}>
                <View 
                  style={[
                    styles.virtueChip,
                    { backgroundColor: getVirtueColor(virtueData.name) }
                  ]}
                >
                  <Text style={styles.virtueText}>
                    {virtueData.name.charAt(0).toUpperCase() + virtueData.name.slice(1)}
                  </Text>
                </View>
                <View style={styles.progressContainer}>
                  <View 
                    style={[
                      styles.progressBar, 
                      { 
                        width: `${virtueData.progress}%`,
                        backgroundColor: getVirtueColor(virtueData.name)
                      }
                    ]} 
                  />
                  <Text style={styles.progressText}>{virtueData.progress}%</Text>
                </View>
              </View>
            ))}
          </View>
        </View>

        {/* Leaderboard Link */}
        <TouchableOpacity 
          style={styles.leaderboardButton}
          onPress={() => {
            // Navigate to leaderboard
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            navigation.navigate("LeaderboardScreen")
          }}
        >
          <View style={styles.leaderboardIconContainer}>
            <Users size={20} color={theme.colors.text.inverse} />
          </View>
          <Text style={styles.leaderboardText}>Global Leaderboard</Text>
          <ArrowRight size={18} color={theme.colors.text.secondary} />
        </TouchableOpacity>

        {/* Reconfigure Daily Path */}
        <TouchableOpacity 
          style={styles.leaderboardButton}
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            navigation.navigate('CitizenshipSetupScreen');
          }}
        >
          <View style={styles.leaderboardIconContainer}>
            <BookOpen size={20} color={theme.colors.text.inverse} />
          </View>
          <Text style={styles.leaderboardText}>Reconfigure daily path</Text>
          <ArrowRight size={18} color={theme.colors.text.secondary} />
        </TouchableOpacity>

        {/* Habit Conquest Progress */}
        <TouchableOpacity 
          style={styles.leaderboardButton}
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            navigation.navigate('HabitConquestProgressScreen');
          }}
        >
          <View style={styles.leaderboardIconContainer}>
            <Shield size={20} color={theme.colors.text.inverse} />
          </View>
          <Text style={styles.leaderboardText}>Habit Conquest progress</Text>
          <ArrowRight size={18} color={theme.colors.text.secondary} />
        </TouchableOpacity>

        {/* Stats */}
        <View style={styles.sectionContainer}>
          <Text style={styles.sectionTitle}>Activity</Text>
          <View style={styles.statsGrid}>
            <View style={styles.statCard}>
              <Shield size={24} color={theme.colors.primary} />
              <Text style={styles.statValue}>{userStatsData.totalChallenges}</Text>
              <Text style={styles.statLabel}>Challenges</Text>
            </View>
            
            <View style={styles.statCard}>
              <MessageCircle size={24} color={theme.colors.info} />
              <Text style={styles.statValue}>{userStatsData.totalComments}</Text>
              <Text style={styles.statLabel}>Comments</Text>
            </View>
            
            <View style={styles.statCard}>
              <BookOpen size={24} color={theme.colors.success} />
              <Text style={styles.statValue}>{userStatsData.totalReflections}</Text>
              <Text style={styles.statLabel}>Reflections</Text>
            </View>
            
            <View style={styles.statCard}>
              <FileText size={24} color={theme.colors.secondary} />
              <Text style={styles.statValue}>{userStatsData.totalNotes}</Text>
              <Text style={styles.statLabel}>Notes</Text>
            </View>
            
            <View style={styles.statCard}>
              <BookmarkSimple size={24} color={theme.colors.warning} />
              <Text style={styles.statValue}>{userStatsData.totalBookmarks}</Text>
              <Text style={styles.statLabel}>Bookmarks</Text>
            </View>
            
            <View style={styles.statCard}>
              <Clock size={24} color={theme.colors.info} />
              <Text style={styles.statValue}>{userStatsData.totalMeditationMinutes}</Text>
              <Text style={styles.statLabel}>Meditation (min)</Text>
            </View>
            
            <View style={styles.statCard}>
              <Calendar size={24} color={theme.colors.success} />
              <Text style={styles.statValue}>{userStatsData.totalActiveDays}</Text>
              <Text style={styles.statLabel}>Active Days</Text>
            </View>
            
            <View style={styles.statCard}>
              <Award size={24} color={theme.colors.primary} />
              <Text style={styles.statValue}>{userStatsData.currentStreak}</Text>
              <Text style={styles.statLabel}>Current Streak</Text>
            </View>
            
            <View style={styles.statCard}>
              <Award size={24} color={theme.colors.warning} />
              <Text style={styles.statValue}>{userStatsData.longestStreak}</Text>
              <Text style={styles.statLabel}>Longest Streak</Text>
            </View>
          </View>
        </View>

        {/* Daily Nuggets */}
        <View style={styles.sectionContainer}>
          <View style={styles.switchRow}>
            <View style={{ flex: 1 }}>
              <Text style={styles.sectionTitle}>Daily Nuggets</Text>
              <Text style={styles.sectionSubtitle}>
                Receive timely kingdom reminders tailored to your activity.
              </Text>
            </View>
            <Switch
              value={showDailyNuggets}
              onValueChange={handleToggleDailyNuggets}
              trackColor={{ false: theme.colors.surfaceVariant, true: theme.colors.primary }}
              thumbColor={showDailyNuggets ? theme.colors.text.inverse : theme.colors.text.secondary}
            />
          </View>
        </View>

        {/* Theme Selection */}
        <View style={styles.sectionContainer}>
          <Text style={styles.sectionTitle}>Theme</Text>
          <ScrollView 
            style={styles.themesScrollView}
            contentContainerStyle={{ gap: theme.spacing.md }}
            showsVerticalScrollIndicator={false}
          >
            {(Object.entries(themeColors) as [ThemeVariant, typeof themeColors.sage][]).map(
              ([variant, colors]) => (
                <TouchableOpacity
                  key={variant}
                  style={[
                    styles.themeOption,
                    variant === currentThemeVariant && styles.selectedTheme,
                    { backgroundColor: colors.light.surface }
                  ]}
                  onPress={() => handleThemeChange(variant as ThemeVariant)}
                >
                  <View style={[
                    styles.colorPreview, 
                    { backgroundColor: colors.light.primary }
                  ]} />
                  <View style={styles.themeTextContainer}>
                    <Text style={[
                      styles.themeTitle,
                      { color: colors.light.text.primary }
                    ]}>
                      {colors.name}
                    </Text>
                    <Text style={[
                      styles.themeDescription,
                      { color: colors.light.text.secondary }
                    ]}>
                      {colors.description}
                    </Text>
                  </View>
                </TouchableOpacity>
              )
            )}
          </ScrollView>
        </View>
      </ScrollView>

      <AvatarSelectionModal
        visible={avatarModalVisible}
        onClose={() => setAvatarModalVisible(false)}
        onSelect={handleAvatarChange}
      />

      <GuestUpgradeModal
        visible={showUpgradeModal}
        onClose={() => setShowUpgradeModal(false)}
        onSubmit={handleUpgradeSubmit}
        onSuccess={() => toast.success('Profile updated successfully!')}
        isSubmitting={isUpgradeSubmitting}
        errorMessage={upgradeError}
        initialValues={{
          firstName: user.first_name,
          lastName: user.last_name,
          email: user.email ?? '',
          avatar: user.avatar,
        }}
      />
    </SafeAreaView>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: theme.colors.background,
  },
  scrollContent: {
    paddingBottom: theme.spacing.xl,
  },
  header: {
    alignItems: 'center',
    paddingVertical: theme.spacing.xl,
    backgroundColor: theme.colors.surface,
    borderBottomLeftRadius: theme.borderRadius.lg,
    borderBottomRightRadius: theme.borderRadius.lg,
    marginBottom: theme.spacing.lg,
    ...theme.shadows.md,
  },
  refreshButton: {
    position: 'absolute',
    top: theme.spacing.md,
    right: theme.spacing.md,
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: theme.colors.surfaceVariant,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1,
  },
  avatarContainer: {
    width: 120,
    height: 120,
    borderRadius: 60,
    marginBottom: theme.spacing.md,
    backgroundColor: theme.colors.surfaceVariant,
    ...Platform.select({
      ios: {
        shadowColor: theme.colors.shadow,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.15,
        shadowRadius: 10,
      },
      android: {
        elevation: 6,
      },
    }),
  },
  avatar: {
    width: '100%',
    height: '100%',
    borderRadius: 60,
  },
  avatarLoading: {
    width: '100%',
    height: '100%',
    borderRadius: 60,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: theme.colors.surfaceVariant,
  },
  editIconContainer: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    backgroundColor: theme.colors.primary,
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 3,
    borderColor: theme.colors.background,
  },
  userName: {
    ...theme.typography.heading.large,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  pointsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surfaceVariant,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
  },
  pointsText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    marginLeft: theme.spacing.xs,
  },
  donateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    marginTop: theme.spacing.md,
    backgroundColor: theme.colors.primary,
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
  },
  donateButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  guestUpgradeCard: {
    width: '100%',
    marginTop: theme.spacing.lg,
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surfaceVariant,
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  guestUpgradeTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  guestUpgradeSubtitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
  },
  guestUpgradeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.primary,
  },
  guestUpgradeButtonText: {
    ...theme.typography.button.primary,
    color: theme.colors.text.inverse,
  },
  rankingContainer: {
    alignItems: 'center',
    marginTop: theme.spacing.sm,
  },
  rankingText: {
    ...theme.typography.heading.small,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  rankingSubtext: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.xs,
  },
  sectionContainer: {
    marginHorizontal: theme.spacing.lg,
    marginTop: theme.spacing.lg,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    ...theme.shadows.sm,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.md,
  },
  switchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.md,
  },
  sectionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  sectionSubtitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  sectionDisclaimer: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.sm,
  },
  virtuesContainer: {
    gap: theme.spacing.md,
  },
  virtueItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.md,
  },
  virtueChip: {
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    minWidth: 100,
    alignItems: 'center',
  },
  virtueText: {
    ...theme.typography.caption.primary,
    color: '#FFFFFF',
  },
  progressContainer: {
    flex: 1,
    height: 8,
    backgroundColor: theme.colors.surfaceVariant,
    borderRadius: theme.borderRadius.full,
    marginRight: theme.spacing.xxl,
    flexDirection: 'row',
    alignItems: 'center',
  },
  progressBar: {
    height: '100%',
    borderRadius: theme.borderRadius.full,
  },
  progressText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginLeft: theme.spacing.md,
    position: 'absolute',
    right: 0 - theme.spacing.xxl,
  },
  leaderboardButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    marginHorizontal: theme.spacing.lg,
    marginTop: theme.spacing.lg,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    ...theme.shadows.sm,
  },
  leaderboardIconContainer: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: theme.colors.primary,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: theme.spacing.md,
  },
  leaderboardText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    flex: 1,
  },
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    gap: theme.spacing.md,
  },
  statCard: {
    flex: 1,
    minWidth: '45%',
    alignItems: 'center',
    backgroundColor: theme.colors.surfaceVariant,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
  },
  statValue: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    marginTop: theme.spacing.xs,
  },
  statLabel: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  themesScrollView: {
    minHeight: 300,
  },
  themeOption: {
    flexDirection: 'row',
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
    marginBottom: theme.spacing.sm,
    borderWidth: 1,
    borderColor: 'transparent',
    alignItems: 'center',
  },
  selectedTheme: {
    borderColor: theme.colors.primary,
    borderWidth: 2,
  },
  colorPreview: {
    width: 48,
    height: 48,
    borderRadius: 24,
    marginRight: theme.spacing.md,
  },
  themeTextContainer: {
    flex: 1,
  },
  themeTitle: {
    ...theme.typography.body.sans,
    marginBottom: theme.spacing.xs,
  },
  themeDescription: {
    ...theme.typography.caption.secondary,
  },
});

export default ProfileScreen; 