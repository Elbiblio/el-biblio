import React, { useMemo, useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  TextInput,
  Alert,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useTheme } from '@/contexts/ThemeContext';
import { useDailyPathStore } from '@/stores/StoreProvider';
import type { RootStackParamList } from '@/types';
import type { HabitConquestPrayerPayload } from '@/types/habitConquest';
import { recordHabitConquestEntry } from '@/api/habitConquest';
import { runInAction } from 'mobx';

type Props = NativeStackScreenProps<RootStackParamList, 'HabitConquestPrayerScreen'>;

const formatDate = (dateKey: string) => {
  const d = new Date(dateKey);
  if (Number.isNaN(d.getTime())) return dateKey;
  return d.toLocaleDateString(undefined, { weekday: 'long', month: 'short', day: 'numeric' });
};

const PRAYER_SUGGESTIONS = (draft: HabitConquestPrayerPayload) => {
  const base: string[] = [
    '“Jesus, keep the door shut when the urge rises.”',
    '“Spirit, remind me of my pledge when I feel weak.”',
    '“Father, show me a kinder replacement for this vice.”',
    '“Lord, nudge me to reach out before I slip.”',
  ];
  if (!draft.clean) {
    base.unshift('“God, cover today’s stumble with mercy and courage for tomorrow.”');
  }
  if (!draft.pledged) {
    base.unshift('“Jesus, help me choose one loving action tomorrow.”');
  }
  return base.slice(0, 5);
};

const HabitConquestPrayerScreen = ({ navigation, route }: Props) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const insets = useSafeAreaInsets();
  const dailyPathStore = useDailyPathStore();

  const draft = route.params?.draft;
  const remainingDates = route.params?.remainingDates ?? [];

  useEffect(() => {
    if (!draft) {
      navigation.replace('HabitConquestReflectionScreen', {
        pendingDates: remainingDates.length ? remainingDates : undefined,
      });
    }
  }, [draft, navigation, remainingDates]);

  const [prayerIntent, setPrayerIntent] = useState('');
  const [submitting, setSubmitting] = useState(false);

  if (!draft) {
    return null;
  }

  const dateLabel = formatDate(draft.date);
  const todayKey = new Date().toISOString().slice(0, 10);
  const isToday = draft.date === todayKey;
  const suggestions = useMemo(() => PRAYER_SUGGESTIONS(draft), [draft]);

  const handleSubmit = async () => {
    if (submitting) return;
    setSubmitting(true);
    try {
      const intent = prayerIntent.trim().length ? prayerIntent.trim() : null;
      
      // Save locally first for immediate feedback
      dailyPathStore.recordHabitConquestCheckin(draft.date, {
        clean: draft.clean,
        pledged: draft.pledged,
      });
      dailyPathStore.recordHabitConquestReflection({
        ...draft,
        prayerIntent: intent,
      });
      if (isToday) {
        dailyPathStore.markStepComplete('habit_conquest');
      }

      // Sync to backend
      try {
        const response = await recordHabitConquestEntry({
          date: draft.date,
          clean: draft.clean,
          pledged: draft.pledged,
          mood: draft.mood,
          note: draft.note ?? null,
          prayerIntent: intent,
        });
        
        // Update local state with backend streak data
        if (response.summary?.config?.streak) {
          runInAction(() => {
            const hc = dailyPathStore.state.habitConquest;
            if (hc && response.summary.config) {
              hc.streakCurrent = response.summary.config.streak.current;
              hc.streakLongest = response.summary.config.streak.longest;
              hc.cleanDays = response.summary.config.streak.cleanDays;
            }
          });
        }
      } catch (error) {
        console.warn('[HabitConquestPrayerScreen] Backend sync failed, saved locally:', error);
        // Continue anyway - local save succeeded
      }

      if (remainingDates.length) {
        navigation.replace('HabitConquestReflectionScreen', { pendingDates: remainingDates });
      } else {
        navigation.replace('HabitConquestProgressScreen');
      }
    } catch (error) {
      console.warn('[HabitConquestPrayerScreen] Failed to save prayer', error);
      Alert.alert('Save failed', 'Something went wrong while saving your prayer. Please try again.');
      setSubmitting(false);
    }
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top + 8 }]}>
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.headerRow}>
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}>
            <Text style={styles.backText}>Back</Text>
          </TouchableOpacity>
          {remainingDates.length ? (
            <View style={styles.queuePill}>
              <Text style={styles.queueText}>{remainingDates.length + 1} left</Text>
            </View>
          ) : null}
        </View>

        <Text style={styles.kicker}>Prayer & intent</Text>
        <Text style={styles.title}>Pray into tomorrow’s victory</Text>
        <Text style={styles.subtitle}>
          Wrap this session with a clear prayer. We’ll carry it into tomorrow’s accountability
          moment.
        </Text>

        <View style={styles.summaryCard}>
          <View style={styles.summaryHeader}>
            <Text style={styles.summaryLabel}>{dateLabel}</Text>
            <Text style={styles.summaryMeta}>{isToday ? 'Logged today' : 'Catch-up entry'}</Text>
          </View>
          <View style={styles.pillRow}>
            <StatusPill label="Door stayed shut" active={draft.clean} />
            <StatusPill label="Chose something good" active={draft.pledged} tone="secondary" />
            <StatusPill label={draft.mood.charAt(0).toUpperCase() + draft.mood.slice(1)} ghost />
          </View>
          {draft.note ? (
            <View style={styles.noteCard}>
              <Text style={styles.noteLabel}>Reflection note</Text>
              <Text style={styles.noteValue}>{draft.note}</Text>
            </View>
          ) : null}
        </View>

        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>What are you praying?</Text>
            <Text style={styles.sectionHint}>Optional but powerful</Text>
          </View>
          <TextInput
            style={styles.input}
            multiline
            placeholder="“Holy Spirit, remind me to take a deep breath and remember my pledge before I reach for the old comfort…”"
            placeholderTextColor={theme.colors.text.secondary}
            value={prayerIntent}
            onChangeText={setPrayerIntent}
            maxLength={500}
            textAlignVertical="top"
          />
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Need inspiration?</Text>
          <Text style={styles.sectionHint}>Tap to autofill and tweak</Text>
          <View style={styles.suggestionWrap}>
            {suggestions.map((suggestion) => (
              <TouchableOpacity
                key={suggestion}
                style={styles.suggestionChip}
                onPress={() => setPrayerIntent(suggestion.replace(/“|”/g, ''))}
                activeOpacity={0.85}
              >
                <Text style={styles.suggestionText}>{suggestion}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>
      </ScrollView>

      <View style={[styles.footer, { paddingBottom: insets.bottom + 16 }]}>
        <TouchableOpacity
          style={[styles.primaryBtn, submitting && styles.primaryBtnDisabled]}
          onPress={handleSubmit}
          activeOpacity={0.85}
          disabled={submitting}
        >
          <Text style={styles.primaryText}>{submitting ? 'Saving…' : 'Save prayer & finish'}</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const StatusPill = ({
  label,
  active,
  tone = 'primary',
  ghost = false,
}: {
  label: string;
  active?: boolean;
  tone?: 'primary' | 'secondary';
  ghost?: boolean;
}) => {
  const theme = useTheme();
  const baseColor = tone === 'primary' ? theme.colors.primary : theme.colors.secondary;
  const styles = useMemo(
    () =>
      StyleSheet.create({
        pill: {
          paddingHorizontal: 14,
          paddingVertical: 6,
          borderRadius: 999,
          backgroundColor: ghost ? `${theme.colors.surface}EE` : `${baseColor}1A`,
          borderWidth: StyleSheet.hairlineWidth,
          borderColor: ghost ? theme.colors.border : `${baseColor}55`,
        },
        text: {
          color: ghost ? theme.colors.text.secondary : baseColor,
          fontWeight: '600',
          fontSize: 12,
        },
      }),
    [baseColor, ghost, theme.colors.border, theme.colors.surface, theme.colors.text.secondary],
  );

  return (
    <View style={styles.pill}>
      <Text style={styles.text}>{ghost ? label : active ? label : `• ${label}`}</Text>
    </View>
  );
};

const createStyles = (theme: ReturnType<typeof useTheme>) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.colors.background,
    },
    scroll: {
      flex: 1,
    },
    content: {
      paddingHorizontal: 20,
      paddingBottom: 24,
      gap: theme.spacing.lg,
    },
    headerRow: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      marginBottom: theme.spacing.sm,
    },
    backBtn: {
      paddingHorizontal: 14,
      paddingVertical: 8,
      borderRadius: theme.borderRadius.full,
      backgroundColor: theme.colors.surface,
    },
    backText: {
      color: theme.colors.text.primary,
      fontWeight: '600',
    },
    queuePill: {
      paddingHorizontal: 12,
      paddingVertical: 6,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.primary}18`,
    },
    queueText: {
      color: theme.colors.primary,
      fontWeight: '600',
      fontSize: 13,
    },
    kicker: {
      textTransform: 'uppercase',
      letterSpacing: 1,
      color: theme.colors.text.secondary,
      fontSize: 12,
    },
    title: {
      ...theme.typography.heading.large,
      color: theme.colors.text.primary,
    },
    subtitle: {
      ...theme.typography.body.sans,
      color: theme.colors.text.secondary,
    },
    summaryCard: {
      borderRadius: theme.borderRadius.xl,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: theme.colors.border,
      backgroundColor: theme.colors.surface,
      padding: 18,
      gap: 12,
    },
    summaryHeader: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
    },
    summaryLabel: {
      color: theme.colors.text.primary,
      fontWeight: '700',
      fontSize: 16,
    },
    summaryMeta: {
      color: theme.colors.text.secondary,
      fontSize: 13,
    },
    pillRow: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      gap: 8,
    },
    noteCard: {
      borderRadius: theme.borderRadius.lg,
      backgroundColor: `${theme.colors.primary}08`,
      padding: 12,
      gap: 6,
    },
    noteLabel: {
      color: theme.colors.primary,
      fontWeight: '600',
      fontSize: 13,
    },
    noteValue: {
      color: theme.colors.text.primary,
      fontSize: 14,
      lineHeight: 20,
    },
    section: {
      gap: 10,
    },
    sectionHeader: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
    },
    sectionTitle: {
      ...theme.typography.heading.small,
      color: theme.colors.text.primary,
    },
    sectionHint: {
      color: theme.colors.text.secondary,
      fontSize: 13,
    },
    input: {
      minHeight: 140,
      borderRadius: theme.borderRadius.lg,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: theme.colors.border,
      backgroundColor: theme.colors.surface,
      padding: 16,
      fontSize: 15,
      color: theme.colors.text.primary,
    },
    suggestionWrap: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      gap: 10,
    },
    suggestionChip: {
      paddingHorizontal: 12,
      paddingVertical: 10,
      borderRadius: theme.borderRadius.full,
      backgroundColor: theme.colors.surface,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: theme.colors.border,
    },
    suggestionText: {
      color: theme.colors.text.primary,
      fontSize: 13,
    },
    footer: {
      paddingHorizontal: 20,
      borderTopWidth: StyleSheet.hairlineWidth,
      borderTopColor: theme.colors.border,
      backgroundColor: theme.colors.background,
    },
    primaryBtn: {
      borderRadius: theme.borderRadius.full,
      backgroundColor: theme.colors.primary,
      paddingVertical: 16,
      alignItems: 'center',
    },
    primaryBtnDisabled: {
      opacity: 0.7,
    },
    primaryText: {
      color: theme.colors.text.inverse,
      fontWeight: '600',
      fontSize: 16,
    },
  });

export default HabitConquestPrayerScreen;
