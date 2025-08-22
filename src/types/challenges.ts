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
  isCompleted: boolean;
  userId: string;
  
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
