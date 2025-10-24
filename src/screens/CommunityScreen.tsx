import React, { useCallback, useEffect, useMemo, useState } from 'react';
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
import { useCommunityStore, useDailyPathStore } from '@/stores/StoreProvider';
import AsyncStorage from '@react-native-async-storage/async-storage';

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
  | 'PrayerRequestsScreen';

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
      const parsed = stored ? (JSON.parse(stored) as QuickMenuUsage) : null;
      setUsageStage(getUsageStage(parsed));
    } catch {
      setUsageStage(0);
    }
  }, []);

  useEffect(() => {
    loadUsageStage();
  }, [loadUsageStage]);

  const cards = useMemo(() => COMMUNITY_CARDS(theme.colors), [theme.colors]);
  const availableCards = useMemo(() => {
    return cards.filter(card => {
      if (card.key === 'prayer_requests' && dailyPathStore?.state?.communityUnlocked) return true;
      return card.stage <= usageStage;
    });
  }, [cards, usageStage, dailyPathStore?.state?.communityUnlocked]);

  const handleNavigate = useCallback((route: CommunityRoute) => {
    navigation.navigate(route);
  }, [navigation]);

  // Reset unread count and set last opened when this screen gains focus
  useFocusEffect(
    React.useCallback(() => {
      markOpened();
      loadUsageStage();
      return () => {};
    }, [markOpened, loadUsageStage])
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
});

export default observer(CommunityScreen);
