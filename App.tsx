import 'react-native-gesture-handler';
import React, { useEffect, useState } from 'react';
import { Text, View, StyleSheet, Button } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { ThemeProvider, useTheme } from './src/contexts/ThemeContext';
import { STORAGE_KEYS } from './src/stores/PreferencesStore';
import { AppInitializationProvider, useAppInitialization } from './src/utils/appInitialization';
import { WebSocketProvider } from './src/components/WebSocketProvider';
import CustomSplash from './src/components/CustomSplash';
import ThemeSelector from './src/components/ThemeSelector';
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
import RegistrationScreen from './src/screens/RegistrationScreen';
import CommunityScreen from './src/screens/CommunityScreen';
import PrayerRequestsScreen from './src/screens/PrayerRequestsScreen';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { appStore } from './src/stores/appStore';
import { StoreProvider } from './src/stores/StoreProvider';
import { useWebSocketVerseSync } from './src/services/websocket';
import { useAuthStore } from './src/stores/StoreProvider';
import PointsEarnedModal from './src/components/PointsEarnedModal';
import { pointsTracker } from './src/utils/pointsTracker';
import { registerGlobals, AudioSession } from '@livekit/react-native';

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
            </ThemeProvider>
          </GestureHandlerRootView>
        </SafeAreaProvider>
      );
    }
    return this.props.children as any;
  }
}

const AppContent = () => {
  const [isLoading, setIsLoading] = useState(true);
  const [initialTheme, setInitialTheme] = useState(defaultTheme);
  const [showThemeSelector, setShowThemeSelector] = useState(false);
  const [isSplashComplete, setIsSplashComplete] = useState(false);
  // Global points modal queue: show one award at a time, queue extras
  const [pointsQueue, setPointsQueue] = useState<Array<{ points: number; title?: string }>>([]);
  const [isPointsVisible, setIsPointsVisible] = useState(false);
  const { setInitialized } = useAppInitialization();
  const fontsLoaded = useAppFonts();
  const { isInitialized: authInitialized, user, token } = useAuthStore();
  const { hasCompletedWelcome, initializeWelcomeState } = appStore;
  
  // Debug: log gate values to diagnose splash/blank screen issues
  React.useEffect(() => {
    console.log('[App] gates', {
      fontsLoaded,
      isLoading,
      isSplashComplete,
      authInitialized,
    });
  }, [fontsLoaded, isLoading, isSplashComplete, authInitialized]);

  useEffect(() => {
    const initialize = async () => {
      try {
        const savedThemeVariant = await AsyncStorage.getItem(STORAGE_KEYS.THEME);
        if (savedThemeVariant) {
          setInitialTheme(getTheme(savedThemeVariant as ThemeVariant));
        } else {
          setShowThemeSelector(true);
        }
        // Initialize welcome state
        await initializeWelcomeState();
      } catch (error) {
        console.warn('Error loading theme:', error);
        setShowThemeSelector(true);
      } finally {
        setIsLoading(false);
      }
    };

    initialize();
  }, []);

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
      }, 500);
      
      return () => clearTimeout(timer);
    }
  }, [fontsLoaded, isLoading, isSplashComplete, authInitialized, setInitialized]);

  // Subscribe to global points earned events emitted by the API interceptor
  useEffect(() => {
    const unsubscribe = pointsTracker.subscribe(({ points, title }) => {
      setPointsQueue(prev => [...prev, { points, title }]);
      // If nothing showing, trigger visibility
      setIsPointsVisible(v => v || true);
    });
    return () => { unsubscribe(); };
  }, []);

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

  const NavigationContent = () => {
    // Bind WebSocket verse handlers to provider-based verse store
    useWebSocketVerseSync();
    // Determine the initial route based on authentication and welcome state
    const getInitialRoute = () => {
      // If user is authenticated and has completed welcome, go to Home
      if (user && token && hasCompletedWelcome) {
        return 'Home';
      }
      // If user is authenticated but hasn't completed welcome, go to Intro
      if (user && token && !hasCompletedWelcome) {
        return 'IntroScreen';
      }
      // If no user or token, go to Intro
      return 'IntroScreen';
    };

    const initialRoute = getInitialRoute();
    // Debug: log routing decision
    console.log('[App] Navigation initial route', {
      initialRoute,
      hasCompletedWelcome,
      hasUser: !!user,
      hasToken: !!token,
    });
    // Create a key that changes when the route should change to force re-render
    const navigatorKey = `${user?.id || 'no-user'}-${hasCompletedWelcome ? 'welcome-completed' : 'welcome-pending'}`;

    return (
      <NavigationContainer onReady={() => console.log('[App] NavigationContainer onReady')}>
        <Stack.Navigator 
          key={navigatorKey}
          screenOptions={{ headerShown: false }}
          initialRouteName={initialRoute}
        >
          <Stack.Screen name="IntroScreen" component={IntroScreen} />
          <Stack.Screen name="RegistrationScreen" component={RegistrationScreen} />
          <Stack.Screen name="Home" component={HomeScreen} />
          <Stack.Screen name="VerseDetail" component={VerseDetail} />
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
          {/* @ts-ignore */}
          <Stack.Screen name="NoteDetail" component={NoteDetailScreen} />
          <Stack.Screen name="MeditationScreen" component={MeditationScreen} />
          <Stack.Screen name="VirtueScreen" component={VirtueScreen} />
          <Stack.Screen name="VirtueTriviaScreen" component={VirtueTriviaScreen} />
          <Stack.Screen name="VirtueQuizScreen" component={VirtueQuizScreen} />
          <Stack.Screen name="VerseBuilderScreen" component={VerseBuilderScreen} />
          <Stack.Screen name="BibleScreen" component={BibleScreen} />
          <Stack.Screen name="ProfileScreen" component={ProfileScreen} />
          <Stack.Screen name="LeaderboardScreen" component={LeaderboardScreen} />
          <Stack.Screen name="GameScreen" component={GameScreen} />
          <Stack.Screen name="SpiritualCareerScreen" component={SpiritualCareerScreen} />
        </Stack.Navigator>
      </NavigationContainer>
    );
  };

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
            <NavigationContent />
          )}
        </ErrorBoundary>
        <Toaster />
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
      <AppInitializationProvider>
        <StoreProvider>
          <WebSocketProvider>
            <AppContent />
          </WebSocketProvider>
        </StoreProvider>
      </AppInitializationProvider>
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

export default App;
