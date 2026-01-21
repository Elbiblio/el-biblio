import { toast } from 'sonner-native';
import { appState } from '@/utils/appInitialization';
import { APIResponse } from '../types';

class ErrorHandler {
  private lastSessionExpiredToastTime = 0;
  private readonly SESSION_EXPIRED_TOAST_COOLDOWN = 5000; // 5 seconds

  private shouldShowSessionExpiredToast(): boolean {
    const now = Date.now();
    const timeSinceLastToast = now - this.lastSessionExpiredToastTime;

    if (timeSinceLastToast < this.SESSION_EXPIRED_TOAST_COOLDOWN) {
      return false;
    }

    this.lastSessionExpiredToastTime = now;
    return true;
  }

  handleSessionExpired(): void {
    const message = 'Session expired. Please login again.';
    const canShowToast = appState.isInitialized && this.shouldShowSessionExpiredToast();

    if (canShowToast) {
      if (__DEV__) {
        console.log('[ErrorHandler] Showing session expired toast');
      }
      toast.error(message);
    } else {
      if (__DEV__) {
        const now = Date.now();
        const timeSinceLastToast = now - this.lastSessionExpiredToastTime;
        console.log('[ErrorHandler] Suppressing duplicate session expired toast', {
          isInitialized: appState.isInitialized,
          timeSinceLastToast,
        });
      }
    }
  }

  handleValidationError(errors: Record<string, string[]>): void {
    if (!appState.isInitialized || !errors) {
      return;
    }

    const errorMessages: string[] = [];
    Object.values(errors).forEach((messages) => {
      if (Array.isArray(messages)) {
        errorMessages.push(...messages);
      }
    });

    if (errorMessages.length > 0) {
      toast.error(errorMessages[0]);
    }
  }

  handleGenericError(message: string): void {
    if (appState.isInitialized) {
      toast.error(message);
    }
  }
}

export const errorHandler = new ErrorHandler();
