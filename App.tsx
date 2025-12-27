import 'react-native-gesture-handler';
import React, { useEffect, useState } from 'react';
import { Linking, Modal, Platform, Text, View, StyleSheet, TouchableOpacity } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { ThemeProvider } from './src/contexts/ThemeContext';
import { STORAGE_KEYS } from './src/stores/PreferencesStore';
import { AppInitializationProvider, useAppInitialization } from './src/utils/appInitialization';
import { WebSocketProvider } from './src/components/WebSocketProvider';
import CustomSplash from './src/components/CustomSplash';
import ThemeSelector from './src/components/ThemeSelector';
import DonateScreen from './src/screens/DonateScreen';
import HomeScreen from './src/screens/HomeScreen';
import VerseDetail from './src/screens/VerseDetail';
import ReflectionDetail from './src/screens/ReflectionDetail';
import DailyVersesScreen from './src/screens/DailyVersesScreen';
import MatchScreen from './src/screens/MatchScreen';
import IntroScreen from './src/screens/IntroScreen';
import WordHubsScreen from './src/screens/WordHubsScreen';
import WordHubDetailScreen from './src/screens/WordHubDetailScreen';
import SavedItemsScreen from './src/screens/SavedItemsScreen';
import NotesScreen from './src/screens/NotesScreen';
import BibleScreen from './src/screens/BibleScreen';
import { RootStackParamList } from './src/types';
import { useAppFonts } from './src/hooks/useFonts';
import { getTheme, ThemeVariant, defaultTheme } from './src/theme';
import { Toaster } from 'sonner-native';
import DailyChallengeScreen from './src/screens/DailyChallengeScreen';
import ChallengeDetailScreen from './src/screens/ChallengeDetailScreen';
import VirtueQuizScreen from './src/screens/VirtueQuizScreen';
import VirtueScreen from './src/screens/VirtueScreen';
import VerseBuilderScreen from './src/screens/VerseBuilderScreen';
import VirtueTriviaScreen from './src/screens/VirtueTriviaScreen';
import MeditationScreen from './src/screens/MeditationScreen';
import NoteDetailScreen from './src/screens/NoteDetailScreen';
import ProfileScreen from './src/screens/ProfileScreen';
import LeaderboardScreen from './src/screens/LeaderboardScreen';
import GameScreen from './src/screens/GameScreen';
import SpiritualCareerScreen from './src/screens/SpiritualCareerScreen';
import CareerDiscoveryScreen from './src/screens/CareerDiscoveryScreen';
import SpiritualCareerGuideScreen from './src/screens/SpiritualCareerGuideScreen';
import CareerHistoricMeditationScreen from './src/screens/CareerHistoricMeditationScreen';
import RegistrationScreen from './src/screens/RegistrationScreen';
import CommunityScreen from './src/screens/CommunityScreen';
import PrayerRequestsScreen from './src/screens/PrayerRequestsScreen';
import MyJourneyScreen from './src/screens/MyJourneyScreen';
import JourneyQuizScreen from './src/screens/JourneyQuizScreen';
import CitizenshipSetupScreen from './src/screens/CitizenshipSetupScreen';
import { BiometricLock } from './src/components/BiometricLock';
import { ErrorBoundary as AppErrorBoundary } from './src/components/ErrorBoundary';
import HabitConquestSetupScreen from './src/screens/HabitConquestSetupScreen';
import HabitConquestSessionScreen from './src/screens/HabitConquestSessionScreen';
import HabitConquestReflectionScreen from './src/screens/HabitConquestReflectionScreen';
import HabitConquestPrayerScreen from './src/screens/HabitConquestPrayerScreen';
import HabitConquestProgressScreen from './src/screens/HabitConquestProgressScreen';
import TalkToGodScreen from './src/screens/TalkToGodScreen';
import HowToPrayScreen from './src/screens/HowToPrayScreen';
import ForgivenessScreen from './src/screens/ForgivenessScreen';
import HolySpiritScreen from './src/screens/HolySpiritScreen';
import GuidePlayerScreen from './src/screens/GuidePlayerScreen';
import SetupCompleteScreen from './src/screens/SetupCompleteScreen';
import WhatYouMissedScreen from './src/screens/WhatYouMissedScreen';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { appStore } from './src/stores/appStore';
import { StoreProvider } from './src/stores/StoreProvider';
import { useWebSocketVerseSync } from './src/services/websocket';
import PointsEarnedModal from './src/components/PointsEarnedModal';
import { pointsTracker } from './src/utils/pointsTracker';
import { registerGlobals, AudioSession } from '@livekit/react-native';
import ChallengeCompletionBanner from './src/components/ChallengeCompletionBanner';
import { registerChallengeReminderTask } from './src/tasks/challengeReminderTask';
import { initAudio } from './src/services/audio';
import { usePreferencesStore, useChallengeStore, useGameStore, useLeaderboardStore, useAuthStore } from './src/stores/StoreProvider';
import { getNextUnlock } from './src/utils/gameUnlocks';
import { syncDailyNuggets, setDailyNuggetStores } from './src/tasks/dailyNuggetOrchestrator';
import { checkForAppUpdate } from './src/services/appUpdate';
import { loadMobileConfig } from './src/services/mobileConfig';
import { PushNotificationService } from './src/services/pushNotifications';
import { ReminderSyncService } from './src/services/reminderSync';
import FeatureSuggestionsScreen from './src/screens/FeatureSuggestionsScreen';
import FeatureSuggestionDetailScreen from './src/screens/FeatureSuggestionDetailScreen';

registerGlobals();

const Stack = createNativeStackNavigator<RootStackParamList>();
// Separate untyped stack for debug mode to avoid param list type errors
const DebugStack = createNativeStackNavigator();

// Toggle this to quickly isolate routing/render problems
const DEBUG_MINIMAL = false;

const DebugScreen = () => (
  <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
    <Text style={{ fontSize: 18, marginBottom: 12 }}>Debug Screen Loaded</Text>
    <Text style={{ opacity: 0.7 }}>If you see this, Navigation and RN rendering work.</Text>
  </View>
);

class ErrorBoundary extends React.Component<{ children: React.ReactNode }, { error: any }>{
  constructor(props: { children: React.ReactNode }) {
    super(props);
    this.state = { error: null };
  }
  static getDerivedStateFromError(error: any) {
    return { error };
  }
  componentDidCatch(error: any, info: any) {
    console.error('[App] ErrorBoundary caught error', error, info);
  }
  render() {
    if (this.state.error) {
      return (
        <SafeAreaProvider>
          <GestureHandlerRootView style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
            <ThemeProvider initialTheme={defaultTheme}>
              <Toaster />
              <Text style={{ color: 'red', padding: 16, textAlign: 'center' }}>
                Navigation error: {String(this.state.error?.message || this.state.error)}
              </Text>
              <TouchableOpacity onPress={() => this.setState({ error: null })} style={{ paddingHorizontal: 16, paddingVertical: 10, backgroundColor: '#222', borderRadius: 8, marginTop: 12 }}>
                <Text style={{ color: '#fff' }}>Restart app</Text>
              </TouchableOpacity>
            </ThemeProvider>
          </GestureHandlerRootView>
        </SafeAreaProvider>
      );
    }
    return this.props.children as any;
  }
}

// Extracted out of AppContent to stabilize hook identity/order across renders
type NavigationContentProps = {
  showChallengeBanner: boolean;
  onDismissChallengeBanner: () => void;
};

const NavigationContent: React.FC<NavigationContentProps> = ({ showChallengeBanner, onDismissChallengeBanner }) => {
  const { isInitialized: authInitialized, user, token } = useAuthStore();
  const { hasCompletedWelcome } = appStore;
  
  // Always call hook unconditionally (React hooks rule)
  // The hook's internal effect will handle conditional logic
  useWebSocketVerseSync();

  const getInitialRoute = () => {
    if (user && token && hasCompletedWelcome) return 'Home';
    if (user && token && !hasCompletedWelcome) return 'IntroScreen';
    return 'IntroScreen';
  };
  const initialRoute = getInitialRoute();
  if (__DEV__) {
    console.log('[App] Navigation initial route', {
      initialRoute,
      hasCompletedWelcome,
      hasUser: !!user,
      hasToken: !!token,
    });
  }
  // Stable key that changes only when auth state meaningfully changes
  // Prevents unnecessary remounts while ensuring proper navigation on auth changes
  const navigatorKey = React.useMemo(() => {
    const userId = user?.id ? String(user.id) : 'no-user';
    const welcomeState = hasCompletedWelcome ? 'welcome-completed' : 'welcome-pending';
    const authState = (user && token) ? 'authenticated' : 'unauthenticated';
    return `${userId}-${welcomeState}-${authState}`;
  }, [user?.id, hasCompletedWelcome, !!user, !!token]);

  return (
    <NavigationContainer onReady={() => { if (__DEV__) console.log('[App] NavigationContainer onReady'); }}>
      <Stack.Navigator
        key={navigatorKey}
        screenOptions={{ headerShown: false }}
        initialRouteName={initialRoute}
      >
        <Stack.Screen name="IntroScreen" component={IntroScreen} />
        <Stack.Screen name="RegistrationScreen" component={RegistrationScreen} />
        <Stack.Screen name="Home">
          {(props: any) => (
            <AppErrorBoundary>
              <HomeScreen {...props} />
            </AppErrorBoundary>
          )}
        </Stack.Screen>
        <Stack.Screen name="WhatYouMissedScreen" component={WhatYouMissedScreen} />
        <Stack.Screen name="VerseDetail">
          {(props: any) => (
            <AppErrorBoundary>
              <VerseDetail {...props} />
            </AppErrorBoundary>
          )}
        </Stack.Screen>
        <Stack.Screen name="ReflectionDetail" component={ReflectionDetail} />
        <Stack.Screen name="DailyVersesScreen" component={DailyVersesScreen} />
        <Stack.Screen name="DailyChallengeScreen" component={DailyChallengeScreen} />
        <Stack.Screen name="ChallengeDetail" component={ChallengeDetailScreen} />
        <Stack.Screen name="WordHubsScreen" component={WordHubsScreen} />
        <Stack.Screen name="WordHubDetailScreen" component={WordHubDetailScreen} />
        <Stack.Screen name="MatchScreen" component={MatchScreen} />
        <Stack.Screen name="SavedItemsScreen" component={SavedItemsScreen} />
        <Stack.Screen name="NotesScreen" component={NotesScreen} />
        <Stack.Screen name="CommunityScreen" component={CommunityScreen} />
        <Stack.Screen name="PrayerRequestsScreen" component={PrayerRequestsScreen} />
        <Stack.Screen name="NoteDetail" component={NoteDetailScreen} />
        <Stack.Screen name="MeditationScreen" component={MeditationScreen} />
        <Stack.Screen name="VirtueScreen" component={VirtueScreen} />
        <Stack.Screen name="VirtueTriviaScreen" component={VirtueTriviaScreen} />
        <Stack.Screen name="VirtueQuizScreen" component={VirtueQuizScreen} />
        <Stack.Screen name="VerseBuilderScreen" component={VerseBuilderScreen} />
        <Stack.Screen name="BibleScreen" component={BibleScreen} />
        <Stack.Screen name="ProfileScreen">
          {(props: any) => (
            <AppErrorBoundary>
              <ProfileScreen {...props} />
            </AppErrorBoundary>
          )}
        </Stack.Screen>
        <Stack.Screen name="DonateScreen" component={DonateScreen} />
        <Stack.Screen name="LeaderboardScreen" component={LeaderboardScreen} />
        <Stack.Screen name="GameScreen" component={GameScreen} />
        <Stack.Screen name="SpiritualCareerScreen" component={SpiritualCareerScreen} />
        <Stack.Screen name="CareerDiscoveryScreen" component={CareerDiscoveryScreen} />
        <Stack.Screen name="SpiritualCareerGuideScreen" component={SpiritualCareerGuideScreen} />
        <Stack.Screen
          name="CareerHistoricMeditationScreen"
          component={CareerHistoricMeditationScreen}
        />
        <Stack.Screen name="MyJourneyScreen" component={MyJourneyScreen} />
        <Stack.Screen name="JourneyQuizScreen" component={JourneyQuizScreen} />
        <Stack.Screen name="SetupCompleteScreen" component={SetupCompleteScreen} />
        <Stack.Screen name="CitizenshipSetupScreen" component={CitizenshipSetupScreen} />
        <Stack.Screen name="HabitConquestSetupScreen" component={HabitConquestSetupScreen} />
        <Stack.Screen name="HabitConquestSessionScreen" component={HabitConquestSessionScreen} />
        <Stack.Screen name="HabitConquestReflectionScreen" component={HabitConquestReflectionScreen} />
        <Stack.Screen name="HabitConquestPrayerScreen" component={HabitConquestPrayerScreen} />
        <Stack.Screen name="HabitConquestProgressScreen" component={HabitConquestProgressScreen} />
        <Stack.Screen name="TalkToGodScreen" component={TalkToGodScreen} />
        <Stack.Screen name="HowToPrayScreen" component={HowToPrayScreen} />
        <Stack.Screen name="ForgivenessScreen" component={ForgivenessScreen} />
        <Stack.Screen name="HolySpiritScreen" component={HolySpiritScreen} />
        <Stack.Screen name="GuidePlayerScreen" component={GuidePlayerScreen} />
        <Stack.Screen name="FeatureSuggestionsScreen" component={FeatureSuggestionsScreen as any} />
        <Stack.Screen name="FeatureSuggestionDetailScreen" component={FeatureSuggestionDetailScreen as any} />
      </Stack.Navigator>
      {showChallengeBanner && (
        <ChallengeCompletionBanner onDismiss={onDismissChallengeBanner} />
      )}
    </NavigationContainer>
  );
};

const AppContent = () => {
  const [isLoading, setIsLoading] = useState(true);
  const [initialTheme, setInitialTheme] = useState(defaultTheme);
  const [showThemeSelector, setShowThemeSelector] = useState(false);
  const [isSplashComplete, setIsSplashComplete] = useState(false);
  const [showUpdateModal, setShowUpdateModal] = useState(false);
  const [isMandatoryUpdate, setIsMandatoryUpdate] = useState(false);
  const [updateMessage, setUpdateMessage] = useState<string | undefined>(undefined);
  const [updateStoreUrl, setUpdateStoreUrl] = useState<string | undefined>(undefined);
  // Global points modal queue: show one award at a time, queue extras
  const [pointsQueue, setPointsQueue] = useState<Array<{ points: number; title?: string }>>([]);
  const [isPointsVisible, setIsPointsVisible] = useState(false);
  const [showChallengeBanner, setShowChallengeBanner] = useState(false);
  const { setInitialized } = useAppInitialization();
  const fontsLoaded = useAppFonts();
  const authStore = useAuthStore();
  const { isInitialized: authInitialized, user, token } = authStore;
  const preferencesStore = usePreferencesStore();
  const challengeStore = useChallengeStore();
  const gameStore = useGameStore();
  const leaderboardStore = useLeaderboardStore();
  const { hasCompletedWelcome, initializeWelcomeState } = appStore;
  const [suppressGenericPointsUntil, setSuppressGenericPointsUntil] = useState<number | null>(null);
  
  // Debug: log gate values to diagnose splash/blank screen issues
  React.useEffect(() => {
    if (__DEV__) {
      console.log('[App] gates', {
        fontsLoaded,
        isLoading,
        isSplashComplete,
        authInitialized,
      });
    }
  }, [fontsLoaded, isLoading, isSplashComplete, authInitialized]);

  useEffect(() => {
    const initialize = async () => {
      const errors: string[] = [];
      try {
        // Configure audio session once
        await initAudio().catch((error) => {
          errors.push('audio');
          if (__DEV__) console.warn('[App] Audio init failed', error);
        });
        
        const savedThemeVariant = await AsyncStorage.getItem(STORAGE_KEYS.THEME);
        if (savedThemeVariant) {
          setInitialTheme(getTheme(savedThemeVariant as ThemeVariant));
        } else {
          setShowThemeSelector(true);
        }
        
        // Initialize welcome state
        await initializeWelcomeState().catch((error) => {
          errors.push('welcome');
          if (__DEV__) console.warn('[App] Welcome state init failed', error);
        });
        
        await registerChallengeReminderTask().catch((error) => {
          errors.push('challenge_reminder');
          if (__DEV__) console.warn('[App] Challenge reminder task failed', error);
        });

        // Initialize push notifications (get token, but don't register until user is authenticated)
        PushNotificationService.initialize().catch((error) => {
          errors.push('push_notifications');
          if (__DEV__) {
            console.warn('[App] Push notification initialization failed:', error);
          }
        });

        // Load mobile runtime config (e.g. WebSocket host/port/appKey) from backend
        await loadMobileConfig().catch((error) => {
          errors.push('mobile_config');
          if (__DEV__) console.warn('[App] Mobile config load failed', error);
        });
        if (Platform.OS === 'android') {
          checkForAppUpdate()
            .then(result => {
              if (!result) return;
              if (result.needsMandatoryUpdate || result.hasOptionalUpdate) {
                setIsMandatoryUpdate(result.needsMandatoryUpdate);
                setUpdateMessage(result.message);
                setUpdateStoreUrl(result.storeUrl);
                setShowUpdateModal(true);
              }
            })
            .catch(error => {
              if (__DEV__) {
                console.warn('[App] Failed to check for updates', error);
              }
            });
        }
        
        if (errors.length > 0 && __DEV__) {
          console.warn('[App] Initialization completed with errors:', errors);
        }
      } catch (error) {
        console.error('[App] Critical initialization error', error);
        setShowThemeSelector(true);
      } finally {
        setIsLoading(false);
      }
    };

    initialize();
  }, []);

  useEffect(() => {
    (async () => {
      try {
        const raw = await AsyncStorage.getItem('points_modal_suppress_until');
        if (raw) {
          const ts = Number(raw);
          if (!Number.isNaN(ts)) setSuppressGenericPointsUntil(ts);
        }
      } catch {}
    })();
  }, []);

  useEffect(() => {
    setDailyNuggetStores({ authStore: authStore as any, preferencesStore: preferencesStore as any });
  }, [authStore, preferencesStore]);

  useEffect(() => {
    // Only proceed if auth is fully initialized AND user is authenticated
    // This ensures we don't try to register before auth is ready
    if (!authInitialized || !user?.id || !token) {
      return;
    }

    let isMounted = true;
    const currentUserId = user.id;
    const currentToken = token;

    const initializePushNotifications = async () => {
      // Defensive check: ensure user is still authenticated and values haven't changed
      if (!isMounted || !currentUserId || !currentToken) {
        return;
      }

      try {
        if (__DEV__) {
          console.log('[App] Registering push notifications for authenticated user:', currentUserId);
        }

        // updateToken will ensure initialization completes before registering
        const tokenUpdated = await PushNotificationService.updateToken(true);
        if (!isMounted) return;

        if (tokenUpdated) {
          if (__DEV__) {
            console.log('[App] Push token registered successfully');
          }
        } else {
          if (__DEV__) {
            console.warn('[App] Push token registration failed - will retry on next auth');
          }
        }

        await ReminderSyncService.syncAllLocalReminders(String(currentUserId));
        if (!isMounted) return;

        if (__DEV__) {
          console.log('[App] Reminder preferences synced');
        }
      } catch (error) {
        if (__DEV__) {
          console.error('[App] Failed to initialize push notifications for user:', error);
        }
      }
    };

    initializePushNotifications();

    return () => {
      isMounted = false;
    };
  }, [authInitialized, user?.id, token]);

  useEffect(() => {
    const startAudioSession = async () => {
      try {
        await AudioSession.startAudioSession();
      } catch (error) {
        console.warn('[LiveKit] Failed to start audio session', error);
      }
    };

    startAudioSession();

    return () => {
      AudioSession.stopAudioSession().catch(() => undefined);
    };
  }, []);

  useEffect(() => {
    if (fontsLoaded && !isLoading && isSplashComplete && authInitialized) {
      // Small delay to ensure all contexts are properly initialized
      const timer = setTimeout(() => {
        setInitialized(true);
        
        // Check for uncompleted challenges after initialization
        try {
          if (challengeStore && Array.isArray(challengeStore.personalChallenges)) {
            const list = challengeStore.personalChallenges as any[];
            const uncompleted = list.filter((c: any) => !c?.isCompleted && c?.hasJoined);
            if (uncompleted.length > 0) {
              setShowChallengeBanner(true);
            }
          }
        } catch (error) {
          console.warn('[App] Failed to check uncompleted challenges', error);
        }

        // Kick off daily nugget sync once everything is ready
        if (preferencesStore.showDailyNuggets) {
          void syncDailyNuggets({ triggerInSeconds: 10 * 60 });
        }
      }, 500);
      
      return () => clearTimeout(timer);
    }
  }, [fontsLoaded, isLoading, isSplashComplete, authInitialized, setInitialized, preferencesStore.showDailyNuggets, challengeStore]);

  // Reschedule nuggets when preference toggles while app is mounted
  useEffect(() => {
    if (!authInitialized || !preferencesStore.showDailyNuggets) {
      return;
    }
    const timer = setTimeout(() => {
      void syncDailyNuggets({ triggerInSeconds: 5 * 60 });
    }, 1000);
    return () => clearTimeout(timer);
  }, [authInitialized, preferencesStore.showDailyNuggets]);


  // Subscribe to global points earned events emitted by the API interceptor
  useEffect(() => {
    const unsubscribe = pointsTracker.subscribe(({ points, title }) => {
      // Read current values at callback execution time
      // Stores are stable references, but state values need to be current
      const currentSuppress = suppressGenericPointsUntil;
      const now = Date.now();
      const suppressActive = currentSuppress != null && now < currentSuppress;
      const totalBefore = leaderboardStore.userStats?.totalPoints ?? authStore?.user?.points ?? 0;
      const vbBest = gameStore.getPersonalBest('verse_builder') || 0;
      const nextBefore = getNextUnlock(totalBefore, vbBest);
      const totalAfter = totalBefore + (points || 0);
      const nextAfter = getNextUnlock(totalAfter, vbBest);
      const unlockedNow = !!nextBefore && !nextAfter;
      
      if (unlockedNow) {
        const endOfDay = (() => { const d = new Date(); d.setHours(23,59,59,999); return d.getTime(); })();
        setSuppressGenericPointsUntil(endOfDay);
        AsyncStorage.setItem('points_modal_suppress_until', String(endOfDay)).catch(() => undefined);
      }

      const isGameScore = title === 'Game Score';
      const shouldSuppress = (suppressActive || unlockedNow) && !title;

      // Only show the global points modal for non-game-score awards
      if (!shouldSuppress && !isGameScore) {
        setPointsQueue(prev => [...prev, { points, title }]);
        setIsPointsVisible(true);
      }

      // Still always update the user's points balance
      if (authStore?.user?.id) {
        authStore.updateUserPoints(points).catch(() => undefined);
      }
    });
    return () => { unsubscribe(); };
  }, [suppressGenericPointsUntil, leaderboardStore, authStore, gameStore]);

  // If queue emptied, hide modal
  useEffect(() => {
    if (pointsQueue.length === 0) {
      setIsPointsVisible(false);
    }
  }, [pointsQueue.length]);



  const handleThemeChange = async (variant: ThemeVariant) => {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.THEME, variant);
    } catch (error) {
      console.error('Error saving theme:', error);
    }
  };

  const handleThemeSelect = async (variant: ThemeVariant) => {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.THEME, variant);
      setInitialTheme(getTheme(variant));
      setShowThemeSelector(false);
    } catch (error) {
      console.error('Error saving theme:', error);
    }
  };

  if (!fontsLoaded || isLoading || !isSplashComplete || !authInitialized) {
    return (
      <ThemeProvider initialTheme={defaultTheme} onThemeChange={handleThemeChange}>
        <View style={{ flex: 1 }}>
          <CustomSplash onAnimationComplete={() => setIsSplashComplete(true)} />
          {/* <View style={stylesDebug.overlay} pointerEvents="none">
            <Text style={stylesDebug.text}>
              fontsLoaded: {String(fontsLoaded)} | isLoading: {String(isLoading)} | splash: {String(isSplashComplete)} | auth: {String(authInitialized)}
            </Text>
          </View> */}
        </View>
      </ThemeProvider>
    );
  }

  return (
    <ThemeProvider
      initialTheme={initialTheme}
      onThemeChange={handleThemeChange}
    >
      <GestureHandlerRootView style={{ flex: 1 }}>
        <ErrorBoundary>
          {showThemeSelector ? (
            <ThemeSelector onSelect={handleThemeSelect} closeAfterSelection />
          ) : (
            <NavigationContent
              showChallengeBanner={showChallengeBanner}
              onDismissChallengeBanner={() => setShowChallengeBanner(false)}
            />
          )}
        </ErrorBoundary>
        <Toaster />
        <Modal
          transparent
          animationType="fade"
          visible={showUpdateModal}
          onRequestClose={() => {
            if (!isMandatoryUpdate) {
              setShowUpdateModal(false);
            }
          }}
        >
          <View style={styles.updateModalBackdrop}>
            <View style={styles.updateModalContainer}>
              <Text style={styles.updateModalTitle}>
                {isMandatoryUpdate ? 'Update Required' : 'Update Available'}
              </Text>
              <Text style={styles.updateModalBody}>
                {updateMessage ||
                  (isMandatoryUpdate
                    ? 'A newer version of the app is required to continue.'
                    : 'A newer version of the app is available. Would you like to update now?')}
              </Text>
              <View style={styles.updateModalActions}>
                {!isMandatoryUpdate && (
                  <TouchableOpacity
                    style={[styles.updateModalButton, styles.updateModalSecondary]}
                    onPress={() => setShowUpdateModal(false)}
                  >
                    <Text style={styles.updateModalSecondaryText}>Later</Text>
                  </TouchableOpacity>
                )}
                <TouchableOpacity
                  style={[styles.updateModalButton, styles.updateModalPrimary]}
                  onPress={() => {
                    if (updateStoreUrl) {
                      Linking.openURL(updateStoreUrl).catch(err => {
                        if (__DEV__) {
                          console.warn('[App] Failed to open store URL', err);
                        }
                      });
                    }
                    if (!isMandatoryUpdate) {
                      setShowUpdateModal(false);
                    }
                  }}
                >
                  <Text style={styles.updateModalPrimaryText}>Update</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>
        <PointsEarnedModal
          visible={isPointsVisible && pointsQueue.length > 0}
          pointsEarned={pointsQueue[0]?.points || 0}
          challengeTitle={pointsQueue[0]?.title}
          title={pointsQueue[0]?.title ? 'Challenge Reward' : 'Points Earned!'}
          autoCloseMs={2400}
          onClose={() => {
            setPointsQueue(prev => prev.slice(1));
            // Keep visible if more in queue; visibility toggled by effect
          }}
        />
      </GestureHandlerRootView>
    </ThemeProvider>
  );
};

const App = () => {
  if (DEBUG_MINIMAL) {
    // Minimal app that bypasses all providers and initialization
    return (
      <SafeAreaProvider>
        <GestureHandlerRootView style={{ flex: 1 }}>
          <ThemeProvider initialTheme={defaultTheme}>
            <NavigationContainer>
              <DebugStack.Navigator screenOptions={{ headerShown: false }} initialRouteName="Debug">
                <DebugStack.Screen name="Debug" component={DebugScreen} />
              </DebugStack.Navigator>
            </NavigationContainer>
          </ThemeProvider>
        </GestureHandlerRootView>
      </SafeAreaProvider>
    );
  }

  return (
    <SafeAreaProvider>
      <BiometricLock>
        <AppInitializationProvider>
          <StoreProvider>
            <WebSocketProvider>
              <AppContent />
            </WebSocketProvider>
          </StoreProvider>
        </AppInitializationProvider>
      </BiometricLock>
    </SafeAreaProvider>
  );
};

const stylesDebug = StyleSheet.create({
  overlay: {
    position: 'absolute',
    bottom: 8,
    right: 8,
    backgroundColor: 'rgba(0,0,0,0.5)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  text: {
    color: '#fff',
    fontSize: 10,
  },
});

const styles = StyleSheet.create({
  updateModalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  updateModalContainer: {
    backgroundColor: '#ffffff',
    borderRadius: 16,
    paddingVertical: 24,
    paddingHorizontal: 20,
    width: '100%',
    maxWidth: 360,
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 12,
    elevation: 6,
  },
  updateModalTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 12,
    textAlign: 'center',
  },
  updateModalBody: {
    fontSize: 16,
    color: '#374151',
    marginBottom: 24,
    textAlign: 'center',
  },
  updateModalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 12,
  },
  updateModalButton: {
    minWidth: 96,
    borderRadius: 999,
    paddingVertical: 10,
    paddingHorizontal: 16,
    alignItems: 'center',
  },
  updateModalPrimary: {
    backgroundColor: '#1f2937',
  },
  updateModalPrimaryText: {
    color: '#ffffff',
    fontWeight: '600',
  },
  updateModalSecondary: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: '#d1d5db',
  },
  updateModalSecondaryText: {
    color: '#1f2937',
    fontWeight: '600',
  },
});

export default App;
