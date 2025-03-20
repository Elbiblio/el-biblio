import React, { useState, useMemo, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  Image,
  TouchableOpacity,
  ActivityIndicator,
  Platform
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme, ThemeVariant } from '@/theme';
import { useAuth } from '@/stores/auth';
import * as Haptics from 'expo-haptics';
import { ArrowLeft, Award, ChevronUp, ChevronDown, Filter } from '../components/Icons';
import { AllVirtues } from '@/types';

type LeaderboardEntry = {
  id: string;
  name: string;
  avatar: string;
  points: number;
  rank: number;
  previousRank: number;
  topVirtue: AllVirtues;
};

type TimeFilter = 'all' | 'week' | 'month';
type VirtueFilter = 'all' | AllVirtues;

const LeaderboardScreen = ({ navigation }: any) => {
  const theme = useTheme();
  const { user } = useAuth();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const [loading, setLoading] = useState(true);
  const [timeFilter, setTimeFilter] = useState<TimeFilter>('all');
  const [virtueFilter, setVirtueFilter] = useState<VirtueFilter>('all');
  const [filterMenuOpen, setFilterMenuOpen] = useState(false);
  
  // Mock leaderboard data - replace with API call
  const [leaderboardData, setLeaderboardData] = useState<LeaderboardEntry[]>([]);
  const [userRank, setUserRank] = useState<LeaderboardEntry | null>(null);

  useEffect(() => {
    // Simulates API fetch
    const fetchLeaderboardData = async () => {
      setLoading(true);
      try {
        // Mock data - would be replaced with actual API call
        await new Promise(resolve => setTimeout(resolve, 800));
        
        const mockData: LeaderboardEntry[] = Array.from({ length: 100 }, (_, i) => ({
          id: `user-${i+1}`,
          name: i === 0 ? 'Sarah Johnson' : 
                i === 1 ? 'Marcus Chen' : 
                i === 2 ? 'Olivia Rodriguez' : 
                `User ${i+1}`,
          avatar: `https://api.elbiblio.com/avatars/${(i % 8) + 1}.png`,
          points: Math.floor(10000 - (i * 50) + (Math.random() * 20)),
          rank: i + 1,
          previousRank: i + 1 + (Math.floor(Math.random() * 5) - 2),
          topVirtue: (['love', 'wisdom', 'perseverance', 'patience', 'knowledge', 'humility'] as AllVirtues[])[i % 6]
        }));
        
        // Insert current user if not already in top 100
        const currentUserInList = mockData.find(entry => entry.id === user?.id);
        if (!currentUserInList && user) {
          const userPosition = Math.floor(Math.random() * 50) + 100; // Random position after top 100
          const userEntry: LeaderboardEntry = {
            id: user.id,
            name: `${user.first_name} ${user.last_name}`,
            avatar: user.avatar || 'https://api.elbiblio.com/avatars/1.png',
            points: 9000 - userPosition * 10,
            rank: userPosition,
            previousRank: userPosition + (Math.floor(Math.random() * 5) - 2),
            topVirtue: 'perseverance'
          };
          setUserRank(userEntry);
        } else if (currentUserInList) {
          setUserRank(currentUserInList);
        }
        
        setLeaderboardData(mockData);
      } catch (error) {
        console.error('Error fetching leaderboard data', error);
      } finally {
        setLoading(false);
      }
    };
    
    fetchLeaderboardData();
  }, [timeFilter, virtueFilter, user]);

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

  const handleFilterPress = (filter: TimeFilter | VirtueFilter, type: 'time' | 'virtue') => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    if (type === 'time') {
      setTimeFilter(filter as TimeFilter);
    } else {
      setVirtueFilter(filter as VirtueFilter);
    }
    setFilterMenuOpen(false);
  };

  const renderLeaderboardItem = ({ item, index }: { item: LeaderboardEntry, index: number }) => {
    const isCurrentUser = item.id === user?.id;
    const rankDiff = item.previousRank - item.rank;
    
    return (
      <View style={[
        styles.leaderboardItem, 
        isCurrentUser && styles.currentUserItem,
        index < 3 && styles.topThreeItem
      ]}>
        <View style={styles.rankContainer}>
          {index < 3 ? (
            <View style={[styles.medalContainer, { backgroundColor: getMedalColor(index + 1) }]}>
              <Text style={styles.medalText}>{index + 1}</Text>
            </View>
          ) : (
            <Text style={styles.rankText}>{item.rank}</Text>
          )}
          {rankDiff !== 0 && (
            <View style={styles.rankChangeContainer}>
              {rankDiff > 0 ? (
                <ChevronUp size={14} color={theme.colors.success} />
              ) : (
                <ChevronDown size={14} color={theme.colors.error} />
              )}
              <Text style={[
                styles.rankChangeText,
                { color: rankDiff > 0 ? theme.colors.success : theme.colors.error }
              ]}>
                {Math.abs(rankDiff)}
              </Text>
            </View>
          )}
        </View>
        
        <Image source={{ uri: item.avatar }} style={styles.avatar} />
        
        <View style={styles.userInfoContainer}>
          <Text 
            style={[styles.nameText, isCurrentUser && styles.currentUserText]} 
            numberOfLines={1}
          >
            {item.name}
            {isCurrentUser && ' (You)'}
          </Text>
          
          <View style={styles.virtueChip}>
            <View 
              style={[
                styles.virtueIndicator, 
                { backgroundColor: getVirtueColor(item.topVirtue) }
              ]} 
            />
            <Text style={styles.virtueText}>
              {item.topVirtue.charAt(0).toUpperCase() + item.topVirtue.slice(1)}
            </Text>
          </View>
        </View>
        
        <View style={styles.pointsContainer}>
          <Award size={16} color={index < 3 ? getMedalColor(index + 1) : theme.colors.primary} />
          <Text style={[
            styles.pointsText,
            index < 3 && { fontWeight: '600' }
          ]}>
            {item.points.toLocaleString()}
          </Text>
        </View>
      </View>
    );
  };

  const ListHeader = () => (
    <View style={styles.headerContainer}>
      <View style={styles.filterSection}>
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
            {virtueFilter !== 'all' && ` • ${virtueFilter.charAt(0).toUpperCase() + virtueFilter.slice(1)}`}
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

            <Text style={styles.filterMenuTitle}>Virtue Category</Text>
            <View style={styles.filterOptions}>
              <TouchableOpacity 
                style={[styles.filterOption, virtueFilter === 'all' && styles.selectedFilter]}
                onPress={() => handleFilterPress('all', 'virtue')}
              >
                <Text style={styles.filterOptionText}>All Virtues</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.filterOption, virtueFilter === 'love' && styles.selectedFilter]}
                onPress={() => handleFilterPress('love', 'virtue')}
              >
                <Text style={styles.filterOptionText}>Love</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.filterOption, virtueFilter === 'wisdom' && styles.selectedFilter]}
                onPress={() => handleFilterPress('wisdom', 'virtue')}
              >
                <Text style={styles.filterOptionText}>Wisdom</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.filterOption, virtueFilter === 'perseverance' && styles.selectedFilter]}
                onPress={() => handleFilterPress('perseverance', 'virtue')}
              >
                <Text style={styles.filterOptionText}>Perseverance</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
      </View>

      <View style={styles.listHeaderRow}>
        <Text style={styles.headerRankText}>Rank</Text>
        <Text style={styles.headerNameText}>User</Text>
        <Text style={styles.headerPointsText}>Points</Text>
      </View>
    </View>
  );

  const UserRankFooter = () => {
    if (!userRank || leaderboardData.find(entry => entry.id === user?.id)) return null;
    
    return (
      <View style={styles.userRankSection}>
        <View style={styles.userRankDivider}>
          <View style={styles.dividerLine} />
          <Text style={styles.dividerText}>Your Ranking</Text>
          <View style={styles.dividerLine} />
        </View>
        
        {renderLeaderboardItem({ item: userRank, index: -1 })}
      </View>
    );
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.loadingContainer} edges={['top']}>
        <View style={styles.header}>
          <TouchableOpacity style={styles.backButton} onPress={handleGoBack}>
            <ArrowLeft size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Leaderboard</Text>
          <View style={styles.headerSpacer} />
        </View>
        <ActivityIndicator size="large" color={theme.colors.primary} />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={handleGoBack}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Leaderboard</Text>
        <View style={styles.headerSpacer} />
      </View>
      
      <FlatList
        data={leaderboardData}
        renderItem={renderLeaderboardItem}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        ListHeaderComponent={ListHeader}
        ListFooterComponent={UserRankFooter}
        stickyHeaderIndices={[0]}
        initialNumToRender={10}
        maxToRenderPerBatch={10}
        windowSize={10}
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
});

export default LeaderboardScreen; 