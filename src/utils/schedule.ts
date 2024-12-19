import { ThemeInfo, THEMES } from '@/types';
import { useMemo } from 'react';

export const THEME_SCHEDULE = {
  0: 'love',      // Sunday
  1: 'knowledge', // Monday
  2: 'humility',  // Tuesday
  3: 'faith',     // Wednesday
  4: 'love',      // Thursday
  5: 'humility',  // Friday
  6: 'faith',     // Saturday
} as const;

export type DayTheme = typeof THEME_SCHEDULE[keyof typeof THEME_SCHEDULE];

export const useThemeOfDay = (date = new Date()) => {
  return useMemo(() => {
    const dayOfWeek = date.getDay() as keyof typeof THEME_SCHEDULE;
    const themeId = THEME_SCHEDULE[dayOfWeek];
    return THEMES[themeId];
  }, [date]) as ThemeInfo;
};

export const getTomorrowsTheme = (today = new Date()) => {
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  const dayOfWeek = tomorrow.getDay() as keyof typeof THEME_SCHEDULE;
  const themeId = THEME_SCHEDULE[dayOfWeek];
  return THEMES[themeId];
};

export const formatRelativeTime = (timestamp: string): string => {
    const now = new Date();
    const date = new Date(timestamp);
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);
  
    if (diffInSeconds < 60) {
      return 'just now';
    } else if (diffInSeconds < 3600) {
      const minutes = Math.floor(diffInSeconds / 60);
      return `${minutes}m ago`;
    } else if (diffInSeconds < 86400) {
      const hours = Math.floor(diffInSeconds / 3600);
      return `${hours}h ago`;
    } else {
      const days = Math.floor(diffInSeconds / 86400);
      return `${days}d ago`;
    }
  };

export const formatTimeLeft = (expiresAt: string): string => {
    const now = new Date();
    const expiration = new Date(expiresAt);
    const diffInHours = (expiration.getTime() - now.getTime()) / (1000 * 60 * 60);
    
    if (diffInHours < 1) {
      const minutesLeft = Math.max(0, Math.floor(diffInHours * 60));
      return `${minutesLeft}m left`;
    } else if (diffInHours < 24) {
      const hoursLeft = Math.floor(diffInHours);
      return `${hoursLeft}h left`;
    } else {
      const daysLeft = Math.floor(diffInHours / 24);
      return `${daysLeft}d left`;
    }
  };