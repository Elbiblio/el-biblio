import React, { useMemo } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { type RootStackParamList } from '@/types';
import { useTheme } from '@/contexts/ThemeContext';
import type { Theme } from '@/theme';
import { useVerseStore, useChallengeStore, useMeditationStore, useDailyPathStore, useAuthStore } from '@/stores/StoreProvider';
import { BookOpen, Fire, Clock, ArrowLeft } from '@/components/Icons';


type Props = NativeStackScreenProps<RootStackParamList, 'WhatYouMissedScreen'>;

const WhatYouMissedScreen = ({ navigation, route }: Props) => {
  const { daysAway } = route.params;
  const insets = useSafeAreaInsets();
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const isRenewMode = daysAway >= 7;

  const verseStore = useVerseStore();
  const { dailyVerses } = verseStore.state;

  const challengeStore = useChallengeStore();
  const { personalChallenges } = challengeStore;

  const meditationStore = useMeditationStore();
  const dailyPathStore = useDailyPathStore();
  const { user } = useAuthStore();

  const activeChallenges = useMemo(
    () => (personalChallenges || []).filter((c: any) => c && c.hasJoined && !c.isCompleted),
    [personalChallenges]
  );

  const handleDismiss = () => {
    navigation.goBack();
  };

  const handleOpenHome = () => {
    navigation.navigate('Home');
  };

  const handleOpenVerse = () => {
    const verse = dailyVerses && dailyVerses.length > 0 ? dailyVerses[0] : null;
    if (verse) {
      navigation.navigate('VerseDetail', { verse });
    } else {
      navigation.navigate('DailyVersesScreen');
    }
  };

  const handleOpenChallenge = () => {
    navigation.navigate('DailyChallengeScreen');
  };

  const handleOpenMeditation = () => {
    navigation.navigate('MeditationScreen');
  };

  const greetingTitle = isRenewMode ? 'Welcome back' : 'Good to see you';
  const gapLabel = daysAway === 1
    ? 'You stepped away yesterday.'
    : `It’s been ${daysAway} days since your last visit.`;

  const heroSubtitle = isRenewMode
    ? 'Let’s gently rebuild your daily rhythm with a simple plan.'
    : 'Let’s do a quick catch-up and get you back into your daily flow.';

  const hasActiveChallenge = activeChallenges.length > 0;

  return (
    <View style={[styles.container, { paddingTop: insets.top, paddingBottom: insets.bottom || 16 }]}> 
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={handleDismiss}>
          <ArrowLeft size={22} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>What you missed</Text>
        <View style={styles.headerSpacer} />
      </View>

      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.heroCard}>
          <Text style={styles.heroTitle}>{greetingTitle}{user ? `, ${user.first_name}` : ''}</Text>
          <Text style={styles.heroGap}>{gapLabel}</Text>
          <Text style={styles.heroSubtitle}>{heroSubtitle}</Text>
        </View>

        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>{isRenewMode ? 'Start with one simple step' : 'Quick catch-up'}</Text>
          <Text style={styles.sectionSubtitle}>
            Pick one or two actions below. You don’t have to do everything today.
          </Text>
        </View>

        <View style={styles.card}>
          <View style={styles.cardIconCircle}>
            <BookOpen size={20} color={theme.colors.primary} />
          </View>
          <View style={styles.cardBody}>
            <Text style={styles.cardTitle}>Today’s Verse</Text>
            <Text style={styles.cardText}>
              Read today’s verse and take a moment to pause with Scripture.
            </Text>
            <TouchableOpacity style={styles.cardButton} onPress={handleOpenVerse}>
              <Text style={styles.cardButtonText}>Read verse</Text>
            </TouchableOpacity>
          </View>
        </View>

        <View style={styles.card}>
          <View style={styles.cardIconCircle}>
            <Fire size={20} color={theme.colors.warning} />
          </View>
          <View style={styles.cardBody}>
            <Text style={styles.cardTitle}>{hasActiveChallenge ? 'Your Daily Challenge' : 'Start a Daily Challenge'}</Text>
            <Text style={styles.cardText}>
              {hasActiveChallenge
                ? 'Pick up your current challenge and log today’s progress.'
                : 'Choose a simple challenge to guide your focus this week.'}
            </Text>
            <TouchableOpacity style={styles.cardButton} onPress={handleOpenChallenge}>
              <Text style={styles.cardButtonText}>{hasActiveChallenge ? 'Go to my challenge' : 'Browse challenges'}</Text>
            </TouchableOpacity>
          </View>
        </View>

        <View style={styles.card}>
          <View style={styles.cardIconCircle}>
            <Clock size={20} color={theme.colors.secondary} />
          </View>
          <View style={styles.cardBody}>
            <Text style={styles.cardTitle}>{isRenewMode ? 'Reset with a short meditation' : 'Take 5 minutes to reset'}</Text>
            <Text style={styles.cardText}>
              Step into a short guided meditation to re-center your heart.
            </Text>
            <TouchableOpacity style={styles.cardButton} onPress={handleOpenMeditation}>
              <Text style={styles.cardButtonText}>Start meditation</Text>
            </TouchableOpacity>
          </View>
        </View>

        {dailyPathStore.isSetupComplete && (
          <View style={styles.footerNote}>
            <Text style={styles.footerNoteText}>
              Your daily path is still here. You can adjust it anytime from your journey.
            </Text>
            <TouchableOpacity onPress={handleOpenHome}>
              <Text style={styles.footerLink}>Go to Home</Text>
            </TouchableOpacity>
          </View>
        )}

        {!dailyPathStore.isSetupComplete && (
          <View style={styles.footerNote}>
            <Text style={styles.footerNoteText}>
              When you’re ready, we can help you create a simple daily rhythm.
            </Text>
            <TouchableOpacity onPress={() => navigation.navigate('DailyPathSetupScreen')}>
              <Text style={styles.footerLink}>Set up my daily path</Text>
            </TouchableOpacity>
          </View>
        )}

        <TouchableOpacity style={styles.skipButton} onPress={handleDismiss}>
          <Text style={styles.skipButtonText}>Skip for now</Text>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
};

export default WhatYouMissedScreen;

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.lg,
    paddingBottom: theme.spacing.sm,
  },
  backButton: {
    padding: theme.spacing.sm,
    marginRight: theme.spacing.sm,
  },
  headerTitle: {
    flex: 1,
    textAlign: 'center',
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  headerSpacer: {
    width: 40,
  },
  scrollContent: {
    paddingHorizontal: theme.spacing.lg,
    paddingBottom: theme.spacing.xl,
  },
  heroCard: {
    borderRadius: theme.borderRadius.xl,
    backgroundColor: theme.colors.surface,
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.lg,
    marginBottom: theme.spacing.lg,
  },
  heroTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  heroGap: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.xs,
  },
  heroSubtitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
  },
  sectionHeader: {
    marginBottom: theme.spacing.md,
  },
  sectionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  sectionSubtitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  card: {
    flexDirection: 'row',
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.md,
  },
  cardIconCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: `${theme.colors.primary}10`,
    marginRight: theme.spacing.md,
  },
  cardBody: {
    flex: 1,
  },
  cardTitle: {
    ...theme.typography.body.sans,
    fontWeight: '600',
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  cardText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.sm,
  },
  cardButton: {
    alignSelf: 'flex-start',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.primary,
  },
  cardButtonText: {
    ...theme.typography.button,
    color: theme.colors.text.inverse,
  },
  footerNote: {
    marginTop: theme.spacing.lg,
    marginBottom: theme.spacing.md,
  },
  footerNoteText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.xs,
  },
  footerLink: {
    ...theme.typography.button,
    color: theme.colors.primary,
  },
  skipButton: {
    alignSelf: 'center',
    marginTop: theme.spacing.lg,
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
  },
  skipButtonText: {
    ...theme.typography.button,
    color: theme.colors.text.secondary,
  },
});
