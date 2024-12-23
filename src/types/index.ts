import { BookOpenFeather, Cross, Heart, HomeLight, IconProps } from "@/components/Icons";
import { SharedValue } from "react-native-reanimated";

export type FoundationalVirtue = 'knowledge' | 'humility' | 'faith' | 'love';

export type PreferredTheme = 'sage' | 'ocean' | 'wooden';

// Virtues directly derived from one foundational virtue
export type DerivedVirtues = {
  knowledge: 'wisdom' | 'discernment' | 'growth'
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

export interface Verse {
  id: string;
  text: string;
  reference: string;
  translation?: string;
  reflections: Reflection[];
  likes: number;
  shares: number;
  isLiked?: boolean;
  isBookmarked?: boolean;
  trending?: boolean;

  theme?: FoundationalVirtue;
}

const sampleReflections: Reflection[] = [
  {
    id: '1',
    author: {
      id: 'user1',
      first_name: 'Sarah',
      last_name: 'Mitchell',
      avatar: 'https://example.com/avatar1.jpg'
    },
    content: "This verse reminds me that in our most exhausting moments, God provides the strength we need. It's not about our own power, but about trusting in His timing and purposes.",
    timestamp: '2h ago',
    likes: 42,
    type: 'story',
    icon: '✨',
    isLiked: false,
    comments: [
      {
        id: 'comment1',
        parentId: null,
        author: {
          id: 'user2',
          first_name: 'John',
          last_name: 'Doe',
          avatar: 'https://placehold.co/40x40'
        },
        content: "Such a beautiful reminder of God's faithfulness. Thank you for sharing!",
        likes: 15,
        timestamp: '5m ago',
        isLiked: false
      }
    ],
  },
  {
    id: '2',
    author: {
      id: 'user2',
      first_name: 'Alice',
      last_name: 'Johnson',
      avatar: 'https://placehold.co/40x40'
    },
    content: "This verse reminds me that in our most exhausting moments, God provides the strength we need. It's not about our own power, but about trusting in His timing and purposes.",
    timestamp: '6h ago',
    likes: 3,
    type: 'story',
    icon: '✨',
    isLiked: false,
    comments: []
  },
  {
    id: '3',
    author: {
      id: 'user3',
      first_name: 'Bob',
      last_name: 'Manuel',
      avatar: 'https://placehold.co/40x40'
    },
    content: "This verse reminds me that in our most exhausting moments, God provides the strength we need. It's not about our own power, but about trusting in His timing and purposes.",
    timestamp: '8h ago',
    likes: 12,
    type: 'story',
    icon: '✨',
    isLiked: false,
    comments: []
  }
  // Add more reflections here...
];

export const sampleVerse: Verse = {
  id: '1',
  text: "But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint.",
  reference: "Isaiah 40:31",
  translation: "NIV",
  likes: 342,
  reflections: sampleReflections,
  shares: 56,
  theme: 'faith',
  trending: true,
};

export const sampleDailyVerses: Verse[] = [
  {
    id: '1',
    text: "But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint.",
    reference: "Isaiah 40:31",
    translation: "ESV",
    reflections: sampleReflections,
    trending: true,
    likes: 342,
    shares: 27,
    theme: "faith"
  },
  // ... more verses
];

export interface WordHub {
  id: string;
  title: string;
  description: string;
  memberCount: number;
  activeMembers: number; // Currently online/active
  messageCount: number;
  lastMessageTime: string;
  topicCount: number;
  authors: User[]; // Number of shared reflections/content
  isPrivate: boolean;
  code?: string;
  minPoints?: number;
  createdAt: string;
  isBookmarked: boolean;
  expiresAt: string;
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
    Icon: BookOpenFeather,
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
      'Identify at least one person in need around you a week',
      'Put their needs before your own comfort',
      'Show compassion and/or share your resources with them'
    ],
    reflection: "Think about how the suggested verses help you in loving God and your neighbor",
    Icon: Heart,
  },
};

export interface Note {
  id: string;
  title: string;
  content: string;
  virtues: AllVirtues[];
  createdAt: string;
  updatedAt: string;
  isPinned: boolean;
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
  randomVerses: DailyVerse[];
};

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
  preferred_theme?: PreferredTheme;
  date_of_birth?: string;
}

export const VirtueGroups = {
  foundational: {
    title: 'Foundational Virtues',
    virtues: ['love', 'faith', 'knowledge', 'humility'] as const,
    icons: { love: THEMES['love'].Icon, faith: THEMES['faith'].Icon, knowledge: THEMES['knowledge'].Icon, humility: THEMES['humility'].Icon }
  },
  derived: {
    title: 'Derived Virtues',
    virtues: [
      'wisdom', 'discernment', 'growth',
      'self-control', 'patience', 'gentleness',
      'trust', 'hope', 'courage',
      'compassion', 'kindness', 'generosity'
    ] as const
  },
  compound: {
    title: 'Compound Virtues',
    virtues: [
      'righteousness', 'justice', 'joy',
      'peace', 'gratitude', 'respect',
      'honesty'
    ] as const
  }
};

export const VirtueGroupsWorld = {
  wisdom: ['knowledge', 'wisdom', 'discernment', 'growth'] as AllVirtues[],
  character: ['humility', 'respect', 'honesty', 'patience', 'self-control', 'self-restraint'] as AllVirtues[],
  strength: ['courage', 'fortitude', 'perseverance', 'hope'] as AllVirtues[],
  love: ['compassion', 'kindness', 'generosity', 'selflessness', 'love'] as AllVirtues[],
  spirit: ['faith', 'trust', 'obedience', 'gratitude'] as AllVirtues[],
  fruit: ['peace', 'joy', 'goodness', 'gentleness'] as AllVirtues[],
  society: ['justice', 'righteousness'] as AllVirtues[],
};

export const sampleNotes: Note[] = [
  {
    id: '1',
    title: 'Contemplating Humility',
    content: "Contemplating the virtue of humility today. True humility isn't thinking less of yourself, but thinking of yourself less. It creates space for others to grow and flourish.",
    virtues: ['humility', 'wisdom', 'love'],
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
    isPinned: true,
    color: '#F5F0FF',
  },
  {
    id: '2',
    title: 'Faith and Courage',
    content: "Faith and courage go hand in hand. When we trust in God's plan, we find the strength to face uncertainties with hope and perseverance.",
    virtues: ['faith', 'courage', 'hope', 'trust'],
    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
    isPinned: false,
    color: '#F0F7FF',
  },
  {
    id: '3',
    title: 'Practicing Gratitude',
    content: "On practicing gratitude: Found joy in the small blessings today. Even in challenges, there's always something to be thankful for.",
    virtues: ['gratitude', 'joy', 'peace'],
    createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
    isPinned: false,
    color: '#FFF0F0',
  },
];

export const sampleWordHubs: WordHub[] = [
  {
    id: '1',
    title: 'Daily Scripture Reflection',
    description: 'Join us in discussing today\'s verse about faith and perseverance. Share your thoughts and learn from others.',
    memberCount: 156,
    activeMembers: 23,
    messageCount: 234,
    lastMessageTime: new Date(Date.now() - 5 * 60000).toISOString(),
    topicCount: 3,
    authors: [
      {
        id: '1',
        first_name: 'Sarah',
        last_name: 'Mitchell',
        avatar: 'https://example.com/avatar1.jpg'
      },
      {
        id: '2',
        first_name: 'John',
        last_name: 'Doe',
        avatar: 'https://example.com/avatar2.jpg'
      },
      {
        id: '3',
        first_name: 'Alice',
        last_name: 'Johnson',
        avatar: 'https://example.com/avatar3.jpg'
      },
      {
        id: '4',
        first_name: 'Michael',
        last_name: 'Brown',
        avatar: 'https://example.com/avatar4.jpg'
      }
    ],
    isPrivate: false,
    createdAt: new Date(Date.now() - 12 * 60 * 60000).toISOString(),
    isBookmarked: true,
    expiresAt: new Date(Date.now() + 24 * 60 * 60000).toISOString(),
  },
];


// Example data structure for verses - replace with API call
export const sampleCurrentVerses: DayVerses = {
  date: 'Mon, Dec 18',
  moderatorVerses: [
    {
      id: '1',
      reference: 'Proverbs 2:6',
      text: "For the Lord gives wisdom; from his mouth come knowledge and understanding.",
      votes: 245,
      isVoted: true,
      translation: 'NIV',
      theme: 'knowledge',
      isModerator: true,
    },
    // Add one for each theme...
  ],
  randomVerses: [
    {
      id: '5',
      reference: 'Romans 8:28',
      text: "And we know that in all things God works for the good of those who love him.",
      votes: 156,
      isVoted: false,
      translation: 'NIV',
      theme: 'faith',
      isModerator: false,
    },
    // Add one for each theme...
  ],
};
export const sampleUpcomingVerses: DayVerses = {
  date: 'Tues, Dec 19',
  moderatorVerses: [
    {
      id: '1',
      reference: 'Proverbs 2:6',
      text: "For the Lord gives wisdom; from his mouth come knowledge and understanding.",
      votes: 245,
      isVoted: true,
      translation: 'NIV',
      theme: 'knowledge',
      isModerator: true,
    },
    // Add one for each theme...
  ],
  randomVerses: [
    {
      id: '5',
      reference: 'Romans 8:28',
      text: "And we know that in all things God works for the good of those who love him.",
      votes: 156,
      isVoted: false,
      translation: 'NIV',
      theme: 'faith',
      isModerator: false,
    },
    // Add one for each theme...
  ],
};

export type RootStackParamList = {
  Home: undefined;
  ThemeSelector: undefined;
  VerseDetail: { verse: Verse };
  ReflectionDetail: { reflection: Reflection };
  IntroScreen: undefined;
  DailyVersesScreen: undefined;
  MatchScreen: undefined;
  WordHubsScreen: undefined;
  SavedItemsScreen: undefined;
  NotesScreen: undefined;
};

export interface AnimatedProps {
  scrollX: SharedValue<number>;
  index: number;
}