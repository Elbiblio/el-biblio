import React, { useCallback, useEffect, useState, useMemo } from 'react';
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

import { AppState, AppStateStatus } from 'react-native';
// Removed local PointsEarnedModal usage; global modal in App.tsx handles display via interceptor
import { useNavigation } from '@react-navigation/native';
import { useWebSocket } from '@/services/websocket';
import * as Haptics from 'expo-haptics';
import { useCommunityStore } from '@/stores/CommunityStore';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useFocusEffect } from '@react-navigation/native';

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

const AnimatedBlurView = Animated.createAnimatedComponent(BlurView);
const CARD_WIDTH = SCREEN_DIMENSIONS.width * 0.9;
const QUICK_MENU_STORAGE_KEY = 'home_quick_menu_usage';
const HOME_WELCOME_KEY = 'home_welcome_note_seen';
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

  const meditationComplete = route.params?.meditationComplete || false;
  // const challenge = route.params?.challenge;

  const theme = useTheme()
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  // const actionStyles = React.useMemo(() => createActionStyles(theme), [theme]);
  // const themeText = { color: theme?.colors.primary };

  const [appState, setAppState] = useState(AppState.currentState);
  const { user, updateUserTime, authRequired, logout } = useAuthStore();
  const { completeChallenge } = useMeditationStore();
  const { isConnected } = useWebSocket();
  const { unreadCount, computeUnreadFromReflections } = useCommunityStore();
  const { shouldShowBadge, updateRank } = useGameBadgeStore();
  const dailyPathStore = useDailyPathStore();
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

  useEffect(() => {
    if (!dailyPathStore.isReady) {
      return;
    }

    if (dailyPathStore.isSetupComplete) {
      setShowSetupPrompt(false);
      return;
    }

    const now = new Date();
    const lastPrompt = dailyPathStore.lastPromptedAt ? new Date(dailyPathStore.lastPromptedAt) : null;
    const hoursSincePrompt = lastPrompt ? (now.getTime() - lastPrompt.getTime()) / (1000 * 60 * 60) : Infinity;

    if (!lastPrompt || hoursSincePrompt >= 12) {
      dailyPathStore.recordSetupPrompt(now.toISOString());
      setShowSetupPrompt(true);
    }
  }, [dailyPathStore, dailyPathStore.isReady, dailyPathStore.isSetupComplete, dailyPathStore.lastPromptedAt]);

  const handleOpenCitizenshipSetup = useCallback(() => {
    setShowSetupPrompt(false);
    navigation.navigate('CitizenshipSetupScreen');
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
  useEffect(() => {
    loadTimeTracking();
    const subscription = AppState.addEventListener('change', handleAppStateChange);

    const syncInterval = setInterval(() => {
      if (appState === 'active') {
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
      setShowAuthModal(false);
    }
  }, [user]);

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
    } catch (error) {
      console.error('Failed to load time tracking:', error);
    }
  };

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
    if (!user || timeTracking.totalActiveTime <= timeTracking.lastSyncedTime) {
      return;
    }

    try {
      await updateUserTime(timeTracking.totalActiveTime);
      setTimeTracking(prev => ({
        ...prev,
        lastSyncedTime: prev.totalActiveTime
      }));
    } catch (error) {
      console.error('Error syncing time:', error);
    }
  };

  const handleAppStateChange = (nextAppState: AppStateStatus) => {
    if (appState === 'active' && nextAppState.match(/inactive|background/)) {
      handleAppInactive();
    } else if (appState.match(/inactive|background/) && nextAppState === 'active') {
      handleAppActive();
    }
    setAppState(nextAppState);
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
    const sessionDuration = now - timeTracking.lastActiveTimestamp;

    const newTracking = {
      ...timeTracking,
      totalActiveTime: timeTracking.totalActiveTime + sessionDuration,
      lastActiveTimestamp: now,
    };

    setTimeTracking(newTracking);
    await saveTimeTracking(newTracking);
    await handleTimeSync();
  };


  const verseStore = useVerseStore();
  const { dailyVerses, isDailyVersesLoading } = verseStore.state;
  const { fetchDailyVerses } = verseStore;

  const challengeStore = useChallengeStore();
  const { personalChallenges, communityChallenges } = challengeStore;
  const { fetchPersonalChallenges, fetchCommunityChallenges } = challengeStore;

  // Refresh challenges whenever Home gains focus (ensures newly joined show up)
  useFocusEffect(
    React.useCallback(() => {
      fetchPersonalChallenges(1);
      fetchCommunityChallenges(1);
    }, [fetchPersonalChallenges, fetchCommunityChallenges])
  );

  const reflectionStore = useReflectionStore();
  const { reflections, isReflectionsLoading } = reflectionStore.state;
  const { fetchReflections } = reflectionStore;

  const leaderboardStore = useLeaderboardStore();
  const { fetchGlobalLeaderboard, fetchUserRank } = leaderboardStore;

  const meditationStore = useMeditationStore();
  const { meditationState, meditationTimer, selectedChallenge } = meditationStore.state;

  useEffect(() => {
    const getHttpStatus = (err: any): number | undefined => err?.status || err?.response?.status;
    const handleAuthHttpError = (err: any) => {
      const status = getHttpStatus(err);
      if (status === 401) {
        // Global interceptor will also mark authRequired; proactively show modal
        setShowAuthModal(true);
      }
    };

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
            try { await logout(); } catch {}
            setShowAuthModal(true);
          }
        }
      }
    };

    load();
  }, [fetchDailyVerses, fetchPersonalChallenges, fetchCommunityChallenges, fetchReflections, fetchGlobalLeaderboard, user?.id]);

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
      ? (personalChallenges || []).some((c: any) => c.id === (selectedChallenge as any).id && !c.isCompleted)
      : false;
    return sessionInProgress || startedButNotCompleted || selectedIncomplete;
  }, [meditationState, meditationTimer, selectedChallenge, personalChallenges]);

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
              );
            }}
          >
            <Animated.View style={[styles.points, { transform: [{ scale: pointsScale }] }]}> 
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
    const toolAnimatedStyle = useAnimatedStyle(() => ({
      transform: [{ scale: toolsScale.value }]
    }));

    return (
      <Animated.View style={[styles.section, toolAnimatedStyle]}>
        <Text style={styles.sectionTitle}>QUICK MENU</Text>
        <View style={styles.toolsGrid}>
          {[
            { icon: Trophy, label: 'Games', route: 'GameScreen', badge: shouldShowBadge ? 1 : null, color: theme?.colors.success, requiresUnlock: false, stage: 0 },
            { icon: Bible, label: 'Bible', route: 'BibleScreen', badge: null, color: theme?.colors.secondary, requiresUnlock: false, stage: 0 },
            { icon: Users, label: 'Community', route: 'CommunityScreen', badge: communityUnreadBadge, color: theme?.colors.success, requiresUnlock: false, stage: 0 },
            { icon: BookOpen, label: 'Meditation', route: 'MeditationScreen', badge: hasUnfinishedMeditation ? 1 : null, color: theme?.colors.primary, requiresUnlock: false, stage: 0 },
            { icon: BookmarkSimple, label: 'Bookmarks', route: 'SavedItemsScreen', badge: null, color: theme?.colors.like, requiresUnlock: false, stage: 1 },
            { icon: Fire, label: 'SoulForge', route: 'VirtueScreen', badge: null, color: theme?.colors.primaryDark, requiresUnlock: true, stage: 2 },
          ].map((tool) => {
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

  useEffect(() => {
    if (!dailyPathStore.isSetupComplete) return;
    if (!dailyPathStore.isChallengesEnabled && challengesUnlockedByPoints) {
      toast.info('Daily challenges unlocked! Join one to stay consistent.');
    }
  }, [dailyPathStore.isSetupComplete, dailyPathStore.isChallengesEnabled, challengesUnlockedByPoints]);

  const renderDailyChallenges = () => {
    if (!shouldShowChallenges) {
      return null;
    }

    const challengeAnimatedStyle = useAnimatedStyle(() => ({
      opacity: challengeOpacity.value,
    }));

    // Show loading state
    if (challengeStore.isLoading) {
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
          <View style={styles.loadingContainer}>
            <Text style={styles.loadingText}>Loading challenges...</Text>
          </View>
        </Animated.View>
      );
    }
    
    // Use real API data from challenge store only
    const personalChallenge = personalChallenges && personalChallenges.length > 0
      ? personalChallenges[0]
      : undefined;
    const joinedChallengeIds = new Set((personalChallenges || []).map(challenge => challenge.id));
    const communityChallenge = (communityChallenges || []).find(challenge => {
      if (joinedChallengeIds.has(challenge.id)) return false;
      if (challenge.hasJoined) return false;
      return true;
    });
    
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
          toast.success('Challenge added to your day');
          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
          setSmartPickDismissed(true);
          navigation.navigate('DailyChallengeScreen');
        }
      })();
    }, [challengeStore, navigation]);

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
                if (isPersonalChallengeComplete && personalChallenge.id) {
                  handleCompleteChallenge(personalChallenge.id);
                } else {
                  challengeOpacity.value = withSequence(
                    withTiming(0.7, { duration: 100 }),
                    withTiming(1, { duration: 100 })
                  );
                }
              }}
            >
              <Text style={styles.completeButtonText}>
                {isPersonalChallengeComplete ? '✅ Complete' : '⏳ In Progress'}
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
    const verseAnimatedStyle = useAnimatedStyle(() => ({
      transform: [{ translateY: verseTranslateY.value }],
      opacity: interpolate(verseTranslateY.value, [20, 0], [0, 1]),
    }));

    if (!dailyVerses || dailyVerses.length === 0) {
      return (
        <Animated.View style={[styles.section, verseAnimatedStyle]}>
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
                {verse.likes || 0} Saves
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
    const spotlightAnimatedStyle = useAnimatedStyle(() => ({
      transform: [{ translateX: spotlightTranslateX.value }],
      opacity: interpolate(spotlightTranslateX.value, [20, 0], [0, 1]),
    }));

    // Use real content if available: take top reflection as spotlight
    const spotlight = (reflections && (reflections as any[]).length > 0) ? (reflections as any[])[0] : null;
    if (!spotlight) return null;

    return (
      <Animated.View style={[styles.section, spotlightAnimatedStyle]}>
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
        {renderDailyJourneyCard()}
        {renderReviveReminderBanner()}
        {renderQuickTools()}
        {renderDailyChallenges()}
        {renderVerseOfTheDay()}
        {renderLearningSpotlight()}
      </ScrollView>

      <VersePreviewModal 
        verse={selectedVerse} 
        onClose={() => setSelectedVerse(null)}
        context="home"
        onVersePress={(verse: ModalVerse) => {
          navigation.navigate('VerseDetail', { verse });
          setSelectedVerse(null);
        }}
      />

      {renderGamesModal()}
      
      {/* Points Earned Modal */}
      {/* PointsEarnedModal is now shown globally in App.tsx via pointsTracker */}

      <AuthModal
        visible={showAuthModal}
        onClose={() => setShowAuthModal(false)}
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
                Jesus prayed, “That they may all be one” (John 17:21). In a world assailed by evil schemes, this community exists as a place of comfort and solace for Christians to unite in prayer, renew their resolves, and grow together in faith, peace, and love as one body in Christ.
              </Text>
              <Text style={styles.homeWelcomeBody}>Please take note of these guiding commitments:</Text>
              <Text style={styles.homeWelcomeItem}>
                <Text style={styles.homeWelcomeItemNumber}>1.&nbsp;</Text>
                We are a non-denominational family. Jesus did not come to start a religion, and He foresaw many branches when He prayed for unity. There is no room for casting stones at one another — such division opposes both His prayer and His nature.
              </Text>
              <Text style={styles.homeWelcomeItem}>
                <Text style={styles.homeWelcomeItemNumber}>2.&nbsp;</Text>
                For the sake of unity, we honor the breadth of Christian perspectives that does not directly contradict the teachings of Jesus Christ. Jesus fulfilled the Law rather than abolishing it, and the apostles carried forward holy traditions. Differences often emerge around which teachings or practices to retain, yet intention, right judgment, faith, and spiritual maturity (Luke 18:8; Mark 9:29) must lead the way. God's mercy and grace are infinite and universal, and cannot be limited (For example in Acts 10:2, the Holy Spirit instructed a God-fearing pagan to invite one of the Apostles).
              </Text>
              <Text style={styles.homeWelcomeItem}>
                <Text style={styles.homeWelcomeItemNumber}>3.&nbsp;</Text>
                Every church can learn from another. Some focus on the yolk, some keep the whole egg including the shell, others add seasoning — but the harvest is judged by its fruit (Matthew 7:16). Any tradition that distorts God’s design — whether promotion of polygamy, sexual immorality, or denying the divinity of Jesus — must give way to the truth and such doctrines (2 John 7-11) will not be tolerated. All are however welcome to learn the truth by laying aside bias and trusting in the grace of God through the Holy Spirit and the community of brethren.
              </Text>
              <Text style={styles.homeWelcomeItem}>
                <Text style={styles.homeWelcomeItemNumber}>4.&nbsp;</Text>
                 We include the full Bible for the purposes of edification (both Jerome and Martin Luther recognized the apocrypha as good for reading), and it is the Holy Spirit who truly teaches all things. We also do not discriminate against recognition of saints (Romans 8:27); just as Peter, Paul, and the apostles walked in Christ, even today there are true disciples who have gone before us, and reflection on their lives can likewise edify and inspire us. The choice of believing that those who walked in Christ are not dead but alive and still working toward the fulfillment of the Kingdom together with us (Romans 8:19-23) is simply a matter of faith. Likewise, arguments about mediation vs intercession, eucharistic celebration, sainthood of Mary, etc., are inconsequential to the purpose of this community, as they concern understanding rather than blasphemy or rejection of grace; what matters is that we work with the grace of God and that our lives bear witness and fruits according to His grace, bringing about His Kingdom on earth.
              </Text>
              <Text style={styles.homeWelcomeItem}>
                <Text style={styles.homeWelcomeItemNumber}>5.&nbsp;</Text>
                By signing up you pledge you are a Christian or willing to become one and to abide by the unitive prayer of Jesus — growing in grace, nurturing others, and avoiding divisive agendas. Elbiblio is a tool for spiritual maturity (Ephesians 4:13-15), not for proselytizing denominational bias. We stand firm in the teachings of Jesus, and God’s original design revealed through the Bible and creation, and we expect every believer to bear the virtues and signs Jesus describes in Matthew 5:1-16 and 25:35-40.
              </Text>
              <Text style={styles.homeWelcomeBody}>
                Together, let us make the community a welcome place for each other.
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


const createActionStyles = (theme: Theme) => StyleSheet.create({
  quickActionsContainer: {
    marginTop: theme?.spacing.md,
    paddingHorizontal: theme?.spacing.md,
    marginBottom: theme?.spacing.xl,
  },
  quickActionsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme?.spacing.md,
  },
  quickActionsTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
  },
  actionGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme?.spacing.sm,
  },
  actionCard: {
    flex: 1,
    minWidth: '47%', // Slightly less than 50% to account for gap
    aspectRatio: 2.5,
    borderRadius: theme?.borderRadius.lg,
    backgroundColor: theme?.colors.background,
    overflow: 'hidden',
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
  actionGradient: {
    ...StyleSheet.absoluteFillObject,
  },
  actionContent: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.md,
    gap: theme?.spacing.sm,
  },
  iconContainer: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionText: {
    ...theme?.typography.caption.primary,
    fontSize: 13,
    fontWeight: '600',
  },
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
});

export default HomeScreen;