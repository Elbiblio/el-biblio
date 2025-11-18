import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { RootStackParamList } from '@/types';

const STORAGE_KEY = 'daily_path_state_v1';

export type DailyFocusKey =
  | 'revive'
  | 'meditation'
  | 'knowledge'
  | 'habits'
  | 'habit_conquest'
  | 'challenge';

export interface DailyStep {
  id: string;
  focus: DailyFocusKey;
  title: string;
  summary: string;
  actionLabel: string;
  route: keyof RootStackParamList;
  params?: Partial<RootStackParamList[keyof RootStackParamList]>;
  icon: DailyFocusIconKey;
  accentColor?: string;
}

export interface ReviveReminderSchedule {
  item: string;
  hour: number;
  minute: number;
  notificationId: string;
}

export type DailyFocusIconKey =
  | 'BookOpen'
  | 'NotePencil'
  | 'Shield'
  | 'Flame'
  | 'Heart'
  | 'Trophy';

export const HABIT_CONQUEST_SCOPE_PARAMS: RootStackParamList['BibleScreen'] = {
  mode: 'scoped',
  scopedTitle: 'Conquer harmful habits',
  scopedSubtitle: 'Trade false comforts for Kingdom strength.',
  scopedVerses: [
    {
      text: 'Your body is a temple of the Holy Spirit; honor God with your body.',
      reference: '1 Corinthians 6:19-20',
    },
    {
      text: 'No temptation has overtaken you except what is common to mankind. God is faithful and will provide a way out.',
      reference: '1 Corinthians 10:13',
    },
    {
      text: 'Offer your body as a living sacrifice and be transformed by the renewing of your mind.',
      reference: 'Romans 12:1-2',
    },
    {
      text: 'God\'s seed remains in you, empowering you to break the pattern of sin.',
      reference: '1 John 3:9',
    },
  ],
};

interface DailyPathState {
  isReady: boolean;
  focusOrder: DailyFocusKey[];
  enableChallenges: boolean;
  completedToday: string[];
  lastCompletedDate: string | null;
  hasCompletedSetup: boolean;
  lastPromptedAt: string | null;
  hasCompletedReadingPlanSetup: boolean;
  hasViewedChallengeSelection: boolean;
  hasConfiguredReviveReminders: boolean;
  hasSeenHabitConquestIntro?: boolean;
  communityUnlocked: boolean;
  hasCompletedChallengeOnboarding: boolean;
  reviveReminderItems: string[];
  lastRevivePromptAt: string | null;
  reviveReminderSchedules: ReviveReminderSchedule[];
  habitConquest?: {
    vice: string | null;
    dailyMinutes: number; // 4 - 40
    split: 'once' | 'twice' | 'thrice';
    // minutes distribution across phases inside a session
    phases: Array<{
      id: 'affirmation' | 'meditation' | 'mercy' | 'forgiveness' | 'thanksgiving';
      label: string;
      minutes: number;
    }>;
    pledgeGood?: string | null;
    doorOfSin?: string | null;
    checkins?: Record<string, { clean: boolean; pledged: boolean }>;
    lastCheckinDate?: string | null;
  };
}

const DEFAULT_STATE: DailyPathState = {
  isReady: false,
  focusOrder: ['revive', 'habit_conquest', 'knowledge'],
  enableChallenges: false,
  completedToday: [],
  lastCompletedDate: null,
  hasCompletedSetup: false,
  lastPromptedAt: null,
  hasCompletedReadingPlanSetup: false,
  hasViewedChallengeSelection: false,
  hasConfiguredReviveReminders: false,
  hasSeenHabitConquestIntro: false,
  communityUnlocked: false,
  hasCompletedChallengeOnboarding: false,
  reviveReminderItems: [],
  lastRevivePromptAt: null,
  reviveReminderSchedules: [],
  habitConquest: {
    vice: null,
    dailyMinutes: 10,
    split: 'once',
    phases: [
      { id: 'affirmation', label: 'Affirmation', minutes: 2 },
      { id: 'meditation', label: 'Meditation', minutes: 3 },
      { id: 'mercy', label: 'Prayer for Mercy', minutes: 2 },
      { id: 'forgiveness', label: 'Prayer for Forgiveness', minutes: 2 },
      { id: 'thanksgiving', label: 'Prayer for Thanksgiving', minutes: 1 },
    ],
    pledgeGood: null,
    doorOfSin: null,
    checkins: {},
    lastCheckinDate: null,
  },
};

const LEGACY_FOCUS_MAP: Record<string, DailyFocusKey> = {
  scripture: 'knowledge',
  reflection: 'habits',
  community: 'habits',
  meditation: 'meditation',
  service: 'habits',
  habit_recovery: 'habit_conquest',
};

const normalizeFocusKey = (key?: string | null): DailyFocusKey | null => {
  if (!key) return null;
  if (['revive', 'meditation', 'knowledge', 'habits', 'habit_conquest', 'challenge'].includes(key)) {
    return key as DailyFocusKey;
  }
  return LEGACY_FOCUS_MAP[key] ?? null;
};

export class DailyPathStore {
  state: DailyPathState = { ...DEFAULT_STATE };

  constructor() {
    makeAutoObservable(this, {}, { autoBind: true });
    this.resetDailyCompletionIfNeeded();
    void this.loadFromStorage();
  }

  get isReady() {
    return this.state.isReady;
  }

  get primaryFocus() {
    return this.state.focusOrder[0] ?? 'revive';
  }

  get secondaryFocus() {
    return this.state.focusOrder.slice(1);
  }

  get hasConfiguredReviveReminders() {
    return this.state.hasConfiguredReviveReminders;
  }

  get hasCompletedChallengeOnboarding() {
    return this.state.hasCompletedChallengeOnboarding;
  }

  get reviveReminderItems() {
    return this.state.reviveReminderItems;
  }

  get lastRevivePromptAt() {
    return this.state.lastRevivePromptAt;
  }

  get reviveReminderSchedules() {
    return this.state.reviveReminderSchedules;
  }

  get isChallengesEnabled() {
    return this.state.enableChallenges;
  }

  get completedToday() {
    this.resetDailyCompletionIfNeeded();
    return this.state.completedToday;
  }

  get completedTodayCount() {
    return this.completedToday.length;
  }

  get isSetupComplete() {
    return this.state.hasCompletedSetup;
  }

  get lastPromptedAt() {
    return this.state.lastPromptedAt;
  }

  get todaysSteps(): DailyStep[] {
    this.resetDailyCompletionIfNeeded();
    const sequence = this.getFocusSequence();
    if (!sequence.length) {
      return [];
    }

    const steps: DailyStep[] = [];
    sequence.slice(0, 3).forEach((focus) => {
      const base = this.stepLibrary[focus];
      if (base) {
        if (focus === 'habit_conquest') {
          // Hidden: do not include Habit Conquest in today's steps for now
          return;
        }
        steps.push({ ...base, id: focus });
      }
    });

    return steps;
  }

  get nextStep(): DailyStep | null {
    return this.todaysSteps.find((step) => !this.isStepComplete(step.id)) ?? null;
  }

  get progress(): number {
    const total = this.todaysSteps.length;
    if (!total) return 0;
    return Math.min(1, this.completedTodayCount / total);
  }

  isStepComplete(stepId: string): boolean {
    return this.completedToday.includes(stepId);
  }

  markStepComplete(stepId: string) {
    this.resetDailyCompletionIfNeeded();
    if (this.state.completedToday.includes(stepId)) {
      return;
    }

    runInAction(() => {
      this.state.completedToday = [...this.state.completedToday, stepId];
      this.state.lastCompletedDate = this.getTodayKey();
    });

    void this.saveToStorage();
  }

  clearStepCompletion(stepId: string) {
    this.resetDailyCompletionIfNeeded();
    if (!this.state.completedToday.includes(stepId)) {
      return;
    }

    runInAction(() => {
      this.state.completedToday = this.state.completedToday.filter((id) => id !== stepId);
      this.state.lastCompletedDate = this.getTodayKey();
    });

    void this.saveToStorage();
  }

  setFocuses(primary: DailyFocusKey, secondary: DailyFocusKey[]) {
    runInAction(() => {
      const ordered = [primary, ...secondary].filter((focus, index, arr) => focus && arr.indexOf(focus) === index);
      this.state.focusOrder = ordered.slice(0, 4);
    });
    void this.saveToStorage();
  }

  setChallengesEnabled(enabled: boolean) {
    runInAction(() => {
      this.state.enableChallenges = enabled;
    });
    void this.saveToStorage();
  }

  setReadingPlanSetupCompleted(done: boolean) {
    runInAction(() => {
      this.state.hasCompletedReadingPlanSetup = done;
    });
    void this.saveToStorage();
  }

  setViewedChallengeSelection(done: boolean) {
    runInAction(() => {
      this.state.hasViewedChallengeSelection = done;
    });
    void this.saveToStorage();
  }

  setCommunityUnlocked(unlocked: boolean) {
    runInAction(() => {
      this.state.communityUnlocked = unlocked;
    });
    void this.saveToStorage();
  }

  setReviveRemindersConfigured(done: boolean) {
    runInAction(() => {
      this.state.hasConfiguredReviveReminders = done;
    });
    void this.saveToStorage();
  }

  setChallengeOnboardingCompleted(done: boolean) {
    runInAction(() => {
      this.state.hasCompletedChallengeOnboarding = done;
    });
    void this.saveToStorage();
  }

  setReviveReminderItems(items: string[]) {
    runInAction(() => {
      const unique = items.filter(Boolean).filter((v, i, arr) => arr.indexOf(v) === i).slice(0, 3);
      this.state.reviveReminderItems = unique;
    });
    void this.saveToStorage();
  }

  setReviveReminderSchedules(schedules: ReviveReminderSchedule[]) {
    runInAction(() => {
      this.state.reviveReminderSchedules = schedules;
    });
    void this.saveToStorage();
  }

  recordRevivePrompt(timestamp: string) {
    runInAction(() => {
      this.state.lastRevivePromptAt = timestamp;
    });
    void this.saveToStorage();
  }

  markSetupComplete() {
    runInAction(() => {
      this.state.hasCompletedSetup = true;
    });
    void this.saveToStorage();
  }

  recordSetupPrompt(timestamp: string) {
    runInAction(() => {
      this.state.lastPromptedAt = timestamp;
    });
    void this.saveToStorage();
  }

  resetToday() {
    runInAction(() => {
      this.state.completedToday = [];
      this.state.lastCompletedDate = this.getTodayKey();
    });
    void this.saveToStorage();
  }

  private async loadFromStorage() {
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw) as Partial<DailyPathState> | null;
        if (parsed) {
          runInAction(() => {
            const legacyPrimary = (parsed as any).primaryFocus as string | undefined;
            const legacySecondary = Array.isArray((parsed as any).secondaryFocus)
              ? ((parsed as any).secondaryFocus as string[])
              : [];
            const storedOrder = Array.isArray(parsed.focusOrder) ? parsed.focusOrder : undefined;

            const primaryCandidates: (string | undefined)[] = storedOrder ?? [legacyPrimary, ...legacySecondary];
            const normalizedOrder = primaryCandidates
              .map(focus => normalizeFocusKey(focus) ?? undefined)
              .filter((focus): focus is DailyFocusKey => !!focus);

            this.state.focusOrder = normalizedOrder.length ? normalizedOrder.slice(0, 4) : DEFAULT_STATE.focusOrder;
            if (typeof parsed.enableChallenges === 'boolean') {
              this.state.enableChallenges = parsed.enableChallenges;
            }
            if (Array.isArray(parsed.completedToday)) {
              this.state.completedToday = parsed.completedToday.filter(Boolean);
            }
            if (typeof parsed.lastCompletedDate === 'string') {
              this.state.lastCompletedDate = parsed.lastCompletedDate;
            }
            if (typeof parsed.hasCompletedSetup === 'boolean') {
              this.state.hasCompletedSetup = parsed.hasCompletedSetup;
            }
            if (typeof (parsed as any).hasCompletedReadingPlanSetup === 'boolean') {
              this.state.hasCompletedReadingPlanSetup = (parsed as any).hasCompletedReadingPlanSetup;
            }
            if (typeof (parsed as any).hasViewedChallengeSelection === 'boolean') {
              this.state.hasViewedChallengeSelection = (parsed as any).hasViewedChallengeSelection;
            }
            if (typeof (parsed as any).hasConfiguredReviveReminders === 'boolean') {
              this.state.hasConfiguredReviveReminders = (parsed as any).hasConfiguredReviveReminders;
            }
            if (typeof (parsed as any).communityUnlocked === 'boolean') {
              this.state.communityUnlocked = (parsed as any).communityUnlocked;
            }
            if (typeof (parsed as any).hasCompletedChallengeOnboarding === 'boolean') {
              this.state.hasCompletedChallengeOnboarding = (parsed as any).hasCompletedChallengeOnboarding;
            }
            if (typeof (parsed as any).hasSeenHabitConquestIntro === 'boolean') {
              this.state.hasSeenHabitConquestIntro = (parsed as any).hasSeenHabitConquestIntro;
            }
            if ((parsed as any).habitConquest) {
              this.state.habitConquest = (parsed as any).habitConquest;
            }
            if (Array.isArray((parsed as any).reviveReminderItems)) {
              this.state.reviveReminderItems = ((parsed as any).reviveReminderItems as string[]).filter(Boolean);
            }
            if (typeof (parsed as any).lastRevivePromptAt === 'string') {
              this.state.lastRevivePromptAt = (parsed as any).lastRevivePromptAt;
            }
            if (Array.isArray((parsed as any).reviveReminderSchedules)) {
              this.state.reviveReminderSchedules = ((parsed as any).reviveReminderSchedules as ReviveReminderSchedule[]).map(item => ({
                item: item.item,
                hour: item.hour,
                minute: item.minute,
                notificationId: item.notificationId,
              }));
            }
            if (typeof parsed.lastPromptedAt === 'string') {
              this.state.lastPromptedAt = parsed.lastPromptedAt;
            }
          });
        }
      }
    } catch (error) {
      console.warn('[DailyPathStore] Failed to load state', error);
    } finally {
      runInAction(() => {
        this.resetDailyCompletionIfNeeded();
        this.state.isReady = true;
      });
    }
  }

  private async saveToStorage() {
    const payload: DailyPathState = {
      ...this.state,
      isReady: true,
    };
    try {
      await AsyncStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({
          focusOrder: payload.focusOrder,
          primaryFocus: payload.focusOrder[0] ?? null,
          secondaryFocus: payload.focusOrder.slice(1),
          enableChallenges: payload.enableChallenges,
          completedToday: payload.completedToday,
          lastCompletedDate: payload.lastCompletedDate,
          hasCompletedSetup: payload.hasCompletedSetup,
          lastPromptedAt: payload.lastPromptedAt,
          hasCompletedReadingPlanSetup: payload.hasCompletedReadingPlanSetup,
          hasViewedChallengeSelection: payload.hasViewedChallengeSelection,
          hasConfiguredReviveReminders: payload.hasConfiguredReviveReminders,
          communityUnlocked: payload.communityUnlocked,
          hasCompletedChallengeOnboarding: payload.hasCompletedChallengeOnboarding,
          hasSeenHabitConquestIntro: payload.hasSeenHabitConquestIntro,
          reviveReminderItems: payload.reviveReminderItems,
          lastRevivePromptAt: payload.lastRevivePromptAt,
          reviveReminderSchedules: payload.reviveReminderSchedules,
          habitConquest: payload.habitConquest,
        }),
      );
    } catch (error) {
      console.warn('[DailyPathStore] Failed to save state', error);
    }
  }

  // Habit Conquest config helpers
  setHabitConquestVice(vice: string) {
    runInAction(() => {
      if (!this.state.habitConquest) this.state.habitConquest = { ...DEFAULT_STATE.habitConquest! };
      this.state.habitConquest!.vice = vice;
    });
    void this.saveToStorage();
  }

  setHabitConquestMinutes(minutes: number) {
    const clamped = Math.max(4, Math.min(40, Math.round(minutes)));
    runInAction(() => {
      if (!this.state.habitConquest) this.state.habitConquest = { ...DEFAULT_STATE.habitConquest! };
      this.state.habitConquest!.dailyMinutes = clamped;
    });
    void this.saveToStorage();
  }

  setHabitConquestSplit(split: 'once' | 'twice' | 'thrice') {
    runInAction(() => {
      if (!this.state.habitConquest) this.state.habitConquest = { ...DEFAULT_STATE.habitConquest! };
      this.state.habitConquest!.split = split;
    });
    void this.saveToStorage();
  }

  setHabitConquestPhaseMinutes(update: Partial<Record<'affirmation'|'meditation'|'mercy'|'forgiveness'|'thanksgiving', number>>) {
    runInAction(() => {
      if (!this.state.habitConquest) this.state.habitConquest = { ...DEFAULT_STATE.habitConquest! };
      const phases = this.state.habitConquest!.phases.map(p => ({ ...p }));
      for (const key of Object.keys(update) as Array<keyof typeof update>) {
        const idx = phases.findIndex(p => p.id === key);
        if (idx >= 0) phases[idx].minutes = Math.max(0, Math.round(update[key]!));
      }
      this.state.habitConquest!.phases = phases;
    });
    void this.saveToStorage();
  }

  setHabitConquestPledge(text: string | null) {
    runInAction(() => {
      if (!this.state.habitConquest) this.state.habitConquest = { ...DEFAULT_STATE.habitConquest! } as any;
      this.state.habitConquest!.pledgeGood = text ?? null;
    });
    void this.saveToStorage();
  }

  setHabitConquestDoor(text: string | null) {
    runInAction(() => {
      if (!this.state.habitConquest) this.state.habitConquest = { ...DEFAULT_STATE.habitConquest! } as any;
      this.state.habitConquest!.doorOfSin = text ?? null;
    });
    void this.saveToStorage();
  }

  recordHabitConquestCheckin(dateKey: string | null, payload: { clean: boolean; pledged: boolean }) {
    runInAction(() => {
      if (!this.state.habitConquest) this.state.habitConquest = { ...DEFAULT_STATE.habitConquest! } as any;
      const key = (dateKey || this.getTodayKey());
      const map = { ...(this.state.habitConquest!.checkins || {}) } as Record<string, { clean: boolean; pledged: boolean }>;
      map[key] = { clean: !!payload.clean, pledged: !!payload.pledged };
      this.state.habitConquest!.checkins = map;
      const prev = this.state.habitConquest!.lastCheckinDate;
      if (!prev || key > prev) {
        this.state.habitConquest!.lastCheckinDate = key;
      }
    });
    void this.saveToStorage();
  }

  getMissingHabitConquestDates(): string[] {
    const today = this.getTodayKey();
    const hc = this.state.habitConquest;
    const last = hc?.lastCheckinDate || null;
    if (!last) {
      // If never checked in, prompt for yesterday only (if before today)
      const d = new Date();
      d.setDate(d.getDate() - 1);
      const y = d.toISOString().slice(0,10);
      return y === today ? [] : [y];
    }
    const res: string[] = [];
    const start = new Date(last);
    start.setDate(start.getDate() + 1);
    let cursor = start;
    while (cursor.toISOString().slice(0,10) < today) {
      res.push(cursor.toISOString().slice(0,10));
      cursor.setDate(cursor.getDate() + 1);
    }
    return res;
  }

  private getFocusSequence(): DailyFocusKey[] {
    const sequence = [...this.state.focusOrder];
    const unique = sequence.filter((focus, index) => sequence.indexOf(focus) === index);
    // Hidden: remove Habit Conquest from sequence temporarily
    const filtered = unique.filter(f => f !== 'habit_conquest');
    if (this.state.enableChallenges && !filtered.includes('challenge')) {
      filtered.push('challenge');
    }
    return filtered;
  }

  private stepLibrary: Record<DailyFocusKey, DailyStep> = {
    revive: {
      id: 'revive',
      focus: 'revive',
      title: 'Renew your spirit',
      summary: 'Start with a short meditation to reconnect with God’s presence.',
      actionLabel: 'Start meditation',
      route: 'MeditationScreen',
      icon: 'Flame',
    },
    meditation: {
      id: 'meditation',
      focus: 'meditation',
      title: 'Breathe & listen',
      summary: 'Pause for a calming meditation and let scripture settle in.',
      actionLabel: 'Open meditation',
      route: 'MeditationScreen',
      icon: 'Heart',
    },
    knowledge: {
      id: 'knowledge',
      focus: 'knowledge',
      title: 'Grow in the Word',
      summary: 'Read today’s passage and note the insight that stands out.',
      actionLabel: 'Go to Bible reading',
      route: 'BibleScreen',
      icon: 'BookOpen',
    },
    habits: {
      id: 'habits',
      focus: 'habits',
      title: 'Write about your resolves and prayers',
      summary: 'Capture a note, prayer or gratitude to grow and build consistency.',
      actionLabel: 'Power of the Word',
      route: 'NotesScreen',
      icon: 'NotePencil',
    },
    habit_conquest: {
      id: 'habit_conquest',
      focus: 'habit_conquest',
      title: 'Conquer harmful habits',
      summary: 'Name the false trades stealing your devotion and replace them with Kingdom purpose.',
      actionLabel: 'Set up habit conquest',
      route: 'HabitConquestSetupScreen',
      params: undefined,
      icon: 'Shield',
    },
    challenge: {
      id: 'challenge',
      focus: 'challenge',
      title: 'Advance your citizenship challenge',
      summary: 'Revisit the challenge you committed to and take the next step.',
      actionLabel: 'Review active challenge',
      route: 'DailyChallengeScreen',
      icon: 'Trophy',
    },
  };

  private resetDailyCompletionIfNeeded() {
    const today = this.getTodayKey();
    if (this.state.lastCompletedDate === today) {
      return;
    }

    runInAction(() => {
      this.state.completedToday = [];
      this.state.lastCompletedDate = today;
    });
  }

  private getTodayKey(): string {
    const now = new Date();
    const y = now.getFullYear();
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  setHasSeenHabitConquestIntro(seen: boolean) {
    runInAction(() => {
      this.state.hasSeenHabitConquestIntro = !!seen;
    });
    void this.saveToStorage();
  }
}
