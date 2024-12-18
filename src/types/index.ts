import { SharedValue } from "react-native-reanimated";

export interface Verse {
  verse: string;
  reference: string;
  theme?: 'knowledge' | 'humility' | 'faith' | 'love';
  themeDescription?: 'Knowledge and Wisdom' | 'Humility and Service' | 'Faith and Hope' | 'Love and Selflesness';
  themeDetail?: string;
}

export interface Reflection {
  id: string;
  author: User;
  content: string;
  type: 'story' | 'insight';
  icon: string;
  likes: number;
  comments: Comment[];
  isLiked: boolean;
  timestamp: string;
}

export interface Comment {
  id: string;
  parentId: string | null;
  author: User;
  content: string;
  likes: number;
  timestamp: string;
  isLiked: boolean;
  replies?: Comment[];
}

export interface User {
  id: string;
  first_name: string;
  last_name: string;
  avatar: string;
}

export type RootStackParamList = {
  Home: undefined;
  ThemeSelector: undefined;
  VerseDetail: { verseId: string };
  ReflectionDetail: { reflectionId: string };
  IntroScreen: undefined;
  DailyVersesScreen: undefined;
};

export interface AnimatedProps {
  scrollX: SharedValue<number>;
  index: number;
}