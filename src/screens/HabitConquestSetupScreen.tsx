import React, { useMemo, useState, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import { useTheme } from '@/contexts/ThemeContext';
import { useDailyPathStore } from '@/stores/StoreProvider';
import { ChevronLeft, Plus, Check } from '@/components/Icons';
import { scheduleHabitConquestReminders } from '@/tasks/habitConquestReminderScheduler';

const VICES = [
  'Laziness & neglect',
  'Recklessness & impulsiveness',
  'Ingratitude & entitlement',
  'Fear & cowardice',
  'Vanity & elitism',
  'Addiction to novelty',
  'Legalism & isolation',
  'Manipulation & ego-driven ambition',
];

const SPLITS: Array<{ id: 'once'|'twice'|'thrice'; label: string }> = [
  { id: 'once', label: 'Once per day' },
  { id: 'twice', label: 'Twice per day' },
  { id: 'thrice', label: 'Three times per day' },
];

const PHASE_KEYS = ['affirmation','meditation','mercy','forgiveness','thanksgiving'] as const;

const HabitConquestSetupScreen: React.FC = () => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const dailyPathStore = useDailyPathStore();

  const initial = dailyPathStore.state.habitConquest;
  const [vice, setVice] = useState<string>(initial?.vice ?? VICES[0]);
  const [minutes, setMinutes] = useState<number>(initial?.dailyMinutes ?? 10);
  const [split, setSplit] = useState<'once'|'twice'|'thrice'>(initial?.split ?? 'once');
  const [phases, setPhases] = useState(initial?.phases ?? [
    { id: 'affirmation', label: 'Affirmation', minutes: 2 },
    { id: 'meditation', label: 'Meditation', minutes: 3 },
    { id: 'mercy', label: 'Prayer for Mercy', minutes: 2 },
    { id: 'forgiveness', label: 'Prayer for Forgiveness', minutes: 2 },
    { id: 'thanksgiving', label: 'Prayer for Thanksgiving', minutes: 1 },
  ]);

  const totalPhaseMinutes = useMemo(() => phases.reduce((s,p)=>s+p.minutes,0), [phases]);
  const remainingToAllocate = Math.max(0, minutes - totalPhaseMinutes);

  const adjustPhase = useCallback((id: typeof PHASE_KEYS[number], delta: number) => {
    setPhases(prev => prev.map(p => p.id === id ? { ...p, minutes: Math.max(0, p.minutes + delta) } : p));
  }, []);

  const incMinutes = useCallback(() => setMinutes(m => Math.min(40, m + 1)), []);
  const decMinutes = useCallback(() => setMinutes(m => Math.max(4, m - 1)), []);

  const allocateRemainder = useCallback(() => {
    if (remainingToAllocate <= 0) return;
    const next = [...phases];
    let r = remainingToAllocate;
    let i = 0;
    while (r > 0 && next.length) {
      next[i % next.length].minutes += 1;
      r -= 1;
      i += 1;
    }
    setPhases(next);
  }, [remainingToAllocate, phases]);

  const handleSave = useCallback(async () => {
    dailyPathStore.setHabitConquestVice(vice);
    dailyPathStore.setHabitConquestMinutes(minutes);
    dailyPathStore.setHabitConquestSplit(split);
    const update: any = {};
    for (const p of phases) update[p.id] = p.minutes;
    dailyPathStore.setHabitConquestPhaseMinutes(update);

    try {
      await scheduleHabitConquestReminders(split, vice, minutes, 30);
    } catch (e) {
      console.warn('[HabitConquestSetup] schedule reminders failed', e);
    }

    navigation.navigate('HabitConquestSessionScreen' as any);
  }, [dailyPathStore, vice, minutes, split, phases, navigation]);

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>Conquer Harmful Habits</Text>
        <Text style={styles.subtitle}>Select the vice and your daily time commitment</Text>

        <Text style={styles.sectionLabel}>Choose a vice</Text>
        <View style={styles.chips}>
          {VICES.map(v => (
            <TouchableOpacity key={v} style={[styles.chip, v === vice && styles.chipSelected]} onPress={() => setVice(v)}>
              <Text style={[styles.chipText, v === vice && styles.chipTextSelected]} numberOfLines={1}>{v}</Text>
            </TouchableOpacity>
          ))}
        </View>

        <Text style={styles.sectionLabel}>Daily time</Text>
        <View style={styles.row}>
          <TouchableOpacity onPress={decMinutes} style={styles.circleButton}>
            <ChevronLeft size={18} color={theme.colors.text.secondary} />
          </TouchableOpacity>
          <Text style={styles.minutesText}>{minutes} min</Text>
          <TouchableOpacity onPress={incMinutes} style={styles.circleButton}>
            <Plus size={18} color={theme.colors.text.secondary} />
          </TouchableOpacity>
        </View>
        <Text style={styles.helper}>4–40 minutes per day</Text>

        <Text style={styles.sectionLabel}>Split across the day</Text>
        <View style={styles.chips}>
          {SPLITS.map(s => (
            <TouchableOpacity key={s.id} style={[styles.chip, s.id === split && styles.chipSelected]} onPress={() => setSplit(s.id)}>
              <Text style={[styles.chipText, s.id === split && styles.chipTextSelected]}>{s.label}</Text>
            </TouchableOpacity>
          ))}
        </View>

        <Text style={styles.sectionLabel}>Phase breakdown per session</Text>
        {phases.map(p => (
          <View key={p.id} style={styles.phaseRow}>
            <Text style={styles.phaseLabel}>{p.label}</Text>
            <View style={styles.row}>
              <TouchableOpacity onPress={() => adjustPhase(p.id as any, -1)} style={styles.smallButton}>
                <ChevronLeft size={16} color={theme.colors.text.secondary} />
              </TouchableOpacity>
              <Text style={styles.phaseMinutes}>{p.minutes}m</Text>
              <TouchableOpacity onPress={() => adjustPhase(p.id as any, 1)} style={styles.smallButton}>
                <Plus size={16} color={theme.colors.text.secondary} />
              </TouchableOpacity>
            </View>
          </View>
        ))}
        <View style={styles.remainingRow}>
          <Text style={styles.helper}>Unallocated: {remainingToAllocate}m</Text>
          <TouchableOpacity style={[styles.allocateButton, remainingToAllocate <= 0 && styles.allocateButtonDisabled]} onPress={allocateRemainder} disabled={remainingToAllocate <= 0}>
            <Text style={styles.allocateText}>Distribute</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>

      <View style={styles.footer}>
        <TouchableOpacity style={styles.saveButton} onPress={handleSave}>
          <Check size={18} color={theme.colors.text.inverse} />
          <Text style={styles.saveText}>Save & Begin</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const createStyles = (theme: ReturnType<typeof useTheme>) => StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.background },
  content: { padding: 16, paddingBottom: 120 },
  title: { fontSize: 20, fontWeight: '700', color: theme.colors.text.primary, marginBottom: 4 },
  subtitle: { fontSize: 14, color: theme.colors.text.secondary, marginBottom: 16 },
  sectionLabel: { fontSize: 14, fontWeight: '600', color: theme.colors.text.primary, marginTop: 16, marginBottom: 8 },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 16, backgroundColor: theme.colors.surface },
  chipSelected: { backgroundColor: theme.colors.primary },
  chipText: { color: theme.colors.text.secondary },
  chipTextSelected: { color: theme.colors.text.inverse, fontWeight: '600' },
  row: { flexDirection: 'row', alignItems: 'center' },
  circleButton: { width: 36, height: 36, borderRadius: 18, alignItems: 'center', justifyContent: 'center', backgroundColor: theme.colors.surface },
  minutesText: { marginHorizontal: 12, fontSize: 18, color: theme.colors.text.primary, minWidth: 64, textAlign: 'center' },
  helper: { fontSize: 12, color: theme.colors.text.tertiary, marginTop: 6 },
  phaseRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 8 },
  phaseLabel: { color: theme.colors.text.primary },
  smallButton: { width: 28, height: 28, borderRadius: 14, alignItems: 'center', justifyContent: 'center', backgroundColor: theme.colors.surface },
  phaseMinutes: { width: 38, textAlign: 'center', color: theme.colors.text.primary },
  remainingRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  allocateButton: { marginTop: 8, paddingHorizontal: 12, paddingVertical: 8, borderRadius: 12, backgroundColor: theme.colors.secondary },
  allocateButtonDisabled: { backgroundColor: theme.colors.surface },
  allocateText: { color: theme.colors.text.inverse, fontWeight: '600' },
  footer: { position: 'absolute', bottom: 0, left: 0, right: 0, padding: 16, backgroundColor: theme.colors.background, borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: theme.colors.border },
  saveButton: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8, backgroundColor: theme.colors.primary, paddingVertical: 12, borderRadius: 12 },
  saveText: { color: theme.colors.text.inverse, fontWeight: '700' },
});

export default HabitConquestSetupScreen;
