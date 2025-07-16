import { BookOpenFeather, Cross, Flame, Heart, HomeLight, IconProps, Leaf, Lightbulb, Scales, Shield } from "@/components/Icons";
import { SharedValue } from "react-native-reanimated";

export type FoundationalVirtue = 'knowledge' | 'humility' | 'faith' | 'love';

export type PreferredTheme = 'sage' | 'ocean' | 'wooden';

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
  translation?: string;
  reflections?: Reflection[];
  likes: number;
  votes: number;
  shares: number;
  isLiked?: boolean;
  isVoted?: boolean;
  isBookmarked?: boolean;
  is_trending?: boolean;
  is_featured?: boolean;
  created_at: string;
  theme?: Virtue;
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
  title: string;
  text?: string;
  excerpt?: string;
  user?: User;
  virtues?: AllVirtues[];
  theme?: Virtue;
  theme_id?: string;
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
  randomVerses: DailyVerse[];
};

export interface Reflection {
  id: string;
  user: User;
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


export const CatholicDenomination: Denomination = {
  id: 'catholic',
  name: 'Catholic',
  color: '#9C27B0'
}

export const ProtestantDenomination: Denomination = {
  id: 'protestant',
  name: 'Protestant',
  color: '#2196F3'
}

export const OrthodoxDenomination: Denomination = {
  id: 'orthodox',
  name: 'Orthodox',
  color: '#FF9800'
}

export const EvangelicalDenomination: Denomination = {
  id: 'evangelical',
  name: 'Evangelical',
  color: '#4CAF50'
}

export const OtherDenomination: Denomination = {
  id: 'other',
  name: 'Other',
  color: '#607D8B'
}

export const DENOMINATIONS: Denomination[] = [
    CatholicDenomination,
    ProtestantDenomination,
    OrthodoxDenomination,
    EvangelicalDenomination,
    OtherDenomination
];


export interface User {
  id: string;
  first_name: string;
  last_name: string;
  avatar: string;
  points?: number;
  primary_language?: string;
  preferred_theme?: PreferredTheme;
  date_of_birth?: string;
  denomination?: DenominationType;
  email_verified_at?: string;
  last_seen?: string;
  total_active_time?: number;
  userVirtues?: VirtueProgress[];
  activeChallenges?: Challenge[];
  last_login?: string;
  created_at?: string;
  is_guest?: boolean;
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

export const VirtueGroups = {
  foundational: {
    title: 'Foundational Virtues',
    virtues: ['love', 'faith', 'knowledge', 'humility'] as const,
    icons: { love: THEMES['love'].Icon, faith: THEMES['faith'].Icon, knowledge: THEMES['knowledge'].Icon, humility: THEMES['humility'].Icon }
  },
  derived: {
    title: 'Derived Virtues',
    virtues: [
      'wisdom', 'discernment', 'prudence',
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
  wisdom: ['knowledge', 'wisdom', 'discernment'] as AllVirtues[],
  character: ['humility', 'respect', 'honesty', 'patience', 'self-control', 'self-restraint'] as AllVirtues[],
  strength: ['courage', 'fortitude', 'perseverance', 'hope'] as AllVirtues[],
  love: ['compassion', 'kindness', 'charity', 'selflessness', 'love'] as AllVirtues[],
  spirit: ['faith', 'trust', 'obedience', 'gratitude'] as AllVirtues[],
  fruit: ['peace', 'joy', 'goodness', 'gentleness'] as AllVirtues[],
  society: ['justice', 'righteousness'] as AllVirtues[],
};

export const sampleNotes: Note[] = [
  {
    id: '1',
    title: 'Contemplating Humility',
    text: "Contemplating the virtue of humility today. True humility isn't thinking less of yourself, but thinking of yourself less. It creates space for others to grow and flourish.",
    virtues: ['humility', 'wisdom', 'love'],
    created_at: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
    updated_at: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
    isPinned: true,
    color: '#F5F0FF',
  },
  {
    id: '2',
    title: 'Faith and Courage',
    text: "Faith and courage go hand in hand. When we trust in God's plan, we find the strength to face uncertainties with hope and perseverance.",
    virtues: ['faith', 'courage', 'hope', 'trust'],
    created_at: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
    updated_at: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
    isPinned: false,
    color: '#F0F7FF',
  },
  {
    id: '3',
    title: 'Practicing Gratitude',
    text: "On practicing gratitude: Found joy in the small blessings today. Even in challenges, there's always something to be thankful for.",
    virtues: ['gratitude', 'joy', 'peace'],
    created_at: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
    updated_at: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
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

export const VIRTUES = [
  {
    id: 'love',
    name: 'Love',
    icon: Heart,
    color: '#FF5E7D',
    prompts: [
      "Reflect on a moment when you experienced unconditional love. How did it feel?",
      "Think of someone who challenges you. How might you extend compassion to them today?",
      "Consider how you show love to yourself. Are there ways you could be more gentle with yourself?",
      "Visualize love as a healing energy radiating from your heart. Where in your life does it need to flow?"
    ]
  },
  {
    id: 'courage',
    name: 'Courage',
    icon: Shield,
    color: '#7C5DF9',
    prompts: [
      "Remember a time when you faced a fear. What strength did you discover within yourself?",
      "What challenge in your life right now requires courage to face?",
      "If fear wasn't holding you back, what would you do differently today?",
      "Visualize yourself standing firm in the face of adversity, rooted like a mountain."
    ]
  },
  {
    id: 'patience',
    name: 'Patience',
    icon: Leaf,
    color: '#56C288',
    prompts: [
      "Notice the rhythm of your breath. Can you find peace in this moment of waiting?",
      "Think of a situation that tests your patience. What might you learn by embracing the wait?",
      "Consider how nature demonstrates patience - seeds growing, seasons changing. What wisdom can you apply to your life?",
      "Imagine your frustrations as leaves floating down a stream, carried away by the current."
    ]
  },
  {
    id: 'justice',
    name: 'Justice',
    icon: Scales,
    color: '#EF8F35',
    prompts: [
      "Reflect on what justice means to you personally. How do you embody this value?",
      "Consider a situation where you witnessed injustice. How did it affect you?",
      "How might you use your voice or position to promote fairness in your community?",
      "Visualize a world where justice prevails. What does it look like, and what part can you play?"
    ]
  },
  {
    id: 'wisdom',
    name: 'Wisdom',
    icon: Flame,
    color: '#E63946',
    prompts: [
      "Recall a lesson life has taught you. How has it shaped your decisions?",
      "Think of someone whose wisdom you admire. What qualities make them wise?",
      "Consider a decision you're facing. What would your wisest self advise?",
      "Imagine wisdom as a light illuminating your path. What does it reveal about your journey?"
    ]
  }
];

// Time options for meditation
export const TIME_OPTIONS = [
  { value: 7, label: '7 min' },
  { value: 15, label: '15 min' },
  { value: 40, label: '40 min' }
];

// Challenge templates based on virtues - conforming to DailyChallenge type
export const CHALLENGE_TEMPLATES: Record<string, DailyChallenge[]> = {
  love: [
    {
      id: 'love-1',
      title: "Practice Compassionate Communication",
      description: "When speaking with others today, pause before responding and choose words of kindness and understanding.",
      type: 'virtue',
      mode: 'attitude',
      category: 'personal',
      end_time: "18:00",
    },
    {
      id: 'love-2',
      title: "Send 3 Appreciation Messages",
      description: "Take 15 minutes to write and send heartfelt messages to three people who have positively impacted your life.",
      type: 'virtue',
      mode: 'action',
      category: 'personal',
      end_time: "18:00",
    },
    {
      id: 'love-3',
      title: "Practice Self-Compassion",
      description: "Speak to yourself as you would to a dear friend throughout the day, especially when facing challenges.",
      type: 'virtue',
      mode: 'attitude',
      category: 'personal',
      end_time: "18:00",
      frequency: 'd',
    }
  ],
  courage: [
    {
      id: 'courage-1',
      title: "Have That Difficult Conversation",
      description: "Set aside 15 minutes today to initiate that conversation you've been avoiding, approaching it with honesty and respect.",
      type: 'virtue',
      mode: 'action',
      category: 'personal',
      end_time: "18:00",
    },
    {
      id: 'courage-2',
      title: "Embrace Discomfort Mindset",
      description: "Throughout today, notice when you feel resistance and choose to lean into that feeling rather than away from it.",
      type: 'virtue',
      mode: 'attitude',
      category: 'personal',
      end_time: "18:00",
    },
    {
      id: 'courage-3',
      title: "Share Your True Perspective",
      description: "In your next meeting or conversation, express your authentic viewpoint even if it differs from the majority.",
      type: 'virtue',
      mode: 'action',
      category: 'personal',
      end_time: "18:00",
    }
  ],
  patience: [
    {
      id: 'patience-1',
      title: "Practice Mindful Waiting",
      description: "Whenever you encounter a wait today, take deep breaths and use it as an opportunity for mindfulness rather than frustration.",
      type: 'virtue',
      mode: 'attitude',
      category: 'personal',
      end_time: "19:00",
    },
    {
      id: 'patience-2',
      title: "Listen Without Interrupting",
      description: "In all conversations today, practice listening fully and completely before formulating your response.",
      type: 'virtue',
      mode: 'attitude',
      category: 'personal',
      end_time: "19:00",
    },
    {
      id: 'patience-3',
      title: "Slow Down One Activity",
      description: "Choose one 15-minute activity today to perform at half your normal pace, noticing details you usually miss.",
      type: 'virtue',
      mode: 'action',
      category: 'personal',
      end_time: "19:00",
    }
  ],
  justice: [
    {
      id: 'justice-1',
      title: "Support Ethical Organizations",
      description: "Take 15 minutes to research and support a business or organization that promotes fair practices and equality.",
      type: 'virtue',
      mode: 'action',
      category: 'personal',
      end_time: "19:00",
    },
    {
      id: 'justice-2',
      title: "Advocate for the Unheard",
      description: "Today, speak up when you notice someone's voice or perspective being overlooked or dismissed.",
      type: 'virtue',
      mode: 'attitude',
      category: 'personal',
      end_time: "19:00",
    },
    {
      id: 'justice-3',
      title: "Examine Personal Biases",
      description: "Spend 15 minutes journaling about a bias you may hold and how it affects your interactions with others.",
      type: 'virtue',
      mode: 'action',
      category: 'personal',
      end_time: "19:00",
    }
  ],
  wisdom: [
    {
      id: 'wisdom-1',
      title: "Adopt a Learning Mindset",
      description: "Approach each conversation today as an opportunity to learn something new, especially from those with different perspectives.",
      type: 'virtue',
      mode: 'attitude',
      category: 'personal',
      end_time: "19:00",
    },
    {
      id: 'wisdom-2',
      title: "Reflective Decision Making",
      description: "Before making decisions today, pause and consider how your future self would want you to proceed.",
      type: 'virtue',
      mode: 'attitude',
      category: 'personal',
      end_time: "19:00",
    },
    {
      id: 'wisdom-3',
      title: "Seek Wise Counsel",
      description: "Spend 15 minutes consulting with someone whose wisdom you respect about a current challenge you're facing.",
      type: 'virtue',
      mode: 'action',
      category: 'personal',
      end_time: "19:00",
    }
  ]
};



// Sample data for virtue notes
export const VIRTUE_NOTES: Note[] = [
  {
    id: 'note1',
    title: 'Patience in Modern Times',
    excerpt: 'In our fast-paced world, patience has become increasingly rare yet more valuable than ever...',
    author: {
      id: '1',
      first_name: 'Dr.',
      last_name: 'Johnson',
      avatar: 'https://example.com/avatar1.jpg'
    },
    denomination: ProtestantDenomination,
    theme_id: 'patience',
    likes: 342,
    created_at: '2023-08-15',
  },
  {
    id: 'note2',
    title: 'The Heart of Kindness',
    excerpt: 'Kindness is not merely an action but a reflection of the heart transformed by grace...',
    author: {
      id: '1',
      first_name: 'Fr.',
      last_name: 'Michael Thomas',
      avatar: 'https://example.com/avatar1.jpg'
    },
    denomination: CatholicDenomination,
    theme_id: 'kindness',
    likes: 287,
    created_at: '2023-09-02',
  },
  {
    id: 'note3',
    title: 'Humility: The Foundation of Virtue',
    excerpt: 'Without humility, no other virtue can truly flourish. It is the soil in which all spiritual growth begins...',
    author: {
      id: '1',
      first_name: 'Elder',
      last_name: 'Nikolai',
      avatar: 'https://example.com/avatar1.jpg'
    },
    denomination: OrthodoxDenomination,
    theme_id: 'humility',
    likes: 198,
    created_at: '2023-07-28',
  },
  {
    id: 'note4',
    title: 'Wisdom in the Digital Age',
    excerpt: 'Discerning truth from falsehood requires a wisdom that transcends information overload...',
    author: {
      id: '1',
      first_name: 'Pastor',
      last_name: 'James Wilson',
      avatar: 'https://example.com/avatar1.jpg'
    },
    denomination: EvangelicalDenomination,
    theme_id: 'wisdom',
    likes: 256,
    created_at: '2023-08-30',
  },
  {
    id: 'note5',
    title: 'Patience and Spiritual Growth',
    excerpt: 'The journey of faith requires patience with ourselves and others as we grow in grace...',
    author: {
      id: '1',
      first_name: 'Bishop',
      last_name: 'Robert Greene',
      avatar: 'https://example.com/avatar1.jpg'
    },
    denomination: CatholicDenomination,
    theme_id: 'patience',
    likes: 175,
    created_at: '2023-09-10',
  },
];


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
  ProfileScreen: undefined;
  DailyChallengeScreen: undefined;
  MeditationScreen: undefined;
  VirtueScreen: undefined;
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
}

export interface VerseActivityMap {
  [verseId: string]: LocalVerseActivity;
}

export interface VerseResult {
  verseID: string;
  verseText: string;
}

// Define user levels and corresponding verse constraints
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

export interface Bookmark {
  id: number;
  user_id: number;
  bookmarkable_id: number;
  bookmarkable_type: string;
  is_pinned: boolean;
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