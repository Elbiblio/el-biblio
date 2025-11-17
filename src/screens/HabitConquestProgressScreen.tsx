import React, { useMemo, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { useDailyPathStore } from '@/stores/StoreProvider';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';

type Props = NativeStackScreenProps<RootStackParamList, 'HabitConquestProgressScreen'>;

const HabitConquestProgressScreen: React.FC<Props> = ({ navigation }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const dailyPathStore = useDailyPathStore();

  const getWeekStart = (d: Date) => {
    const date = new Date(d);
    const day = date.getDay();
    const diff = (day === 0 ? -6 : 1) - day; // Monday as start
    date.setDate(date.getDate() + diff);
    date.setHours(0,0,0,0);
    return date;
  };

  const formatDay = (date: Date) => {
    return date.toLocaleDateString(undefined, { weekday: 'long', month: 'short', day: 'numeric' });
  };

  const weekDays = (() => {
    const start = getWeekStart(new Date());
    return Array.from({ length: 7 }).map((_, i) => {
      const d = new Date(start);
      d.setDate(start.getDate() + i);
      return d;
    });
  })();

  const getCheckin = useCallback((dateKey: string) => {
    const map = dailyPathStore.state.habitConquest?.checkins || {};
    const entry = map[dateKey] || { clean: false, pledged: false };
    return entry;
  }, [dailyPathStore.state.habitConquest?.checkins]);

  const toggleClean = useCallback((dateKey: string) => {
    const { clean, pledged } = getCheckin(dateKey);
    dailyPathStore.recordHabitConquestCheckin(dateKey, { clean: !clean, pledged });
  }, [dailyPathStore, getCheckin]);

  const togglePledged = useCallback((dateKey: string) => {
    const { clean, pledged } = getCheckin(dateKey);
    dailyPathStore.recordHabitConquestCheckin(dateKey, { clean, pledged: !pledged });
  }, [dailyPathStore, getCheckin]);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}>
          <Text style={styles.backText}>Back</Text>
        </TouchableOpacity>
        <View style={{ flex: 1 }}>
          <Text style={styles.title}>Habit Conquest Progress</Text>
          {dailyPathStore.state.habitConquest?.vice ? (
            <Text style={styles.subtitle}>{dailyPathStore.state.habitConquest?.vice}</Text>
          ) : null}
        </View>
        <TouchableOpacity onPress={() => navigation.navigate('HabitConquestSetupScreen')} style={styles.editBtn}>
          <Text style={styles.editText}>Edit plan</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        {weekDays.map((d) => {
          const key = d.toISOString().slice(0,10);
          const { clean, pledged } = getCheckin(key);
          return (
            <View key={key} style={styles.dayRow}>
              <View style={{ flex: 1 }}>
                <Text style={styles.dayTitle}>{formatDay(d)}</Text>
                <Text style={styles.dayDate}>{key}</Text>
              </View>
              <View style={styles.metricGroupCol}>
                <TouchableOpacity style={styles.checkRow} onPress={() => toggleClean(key)} activeOpacity={0.85}>
                  <View style={[styles.checkBox, clean && styles.checkBoxChecked]}>
                    {clean ? <Text style={styles.checkTick}>✓</Text> : null}
                  </View>
                  <Text style={styles.checkLabelLarge}>Door shut</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.checkRow} onPress={() => togglePledged(key)} activeOpacity={0.85}>
                  <View style={[styles.checkBox, pledged && styles.checkBoxChecked]}>
                    {pledged ? <Text style={styles.checkTick}>✓</Text> : null}
                  </View>
                  <Text style={styles.checkLabelLarge}>Did something nice today to help myself grow</Text>
                </TouchableOpacity>
              </View>
            </View>
          );
        })}
      </ScrollView>
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
  content: { paddingVertical: 8, gap: 12 },
  dayRow: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 12, borderRadius: 12, backgroundColor: theme.colors.surface, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border },
  dayTitle: { color: theme.colors.text.primary, fontWeight: '600' },
  dayDate: { color: theme.colors.text.tertiary, fontSize: 12, marginTop: 2 },
  metricGroup: { flexDirection: 'row', gap: 8 },
  metricPill: { paddingHorizontal: 10, paddingVertical: 8, borderRadius: 12, backgroundColor: theme.colors.background, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border },
  metricPillActive: { backgroundColor: `${(theme as any).colors.primary}15`, borderColor: theme.colors.primary },
  metricText: { color: theme.colors.text.secondary, fontSize: 12 },
  metricTextActive: { color: theme.colors.primary, fontWeight: '600' },
  metricGroupCol: { flexDirection: 'column', gap: 8 },
  checkRow: { flexDirection: 'row', alignItems: 'center', gap: 12, paddingVertical: 6 },
  checkBox: { width: 24, height: 24, borderRadius: 8, borderWidth: 2, borderColor: theme.colors.border, backgroundColor: theme.colors.surface, alignItems: 'center', justifyContent: 'center' },
  checkBoxChecked: { backgroundColor: `${(theme as any).colors.primary}22`, borderColor: theme.colors.primary },
  checkTick: { color: theme.colors.primary, fontWeight: '800', lineHeight: 18 },
  checkLabelLarge: { color: theme.colors.text.primary, fontSize: 14, fontWeight: '600', flexShrink: 1 },
  editBtn: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 12, backgroundColor: theme.colors.surface },
  editText: { color: theme.colors.primary, fontWeight: '600' },
});

export default HabitConquestProgressScreen;
