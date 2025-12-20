import React, { useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import { useDailyPathStore } from '@/stores/StoreProvider';
import { Shield } from '@/components/Icons';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import type { HabitConquestJournalEntry, HabitConquestMood } from '@/types/habitConquest';

type Props = NativeStackScreenProps<RootStackParamList, 'HabitConquestProgressScreen'>;

const HabitConquestProgressScreen: React.FC<Props> = observer(({ navigation }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const insets = useSafeAreaInsets();
  const dailyPathStore = useDailyPathStore();
  const hc = dailyPathStore.state.habitConquest;
  const journal = hc?.journal ?? [];
  const checkins = hc?.checkins ?? {};

  const stats = useMemo(() => computeStreakStats(checkins), [checkins]);
  const pendingDates = dailyPathStore.getMissingHabitConquestDates?.() ?? [];
  const todayKey = getTodayKey();
  const latestEntries = journal.slice(0, 8);
  const hasEntries = latestEntries.length > 0;
  const recordedDays = getRecordedDayCount(checkins);
  const cleanRate =
    recordedDays > 0 ? Math.round((stats.cleanDays / recordedDays) * 100) : null;

  const handleCatchUp = () => {
    if (!pendingDates.length) return;
    navigation.navigate('HabitConquestReflectionScreen', { pendingDates });
  };

  const handleLogToday = () => {
    navigation.navigate('HabitConquestReflectionScreen', { pendingDates: [todayKey] });
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top + 8 }]}>
      <ScrollView
        contentContainerStyle={[styles.content, { paddingBottom: insets.bottom + 32 }]}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.headerRow}>
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}>
            <Text style={styles.backText}>Back</Text>
          </TouchableOpacity>
          <Text style={styles.screenTitle}>Habit Conquest</Text>
        </View>

        <View style={styles.heroCard}>
          <View style={styles.heroHeader}>
            <Shield size={30} color={theme.colors.text.inverse} />
            <View>
              <Text style={styles.heroEyebrow}>Current streak</Text>
              <Text style={styles.heroTitle}>{stats.currentStreak} clean day{stats.currentStreak === 1 ? '' : 's'}</Text>
            </View>
          </View>
          <View style={styles.heroStatsRow}>
            <StatBadge label="Longest run" value={`${stats.longestStreak}`} suffix="days" />
            <StatBadge label="Clean days logged" value={`${stats.cleanDays}`} />
            <StatBadge label="Check-ins stored" value={`${recordedDays}`} />
          </View>
          <View style={styles.heroActions}>
            <TouchableOpacity
              style={[styles.primaryBtn, styles.heroPrimary]}
              onPress={() => navigation.navigate('HabitConquestSessionScreen')}
              activeOpacity={0.9}
            >
              <Text style={styles.primaryBtnText}>Start a guided session</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.primaryBtn, styles.heroSecondary]}
              onPress={handleLogToday}
            >
              <Text style={[styles.primaryBtnText, { color: theme.colors.primary }]}>
                Log reflection
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        {pendingDates.length ? (
          <View style={styles.catchUpCard}>
            <View style={{ flex: 1 }}>
              <Text style={styles.catchUpTitle}>Catch up on {pendingDates.length} day{pendingDates.length === 1 ? '' : 's'}</Text>
              <Text style={styles.catchUpSubtitle}>
                Finish reflection + prayer so your streak and prayer trail stay accurate.
              </Text>
            </View>
            <TouchableOpacity style={styles.catchUpBtn} onPress={handleCatchUp}>
              <Text style={styles.catchUpBtnText}>Finish queued</Text>
            </TouchableOpacity>
          </View>
        ) : null}

        <View style={styles.metricsRow}>
          <InsightCard
            label="Clean rate"
            value={cleanRate !== null ? `${cleanRate}%` : '—'}
            caption={cleanRate !== null ? 'of recorded days' : 'Log more days to see this'}
          />
          <InsightCard
            label="Prayer log"
            value={`${journal.length}`}
            caption="Saved entries with mood + notes"
          />
        </View>

        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Journal & prayer trail</Text>
          {hasEntries ? (
            <TouchableOpacity onPress={handleLogToday}>
              <Text style={styles.sectionLink}>Add new entry</Text>
            </TouchableOpacity>
          ) : null}
        </View>

        {hasEntries ? (
          latestEntries.map((entry) => <JournalEntryCard key={entry.date} entry={entry} />)
        ) : (
          <View style={styles.emptyState}>
            <Text style={styles.emptyTitle}>No entries yet</Text>
            <Text style={styles.emptySubtitle}>
              Your reflections and prayers will land here after each Habit Conquest session. Log today’s
              check-in to begin your trail.
            </Text>
            <TouchableOpacity style={styles.primaryBtn} onPress={handleLogToday}>
              <Text style={styles.primaryBtnText}>Log first reflection</Text>
            </TouchableOpacity>
          </View>
        )}
      </ScrollView>
    </View>
  );
});

const JournalEntryCard = ({ entry }: { entry: HabitConquestJournalEntry }) => {
  const theme = useTheme();
  const styles = useMemo(() => journalStyles(theme), [theme]);
  const moodCopy = MOOD_COPY[entry.mood];

  return (
    <View style={styles.card}>
      <View style={styles.cardHeader}>
        <View>
          <Text style={styles.dateLabel}>{formatDate(entry.date)}</Text>
          <Text style={styles.metaText}>
            {moodCopy.emoji} {moodCopy.label}
          </Text>
        </View>
        <View style={styles.statusRow}>
          <StatusChip label="Door shut" active={entry.clean} />
          <StatusChip label="Chose good" active={entry.pledged} tone="secondary" />
        </View>
      </View>
      {entry.note ? <Text style={styles.noteText}>{entry.note}</Text> : null}
      {entry.prayerIntent ? (
        <View style={styles.prayerBox}>
          <Text style={styles.prayerLabel}>Prayer carried forward</Text>
          <Text style={styles.prayerText}>{entry.prayerIntent}</Text>
        </View>
      ) : null}
    </View>
  );
};

const StatusChip = ({
  label,
  active,
  tone = 'primary',
}: {
  label: string;
  active: boolean;
  tone?: 'primary' | 'secondary';
}) => {
  const theme = useTheme();
  const styles = useMemo(() => chipStyles(theme, tone, active), [theme, tone, active]);
  return (
    <View style={styles.chip}>
      <Text style={styles.text}>{active ? label : `• ${label}`}</Text>
    </View>
  );
};

const StatBadge = ({ label, value, suffix }: { label: string; value: string; suffix?: string }) => {
  const theme = useTheme();
  return (
    <View style={statStyles(theme).container}>
      <Text style={statStyles(theme).value}>
        {value}
        {suffix ? <Text style={statStyles(theme).suffix}> {suffix}</Text> : null}
      </Text>
      <Text style={statStyles(theme).label}>{label}</Text>
    </View>
  );
};

const InsightCard = ({ label, value, caption }: { label: string; value: string; caption: string }) => {
  const theme = useTheme();
  return (
    <View style={insightStyles(theme).card}>
      <Text style={insightStyles(theme).label}>{label}</Text>
      <Text style={insightStyles(theme).value}>{value}</Text>
      <Text style={insightStyles(theme).caption}>{caption}</Text>
    </View>
  );
};

const createStyles = (theme: ReturnType<typeof useTheme>) => {
  const highlight = theme.colors.warning ?? theme.colors.secondary ?? theme.colors.primary;
  return StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.colors.background,
    },
    content: {
      paddingHorizontal: 20,
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
    screenTitle: {
      ...theme.typography.heading.medium,
      color: theme.colors.text.primary,
    },
    heroCard: {
      borderRadius: theme.borderRadius.xl,
      padding: 20,
      backgroundColor: theme.colors.primary,
    },
    heroHeader: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 16,
    },
    heroEyebrow: {
      color: `${theme.colors.text.inverse}AA`,
      fontSize: 13,
      textTransform: 'uppercase',
      letterSpacing: 0.5,
    },
    heroTitle: {
      color: theme.colors.text.inverse,
      fontSize: 28,
      fontWeight: '800',
    },
    heroStatsRow: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      marginTop: 16,
      gap: 12,
    },
    heroActions: {
      flexDirection: 'row',
      gap: 12,
      marginTop: 20,
      flexWrap: 'wrap',
    },
    primaryBtn: {
      flexGrow: 1,
      borderRadius: theme.borderRadius.full,
      paddingVertical: 14,
      alignItems: 'center',
      justifyContent: 'center',
    },
    primaryBtnText: {
      fontWeight: '700',
      color: theme.colors.text.inverse,
    },
    heroPrimary: {
      backgroundColor: theme.colors.text.inverse,
    },
    heroSecondary: {
      backgroundColor: `${theme.colors.text.inverse}22`,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: `${theme.colors.text.inverse}44`,
    },
    catchUpCard: {
      borderRadius: theme.borderRadius.lg,
      padding: 16,
      backgroundColor: `${highlight}15`,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: `${highlight}40`,
      flexDirection: 'row',
      alignItems: 'center',
      gap: 12,
    },
    catchUpTitle: {
      ...theme.typography.heading.small,
      color: theme.colors.text.primary,
    },
    catchUpSubtitle: {
      color: theme.colors.text.secondary,
      fontSize: 13,
      marginTop: 4,
    },
    catchUpBtn: {
      paddingHorizontal: 14,
      paddingVertical: 10,
      borderRadius: theme.borderRadius.full,
      backgroundColor: theme.colors.primary,
    },
    catchUpBtnText: {
      color: theme.colors.text.inverse,
      fontWeight: '600',
    },
    metricsRow: {
      flexDirection: 'row',
      gap: 16,
      flexWrap: 'wrap',
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
    sectionLink: {
      color: theme.colors.primary,
      fontWeight: '600',
    },
    emptyState: {
      borderRadius: theme.borderRadius.lg,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: theme.colors.border,
      padding: 20,
      gap: 12,
      backgroundColor: theme.colors.surface,
    },
    emptyTitle: {
      ...theme.typography.heading.small,
      color: theme.colors.text.primary,
    },
    emptySubtitle: {
      color: theme.colors.text.secondary,
      lineHeight: 20,
    },
  });
};

const journalStyles = (theme: ReturnType<typeof useTheme>) =>
  StyleSheet.create({
    card: {
      borderRadius: theme.borderRadius.lg,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: theme.colors.border,
      backgroundColor: theme.colors.surface,
      padding: 18,
      gap: 10,
    },
    cardHeader: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      gap: 12,
    },
    dateLabel: {
      fontWeight: '700',
      color: theme.colors.text.primary,
    },
    metaText: {
      color: theme.colors.text.secondary,
      marginTop: 2,
    },
    statusRow: {
      flexDirection: 'row',
      gap: 8,
    },
    noteText: {
      color: theme.colors.text.primary,
      lineHeight: 20,
    },
    prayerBox: {
      borderRadius: theme.borderRadius.md,
      backgroundColor: `${theme.colors.primary}08`,
      padding: 12,
      gap: 4,
    },
    prayerLabel: {
      fontSize: 12,
      color: theme.colors.primary,
      fontWeight: '600',
    },
    prayerText: {
      color: theme.colors.text.primary,
    },
  });

const chipStyles = (
  theme: ReturnType<typeof useTheme>,
  tone: 'primary' | 'secondary',
  active: boolean,
) =>
  StyleSheet.create({
    chip: {
      paddingHorizontal: 12,
      paddingVertical: 6,
      borderRadius: theme.borderRadius.full,
      backgroundColor: active
        ? `${(tone === 'primary' ? theme.colors.primary : theme.colors.secondary)}20`
        : theme.colors.surface,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: active
        ? tone === 'primary'
          ? theme.colors.primary
          : theme.colors.secondary
        : theme.colors.border,
    },
    text: {
      color: active
        ? tone === 'primary'
          ? theme.colors.primary
          : theme.colors.secondary
        : theme.colors.text.secondary,
      fontWeight: '600',
      fontSize: 12,
    },
  });

const statStyles = (theme: ReturnType<typeof useTheme>) =>
  StyleSheet.create({
    container: {
      flex: 1,
    },
    value: {
      color: theme.colors.text.inverse,
      fontSize: 20,
      fontWeight: '800',
    },
    suffix: {
      fontSize: 14,
      fontWeight: '600',
    },
    label: {
      color: `${theme.colors.text.inverse}CC`,
      fontSize: 12,
      marginTop: 2,
    },
  });

const insightStyles = (theme: ReturnType<typeof useTheme>) =>
  StyleSheet.create({
    card: {
      flex: 1,
      minWidth: 150,
      borderRadius: theme.borderRadius.lg,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: theme.colors.border,
      backgroundColor: theme.colors.surface,
      padding: 16,
      gap: 4,
    },
    label: {
      color: theme.colors.text.secondary,
      fontSize: 13,
      textTransform: 'uppercase',
      letterSpacing: 0.5,
    },
    value: {
      ...theme.typography.heading.medium,
      color: theme.colors.text.primary,
    },
    caption: {
      color: theme.colors.text.secondary,
      fontSize: 13,
    },
  });

const DATE_KEY_REGEX = /^\d{4}-\d{2}-\d{2}$/;

const MOOD_COPY: Record<
  HabitConquestMood,
  { label: string; emoji: string }
> = {
  renewed: { label: 'Renewed', emoji: '✨' },
  steady: { label: 'Steady', emoji: '🌿' },
  tired: { label: 'Tired', emoji: '😌' },
  hopeful: { label: 'Hopeful', emoji: '🌅' },
  resilient: { label: 'Resilient', emoji: '🛡️' },
  convicted: { label: 'Convicted', emoji: '🔥' },
};

const computeStreakStats = (
  checkins: Record<string, { clean: boolean; pledged: boolean }>,
) => {
  const validKeys = Object.keys(checkins).filter((key) => DATE_KEY_REGEX.test(key));
  if (!validKeys.length) {
    return { currentStreak: 0, longestStreak: 0, cleanDays: 0 };
  }

  const sortedKeys = validKeys.sort();
  let longest = 0;
  let run = 0;
  let prevKey: string | null = null;
  let cleanDays = 0;

  sortedKeys.forEach((key) => {
    const entry = checkins[key];
    if (entry?.clean) {
      cleanDays += 1;
      if (prevKey && diffDays(prevKey, key) === 1) {
        run += 1;
      } else {
        run = 1;
      }
      prevKey = key;
      longest = Math.max(longest, run);
    } else {
      run = 0;
      prevKey = null;
    }
  });

  let current = 0;
  let cursor = getTodayKey();
  while (true) {
    const entry = checkins[cursor];
    if (entry && entry.clean) {
      current += 1;
      cursor = shiftDateKey(cursor, -1);
    } else {
      break;
    }
  }

  return {
    currentStreak: current,
    longestStreak: longest,
    cleanDays,
  };
};

const getRecordedDayCount = (checkins: Record<string, { clean: boolean; pledged: boolean }>) =>
  Object.keys(checkins).filter((key) => DATE_KEY_REGEX.test(key)).length;

const getTodayKey = () => new Date().toISOString().slice(0, 10);

const shiftDateKey = (key: string, delta: number) => {
  const d = new Date(`${key}T00:00:00Z`);
  if (Number.isNaN(d.getTime())) return key;
  d.setUTCDate(d.getUTCDate() + delta);
  return d.toISOString().slice(0, 10);
};

const diffDays = (a: string, b: string) => {
  const da = new Date(`${a}T00:00:00Z`);
  const db = new Date(`${b}T00:00:00Z`);
  if (Number.isNaN(da.getTime()) || Number.isNaN(db.getTime())) return Infinity;
  return Math.round((db.getTime() - da.getTime()) / 86400000);
};

const formatDate = (dateKey: string) => {
  const d = new Date(dateKey);
  if (Number.isNaN(d.getTime())) return dateKey;
  return d.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' });
};

export default HabitConquestProgressScreen;
