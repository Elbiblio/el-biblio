import React, { useEffect, useState } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { ThemeProvider, useTheme } from './src/contexts/ThemeContext';
import { AuthProvider, useAuth } from './src/stores/auth';
import { PreferencesProvider, usePreferences, STORAGE_KEYS } from './src/stores/preferences';
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
import SavedItemsScreen from './src/screens/SavedItemsScreen';
import NotesScreen from './src/screens/NotesScreen';
import BibleScreen from './src/screens/BibleScreen';
import { RootStackParamList } from './src/types';
import { useAppFonts } from './src/hooks/useFonts';
import { getTheme, ThemeVariant, defaultTheme } from './src/theme';
import { Toaster } from 'sonner-native';
import DailyChallengeScreen from './src/screens/DailyChallengeScreen';
import VirtueQuizScreen from './src/screens/VirtueQuizScreen';
import VirtueScreen from './src/screens/VirtueScreen';
import VerseBuilderScreen from './src/screens/VerseBuilderScreen';
import VirtueTriviaScreen from './src/screens/VirtueTriviaScreen';
import MeditationScreen from './src/screens/MeditationScreen';
import NoteDetailScreen from './src/screens/NoteDetailScreen';
import ProfileScreen from './src/screens/ProfileScreen';
import LeaderboardScreen from './src/screens/LeaderboardScreen';
import GameScreen from './src/screens/GameScreen';
import RegistrationScreen from './src/screens/RegistrationScreen';
import CommunityScreen from './src/screens/CommunityScreen';
import PrayerRequestsScreen from './src/screens/PrayerRequestsScreen';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useAppStore } from './src/stores/appStore';

const Stack = createNativeStackNavigator<RootStackParamList>();

const AppContent = () => {
  const [isLoading, setIsLoading] = useState(true);
  const [initialTheme, setInitialTheme] = useState(defaultTheme);
  const [showThemeSelector, setShowThemeSelector] = useState(false);
  const [isSplashComplete, setIsSplashComplete] = useState(false);
  const { setInitialized } = useAppInitialization();
  const fontsLoaded = useAppFonts();
  const { isInitialized: authInitialized, user, token } = useAuth();
  const { hasCompletedWelcome, initializeWelcomeState } = useAppStore();
  
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
    if (fontsLoaded && !isLoading && isSplashComplete && authInitialized) {
      // Small delay to ensure all contexts are properly initialized
      const timer = setTimeout(() => {
        setInitialized(true);
      }, 500);
      
      return () => clearTimeout(timer);
    }
  }, [fontsLoaded, isLoading, isSplashComplete, authInitialized, setInitialized]);



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
        <CustomSplash onAnimationComplete={() => setIsSplashComplete(true)} />
      </ThemeProvider>
    );
  }

  const NavigationContent = () => {
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
    // Create a key that changes when the route should change to force re-render
    const navigatorKey = `${user?.id || 'no-user'}-${hasCompletedWelcome ? 'welcome-completed' : 'welcome-pending'}`;

    return (
      <NavigationContainer>
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
          <Stack.Screen name="WordHubsScreen" component={WordHubsScreen} />
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
        {showThemeSelector ? (
          <ThemeSelector onSelect={handleThemeSelect} closeAfterSelection />
        ) : (
          <NavigationContent />
        )}
        <Toaster />
      </GestureHandlerRootView>
    </ThemeProvider>
  );
};

const App = () => {
  return (
    <SafeAreaProvider>
      <AppInitializationProvider>
        <PreferencesProvider>
          <AuthProvider>
            <WebSocketProvider>
              <AppContent />
            </WebSocketProvider>
          </AuthProvider>
        </PreferencesProvider>
      </AppInitializationProvider>
    </SafeAreaProvider>
  );
};

export default App;