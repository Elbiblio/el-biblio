import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, StatusBar, ScrollView, Modal } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { useFocusEffect } from '@react-navigation/native';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { type RootStackParamList } from '@/types';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ArrowLeft, BookOpen, Fire, MessageSquare, NotePencil, Users } from '@/components/Icons';
import { observer } from 'mobx-react-lite';
import { useCommunityStore, useDailyPathStore } from '@/stores/StoreProvider';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { toast } from 'sonner-native';

export type CommunityScreenProps = NativeStackScreenProps<RootStackParamList, 'CommunityScreen'>;

type QuickMenuUsage = {
  meditationCount: number;
  bibleCount: number;
  unlockedItems: string[];
};

const getUsageStage = (usage: QuickMenuUsage | null) => {
  if (!usage) return 0;
  if (usage.unlockedItems?.includes('coreTools')) return 2;
  if ((usage.meditationCount ?? 0) > 0 && (usage.bibleCount ?? 0) > 0) return 1;
  return 0;
};

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
  const [usageStage, setUsageStage] = useState(0);

  const loadUsageStage = useCallback(async () => {
    try {
      const stored = await AsyncStorage.getItem('home_quick_menu_usage');
      
      if (!stored) {
        setUsageStage(0);
        return;
      }
      
      // Validate JSON structure before parsing
      let parsed;
      try {
        parsed = JSON.parse(stored);
      } catch (parseError) {
        console.warn('Invalid JSON in usage stage data, resetting to default:', parseError);
        await AsyncStorage.removeItem('home_quick_menu_usage');
        setUsageStage(0);
        return;
      }
      
      // Validate parsed data structure
      if (!parsed || typeof parsed !== 'object') {
        console.warn('Invalid usage stage data structure, resetting to default');
        await AsyncStorage.removeItem('home_quick_menu_usage');
        setUsageStage(0);
        return;
      }
      
      const usage = parsed as QuickMenuUsage;
      setUsageStage(getUsageStage(usage));
    } catch (error) {
      console.error('Failed to load usage stage:', error);
      setUsageStage(0);
      // Clear corrupted data
      try {
        await AsyncStorage.removeItem('home_quick_menu_usage');
      } catch (clearError) {
        console.error('Failed to clear corrupted usage stage data:', clearError);
      }
    }
  }, []);

  const cards = useMemo(() => COMMUNITY_CARDS(theme.colors), [theme.colors]);
  const availableCards = useMemo(() => {
    return cards.filter(card => {
      // Standardize unlock logic: prayer requests unlock at stage 2 like other features
      // or if community is specifically unlocked
      if (card.key === 'prayer_requests') {
        return card.stage <= usageStage || dailyPathStore?.state?.communityUnlocked;
      }
      return card.stage <= usageStage;
    });
  }, [cards, usageStage, dailyPathStore?.state?.communityUnlocked]);

  // Define available routes for validation - ensure all routes actually exist
  const AVAILABLE_ROUTES: CommunityRoute[] = [
    'DailyChallengeScreen',
    'DailyVersesScreen', 
    'NotesScreen',
    'WordHubsScreen',
    'PrayerRequestsScreen',
  ];

  const handleNavigate = useCallback((route: CommunityRoute) => {
    try {
      // Validate route against available routes
      if (!AVAILABLE_ROUTES.includes(route)) {
        console.warn(`Navigation route "${route}" is not implemented`);
        toast.error('This feature is not available yet');
        return;
      }
      
      // Additional validation: ensure route exists in navigation
      const navigationState = navigation.getState();
      const routeExists = navigationState?.routes.some((r: any) => r.name === route) || 
                         navigationState?.history?.some((h: any) => h.key === route);
      
      if (!routeExists) {
        console.warn(`Navigation route "${route}" not found in navigation state`);
        toast.error('Unable to navigate to this feature');
        return;
      }
      
      navigation.navigate(route);
    } catch (error) {
      console.error('Navigation error:', error);
      toast.error('Unable to navigate to this feature');
    }
  }, [navigation]);

  // Reset unread count and set last opened when this screen gains focus
  useFocusEffect(
    React.useCallback(() => {
      // Sequential operations to prevent race conditions
      const initializeScreen = async () => {
        try {
          await markOpened();
          await loadUsageStage();
          
          const unlocked = dailyPathStore?.state?.communityUnlocked;
          if (!unlocked) {
            const stage = getUsageStage(null);
            toast.info('Community features unlock as you engage with Bible reading and meditation. Keep going!');
          }
        } catch (error) {
          console.error('Error initializing CommunityScreen:', error);
        }
      };
      
      initializeScreen();
      return () => {};
    }, [markOpened, loadUsageStage, dailyPathStore?.state?.communityUnlocked])
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
        {usageStage === 0 && (
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
