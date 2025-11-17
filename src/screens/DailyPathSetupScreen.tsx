import React, { useMemo, useState, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { useDailyPathStore } from '@/stores/StoreProvider';
import { useBibleStore } from '@/stores/BibleStore';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import ReadingPlanSetupModal from '@/components/ReadingPlanSetupModal';

type Props = NativeStackScreenProps<RootStackParamList, 'DailyPathSetupScreen'>;

const DailyPathSetupScreen: React.FC<Props> = ({ navigation }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const dailyPathStore = useDailyPathStore();
  const bibleStore = useBibleStore();

  const [selectKnowledge, setSelectKnowledge] = useState<boolean>(true);
  const [selectHabitConquest, setSelectHabitConquest] = useState<boolean>(true);
  const [selectMeditation, setSelectMeditation] = useState<boolean>(false);
  const [selectHabits, setSelectHabits] = useState<boolean>(false);
  const [selectChallenges, setSelectChallenges] = useState<boolean>(false);

  const [showReadingPlanModal, setShowReadingPlanModal] = useState(false);

  const handleSaveFocuses = useCallback(() => {
    const selected: Array<'knowledge'|'habit_conquest'|'meditation'|'habits'|'challenge'> = [];
    if (selectHabitConquest) selected.push('habit_conquest');
    if (selectKnowledge) selected.push('knowledge');
    if (selectMeditation) selected.push('meditation');
    if (selectHabits) selected.push('habits');
    if (selectChallenges) selected.push('challenge');

    const primary: any = 'revive';
    const secondary: any[] = selected;
    dailyPathStore.setFocuses(primary, secondary as any);
    if (selectChallenges !== dailyPathStore.isChallengesEnabled) {
      dailyPathStore.setChallengesEnabled(selectChallenges);
    }
    dailyPathStore.markSetupComplete();
  }, [selectHabitConquest, selectKnowledge, selectMeditation, selectHabits, selectChallenges, dailyPathStore]);

  const handleContinueToJourney = useCallback(() => {
    handleSaveFocuses();
    try { navigation.navigate('MyJourneyScreen'); } catch { navigation.navigate('Home' as any); }
  }, [handleSaveFocuses, navigation]);

  const readingPlan = bibleStore.readingPlan;
  const readingModeLabel = useMemo(() => {
    const id = readingPlan?.readingMode;
    if (id === 'lectio_divina') return 'Lectio Divina';
    if (id === 'reading_meditation') return 'Reading + Meditation';
    return id ? 'Reading' : '';
  }, [readingPlan?.readingMode]);
  const habit = dailyPathStore.state.habitConquest;

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}>
          <Text style={styles.backText}>Back</Text>
        </TouchableOpacity>
        <View style={{ flex: 1 }}>
          <Text style={styles.title}>Daily Path Setup</Text>
          <Text style={styles.subtitle}>Choose your modules and configure where needed</Text>
        </View>
        <TouchableOpacity onPress={handleContinueToJourney} style={styles.primaryBtn}>
          <Text style={styles.primaryText}>Continue</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Modules</Text>

          <View style={styles.rowBetween}>
            <View style={styles.rowCol}>
              <Text style={styles.itemTitle}>Grow in the Word</Text>
              <Text style={styles.itemSub}>Read Scripture daily with a plan</Text>
            </View>
            <TouchableOpacity
              style={[styles.checkBox, selectKnowledge && styles.checkBoxChecked]}
              activeOpacity={0.85}
              onPress={() => setSelectKnowledge(v => !v)}
            />
          </View>
          {selectKnowledge && (
            <View style={styles.configRow}>
              <TouchableOpacity style={styles.configBtn} onPress={() => setShowReadingPlanModal(true)}>
                <Text style={styles.configText}>{readingPlan ? 'Update plan' : 'Configure plan'}</Text>
              </TouchableOpacity>
            </View>
          )}

          <View style={styles.divider} />

          <View style={styles.rowBetween}>
            <View style={styles.rowCol}>
              <Text style={styles.itemTitle}>Conquer harmful habits</Text>
              <Text style={styles.itemSub}>Replace false trades with Kingdom purpose</Text>
            </View>
            <TouchableOpacity
              style={[styles.checkBox, selectHabitConquest && styles.checkBoxChecked]}
              activeOpacity={0.85}
              onPress={() => setSelectHabitConquest(v => !v)}
            />
          </View>
          {selectHabitConquest && (
            <View style={styles.configRow}>
              <TouchableOpacity style={styles.configBtn} onPress={() => navigation.navigate('HabitConquestSetupScreen')}>
                <Text style={styles.configText}>{habit?.vice ? 'Edit setup' : 'Configure setup'}</Text>
              </TouchableOpacity>
            </View>
          )}

          <View style={styles.divider} />

          <View style={styles.rowBetween}>
            <View style={styles.rowCol}>
              <Text style={styles.itemTitle}>Meditation</Text>
              <Text style={styles.itemSub}>Pause and breathe with God</Text>
            </View>
            <TouchableOpacity
              style={[styles.checkBox, selectMeditation && styles.checkBoxChecked]}
              activeOpacity={0.85}
              onPress={() => setSelectMeditation(v => !v)}
            />
          </View>

          <View style={styles.divider} />

          <View style={styles.rowBetween}>
            <View style={styles.rowCol}>
              <Text style={styles.itemTitle}>Habits & Notes</Text>
              <Text style={styles.itemSub}>Capture insights and next steps</Text>
            </View>
            <TouchableOpacity
              style={[styles.checkBox, selectHabits && styles.checkBoxChecked]}
              activeOpacity={0.85}
              onPress={() => setSelectHabits(v => !v)}
            />
          </View>

          <View style={styles.divider} />

          <View style={styles.rowBetween}>
            <View style={styles.rowCol}>
              <Text style={styles.itemTitle}>Challenges</Text>
              <Text style={styles.itemSub}>Advance your citizenship challenge</Text>
            </View>
            <TouchableOpacity
              style={[styles.checkBox, selectChallenges && styles.checkBoxChecked]}
              activeOpacity={0.85}
              onPress={() => setSelectChallenges(v => !v)}
            />
          </View>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Summary</Text>

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Modules enabled</Text>
            <Text style={styles.summaryValue}>
              {['revive']
                .concat(selectHabitConquest ? ['habit conquest'] : [])
                .concat(selectKnowledge ? ['Bible reading'] : [])
                .concat(selectMeditation ? ['meditation'] : [])
                .concat(selectHabits ? ['habits'] : [])
                .concat(selectChallenges ? ['challenges'] : [])
                .join(', ')}
            </Text>
          </View>

          {selectKnowledge && (
            <View style={styles.summaryCard}>
              <Text style={styles.sectionTitle}>Bible Reading</Text>
              {readingPlan ? (
                <>
                  <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Daily time</Text><Text style={styles.summaryValue}>{readingPlan.timePerDay} mins</Text></View>
                  <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Mode</Text><Text style={styles.summaryValue}>{readingModeLabel}</Text></View>
                  <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Books selected</Text><Text style={styles.summaryValue}>{readingPlan.books.length}</Text></View>
                  <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Reminder</Text><Text style={styles.summaryValue}>{readingPlan.reminderTime || 'None'}</Text></View>
                </>
              ) : (
                <Text style={styles.itemSub}>No plan yet. Configure to get a daily reading plan.</Text>
              )}
            </View>
          )}

          {selectHabitConquest && (
            <View style={styles.summaryCard}>
              <Text style={styles.sectionTitle}>Habit Conquest</Text>
              {habit?.vice ? (
                <>
                  <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Focus</Text><Text style={styles.summaryValue}>{habit.vice}</Text></View>
                  <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Door shut</Text><Text style={styles.summaryValue}>{habit.doorOfSin || 'Not set'}</Text></View>
                  <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Pledge good</Text><Text style={styles.summaryValue}>{habit.pledgeGood || 'Not set'}</Text></View>
                  <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Daily minutes</Text><Text style={styles.summaryValue}>{habit.dailyMinutes} mins</Text></View>
                </>
              ) : (
                <Text style={styles.itemSub}>Not configured yet. Set up to begin daily accountability.</Text>
              )}
            </View>
          )}
        </View>

        <TouchableOpacity style={styles.primaryCta} onPress={handleContinueToJourney}>
          <Text style={styles.primaryCtaText}>Continue to Journey</Text>
        </TouchableOpacity>
      </ScrollView>

      <ReadingPlanSetupModal
        visible={showReadingPlanModal}
        onClose={() => setShowReadingPlanModal(false)}
        onCreatePlan={async (opts) => {
          await bibleStore.createReadingPlan({
            books: opts.books,
            timePerDay: opts.timePerDay,
            readingMode: opts.readingMode as any,
            phases: opts.phases as any,
            reminderTime: opts.reminderTime ?? null,
            presetIds: opts.presetIds,
            minChaptersPerDay: opts.minChaptersPerDay,
            maxChaptersPerDay: opts.maxChaptersPerDay,
            readingPaceWpm: opts.readingPaceWpm,
          });
          dailyPathStore.setReadingPlanSetupCompleted(true);
          setShowReadingPlanModal(false);
        }}
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
  primaryBtn: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 12, backgroundColor: theme.colors.surface },
  primaryText: { color: theme.colors.primary, fontWeight: '600' },
  content: { paddingVertical: 8, gap: 12 },
  card: { backgroundColor: theme.colors.surface, borderRadius: 12, padding: 16, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border, gap: 12 },
  cardTitle: { color: theme.colors.text.primary, fontWeight: '700' },
  rowBetween: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  rowCol: { flexDirection: 'column', gap: 4, flex: 1 },
  itemTitle: { color: theme.colors.text.primary, fontWeight: '600' },
  itemSub: { color: theme.colors.text.secondary, fontSize: 12 },
  checkBox: { width: 22, height: 22, borderRadius: 6, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border, backgroundColor: theme.colors.background },
  checkBoxChecked: { backgroundColor: `${(theme as any).colors.primary}55`, borderColor: theme.colors.primary },
  configRow: { flexDirection: 'row', justifyContent: 'flex-end' },
  configBtn: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 8, backgroundColor: theme.colors.background, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border },
  configText: { color: theme.colors.primary, fontWeight: '600' },
  divider: { height: 1, backgroundColor: theme.colors.border },
  summaryCard: { backgroundColor: theme.colors.background, borderRadius: 12, padding: 12, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border, gap: 8 },
  sectionTitle: { color: theme.colors.text.primary, fontWeight: '600' },
  summaryRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  summaryLabel: { color: theme.colors.text.secondary },
  summaryValue: { color: theme.colors.text.primary, fontWeight: '600' },
  primaryCta: { backgroundColor: theme.colors.primary, borderRadius: 12, paddingVertical: 12, alignItems: 'center' },
  primaryCtaText: { color: theme.colors.text.inverse, fontWeight: '700' },
});

export default DailyPathSetupScreen;
