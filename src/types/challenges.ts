export type ChallengeType = 'virtue' | 'vice';
export type ChallengeCategory = 'personal' | 'community' | 'suggested';

export interface Challenge {
  id: string;
  title: string;
  description?: string;
  type: ChallengeType;
  category: ChallengeCategory;
  progress?: number;
  endTime: string;
  createdAt: string;
  expiresAt: string;
  startDate?: string;
  isCompleted: boolean;
  userId: string;
  isFeatured?: boolean;
  
  // New fields from API
  frequency?: 'd' | 'w' | 'm' | string;
  level?: string;
  points?: number;
  finalPoints?: number;
  
  // For community challenges
  participants?: number;
  participantAvatars?: Array<{
    id: string;
    avatar: string;
    first_name: string;
    last_name: string;
    points?: number;
    role?: string;
    is_active?: boolean;
    primary_language?: string;
    email?: string;
    created_at?: string;
    updated_at?: string;
  }>;
  hasJoined?: boolean;
  
  // Theme/category name from backend
  theme_name?: string;
  
  // For community and suggested challenges
  upvotes?: number;
  hasUpvoted?: boolean;
}

export interface ChallengeStats {
  totalCompleted: number;
  streakDays: number;
  virtuesImproved: string[];
  vicesReduced: string[];
}

export interface ChallengeFilters {
  type?: ChallengeType;
  category?: ChallengeCategory;
  completed?: boolean;
  timeRange?: 'today' | 'week' | 'month' | 'all';
}

export interface DailyChallenge {
  id: string;
  title: string;
  description?: string;
  type: ChallengeType;
  category: ChallengeCategory;
  endTime: string;
  createdAt: string;
  expiresAt: string;
  isCompleted: boolean;
  userId: string;
  participants?: number;
  upvotes?: number;
  hasJoined?: boolean;
  hasUpvoted?: boolean;
}

// Backend payloads (snake_case)
export interface BackendChallenge {
  id: string | number;
  title: string;
  description?: string;
  type?: ChallengeType; // sometimes named `type` in resources
  category?: ChallengeCategory;
  progress?: number;
  end_time?: string;
  created_at?: string;
  expires_at?: string;
  end_date?: string;
  start_date?: string;
  start_time?: string;
  is_completed?: boolean;
  user_id?: string | number;
  participants_count?: number;
  upvotes_count?: number;
  has_upvoted?: boolean;
  is_joined?: boolean;
  is_featured?: boolean;
  completed_at?: string | null;
  // allow extra fields without typing every one
  [key: string]: any;
}

export interface BackendParticipant {
  id: number | string;
  first_name: string;
  last_name: string;
  avatar?: string | null;
  progress?: number;
  joined_at?: string | null;
  completed_at?: string | null;
}

export interface BackendChallengeParticipantsResponse {
  challenge: BackendChallenge;
  participants: BackendParticipant[];
  pagination: {
    current_page: number;
    last_page: number;
    per_page: number;
    total: number;
  };
}
