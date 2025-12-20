import React, { useMemo, useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, TextInput } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '@/contexts/ThemeContext';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import { HABIT_CONQUEST_MOODS, type HabitConquestMood } from '@/types/habitConquest';

type Props = NativeStackScreenProps<RootStackParamList, 'HabitConquestReflectionScreen'>;

const MOOD_COPY: Record<HabitConquestMood, { label: string; detail: string; emoji: string }> = {
  renewed: { label: 'Renewed', detail: 'Light and refreshed', emoji: '✨' },
  steady: { label: 'Steady', detail: 'Calm and focused', emoji: '🌿' },
  tired: { label: 'Tired', detail: 'Needing rest', emoji: '😌' },
  hopeful: { label: 'Hopeful', detail: 'Trusting the process', emoji: '🌅' },
  resilient: { label: 'Resilient', detail: 'Pushing through', emoji: '🛡️' },
  convicted: { label: 'Convicted', detail: 'Ready to repent', emoji: '🔥' },
};

const formatDate = (dateKey: string) => {
  const d = new Date(dateKey);
  if (Number.isNaN(d.getTime())) return dateKey;
  return d.toLocaleDateString(undefined, { weekday: 'long', month: 'short', day: 'numeric' });
};

const HabitConquestReflectionScreen: React.FC<Props> = ({ navigation, route }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const insets = useSafeAreaInsets();

  const todayKey = new Date().toISOString().slice(0, 10);
  const pendingDatesRaw: string[] =
    route.params?.pendingDates && route.params.pendingDates.length > 0
      ? [...route.params.pendingDates]
      : [todayKey];
  const pendingDates: string[] = useMemo(
    () => Array.from(new Set(pendingDatesRaw)),
    [pendingDatesRaw],
  );

  const currentDate = pendingDates[0];
  const remainingDates = pendingDates.slice(1);

  useEffect(() => {
    if (!currentDate) {
      navigation.replace('HabitConquestSessionScreen');
    }
  }, [currentDate, navigation]);

  const [clean, setClean] = useState(true);
  const [pledged, setPledged] = useState(true);
  const [mood, setMood] = useState<HabitConquestMood>('renewed');
  const [note, setNote] = useState('');

  if (!currentDate) {
    return null;
  }

  const handleContinue = () => {
    navigation.navigate('HabitConquestPrayerScreen', {
      draft: {
        date: currentDate,
        clean,
        pledged,
        mood,
        note: note.trim().length ? note.trim() : null,
      },
      remainingDates,
    });
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
          {pendingDates.length > 1 ? (
            <View style={styles.queuePill}>
              <Text style={styles.queueText}>{pendingDates.length} days queued</Text>
            </View>
          ) : null}
        </View>

        <Text style={styles.kicker}>Reflection</Text>
        <Text style={styles.title}>Log today’s state of heart</Text>
        <Text style={styles.subtitle}>
          Honest check-ins keep your accountability fresh. We’ll move straight into prayer after this step.
        </Text>

        <View style={styles.dateCard}>
          <View style={styles.dateDot} />
          <View style={{ flex: 1 }}>
            <Text style={styles.dateLabel}>{formatDate(currentDate)}</Text>
            <Text style={styles.dateMeta}>
              {pendingDates.length === 1 ? 'Today' : remainingDates.length ? 'Catch-up entry' : 'Final entry for today'}
            </Text>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Did you keep your vows?</Text>
          <View style={styles.toggleGrid}>
            <ToggleChip
              label="Kept my door shut"
              active={clean}
              onPress={() => setClean(!clean)}
              themeColor={theme.colors.primary}
            />
            <ToggleChip
              label="Chose something good"
              active={pledged}
              onPress={() => setPledged(!pledged)}
              themeColor={theme.colors.secondary}
            />
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Capture today’s mood</Text>
          <View style={styles.moodGrid}>
            {HABIT_CONQUEST_MOODS.map((item) => {
              const copy = MOOD_COPY[item];
              const isActive = mood === item;
              return (
                <TouchableOpacity
                  key={item}
                  style={[styles.moodCard, isActive && styles.moodCardActive]}
                  onPress={() => setMood(item)}
                  activeOpacity={0.9}
                >
                  <Text style={styles.moodEmoji}>{copy.emoji}</Text>
                  <Text style={[styles.moodLabel, isActive && styles.moodLabelActive]}>{copy.label}</Text>
                  <Text style={[styles.moodDetail, isActive && styles.moodDetailActive]}>{copy.detail}</Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Any notes for tomorrow?</Text>
            <Text style={styles.sectionHint}>Optional</Text>
          </View>
          <TextInput
            style={styles.noteInput}
            multiline
            maxLength={400}
            placeholder="What helped or hindered you today?"
            placeholderTextColor={theme.colors.text.secondary}
            value={note}
            onChangeText={setNote}
            textAlignVertical="top"
          />
        </View>
      </ScrollView>

      <View style={[styles.footer, { paddingBottom: insets.bottom + 16 }]}>
        <TouchableOpacity style={styles.primaryBtn} onPress={handleContinue} activeOpacity={0.9}>
          <Text style={styles.primaryText}>Continue to prayer</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const ToggleChip = ({
  label,
  active,
  onPress,
  themeColor,
}: {
  label: string;
  active: boolean;
  onPress: () => void;
  themeColor: string;
}) => (
  <TouchableOpacity
    onPress={onPress}
    style={[
      chipStyles.base,
      { borderColor: themeColor },
      active && { backgroundColor: `${themeColor}18` },
    ]}
    activeOpacity={0.85}
  >
    <Text style={[chipStyles.text, active && { color: themeColor }]}>{label}</Text>
  </TouchableOpacity>
);

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
    dateCard: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 12,
      padding: 16,
      borderRadius: theme.borderRadius.lg,
      backgroundColor: theme.colors.surface,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: theme.colors.border,
    },
    dateDot: {
      width: 10,
      height: 10,
      borderRadius: 5,
      backgroundColor: theme.colors.primary,
    },
    dateLabel: {
      color: theme.colors.text.primary,
      fontWeight: '600',
      fontSize: 16,
    },
    dateMeta: {
      color: theme.colors.text.secondary,
      fontSize: 13,
    },
    section: {
      gap: 12,
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
    toggleGrid: {
      flexDirection: 'row',
      gap: 12,
      flexWrap: 'wrap',
    },
    moodGrid: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      gap: 12,
    },
    moodCard: {
      width: '47%',
      minWidth: 150,
      flexGrow: 1,
      borderRadius: theme.borderRadius.lg,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: theme.colors.border,
      padding: 16,
      backgroundColor: theme.colors.surface,
      gap: 6,
    },
    moodCardActive: {
      borderColor: theme.colors.primary,
      backgroundColor: `${theme.colors.primary}12`,
    },
    moodEmoji: {
      fontSize: 22,
    },
    moodLabel: {
      fontWeight: '600',
      color: theme.colors.text.primary,
    },
    moodLabelActive: {
      color: theme.colors.primary,
    },
    moodDetail: {
      color: theme.colors.text.secondary,
      fontSize: 13,
    },
    moodDetailActive: {
      color: theme.colors.primary,
    },
    noteInput: {
      minHeight: 120,
      borderRadius: theme.borderRadius.lg,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: theme.colors.border,
      padding: 16,
      backgroundColor: theme.colors.surface,
      color: theme.colors.text.primary,
      fontSize: 15,
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
    primaryText: {
      color: theme.colors.text.inverse,
      fontWeight: '600',
      fontSize: 16,
    },
  });

const chipStyles = StyleSheet.create({
  base: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 999,
    borderWidth: StyleSheet.hairlineWidth,
  },
  text: {
    fontWeight: '600',
  },
});

export default HabitConquestReflectionScreen;
