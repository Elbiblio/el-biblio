import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import axios from 'axios';
import { apiClient, endpoints, setUnauthorizedHandler, setTokenCache } from '@/api/client';
import { PushNotificationService } from '@/services/pushNotifications';
import { ReminderSyncService, ReminderTime } from '@/services/reminderSync';
import { cancelDailyVerseReminders, scheduleDailyVerseReminders } from '@/tasks/dailyVerseReminderScheduler';
import { User, UserRole, SignUpData } from '@/types';

export type AuthPromptIntent = 'reauth' | 'guest_signup' | null;

export class AuthStore {
  user: User | null = null;
  token: string | null = null;
  isLoading = false;
  isInitialized = false;
  error: string | null = null;
  isGuest = false;
  isEmailVerified = false;
  userRole: UserRole = UserRole.User;
  private readonly TOKEN_KEY = 'auth_token';
  private readonly USER_KEY = 'user_data';
  private readonly GUEST_CREDENTIALS_KEY = 'guest_credentials';
  // When true, UI should prompt user to login/sign up
  authRequired = false;
  authPromptIntent: AuthPromptIntent = null;
  pendingAuthEmail: string | null = null;

  constructor() {
    // Auto-bind methods to preserve `this` when functions are destructured in components
    makeAutoObservable(this, {}, { autoBind: true });
    // Register a global 401 handler once
    setUnauthorizedHandler(this.handleUnauthorized);
    this.initialize();
  }

  // Small helper to wait for a given time (used for retry backoff)
  private wait = (ms: number) => new Promise<void>(resolve => setTimeout(resolve, ms));

  private setLoading = (loading: boolean) => {
    this.isLoading = loading;
  };

  // Update user's total active time and last seen timestamp
  updateUserTime = async (totalActiveTime: number): Promise<void> => {
    try {
      if (!this.user?.id) throw new Error('User not found');

      const response = await apiClient.put<User>(
        endpoints.users.update(this.user.id),
        {
          last_seen: new Date().toISOString(),
          total_active_time: totalActiveTime,
        }
      );

      runInAction(() => {
        if (response.data) {
          this.setUser({
            ...this.user!,
            last_seen: response.data.last_seen,
            total_active_time: response.data.total_active_time,
          });
        }
      });
    } catch (error) {
      console.error('Time update error:', error);
      // Swallow error to avoid disrupting UX
    }
  };

  // Update user's avatar
  updateAvatar = async (avatarUrl: string): Promise<boolean> => {
    try {
      if (!this.user?.id) throw new Error('User not found');

      const response = await apiClient.put<User>(
        endpoints.users.update(this.user.id),
        { avatar: avatarUrl }
      );

      runInAction(() => {
        if (response.data) {
          this.setUser({
            ...this.user!,
            avatar: response.data.avatar,
          });
        }
      });

      return true;
    } catch (error) {
      console.error('Avatar update error:', error);
      return false;
    }
  };

  // Update user's points (keeps legacy API semantics: adds to current points on server)
  updateUserPoints = async (points: number): Promise<void> => {
    try {
      if (!this.user?.id) throw new Error('User not found');

      // Legacy behavior added provided points to current total on server
      // Preserve for backward compatibility
      const currentPoints = (this.user as any)?.points ?? 0;
      const newTotal = (parseInt(String(currentPoints)) || 0) + (parseInt(String(points)) || 0);

      const response = await apiClient.put<User>(
        endpoints.users.update(this.user.id),
        { points: String(newTotal) }
      );

      runInAction(() => {
        if (response.data) {
          this.setUser({
            ...this.user!,
            points: response.data.points as any,
          });
        }
      });
    } catch (error) {
      console.error('Points update error:', error);
      // Swallow error to avoid disrupting UX
    }
  };

  private setError = (error: string | null) => {
    this.error = error;
  };

  private setUser = (user: User | null) => {
    this.user = user;
    // Our User type doesn't include guest/email verification flags; default safely
    this.isGuest = false;
    this.isEmailVerified = !!user?.email;
    this.userRole = user?.role ?? UserRole.User;
    if (user) {
      AsyncStorage.setItem(this.USER_KEY, JSON.stringify(user));
      this.authPromptIntent = null;
      this.pendingAuthEmail = null;
      this.authRequired = false;
    } else {
      AsyncStorage.removeItem(this.USER_KEY);
    }
  };

  private setToken = (token: string | null) => {
    this.token = token;
    setTokenCache(token);
    if (token) {
      AsyncStorage.setItem(this.TOKEN_KEY, token);
    } else {
      AsyncStorage.removeItem(this.TOKEN_KEY);
    }
  };

  initialize = async () => {
    if (this.isInitialized) return;

    try {
      this.setLoading(true);
      const [token, userData, guestCreds] = await Promise.all([
        AsyncStorage.getItem(this.TOKEN_KEY),
        AsyncStorage.getItem(this.USER_KEY),
        AsyncStorage.getItem(this.GUEST_CREDENTIALS_KEY),
      ]);

      if (token && userData) {
        const user = JSON.parse(userData);
        runInAction(() => {
          this.setToken(token);
          this.setUser(user);
          // Infer guest status from stored credentials
          this.isGuest = !!guestCreds;
          this.isInitialized = true;
        });

        void this.bootstrapNotifications();
      } else if (!token && guestCreds) {
        // Attempt silent guest login to ensure app loads correctly for guest users
        try {
          const { email, password } = JSON.parse(guestCreds);
          const ok = await this.login(email, password);
          if (ok) {
            runInAction(() => {
              this.isGuest = true;
            });
          }
        } catch (e) {
          // If silent guest login fails, leave as unauthenticated; UI may prompt later
          console.warn('Silent guest login failed during initialization');
        }
      }
    } catch (error) {
      console.error('Error initializing auth:', error);
      this.setError('Failed to initialize authentication');
    } finally {
      runInAction(() => {
        this.isLoading = false;
        this.isInitialized = true;
      });
    }
  };

  login = async (email: string, password: string): Promise<boolean> => {
    try {
      this.setLoading(true);
      this.setError(null);

      const response = await apiClient.post<{
        token?: string;
        user?: User;
      }>(endpoints.auth.login, { email, password });

      if (!response.success || !response.data?.token || !response.data?.user) {
        throw new Error(response.message || 'Login failed');
      }

      runInAction(() => {
        this.setToken(response.data!.token!);
        this.setUser(response.data!.user!);
        this.authRequired = false;
      });

      void this.bootstrapNotifications();

      return true;
    } catch (error) {
      this.handleAuthError(error);
      return false;
    } finally {
      this.setLoading(false);
    }
  };

  logout = async (): Promise<void> => {
    try {
      this.setLoading(true);
      // Optional: Call logout endpoint if needed
      // await apiClient.post(endpoints.auth.logout);
      await cancelDailyVerseReminders();
    } catch (error) {
      console.error('Error during logout:', error);
    } finally {
      runInAction(() => {
        this.setToken(null);
        this.setUser(null);
        this.authPromptIntent = null;
        this.pendingAuthEmail = null;
        this.authRequired = false;
        this.setLoading(false);
      });
    }
  };

  signUp = async (data: SignUpData): Promise<boolean> => {
    try {
      this.setLoading(true);
      this.setError(null);

      const response = await apiClient.post<{
        token?: string;
        user?: User;
      }>(endpoints.auth.signup, data);

      if (!response.success) {
        throw new Error(response.message || 'Sign up failed');
      }

      if (response.data?.token && response.data?.user) {
        runInAction(() => {
          this.setToken(response.data!.token!);
          this.setUser(response.data!.user!);
        });
        void this.bootstrapNotifications();
        return true;
      }

      const email = (data as any).email;
      const password = (data as any).password;
      if (!email || !password) {
        throw new Error('Account created, but automatic sign-in failed. Please sign in.');
      }

      const maxLoginAttempts = 2;
      for (let attempt = 1; attempt <= maxLoginAttempts; attempt++) {
        if (attempt > 1) {
          const delay = 400 * Math.pow(2, attempt - 2);
          await this.wait(delay);
        }
        const loggedIn = await this.login(email, password);
        if (loggedIn) {
          return true;
        }
      }

      throw new Error('Account created, but automatic sign-in failed. Please sign in.');
    } catch (error) {
      this.handleAuthError(error);
      return false;
    } finally {
      this.setLoading(false);
    }
  };

  createGuestAccount = async (): Promise<boolean> => {
    try {
      this.setLoading(true);
      this.setError(null);

      // Attempt a few times in case of rare email collisions/validation hiccups
      const attempts = 3;
      let lastError: string | null = null;
      for (let i = 0; i < attempts; i++) {
        const suffix = `${Math.random().toString(36).slice(2, 8)}${Date.now()
          .toString()
          .slice(-4)}`;
        const email = `guest_${suffix}@guest.elbiblio.com`;
        const password = `${Math.random().toString(36).slice(2, 10)}A1!`;

        const payload: SignUpData = {
          email,
          password,
          first_name: 'Guest',
          last_name: suffix,
          primary_language: 'en',
        };

        console.log('[Auth] Attempting guest signup with payload:', payload);

        const response = await apiClient.post<{
          token?: string;
          user?: User;
        }>(endpoints.auth.signup, payload, { headers: { 'X-Anonymous': 'true' } });

        if (!response.success) {
          console.warn('[Auth] Guest signup failure response:', {
            message: response.message,
            errors: response.errors,
            data: response.data,
          });
        }

        // Case A: API returns token + user on signup
        if (response.data?.token && response.data?.user) {
          runInAction(() => {
            this.setToken(response.data!.token!);
            this.setUser(response.data!.user!);
            this.isGuest = true;
          });
          // Persist guest credentials for seamless re-login on 401
          await AsyncStorage.setItem(this.GUEST_CREDENTIALS_KEY, JSON.stringify({ email, password }));
          void this.bootstrapNotifications();
          return true;
        }

        // Case B: API returns only user (no token) -> perform login with generated credentials
        if (response.success) {
          console.info('[Auth] Guest signup succeeded, attempting auto-login for:', email);
          // Persist credentials early so we can retry later even if auto-login fails now
          try {
            await AsyncStorage.setItem(this.GUEST_CREDENTIALS_KEY, JSON.stringify({ email, password }));
          } catch (e) {
            console.warn('[Auth] Failed to persist guest credentials before auto-login attempt');
          }
          // Retry auto-login with exponential backoff to handle transient server errors
          const maxLoginAttempts = 3;
          for (let attempt = 1; attempt <= maxLoginAttempts; attempt++) {
            if (attempt > 1) {
              const delay = 500 * Math.pow(2, attempt - 2); // 500ms, 1000ms
              console.info(`[Auth] Auto-login retry ${attempt}/${maxLoginAttempts} after ${delay}ms`);
              await this.wait(delay);
            }
            const loggedIn = await this.login(email, password);
            if (loggedIn) {
              runInAction(() => {
                this.isGuest = true;
              });
              return true;
            }
          }
          // Signup succeeded but auto-login failed after retries. Avoid creating more accounts.
          // Provide a clear error and stop retrying with new accounts.
          console.warn('[Auth] Auto-login failed after guest signup for:', email);
          lastError = 'Account created, but automatic sign-in failed. Please try again.';
          break;
        }

        // Otherwise, remember error and try next attempt
        lastError = response.message || 'Signup failed';
        if (response.errors) {
          console.log('guest data', payload);
          console.warn('Guest signup validation errors:', response.errors);
        }
      }

      throw new Error(lastError || 'Failed to create guest account');
    } catch (error) {
      console.error('[Auth] Guest signup exception:', error);
      this.handleAuthError(error);
      return false;
    } finally {
      this.setLoading(false);
    }
  };

  private handleAuthError = (error: any) => {
    console.error('Auth error:', error);

    const extractFirstError = (errors?: Record<string, string[]>) => {
      if (!errors) return undefined;
      for (const value of Object.values(errors)) {
        if (Array.isArray(value) && value.length > 0) {
          return value[0];
        }
      }
      return undefined;
    };

    let errorMessage = 'An error occurred during authentication';

    if (axios.isAxiosError(error)) {
      const responseData: any = error.response?.data;
      errorMessage = responseData?.message || error.message || errorMessage;
      const firstValidationError = extractFirstError(responseData?.errors);
      if (firstValidationError) {
        errorMessage = firstValidationError;
      }
    } else if (error && typeof error === 'object') {
      if ('success' in error && error.success === false) {
        const apiError = error as { message?: string; errors?: Record<string, string[]> };
        const firstValidationError = extractFirstError(apiError.errors);
        errorMessage = firstValidationError || apiError.message || errorMessage;
      } else if ('message' in error && typeof (error as any).message === 'string') {
        errorMessage = (error as any).message || errorMessage;
      }
    } else if (typeof error === 'string') {
      errorMessage = error || errorMessage;
    }

    this.setError(errorMessage);
  };

  // Called by API client's 401 interceptor
  private reauthInProgress = false;

  private notificationsBootstrapInProgress = false;

  private resolveDailyVerseReminderTimes = async (userId: string): Promise<ReminderTime[]> => {
    try {
      const remote = await ReminderSyncService.loadFromBackend(userId);
      const daily = remote.find((pref) => pref.reminder_type === 'daily_reminder');
      if (daily?.enabled && Array.isArray(daily.reminder_times) && daily.reminder_times.length) {
        return daily.reminder_times;
      }
    } catch {
      // ignore
    }

    const local = await ReminderSyncService.getLocalReminderState('daily_reminder');
    if (local?.enabled && Array.isArray(local.times) && local.times.length) {
      return local.times;
    }

    return [];
  };

  private bootstrapNotifications = async (): Promise<void> => {
    if (this.notificationsBootstrapInProgress) return;

    const userId = this.user?.id;
    if (!userId) return;

    this.notificationsBootstrapInProgress = true;
    try {
      const didRegisterPush = await PushNotificationService.updateToken(false);

      await ReminderSyncService.syncAllLocalReminders(String(userId));

      if (didRegisterPush) {
        await cancelDailyVerseReminders();
        return;
      }

      const times = await this.resolveDailyVerseReminderTimes(String(userId));
      if (!times.length) {
        return;
      }

      await scheduleDailyVerseReminders(times);
    } catch (error) {
      console.warn('[Auth] Notification bootstrap failed', error);
    } finally {
      this.notificationsBootstrapInProgress = false;
    }
  };
  private handleUnauthorized = async () => {
    if (this.reauthInProgress) return;
    this.reauthInProgress = true;
    const lastEmail = this.user?.email ?? null;
    const wasGuestSession = this.isGuest;
    const hadSession = !!this.token || !!this.user || wasGuestSession;
    const promptForAuth = () => {
      runInAction(() => {
        let intent: AuthPromptIntent = null;
        if (wasGuestSession) {
          intent = 'guest_signup';
        } else if (hadSession) {
          intent = 'reauth';
        } else {
          intent = null;
        }
        this.authPromptIntent = intent;
        this.pendingAuthEmail = wasGuestSession ? null : lastEmail;
        this.setToken(null);
        this.setUser(null);
        this.authRequired = true;
      });
    };
    try {
      // Try silent guest re-login if we have stored credentials
      const credsStr = await AsyncStorage.getItem(this.GUEST_CREDENTIALS_KEY);
      if (credsStr) {
        const { email, password } = JSON.parse(credsStr);
        const ok = await this.login(email, password);
        if (ok) return; // silently recovered
      }

      // No guest creds or re-login failed: clear auth and signal UI to prompt
      promptForAuth();
    } catch (e) {
      promptForAuth();
    } finally {
      this.reauthInProgress = false;
    }
  };

  upgradeGuestAccount = async (
    data: Pick<SignUpData, 'first_name' | 'last_name' | 'email' | 'password' | 'avatar'>
  ): Promise<boolean> => {
    if (!this.user?.id) {
      this.setError('User not found');
      return false;
    }

    try {
      this.setLoading(true);
      this.setError(null);

      const payload: Record<string, string> = {
        first_name: data.first_name.trim(),
        last_name: data.last_name.trim(),
        email: data.email.trim(),
        password: data.password,
      };

      if (data.avatar) {
        payload.avatar = data.avatar;
      }

      const response = await apiClient.put<User>(
        endpoints.users.update(this.user.id),
        payload
      );

      const updatedUser = ((response.data as any)?.data ?? response.data) as User | undefined;

      runInAction(() => {
        const mergedUser: User = {
          ...this.user!,
          first_name: data.first_name.trim(),
          last_name: data.last_name.trim(),
          email: data.email.trim(),
          ...(data.avatar ? { avatar: data.avatar } : {}),
          ...(updatedUser ?? {}),
        };

        this.setUser(mergedUser);
        this.isGuest = false;
      });

      await AsyncStorage.removeItem(this.GUEST_CREDENTIALS_KEY);
      this.authRequired = false;

      return true;
    } catch (error) {
      this.handleAuthError(error);
      return false;
    } finally {
      this.setLoading(false);
    }
  };

  dismissAuthPrompt = () => {
    runInAction(() => {
      this.authRequired = false;
      this.authPromptIntent = null;
      this.pendingAuthEmail = null;
    });
  };

  requestAuthPrompt = (intent: AuthPromptIntent = null, pendingEmail?: string | null) => {
    runInAction(() => {
      this.authPromptIntent = intent;
      this.pendingAuthEmail = pendingEmail ?? null;
      this.authRequired = true;
    });
  };
}

