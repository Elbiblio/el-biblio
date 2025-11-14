import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import type { Theme } from '@/theme';
import type { RootStackParamList } from '@/types';
import { ArrowLeft } from '@/components/Icons';
import { getGuideById, ReadingReflectionConfig } from '@/services/GuideService';
import Animated, { FadeInDown } from 'react-native-reanimated';

export type HolySpiritScreenProps = NativeStackScreenProps<RootStackParamList, 'HolySpiritScreen'>;

const HOLY_SPIRIT_POINTS = [
  'The Holy Spirit is God’s own sanctifying grace and power living in us.',
  'The Spirit does not force itself on us – He is invited, welcomed, and desired.',
  'With the Holy Spirit, we do not need to fear the world.',
  'Through the Spirit, we see others as children of the Kingdom, not strangers.',
  'The Spirit marks us as citizens of the Kingdom and helps us live out that identity.',
  'The Spirit supplies what we truly need, in line with God’s plan for us.',
];

type HolySpiritStepId = 'read' | 'meditate' | 'pray';

const HOLY_STEPS: { id: HolySpiritStepId; title: string; subtitle: string }[] = [
  {
    id: 'read',
    title: 'Read',
    subtitle: 'Receive the teaching slowly',
  },
  {
    id: 'meditate',
    title: 'Meditate',
    subtitle: 'Notice what the Spirit highlights',
  },
  {
    id: 'pray',
    title: 'Pray',
    subtitle: 'Respond to God in trust',
  },
];

const HolySpiritScreen = ({ navigation }: HolySpiritScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const [sectionTitle, setSectionTitle] = React.useState<string | null>(null);
  const [sectionBody, setSectionBody] = React.useState<string | null>(null);
  const [reflectionPrompt, setReflectionPrompt] = React.useState<string | null>(null);
  const [activeStep, setActiveStep] = React.useState<HolySpiritStepId>('read');

  React.useEffect(() => {
    let isActive = true;

    const loadGuide = async () => {
      try {
        const guide = await getGuideById('holy-spirit');
        if (!guide) return;
        if (guide.content.mode !== 'reading_reflection') return;
        const cfg = guide.content as ReadingReflectionConfig;
        const firstSection = cfg.sections[0];
        if (isActive) {
          if (firstSection) {
            setSectionTitle(firstSection.title);
            setSectionBody(firstSection.body);
          }
          setReflectionPrompt(cfg.reflectionPrompt ?? null);
        }
      } catch {
        // ignore
      }
    };

    void loadGuide();

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
        <Text style={styles.title}>Holy Spirit</Text>
        <View style={{ width: 24 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <Text style={styles.introTitle}>Welcome the Holy Spirit afresh</Text>
        <Text style={styles.introBody}>
          The Holy Spirit is God’s own presence in you – the One who finishes the work of the
          Kingdom in your heart and teaches you to live as God’s child.
        </Text>
        <Animated.View entering={FadeInDown.duration(280)} style={styles.stepChipsContainer}>
          {HOLY_STEPS.map(step => {
            const isActive = step.id === activeStep;
            return (
              <TouchableOpacity
                key={step.id}
                style={[styles.stepChip, isActive && styles.stepChipActive]}
                activeOpacity={0.9}
                onPress={() => setActiveStep(step.id)}
              >
                <Text style={isActive ? styles.stepChipLabelActive : styles.stepChipLabel}>
                  {step.title}
                </Text>
                <Text style={styles.stepChipSubtitle}>{step.subtitle}</Text>
              </TouchableOpacity>
            );
          })}
        </Animated.View>

        {activeStep === 'read' && (
          <Animated.View entering={FadeInDown.delay(80).duration(260)} style={styles.card}>
            <Text style={styles.cardTitle}>{sectionTitle || 'God with us, within us'}</Text>
            <Text style={styles.cardBody}>
              {sectionBody ||
                'The prophets longed for the day when God would dwell with His people. In Christ, that day has come, and through the Holy Spirit, God now lives in you. The Spirit reveals God’s plan step by step and helps you trust Him in every season.'}
            </Text>
            <View style={styles.bulletList}>
              {HOLY_SPIRIT_POINTS.map(point => (
                <Text key={point} style={styles.bulletItem}>
                  • {point}
                </Text>
              ))}
            </View>
          </Animated.View>
        )}

        {activeStep === 'meditate' && (
          <Animated.View entering={FadeInDown.delay(80).duration(260)} style={styles.card}>
            <Text style={styles.cardTitle}>Meditate with the Spirit</Text>
            <Text style={styles.cardBody}>
              Let one phrase or idea stay with you. Notice where it meets your fears,
              relationships, or calling in the Kingdom.
            </Text>
            <View style={styles.bulletList}>
              <Text style={styles.bulletItem}>• Where am I most afraid or anxious today?</Text>
              <Text style={styles.bulletItem}>
                • Who do I find hard to see as a brother or sister in the Kingdom?
              </Text>
              <Text style={styles.bulletItem}>
                • Which part of my day do I most need to invite the Spirit into right now?
              </Text>
            </View>
            {reflectionPrompt && (
              <Text style={styles.cardBody}>{reflectionPrompt}</Text>
            )}
          </Animated.View>
        )}

        {activeStep === 'pray' && (
          <Animated.View entering={FadeInDown.delay(80).duration(260)} style={styles.card}>
            <Text style={styles.cardTitle}>Respond in prayer</Text>
            <Text style={styles.cardBody}>
              Use this space to invite the Spirit into real situations in your life – fears,
              relationships, work, and your calling in the Kingdom.
            </Text>
            <Text style={styles.cardPrayerHeading}>Suggested prayer</Text>
            <Text style={styles.cardPrayer}>
              Holy Spirit, I welcome You. Fill me again with Your presence. Teach me to see
              the world without fear, to love others as children of the Kingdom, and to walk in
              the works You have prepared for me. Lead me today in every decision.
            </Text>
          </Animated.View>
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
  stepChipsContainer: {
    marginTop: theme.spacing.sm,
    flexDirection: 'row',
    gap: theme.spacing.sm,
  },
  stepChip: {
    flex: 1,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.background,
  },
  stepChipActive: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
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
  stepChipSubtitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: 2,
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
  cardBody: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
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
});

export default observer(HolySpiritScreen);
