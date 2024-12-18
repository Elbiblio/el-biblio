import React, { useEffect, useState } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { ThemeProvider } from './src/contexts/ThemeContext';
import CustomSplash from './src/components/CustomSplash';
import ThemeSelector from './src/components/ThemeSelector';
import HomeScreen from './src/screens/HomeScreen';
import VerseDetail from './src/screens/VerseDetail';
import ReflectionDetail from './src/screens/ReflectionDetail';
import { RootStackParamList } from './src/types';
import { useAppFonts } from './src/hooks/useFonts';
import { getTheme, ThemeVariant, defaultTheme } from './src/theme';
import { useThemeStore } from './src/theme/store';

const Stack = createNativeStackNavigator<RootStackParamList>();
const THEME_STORAGE_KEY = '@app_theme';

const App = () => {
  const fontsLoaded = useAppFonts();
  const [isLoading, setIsLoading] = useState(true);
  const [initialTheme, setInitialTheme] = useState(defaultTheme);
  const [showThemeSelector, setShowThemeSelector] = useState(false);
  const [isSplashComplete, setIsSplashComplete] = useState(false);
  const theme = useThemeStore()

  useEffect(() => {
    loadSavedTheme();
  }, []);

  useEffect(() => {
    theme.setTheme(initialTheme)
  }, [initialTheme])

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

  if (!fontsLoaded || isLoading || !isSplashComplete) {
    return (
      <ThemeProvider initialTheme={defaultTheme} onThemeChange={handleThemeChange}>
        <CustomSplash onAnimationComplete={() => setIsSplashComplete(true)} />
      </ThemeProvider>
    );
  }

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
            <NavigationContainer>
              <Stack.Navigator screenOptions={{ headerShown: false }}>
                <Stack.Screen name="Home" component={HomeScreen} />
                <Stack.Screen name="VerseDetail" component={VerseDetail} />
                <Stack.Screen name="ReflectionDetail" component={ReflectionDetail} />
              </Stack.Navigator>
            </NavigationContainer>
          </GestureHandlerRootView>
        )}
      </ThemeProvider>
    </SafeAreaProvider>
  );
};

export default App;