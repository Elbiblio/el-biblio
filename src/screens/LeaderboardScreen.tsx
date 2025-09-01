import React, { useState, useMemo, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  Image,
  TouchableOpacity,
  ActivityIndicator,
  Platform,
  RefreshControl
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme, ThemeVariant } from '@/theme';
import { useAuth } from '@/stores/auth';
import { useLeaderboardStore } from '@/stores/leaderboard';
import * as Haptics from 'expo-haptics';
import { ArrowLeft, Award, ChevronUp, ChevronDown, Filter, Users, Fire, Calendar } from '@/components/Icons';
import { AllVirtues, LeaderboardEntry } from '@/types';
import { toast } from 'sonner-native';

type TimeFilter = 'all' | 'day' | 'week' | 'month';
type LeaderboardType = 'global' | 'theme' | 'timeframe';

const LeaderboardScreen = ({ navigation }: any) => {
  const theme = useTheme();
  const { user } = useAuth();
  const styles = useMemo(() => createStyles(theme), [theme]);
  
  // Leaderboard store
  const {
    globalLeaderboard,
    themeLeaderboard,
    timeframeLeaderboard,
    isGlobalLoading,
    isThemeLoading,
    isTimeframeLoading,
    globalError,
    themeError,
    timeframeError,
    pagination,
    filters,
    fetchGlobalLeaderboard,
    fetchThemeLeaderboard,
    fetchTimeframeLeaderboard,
    fetchUserRank,
    clearErrors,
    setFilters,
  } = useLeaderboardStore();

  const [timeFilter, setTimeFilter] = useState<TimeFilter>('all');
  const [leaderboardType, setLeaderboardType] = useState<LeaderboardType>('global');
  const [filterMenuOpen, setFilterMenuOpen] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [userRank, setUserRank] = useState<{
    rank: number;
    total_users: number;
    user: any;
  } | null>(null);

  // Get current leaderboard data based on type
  const currentLeaderboard = useMemo(() => {
    switch (leaderboardType) {
      case 'global':
        return globalLeaderboard;
      case 'theme':
        return themeLeaderboard;
      case 'timeframe':
        return timeframeLeaderboard;
      default:
        return globalLeaderboard;
    }
  }, [leaderboardType, globalLeaderboard, themeLeaderboard, timeframeLeaderboard]);

  const isLoading = isGlobalLoading || isThemeLoading || isTimeframeLoading;
  const error = globalError || themeError || timeframeError;

  useEffect(() => {
    loadLeaderboard();
    if (user?.id) {
      loadUserRank();
    }
  }, [leaderboardType, timeFilter]);

  useEffect(() => {
    if (error) {
      toast.error(error);
      clearErrors();
    }
  }, [error]);

  const loadLeaderboard = async (page = 1) => {
    try {
      switch (leaderboardType) {
        case 'global':
          await fetchGlobalLeaderboard(page, timeFilter);
          break;
        case 'timeframe':
          await fetchTimeframeLeaderboard(timeFilter, page);
          break;
        case 'theme':
          // For theme leaderboard, you might want to add theme selection
          // For now, using a default theme ID
          await fetchThemeLeaderboard('1', page);
          break;
      }
    } catch (error) {
      console.error('Error loading leaderboard:', error);
    }
  };

  const loadUserRank = async () => {
    if (!user?.id) return;
    
    try {
      const rankData = await fetchUserRank(user.id, timeFilter);
      setUserRank(rankData);
    } catch (error) {
      console.error('Error loading user rank:', error);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadLeaderboard(1);
    if (user?.id) {
      await loadUserRank();
    }
    setRefreshing(false);
  };

  const handleLoadMore = () => {
    if (pagination.hasMore && !isLoading) {
      loadLeaderboard(pagination.currentPage + 1);
    }
  };

  const getVirtueColor = (virtue: AllVirtues): string => {
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

  const getMedalColor = (rank: number): string => {
    switch (rank) {
      case 1: return '#FFD700'; // Gold
      case 2: return '#C0C0C0'; // Silver
      case 3: return '#CD7F32'; // Bronze
      default: return theme.colors.surfaceVariant;
    }
  };

  const handleGoBack = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    navigation.goBack();
  };

  const handleFilterPress = (filter: TimeFilter, type: 'time') => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    if (type === 'time') {
      setTimeFilter(filter);
      setFilters({ timeframe: filter });
    }
    setFilterMenuOpen(false);
  };

  const handleLeaderboardTypeChange = (type: LeaderboardType) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setLeaderboardType(type);
    setFilterMenuOpen(false);
  };

  const renderLeaderboardItem = ({ item, index }: { item: LeaderboardEntry, index: number }) => {
    const isCurrentUser = item.user?.id === user?.id;
    const rank = item.rank || index + 1;
    
    return (
      <View style={[
        styles.leaderboardItem, 
        isCurrentUser && styles.currentUserItem,
        index < 3 && styles.topThreeItem
      ]}>
        <View style={styles.rankContainer}>
          {index < 3 ? (
            <View style={[styles.medalContainer, { backgroundColor: getMedalColor(index + 1) }]}>
              <Text style={styles.medalText}>{rank}</Text>
            </View>
          ) : (
            <Text style={styles.rankText}>{rank}</Text>
          )}
        </View>
        
        <Image 
          source={{ uri: item.user?.avatar || 'https://api.elbiblio.com/avatars/1.png' }} 
          style={styles.avatar} 
        />
        
        <View style={styles.userInfoContainer}>
          <Text 
            style={[styles.nameText, isCurrentUser && styles.currentUserText]} 
            numberOfLines={1}
          >
            {`${item.user?.first_name || ''} ${item.user?.last_name || ''}`.trim()}
            {isCurrentUser && ' (You)'}
          </Text>
          
          <View style={styles.statsContainer}>
            <Text style={styles.statsText}>
              {leaderboardType === 'global' ? 
                `${item.verses_read || 0} verses` :
                leaderboardType === 'theme' ?
                `${item.reflections_count || 0} reflections` :
                `${item.activities_count || 0} activities`
              }
            </Text>
          </View>
        </View>
        
        <View style={styles.pointsContainer}>
          <Award size={16} color={index < 3 ? getMedalColor(index + 1) : theme.colors.primary} />
          <Text style={[
            styles.pointsText,
            index < 3 && { fontWeight: '600' }
          ]}>
            {leaderboardType === 'timeframe' ? 
              (item.points_earned || 0).toLocaleString() :
              (item.points || 0).toLocaleString()
            }
          </Text>
        </View>
      </View>
    );
  };

  const ListHeader = () => (
    <View style={styles.headerContainer}>
      <View style={styles.filterSection}>
        <View style={styles.leaderboardTypeButtons}>
          <TouchableOpacity 
            style={[styles.typeButton, leaderboardType === 'global' && styles.selectedTypeButton]}
            onPress={() => handleLeaderboardTypeChange('global')}
          >
            <Users size={16} color={leaderboardType === 'global' ? theme.colors.text.inverse : theme.colors.text.secondary} />
            <Text style={[styles.typeButtonText, leaderboardType === 'global' && styles.selectedTypeButtonText]}>
              Global
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.typeButton, leaderboardType === 'timeframe' && styles.selectedTypeButton]}
            onPress={() => handleLeaderboardTypeChange('timeframe')}
          >
            <Fire size={16} color={leaderboardType === 'timeframe' ? theme.colors.text.inverse : theme.colors.text.secondary} />
            <Text style={[styles.typeButtonText, leaderboardType === 'timeframe' && styles.selectedTypeButtonText]}>
              Trending
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.typeButton, leaderboardType === 'theme' && styles.selectedTypeButton]}
            onPress={() => handleLeaderboardTypeChange('theme')}
          >
            <Calendar size={16} color={leaderboardType === 'theme' ? theme.colors.text.inverse : theme.colors.text.secondary} />
            <Text style={[styles.typeButtonText, leaderboardType === 'theme' && styles.selectedTypeButtonText]}>
              Theme
            </Text>
          </TouchableOpacity>
        </View>

        <TouchableOpacity 
          style={styles.filterButton}
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            setFilterMenuOpen(!filterMenuOpen);
          }}
        >
          <Filter size={18} color={theme.colors.text.secondary} />
          <Text style={styles.filterButtonText}>
            {timeFilter !== 'all' ? 
              `${timeFilter.charAt(0).toUpperCase() + timeFilter.slice(1)}` : 
              'All Time'}
          </Text>
        </TouchableOpacity>

        {filterMenuOpen && (
          <View style={styles.filterMenu}>
            <Text style={styles.filterMenuTitle}>Time Period</Text>
            <View style={styles.filterOptions}>
              <TouchableOpacity 
                style={[styles.filterOption, timeFilter === 'all' && styles.selectedFilter]}
                onPress={() => handleFilterPress('all', 'time')}
              >
                <Text style={styles.filterOptionText}>All Time</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.filterOption, timeFilter === 'day' && styles.selectedFilter]}
                onPress={() => handleFilterPress('day', 'time')}
              >
                <Text style={styles.filterOptionText}>Today</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.filterOption, timeFilter === 'week' && styles.selectedFilter]}
                onPress={() => handleFilterPress('week', 'time')}
              >
                <Text style={styles.filterOptionText}>This Week</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.filterOption, timeFilter === 'month' && styles.selectedFilter]}
                onPress={() => handleFilterPress('month', 'time')}
              >
                <Text style={styles.filterOptionText}>This Month</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
      </View>

      {userRank && (
        <View style={styles.userRankCard}>
          <Text style={styles.userRankTitle}>Your Ranking</Text>
          <View style={styles.userRankContent}>
            <Text style={styles.userRankText}>
              #{userRank.rank} of {userRank.total_users} users
            </Text>
            <Text style={styles.userRankSubtext}>
              {leaderboardType === 'global' ? 'Global leaderboard' :
               leaderboardType === 'timeframe' ? `${timeFilter} activity` :
               'Theme leaderboard'}
            </Text>
          </View>
        </View>
      )}
    </View>
  );

  const ListFooter = () => {
    if (isLoading && pagination.currentPage > 1) {
      return (
        <View style={styles.loadingFooter}>
          <ActivityIndicator color={theme.colors.primary} />
          <Text style={styles.loadingText}>Loading more...</Text>
        </View>
      );
    }
    return null;
  };

  const ListEmpty = () => {
    if (isLoading) {
      return (
        <View style={styles.emptyContainer}>
          <ActivityIndicator size="large" color={theme.colors.primary} />
          <Text style={styles.emptyText}>Loading leaderboard...</Text>
        </View>
      );
    }

    if (error) {
      return (
        <View style={styles.emptyContainer}>
          <Text style={styles.errorText}>Failed to load leaderboard</Text>
          <TouchableOpacity style={styles.retryButton} onPress={() => loadLeaderboard(1)}>
            <Text style={styles.retryButtonText}>Retry</Text>
          </TouchableOpacity>
        </View>
      );
    }

    return (
      <View style={styles.emptyContainer}>
        <Text style={styles.emptyText}>No leaderboard data available</Text>
      </View>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={handleGoBack}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Leaderboard</Text>
        <View style={styles.placeholder} />
      </View>

      <FlatList
        data={currentLeaderboard}
        renderItem={renderLeaderboardItem}
        keyExtractor={(item, index) => item.user?.id ?? item.rank?.toString() ?? `row-${index}`}
        ListHeaderComponent={ListHeader}
        ListFooterComponent={ListFooter}
        ListEmptyComponent={ListEmpty}
        onEndReached={handleLoadMore}
        onEndReachedThreshold={0.1}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            colors={[theme.colors.primary]}
            tintColor={theme.colors.primary}
          />
        }
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.listContent}
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
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.md,
    backgroundColor: theme.colors.surface,
    ...theme.shadows.sm,
  },
  backButton: {
    padding: theme.spacing.sm,
    marginLeft: -theme.spacing.sm,
  },
  headerTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
  },
  headerSpacer: {
    width: 40,
  },
  listContent: {
    paddingBottom: theme.spacing.xxl,
  },
  headerContainer: {
    backgroundColor: theme.colors.surface,
    paddingBottom: theme.spacing.md,
    ...theme.shadows.sm,
  },
  filterSection: {
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.md,
    zIndex: 10,
  },
  filterButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surfaceVariant,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    alignSelf: 'flex-start',
  },
  filterButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginLeft: theme.spacing.xs,
  },
  filterMenu: {
    position: 'absolute',
    top: 60,
    left: theme.spacing.lg,
    right: theme.spacing.lg,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    ...Platform.select({
      ios: {
        shadowColor: theme.colors.shadow,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.15,
        shadowRadius: 8,
      },
      android: {
        elevation: 5,
      },
    }),
    zIndex: 100,
  },
  filterMenuTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
    marginBottom: theme.spacing.sm,
  },
  filterOptions: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.sm,
    marginBottom: theme.spacing.md,
  },
  filterOption: {
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surfaceVariant,
  },
  selectedFilter: {
    backgroundColor: `${theme.colors.primary}30`,
    borderWidth: 1,
    borderColor: theme.colors.primary,
  },
  filterOptionText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  listHeaderRow: {
    flexDirection: 'row',
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.surfaceVariant,
  },
  headerRankText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    width: 80,
  },
  headerNameText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    flex: 1,
  },
  headerPointsText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    width: 80,
    textAlign: 'right',
  },
  leaderboardItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme.spacing.md,
    paddingHorizontal: theme.spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.surfaceVariant,
  },
  topThreeItem: {
    backgroundColor: `${theme.colors.primary}10`,
  },
  currentUserItem: {
    backgroundColor: `${theme.colors.primary}20`,
    borderLeftWidth: 3,
    borderLeftColor: theme.colors.primary,
  },
  rankContainer: {
    width: 50,
    alignItems: 'center',
  },
  rankText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    fontWeight: '500',
  },
  medalContainer: {
    width: 28,
    height: 28,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 2,
  },
  medalText: {
    ...theme.typography.body.sans,
    fontWeight: '700',
    color: theme.colors.text.inverse,
    fontSize: 14,
  },
  rankChangeContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 2,
  },
  rankChangeText: {
    ...theme.typography.caption.secondary,
    fontSize: 10,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    marginRight: theme.spacing.md,
  },
  userInfoContainer: {
    flex: 1,
    justifyContent: 'center',
  },
  nameText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    marginBottom: 4,
  },
  currentUserText: {
    fontWeight: '600',
  },
  virtueChip: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  virtueIndicator: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 4,
  },
  virtueText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  pointsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    width: 80,
    justifyContent: 'flex-end',
  },
  pointsText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    marginLeft: 4,
  },
  userRankSection: {
    marginTop: theme.spacing.lg,
  },
  userRankDivider: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.lg,
    marginBottom: theme.spacing.sm,
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: theme.colors.surfaceVariant,
  },
  dividerText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginHorizontal: theme.spacing.md,
  },
  leaderboardTypeButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: theme.spacing.md,
    paddingHorizontal: theme.spacing.sm,
  },
  typeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surfaceVariant,
  },
  selectedTypeButton: {
    backgroundColor: theme.colors.primary,
  },
  typeButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginLeft: theme.spacing.xs,
  },
  selectedTypeButtonText: {
    color: theme.colors.text.inverse,
  },
  userRankCard: {
    backgroundColor: theme.colors.surface,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    marginHorizontal: theme.spacing.lg,
    marginBottom: theme.spacing.md,
    ...theme.shadows.sm,
  },
  userRankTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
    marginBottom: theme.spacing.sm,
  },
  userRankContent: {
    alignItems: 'center',
  },
  userRankText: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    fontWeight: '700',
  },
  userRankSubtext: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.xs,
  },
  loadingFooter: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme.spacing.md,
  },
  loadingText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginLeft: theme.spacing.xs,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: theme.spacing.xxl,
  },
  emptyText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.md,
  },
  errorText: {
    ...theme.typography.body.sans,
    color: theme.colors.error,
    textAlign: 'center',
    marginBottom: theme.spacing.md,
  },
  retryButton: {
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.lg,
    backgroundColor: theme.colors.primary,
    borderRadius: theme.borderRadius.full,
  },
  retryButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
  placeholder: {
    width: 40,
  },
  statsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
  },
  statsText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
});

export default LeaderboardScreen; 