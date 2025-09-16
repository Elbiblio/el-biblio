import React, { useState, useCallback, useRef } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Platform,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import {
  ArrowLeft,
  Star,
  Sparkle,
  Info,
  Upvote,
  Check,
} from '@/components/Icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import * as Haptics from 'expo-haptics';
import VerseTooltip from '@/components/VerseTooltip';
import { RootStackParamList, Verse, THEMES, FoundationalVirtue } from '@/types';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useThemeOfDay } from '@/utils/schedule';
import { getTomorrowsTheme } from '@/utils/schedule';
import ThemeInfo from '@/modals/ThemeInfo';
import { useVerseStore, useAuthStore } from '@/stores/StoreProvider';
import { toast } from 'sonner-native';
import { observer } from 'mobx-react-lite';


const DailyVersesScreen = ({ navigation }: NativeStackScreenProps<RootStackParamList, 'DailyVersesScreen'>) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const [showThemeInfo, setShowThemeInfo] = useState(false);

  const { user } = useAuthStore();
  const verseStore = useVerseStore();
  const {
    dailyVerses,
    isDailyVersesLoading,
    dailyVersesError,
    isConnected,
    lastUpdate,
  } = verseStore.state;
  const {
    fetchDailyVerses,
    createInteraction,
    updateVerseVotes,
    setConnectionStatus,
  } = verseStore;

  const todayTheme = useThemeOfDay();
  const tomorrowTheme = getTomorrowsTheme();

  const sortedVerses = React.useMemo(() => {
    if (!dailyVerses?.length) return { current: [], upcoming: [] };

    const now = new Date();
    return dailyVerses.reduce<{ current: Verse[], upcoming: Verse[] }>((acc, verse) => {
      const verseDate = new Date(verse.created_at);
      if (verseDate.getDate() === now.getDate()) {
        acc.current.push(verse);
      } else if (verseDate.getDate() === now.getDate() + 1) {
        acc.upcoming.push(verse);
      }
      return acc;
    }, { current: [], upcoming: [] });
  }, [dailyVerses]);

  // Load verses on mount
  React.useEffect(() => {
    fetchDailyVerses();
  }, [fetchDailyVerses]);

  // Simulate real-time updates (in a real app, this would be WebSocket)
  React.useEffect(() => {
    const interval = setInterval(() => {
      // Simulate connection status updates
      setConnectionStatus(Math.random() > 0.1); // 90% uptime simulation
    }, 30000); // Check every 30 seconds

    return () => clearInterval(interval);
  }, [setConnectionStatus]);

  // Handle voting
  const handleVote = async (verse: Verse) => {
    if (!user) {
      toast.info('Please log in to vote');
      return;
    }

    try {
      // Optimistic update for better UX
      const newVotes = verse.votes + 1;
      const isVoted = true;
      updateVerseVotes(verse.id, newVotes, isVoted);

      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      toast.success('Vote recorded!');

      // Send to API
      await createInteraction({
        interactable_id: verse.id,
        interactable_type: 'App\\Models\\Verse',
        type: 3, // Vote type
        user_id: user.id
      });

    } catch (error) {
      // Revert optimistic update on error
      updateVerseVotes(verse.id, verse.votes, false);
      toast.error('Failed to record vote');
    }
  };

  const [selectedTab, setSelectedTab] = useState<'current' | 'upcoming'>('current');
  const [selectedVerse, setSelectedVerse] = useState<Verse | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const verseRef = useRef<View>(null);

  const selectedTheme = selectedTab === 'current' ? todayTheme : tomorrowTheme;

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    try {
      await fetchDailyVerses();
    } finally {
      setRefreshing(false);
    }
  }, [fetchDailyVerses]);

  const formattedTheme = {
    ...selectedTheme,
    practices: selectedTheme.practices || [],
    subtitle: selectedTheme.subtitle || '', // Add default values if needed
    description: selectedTheme.description || '',
  };

  const renderVerseCard = useCallback((verse: Verse) => {
    const themeInfo = THEMES[verse.theme?.name as FoundationalVirtue];

    return (
      <View
        key={verse.id}
        style={[
          styles.verseCard,
          { borderColor: `${themeInfo.color}20` }
        ]}
      >
        <BlurView intensity={10} style={StyleSheet.absoluteFill} />
        <TouchableOpacity
          onPress={() => setSelectedVerse(verse)}
          style={styles.verseContent}
        >
          <View ref={verseRef}>
            {/* Moderator Badge if applicable */}
            {verse.is_featured && (
              <View style={[
                styles.moderatorBadge,
                { backgroundColor: `${themeInfo.color}15` }
              ]}>
                <Sparkle size={12} color={themeInfo.color} />
                <Text style={[
                  styles.moderatorText,
                  { color: themeInfo.color }
                ]}>
                  Featured
                </Text>
              </View>
            )}

            {/* Verse Content */}
            <View style={styles.verseHeader}>
              <Text style={[
                styles.verseReference,
                { color: themeInfo.color }
              ]}>
                {verse.reference}
              </Text>
              <Text style={styles.translation}>{verse.translation}</Text>
            </View>

            <Text style={styles.verseText}>
              {verse.text}
            </Text>

            {/* Footer */}
            <View style={styles.verseFooter}>
              <View style={styles.voteCount}>
                <Star size={16} color={themeInfo.color} />
                <Text style={styles.voteText}>{verse.votes} votes</Text>
              </View>

              {selectedTab === 'upcoming' && (
                <TouchableOpacity
                  style={[
                    styles.voteButton,
                    verse.isVoted && styles.votedButton,
                    {
                      backgroundColor: verse.isVoted ?
                        themeInfo.color :
                        `${themeInfo.color}15`
                    }
                  ]}
                  onPress={() => {
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                    handleVote(verse)
                  }}
                  disabled={verse.isVoted}
                >
                  {
                    verse.isVoted ?
                      <Check size={16}
                        color={theme.colors.text.inverse}
                        filled
                      /> :
                      <Upvote
                        size={16}
                        color={verse.isVoted ? theme.colors.text.inverse : themeInfo.color}
                        filled={verse.isVoted}
                      />
                  }
                  <Text style={[
                    styles.voteButtonText,
                    { color: verse.isVoted ? theme.colors.text.inverse : themeInfo.color }
                  ]}>
                    {verse.isVoted ? 'Voted' : 'Vote'}
                  </Text>
                </TouchableOpacity>
              )}
            </View>
          </View>
        </TouchableOpacity>
      </View>
    );
  }, [theme, setSelectedVerse, handleVote, user]);

  return (
    <>
      <View style={[styles.container, { paddingTop: insets.top }]}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
            <ArrowLeft size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>
          <Text style={styles.title}>Daily Verses</Text>
          <TouchableOpacity onPress={() => { navigation.navigate("IntroScreen") }}>
            <Info size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>
        </View>

        {/* Connection Status */}
        <View style={styles.statusContainer}>
          <View style={[styles.connectionIndicator, { backgroundColor: isConnected ? theme.colors.success : theme.colors.error }]} />
          <Text style={styles.statusText}>
            {isConnected ? 'Live' : 'Offline'} • 
            {lastUpdate ? ` Updated ${lastUpdate.toLocaleTimeString()}` : ' Never updated'}
          </Text>
        </View>

        {/* Tab Selector */}
        <View style={styles.tabContainer}>
          <TouchableOpacity
            style={[styles.tab, selectedTab === 'current' && styles.activeTab]}
            onPress={() => setSelectedTab('current')}
          >
            <Text style={[
              styles.tabText,
              selectedTab === 'current' && styles.activeTabText
            ]}>
              Today's Verses
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.tab, selectedTab === 'upcoming' && styles.activeTab]}
            onPress={() => setSelectedTab('upcoming')}
          >
            <Text style={[
              styles.tabText,
              selectedTab === 'upcoming' && styles.activeTabText
            ]}>
              Tomorrow's Selection
            </Text>
          </TouchableOpacity>
        </View>

        {/* Main Content */}
        <ScrollView
          style={styles.scrollContent}
          contentContainerStyle={styles.scrollContainer}
          showsVerticalScrollIndicator={false}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              colors={[theme.colors.primary]}
              tintColor={theme.colors.primary}
            />
          }
        >
          {isDailyVersesLoading ? (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color={theme.colors.primary} />
            </View>
          ) : dailyVersesError ? (
            <View style={styles.errorContainer}>
              <Text style={styles.errorText}>{dailyVersesError}</Text>
              <TouchableOpacity
                style={styles.retryButton}
                onPress={fetchDailyVerses}
              >
                <Text style={styles.retryText}>Retry</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <>
              <Text style={[
                styles.dateText,
                { alignSelf: selectedTab === 'current' ? 'flex-start' : 'flex-end' }
              ]}>
                {new Date().toLocaleDateString('en-US', {
                  weekday: 'short',
                  month: 'short',
                  day: 'numeric'
                })}
              </Text>

              <TouchableOpacity
                style={[
                  styles.themeBadge,
                  {
                    backgroundColor: `${selectedTheme.color}15`,
                    alignSelf: selectedTab === 'current' ? 'flex-start' : 'flex-end'
                  }
                ]}
                onPress={() => setShowThemeInfo(true)}
              >
                <selectedTheme.Icon size={16} color={selectedTheme.color} />
                <Text style={[styles.themeText, { color: selectedTheme.color }]}>
                  Theme: {selectedTheme.title}
                </Text>
              </TouchableOpacity>

              {/* Featured Verses */}
              <View style={styles.sectionContainer}>
                {(selectedTab === 'current' ? sortedVerses.current : sortedVerses.upcoming)
                  .map(verse => renderVerseCard(verse))}
              </View>

              {/* Empty State */}
              {(selectedTab === 'current' ? sortedVerses.current : sortedVerses.upcoming).length === 0 && (
                <View style={styles.emptyStateContainer}>
                  <Text style={styles.emptyStateText}>
                    {selectedTab === 'current'
                      ? "Today's verses will be available soon!"
                      : "Tomorrow's verses will be available later today!"}
                  </Text>
                </View>
              )}
            </>
          )}
        </ScrollView>

        {/* Verse Tooltip */}
        {selectedVerse && (
          <VerseTooltip
            verseRef={selectedVerse.reference}
            targetRef={verseRef}
            onClose={() => setSelectedVerse(null)}
          />
        )}
      </View>
      {/* Theme Info Modal */}
      <ThemeInfo
        theme={formattedTheme}
        visible={showThemeInfo}
        onClose={() => setShowThemeInfo(false)}
      />
    </>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  title: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  tabContainer: {
    flexDirection: 'row',
    padding: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  tab: {
    flex: 1,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
  },
  activeTab: {
    backgroundColor: theme.colors.primary,
  },
  tabText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  activeTabText: {
    color: theme.colors.text.inverse,
  },
  scrollContent: {
    flex: 1,
  },
  scrollContainer: {
    padding: theme.spacing.md,
  },
  dateText: {
    ...theme.typography.heading.small,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.xs,
  },
  sectionContainer: {
    marginBottom: theme.spacing.lg,
  },
  sectionTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  verseCard: {
    marginBottom: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    overflow: 'hidden',
    backgroundColor: theme.colors.background,
    ...Platform.select({
      ios: {
        shadowColor: theme.colors.primary,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.1,
        shadowRadius: 8,
      },
      android: {
        elevation: 4,
      },
    }),
  },
  verseContent: {
    padding: theme.spacing.md,
  },
  themeBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 6,
    borderRadius: theme.borderRadius.full,
    marginVertical: theme.spacing.md,
  },
  themeText: {
    ...theme.typography.caption.primary,
    fontSize: 12,
    marginLeft: 4,
  },
  moderatorBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    marginBottom: theme.spacing.xs,
  },
  moderatorText: {
    ...theme.typography.caption.primary,
    fontSize: 12,
    marginLeft: 4,
  },
  verseHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.sm,
  },
  verseReference: {
    ...theme.typography.verse.emphasis,
    fontSize: 16,
  },
  translation: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  verseText: {
    ...theme.typography.verse.regular,
    color: theme.colors.text.primary,
    fontSize: 16,
    lineHeight: 24,
    marginBottom: theme.spacing.md,
  },
  verseFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  voteCount: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  voteText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  voteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
  },
  votedButton: {
    opacity: 0.9,
  },
  voteButtonText: {
    ...theme.typography.caption.primary,
    fontSize: 12,
    fontWeight: '600',
  },
  toggleThemeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
  },
  toggleThemeText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    marginRight: theme.spacing.xs,
  },
  emptyStateContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme.spacing.xl,
  },
  emptyStateText: {
    ...theme.typography.body.serif,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginTop: theme.spacing.md,
  },
  cardBorder: {
    borderTopWidth: 3,
    borderTopColor: 'transparent',
  },
  separatorText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginVertical: theme.spacing.md,
  },
  themeSummary: {
    marginTop: theme.spacing.md,
    padding: theme.spacing.md,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
  },
  themeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.sm,
    marginTop: theme.spacing.sm,
  },
  themeChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 6,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    gap: 4,
  },
  infoIconContainer: {
    marginLeft: 'auto',
  },
  modalContainer: {
    backgroundColor: theme.colors.background,
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,
    maxWidth: '90%',
    width: 350,
  },
  modalTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  modalContent: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.lg,
  },
  closeButton: {
    alignSelf: 'flex-end',
    padding: theme.spacing.sm,
    marginTop: -theme.spacing.sm,
    marginRight: -theme.spacing.sm,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme.spacing.xl,
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme.spacing.xl,
  },
  errorText: {
    ...theme.typography.body.sans,
    color: theme.colors.error,
    textAlign: 'center',
    marginBottom: theme.spacing.md,
  },
  retryButton: {
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.lg,
    borderRadius: theme.borderRadius.full,
  },
  retryText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
  
  // Connection status
  statusContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.xs,
    backgroundColor: theme.colors.surface,
  },
  connectionIndicator: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: theme.spacing.xs,
  },
  statusText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontSize: 12,
  },
});

export default observer(DailyVersesScreen);