import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, TextInput } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { observer } from 'mobx-react-lite';
import Animated, { FadeInDown, FadeIn } from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import { useTheme } from '@/contexts/ThemeContext';
import type { Theme } from '@/theme';
import type { RootStackParamList } from '@/types';
import { ArrowLeft, Brain } from '@/components/Icons';
import { CAREER_DEFINITIONS, DAILY_TASKS, STRENGTH_DEFINITIONS } from '@/services/spiritualCareerData';

export type CareerHistoricMeditationScreenProps = NativeStackScreenProps<
  RootStackParamList,
  'CareerHistoricMeditationScreen'
>;

type StrengthCategoryKey = 'expression' | 'wisdom' | 'care' | 'action' | 'service' | 'spiritual';
type StepKey = 'joy' | 'direct' | 'indirect' | 'combined' | 'reflect';

const CATEGORY_LABELS: Record<StrengthCategoryKey, string> = {
  expression: 'creative expression',
  wisdom: 'wisdom and discernment',
  care: 'care and nurture',
  action: 'courageous action',
  service: 'service and stewardship',
  spiritual: 'spiritual focus and prayer',
};

const CATEGORY_SHORT_LABELS: Record<StrengthCategoryKey, string> = {
  expression: 'Expression',
  wisdom: 'Wisdom',
  care: 'Care',
  action: 'Action',
  service: 'Service',
  spiritual: 'Prayer',
};

const JOY_OPTIONS: {
  id: string;
  label: string;
  description: string;
  categories: StrengthCategoryKey[];
}[] = [
  {
    id: 'create',
    label: 'Creating, designing, or crafting',
    description: 'Art, writing, music, media, or anything creative',
    categories: ['expression'],
  },
  {
    id: 'encourage',
    label: 'Encouraging or mentoring people',
    description: 'Cheering people on, helping them grow',
    categories: ['care'],
  },
  {
    id: 'host',
    label: 'Hosting and welcoming',
    description: 'Making spaces feel warm and safe',
    categories: ['care'],
  },
  {
    id: 'organize',
    label: 'Organizing and planning',
    description: 'Bringing order, systems, or structure to things',
    categories: ['service', 'wisdom'],
  },
  {
    id: 'start',
    label: 'Starting new things',
    description: 'Launching projects, groups, or ideas',
    categories: ['action'],
  },
  {
    id: 'justice',
    label: 'Standing up for justice',
    description: 'Defending the vulnerable, addressing unfairness',
    categories: ['action'],
  },
  {
    id: 'pray',
    label: 'Praying and worshipping',
    description: 'Spending time with God in prayer or worship',
    categories: ['spiritual'],
  },
  {
    id: 'listen',
    label: 'Listening deeply to others',
    description: 'Sitting with people in their stories and pain',
    categories: ['care', 'spiritual'],
  },
  {
    id: 'teach',
    label: 'Teaching or explaining things',
    description: 'Helping people understand ideas or Scripture',
    categories: ['wisdom', 'care'],
  },
];

const STEP_FLOW: StepKey[] = ['joy', 'direct', 'indirect', 'combined', 'reflect'];

const STEP_META: Record<StepKey, { title: string; subtitle: string }> = {
  joy: {
    title: "Recognize joy as God's clue",
    subtitle: 'Name the work that has always felt life-giving.',
  },
  direct: {
    title: 'See the spiritual strength',
    subtitle: 'Understand how heaven names this talent.',
  },
  indirect: {
    title: 'Bring it into your everyday work',
    subtitle: 'Shape your current assignment with this grace.',
  },
  combined: {
    title: 'Design a blended rhythm',
    subtitle: 'Hold faithful provision and direct Kingdom work together.',
  },
  reflect: {
    title: 'Pray to God about your role',
    subtitle: 'Listen to know what you need to be ready, if you are not ready yet.',
  },
};

const TOTAL_STEPS = STEP_FLOW.length;

const PRIMARY_CTA_LABELS: Record<StepKey, string> = {
  joy: 'Your strength',
  direct: 'Your role',
  indirect: 'Create rhythm',
  combined: 'Pray with God',
  reflect: 'Finish meditation',
};

const CareerHistoricMeditationScreen = ({
  navigation,
}: CareerHistoricMeditationScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const [selectedJoyIds, setSelectedJoyIds] = React.useState<string[]>([]);
  const [currentJob, setCurrentJob] = React.useState('');
  const [step, setStep] = React.useState<StepKey>('joy');

  const joySummary = React.useMemo(() => {
    if (!selectedJoyIds.length) return null;

    const counts: Record<StrengthCategoryKey, number> = {
      expression: 0,
      wisdom: 0,
      care: 0,
      action: 0,
      service: 0,
      spiritual: 0,
    };

    selectedJoyIds.forEach(id => {
      const option = JOY_OPTIONS.find(o => o.id === id);
      if (!option) {
        return;
      }
      option.categories.forEach(cat => {
        counts[cat] += 1;
      });
    });

    let primary: StrengthCategoryKey | null = null;
    let bestScore = 0;
    (Object.keys(counts) as StrengthCategoryKey[]).forEach(cat => {
      if (counts[cat] > bestScore) {
        bestScore = counts[cat];
        primary = cat;
      }
    });

    if (!primary || bestScore === 0) {
      return null;
    }

    const strengths = STRENGTH_DEFINITIONS.filter(s => s.category === primary).map(
      s => s.label,
    );
    const careers = CAREER_DEFINITIONS[primary] || [];
    const tasks = DAILY_TASKS[primary] || [];

    return { primary, strengths, careers, tasks };
  }, [selectedJoyIds]);

  const currentIndex = React.useMemo(() => STEP_FLOW.indexOf(step), [step]);
  const currentMeta = STEP_META[step];
  const isFirstStep = currentIndex === 0;
  const isFinalStep = currentIndex === TOTAL_STEPS - 1;
  const primaryCtaLabel = PRIMARY_CTA_LABELS[step];
  const progressPercent = (currentIndex + 1) / TOTAL_STEPS;

  const toggleJoyOption = (id: string) => {
    setSelectedJoyIds(prev =>
      prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id],
    );
  };

  const canContinue = selectedJoyIds.length > 0;
  const handleAdvance = React.useCallback(
    (next: StepKey) => {
      if (!joySummary && next !== 'joy') {
        return;
      }
      setStep(next);
    },
    [joySummary],
  );

  const goToPrev = React.useCallback(() => {
    if (isFirstStep) {
      return;
    }
    setStep(STEP_FLOW[currentIndex - 1]);
  }, [currentIndex, isFirstStep]);

  const goToNext = React.useCallback(() => {
    if (isFinalStep) {
      navigation.goBack();
      return;
    }
    handleAdvance(STEP_FLOW[currentIndex + 1]);
  }, [currentIndex, handleAdvance, isFinalStep, navigation]);

  const nextDisabled = step === 'joy' && !canContinue;
  const heroProgressWidth = `${Math.round(Math.max(progressPercent, 0.12) * 100)}%` as `${number}%`;

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>Historic career meditation</Text>
        <View style={{ width: 24 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <Animated.View entering={FadeInDown.duration(280)} style={styles.heroCard}>
          <LinearGradient
            colors={[`${theme.colors.primary}1A`, `${theme.colors.primary}08`]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.heroGradient}
          >
            <View style={styles.heroTopRow}>
              <View style={styles.stepBadge}>
                <Text style={styles.stepBadgeText}>
                  Step {currentIndex + 1} of {TOTAL_STEPS}
                </Text>
              </View>
              <View style={styles.heroIcon}>
                <Brain size={24} color={theme.colors.primary} />
              </View>
            </View>
            <Text style={styles.heroTitle}>{currentMeta.title}</Text>
            <Text style={styles.heroSubtitle}>{currentMeta.subtitle}</Text>
            <View style={styles.progressRow}>
              <View style={styles.progressTrack}>
                <View style={[styles.progressFill, { width: heroProgressWidth }]} />
              </View>
              <Text style={styles.progressValue}>{Math.round(progressPercent * 100)}%</Text>
            </View>
          </LinearGradient>
        </Animated.View>

        {step === 'joy' && (
          <Animated.View entering={FadeInDown.delay(100).duration(320)} style={styles.stepCard}>
            <Text style={styles.blockTitle}>Joy as evidence of calling</Text>
            <Text style={styles.blockBody}>
              The world often says that earning money is proof of your talents. In the Kingdom,
              your true talents are often revealed by the work you are joyful doing for its own
              sake, even when no one is paying you. Like Jesus said, "My food is to do the will of
              the Father." Without this work can never feel satisfying or purposeful and may even
              lead to depression.
            </Text>
            <Text style={styles.blockBody}>
              Here we look back over your story with God to notice what He has placed in you.
            </Text>
            <Text style={styles.sectionHeading}>What have you loved doing?</Text>
            <Text style={styles.sectionBody}>
              Tap the areas that have consistently brought you joy for their own sake.
            </Text>
            <View style={styles.joyGrid}>
              {JOY_OPTIONS.map(option => {
                const isSelected = selectedJoyIds.includes(option.id);
                return (
                  <TouchableOpacity
                    key={option.id}
                    style={[
                      styles.joyTile,
                      isSelected && styles.joyTileSelected,
                    ]}
                    activeOpacity={0.85}
                    onPress={() => toggleJoyOption(option.id)}
                  >
                    <Text style={isSelected ? styles.joyTileLabelSelected : styles.joyTileLabel}>
                      {option.label}
                    </Text>
                    <Text
                      style={
                        isSelected
                          ? styles.joyTileDescriptionSelected
                          : styles.joyTileDescription
                      }
                    >
                      {option.description}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </Animated.View>
        )}

        {step === 'direct' && joySummary && (
          <Animated.View entering={FadeIn.delay(100).duration(280)} style={styles.stepCard}>
            <Text style={styles.sectionHeading}>Notice the spiritual strength</Text>
            <Text style={styles.sectionBody}>
              A strength God has placed in you: {CATEGORY_LABELS[joySummary.primary]}.
            </Text>
            <Text style={styles.sectionBody}>
              This is not proven by how much money you earn, but by how often you find joy serving
              in this way. These are real talents the Spirit has entrusted to you.
            </Text>
            {!!joySummary.strengths.length && (
              <View style={styles.callout}>
                <Text style={styles.calloutLabel}>Spiritual language for this grace</Text>
                <Text style={styles.calloutBody}>{joySummary.strengths.join(', ')}</Text>
              </View>
            )}
            <View style={styles.applySection}>
              <Text style={styles.applyTitle}>Direct Kingdom expressions</Text>
              <Text style={styles.applyBody}>
                Roles where this strength sits at the very center of the work:
              </Text>
              {joySummary.careers.slice(0, 3).map(career => (
                <View key={career.title} style={styles.applyTile}>
                  <Text style={styles.applyTileTitle}>
                    {career.icon} {career.title}
                  </Text>
                  <Text style={styles.applyTileBody}>{career.description}</Text>
                </View>
              ))}
            </View>
          </Animated.View>
        )}

        {step === 'indirect' && joySummary && (
          <Animated.View entering={FadeIn.delay(100).duration(280)} style={styles.stepCard}>
            <Text style={styles.sectionHeading}>Carry it into your current work</Text>
            <Text style={styles.sectionBody}>
              Tell us what occupies most of your week, then imagine how this strength can shape
              the way you show up there.
            </Text>
            <TextInput
              value={currentJob}
              onChangeText={setCurrentJob}
              placeholder="e.g. teacher, engineer, parent, student..."
              placeholderTextColor={theme.colors.text.tertiary}
              style={styles.jobInput}
            />
            <View style={styles.callout}>
              <Text style={styles.calloutLabel}>As a {currentJob.trim() || 'worker or student'}</Text>
              <Text style={styles.calloutBody}>
                Express {CATEGORY_LABELS[joySummary.primary]} in practical, Spirit-led ways:
              </Text>
              {joySummary.tasks.slice(0, 2).map(task => (
                <Text key={task.id} style={styles.calloutBullet}>
                  • {task.text}
                </Text>
              ))}
            </View>
          </Animated.View>
        )}

        {step === 'combined' && joySummary && (
          <Animated.View entering={FadeIn.delay(100).duration(280)} style={styles.stepCard}>
            <Text style={styles.sectionHeading}>Hold direct and indirect together</Text>
            <Text style={styles.sectionBody}>
              Stay faithful in your current assignment while dedicating intentional time to direct
              service flowing from this gift.
            </Text>
            {joySummary.careers[0] && (
              <View style={styles.callout}>
                <Text style={styles.calloutLabel}>Try a blended rhythm</Text>
                <Text style={styles.calloutBody}>
                  Keep your present role and explore something like {joySummary.careers[0].title}
                  {' '}on a weekly or monthly cadence.
                </Text>
              </View>
            )}
            {joySummary.tasks[0] && (
              <Text style={styles.sectionBody}>
                Start with one small practice this week: {joySummary.tasks[0].text}
              </Text>
            )}
          </Animated.View>
        )}

        {step === 'reflect' && joySummary && (
          <Animated.View entering={FadeIn.delay(100).duration(280)} style={styles.stepCard}>
            <Text style={styles.sectionHeading}>Pray to God abour your role</Text>
            <Text style={styles.sectionBody}>
              Moses was in a hurry to execute justice before he was ready. And though his role was to guide and give the law, he did not yet encounter God.
              Every believer today has even greater opportunity than Moses because the privilege of the Holy Spirit is now opened to all.
              Pray for a relationship with the Holy Spirit  not just to reveal your role in the Kingdom but to make you ready for it and
              renew your strength to carry it out with great diligence, trusting that God will provide for all your needs.
            </Text>
            <View style={styles.callout}>
              <Text style={styles.calloutLabel}>Journal and pray:</Text>
              <Text style={styles.calloutBullet}>• What do you desire to do for God's Kingdom?</Text>
              <Text style={styles.calloutBullet}>• Do your current roles today help to bring about God's Kingdom directly or indirectly?</Text>
              <Text style={styles.calloutBullet}>• If not, how can you adjust your roles to better serve God's Kingdom?</Text>
              <Text style={styles.calloutBullet}>• Do you feel satisified, safe or overwhelmed with your wordly role?</Text>
              <Text style={styles.calloutBullet}>• If not talk to God about how you feel, let His Spirit inspire you on practical directions to take</Text>
            </View>
          </Animated.View>
        )}
      </ScrollView>

      <Animated.View entering={FadeInDown.delay(120).duration(260)} style={styles.footerBar}>
        <TouchableOpacity
          style={[styles.footerButton, styles.footerButtonSecondary, isFirstStep && styles.footerButtonDisabled]}
          activeOpacity={0.85}
          onPress={goToPrev}
          disabled={isFirstStep}
        >
          <Text style={styles.footerButtonTextSecondary}>Back</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.footerButton, nextDisabled && styles.footerButtonDisabled]}
          activeOpacity={0.85}
          onPress={goToNext}
          disabled={nextDisabled}
        >
          <Text style={styles.footerButtonTextPrimary}>{primaryCtaLabel}</Text>
        </TouchableOpacity>
      </Animated.View>
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
    paddingHorizontal: theme.spacing.md,
    paddingBottom: theme.spacing.xxl + theme.spacing.xl,
    gap: theme.spacing.lg,
  },
  heroCard: {
    borderRadius: theme.borderRadius.xl,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: `${theme.colors.primary}26`,
    backgroundColor: theme.colors.surface,
  },
  heroGradient: {
    padding: theme.spacing.lg,
    gap: theme.spacing.md,
  },
  heroTopRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  stepBadge: {
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.background,
  },
  stepBadgeText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontWeight: '500',
  },
  heroIcon: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: `${theme.colors.primary}14`,
  },
  heroTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
  },
  heroSubtitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
  },
  progressRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  progressTrack: {
    flex: 1,
    height: 6,
    borderRadius: theme.borderRadius.full,
    backgroundColor: `${theme.colors.primary}14`,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: theme.colors.primary,
    borderRadius: theme.borderRadius.full,
  },
  progressValue: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  stepCard: {
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.xl,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: theme.spacing.md,
    shadowColor: theme.colors.shadow,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 16,
    elevation: 6,
  },
  blockTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
  },
  blockBody: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
  },
  sectionHeading: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  sectionBody: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  joyGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.sm,
  },
  joyTile: {
    width: '48%',
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.background,
    gap: theme.spacing.xs,
  },
  joyTileSelected: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
    shadowColor: theme.colors.shadow,
    shadowOpacity: 0.12,
    shadowOffset: { width: 0, height: 10 },
    shadowRadius: 18,
    elevation: 5,
  },
  joyTileLabel: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  joyTileLabelSelected: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '700',
  },
  joyTileDescription: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  joyTileDescriptionSelected: {
    ...theme.typography.caption.secondary,
    color: theme.colors.primary,
  },
  callout: {
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}26`,
    gap: theme.spacing.xs,
  },
  calloutLabel: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  calloutBody: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  calloutBullet: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  applySection: {
    gap: theme.spacing.sm,
  },
  applyTitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  applyBody: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  applyTile: {
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.background,
    gap: theme.spacing.xs,
  },
  applyTileTitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  applyTileBody: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  jobInput: {
    marginTop: theme.spacing.sm,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: theme.borderRadius.lg,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    backgroundColor: theme.colors.background,
  },
  footerBar: {
    position: 'absolute',
    left: theme.spacing.md,
    right: theme.spacing.md,
    bottom: theme.spacing.md,
    flexDirection: 'row',
    gap: theme.spacing.sm,
  },
  footerButton: {
    flex: 1,
    paddingVertical: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: theme.colors.shadow,
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.15,
    shadowRadius: 24,
    elevation: 8,
  },
  footerButtonSecondary: {
    backgroundColor: theme.colors.background,
    borderWidth: 1,
    borderColor: theme.colors.border,
    shadowOpacity: 0,
    elevation: 0,
  },
  footerButtonDisabled: {
    opacity: 0.4,
  },
  footerButtonTextPrimary: {
    ...theme.typography.button.primary,
    color: theme.colors.text.inverse,
  },
  footerButtonTextSecondary: {
    ...theme.typography.button.secondary,
    color: theme.colors.text.primary,
  },
});

export default observer(CareerHistoricMeditationScreen);
