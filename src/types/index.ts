import { BookOpenFeather, Cross, Flame, Heart, HomeLight, IconProps, Leaf, Lightbulb, Scales, Shield } from "@/components/Icons";
import { SharedValue } from "react-native-reanimated";

export type FoundationalVirtue = 'knowledge' | 'humility' | 'faith' | 'love';

export type PreferredTheme = 'sage' | 'ocean' | 'wooden';

// API Enums
export enum UserRole {
  Moderator = 1,
  User = 2,
  Admin = 99
}

// Prayer Requests
export interface PrayerRequest {
  id: string;
  user_id?: string;
  user?: User;
  content: string; // request detail/body
  category?: string;
  visibility?: 'public' | 'community' | 'private';
  prayed_users?: User[];
  prayed_count?: number;
  created_at: string;
  updated_at?: string;
}

export enum ActivityType {
  Create = 1,
  Comment = 2,
  Like = 3
}

export enum UserInteractionType {
  Like = 1,
  Bookmark = 2,
  Vote = 3
}

export enum MatchStatus {
  Pending = 1,
  Matched = 2,
  Expired = 3,
  Cancelled = 4
}

export enum MatchType {
  Unity = 1,
  Diversity = 2,
  Any = 3
}

export enum NotificationType {
  Public = 1,
  User = 2
}

export enum ReflectionType {
  Story = 1,
  Insight = 2
}

// Virtues directly derived from one foundational virtue
export type DerivedVirtues = {
  knowledge: 'wisdom' | 'discernment' | 'prudence'
  humility: 'self-control' | 'self-restraint' | 'patience' | 'gentleness' | 'obedience'
  faith: 'trust' | 'hope' | 'perseverance' | 'courage' | 'fortitude'
  love: 'compassion' | 'kindness' | 'generosity' | 'goodness' | 'selflessness'
}

// Virtues that combine multiple foundational virtues
export type CompoundVirtues = {
  righteousness: ['knowledge', 'faith']
  justice: ['knowledge', 'love']
  joy: ['faith', 'love']
  peace: ['faith', 'love']
  gratitude: ['humility', 'knowledge', 'faith']
  respect: ['humility', 'love']
  honesty: ['knowledge', 'humility']
}

// Helper type to get all derived virtues
export type AllDerivedVirtues = DerivedVirtues[keyof DerivedVirtues]

// Helper type to get all compound virtue names
export type CompoundVirtueNames = keyof CompoundVirtues

// Complete type including all virtues
export type AllVirtues =
  | FoundationalVirtue
  | AllDerivedVirtues
  | CompoundVirtueNames

export type SavedItemType = 'clip' | 'reflection' | 'note' | 'verse';

export interface SavedItem {
  id: string;
  type: SavedItemType;
  content: string;
  theme?: FoundationalVirtue;
  isPinned: boolean;
  savedAt: string;
  reference?: string; // For verses
  author?: User; // For clips and reflections
  context?: string; // Additional context like chat room or thread
}

export interface SavedItemsFilter {
  type?: SavedItem['type'];
  theme?: SavedItem['theme'];
  dateRange?: {
    start: Date;
    end: Date;
  };
  searchQuery?: string;
}

export interface Virtue {
  id: string;
  name: string;
  description: string;
  color_code?: string;
  display_name?: string;
  is_foundational?: boolean;
  userProgress?: VirtueProgress;
  totalUsers?: number;
  scriptureReference?: string;
}

export interface VirtueProgress {
  current_level: number;
  theme_id: string;
  virtue: string;
  level: number;
  total_minutes: number;
  total_points: number;
  total_challenges: number;
  total_levels: number;
}

export interface AppVirtue extends Virtue {
  icon: React.FC<IconProps>;
  color_code: string;
}

export interface Verse {
  id: string;
  text: string;
  reference: string;
  date: string;
  translation: string;
  theme_id?: string;
  theme?: Virtue;
  votes: number;
  likes: number;
  shares: number;
  is_trending: boolean;
  is_active: boolean;
  is_featured: boolean;
  reflections?: Reflection[];
  isLiked?: boolean;
  isVoted?: boolean;
  isBookmarked?: boolean;
  created_at: string;
  updated_at: string;
}

export const FaithTheme: Virtue = {
  id: "3",
  name: "faith",
  display_name: "Faith",
  is_foundational: true,
  description: "Faith is the strength of our belief in the supremacy and omniscience of God, and the confidence that we can trust in God's love and justice and align our attitudes and actions accordingly.",
}

export interface WordHub {
  id: string;
  title: string;
  description: string;
  creator_id: string;
  is_private: boolean;
  access_code: string;
  min_points?: number;
  expires_at: string;
  memberCount: number;
  activeMembers: number; // Currently online/active
  messageCount: number;
  lastMessageTime: string;
  topicCount: number;
  authors: User[]; // Number of shared reflections/content
  isBookmarked: boolean;
  created_at: string;
  updated_at: string;
  deleted_at?: string;
}

export interface ThemeInfo {
  id: FoundationalVirtue;
  title: string;
  description: string;
  color: string;
  summary: string;
  related: string;
  reflection?: string;
  subtitle: string;
  practices: string[];
  Icon: React.FC<IconProps>;
}

export const THEMES: Record<ThemeInfo['id'], ThemeInfo> = {
  knowledge: {
    id: 'knowledge',
    title: 'Knowledge and Wisdom',
    summary: 'Understanding God and His purpose',
    related: "wisdom, discernment, growth",
    subtitle: 'The Foundation',
    description: 'Understanding God and His purpose gives us the wisdom to begin our spiritual journey. When combined with other virtues, it helps us make wise choices, understand others, and grow in discernment.',
    practices: [
      'Read scripture with intention, not just for information',
      'Write down at least one insight a week',
      'Share what you learn with at least one person per week'
    ],
    reflection: "Think about how the suggested verses help you in knowing God and His divine purpose",
    color: '#8B5E3C', // Wooden theme
    Icon: Lightbulb,
  },
  faith: {
    id: 'faith',
    title: 'Faith and Hope',
    summary: 'Trust and courage in God\'s ways',
    related: "trust, hope, perseverance, courage, fortitude",
    subtitle: 'The Strength',
    description: 'Built on knowledge and humility, faith gives us courage and zeal to trust and follow in God\'s ways. It provides the strength to persist in difficulties and the passion and hope to await divine justice and perfection. When combined with other virtues, it produces perseverance, peace, and fortitude.',
    practices: [
      'Say more thanksgiving and virtue seeking prayers than material needs',
      'Take a leap of faith in helping/blessing someone per week',
      'Record/share your testimony of God\'s faithfulness weekly'
    ],
    reflection: "Think about how the suggested verses help you in trusting God and divine justice",
    color: '#4A6FA5', // Ocean theme
    Icon: HomeLight,
  },
  humility: {
    id: 'humility',
    title: 'Humility and Service',
    summary: 'Setting aside ego to learn and grow',
    related: "patience, obedience,gentleness, self-restraint, self-control",
    subtitle: 'The Soil',
    description: 'Once we gain knowledge, humility prepares our hearts to grow. It allows us to set aside our ego, learn from others, and create space for honesty, justice and transformation. Combined with other virtues, it enables patience, gentleness, and self-control.',
    practices: [
      'Listen twice as much as you speak',
      'Acknowledge at least one mistake per week and learn from it',
      'Serve someone without seeking recognition'
    ],
    reflection: "Think about how the suggested verses help you in setting aside your ego for the service and benefit of others",
    color: '#638B6C', // Sage theme
    Icon: Cross,
  },
  love: {
    id: 'love',
    title: 'Love and Selflessness',
    summary: 'Transforming relationships with God and others',
    related: "kindness, generosity, goodness, compassion, selflessness",
    color: '#E15554', // Warm/Love theme
    subtitle: 'The Fullness',
    description: 'Supported by knowledge, humility, and faith, love brings all virtues to their fullness. It transforms our relationships with God and others. Combined with other virtues, it produces joy, kindness, and goodness.',
    practices: [
      'Identify at least one person in need around you per week',
      'Put their needs before your own comfort',
      'Show compassion and/or share your resources with them'
    ],
    reflection: "Think about how the suggested verses help you in loving God and your neighbor",
    Icon: Heart,
  },
};

export interface Note {
  id: string;
  title?: string;
  text?: string;
  excerpt?: string;
  user_id?: string;
  user?: User;
  virtues?: AllVirtues[];
  theme_id?: string;
  theme?: Virtue;
  is_public?: boolean;
  is_featured?: boolean;
  author?: User;
  denomination?: Denomination;
  comments?: Comment[];
  likes?: number;
  shares?: number;
  created_at?: string;
  updated_at?: string;
  isPinned?: boolean;
  color?: string; // For note background tint
}

export interface DailyVerse {
  id: string;
  reference: string;
  text: string;
  votes: number;
  isVoted: boolean;
  translation: string;
  theme: FoundationalVirtue;
  isModerator: boolean;
}

export type DayVerses = {
  date: string;
  moderatorVerses: DailyVerse[];
  userVerses: DailyVerse[];
};

export interface Reflection {
  id: string;
  user_id: string;
  user: User;
  verse_id: string;
  content: string;
  type: ReflectionType;
  icon?: string;
  likes: number;
  shares: number;
  comments: Comment[];
  isLiked: boolean;
  timestamp: string;
  created_at: string;
  updated_at: string;
  deleted_at?: string;
}

export interface Comment {
  id: string;
  user_id: string;
  reflection_id: string;
  parent_id?: string;
  content: string;
  likes: number;
  timestamp: string;
  isLiked: boolean;
  replies?: Comment[];
  created_at: string;
  updated_at: string;
  deleted_at?: string;
}

export interface WordHubMessage {
  id: string;
  message: string;
  created_at: string;
  user: {
    id: string;
    name: string;
    avatar?: string;
  };
}

export interface Denomination {
  id: string;
  name: string;
  color: string;
}

export type DenominationType = 'all' | 'catholic' | 'evangelical' | 'protestant' | 'orthodox' | 'other';

export interface User {
  id: string;
  first_name: string;
  last_name: string;
  avatar: string;
  points: number;
  role: UserRole;
  is_active: boolean;
  primary_language: string;
  email?: string;
  total_active_time?: number;
  last_seen?: string;
  activeChallenges?: Challenge[];
  created_at: string;
  updated_at: string;
  password?: string; // Make password optional for API responses
}

export interface Challenge {
  id: string;
  title: string;
  description: string;
  type: 'virtue' | 'vice';
  mode: 'attitude' | 'action';
  frequency?: 'd' | 'w' | 'm' | 'o';
  category: 'personal' | 'community';
  start_date?: Date | string;
  emoji?: string;
  end_date?: Date | string;
  start_time?: string;
  end_time?: string;
  level?: number;
  top_participants?: User[];//top 5 participants
  total_participants?: number;
  is_active?: boolean;
  is_featured?: boolean;
};

export interface DailyChallenge extends Challenge {
  frequency?: 'd';
  upvotes?: number;
  hasJoined?: boolean;
  hasUpvoted?: boolean;
};

export interface MeditationSession {
  id?: string;
  virtue_id: string;
  user_id?: string;
  duration_minutes: number;
  started_at: string;
  ended_at: string;
}

export interface Activity {
  id: string;
  user_id: string;
  subject_type: string;
  subject_id: string;
  type: ActivityType;
  points_earned: number;
  metadata?: any;
  created_at: string;
  updated_at: string;
}

export interface Bookmark {
  id: number;
  user_id: number;
  bookmarkable_id: number;
  bookmarkable_type: string;
  clip_text?: string;
  created_at: string;
  updated_at: string;
  bookmarkable?: {
    id: number;
    type: 'verse' | 'reflection' | 'note' | 'clip';
    content: string;
    reference?: string;
    theme?: FoundationalVirtue;
    context?: string;
    author?: {
      id: number;
      first_name: string;
      last_name: string;
      avatar: string;
    };
  };
}

export interface UserInteraction {
  id: string;
  user_id: string;
  interactable_type: string;
  interactable_id: string;
  type: UserInteractionType;
  created_at: string;
  updated_at: string;
}

export interface Notification {
  id: string;
  notifiable_type: string;
  notifiable_id: string;
  user_id: string;
  data?: string;
  read_at?: string;
  type?: NotificationType;
  created_at: string;
  updated_at: string;
}

export interface Match {
  id: string;
  user_id: string;
  match_type: MatchType;
  wait_time_minutes: number;
  matched_user_id?: string;
  matched_at?: string;
  expires_at: string;
  status: MatchStatus;
  created_at: string;
  updated_at: string;
}

export interface Language {
  id: string;
  code: string;
  name: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Cache {
  key: string;
  value: string;
  expiration: number;
}

export interface Job {
  id: string;
  queue: string;
  payload: string;
  attempts: number;
  reserved_at?: number;
  available_at: number;
  created_at: number;
}

export type LeaderboardEntry = {
  user: User; // required
  points?: number;
  rank?: number;
  verses_read?: number;
  reflections_count?: number;
  bookmarks_count?: number;
  activities_count?: number;
  points_earned?: number;
};

export interface LeaderboardFilter {
  timeframe: 'daily' | 'weekly' | 'monthly' | 'all';
  virtue?: AllVirtues;
  limit?: number;
}

export interface UserStats {
  totalPoints: number;
  totalReflections: number;
  totalNotes: number;
  totalBookmarks: number;
  totalMeditationMinutes: number;
  totalActiveDays: number;
  currentStreak: number;
  longestStreak: number;
  topVirtues: Array<{
    virtue: AllVirtues;
    points: number;
    level: number;
  }>;
  recentActivity: Activity[];
}

export interface SearchResult {
  verses: Verse[];
  notes: Note[];
  reflections: Reflection[];
  users: User[];
  totalResults: number;
  searchQuery: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    current_page: number;
    from: number;
    last_page: number;
    per_page: number;
    to: number;
    total: number;
  };
}

export type RootStackParamList = {
  Home: undefined | { meditationComplete?: boolean, challenge?: DailyChallenge, pointsEarned?: number };
  ThemeSelector: undefined;
  VerseDetail: { verse: Verse };
  ReflectionDetail: { reflection: Reflection };
  NoteDetail: { noteId: string | number };
  IntroScreen: undefined;
  RegistrationScreen: undefined;
  DailyVersesScreen: undefined;
  NotesScreen: undefined;
  MatchScreen: undefined;
  WordHubsScreen: undefined;
  WordHubDetailScreen: { hubId: string };
  SavedItemsScreen: undefined;
  CommunityScreen: undefined;
  PrayerRequestsScreen: undefined;
  ProfileScreen: undefined;
  DailyChallengeScreen: undefined;
  MeditationScreen: undefined;
  VirtueScreen: undefined;
  GameScreen: undefined;
  LeaderboardScreen: undefined;
  VerseBuilderScreen: undefined;
  VirtueTriviaScreen: undefined;
  VirtueQuizScreen: { virtueId?: string, level?: number };
  QuizDetail: { id: string };
  BibleScreen: {book?: string, chapter?: number, verse?: number};
};

export interface BibleVersion {
  englishName: string;
  tableName: string;
  shortName: string;
  dbFilename: string;
  downloadUrl: string;
  preinstalled: boolean;
}

export interface BibleVerse {
  id: string;
  text: string;
  reference: string;
}

export interface Book {
  name: string;
  abbreviation: string;
  chapters: number;
}

export interface LocalVerseActivity {
  isHighlighted: boolean;
  isBookmarked: boolean;
  interactions: {
    reflectionCount: number;
    commentCount: number;
    likeCount: number;
  };
  likeCount?: number;
  shareCount?: number;
  reflectionCount?: number;
  isLiked?: boolean;
}

export interface VerseActivityMap {
  [verseId: string]: LocalVerseActivity;
}

export interface VerseResult {
  verseID: string;
  verseText: string;
}

export type UserLevel = 'novice' | 'beginner' | 'intermediate' | 'advanced' | 'expert';

export interface VerseMastery {
  userId?: number;
  verseId: string;
  attempts: number;
  correct: number;
  firstAttempt?: number;
  lastAttempt?: number;
  needsReview: boolean;
}

export interface AnimatedProps {
  scrollX: SharedValue<number>;
  index: number;
}

export type GameId = 'verse_builder' | 'virtue_trivia' | 'virtue_quiz' | string;

export interface GameScore {
  id?: string;
  gameId: GameId;
  userId?: string;
  score: number;
  level?: number;
  timeSpent?: number;
  correctAnswers?: number;
  totalQuestions?: number;
  timestamp: string;
}

export interface GameLeaderboard {
  gameId: string;
  entries: Array<{
    userId: string;
    userName: string;
    userAvatar: string;
    score: number;
    rank: number;
    timestamp: string;
  }>;
}

export interface GameState {
  questions: Array<{
    id: string;
    question: string;
    options: string[];
    correctAnswer: string;
    explanation?: string;
    verseReference?: string;
  }>;
  currentQuestionIndex: number;
  score: number;
  streak: number;
  answered: boolean;
  selectedAnswer: string | null;
  correctAnswer: string;
  gameOver: boolean;
  correctAnswersCount: number;
}

export type TimeFilter = 'all' | 'today' | 'week' | 'month';

export type VirtueFilter = 'all' | FoundationalVirtue | AllVirtues;

export interface SignUpData {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  avatar?: string;
  primary_language?: string;
  english_fluency?: number;
  date_of_birth?: string;
  denomination?: DenominationType;
}

export interface LoginResponse {
  token: string;
  user: User;
}

export interface Theme {
  id: string;
  name: string;
  display_name: string;
  color_code: string;
  is_foundational: boolean;
  created_at: string;
  updated_at: string;
}

export interface VIRTUE_NOTES {
  id: string;
  title: string;
  content: string;
  theme_id: FoundationalVirtue;
  denomination?: Denomination;
  author: User;
  likes: number;
  created_at: string;
}

export interface VirtueGroups {
  foundational: {
    name: string;
    virtues: FoundationalVirtue[];
  };
  derived: {
    name: string;
    virtues: AllDerivedVirtues[];
  };
  compound: {
    name: string;
    virtues: CompoundVirtueNames[];
  };
}

export const VirtueGroups: VirtueGroups = {
  foundational: {
    name: 'Foundational Virtues',
    virtues: ['knowledge', 'humility', 'faith', 'love']
  },
  derived: {
    name: 'Derived Virtues',
    virtues: ['wisdom', 'discernment', 'prudence', 'self-control', 'self-restraint', 'patience', 'gentleness', 'obedience', 'trust', 'hope', 'perseverance', 'courage', 'fortitude', 'compassion', 'kindness', 'generosity', 'goodness', 'selflessness']
  },
  compound: {
    name: 'Compound Virtues',
    virtues: ['righteousness', 'justice', 'joy', 'peace', 'gratitude', 'respect', 'honesty']
  }
};

export const DENOMINATIONS: Denomination[] = [
  { id: '1', name: 'Catholic', color: '#E74C3C' },
  { id: '2', name: 'Evangelical', color: '#3498DB' },
  { id: '3', name: 'Protestant', color: '#2ECC71' },
  { id: '4', name: 'Orthodox', color: '#F39C12' },
  { id: '5', name: 'Other', color: '#9B59B6' },
];

export const SCREEN_DIMENSIONS = {
  width: 375,
  height: 812,
};