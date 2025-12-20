import React, { useEffect, useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, AppState, AppStateStatus } from 'react-native';
import * as LocalAuthentication from 'expo-local-authentication';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useTheme } from '@/contexts/ThemeContext';

const BIOMETRIC_ENABLED_KEY = 'biometric_enabled';
const LAST_AUTH_KEY = 'last_biometric_auth';
const AUTH_TIMEOUT = 5 * 60 * 1000; // 5 minutes

interface BiometricLockProps {
  children: React.ReactNode;
  onUnlock?: () => void;
}

export const BiometricLock: React.FC<BiometricLockProps> = ({ children, onUnlock }) => {
  const [isLocked, setIsLocked] = useState(true);
  const [biometricAvailable, setBiometricAvailable] = useState(false);
  const [biometricEnabled, setBiometricEnabled] = useState(false);
  const [isAuthenticating, setIsAuthenticating] = useState(false);
  const theme = useTheme();

  useEffect(() => {
    checkBiometric();
    
    const subscription = AppState.addEventListener('change', handleAppStateChange);
    return () => {
      subscription.remove();
    };
  }, []);

  const handleAppStateChange = async (nextAppState: AppStateStatus) => {
    if (nextAppState === 'active' && biometricEnabled && biometricAvailable) {
      await checkRecentAuth();
    }
  };

  const checkBiometric = async () => {
    try {
      // Check if device supports biometric authentication
      const compatible = await LocalAuthentication.hasHardwareAsync();
      if (!compatible) {
        console.log('[BiometricLock] Device does not support biometric authentication');
        setBiometricAvailable(false);
        setIsLocked(false);
        onUnlock?.();
        return;
      }

      // Check if user has enrolled biometrics
      const enrolled = await LocalAuthentication.isEnrolledAsync();
      if (!enrolled) {
        console.log('[BiometricLock] User has not enrolled biometrics');
        setBiometricAvailable(false);
        setIsLocked(false);
        onUnlock?.();
        return;
      }

      // Device supports and user has enrolled biometrics
      setBiometricAvailable(true);

      // Check if user has enabled biometric authentication in app
      const enabled = await AsyncStorage.getItem(BIOMETRIC_ENABLED_KEY);
      const isEnabled = enabled === 'true'; // Disabled by default
      setBiometricEnabled(isEnabled);

      if (biometricAvailable && isEnabled) {
        await checkRecentAuth();
      } else {
        setIsLocked(false);
        onUnlock?.();
      }
    } catch (error) {
      console.error('[BiometricLock] Check failed', error);
      // Graceful fallback - unlock on any error to prevent lockout
      setBiometricAvailable(false);
      setIsLocked(false);
      onUnlock?.();
    }
  };

  const checkRecentAuth = async () => {
    try {
      const lastAuth = await AsyncStorage.getItem(LAST_AUTH_KEY);
      if (lastAuth) {
        const timeSinceAuth = Date.now() - parseInt(lastAuth);
        if (timeSinceAuth < AUTH_TIMEOUT) {
          setIsLocked(false);
          onUnlock?.();
          return;
        }
      }
      setIsLocked(true);
    } catch (error) {
      console.error('[BiometricLock] Recent auth check failed', error);
      setIsLocked(true);
    }
  };

  const authenticate = async () => {
    if (isAuthenticating) return;
    
    setIsAuthenticating(true);
    try {
      // Get supported authentication types
      const supportedTypes = await LocalAuthentication.supportedAuthenticationTypesAsync();
      
      // Configure authentication based on available types
      const authConfig: LocalAuthentication.LocalAuthenticationOptions = {
        promptMessage: 'Authenticate to access El-Biblio',
        fallbackLabel: 'Use Passcode',
        disableDeviceFallback: false,
        cancelLabel: 'Cancel',
      };

      // Adjust prompt based on available biometric type
      if (supportedTypes.includes(LocalAuthentication.AuthenticationType.FACIAL_RECOGNITION)) {
        authConfig.promptMessage = 'Use Face ID to access El-Biblio';
      } else if (supportedTypes.includes(LocalAuthentication.AuthenticationType.FINGERPRINT)) {
        authConfig.promptMessage = 'Use fingerprint to access El-Biblio';
      }

      const result = await LocalAuthentication.authenticateAsync(authConfig);

      if (result.success) {
        await AsyncStorage.setItem(LAST_AUTH_KEY, Date.now().toString());
        setIsLocked(false);
        onUnlock?.();
      } else if (result.warning) {
        console.warn('[BiometricLock] Authentication warning:', result.warning);
        // Don't unlock on warning - user should try again
      } else {
        console.warn('[BiometricLock] Authentication failed or cancelled');
      }
    } catch (error) {
      console.error('[BiometricLock] Authentication error', error);
      // Graceful fallback - unlock on error to prevent lockout
      setIsLocked(false);
      onUnlock?.();
    } finally {
      setIsAuthenticating(false);
    }
  };

  if (!isLocked) {
    return <>{children}</>;
  }

  const styles = StyleSheet.create({
    lockScreen: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: theme.colors.background,
      padding: 24,
    },
    lockTitle: {
      fontSize: 32,
      fontWeight: 'bold',
      color: theme.colors.primary,
      marginBottom: 16,
    },
    lockMessage: {
      fontSize: 16,
      color: theme.colors.text.secondary,
      marginBottom: 32,
      textAlign: 'center',
    },
    unlockButton: {
      paddingHorizontal: 32,
      paddingVertical: 12,
      backgroundColor: theme.colors.primary,
      borderRadius: 8,
    },
    unlockText: {
      color: '#fff',
      fontSize: 16,
      fontWeight: '600',
    },
  });

  return (
    <View style={styles.lockScreen}>
      <Text style={styles.lockTitle}>El-Biblio</Text>
      <Text style={styles.lockMessage}>
        {biometricAvailable 
          ? 'Authenticate to continue' 
          : 'Biometric authentication not available on this device'}
      </Text>
      <TouchableOpacity 
        style={styles.unlockButton} 
        onPress={authenticate}
        disabled={isAuthenticating}
      >
        <Text style={styles.unlockText}>
          {isAuthenticating ? 'Authenticating...' : biometricAvailable ? 'Unlock' : 'Continue'}
        </Text>
      </TouchableOpacity>
    </View>
  );
};

export const enableBiometric = async (): Promise<boolean> => {
  try {
    // Check if device supports biometric authentication
    const compatible = await LocalAuthentication.hasHardwareAsync();
    if (!compatible) {
      console.warn('[BiometricLock] Device does not support biometric authentication');
      return false;
    }

    // Check if user has enrolled biometrics
    const enrolled = await LocalAuthentication.isEnrolledAsync();
    if (!enrolled) {
      console.warn('[BiometricLock] User has not enrolled biometrics');
      return false;
    }

    // Test authentication before enabling
    const testResult = await LocalAuthentication.authenticateAsync({
      promptMessage: 'Test biometric authentication',
      cancelLabel: 'Cancel',
      disableDeviceFallback: true, // Force biometric for test
    });

    if (testResult.success) {
      await AsyncStorage.setItem(BIOMETRIC_ENABLED_KEY, 'true');
      return true;
    } else {
      console.warn('[BiometricLock] Test authentication failed');
      return false;
    }
  } catch (error) {
    console.error('[BiometricLock] Enable failed', error);
    return false;
  }
};

export const disableBiometric = async (): Promise<void> => {
  try {
    await AsyncStorage.setItem(BIOMETRIC_ENABLED_KEY, 'false');
    await AsyncStorage.removeItem(LAST_AUTH_KEY);
  } catch (error) {
    console.error('[BiometricLock] Disable failed', error);
  }
};

export const isBiometricEnabled = async (): Promise<boolean> => {
  try {
    const enabled = await AsyncStorage.getItem(BIOMETRIC_ENABLED_KEY);
    return enabled === 'true';
  } catch (error) {
    return false;
  }
};
