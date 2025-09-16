import React, { useMemo } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, StatusBar, ScrollView } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { useFocusEffect, useNavigation } from '@react-navigation/native';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { type RootStackParamList } from '@/types';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ArrowLeft, Bible, BookOpen, Fire, Globe, MessageSquare, NotePencil, Users } from '@/components/Icons';
import { observer } from 'mobx-react-lite';
import { useCommunityStore } from '@/stores/StoreProvider';

export type CommunityScreenProps = NativeStackScreenProps<RootStackParamList, 'CommunityScreen'>;

const CARDS = (colors: Theme['colors']) => ([
  {
    key: 'daily_verses',
    title: 'Daily Verses & Reflections',
    subtitle: 'See what the community is sharing today',
    icon: BookOpen,
    color: colors.primary,
    route: 'DailyVersesScreen' as const,
  },
  {
    key: 'community_challenges',
    title: 'Community Challenges',
    subtitle: 'Join today\'s challenge',
    icon: Fire,
    color: colors.primaryDark,
    route: 'DailyChallengeScreen' as const,
  },
  {
    key: 'wordhubs',
    title: 'WordHubs',
    subtitle: 'Find and join study hubs',
    icon: Users,
    color: colors.secondary,
    route: 'WordHubsScreen' as const,
  },
  {
    key: 'community_notes',
    title: 'Community Notes',
    subtitle: 'Read and share insights',
    icon: NotePencil,
    color: colors.like,
    route: 'NotesScreen' as const,
  },
  {
    key: 'prayer_requests',
    title: 'Prayer Requests',
    subtitle: 'Share and pray with others',
    icon: MessageSquare,
    color: colors.success,
    route: 'PrayerRequestsScreen' as const,
  },
]);

const CommunityScreen = ({ navigation }: CommunityScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const { markOpened } = useCommunityStore();

  const cards = useMemo(() => CARDS(theme.colors), [theme.colors]);

  // Reset unread count and set last opened when this screen gains focus
  useFocusEffect(
    React.useCallback(() => {
      markOpened();
      return () => {};
    }, [markOpened])
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
          {cards.map((card) => (
            <TouchableOpacity
              key={card.key}
              style={styles.card}
              activeOpacity={0.85}
              onPress={() => navigation.navigate(card.route as any)}
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
