import React, { useEffect, useState } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { ThemeProvider, useTheme } from './src/contexts/ThemeContext';
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
import { RootStackParamList } from './src/types';
import { useAppFonts } from './src/hooks/useFonts';
import { getTheme, ThemeVariant, defaultTheme } from './src/theme';
import { Toaster } from 'sonner-native';
import { useWelcomeState } from './src/contexts/ThemeContext';
const Stack = createNativeStackNavigator<RootStackParamList>();
const THEME_STORAGE_KEY = '@app_theme';

const App = () => {
  const fontsLoaded = useAppFonts();
  const [isLoading, setIsLoading] = useState(true);
  const [initialTheme, setInitialTheme] = useState(defaultTheme);
  const [showThemeSelector, setShowThemeSelector] = useState(false);
  const [isSplashComplete, setIsSplashComplete] = useState(false);
  const theme = useTheme();

  useEffect(() => {
    const initialize = async () => {
      await Promise.all([
        loadSavedTheme(),
      ]);
      setIsLoading(false);
    };
    
    initialize();
  }, []);

  // useEffect(() => {
  //   theme.setTheme(initialTheme)
  // }, [initialTheme])

  const loadSavedTheme = async () => {
    try {
      const savedThemeVariant = await AsyncStorage.getItem(THEME_STORAGE_KEY);
      if (savedThemeVariant) {
        setInitialTheme(getTheme(savedThemeVariant as ThemeVariant));
      } else {
        setShowThemeSelector(true);
      }
    } catch (error) {
      console.warn('Error loading theme:', error);
      setShowThemeSelector(true);
    } finally {
      setIsLoading(false);
    }
  };

  const handleThemeChange = async (variant: ThemeVariant) => {
    try {
      await AsyncStorage.setItem(THEME_STORAGE_KEY, variant);
    } catch (error) {
      console.error('Error saving theme:', error);
    }
  };

  const handleThemeSelect = async (variant: ThemeVariant) => {
    try {
      await AsyncStorage.setItem(THEME_STORAGE_KEY, variant);
      setInitialTheme(getTheme(variant));
      setShowThemeSelector(false);
    } catch (error) {
      console.error('Error saving theme:', error);
    }
  };

  // Remove useWelcomeState from here since it needs ThemeProvider

  if (!fontsLoaded || isLoading || !isSplashComplete) {
    return (
      <ThemeProvider initialTheme={defaultTheme} onThemeChange={handleThemeChange}>
        <CustomSplash onAnimationComplete={() => setIsSplashComplete(true)} />
      </ThemeProvider>
    );
  }

  const NavigationContent = () => {
    const { hasCompletedWelcome } = useWelcomeState();
    
    return (
      <NavigationContainer>
        <Toaster />
        <Stack.Navigator screenOptions={{ headerShown: false }}>
          {!hasCompletedWelcome ? (
            <Stack.Screen name="IntroScreen" component={IntroScreen} />
          ) : (
            <>
              <Stack.Screen name="Home" component={HomeScreen} />
              <Stack.Screen name="VerseDetail" component={VerseDetail} />
              <Stack.Screen name="ReflectionDetail" component={ReflectionDetail} />
              <Stack.Screen name="DailyVersesScreen" component={DailyVersesScreen} />
              <Stack.Screen name="WordHubsScreen" component={WordHubsScreen} />
              <Stack.Screen name="MatchScreen" component={MatchScreen} />
              <Stack.Screen name="SavedItemsScreen" component={SavedItemsScreen} />
              <Stack.Screen name="NotesScreen" component={NotesScreen} />
              <Stack.Screen name="IntroScreen" component={IntroScreen} />
            </>
          )}
        </Stack.Navigator>
      </NavigationContainer>
    );
  };

  return (
    <SafeAreaProvider>
      <ThemeProvider 
        initialTheme={initialTheme}
        onThemeChange={handleThemeChange}
      >
        {showThemeSelector ? (
          <ThemeSelector onSelect={handleThemeSelect} />
        ) : (
          <GestureHandlerRootView style={{ flex: 1 }}>
            <NavigationContent />
          </GestureHandlerRootView>
        )}
      </ThemeProvider>
    </SafeAreaProvider>
  );
};

export default App;