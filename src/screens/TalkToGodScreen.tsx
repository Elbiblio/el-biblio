import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import type { Theme } from '@/theme';
import type { RootStackParamList } from '@/types';
import { ArrowLeft, MessageSquare } from '@/components/Icons';
import { getGuides, GuideSummary } from '@/services/GuideService';

export type TalkToGodScreenProps = NativeStackScreenProps<RootStackParamList, 'TalkToGodScreen'>;

const TalkToGodScreen = ({ navigation }: TalkToGodScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const [guides, setGuides] = React.useState<GuideSummary[]>([]);

  React.useEffect(() => {
    let isActive = true;

    const loadGuides = async () => {
      try {
        const list = await getGuides();
        if (isActive) {
          setGuides(list);
        }
      } catch {
        // Fail silently for now; local fallback is baked into GuideService
      }
    };

    void loadGuides();

    return () => {
      isActive = false;
    };
  }, []);

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}> 
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>Guides</Text>
        <View style={{ width: 24 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <Text style={styles.introTitle}>Choose a guide</Text>
        <Text style={styles.introBody}>
          These guides help you learn how to pray, walk through forgiveness, and welcome
          the Holy Spirit into your day.
        </Text>

        {guides.map(guide => (
          <View key={guide.id} style={styles.card}>
            <Text style={styles.cardTitle}>{guide.title}</Text>
            <Text style={styles.cardBody}>{guide.subtitle}</Text>
            <TouchableOpacity
              style={styles.primaryButton}
              activeOpacity={0.9}
              onPress={() => navigation.navigate('GuidePlayerScreen', { guideId: guide.id })}
            >
              <Text style={styles.primaryButtonText}>{guide.ctaLabel}</Text>
            </TouchableOpacity>
          </View>
        ))}

        <View style={styles.communityCard}>
          <View style={styles.communityHeader}>
            <View
              style={{
                width: 36,
                height: 36,
                borderRadius: 18,
                alignItems: 'center',
                justifyContent: 'center',
                backgroundColor: `${theme.colors.success}15`,
              }}
            >
              <MessageSquare size={20} color={theme.colors.success} />
            </View>
            <View style={styles.communityTextWrapper}>
              <Text style={styles.communityTitle}>Pray with the community</Text>
              <Text style={styles.communitySubtitle}>
                Share a request or pray for others on Elbiblio.
              </Text>
            </View>
          </View>
          <TouchableOpacity
            style={styles.communityButton}
            activeOpacity={0.9}
            onPress={() => navigation.navigate('PrayerRequestsScreen')}
          >
            <Text style={styles.communityButtonText}>Go to Prayer Requests</Text>
          </TouchableOpacity>
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
    paddingBottom: theme.spacing.xl,
    gap: theme.spacing.md,
  },
  introTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  introBody: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  tabBar: {
    flexDirection: 'row',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.full,
    padding: 4,
    marginTop: theme.spacing.md,
    marginBottom: theme.spacing.md,
  },
  tabButton: {
    flex: 1,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
    alignItems: 'center',
  },
  tabButtonActive: {
    backgroundColor: theme.colors.primary,
  },
  tabButtonText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontWeight: '500',
  },
  tabButtonTextActive: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  section: {
    gap: theme.spacing.md,
  },
  card: {
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: theme.spacing.sm,
  },
  cardTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '700',
  },
  iconCircle: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  cardBody: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  questionCard: {
    marginTop: theme.spacing.md,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: theme.spacing.sm,
  },
  questionTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
    marginBottom: theme.spacing.xs,
  },
  questionBlock: {
    marginTop: theme.spacing.sm,
    gap: theme.spacing.xs,
  },
  questionOption: {
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.md,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.background,
  },
  questionOptionSelected: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
  },
  questionOptionText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  questionFeedbackCorrect: {
    ...theme.typography.caption.primary,
    color: theme.colors.success,
  },
  questionFeedbackIncorrect: {
    ...theme.typography.caption.primary,
    color: theme.colors.error,
  },
  primaryButton: {
    marginTop: theme.spacing.md,
    alignSelf: 'flex-start',
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.primary,
  },
  primaryButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  secondaryButton: {
    marginTop: theme.spacing.sm,
    alignSelf: 'flex-start',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}08`,
  },
  secondaryButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  bulletList: {
    marginTop: theme.spacing.xs,
    gap: 2,
  },
  bulletItem: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  cardPrayerHeading: {
    marginTop: theme.spacing.sm,
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  cardPrayer: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  stepChipsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  stepChip: {
    flex: 1,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.background,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  stepChipActive: {
    backgroundColor: `${theme.colors.primary}10`,
    borderColor: theme.colors.primary,
  },
  stepChipLabel: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '500',
  },
  stepChipLabelActive: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  stepDurationText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: 2,
  },
  viceInput: {
    marginTop: theme.spacing.sm,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: theme.borderRadius.md,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  passageList: {
    marginTop: theme.spacing.sm,
    gap: theme.spacing.xs,
  },
  passageChip: {
    borderRadius: theme.borderRadius.md,
    borderWidth: 1,
    borderColor: theme.colors.border,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    backgroundColor: theme.colors.background,
  },
  passageChipSelected: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
  },
  passageChipLabel: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  passageChipLabelSelected: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  timerRow: {
    marginTop: theme.spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  timerLabel: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  timerValue: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  timerButtonsRow: {
    marginTop: theme.spacing.sm,
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  timerResetButton: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.background,
  },
  timerResetButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    fontWeight: '500',
  },
  communityCard: {
    marginTop: theme.spacing.sm,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: `${theme.colors.primary}08`,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}20`,
    gap: theme.spacing.sm,
  },
  communityHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  communityTextWrapper: {
    flex: 1,
    gap: 2,
  },
  communityTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  communitySubtitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  communityButton: {
    marginTop: theme.spacing.sm,
    alignSelf: 'flex-start',
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.primary,
  },
  communityButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
});

export default observer(TalkToGodScreen);
