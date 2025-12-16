import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import { apiClient, endpoints } from '@/api/client';
import AsyncStorage from '@react-native-async-storage/async-storage';

let Constants: any;
try {
  Constants = require('expo-constants');
} catch {
  Constants = null;
}

const TOKEN_STORAGE_KEY = 'push_token_registered';
const DEVICE_ID_KEY = 'device_id';
const PUSH_NOTIFICATION_CHANNEL_ID = 'push-notifications';
const DEFAULT_NOTIFICATION_SOUND = 'bell.wav';

export interface PushTokenRegistration {
  token: string;
  platform: 'ios' | 'android';
  device_id?: string;
}

export class PushNotificationService {
  private static token: string | null = null;
  private static isInitialized = false;

  static async initialize(): Promise<boolean> {
    if (this.isInitialized && this.token) {
      return true;
    }

    try {
      const isDevice = Platform.OS !== 'web';
      if (!isDevice) {
        if (__DEV__) {
          console.warn('[PushNotifications] Push notifications only work on physical devices');
        }
        return false;
      }

      const { status: existingStatus } = await Notifications.getPermissionsAsync();
      let finalStatus = existingStatus;

      if (existingStatus !== 'granted') {
        const { status } = await Notifications.requestPermissionsAsync();
        finalStatus = status;
      }

      if (finalStatus !== 'granted') {
        if (__DEV__) {
          console.warn('[PushNotifications] Failed to get push notification permissions');
        }
        this.isInitialized = true;
        return false;
      }

      try {
        const projectId = Constants?.expoConfig?.extra?.eas?.projectId || Constants?.easConfig?.projectId;
        
        const tokenOptions: { projectId?: string } = {};
        if (projectId) {
          tokenOptions.projectId = projectId;
        } else if (__DEV__) {
          console.warn('[PushNotifications] No Expo project ID found. Push notifications may not work.');
        }

        const tokenData = await Notifications.getExpoPushTokenAsync(tokenOptions);

        if (!tokenData?.data) {
          if (__DEV__) {
            console.error('[PushNotifications] No token data received from Expo');
          }
          this.isInitialized = true;
          return false;
        }

        this.token = tokenData.data;
        this.isInitialized = true;

        await this.ensureNotificationChannel();
        
        if (__DEV__) {
          console.log('[PushNotifications] Token obtained successfully');
        }
        
        return true;
      } catch (error: any) {
        this.isInitialized = true;
        if (__DEV__) {
          console.error('[PushNotifications] Error getting push token:', error?.message || error);
        }
        return false;
      }
    } catch (error: any) {
      this.isInitialized = true;
      if (__DEV__) {
        console.error('[PushNotifications] Initialization error:', error?.message || error);
      }
      return false;
    }
  }

  static async registerWithBackend(token: string, force: boolean = false): Promise<boolean> {
    if (!token) {
      if (__DEV__) {
        console.warn('[PushNotifications] Cannot register: no token available');
      }
      return false;
    }

    try {
      const registeredToken = await AsyncStorage.getItem(TOKEN_STORAGE_KEY);
      
      if (!force && registeredToken === token) {
        if (__DEV__) {
          console.log('[PushNotifications] Token already registered locally, skipping backend call');
        }
        return true;
      }

      const deviceId = await this.getDeviceId();

      const payload: PushTokenRegistration = {
        token,
        platform: Platform.OS === 'ios' ? 'ios' : 'android',
        device_id: deviceId,
      };

      try {
        const response = await apiClient.post(endpoints.notifications.registerDevice, payload);
        
        if (response.success) {
          await AsyncStorage.setItem(TOKEN_STORAGE_KEY, token);
          if (__DEV__) {
            console.log('[PushNotifications] Push token registered successfully with backend');
          }
          return true;
        } else {
          if (__DEV__) {
            console.warn('[PushNotifications] Backend registration returned unsuccessful:', response.message);
          }
          return false;
        }
      } catch (apiError: any) {
        const status = apiError?.response?.status;
        
        if (status === 401 || status === 403) {
          if (__DEV__) {
            console.warn('[PushNotifications] Not authenticated (401/403), will retry when user logs in');
          }
          return false;
        }
        
        if (__DEV__) {
          console.error('[PushNotifications] API error details:', {
            status,
            message: apiError?.response?.data?.message || apiError?.message,
            url: apiError?.config?.url,
          });
        }
        
        return false;
      }
    } catch (error) {
      console.error('[PushNotifications] Failed to register push token:', error);
      return false;
    }
  }

  private static async getDeviceId(): Promise<string> {
    try {
      const stored = await AsyncStorage.getItem(DEVICE_ID_KEY);
      if (stored) return stored;

      const deviceId = `device_${Date.now()}_${Math.random().toString(36).substring(2, 15)}`;
      await AsyncStorage.setItem(DEVICE_ID_KEY, deviceId);
      return deviceId;
    } catch (error) {
      console.error('[PushNotifications] Error getting device ID:', error);
      return `device_${Date.now()}`;
    }
  }

  static async updateToken(force: boolean = false): Promise<boolean> {
    if (!this.isInitialized || !this.token) {
      const initialized = await this.initialize();
      if (!initialized || !this.token) {
        return false;
      }
    }
    
    return await this.registerWithBackend(this.token, force);
  }

  static getCurrentToken(): string | null {
    return this.token;
  }

  static async unregister(): Promise<void> {
    try {
      await AsyncStorage.removeItem(TOKEN_STORAGE_KEY);
      this.token = null;
      this.isInitialized = false;
    } catch (error) {
      console.error('[PushNotifications] Error unregistering:', error);
    }
  }

  static async checkPermissions(): Promise<boolean> {
    try {
      const { status } = await Notifications.getPermissionsAsync();
      return status === 'granted';
    } catch (error) {
      console.error('[PushNotifications] Error checking permissions:', error);
      return false;
    }
  }

  static async requestPermissions(): Promise<boolean> {
    try {
      const { status } = await Notifications.requestPermissionsAsync();
      return status === 'granted';
    } catch (error) {
      console.error('[PushNotifications] Error requesting permissions:', error);
      return false;
    }
  }

  static async ensureNotificationChannel(): Promise<void> {
    if (Platform.OS !== 'android') {
      return;
    }

    try {
      await Notifications.setNotificationChannelAsync(PUSH_NOTIFICATION_CHANNEL_ID, {
        name: 'Push Notifications',
        description: 'Notifications from El-Biblio',
        importance: Notifications.AndroidImportance.HIGH,
        sound: DEFAULT_NOTIFICATION_SOUND,
        enableVibrate: true,
        vibrationPattern: [0, 250, 250, 250],
      });
      if (__DEV__) {
        console.log('[PushNotifications] Notification channel configured');
      }
    } catch (error) {
      console.error('[PushNotifications] Error setting up notification channel:', error);
    }
  }

  static getNotificationChannelId(): string {
    return PUSH_NOTIFICATION_CHANNEL_ID;
  }

  static getDefaultSound(): string {
    return DEFAULT_NOTIFICATION_SOUND;
  }
}

