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
