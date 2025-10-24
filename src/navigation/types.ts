import type { RootStackParamList, ScopedVerseParam } from '@/types';

export type { RootStackParamList, ScopedVerseParam };

// If you have tab navigation, you can define its params like this:
export type MainTabParamList = {
  HomeTab: undefined;
  BibleTab: undefined;
  JourneyTab: undefined;
  ProfileTab: undefined;
};

// This allows type checking for navigation props
declare global {
  namespace ReactNavigation {
    interface RootParamList extends RootStackParamList {}
  }
}
