import React, { useCallback, useEffect, useState, useMemo, useRef } from 'react';
import {
  View,
  ScrollView,
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  Platform,
  Modal,
  RefreshControl,
  TextInput,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withSequence,
  withTiming,
  interpolate,
  Extrapolation,
  FadeInDown,
  runOnJS,
} from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { BlurView } from 'expo-blur';
import {
  BookOpen,
  BookmarkSimple,
  NotePencil,
  Users,
  Fire,
  MessageSquare,
  Star,
  ChevronRight,
  Trophy,
  Bible,
  Flame,
  Lightning,
  Lock,
  X,
} from './../components/Icons';
import { LinearGradient } from 'expo-linear-gradient';
import { Reflection, RootStackParamList, Verse, User } from '@/types';
import { Challenge } from '@/types/challenges';
import AvatarStack from '@/components/AvatarStack';
import DailyJourneyCard from '@/components/DailyJourneyCard';
import CircleButton from '@/components/CircleButton';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { SCREEN_DIMENSIONS } from '@/constants';
import { isSoulForgeUnlocked, SOUL_FORGE_UNLOCK_POINTS } from '@/utils/gameUnlocks';
import { toast } from 'sonner-native';
import {
  useVerseStore,
  useAuthStore,
  useChallengeStore,
  useReflectionStore,
  useLeaderboardStore,
  useMeditationStore,
  useDailyPathStore,
  useJourneyStore,
} from '@/stores/StoreProvider';
import { ensureReviveRemindersActive, cancelReviveReminders, scheduleReviveReminders, REVIVE_REMINDER_DEFAULT_TIMES } from '@/tasks/reviveReminderScheduler';
import { useGameBadgeStore } from '@/stores/GameBadgeStore';
import { observer } from 'mobx-react-lite';
import AuthModal from '@/components/AuthModal';
import type { Verse as VerseType } from "@/types";
import VersePreviewModal from "@/components/VersePreviewModal";
import type { Verse as ModalVerse } from "@/types";
import type { DailyStep, ReviveReminderSchedule } from '@/stores/DailyPathStore';
import SmartPickCard from '@/components/SmartPickCard';
import { getCapsuleForVice } from '@/modules/habitConquestCapsules';
import { ensureHabitConquestRemindersActive } from '@/tasks/habitConquestReminderScheduler';

import { AppState, AppStateStatus } from 'react-native';
import { useWebSocket } from '@/services/websocket';
import * as Haptics from 'expo-haptics';
import { useCommunityStore } from '@/stores/CommunityStore';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useFocusEffect } from '@react-navigation/native';
import { engagementTracker } from '@/utils/engagementTracker';

const WELCOME_BACK_THRESHOLD = 10 * 60 * 1000; // 10 minutes in milliseconds
const MAX_ACTIVE_TIME = 30 * 60 * 1000; // 30 minutes in milliseconds
const SYNC_INTERVAL = 5 * 60 * 1000; // Sync every 5 minutes
const REVIVE_REMINDER_INTERVAL = 3 * 60 * 60 * 1000; // 3 hours in milliseconds

interface TimeTracking {
  lastActiveTimestamp: number;
  totalActiveTime: number;
  lastSyncedTime: number;
  dayStartTimestamp: number;
}

const CARD_WIDTH = SCREEN_DIMENSIONS.width * 0.9;
const QUICK_MENU_STORAGE_KEY = 'home_quick_menu_usage';
const HOME_WELCOME_KEY = 'home_welcome_note_seen';
const CAREER_SHORTCUT_STORAGE_KEY = 'career_discovery_shortcut_seen_v1';
const WHAT_YOU_MISSED_LAST_PROMPT_KEY = 'what_you_missed_last_prompt_v1';
const getUsageStage = (usage: QuickMenuUsage) => {
  if (usage.unlockedItems.includes('coreTools')) return 2;
  if (usage.meditationCount > 0 && usage.bibleCount > 0) return 1;
  return 0;
};

type QuickMenuUsage = {
  meditationCount: number;
  bibleCount: number;
  unlockedItems: string[];
};

const QuickActionCard = ({ action, index, actionStyles, onPress }: { 
  action: any; 
  index: number, 
  actionStyles: any, 
  onPress: (route: keyof RootStackParamList) => void 
}) => {
  return (
    <TouchableOpacity
      style={actionStyles.actionCard}
      activeOpacity={0.7}
      onPress={() => onPress(action.route)}
    >
      <LinearGradient
        colors={[`${action.color}08`, `${action.color}03`]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={actionStyles.actionGradient}
      />
      <View style={actionStyles.actionContent}>
        <View style={[actionStyles.iconContainer, { backgroundColor: `${action.color}15` }]}>
          <action.icon size={20} color={action.color} />
        </View>
        <Text style={[actionStyles.actionText, { color: action.color }]}>
          {action.title}
        </Text>
      </View>
    </TouchableOpacity>
  );
};

type HomeProps = NativeStackScreenProps<RootStackParamList, 'Home'>;

// const getTimeBasedGreeting = () => {
//   const hour = new Date().getHours();

//   if (hour >= 5 && hour < 12) {
//     return "Good morning";
//   } else if (hour >= 12 && hour < 17) {
//     return "Good day";
//   } else if (hour >= 17 && hour < 22) {
//     return "Good evening";
//   } else {
//     return "Hello"; // Late night/early morning
//   }
// };

// // Engaging subtitles for different contexts
// const GREETING_VARIANTS = [
//   "How's your spiritual journey today?",
//   "Ready to dive into Scripture?",
//   "Let's explore God's word together",
//   "Time for reflection and growth",
//   "Find peace in His presence",
//   "Discover new insights today",
//   "Continue your faith journey",
// ];

// const FIRST_VISIT_VARIANTS = [
//   "What would you like to explore today?",
//   "Begin your journey with purpose",
//   "Let's start this day with grace",
//   "Ready for today's reflection?",
//   "Your daily moment of peace awaits",
// ];

const HomeScreen = observer(({ navigation, route }: HomeProps) => {
  const insets = useSafeAreaInsets();
  const pointsScale = useSharedValue(1);
  // const [activeVerse, setActiveVerse] = useState<string | null>(null);
  const cardScale = useSharedValue(1);
  const scrollY = useSharedValue(0);
  // const [currentVerseIndex, setCurrentVerseIndex] = useState(0);
  const scrollX = useSharedValue(0);
  const [showAuthModal, setShowAuthModal] = useState(false);
  const [selectedVerse, setSelectedVerse] = useState<VerseType | null>(null);
  const [isFirstVisitToday, setIsFirstVisitToday] = useState(false);
  const [showGamesModal, setShowGamesModal] = useState(false);
  const [showReviveModal, setShowReviveModal] = useState(false);
  const [isDisablingRevive, setIsDisablingRevive] = useState(false);
  const [editedItems, setEditedItems] = useState<string[]>([]);
  const [editedSchedules, setEditedSchedules] = useState<ReviveReminderSchedule[]>([]);
  const [editedTimes, setEditedTimes] = useState<string[]>([]);
  const [timeErrors, setTimeErrors] = useState<boolean[]>([]);
  const [isSavingRevive, setIsSavingRevive] = useState(false);
  const [showHomeWelcomeNote, setShowHomeWelcomeNote] = useState(false);
  const [hasSeenHomeWelcome, setHasSeenHomeWelcome] = useState(true);
  // Removed: local points modal state; rely on global interceptor-driven modal
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [quickMenuUsage, setQuickMenuUsage] = useState<QuickMenuUsage>({ meditationCount: 0, bibleCount: 0, unlockedItems: [] });
  const [showSetupPrompt, setShowSetupPrompt] = useState(false);
  const [smartPickDismissed, setSmartPickDismissed] = useState(false);
  const [showChallengeFeedback, setShowChallengeFeedback] = useState(false);
  const [challengeFeedbackText, setChallengeFeedbackText] = useState('');
  const [feedbackTargetId, setFeedbackTargetId] = useState<string | null>(null);
  const [showCareerDiscoveryShortcut, setShowCareerDiscoveryShortcut] = useState(false);

  const meditationComplete = route.params?.meditationComplete || false;
  // const challenge = route.params?.challenge;

  const theme = useTheme()
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  // const actionStyles = React.useMemo(() => createActionStyles(theme), [theme]);
  // const themeText = { color: theme?.colors.primary };

  const [appState, setAppState] = useState(AppState.currentState);
  const appStateRef = useRef(AppState.currentState);
  const syncingRef = useRef(false);
  const timeTrackingRef = useRef<TimeTracking>({
    lastActiveTimestamp: Date.now(),
    totalActiveTime: 0,
    lastSyncedTime: 0,
    dayStartTimestamp: new Date().setHours(0, 0, 0, 0),
  });
  const { user, updateUserTime, authRequired, logout, authPromptIntent, pendingAuthEmail, dismissAuthPrompt } = useAuthStore();
  const { completeChallenge } = useMeditationStore();
  const { isConnected } = useWebSocket();
  const { unreadCount, computeUnreadFromReflections } = useCommunityStore();
  const { shouldShowBadge, updateRank } = useGameBadgeStore();
  const dailyPathStore = useDailyPathStore();
  const journeyStore = useJourneyStore();
  const [timeTracking, setTimeTracking] = useState<TimeTracking>({
    lastActiveTimestamp: Date.now(),
    totalActiveTime: user?.total_active_time || 0,
    lastSyncedTime: user?.total_active_time || 0,
    dayStartTimestamp: new Date().setHours(0, 0, 0, 0),
  });

  const handleDailyJourneyAction = useCallback(
    (step: DailyStep) => {
      navigation.navigate(step.route as any, step.params as any);
    },
    [navigation],
  );

  const handleDailyJourneyToggle = useCallback(
    (step: DailyStep) => {
      if (dailyPathStore.isStepComplete(step.id)) {
        dailyPathStore.clearStepCompletion(step.id);
      } else {
        dailyPathStore.markStepComplete(step.id);
      }
    },
    [dailyPathStore],
  );

  const handleManageReviveReminders = useCallback(() => {
    const currentItems = [...dailyPathStore.reviveReminderItems];
    const currentSchedules = currentItems.map((item, index) => {
      const schedule = dailyPathStore.reviveReminderSchedules[index];
      if (schedule) {
        return { ...schedule };
      }
      return {
        item,
        hour: REVIVE_REMINDER_DEFAULT_TIMES[Math.min(index, REVIVE_REMINDER_DEFAULT_TIMES.length - 1)].hour,
        minute: REVIVE_REMINDER_DEFAULT_TIMES[Math.min(index, REVIVE_REMINDER_DEFAULT_TIMES.length - 1)].minute,
        notificationId: '',
      };
    });
    setEditedItems(currentItems);
    setEditedSchedules(currentSchedules);
    setEditedTimes(currentSchedules.map((schedule) => `${String(schedule.hour).padStart(2, '0')}:${String(schedule.minute).padStart(2, '0')}`));
    setTimeErrors(currentSchedules.map(() => false));
    setShowReviveModal(true);
  }, [dailyPathStore.reviveReminderItems, dailyPathStore.reviveReminderSchedules]);

  const handleCloseReviveModal = useCallback(() => {
    setShowReviveModal(false);
    setEditedItems([]);
    setEditedSchedules([]);
    setEditedTimes([]);
    setTimeErrors([]);
    setIsSavingRevive(false);
  }, []);

  useFocusEffect(
    useCallback(() => {
      const hc = dailyPathStore.state.habitConquest;
      const hasHC = dailyPathStore.primaryFocus === 'habit_conquest' || dailyPathStore.secondaryFocus.includes('habit_conquest');
      if (hasHC && hc?.split) {
        ensureHabitConquestRemindersActive(hc.split as any, hc.vice ?? null, hc.dailyMinutes ?? null, 30)
          .catch((e) => console.warn('[HomeScreen] ensure HC reminders failed', e));
      }
      return () => {};
    }, [dailyPathStore.primaryFocus, dailyPathStore.secondaryFocus, dailyPathStore.state.habitConquest])
  );

  const renderHabitConquestCapsule = () => {
    // Hidden: temporarily disable Habit Conquest card on Home
    return null;
  };

  const renderHabitConquestCheckinBanner = () => {
    // Hidden: temporarily disable Habit Conquest check-in banner
    return null;
  };

  const handleEditItemLabel = useCallback((index: number, text: string) => {
    setEditedItems((prev) => {
      const next = [...prev];
      next[index] = text;
      return next;
    });
    setEditedSchedules((prev) => {
      const next = [...prev];
      const existing = next[index] ?? {
        item: text,
        hour: REVIVE_REMINDER_DEFAULT_TIMES[Math.min(index, REVIVE_REMINDER_DEFAULT_TIMES.length - 1)].hour,
        minute: REVIVE_REMINDER_DEFAULT_TIMES[Math.min(index, REVIVE_REMINDER_DEFAULT_TIMES.length - 1)].minute,
        notificationId: '',
      };
      next[index] = { ...existing, item: text };
      return next;
    });
    setEditedTimes((prev) => {
      const next = [...prev];
      const schedule = editedSchedules[index] ?? {
        hour: REVIVE_REMINDER_DEFAULT_TIMES[Math.min(index, REVIVE_REMINDER_DEFAULT_TIMES.length - 1)].hour,
        minute: REVIVE_REMINDER_DEFAULT_TIMES[Math.min(index, REVIVE_REMINDER_DEFAULT_TIMES.length - 1)].minute,
      };
      next[index] = `${String(schedule.hour).padStart(2, '0')}:${String(schedule.minute).padStart(2, '0')}`;
      return next;
    });
  }, [editedSchedules]);

  const handleEditItemTime = useCallback((index: number, time: string) => {
    setEditedTimes((prev) => {
      const next = [...prev];
      next[index] = time;
      return next;
    });

    const timeMatch = time.match(/^\s*(\d{1,2})[:](\d{2})\s*$/);
    const hour = timeMatch ? Number(timeMatch[1]) : NaN;
    const minute = timeMatch ? Number(timeMatch[2]) : NaN;
    const isValid = !Number.isNaN(hour) && !Number.isNaN(minute) && hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;

    setTimeErrors((prev) => {
      const next = [...prev];
      next[index] = !isValid;
      return next;
    });

    if (!isValid) {
      return;
    }

    setEditedSchedules((prev) => {
      const next = [...prev];
      const existing = next[index] ?? {
        item: editedItems[index] ?? '',
        hour,
        minute,
        notificationId: '',
      };
      next[index] = {
        ...existing,
        hour,
        minute,
      };
      return next;
    });
  }, [editedItems]);

  const handleAddReminder = useCallback(() => {
    if (editedItems.length >= 3) {
      toast.error('You can only keep three revive reminders.');
      return;
    }
    const nextIndex = editedItems.length;
    const fallback = REVIVE_REMINDER_DEFAULT_TIMES[Math.min(nextIndex, REVIVE_REMINDER_DEFAULT_TIMES.length - 1)];
    setEditedItems((prev) => [...prev, '']);
    setEditedSchedules((prev) => [...prev, {
      item: '',
      hour: fallback.hour,
      minute: fallback.minute,
      notificationId: '',
    }]);
    setEditedTimes((prev) => [...prev, `${String(fallback.hour).padStart(2, '0')}:${String(fallback.minute).padStart(2, '0')}`]);
    setTimeErrors((prev) => [...prev, false]);
  }, [editedItems.length]);

  const handleRemoveReminder = useCallback((index: number) => {
    setEditedItems((prev) => prev.filter((_, idx) => idx !== index));
    setEditedSchedules((prev) => prev.filter((_, idx) => idx !== index));
    setEditedTimes((prev) => prev.filter((_, idx) => idx !== index));
    setTimeErrors((prev) => prev.filter((_, idx) => idx !== index));
  }, []);

  const handleSaveReviveReminders = useCallback(async () => {
    if (isSavingRevive) {
      return;
    }
    if (timeErrors.some(Boolean)) {
      toast.error('Fix invalid reminder times.');
      return;
    }

    const entries = editedItems.reduce<Array<{ label: string; schedule: ReviveReminderSchedule | undefined; index: number }>>((acc, item, index) => {
      const label = item.trim();
      if (!label) {
        return acc;
      }
      acc.push({ label, schedule: editedSchedules[index], index });
      return acc;
    }, []);

    if (!entries.length) {
      toast.error('Add at least one reminder.');
      return;
    }

    setIsSavingRevive(true);
    try {
      const enriched = entries.map(({ label, schedule, index }) => {
        const fallback = REVIVE_REMINDER_DEFAULT_TIMES[Math.min(index, REVIVE_REMINDER_DEFAULT_TIMES.length - 1)];
        const hour = schedule?.hour ?? fallback.hour;
        const minute = schedule?.minute ?? fallback.minute;
        return { label, hour, minute };
      });

      const sorted = enriched.sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));

      const labels = sorted.map(({ label }) => label);
      const times = sorted.map(({ hour, minute }) => ({ hour, minute }));

      const schedules = await scheduleReviveReminders(labels, { times });
      dailyPathStore.setReviveReminderItems(labels);
      dailyPathStore.setReviveReminderSchedules(schedules);
      dailyPathStore.setReviveRemindersConfigured(true);
      toast.success('Revive reminders updated');
      handleCloseReviveModal();
    } catch (error) {
      toast.error('Unable to save revive reminders');
      console.warn('[HomeScreen] save revive reminders failed', error);
    } finally {
      setIsSavingRevive(false);
    }
  }, [isSavingRevive, editedItems, editedSchedules, dailyPathStore, handleCloseReviveModal]);

  const handleDisableReviveReminders = useCallback(async () => {
    if (isDisablingRevive) {
      return;
    }
    setIsDisablingRevive(true);
    try {
      await cancelReviveReminders();
      dailyPathStore.setReviveReminderItems([]);
      dailyPathStore.setReviveReminderSchedules([]);
      dailyPathStore.setReviveRemindersConfigured(false);
      toast.success('Revive reminders disabled');
      setShowReviveModal(false);
    } catch (error) {
      toast.error('Could not disable revive reminders');
      console.warn('[HomeScreen] disable revive reminders failed', error);
    } finally {
      setIsDisablingRevive(false);
    }
  }, [isDisablingRevive, dailyPathStore]);

  const renderDailyJourneyCard = () => {
    if (!dailyPathStore.isSetupComplete) {
      return null;
    }

    if (!dailyPathStore.isReady) {
      return null;
    }

    const steps = dailyPathStore.todaysSteps;
    if (!steps.length) {
      return null;
    }

    if (dailyPathStore.progress >= 1) {
      return (
        <View style={styles.miniJourney}>
          <View style={{ flex: 1 }}>
            <Text style={styles.miniJourneyTitle}>Daily path completed</Text>
            <Text style={styles.miniJourneySub}>Well done. See your journey or adjust tomorrow's plan.</Text>
          </View>
          <TouchableOpacity
            style={styles.miniJourneyBtn}
            activeOpacity={0.85}
            onPress={() => navigation.navigate('MyJourneyScreen' as any)}
          >
            <Text style={styles.miniJourneyBtnText}>View</Text>
          </TouchableOpacity>
        </View>
      );
    }

    return (
      <DailyJourneyCard
        steps={steps}
        nextStep={dailyPathStore.nextStep}
        completed={dailyPathStore.completedToday}
        progress={dailyPathStore.progress}
        onActionPress={handleDailyJourneyAction}
        onToggleComplete={handleDailyJourneyToggle}
      />
    );
  };

  const renderReviveReminderBanner = () => {
    if (!dailyPathStore.hasConfiguredReviveReminders || !dailyPathStore.reviveReminderItems.length) {
      return null;
    }

    return (
      <View style={styles.reviveBanner}>
        <View style={styles.reviveBannerContent}>
          <Text style={styles.reviveBannerTitle}>Revive reminders are on</Text>
          <Text style={styles.reviveBannerBody}>
            We will nudge you to keep your revival habits going. Manage or disable reminders anytime.
          </Text>
        </View>
        <View style={styles.reviveBannerButtons}>
          <TouchableOpacity
            style={styles.revivePrimary}
            onPress={handleManageReviveReminders}
            activeOpacity={0.85}
          >
            <Text style={styles.revivePrimaryText}>Manage reminders</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  const handleDismissCareerDiscoveryShortcut = useCallback(async () => {
    try {
      await AsyncStorage.setItem(CAREER_SHORTCUT_STORAGE_KEY, 'seen');
    } catch (error) {
      console.error('Error saving career shortcut state:', error);
    }
    setShowCareerDiscoveryShortcut(false);
  }, []);

  const handleOpenCareerDiscovery = useCallback(async () => {
    try {
      await AsyncStorage.setItem(CAREER_SHORTCUT_STORAGE_KEY, 'seen');
    } catch (error) {
      console.error('Error saving career shortcut state:', error);
    }
    setShowCareerDiscoveryShortcut(false);
    navigation.navigate('CareerDiscoveryScreen');
  }, [navigation]);

  const renderCareerDiscoveryShortcut = () => {
    if (!showCareerDiscoveryShortcut) {
      return null;
    }

    return (
      <View style={styles.careerShortcutCard}>
        <View style={styles.careerShortcutHeader}>
          <View style={styles.careerShortcutIconWrap}>
            <Brain size={20} color={theme?.colors.primary} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={styles.careerShortcutTitle}>Discover your spiritual career</Text>
            <Text style={styles.careerShortcutSubtitle}>
              Take a short guide to see how your gifts and work fit into the Kingdom story.
            </Text>
          </View>
        </View>
        <View style={styles.careerShortcutActions}>
          <TouchableOpacity
            style={styles.careerShortcutPrimary}
            activeOpacity={0.85}
            onPress={handleOpenCareerDiscovery}
          >
            <Text style={styles.careerShortcutPrimaryText}>Start Career Guide</Text>
            <ChevronRight size={16} color={'#fff'} />
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.careerShortcutSecondary}
            activeOpacity={0.75}
            onPress={handleDismissCareerDiscoveryShortcut}
          >
            <Text style={styles.careerShortcutSecondaryText}>Maybe later</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  useEffect(() => {
    if (!dailyPathStore.isReady) {
      return;
    }
    // Setup prompt is now shown only on MyJourneyScreen
    return;
  }, [dailyPathStore, dailyPathStore.isReady, dailyPathStore.isSetupComplete, dailyPathStore.lastPromptedAt]);

  const handleOpenCitizenshipSetup = useCallback(() => {
    setShowSetupPrompt(false);
    navigation.navigate('DailyPathSetupScreen');
  }, [navigation]);

  const handleDismissCitizenshipPrompt = useCallback(() => {
    setShowSetupPrompt(false);
  }, []);

  const renderCitizenshipPrompt = () => {
    if (!showSetupPrompt) {
      return null;
    }

    return (
      <View style={styles.citizenshipCard}>
        <View style={styles.citizenshipTextGroup}>
          <Text style={styles.citizenshipTitle}>Begin your daily citizenship path</Text>
          <Text style={styles.citizenshipBody}>
            Choose the focuses that fit your season so we can guide today’s next step.
          </Text>
        </View>
        <View style={styles.citizenshipActions}>
          <TouchableOpacity
            style={styles.citizenshipPrimary}
            onPress={handleOpenCitizenshipSetup}
            activeOpacity={0.85}
          >
            <Text style={styles.citizenshipPrimaryText}>Set up daily path</Text>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={styles.citizenshipSecondary}
            onPress={handleDismissCitizenshipPrompt}
            activeOpacity={0.75}
          >
            <Text style={styles.citizenshipSecondaryText}>Not now</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  // Add animation values for more lively UI
  const toolsScale = useSharedValue(1);
  const challengeOpacity = useSharedValue(0);
  const verseTranslateY = useSharedValue(20);
  const spotlightTranslateX = useSharedValue(20);
  // Animated styles must be declared at component top-level (not inside render helpers)
  const challengeAnimatedStyle = useAnimatedStyle(() => ({
    opacity: challengeOpacity.value,
  }));
  const verseAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: verseTranslateY.value }],
    opacity: interpolate(verseTranslateY.value, [20, 0], [0, 1]),
  }));
  const spotlightAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: spotlightTranslateX.value }],
    opacity: interpolate(spotlightTranslateX.value, [20, 0], [0, 1]),
  }));
  const toolsAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: toolsScale.value }],
  }));
  const pointsAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: pointsScale.value }],
  }));
  useEffect(() => {
    loadTimeTracking();
    const subscription = AppState.addEventListener('change', (nextAppState) => {
      const prev = appStateRef.current;
      appStateRef.current = nextAppState;
      if (prev === 'active' && nextAppState.match(/inactive|background/)) {
        handleAppInactive();
      } else if (prev.match(/inactive|background/) && nextAppState === 'active') {
        handleAppActive();
      }
      setAppState(nextAppState);
    });

    const syncInterval = setInterval(() => {
      if (appStateRef.current === 'active') {
        handleTimeSync();
      }
    }, SYNC_INTERVAL);

    verseTranslateY.value = withTiming(0, { duration: 600 });
    challengeOpacity.value = withTiming(1, { duration: 600 });

    return () => {
      subscription.remove();
      clearInterval(syncInterval);
    };
  }, []);


  // If an API call returns 401, the global unauthorized handler sets authRequired=true.
  // When that happens, present the AuthModal. If the user logs in successfully, close it.
  useEffect(() => {
    if (authRequired) {
      setShowAuthModal(true);
    }
  }, [authRequired]);

  useEffect(() => {
    if (user) {
      dismissAuthPrompt();
      setShowAuthModal(false);
    }
  }, [user, dismissAuthPrompt]);

  const loadTimeTracking = async () => {
    try {
      // Load time tracking from user store instead of AsyncStorage
      const savedTracking: TimeTracking = {
        lastActiveTimestamp: Date.now(),
        totalActiveTime: user?.total_active_time || 0,
        lastSyncedTime: user?.total_active_time || 0,
        dayStartTimestamp: new Date().setHours(0, 0, 0, 0),
      };
      
      setTimeTracking(savedTracking);
      timeTrackingRef.current = savedTracking;
    } catch (error) {
      console.error('Failed to load time tracking:', error);
    }
  };

  const handleAuthModalClose = useCallback(() => {
    dismissAuthPrompt();
    setShowAuthModal(false);
  }, [dismissAuthPrompt]);

  const handleOpenHomeWelcome = useCallback(() => {
    setShowHomeWelcomeNote(true);
  }, []);

  const handleDismissHomeWelcome = useCallback(async () => {
    setShowHomeWelcomeNote(false);
    setHasSeenHomeWelcome(true);
    toast.success('Welcome, and thank you for choosing to walk in this spirit of oneness.');
    try {
      await AsyncStorage.setItem(HOME_WELCOME_KEY, 'seen');
    } catch (error) {
      console.error('Error saving home welcome state:', error);
    }
  }, []);

  const saveTimeTracking = async (tracking: TimeTracking) => {
    try {
      // Update time tracking through user store instead of AsyncStorage
      // The user store will handle the API call to update total_active_time
      if (user) {
        await updateUserTime(tracking.totalActiveTime);
      }
    } catch (error) {
      console.error('Failed to save time tracking:', error);
    }
  };

  const handleTimeSync = async () => {
    const tt = timeTrackingRef.current;
    if (!user || !tt || tt.totalActiveTime <= tt.lastSyncedTime) {
      return;
    }
    if (syncingRef.current) {
      return;
    }
    syncingRef.current = true;
    try {
      await updateUserTime(tt.totalActiveTime);
      setTimeTracking(prev => {
        const next = { ...prev, lastSyncedTime: prev.totalActiveTime };
        timeTrackingRef.current = next;
        return next;
      });
    } catch (error) {
      console.error('Error syncing time:', error);
    } finally {
      syncingRef.current = false;
    }
  };

  

  const handleAppActive = () => {
    const now = Date.now();
    setTimeTracking(prev => ({
      ...prev,
      lastActiveTimestamp: now
    }));

    if (dailyPathStore.hasConfiguredReviveReminders) {
      void ensureReviveRemindersActive(dailyPathStore.reviveReminderSchedules)
        .then((schedules) => {
          if (schedules.length) {
            dailyPathStore.setReviveReminderSchedules(schedules);
          }
        })
        .catch((error) => {
          console.warn('[HomeScreen] revive reminder ensure failed', error);
        });
    }

    if (
      dailyPathStore.hasConfiguredReviveReminders &&
      dailyPathStore.reviveReminderItems.length
    ) {
      const lastPrompt = dailyPathStore.lastRevivePromptAt ? new Date(dailyPathStore.lastRevivePromptAt).getTime() : 0;
      if (!lastPrompt || now - lastPrompt >= REVIVE_REMINDER_INTERVAL) {
        const reminder = dailyPathStore.reviveReminderItems[0];
        toast.info(`Remember: ${reminder}`);
        dailyPathStore.recordRevivePrompt(new Date(now).toISOString());
      }
    }
  };

  const handleAppInactive = async () => {
    const now = Date.now();
    const prev = timeTrackingRef.current;
    const rawDuration = now - prev.lastActiveTimestamp;
    // Clamp a single session chunk to avoid massively over-counting
    // when the app has been backgrounded for a long time.
    const sessionDuration = Math.max(0, Math.min(rawDuration, MAX_ACTIVE_TIME));

    const newTracking = {
      ...prev,
      totalActiveTime: prev.totalActiveTime + sessionDuration,
      lastActiveTimestamp: now,
    };

    setTimeTracking(newTracking);
    timeTrackingRef.current = newTracking;
    await saveTimeTracking(newTracking);
    await handleTimeSync();
  };


  const verseStore = useVerseStore();
  const { dailyVerses, isDailyVersesLoading } = verseStore.state;
  const { fetchDailyVerses } = verseStore;

  const challengeStore = useChallengeStore();
  const { personalChallenges, communityChallenges } = challengeStore;
  const { fetchPersonalChallenges, fetchCommunityChallenges } = challengeStore;

  const getHttpStatus = useCallback((err: any): number | undefined => err?.status || err?.response?.status, []);
  const handleAuthHttpError = useCallback((err: any) => {
    const status = getHttpStatus(err);
    if (status === 401 && user) {
      setShowAuthModal(true);
    }
  }, [getHttpStatus, setShowAuthModal, user]);

  // Refresh challenges whenever Home gains focus (ensures newly joined show up)
  useFocusEffect(
    React.useCallback(() => {
      const refreshChallenges = async () => {
        try {
          await fetchPersonalChallenges(1);
        } catch (error) {
          handleAuthHttpError(error);
        }
        try {
          await fetchCommunityChallenges(1);
        } catch (error) {
          handleAuthHttpError(error);
        }
      };

      refreshChallenges();

      return () => {};
    }, [fetchPersonalChallenges, fetchCommunityChallenges, handleAuthHttpError])
  );

  const reflectionStore = useReflectionStore();
  const { reflections, isReflectionsLoading } = reflectionStore.state;
  const { fetchReflections } = reflectionStore;

  const leaderboardStore = useLeaderboardStore();
  const { fetchGlobalLeaderboard, fetchUserRank } = leaderboardStore;

  const meditationStore = useMeditationStore();
  const { meditationState, meditationTimer, selectedChallenge } = meditationStore.state;

  const acceptedJesusCompleted = journeyStore.getPhaseStatus('accept-jesus') === 'completed';

  useEffect(() => {
    const load = async () => {
      try { await fetchDailyVerses(); } catch (e) { /* Not auth-critical */ }
      try { await fetchPersonalChallenges(1); } catch (e) { handleAuthHttpError(e); }
      try { await fetchCommunityChallenges(1); } catch (e) { handleAuthHttpError(e); }
      try { await fetchReflections(1, { sortBy: 'likes', sortOrder: 'desc' }); } catch (e) { handleAuthHttpError(e); }
      try { await fetchGlobalLeaderboard(); } catch (e) { /* Not auth-critical */ }
      // Initial rank check for Games badge
      if (user?.id) {
        try {
          const res = await fetchUserRank(user.id, 'all');
          if (res?.rank) updateRank('all', res.rank);
        } catch (e: any) {
          const status = getHttpStatus(e);
          if (status === 404) {
            // User may have been deleted/banned: logout and prompt auth
          }
        }
      }
    };

    load();
  }, [fetchDailyVerses, fetchPersonalChallenges, fetchCommunityChallenges, fetchReflections, fetchGlobalLeaderboard, user?.id, handleAuthHttpError, logout]);

  // Poll user rank periodically to detect changes and toggle Games badge
  useEffect(() => {
    if (!user?.id) return;
    const id = setInterval(() => {
      fetchUserRank(user.id!, 'all').then((res) => {
        if (res?.rank) updateRank('all', res.rank);
      }).catch(() => {});
    }, 2 * 60 * 1000); // every 2 minutes
    return () => clearInterval(id);
  }, [user?.id, fetchUserRank, updateRank]);

  // Recompute community unread badge whenever reflections list updates
  useEffect(() => {
    computeUnreadFromReflections(reflections as unknown as Reflection[]);
  }, [reflections, computeUnreadFromReflections]);

  useEffect(() => {
    checkFirstVisit();
  }, []);

  const checkFirstVisit = async () => {
    try {
      // Check first visit using user store or API
      // For now, we'll use a simple approach
      const today = new Date().toDateString();
      // For now, we'll just check if it's the first visit today
      // This can be enhanced when the API supports last_visit_date
      setIsFirstVisitToday(true);
    } catch (error) {
      console.error('Error checking first visit:', error);
    }
  };

  const shouldShowWelcomeBack = () => {
    if (!user?.last_seen) return false;

    const lastSeen = new Date(user.last_seen).getTime();
    const timeSinceLastActive = Date.now() - lastSeen;
    const hasMinimumBreak = timeSinceLastActive >= WELCOME_BACK_THRESHOLD;
    const withinActiveTimeLimit = timeTracking.totalActiveTime <= MAX_ACTIVE_TIME;

    return hasMinimumBreak && withinActiveTimeLimit;
  };

  useEffect(() => {
    const loadCareerShortcutState = async () => {
      try {
        const seen = await AsyncStorage.getItem(CAREER_SHORTCUT_STORAGE_KEY);
        if (!seen && timeTracking.totalActiveTime <= MAX_ACTIVE_TIME) {
          setShowCareerDiscoveryShortcut(true);
        }
      } catch (error) {
        console.error('Error loading career shortcut state:', error);
      }
    };

    loadCareerShortcutState();
  }, [timeTracking.totalActiveTime]);

  const checkWhatYouMissed = useCallback(async () => {
    try {
      // Prefer engagement-based timestamp over generic last_seen
      const engagedMs = await engagementTracker.getLastEngagedAtMs();

      let baseMs: number | null = engagedMs;
      if (!baseMs && user?.last_seen) {
        const lastSeenMs = new Date(user.last_seen).getTime();
        baseMs = !lastSeenMs || Number.isNaN(lastSeenMs) ? null : lastSeenMs;
      }

      if (!baseMs) return;

      const now = Date.now();
      const diffDays = Math.floor((now - baseMs) / (24 * 60 * 60 * 1000));
      if (diffDays < 2) {
        return;
      }

      const todayKey = new Date().toISOString().slice(0, 10);
      const lastPrompt = await AsyncStorage.getItem(WHAT_YOU_MISSED_LAST_PROMPT_KEY);
      if (lastPrompt === todayKey) {
        return;
      }

      navigation.navigate('WhatYouMissedScreen', { daysAway: diffDays });
      await AsyncStorage.setItem(WHAT_YOU_MISSED_LAST_PROMPT_KEY, todayKey);
    } catch (error) {
      console.warn('[HomeScreen] checkWhatYouMissed failed', error);
    }
  }, [user?.last_seen, navigation]);

  useEffect(() => {
    if (!user?.last_seen) return;
    void checkWhatYouMissed();
  }, [checkWhatYouMissed, user?.last_seen]);

  // Only treat joined & not-completed challenges as "active" on Home
  const activePersonalChallenges = useMemo(
    () => (personalChallenges || []).filter((c: any) => c && c.hasJoined && !c.isCompleted),
    [personalChallenges]
  );

  // const { mainGreeting, subGreeting } = useMemo(() => {
  //   if (!user) {
  //     return {
  //       mainGreeting: "Welcome to Elbiblio",
  //       subGreeting: "Don't be a stranger, join us today"
  //     };
  //   }

  //   let mainGreeting: string;
  //   let subGreeting: string;

  //   if (isFirstVisitToday) {
  //     mainGreeting = getTimeBasedGreeting();
  //     subGreeting = FIRST_VISIT_VARIANTS[Math.floor(Math.random() * FIRST_VISIT_VARIANTS.length)];
  //   } else if (shouldShowWelcomeBack()) {
  //     mainGreeting = "Welcome back";
  //     subGreeting = GREETING_VARIANTS[Math.floor(Math.random() * GREETING_VARIANTS.length)];
  //   } else {
  //     mainGreeting = getTimeBasedGreeting();
  //     subGreeting = GREETING_VARIANTS[Math.floor(Math.random() * GREETING_VARIANTS.length)];
  //   }

  //   return {
  //     mainGreeting: `${mainGreeting}, ${user.first_name}`,
  //     subGreeting
  //   };
  // }, [user, isFirstVisitToday, timeTracking]);

  // const headerAnimatedStyle = useAnimatedStyle(() => ({
  //   transform: [
  //     {
  //       translateY: interpolate(
  //         scrollY.value,
  //         [0, 100],
  //         [0, -50],
  //         Extrapolation.CLAMP
  //       ),
  //     },
  //   ],
  //   opacity: interpolate(
  //     scrollY.value,
  //     [0, 100],
  //     [1, 0],
  //     Extrapolation.CLAMP
  //   ),
  // }));

  // const ScrollIndicators = () => {
  //   return (
  //     <View style={styles.indicatorContainer}>
  //       {dailyVerses?.map((_: any, index: number) => {
  //         const animatedStyle = useAnimatedStyle(() => {
  //           const width = interpolate(
  //             scrollX.value,
  //             [
  //               (index - 1) * (CARD_WIDTH + theme?.spacing.sm),
  //               index * (CARD_WIDTH + theme?.spacing.sm),
  //               (index + 1) * (CARD_WIDTH + theme?.spacing.sm),
  //             ],
  //             [8, 24, 8],
  //             Extrapolation.CLAMP
  //           );

  //           const opacity = interpolate(
  //             scrollX.value,
  //             [
  //               (index - 1) * (CARD_WIDTH + theme?.spacing.sm),
  //               index * (CARD_WIDTH + theme?.spacing.sm),
  //               (index + 1) * (CARD_WIDTH + theme?.spacing.sm),
  //             ],
  //             [0.5, 1, 0.5],
  //             Extrapolation.CLAMP
  //           );

  //           return {
  //             width,
  //             opacity,
  //           };
  //         });

  //         return (
  //           <Animated.View
  //             key={index}
  //             style={[styles.indicator, animatedStyle]}
  //           />
  //         );
  //       })}
  //     </View>
  //   );
  // };

  const handleScroll = (event: { nativeEvent: { contentOffset: { y: number } } }) => {
    scrollY.value = event.nativeEvent.contentOffset.y;
  };

  const handleVersePress = (verse: Verse) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    cardScale.value = withSequence(
      withTiming(0.95, { duration: 100 }),
      withTiming(1, { duration: 100 })
    );
    navigation.navigate("VerseDetail", { verse });
  };

  // const handleVerseScroll = useCallback((event: { nativeEvent: { contentOffset: { x: number } } }) => {
  //   scrollX.value = event.nativeEvent.contentOffset.x;
  //   const newIndex = Math.round(event.nativeEvent.contentOffset.x / (CARD_WIDTH + theme?.spacing.sm));
  //   setCurrentVerseIndex(newIndex);
  // }, []);

  const persistQuickMenuUsage = async (nextUsage: QuickMenuUsage) => {
    try {
      await AsyncStorage.setItem(QUICK_MENU_STORAGE_KEY, JSON.stringify(nextUsage));
    } catch (error) {
      console.error('Failed to persist quick menu usage:', error);
    }
  };

  const loadQuickMenuUsage = useCallback(async () => {
    try {
      const stored = await AsyncStorage.getItem(QUICK_MENU_STORAGE_KEY);
      if (stored) {
        setQuickMenuUsage(JSON.parse(stored));
      }
    } catch (error) {
      console.error('Failed to load quick menu usage:', error);
    }
  }, []);

  useEffect(() => {
    loadQuickMenuUsage();
  }, [loadQuickMenuUsage]);

  useEffect(() => {
    const loadHomeWelcomeState = async () => {
      try {
        const stored = await AsyncStorage.getItem(HOME_WELCOME_KEY);
        const seen = stored === 'seen';
        setHasSeenHomeWelcome(seen);
        if (!seen) {
          setShowHomeWelcomeNote(true);
        }
      } catch (error) {
        console.error('Error loading home welcome state:', error);
        setHasSeenHomeWelcome(false);
        setShowHomeWelcomeNote(true);
      }
    };

    void loadHomeWelcomeState();
  }, []);

  const handleQuickActionPress = (route: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    if (!user && route !== 'BibleScreen') {
      if (route === 'CommunityScreen') {
        toast.info('Create a free account to access Community features.');
      }
      setShowAuthModal(true);
      return;
    }
    navigation.navigate(route as any);
    setQuickMenuUsage(prev => {
      const next: QuickMenuUsage = { ...prev };
      if (route === 'MeditationScreen') {
        next.meditationCount += 1;
      }
      if (route === 'BibleScreen') {
        next.bibleCount += 1;
      }
      const shouldUnlockExtraBar = next.meditationCount >= 2 && next.bibleCount >= 2;
      if (shouldUnlockExtraBar && !next.unlockedItems.includes('coreTools')) {
        next.unlockedItems = [...next.unlockedItems, 'coreTools'];
      }
      persistQuickMenuUsage(next);
      return next;
    });
  };

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await Promise.all([
        fetchDailyVerses(),
        fetchPersonalChallenges(1),
        fetchCommunityChallenges(1),
        fetchReflections(1, { sortBy: 'likes', sortOrder: 'desc' }),
        fetchGlobalLeaderboard(),
      ]);
    } catch (error) {
      console.error('Error refreshing data:', error);
    } finally {
      setIsRefreshing(false);
    }
  };

  // Badge: show when there's an unfinished meditation or the selected personal challenge is incomplete
  const hasUnfinishedMeditation = useMemo(() => {
    const sessionInProgress = meditationState === 'countdown' || meditationState === 'active';
    const startedButNotCompleted = meditationTimer > 0 && meditationState !== 'complete';
    const selectedIncomplete = selectedChallenge
      ? (activePersonalChallenges || []).some((c: any) => c.id === (selectedChallenge as any).id)
      : false;
    return sessionInProgress || startedButNotCompleted || selectedIncomplete;
  }, [meditationState, meditationTimer, selectedChallenge, activePersonalChallenges]);

  // Community unread badge value
  const communityUnreadBadge = useMemo(() => {
    if (!unreadCount || unreadCount <= 0) return null;
    return unreadCount > 99 ? '99+' : unreadCount;
  }, [unreadCount]);

  const renderHeader = () => (
    <View style={styles.header}>
      <View style={styles.headerContent}>
        <View style={styles.headerLeft}>
          <TouchableOpacity onPress={() => navigation.navigate('MyJourneyScreen')} activeOpacity={0.7}>
            <Text style={styles.appTitle}>ELBIBLIO</Text>
          </TouchableOpacity>
          {isConnected && (
            <View style={styles.connectionIndicator}>
              <View style={[styles.connectionDot, { backgroundColor: theme?.colors.success }]} />
              <Text style={styles.connectionText}>Live</Text>
            </View>
          )}
        </View>
        {user ? (
          <TouchableOpacity
            style={styles.pointsContainer}
            onPress={() => {
              navigation.navigate('MyJourneyScreen');
              pointsScale.value = withSequence(
                withSpring(1.1),
                withSpring(1)
              );
            }}
          >
            <Animated.View style={[styles.points, pointsAnimatedStyle]}> 
              <LinearGradient
                colors={[theme?.colors.primary, theme?.colors.primaryLight]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.pointsGradient}
              >
                <Star size={16} color="#FFF" />
                <Text style={styles.pointsText}>{user.points || 0} </Text>
              </LinearGradient>
            </Animated.View>
          </TouchableOpacity>
        ) : (
          <TouchableOpacity
            style={styles.joinButton}
            onPress={() => setShowAuthModal(true)}
          >
            <Text style={styles.joinButtonText}>Join Now</Text>
          </TouchableOpacity>
        )}
      </View>
      <TouchableOpacity
        style={styles.welcomePrompt}
        onPress={handleOpenHomeWelcome}
        activeOpacity={0.85}
      >
        <Text style={styles.welcomePromptText}>🤝 Read Welcome Note</Text>
        {!hasSeenHomeWelcome && (
          <View style={styles.welcomePromptBadge}>
            <Text style={styles.welcomePromptBadgeText}>NEW</Text>
          </View>
        )}
      </TouchableOpacity>
    </View>
  );

  // Quick Tools Grid Section with animations
  const renderQuickTools = () => {
    const toolAnimatedStyle = toolsAnimatedStyle;

    const baseTools = [
      { icon: Trophy, label: 'Games', route: 'GameScreen', badge: shouldShowBadge ? 1 : null, color: theme?.colors.success, requiresUnlock: false, stage: 0 },
      { icon: Bible, label: 'Bible', route: 'BibleScreen', badge: null, color: theme?.colors.secondary, requiresUnlock: false, stage: 0 },
      { icon: Users, label: 'Community', route: 'CommunityScreen', badge: communityUnreadBadge, color: theme?.colors.success, requiresUnlock: false, stage: 0 },
      { icon: BookOpen, label: 'Meditation', route: 'MeditationScreen', badge: hasUnfinishedMeditation ? 1 : null, color: theme?.colors.primary, requiresUnlock: false, stage: 0 },
      { icon: BookmarkSimple, label: 'Bookmarks', route: 'SavedItemsScreen', badge: null, color: theme?.colors.like, requiresUnlock: false, stage: 1 },
      { icon: Fire, label: 'SoulForge', route: 'VirtueScreen', badge: null, color: theme?.colors.primaryDark, requiresUnlock: true, stage: 2 },
    ];

    const tools = acceptedJesusCompleted
      ? [
          baseTools[0],
          baseTools[1],
          {
            icon: Lightning,
            label: 'Guides',
            route: 'TalkToGodScreen',
            badge: null,
            color: theme?.colors.primary,
            requiresUnlock: false,
            stage: 0,
          },
          ...baseTools.slice(2),
        ]
      : baseTools;

    return (
      <Animated.View style={[styles.section, toolAnimatedStyle]}>
        <Text style={styles.sectionTitle}>QUICK MENU</Text>
        <View style={styles.toolsGrid}>
          {tools.map((tool) => {
            const totalPoints = leaderboardStore.userStats?.totalPoints ?? 0;
            const isUnlocked = tool.requiresUnlock ? isSoulForgeUnlocked(totalPoints) : true;
            const usageStage = quickMenuUsage.unlockedItems.includes('coreTools') ? 2 : (quickMenuUsage.meditationCount > 0 && quickMenuUsage.bibleCount > 0 ? 1 : 0);
            const isStageUnlocked = tool.stage <= usageStage;
            if (!isStageUnlocked) {
              return null;
            }
            
            return (
            <TouchableOpacity
              key={tool.label}
              style={[styles.toolButton, !isUnlocked && { opacity: 0.6 }]}
              onPress={() => {
                if (!isUnlocked) {
                  const totalPoints = leaderboardStore.userStats?.totalPoints ?? user?.points ?? 0;
                  const remaining = Math.max(0, SOUL_FORGE_UNLOCK_POINTS - totalPoints);
                  toast.info(`Earn ${remaining} more points to unlock SoulForge.`);
                  Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
                  return;
                }
                // Add press animation
                toolsScale.value = withSequence(
                  withTiming(0.97, { duration: 100 }),
                  withTiming(1, { duration: 100 })
                );
                handleQuickActionPress(tool.route);
              }}
              disabled={!isUnlocked}
            >
              <LinearGradient
                colors={[`${tool.color}15`, `${tool.color}05`]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.toolGradient}
              />
              <View style={[styles.toolIconContainer, { backgroundColor: isUnlocked ? `${tool.color}15` : '#00000010' }]}>
                {isUnlocked ? (
                  <tool.icon size={24} color={tool.color} strokeWidth={2} />
                ) : (
                  <Lock size={24} color={theme?.colors.text.secondary} />
                )}
                {tool.badge && isUnlocked && (
                  <View style={styles.badgeContainer}>
                    <Text style={styles.badgeText}>{tool.badge}</Text>
                  </View>
                )}
              </View>
              <Text style={[styles.toolLabel, !isUnlocked && { opacity: 0.5 }]}>
                {tool.label}
                {!isUnlocked && ' 🔒'}
              </Text>
            </TouchableOpacity>
          );
          })}
        </View>
        {getUsageStage(quickMenuUsage) === 0 && (
          <Text style={styles.toolTip}>
            Tip: Start with meditation and Bible to unlock more tools
          </Text>
        )}
      </Animated.View>
    );
  };
  // Calculate challenge progress based on time
  const calculateChallengeProgress = (challenge: Challenge): number => {
    if (!challenge.createdAt || !challenge.expiresAt) return 0;
    
    const now = new Date().getTime();
    const startTime = new Date(challenge.createdAt).getTime();
    const endTime = new Date(challenge.expiresAt).getTime();
    
    // If challenge is completed or time has passed
    if (now >= endTime) return 100;
    
    // If challenge hasn't started yet
    if (now < startTime) return 0;
    
    // Calculate progress percentage
    const totalDuration = endTime - startTime;
    const elapsed = now - startTime;
    return Math.min(Math.round((elapsed / totalDuration) * 100), 100);
  };
  
  // Handle challenge completion
  const handleCompleteChallenge = async (challengeId: string) => {
    try {
      await completeChallenge(challengeId);
      // Points are awarded by backend and surfaced via global PointsEarnedModal; no local updates
    } catch (error) {
      console.error('Failed to complete challenge:', error);
    }
  };
  
  // Render Daily Challenges Section with real API data
  const challengesUnlockedByPoints = useMemo(() => {
    if (!user) return false;
    const totalPoints = leaderboardStore.userStats?.totalPoints ?? user.points ?? 0;
    return totalPoints >= SOUL_FORGE_UNLOCK_POINTS;
  }, [leaderboardStore.userStats?.totalPoints, user]);

  const shouldShowChallenges = useMemo(() => {
    if (!dailyPathStore.isSetupComplete) return false;
    return dailyPathStore.isChallengesEnabled || challengesUnlockedByPoints;
  }, [dailyPathStore.isSetupComplete, dailyPathStore.isChallengesEnabled, challengesUnlockedByPoints]);

  const hasShownChallengeUnlock = useRef(false);
  useEffect(() => {
    if (!dailyPathStore.isSetupComplete) return;
    if (!dailyPathStore.isChallengesEnabled && challengesUnlockedByPoints && !hasShownChallengeUnlock.current) {
      hasShownChallengeUnlock.current = true;
      toast.info('Daily challenges unlocked! Join one to stay consistent.');
    }
    if (dailyPathStore.isChallengesEnabled) {
      hasShownChallengeUnlock.current = false;
    }
  }, [dailyPathStore.isSetupComplete, dailyPathStore.isChallengesEnabled, challengesUnlockedByPoints]);

  const joinedChallengeIds = useMemo(
    () => new Set((activePersonalChallenges || []).map((challenge: any) => challenge.id)),
    [activePersonalChallenges]
  );
  // Use only active (joined & not-completed) challenges for Home logic
  const smartPickChallenge = useMemo(() => {
    if (smartPickDismissed) return null;
    if (challengeStore.isLoading) return null;
    const excludeIds = Array.from(joinedChallengeIds);
    return challengeStore.getRecommendedChallenge({ excludeIds, allowJoined: false });
  }, [challengeStore, joinedChallengeIds, smartPickDismissed]);
  const handleSmartPickJoin = useCallback((challenge: Challenge) => {
    void (async () => {
      const success = await challengeStore.joinChallenge(challenge.id);
      if (success) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        setSmartPickDismissed(true);
        navigation.navigate('DailyChallengeScreen');
      }
    })();
  }, [challengeStore, navigation]);

  const renderDailyChallenges = () => {
    if (!shouldShowChallenges) {
      return null;
    }
    const challengeStyle = challengeAnimatedStyle;

    // Show loading state
    if (challengeStore.isLoading) {
      return (
        <Animated.View style={[styles.section, challengeStyle]}>
          <View style={styles.sectionHeaderWithAction}>
            <Text style={styles.sectionTitle}>DAILY CHALLENGES</Text>
            <TouchableOpacity 
              style={styles.viewAllButton}
              onPress={() => navigation.navigate('DailyChallengeScreen')}
            >
              <Text style={styles.viewAllText}>View All</Text>
              <ChevronRight size={16} color={theme?.colors.primary} />
            </TouchableOpacity>
          </View>
          <View style={styles.loadingContainer}>
            <Text style={styles.loadingText}>Loading challenges...</Text>
          </View>
        </Animated.View>
      );
    }
    
    // Use real API data from challenge store only
    const personalChallenge = activePersonalChallenges && activePersonalChallenges.length > 0
      ? activePersonalChallenges[0]
      : undefined;
    const communityChallenge = (communityChallenges || []).find(challenge => {
      if (joinedChallengeIds.has(challenge.id)) return false;
      if (challenge.hasJoined) return false;
      return true;
    });
    

    // Calculate progress for personal challenge
    const personalProgress = personalChallenge ? calculateChallengeProgress(personalChallenge as any) : 0;
    const isPersonalChallengeComplete = personalChallenge ? personalProgress >= 100 : false;
    const hasCompletedFrequencyGoal = !!(personalChallenge?.isCompleted && (personalChallenge?.frequency === 'd' || personalChallenge?.frequency === 'w'));
    const personalCompletionLabel = personalChallenge?.frequency === 'd'
      ? 'Completed Today'
      : personalChallenge?.frequency === 'w'
        ? 'Completed This Week'
        : 'Completed';
    const completionBadgeStyles = {
      container: {
        marginTop: theme?.spacing.sm,
        alignSelf: 'flex-start' as const,
        backgroundColor: `${theme?.colors.success}15`,
        borderRadius: theme?.borderRadius.full,
        paddingHorizontal: theme?.spacing.sm,
        paddingVertical: theme?.spacing.xs,
      },
      text: {
        ...theme?.typography.caption.primary,
        color: theme?.colors.success,
        fontWeight: '600' as const,
        fontSize: 12,
      },
    };

    return (
      <Animated.View style={[styles.section, challengeAnimatedStyle]}>
        <View style={styles.sectionHeaderWithAction}>
          <Text style={styles.sectionTitle}>DAILY CHALLENGES</Text>
          <TouchableOpacity 
            style={styles.viewAllButton}
            onPress={() => navigation.navigate('DailyChallengeScreen')}
          >
            <Text style={styles.viewAllText}>View All</Text>
            <ChevronRight size={16} color={theme?.colors.primary} />
          </TouchableOpacity>
        </View>

        {!smartPickDismissed && smartPickChallenge && (
          <View style={styles.smartPickWrapper}>
            <SmartPickCard
              challenge={smartPickChallenge}
              onPressJoin={handleSmartPickJoin}
              onPressDismiss={() => setSmartPickDismissed(true)}
              ctaLabel={smartPickChallenge.hasJoined ? 'View challenge' : 'Join challenge'}
            />
          </View>
        )}

        {/* Joined Challenge (Personal) */}
        {personalChallenge ? (
          <View style={styles.challengeCard}>
            <View style={styles.challengeHeader}>
              <Text style={styles.challengeType}>Joined:</Text>
            </View>
            <Text style={styles.challengeText}>
              <Text style={styles.challengeIcon}>🌱</Text> {personalChallenge.title}
            </Text>
            <View style={styles.progressContainer}>
              <View style={styles.progressBar}>
                <View style={[styles.progressFill, { width: `${personalProgress}%` }]} />
              </View>
              <Text style={styles.progressText}>{personalProgress}%</Text>
            </View>
            {hasCompletedFrequencyGoal && (
              <View style={completionBadgeStyles.container}>
                <Text style={completionBadgeStyles.text}>{personalCompletionLabel}</Text>
              </View>
            )}
            <TouchableOpacity 
              style={[styles.completeButton, 
                isPersonalChallengeComplete ? styles.completeButtonActive : {}]}
              onPress={() => {
                if (personalChallenge.id && isPersonalChallengeComplete) {
                  setFeedbackTargetId(personalChallenge.id);
                  setChallengeFeedbackText('');
                  setShowChallengeFeedback(true);
                } else {
                  challengeOpacity.value = withSequence(
                    withTiming(0.7, { duration: 100 }),
                    withTiming(1, { duration: 100 })
                  );
                }
              }}
            >
              <Text style={styles.completeButtonText}>
                {isPersonalChallengeComplete ? 'Complete Now' : '⏳ In Progress'}
              </Text>
            </TouchableOpacity>
          </View>
        ) : (
          <View style={styles.challengeCard}>
            <View style={styles.challengeHeader}>
              <Text style={styles.challengeType}>Joined:</Text>
            </View>
            <Text style={styles.challengeText}>
              You have not joined any challenges yet.
            </Text>
            <TouchableOpacity 
              style={styles.joinChallengeButton}
              onPress={() => navigation.navigate('DailyChallengeScreen')}
            >
              <Text style={styles.joinChallengeText}>✨ Explore Challenges</Text>
            </TouchableOpacity>
          </View>
        )}
        
        {/* Community Challenge */}
        {communityChallenge ? (
          <View style={styles.challengeCard}>
            <View style={styles.challengeHeader}>
              <Text style={styles.challengeType}>Community:</Text>
            </View>
            <Text style={styles.challengeText}>
              <Text style={styles.challengeIcon}>🤝</Text> {communityChallenge.title}
            </Text>
            {(communityChallenge.participantAvatars && communityChallenge.participantAvatars.length > 0) && (
              <View style={styles.communityStats}>
                <View style={styles.avatarContainer}>
                  <AvatarStack
                    users={communityChallenge.participantAvatars as unknown as User[]}
                    maxAvatars={3}
                    size={24}
                  />
                </View>
                <Text style={styles.participantsText}>
                  {communityChallenge.participants || 0} people joined
                </Text>
              </View>
            )}
            <TouchableOpacity 
              style={styles.joinChallengeButton}
              onPress={() => {
                challengeOpacity.value = withSequence(
                  withTiming(0.7, { duration: 100 }),
                  withTiming(1, { duration: 100 })
                );
                navigation.navigate('DailyChallengeScreen');
              }}
            >
              <Text style={styles.joinChallengeText}>✨ View Challenges</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <View style={styles.challengeCard}>
            <View style={styles.challengeHeader}>
              <Text style={styles.challengeType}>Community:</Text>
            </View>
            <Text style={styles.challengeText}>
              No community challenges available right now.
            </Text>
            <TouchableOpacity 
              style={styles.joinChallengeButton}
              onPress={() => navigation.navigate('DailyChallengeScreen')}
            >
              <Text style={styles.joinChallengeText}>✨ Explore Challenges</Text>
            </TouchableOpacity>
          </View>
        )}
      </Animated.View>
    );
  };

  // Verse of the Day Section with animations
  const renderVerseOfTheDay = () => {
    const verseStyle = verseAnimatedStyle;

    if (!dailyVerses || dailyVerses.length === 0) {
      return (
        <Animated.View style={[styles.section, verseStyle]}>
          <Text style={styles.sectionTitle}>VERSE OF THE DAY</Text>
          <View style={styles.verseCard}>
            <Text style={styles.loadingText}>No verse of the day yet. Please check back later.</Text>
            <TouchableOpacity
              style={[styles.joinChallengeButton, { marginTop: theme?.spacing.md }]}
              onPress={() => navigation.navigate('DailyVersesScreen')}
            >
              <Text style={styles.joinChallengeText}>📖 Browse Previous Verses</Text>
            </TouchableOpacity>
          </View>
        </Animated.View>
      );
    }

    const verse = dailyVerses[0];
    return (
      <Animated.View style={[styles.section, verseAnimatedStyle]}>
        <Text style={styles.sectionTitle}>VERSE OF THE DAY</Text>
        <TouchableOpacity
          style={styles.verseCard}
          onPress={() => {
            verseTranslateY.value = withSequence(
              withTiming(5, { duration: 100 }),
              withTiming(0, { duration: 100 })
            );
            setSelectedVerse(verse);
          }}
        >
          <LinearGradient
            colors={[`${theme?.colors.primary}10`, `${theme?.colors.primary}02`]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.cardGradient}
          />
          <Text style={styles.verseReference}>{verse.reference_display || verse.reference}</Text>
          {verse.context_reference && (
            <Text style={styles.verseContextReference}>
              {verse.context_reference}
            </Text>
          )}
          <Text style={styles.verseText} numberOfLines={3}>
            {verse.text}
          </Text>
          <View style={styles.verseStats}>
            <View style={styles.statItem}>
              <MessageSquare size={16} color={theme?.colors.primary} />
              <Text style={styles.statText}>
                {verse.reflections?.length || 0} Reflections
              </Text>
            </View>
            <View style={styles.statItem}>
              <BookmarkSimple size={16} color={theme?.colors.secondary} />
              <Text style={styles.statText}>
                {(() => {
                  try {
                    const key = `App\\Models\\Verse_${verse.id}`;
                    return verseStore.state.bookmarks.has(key) ? 'Saved' : 'Save';
                  } catch {
                    return 'Save';
                  }
                })()}
              </Text>
            </View>
          </View>
          <View style={styles.interactionsContainer}>
            <View style={styles.reflectionMeta}>
              {verse.reflections && verse.reflections.length > 0 && (
                <>
                  <AvatarStack
                    users={verse.reflections.map((reflection: Reflection) => reflection.user)}
                    maxAvatars={3}
                    size={24}
                  />
                  <Text style={styles.reflectionCount}>
                    {verse.reflections.length > 3
                      ? `+${verse.reflections.length - 3} others sharing`
                      : `${verse.reflections.length} sharing`}
                  </Text>
                </>
              )}
            </View>
          </View>
        </TouchableOpacity>
      </Animated.View>
    );
  };

  // Learning Spotlight Section with animations
  const renderLearningSpotlight = () => {
    const spotlightStyle = spotlightAnimatedStyle;

    // Use real content if available: take top reflection as spotlight
    const spotlight = (reflections && (reflections as any[]).length > 0) ? (reflections as any[])[0] : null;
    if (!spotlight) return null;

    return (
      <Animated.View style={[styles.section, spotlightStyle]}>
        <Text style={styles.sectionTitle}>LEARNING SPOTLIGHT</Text>
        <TouchableOpacity 
          style={styles.spotlightCard}
          onPress={() => {
            spotlightTranslateX.value = withSequence(
              withTiming(5, { duration: 100 }),
              withTiming(0, { duration: 100 })
            );
            navigation.navigate('ReflectionDetail', { reflection: spotlight });
          }}
        >
          <View style={styles.spotlightIconContainer}>
            <BookOpen size={20} color={theme?.colors.primary} />
          </View>
          <View style={styles.spotlightContent}>
            <Text style={styles.spotlightLabel}>Featured Reflection</Text>
            <Text style={styles.spotlightTitle} numberOfLines={1}>{spotlight?.content || 'Reflection'}</Text>
          </View>
          <ChevronRight size={16} color={theme?.colors.text.secondary} />
        </TouchableOpacity>
      </Animated.View>
    );
  };

  // Render Games Modal
  const renderGamesModal = () => (
    <Modal
      visible={showGamesModal}
      transparent
      animationType="fade"
      onRequestClose={() => setShowGamesModal(false)}
    >
      <TouchableOpacity
        style={styles.modalOverlay}
        activeOpacity={0.9}
        onPress={() => setShowGamesModal(false)}
      >
        <BlurView intensity={80} style={StyleSheet.absoluteFill} tint={theme?.colors.isDark ? 'dark' : 'light'} />
        <Animated.View
          style={styles.gamesModalContainer}
          entering={FadeInDown.duration(300)}
        >
          <View style={styles.gamesModalHeader}>
            <Text style={styles.gamesModalTitle}>Select a Game</Text>
            <TouchableOpacity onPress={() => setShowGamesModal(false)}>
              <Text style={styles.closeButton}>✕</Text>
            </TouchableOpacity>
          </View>
          
          <TouchableOpacity 
            style={styles.gameOption}
            onPress={() => {
              setShowGamesModal(false);
              navigation.navigate('VerseBuilderScreen');
            }}
          >
            <View style={[styles.gameIconContainer, { backgroundColor: `${theme?.colors.primary}15` }]}>
              <BookOpen size={24} color={theme?.colors.primary} />
            </View>
            <View style={styles.gameOptionContent}>
              <Text style={styles.gameOptionTitle}>Verse Builder</Text>
              <Text style={styles.gameOptionDesc}>Piece together verses from memory</Text>
            </View>
            <ChevronRight size={18} color={theme?.colors.text.secondary} />
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={styles.gameOption}
            onPress={() => {
              setShowGamesModal(false);
              navigation.navigate('VirtueTriviaScreen');
            }}
          >
            <View style={[styles.gameIconContainer, { backgroundColor: `${theme?.colors.secondary}15` }]}>
              <Flame size={24} color={theme?.colors.secondary} />
            </View>
            <View style={styles.gameOptionContent}>
              <Text style={styles.gameOptionTitle}>Virtue Trivia</Text>
              <Text style={styles.gameOptionDesc}>Test your biblical knowledge</Text>
            </View>
            <ChevronRight size={18} color={theme?.colors.text.secondary} />
          </TouchableOpacity>
        </Animated.View>
      </TouchableOpacity>
    </Modal>
  );

  // Removed local points modal logic; global modal listens to API interceptor.



  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <ScrollView
        onScroll={handleScroll}
        scrollEventThrottle={16}
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={handleRefresh}
            colors={[theme?.colors.primary]}
            tintColor={theme?.colors.primary}
          />
        }
      >
        {renderHeader()}
        {renderCitizenshipPrompt()}
        {renderHabitConquestCheckinBanner()}
        {renderDailyJourneyCard()}
        {renderHabitConquestCapsule()}
        {renderReviveReminderBanner()}
        {renderCareerDiscoveryShortcut()}
        {renderQuickTools()}
        {/* {renderTalkToGodSection()} */}
        {renderDailyChallenges()}
        {renderVerseOfTheDay()}
        {renderLearningSpotlight()}
      </ScrollView>

      <VersePreviewModal 
        verse={selectedVerse} 
        onClose={() => setSelectedVerse(null)}
        context="home"
        onVersePress={(verse: ModalVerse) => {
          // Build learnContext similar to VersePreviewModal scoped params
          const primaryText = verse.text?.trim();
          const baseReference = verse.reference?.replace(/:\d+.*$/, '') ?? null;
          const primaryReference = (verse as any).reference_display || verse.reference || undefined;
          const scopedVerses: { text: string; reference?: string | null; isPrimary?: boolean }[] = [];
          const addVerse = (entry: { text: string; reference?: string | null; isPrimary?: boolean }) => {
            const key = `${entry.reference ?? ''}|${entry.text}`;
            if (scopedVerses.some(existing => `${existing.reference ?? ''}|${existing.text}` === key)) return;
            scopedVerses.push(entry);
          };
          const mainVerseNumber = typeof (verse as any).verse === 'number' ? (verse as any).verse : null;
          const contextLines = (verse.context_text ?? '')
            .split(/\n+/)
            .map(line => line.trim())
            .filter(Boolean);
          contextLines.forEach(line => {
            const match = line.match(/^(\d+)[\s.:\-]*\s*(.*)$/);
            const candidateNumber = match ? Number(match[1]) : null;
            const text = (match ? match[2] : line).trim();
            if (!text) return;
            const isPrimary = candidateNumber != null && mainVerseNumber != null
              ? candidateNumber === mainVerseNumber
              : (!!primaryText && text === primaryText);
            const reference = candidateNumber != null
              ? (baseReference ? `${baseReference}:${candidateNumber}` : `${(verse as any).book ?? ''} ${(verse as any).chapter ?? ''}:${candidateNumber}`.trim())
              : (verse as any).context_reference ?? primaryReference;
            addVerse({ text, reference, isPrimary });
          });
          if (!scopedVerses.some(item => item.isPrimary) && primaryText) {
            addVerse({ text: primaryText, reference: primaryReference, isPrimary: true });
          }
          const learnContext = {
            scopedTitle: (verse as any).context_reference ?? primaryReference ?? null,
            scopedSubtitle: (verse as any).translation ?? null,
            scopedVerses: scopedVerses.length ? scopedVerses : null,
          } as const;
          navigation.navigate('VerseDetail', { verse, learnContext });
          setSelectedVerse(null);
        }}
      />

      {renderGamesModal()}
      
      {/* Points Earned Modal */}
      {/* PointsEarnedModal is now shown globally in App.tsx via pointsTracker */}

      <AuthModal
        visible={showAuthModal}
        onClose={handleAuthModalClose}
        intent={authPromptIntent}
        pendingEmail={pendingAuthEmail ?? undefined}
      />

      <Modal
        visible={showHomeWelcomeNote}
        transparent
        animationType="fade"
        onRequestClose={handleDismissHomeWelcome}
      >
        <View style={styles.homeWelcomeOverlay}>
          <View style={styles.homeWelcomeCard}>
            <ScrollView
              contentContainerStyle={styles.homeWelcomeScrollContent}
              showsVerticalScrollIndicator={false}
              style={{ maxHeight: 520 }}
            >
              <Text style={styles.homeWelcomeTitle}>Welcome to Elbiblio</Text>
              <Text style={styles.homeWelcomeBody}>
                "That they may all be one, just as you, Father, are in me, and I in you, that they also may be in us, so that the world may believe that you have sent me." (John 17:21). This was Jesus' final prayer before His sacrifice. It was not a suggestion, but the core of His mission for His Church.
              </Text>

              <Text style={styles.homeWelcomeBody}>This community exists to answer that prayer. We provide a place of solace and rejuvenation from the troubles of the world, a hospital for the broken, and a family for all who truly desire to be God's children. Our foundation is the word of God, and our bond is the wholesome love and grace of God.</Text>

              <Text style={styles.homeWelcomeBody}>To achieve this, we commit to the following truths:</Text>

              <Text style={styles.homeWelcomeItem}>
                <Text style={styles.homeWelcomeItemNumber}>1.&nbsp;</Text>
                <Text style={{fontWeight: 'bold'}}>Our Unity is in Christ, Not in Uniformity.</Text> Jesus foresaw many branches (John 15:5) but prayed for one vine. The apostles dealt with disputes (Acts 15:1-29) but maintained fellowship. We are a non-denominational family that embraces all who confess Jesus as the sovereign Lord (Romans 10:9), recognizing that our unity is a testament to the world of God's love (John 13:35). Divisive agendas and "casting stones" at other believers have no place here, for they directly oppose the heart of Christ.
              </Text>

              <Text style={styles.homeWelcomeItem}>
                <Text style={styles.homeWelcomeItemNumber}>2.&nbsp;</Text>
                <Text style={{fontWeight: 'bold'}}>The Supreme Doctrine is God's Nature: Love and Grace.</Text> "God is love" (1 John 4:8). The ultimate evidence of knowing Him is not perfect doctrine, but a life transformed by His love (1 John 4:20-21). Jesus declared that the entire Law and Prophets hang on two commandments: to love God and to love our neighbor (Matthew 22:37-40). Any teaching that does not produce in us the fruits of the Spirit—"love, joy, peace, patience, kindness, goodness, faithfulness, gentleness, self-control" (Galatians 5:22-23)—has missed the point of the Gospel.
              </Text>

              <Text style={styles.homeWelcomeItem}>
                <Text style={styles.homeWelcomeItemNumber}>3.&nbsp;</Text>
                <Text style={{fontWeight: 'bold'}}>We Judge by Christ's Standard: Fruit, Not Faction.</Text> Jesus was explicit: "You will recognize them by their fruits" (Matthew 7:16-20). His depiction of the final judgment in Matthew 25:31-46 focuses entirely on acts of mercy—feeding the hungry, clothing the naked, visiting the prisoner—not on liturgical precision. Therefore, we extend grace on matters where sincere Christians have historically disagreed, such as:
                {"\n\n"}• <Text style={{fontStyle: 'italic'}}>Intercessory Prayer:</Text> We affirm Christ as the one mediator between God and man (1 Timothy 2:5). We also recognize that asking a fellow believer for prayer is biblical (James 5:16) and that some Christians extend this practice to include those who have died in Christ, believing they are alive in Him (Luke 20:38) and part of the same spiritual family. We view this as a matter of personal faith and conscience, not a cause for division.
                {"\n\n"}• <Text style={{fontStyle: 'italic'}}>Scripture:</Text> We include the Apocrypha for edification and historical context, as did Jerome and Luther. We trust the Holy Spirit to guide all believers into truth, and our focus is not to judge how people worship but to ensure our worship bears the fruits expected of true Christians.
                {"\n\n"}However, we draw a clear line against any teaching that denies the divinity of Jesus (1 John 4:2-3), distorts God's design for humanity (1 Corinthians 6:9-11), or promotes sexual immorality, greed, or slander (1 Corinthians 5:11). Such doctrines are not a matter of perspective but of truth, and they will not be tolerated.
              </Text>

              <Text style={styles.homeWelcomeItem}>
                <Text style={styles.homeWelcomeItemNumber}>4.&nbsp;</Text>
                <Text style={{fontWeight: 'bold'}}>We Focus on the Weightier Matters of the Law.</Text> Jesus condemned the Pharisees for neglecting "the weightier matters of the law: justice and mercy and faithfulness" (Matthew 23:23). We humbly acknowledge that the Church has often done the same, majoring in minors and minoring in majors and as such often have something to learn from one another. Our call is to pursue the character of Christ as outlined in the Beatitudes (Matthew 5:1-12)—to be poor in spirit, meek, pure in heart, and peacemakers. This is the identity we are called to above all else as Christians, especially as it becomes increasingly difficult to be true citizens of God's Kingdom in today's world.
              </Text>

              <Text style={styles.homeWelcomeItem}>
                <Text style={styles.homeWelcomeItemNumber}>5.&nbsp;</Text>
                <Text style={{fontWeight: 'bold'}}>Our Mission is Your Restoration and Growth.</Text> By joining, you pledge to walk in this spirit of grace and truth. You affirm that you are a follower of Christ, or are sincerely seeking Him. Elbiblio is a tool for your spiritual maturity (Ephesians 4:13-15), a place for rest and renewal in the spirit of truth and the love of God. We commit to nurturing one another, speaking the truth in love, and together building a community that pleases Jesus our Savior.
              </Text>
            </ScrollView>
            <View style={styles.homeWelcomeButtonContainer}>
              <TouchableOpacity style={styles.homeWelcomeButton} onPress={handleDismissHomeWelcome} activeOpacity={0.85}>
                <Text style={styles.homeWelcomeButtonText}>I agree</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* Challenge Feedback Modal */}
      <Modal
        visible={showChallengeFeedback}
        transparent
        animationType="fade"
        onRequestClose={() => setShowChallengeFeedback(false)}
      >
        <View style={styles.reviveModalOverlay}>
          <TouchableOpacity style={StyleSheet.absoluteFill} activeOpacity={1} onPress={() => setShowChallengeFeedback(false)} />
          <View style={styles.reviveModalCard}>
            <Text style={styles.reviveModalTitle}>Share a quick feedback?</Text>
            <Text style={styles.reviveBannerBody}>A short note helps others stick with it.</Text>
            <TextInput
              style={styles.reviveFeedbackInput}
              placeholder="What helped you complete this today?"
              placeholderTextColor={theme?.colors.text.tertiary}
              value={challengeFeedbackText}
              onChangeText={setChallengeFeedbackText}
              multiline
            />
            <View style={styles.reviveModalActions}>
              <TouchableOpacity
                style={styles.reviveModalClose}
                onPress={() => setShowChallengeFeedback(false)}
                activeOpacity={0.85}
              >
                <Text style={styles.reviveModalCloseText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.reviveModalDisable}
                onPress={async () => {
                  if (feedbackTargetId) {
                    await handleCompleteChallenge(feedbackTargetId);
                  }
                  setShowChallengeFeedback(false);
                }}
                activeOpacity={0.85}
              >
                <Text style={styles.reviveModalDisableText}>Skip</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.reviveModalSave}
                onPress={async () => {
                  if (feedbackTargetId) {
                    const text = challengeFeedbackText.trim();
                    if (text) {
                      try { await challengeStore.submitCompletionFeedback(feedbackTargetId, text); } catch {}
                    }
                    await handleCompleteChallenge(feedbackTargetId);
                  }
                  setShowChallengeFeedback(false);
                }}
                activeOpacity={0.85}
              >
                <Text style={styles.reviveModalSaveText}>Share & Done</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      <Modal
        visible={showReviveModal}
        transparent
        animationType="fade"
        onRequestClose={handleCloseReviveModal}
      >
        <View style={styles.reviveModalOverlay}>
          <TouchableOpacity style={StyleSheet.absoluteFill} activeOpacity={1} onPress={handleCloseReviveModal} />
          <View style={styles.reviveModalCard}>
            <Text style={styles.reviveModalTitle}>Revive reminders</Text>
            <View style={styles.reviveModalList}>
              {editedItems.map((item, index) => (
                <View key={`revive-edit-${index}`} style={styles.reviveModalItem}>
                  <View style={styles.reviveInputColumns}>
                    <TextInput
                      style={styles.reviveModalItemInput}
                      value={item}
                      placeholder="Enter reminder"
                      onChangeText={(text) => handleEditItemLabel(index, text)}
                    />
                    <View style={{ minWidth: 100 }}>
                      <TextInput
                        style={[
                          styles.reviveModalTimeInput,
                          timeErrors[index] ? styles.reviveModalTimeInputError : null,
                        ]}
                        value={editedTimes[index] ?? ''}
                        placeholder="HH:MM"
                        keyboardType="numeric"
                        onChangeText={(text) => handleEditItemTime(index, text)}
                      />
                      {timeErrors[index] ? (
                        <Text style={styles.reviveModalErrorText}>Enter 24h time (e.g. 08:30)</Text>
                      ) : null}
                    </View>
                  </View>
                  <TouchableOpacity
                    style={styles.reviveModalRemove}
                    onPress={() => handleRemoveReminder(index)}
                    activeOpacity={0.7}
                  >
                    <Text style={styles.reviveModalRemoveText}>Remove</Text>
                  </TouchableOpacity>
                </View>
              ))}
            </View>
            <TouchableOpacity style={styles.reviveModalAdd} onPress={handleAddReminder} activeOpacity={0.85}>
              <Text style={styles.reviveModalAddText}>Add another reminder</Text>
            </TouchableOpacity>
            <View style={styles.reviveModalActions}>
              <TouchableOpacity
                style={[styles.reviveModalSave, isSavingRevive ? styles.reviveModalSaveDisabled : null]}
                onPress={handleSaveReviveReminders}
                activeOpacity={0.85}
                disabled={isSavingRevive}
              >
                <Text style={styles.reviveModalSaveText}>{isSavingRevive ? 'Saving…' : 'Save changes'}</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.reviveModalDisable, isDisablingRevive ? styles.reviveModalDisableDisabled : null]}
                onPress={handleDisableReviveReminders}
                activeOpacity={0.85}
                disabled={isDisablingRevive}
              >
                <Text style={styles.reviveModalDisableText}>{isDisablingRevive ? 'Disabling…' : 'Disable reminders'}</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.reviveModalClose}
                onPress={handleCloseReviveModal}
                activeOpacity={0.85}
              >
                <Text style={styles.reviveModalCloseText}>Close</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
});

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme?.colors.background,
  },
  header: {
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme?.colors.border,
  },
  welcomePrompt: {
    marginTop: theme?.spacing.sm,
    alignSelf: 'flex-start',
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.xs,
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.xs,
    borderRadius: theme?.borderRadius.full,
    backgroundColor: `${theme?.colors.primary}12`,
    borderWidth: 1,
    borderColor: `${theme?.colors.primary}25`,
  },
  welcomePromptText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.primary,
    fontWeight: '600',
  },
  welcomePromptBadge: {
    backgroundColor: theme?.colors.success,
    borderRadius: theme?.borderRadius.full,
    paddingHorizontal: theme?.spacing.xs,
    paddingVertical: 2,
  },
  welcomePromptBadgeText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.inverse,
    fontSize: 10,
    fontWeight: '700',
  },
  headerContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.sm,
  },
  connectionIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.xs,
  },
  connectionDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  connectionText: {
    ...theme?.typography.caption.secondary,
    fontSize: 10,
    fontWeight: '600',
  },
  loadingContainer: {
    alignItems: 'center',
    paddingVertical: theme?.spacing.xl,
  },
  appTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.primary,
    fontWeight: '700',
  },
  pointsContainer: {
    overflow: 'hidden',
    borderRadius: theme?.borderRadius.full,
  },
  points: {
    borderRadius: theme?.borderRadius.full,
    ...Platform.select({
      ios: {
        shadowColor: theme?.colors.primary,
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.2,
        shadowRadius: 4,
      },
      android: {
        elevation: 4,
      },
    }),
  },
  pointsGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    gap: theme?.spacing.xs,
  },
  pointsText: {
    ...theme?.typography.caption.primary,
    color: '#FFF',
    fontWeight: '600',
  },
  joinButton: {
    backgroundColor: theme?.colors.primary,
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
  },
  joinButtonText: {
    ...theme?.typography.caption.primary,
    color: '#FFF',
    fontWeight: '600',
  },
  hcCard: {
    marginHorizontal: theme?.spacing.md,
    marginBottom: theme?.spacing.lg,
    padding: theme?.spacing.lg,
    borderRadius: theme?.borderRadius.xl,
    backgroundColor: theme?.colors.surface,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    gap: theme?.spacing.sm,
  },
  hcHeader: {
    gap: theme?.spacing.xs,
  },
  hcTitle: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    fontWeight: '700',
  },
  hcSubtitle: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  hcBody: {
    gap: theme?.spacing.xs,
  },
  hcItem: {
    gap: 2,
  },
  hcItemKind: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.info,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  hcItemText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.primary,
    lineHeight: 18,
  },
  hcActions: {
    marginTop: theme?.spacing.sm,
  },
  hcPrimary: {
    backgroundColor: theme?.colors.primary,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.lg,
    alignItems: 'center',
  },
  hcPrimaryText: {
    ...theme?.typography.button,
    color: theme?.colors.text.inverse,
  },
  citizenshipCard: {
    flexDirection: 'column',
    gap: theme?.spacing.md,
    marginHorizontal: theme?.spacing.md,
    marginBottom: theme?.spacing.lg,
    padding: theme?.spacing.lg,
    borderRadius: theme?.borderRadius.xl,
    backgroundColor: `${theme?.colors.primary}12`,
    borderWidth: 1,
    borderColor: `${theme?.colors.primary}35`,
  },
  citizenshipTextGroup: {
    gap: theme?.spacing.xs,
  },
  citizenshipTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
  },
  citizenshipBody: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    lineHeight: 18,
  },
  citizenshipActions: {
    flexDirection: 'row',
    gap: theme?.spacing.sm,
  },
  citizenshipPrimary: {
    flex: 1,
    backgroundColor: theme?.colors.primary,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  citizenshipPrimaryText: {
    ...theme?.typography.button,
    color: theme?.colors.text.inverse,
  },
  citizenshipSecondary: {
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  citizenshipSecondaryText: {
    ...theme?.typography.button,
    color: theme?.colors.text.secondary,
  },
  reviveBanner: {
    marginHorizontal: theme?.spacing.md,
    marginBottom: theme?.spacing.lg,
    padding: theme?.spacing.md,
    borderRadius: theme?.borderRadius.lg,
    backgroundColor: `${theme?.colors.primary}08`,
    borderWidth: 1,
    borderColor: `${theme?.colors.primary}20`,
    gap: theme?.spacing.sm,
  },
  reviveBannerContent: {
    gap: theme?.spacing.xs,
  },
  reviveBannerTitle: {
    ...theme?.typography.body.sans,
    color: theme?.colors.primary,
    fontWeight: '600',
  },
  reviveBannerBody: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  reviveBannerButtons: {
    flexDirection: 'row',
    gap: theme?.spacing.sm,
  },
  careerShortcutCard: {
    marginHorizontal: theme?.spacing.md,
    marginBottom: theme?.spacing.lg,
    padding: theme?.spacing.md,
    borderRadius: theme?.borderRadius.xl,
    backgroundColor: `${theme?.colors.primary}08`,
    borderWidth: 1,
    borderColor: `${theme?.colors.primary}24`,
    gap: theme?.spacing.sm,
  },
  careerShortcutHeader: {
    flexDirection: 'row',
    gap: theme?.spacing.sm,
    alignItems: 'flex-start',
  },
  careerShortcutIconWrap: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: `${theme?.colors.primary}16`,
  },
  careerShortcutTitle: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    fontWeight: '700',
    marginBottom: 2,
  },
  careerShortcutSubtitle: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  careerShortcutActions: {
    flexDirection: 'row',
    marginTop: theme?.spacing.sm,
    gap: theme?.spacing.sm,
  },
  careerShortcutPrimary: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme?.spacing.xs,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.lg,
    backgroundColor: theme?.colors.primary,
  },
  careerShortcutPrimaryText: {
    ...theme?.typography.button,
    color: theme?.colors.text.inverse,
    fontWeight: '600',
  },
  careerShortcutSecondary: {
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  careerShortcutSecondaryText: {
    ...theme?.typography.button,
    color: theme?.colors.text.secondary,
  },
  smartPickWrapper: {
    marginTop: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
  },
  revivePrimary: {
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.md,
    backgroundColor: theme?.colors.primary,
  },
  revivePrimaryText: {
    ...theme?.typography.button,
    color: theme?.colors.text.inverse,
  },
  reviveModalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.4)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme?.spacing.lg,
  },
  reviveModalCard: {
    width: '100%',
    borderRadius: theme?.borderRadius.xl,
    backgroundColor: theme?.colors.background,
    padding: theme?.spacing.lg,
    gap: theme?.spacing.lg,
  },
  reviveModalTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
  },
  reviveModalList: {
    gap: theme?.spacing.sm,
  },
  reviveModalItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme?.spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: `${theme?.colors.border}30`,
    gap: theme?.spacing.sm,
  },
  reviveInputColumns: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.sm,
  },
  reviveModalItemInput: {
    flex: 1,
    paddingVertical: theme?.spacing.xs,
    paddingHorizontal: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.md,
    borderWidth: 1,
    borderColor: `${theme?.colors.border}70`,
    backgroundColor: theme?.colors.surface,
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
  },
  reviveFeedbackInput: {
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.lg,
    borderWidth: 1,
    borderColor: `${theme?.colors.border}70`,
    backgroundColor: theme?.colors.surface,
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    minHeight: 100,
    textAlignVertical: 'top',
    marginTop: theme?.spacing.sm,
  },
  reviveModalTimeInput: {
    width: 84,
    paddingVertical: theme?.spacing.xs,
    paddingHorizontal: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.md,
    borderWidth: 1,
    borderColor: `${theme?.colors.border}70`,
    backgroundColor: theme?.colors.surface,
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    textAlign: 'center',
  },
  reviveModalTimeInputError: {
    borderColor: theme?.colors.error,
  },
  reviveModalItemText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
  },
  reviveModalErrorText: {
    marginTop: theme?.spacing.xs,
    ...theme?.typography.caption.secondary,
    color: theme?.colors.error,
  },
  reviveModalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: theme?.spacing.sm,
  },
  reviveModalRemove: {
    paddingVertical: theme?.spacing.xs,
    paddingHorizontal: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.md,
    borderWidth: 1,
    borderColor: `${theme?.colors.error}50`,
    backgroundColor: `${theme?.colors.error}10`,
  },
  reviveModalRemoveText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.error,
    fontWeight: '600',
  },
  reviveModalAdd: {
    alignSelf: 'flex-start',
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.md,
    borderWidth: 1,
    borderColor: `${theme?.colors.primary}40`,
    backgroundColor: `${theme?.colors.primary}10`,
  },
  reviveModalAddText: {
    ...theme?.typography.button,
    color: theme?.colors.primary,
  },
  reviveModalDisable: {
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.md,
    backgroundColor: theme?.colors.error,
  },
  reviveModalDisableDisabled: {
    opacity: 0.7,
  },
  reviveModalDisableText: {
    ...theme?.typography.button,
    color: theme?.colors.text.inverse,
  },
  reviveModalSave: {
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.md,
    backgroundColor: theme?.colors.primary,
  },
  reviveModalSaveDisabled: {
    opacity: 0.7,
  },
  reviveModalSaveText: {
    ...theme?.typography.button,
    color: theme?.colors.text.inverse,
  },
  reviveModalClose: {
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    backgroundColor: theme?.colors.surface,
  },
  reviveModalCloseText: {
    ...theme?.typography.button,
    color: theme?.colors.text.primary,
  },
  homeWelcomeOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme?.spacing.lg,
  },
  homeWelcomeBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  homeWelcomeCard: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.xl,
    paddingVertical: theme?.spacing.lg,
    paddingHorizontal: theme?.spacing.lg,
    width: '94%',
    maxWidth: 560,
    maxHeight: '85%',
    alignSelf: 'center',
    borderWidth: 1,
    borderColor: `${theme?.colors.primary}20`,
    shadowColor: theme?.colors.primary,
    shadowOpacity: 0.2,
    shadowRadius: 18,
    elevation: 10,
    zIndex: 2,
  },
  homeWelcomeScrollContent: {
    gap: theme?.spacing.md,
    paddingBottom: theme?.spacing.lg,
  },
  homeWelcomeTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
    textAlign: 'center',
  },
  homeWelcomeBody: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
  },
  homeWelcomeItem: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    lineHeight: 22,
  },
  homeWelcomeItemNumber: {
    ...theme?.typography.body.sans,
    color: theme?.colors.primary,
    fontWeight: '700',
  },
  homeWelcomeButtonContainer: {
    paddingTop: theme?.spacing.md,
    borderTopWidth: 1,
    borderTopColor: theme?.colors.border,
  },
  homeWelcomeButton: {
    backgroundColor: theme?.colors.primary,
    borderRadius: theme?.borderRadius.lg,
    paddingVertical: theme?.spacing.md,
    alignItems: 'center',
  },
  homeWelcomeButtonText: {
    ...theme?.typography.button.primary,
    color: theme?.colors.text.inverse,
    fontWeight: '600',
  },
  scrollContent: {
    paddingBottom: theme?.spacing.xl,
  },
  versesSection: {
    padding: theme?.spacing.md,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme?.spacing.md,
  },
  sectionTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.sm,
  },
  seeAllButton: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  seeAllText: {
    ...theme?.typography.caption.primary
  },
  verseCardContainer: {
    width: CARD_WIDTH,
    marginRight: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
  },
  verseSymbol: {
    position: 'absolute',
    top: theme?.spacing.sm,
    right: theme?.spacing.sm,
    zIndex: 2,
  },
  symbolGradient: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  verseContent: {
    flex: 1,
    padding: theme?.spacing.lg,
    justifyContent: 'space-between',
  },
  verseFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 'auto',
  },
  versesScrollContent: {
    paddingRight: theme?.spacing.md,
    gap: theme?.spacing.md,
  },
  trendingBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    backgroundColor: `${theme?.colors.primary}10`,
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: theme?.spacing.xs,
    borderRadius: theme?.borderRadius.full,
    marginBottom: theme?.spacing.md,
    gap: 4,
  },
  trendingText: {
    ...theme?.typography.caption.secondary,
    fontSize: 12,
    fontWeight: '600',
  },
  indicatorsWrapper: {
    position: 'absolute',
    bottom: -20,
    left: 0,
    right: 0,
    alignItems: 'center',
  },
  interactionButton: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.full,
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: 6,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 3,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  interactionButtonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  interactionCount: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontSize: 12,
    fontWeight: '600',
  },
  metaText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontSize: 12,
  },
  animatedProgressBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 3,
    backgroundColor: theme?.colors.primary,
  },
  gradientOverlay: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 80,
  },
  expandButton: {
    position: 'absolute',
    bottom: 0,
    alignSelf: 'flex-end',
    backgroundColor: theme?.colors.primary,
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.xs,
    ...Platform.select({
      ios: {
        shadowColor: theme?.colors.primary,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.3,
        shadowRadius: 8,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  expandButtonText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.inverse,
    fontWeight: '600',
  },
  sectionDivider: {
    height: 8,
    backgroundColor: theme?.colors.surface,
    marginBottom: theme?.spacing.lg,
  },
  section: {
    marginTop: theme?.spacing.lg,
    paddingHorizontal: theme?.spacing.md,
  },
  toolsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    gap: theme?.spacing.sm,
  },
  toolButton: {
    width: '31%',
    aspectRatio: 0.9,
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: theme?.colors.border,
    overflow: 'hidden',
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 4,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  toolGradient: {
    ...StyleSheet.absoluteFillObject,
  },
  toolIconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme?.spacing.sm,
  },
  toolLabel: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.primary,
    textAlign: 'center',
    fontWeight: '600',
  },
  badgeContainer: {
    position: 'absolute',
    top: -5,
    right: -5,
    backgroundColor: theme?.colors.error,
    borderRadius: theme?.borderRadius.full,
    width: 18,
    height: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badgeText: {
    ...theme?.typography.caption.secondary,
    fontSize: 10,
    color: '#FFF',
    fontWeight: '700',
  },
  toolTip: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginTop: theme?.spacing.md,
    textAlign: 'center',
    fontStyle: 'italic',
  },
  talkCard: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
  },
  talkSubtitle: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  talkLockedRow: {
    marginTop: theme?.spacing.sm,
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: theme?.spacing.sm,
  },
  talkLockedText: {
    flex: 1,
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  talkSecondaryButton: {
    alignSelf: 'flex-start',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
    borderWidth: 1,
    borderColor: theme?.colors.primary,
    backgroundColor: `${theme?.colors.primary}08`,
  },
  talkSecondaryButtonText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.primary,
    fontWeight: '600',
  },
  talkPrimaryButton: {
    alignSelf: 'flex-start',
    paddingHorizontal: theme?.spacing.lg,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
    backgroundColor: theme?.colors.primary,
    marginTop: theme?.spacing.sm,
  },
  talkPrimaryButtonText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.inverse,
    fontWeight: '600',
  },
  challengeCard: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 4,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  challengeHeader: {
    marginBottom: theme?.spacing.sm,
  },
  challengeType: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
  },
  challengeText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.md,
  },
  challengeIcon: {
    fontSize: 16,
    marginRight: theme?.spacing.sm,
  },
  progressContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme?.spacing.md,
  },
  progressBar: {
    flex: 1,
    height: 8,
    backgroundColor: `${theme?.colors.primary}20`,
    borderRadius: theme?.borderRadius.full,
    marginRight: theme?.spacing.sm,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: theme?.colors.primary,
    borderRadius: theme?.borderRadius.full,
  },
  progressText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
  },
  completionBadge: {
    marginTop: theme?.spacing.sm,
    alignSelf: 'flex-start',
    backgroundColor: `${theme?.colors.success}15`,
    borderRadius: theme?.borderRadius.full,
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: theme?.spacing.xs,
  },
  completionBadgeText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.success,
    fontWeight: '600',
    fontSize: 12,
  },
  completeButton: {
    alignSelf: 'flex-end',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
    backgroundColor: `${theme?.colors.success}15`,
  },
  completeButtonText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.success,
    fontWeight: '600',
  },
  joinChallengeButton: {
    alignSelf: 'flex-end',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
    backgroundColor: theme?.colors.primary,
  },
  joinChallengeText: {
    ...theme?.typography.caption.primary,
    color: '#FFF',
    fontWeight: '600',
  },
  communityStats: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme?.spacing.md,
  },
  avatarContainer: {
    marginRight: theme?.spacing.sm,
  },
  participantsText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  verseCard: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.lg,
    borderWidth: 1,
    borderColor: `${theme?.colors.primary}20`,
    overflow: 'hidden',
    ...Platform.select({
      ios: {
        shadowColor: theme?.colors.primary,
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 8,
      },
      android: {
        elevation: 3,
      },
    }),
  },
  cardGradient: {
    ...StyleSheet.absoluteFillObject,
  },
  verseReference: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.xs,
  },
  verseContextReference: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginBottom: theme?.spacing.xs,
  },
  verseText: {
    ...theme?.typography.verse.regular,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.md,
  },
  verseStats: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme?.spacing.md,
  },
  statItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.xs,
  },
  statText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  loadingText: {
    ...theme?.typography.body.sans,
    textAlign: 'center',
    color: theme?.colors.text.secondary,
  },
  contextOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme?.spacing.lg,
  },
  contextContainer: {
    width: '100%',
    maxWidth: 420,
    backgroundColor: theme?.colors.background,
    borderRadius: theme?.borderRadius.lg,
    overflow: 'hidden',
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: theme?.colors.border,
  },
  contextHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    padding: theme?.spacing.md,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: theme?.colors.border,
  },
  contextTitle: {
    ...theme?.typography.heading.small,
    flex: 1,
    color: theme?.colors.text.primary,
    marginRight: theme?.spacing.sm,
  },
  contextBody: {
    maxHeight: 300,
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
  },
  contextText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    lineHeight: 22,
  },
  contextFooter: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: theme?.spacing.sm,
    padding: theme?.spacing.md,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: theme?.colors.border,
  },
  contextPrimaryButton: {
    paddingVertical: theme?.spacing.xs,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.full,
    backgroundColor: theme?.colors.primary,
  },
  contextPrimaryText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.inverse,
  },
  contextSecondaryButton: {
    paddingVertical: theme?.spacing.xs,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.full,
    backgroundColor: theme?.colors.surface,
  },
  contextSecondaryText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.primary,
    fontWeight: '600',
  },
  interactionsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  reflectionMeta: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  reflectionCount: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginLeft: theme?.spacing.xs,
  },
  spotlightCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 4,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  spotlightIconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: `${theme?.colors.primary}15`,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: theme?.spacing.md,
  },
  spotlightContent: {
    flex: 1,
  },
  spotlightLabel: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  spotlightTitle: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    fontWeight: '600',
  },
  quizProgress: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: theme?.spacing.xs,
  },
  quizProgressBar: {
    width: 80,
    height: 4,
    backgroundColor: `${theme?.colors.secondary}20`,
    borderRadius: theme?.borderRadius.full,
    marginRight: theme?.spacing.sm,
    overflow: 'hidden',
  },
  quizProgressFill: {
    height: '100%',
    backgroundColor: theme?.colors.secondary,
    borderRadius: theme?.borderRadius.full,
  },
  quizProgressText: {
    ...theme?.typography.caption.secondary,
    fontSize: 10,
    color: theme?.colors.text.secondary,
  },
  indicatorContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: theme?.spacing.xs,
  },
  indicator: {
    height: 4,
    backgroundColor: theme?.colors.primary,
    borderRadius: theme?.borderRadius.full,
  },
  sectionHeaderWithAction: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme?.spacing.sm,
  },
  viewAllButton: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  viewAllText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.primary,
    fontWeight: '600',
  },
  modalOverlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme?.spacing.lg,
  },
  gamesModalContainer: {
    width: '90%',
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.lg,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 10 },
        shadowOpacity: 0.15,
        shadowRadius: 20,
      },
      android: {
        elevation: 10,
      },
    }),
  },
  gamesModalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme?.spacing.lg,
  },
  gamesModalTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
  },
  closeButton: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.secondary,
    fontSize: 18,
    paddingHorizontal: theme?.spacing.xs,
  },
  gameOption: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme?.spacing.md,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: `${theme?.colors.border}60`,
  },
  gameIconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: theme?.spacing.md,
  },
  gameOptionContent: {
    flex: 1,
  },
  gameOptionTitle: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    fontWeight: '600',
  },
  gameOptionDesc: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  completeButtonActive: {
    backgroundColor: `${theme?.colors.success}15`,
  },
  hcCheckinBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginHorizontal: 16,
    marginBottom: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 14,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: 12,
  },
  hcCheckinTitle: { fontWeight: '700', color: theme.colors.text.primary },
  hcCheckinBody: { color: theme.colors.text.secondary, marginTop: 2 },
  hcCheckinPrimary: { paddingHorizontal: 14, paddingVertical: 10, borderRadius: 12, backgroundColor: theme.colors.primary },
  hcCheckinPrimaryText: { color: theme.colors.text.inverse, fontWeight: '600' },
  miniJourney: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginHorizontal: 16,
    marginBottom: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 14,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: 12,
  },
  miniJourneyTitle: { fontWeight: '700', color: theme.colors.text.primary },
  miniJourneySub: { color: theme.colors.text.secondary, marginTop: 2 },
  miniJourneyBtn: { paddingHorizontal: 14, paddingVertical: 10, borderRadius: 12, backgroundColor: theme.colors.primary },
  miniJourneyBtnText: { color: theme.colors.text.inverse, fontWeight: '600' },
});

export default HomeScreen;