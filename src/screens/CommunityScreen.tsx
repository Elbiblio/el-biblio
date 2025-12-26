import React, { useCallback, useMemo } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, StatusBar, ScrollView } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { useFocusEffect } from '@react-navigation/native';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { type RootStackParamList } from '@/types';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ArrowLeft, BookOpen, Fire, MessageSquare, NotePencil, Users } from '@/components/Icons';
import { observer } from 'mobx-react-lite';
import { useAuthStore, useCommunityStore, useDailyPathStore, useLeaderboardStore } from '@/stores/StoreProvider';
import { toast } from 'sonner-native';
import { COMMUNITY_STAGE_POINTS, deriveCommunityStage } from '@/constants/communityUnlocks';

export type CommunityScreenProps = NativeStackScreenProps<RootStackParamList, 'CommunityScreen'>;

type CommunityRoute =
  | 'DailyChallengeScreen'
  | 'DailyVersesScreen'
  | 'NotesScreen'
  | 'WordHubsScreen'
  | 'PrayerRequestsScreen'
  | 'FeatureSuggestionsScreen';

type CommunityCard = {
  key: string;
  title: string;
  subtitle: string;
  icon: React.FC<{ size?: number; color?: string }>;
  color: string;
  route: CommunityRoute;
  stage: number;
};

const COMMUNITY_CARDS = (colors: Theme['colors']): CommunityCard[] => ([
  {
    key: 'community_challenges',
    title: 'Community Challenges',
    subtitle: 'Join today\'s challenge',
    icon: Fire,
    color: colors.primaryDark,
    route: 'DailyChallengeScreen',
    stage: 0,
  },
  {
    key: 'daily_verses',
    title: 'Daily Verses & Reflections',
    subtitle: 'See what the community is sharing today',
    icon: BookOpen,
    color: colors.primary,
    route: 'DailyVersesScreen',
    stage: 1,
  },
  {
    key: 'community_notes',
    title: 'Community Notes',
    subtitle: 'Read and share insights',
    icon: NotePencil,
    color: colors.like,
    route: 'NotesScreen',
    stage: 1,
  },
  {
    key: 'wordhubs',
    title: 'WordHubs',
    subtitle: 'Create or join study hubs',
    icon: Users,
    color: colors.secondary,
    route: 'WordHubsScreen',
    stage: 2,
  },
  {
    key: 'prayer_requests',
    title: 'Prayer Requests',
    subtitle: 'Share and pray with the community',
    icon: MessageSquare,
    color: colors.success,
    route: 'PrayerRequestsScreen',
    stage: 2,
  },
  // {
  //   key: 'feature_suggestions',
  //   title: 'Feature suggestions',
  //   subtitle: 'Propose and vote on ideas',
  //   icon: Users,
  //   color: colors.primary,
  //   route: 'FeatureSuggestionsScreen',
  //   stage: 2,
  // },
]);

const CommunityScreen = ({ navigation }: CommunityScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const { markOpened } = useCommunityStore();
  const dailyPathStore = useDailyPathStore();
  const { user, isGuest, requestAuthPrompt } = useAuthStore();
  const leaderboardStore = useLeaderboardStore();

  const cards = useMemo(() => COMMUNITY_CARDS(theme.colors), [theme.colors]);

  // Define available routes for validation - ensure all routes actually exist
  const AVAILABLE_ROUTES: ReadonlySet<CommunityRoute> = useMemo(() => new Set([
    'DailyChallengeScreen',
    'DailyVersesScreen', 
    'NotesScreen',
    'WordHubsScreen',
    'PrayerRequestsScreen',
  ]), []);

  const totalPoints = leaderboardStore.userStats?.totalPoints ?? user?.points ?? 0;
  const derivedStage = useMemo(
    () =>
      deriveCommunityStage({
        communityUnlocked: dailyPathStore?.state?.communityUnlocked,
        totalPoints,
      }),
    [dailyPathStore?.state?.communityUnlocked, totalPoints]
  );

  const availableCards = useMemo(() => {
    if (dailyPathStore?.state?.communityUnlocked) {
      return cards;
    }
    return cards.filter((card) => card.stage <= derivedStage);
  }, [cards, derivedStage, dailyPathStore?.state?.communityUnlocked]);

  const handleNavigate = useCallback((route: CommunityRoute) => {
    if (!AVAILABLE_ROUTES.has(route)) {
      console.warn(`Navigation route "${route}" is not implemented`);
      toast.error('This feature is not available yet');
      return;
    }

    if (!user || isGuest || !user.email) {
      const intent = isGuest ? 'guest_signup' : null;
      requestAuthPrompt(intent, user?.email ?? null);
      toast.info('Create a free account to access Community features.');
      return;
    }

    try {
      navigation.navigate(route);
    } catch (error) {
      console.error('Navigation error:', error);
      toast.error('Unable to navigate to this feature');
    }
  }, [AVAILABLE_ROUTES, navigation, user, isGuest, requestAuthPrompt]);

  // Reset unread count and set last opened when this screen gains focus
  useFocusEffect(
    React.useCallback(() => {
      // Sequential operations to prevent race conditions
      const initializeScreen = async () => {
        try {
          markOpened();
          const unlocked = dailyPathStore?.state?.communityUnlocked;
          if (!unlocked && derivedStage === 0) {
            toast.info('Community features unlock as you engage with Scripture and reflection. Keep going!');
          }
        } catch (error) {
          console.error('Error initializing CommunityScreen:', error);
        }
      };
      
      initializeScreen();
      return () => {};
    }, [markOpened, dailyPathStore?.state?.communityUnlocked, derivedStage])
  );

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}> 
      <StatusBar barStyle="dark-content" />
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>Community</Text>
        <View style={{ width: 24 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <Text style={styles.sectionTitle}>Explore</Text>
        <View style={styles.grid}>
          {availableCards.map((card) => (
            <TouchableOpacity
              key={card.key}
              style={styles.card}
              activeOpacity={0.85}
              onPress={() => handleNavigate(card.route)}
            >
              <LinearGradient
                colors={[`${card.color}15`, `${card.color}05`]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.cardGradient}
              />
              <View style={[styles.iconContainer, { backgroundColor: `${card.color}15` }]}> 
                <card.icon size={22} color={card.color} />
              </View>
              <View style={styles.cardText}>
                <Text style={styles.cardTitle}>{card.title}</Text>
                <Text style={styles.cardSubtitle}>{card.subtitle}</Text>
              </View>
            </TouchableOpacity>
          ))}
        </View>
        {derivedStage === 0 && (
          <Text style={styles.tipText}>
            Grow your journey to unlock more community spaces.
          </Text>
        )}
      </ScrollView>

    </View>
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
  content: {
    padding: theme.spacing.md,
  },
  sectionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  grid: {
    gap: theme.spacing.md,
  },
  tipText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.md,
  },
  card: {
    position: 'relative',
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    padding: theme.spacing.md,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}10`,
    overflow: 'hidden',
  },
  cardGradient: {
    ...StyleSheet.absoluteFillObject,
  },
  iconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme.spacing.sm,
  },
  cardText: {
    gap: 4,
  },
  cardTitle: {
    ...theme.typography.body.serif,
    color: theme.colors.text.primary,
    fontWeight: '700',
  },
  cardSubtitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  welcomeBackdrop: {
    flex: 1,
    backgroundColor: `${theme.colors.background}F2`,
    justifyContent: 'center',
    padding: theme.spacing.lg,
  },
  welcomeCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.xl,
    paddingVertical: theme.spacing.lg,
    paddingHorizontal: theme.spacing.lg,
    maxHeight: '80%',
    borderWidth: 1,
    borderColor: `${theme.colors.primary}20`,
    shadowColor: theme.colors.primary,
    shadowOpacity: 0.2,
    shadowRadius: 16,
    elevation: 8,
  },
  welcomeContent: {
    gap: theme.spacing.md,
  },
  welcomeTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    textAlign: 'center',
  },
  welcomeBody: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
  },
  welcomeButton: {
    marginTop: theme.spacing.lg,
    backgroundColor: theme.colors.primary,
    borderRadius: theme.borderRadius.lg,
    paddingVertical: theme.spacing.md,
    alignItems: 'center',
  },
  welcomeButtonText: {
    ...theme.typography.button.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
});

export default observer(CommunityScreen);
