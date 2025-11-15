import React, { useMemo } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '@/contexts/ThemeContext';
import type { Theme } from '@/theme';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import { useDailyPathStore } from '@/stores/StoreProvider';
import { useBibleStore } from '@/stores/BibleStore';
import { CheckCircle, BookOpen, Clock } from '@/components/Icons';

const SetupCompleteScreen = () => {
  const insets = useSafeAreaInsets();
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const dailyPathStore = useDailyPathStore();
  const bibleStore = useBibleStore();

  const primary = dailyPathStore.primaryFocus;
  const secondaries = dailyPathStore.secondaryFocus || [];
  const plan = bibleStore.readingPlan;

  return (
    <View style={[styles.container, { paddingTop: insets.top + theme.spacing.lg }]}> 
      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.headerIconWrap}>
          <CheckCircle size={56} color={theme.colors.success} />
        </View>
        <Text style={styles.title}>You're all set!</Text>
        <Text style={styles.subtitle}>Here’s a quick summary of your daily path.</Text>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Daily Path</Text>
          <View style={styles.row}> 
            <Text style={styles.label}>Primary</Text>
            <Text style={styles.value}>{primary || '—'}</Text>
          </View>
          <View style={styles.row}> 
            <Text style={styles.label}>Secondary</Text>
            <Text style={styles.value}>{secondaries.length ? secondaries.join(', ') : '—'}</Text>
          </View>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Reading Plan</Text>
          {plan ? (
            <>
              <View style={styles.planRow}>
                <BookOpen size={18} color={theme.colors.text.secondary} />
                <Text style={styles.planText}>{plan.books.length} book(s) • {plan.segments.length} segment(s)</Text>
              </View>
              <View style={styles.planRow}>
                <Clock size={18} color={theme.colors.text.secondary} />
                <Text style={styles.planText}>{plan.timePerDay} min/day</Text>
              </View>
            </>
          ) : (
            <Text style={styles.value}>No plan configured</Text>
          )}
        </View>
      </ScrollView>

      <View style={styles.footer}>
        <TouchableOpacity
          style={styles.primaryButton}
          onPress={() => navigation.navigate('MyJourneyScreen')}
          activeOpacity={0.85}
        >
          <Text style={styles.primaryButtonText}>Go to My Journey</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.background },
  content: { paddingHorizontal: theme.spacing.lg, paddingBottom: theme.spacing.xl, gap: theme.spacing.lg },
  headerIconWrap: { alignItems: 'center', justifyContent: 'center', marginBottom: theme.spacing.sm },
  title: { ...theme.typography.heading.medium, color: theme.colors.text.primary, textAlign: 'center', fontWeight: '700' },
  subtitle: { ...theme.typography.body.sans, color: theme.colors.text.secondary, textAlign: 'center' },
  card: { borderWidth: 1, borderColor: theme.colors.border, backgroundColor: theme.colors.surface, borderRadius: theme.borderRadius.xl, padding: theme.spacing.lg, gap: theme.spacing.sm },
  cardTitle: { ...theme.typography.caption.primary, color: theme.colors.text.secondary, textTransform: 'uppercase', letterSpacing: 0.6 },
  row: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  label: { ...theme.typography.body.sans, color: theme.colors.text.secondary },
  value: { ...theme.typography.body.sans, color: theme.colors.text.primary, fontWeight: '600' },
  planRow: { flexDirection: 'row', alignItems: 'center', gap: theme.spacing.xs },
  planText: { ...theme.typography.caption.primary, color: theme.colors.text.secondary },
  footer: { paddingHorizontal: theme.spacing.lg, paddingBottom: theme.spacing.xl, paddingTop: theme.spacing.md, borderTopWidth: 1, borderTopColor: theme.colors.border, backgroundColor: theme.colors.background },
  primaryButton: { backgroundColor: theme.colors.primary, paddingVertical: theme.spacing.md, borderRadius: theme.borderRadius.lg, alignItems: 'center' },
  primaryButtonText: { ...theme.typography.button, color: theme.colors.text.inverse },
});

export default SetupCompleteScreen;
