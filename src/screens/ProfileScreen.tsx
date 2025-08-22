import React, { useState, useMemo, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  ActivityIndicator,
  Platform
} from 'react-native';
import { useTheme, useThemeVariant } from '@/contexts/ThemeContext';
import { Theme, ThemeVariant, themeColors } from '@/theme';
import { useAuth } from '@/stores/auth';
import { useReflectionStore } from '@/stores/reflection';
import { useNotesStore } from '@/stores/notes';
import { useChallengeStore } from '@/stores/challenge';
import { useLeaderboardStore } from '@/stores/leaderboard';
import { useVirtueStore } from '@/stores/virtue';
import { useMeditationStore } from '@/stores/meditation';
import AvatarSelectionModal from '@/components/AvatarSelectionModal';
import { SafeAreaView } from 'react-native-safe-area-context';
import { FoundationalVirtue, AllVirtues, Virtue, VirtueProgress } from '@/types';
import * as Haptics from 'expo-haptics';
import { Shield, BookOpen, MessageCircle, FileText, Award, Edit2, Users, ArrowRight, ArrowCounterClockwise, BookmarkSimple, Calendar, Clock } from '../components/Icons';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RootStackParamList } from '@/types';
import { toast } from 'sonner-native';
import { RefreshControl } from 'react-native';
import apiClient from '@/api/client';

const ProfileScreen = () => {
  const theme = useTheme();
  const setThemeVariant = useThemeVariant();
  const { user, updateAvatar } = useAuth();
  const [avatarModalVisible, setAvatarModalVisible] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  
  const styles = useMemo(() => createStyles(theme), [theme]);

  // Store hooks
  const {
    reflections,
    fetchReflectionsByUser,
    isReflectionsLoading,
  } = useReflectionStore();

  const {
    notes,
    fetchNotes,
    isNotesLoading,
  } = useNotesStore();

  const {
    personalChallenges,
    fetchPersonalChallenges,
    isPersonalLoading,
  } = useChallengeStore();

  const {
    globalLeaderboard,
    fetchGlobalLeaderboard,
  } = useLeaderboardStore();

  const {
    virtues,
    userProgress,
    fetchVirtues,
    fetchUserProgress,
  } = useVirtueStore();

  const {
    sessions,
    getTotalMeditationTime,
  } = useMeditationStore();

  // State for user stats and activity
  const [userStats, setUserStats] = useState<any>(null);
  const [recentActivity, setRecentActivity] = useState<any[]>([]);
  const [isStatsLoading, setIsStatsLoading] = useState(false);
  const [isActivityLoading, setIsActivityLoading] = useState(false);

  // Fetch user stats and activity
  const fetchUserStats = async () => {
    if (!user) return;
    
    setIsStatsLoading(true);
    try {
      const response = await apiClient.get(`/users/${user.id}/stats`);
      if (response.data?.success) {
        setUserStats(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching user stats:', error);
    } finally {
      setIsStatsLoading(false);
    }
  };

  const fetchRecentActivity = async () => {
    if (!user) return;
    
    setIsActivityLoading(true);
    try {
      const response = await apiClient.get(`/users/${user.id}/activity?include=subject&per_page=10`);
      if (response.data?.success) {
        setRecentActivity(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching recent activity:', error);
    } finally {
      setIsActivityLoading(false);
    }
  };

  // Fetch data on mount
  useEffect(() => {
    fetchUserStats();
    fetchRecentActivity();
  }, [user]);

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
    const stats = userStats || {};
    
    return {
      totalPoints: stats.total_points || user?.points || 0,
      totalReflections: stats.total_reflections || reflections.length,
      totalNotes: stats.total_notes || notes.length,
      totalChallenges: stats.total_challenges_completed || personalChallenges.length,
      totalComments: reflections.reduce((acc, reflection) => acc + (reflection.comments?.length || 0), 0),
      totalBookmarks: stats.total_bookmarks || 0,
      totalMeditationMinutes: stats.total_meditation_sessions ? stats.total_meditation_sessions * 10 : sessions.reduce((total, session) => total + session.duration_minutes, 0),
      totalActiveDays: stats.total_active_days || 0,
      currentStreak: stats.current_streak || 0,
      longestStreak: stats.longest_streak || 0,
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

  const handleThemeChange = (themeVariant: ThemeVariant) => {
    setThemeVariant(themeVariant);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
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
            onPress={() => setAvatarModalVisible(true)}
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
          
          {/* User Ranking */}
          {globalLeaderboard.length > 0 && (
            <View style={styles.rankingContainer}>
              <Text style={styles.rankingText}>
                Rank #{globalLeaderboard.findIndex(entry => entry.user.id === user.id) + 1 || 'N/A'}
              </Text>
              <Text style={styles.rankingSubtext}>Global Ranking</Text>
            </View>
          )}
        </View>

        {/* Top Virtues */}
        <View style={styles.sectionContainer}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Top Virtues</Text>
            <Text style={styles.sectionSubtitle}>Learning Progress</Text>
          </View>
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
  sectionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  sectionSubtitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
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