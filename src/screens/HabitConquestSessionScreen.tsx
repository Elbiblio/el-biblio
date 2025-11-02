import React, { useMemo } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import ReadingTimer from '@/components/ReadingTimer';
import { useDailyPathStore } from '@/stores/StoreProvider';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import type { ReadingPlanPhase } from '@/constants/readingPlanModes';

// Minimal session runner for Habit Conquest
// Uses configured per-session phases from DailyPathStore

type Props = NativeStackScreenProps<RootStackParamList, 'HabitConquestSessionScreen'>;

const HabitConquestSessionScreen: React.FC<Props> = ({ navigation }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const dailyPathStore = useDailyPathStore();

  const hc = dailyPathStore.state.habitConquest;
  const phases = hc?.phases ?? [
    { id: 'affirmation', label: 'Affirmation', minutes: 2 },
    { id: 'meditation', label: 'Meditation', minutes: 3 },
    { id: 'mercy', label: 'Prayer for Mercy', minutes: 2 },
    { id: 'forgiveness', label: 'Prayer for Forgiveness', minutes: 2 },
    { id: 'thanksgiving', label: 'Prayer for Thanksgiving', minutes: 1 },
  ];

  const sessionsCount = hc?.split === 'thrice' ? 3 : hc?.split === 'twice' ? 2 : 1;
  const targetPerSession = Math.max(0, Math.round((hc?.dailyMinutes ?? phases.reduce((s,p)=>s+p.minutes,0)) / sessionsCount));

  const scaledPhasesRaw = React.useMemo(() => {
    const baseTotal = phases.reduce((s, p) => s + (p.minutes || 0), 0);
    if (baseTotal <= 0) return phases;
    if (!targetPerSession || targetPerSession === baseTotal) return phases;
    const ratio = targetPerSession / baseTotal;
    // First pass: floor
    const prelim = phases.map(p => ({ ...p, minutes: Math.max(0, Math.floor(p.minutes * ratio)) }));
    let diff = targetPerSession - prelim.reduce((s, p) => s + p.minutes, 0);
    if (diff === 0) return prelim;
    // Distribute remainder across phases in order
    const next = [...prelim];
    let i = 0;
    while (diff > 0 && next.length) {
      next[i % next.length].minutes += 1;
      diff -= 1;
      i += 1;
    }
    return next;
  }, [phases, targetPerSession]);

  const timerPhases: ReadingPlanPhase[] = scaledPhasesRaw.map(p => {
    let id: ReadingPlanPhase['id'];
    switch (p.id) {
      case 'meditation':
        id = 'meditation';
        break;
      case 'mercy':
      case 'forgiveness':
      case 'thanksgiving':
        id = 'prayer';
        break;
      case 'affirmation':
      default:
        id = 'contemplation';
    }
    return { id, label: p.label, minutes: p.minutes } as ReadingPlanPhase;
  });

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}>
          <Text style={styles.backText}>Back</Text>
        </TouchableOpacity>
        <View style={{ flex: 1 }}>
          <Text style={styles.title}>Habit Conquest</Text>
          {hc?.vice ? <Text style={styles.subtitle}>{hc.vice}</Text> : null}
        </View>
      </View>

      <ReadingTimer
        timerId="habit-conquest"
        phases={timerPhases}
        autoStart
        onAllPhasesComplete={() => navigation.goBack()}
      />
    </View>
  );
};

const createStyles = (theme: ReturnType<typeof useTheme>) => StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.background, padding: 16, gap: 12 },
  header: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  backBtn: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 12, backgroundColor: theme.colors.surface },
  backText: { color: theme.colors.text.primary },
  title: { color: theme.colors.text.primary, fontWeight: '700', fontSize: 18 },
  subtitle: { color: theme.colors.text.secondary, fontSize: 12, marginTop: 2 },
});

export default HabitConquestSessionScreen;
