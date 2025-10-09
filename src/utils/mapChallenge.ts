import { Challenge } from '@/types/challenges';
import { BackendChallenge, BackendParticipant } from '@/types/challenges';
import { User } from '@/types';

export const mapChallenge = (b: BackendChallenge): Challenge => {
  return {
    id: String(b.id),
    title: b.title,
    description: b.description,
    type: (b.type as any) || 'virtue',
    category: (b.category as any) || 'personal',
    progress: typeof b.progress === 'number' ? b.progress : undefined,
    endTime: b.end_time || '23:59:59',
    createdAt: b.created_at || new Date().toISOString(),
    expiresAt: b.expires_at || b.end_date || '',
    startDate: b.start_date,
    isCompleted: !!b.is_completed,
    userId: b.user_id !== undefined ? String(b.user_id) : '',

    // New fields
    frequency: b.frequency,
    level: b.level,
    points: typeof b.effective_points === 'number' ? b.effective_points : undefined,
    finalPoints: typeof b.final_points === 'number' ? b.final_points : undefined,

    participants: typeof b.participants_count === 'number' ? b.participants_count : undefined,
    hasJoined: typeof b.is_joined === 'boolean' ? b.is_joined : undefined,

    upvotes: typeof b.upvotes_count === 'number' ? b.upvotes_count : undefined,
    hasUpvoted: typeof b.has_upvoted === 'boolean' ? b.has_upvoted : undefined,
    isFeatured: typeof b.is_featured === 'boolean' ? b.is_featured : undefined,

    // Theme name from backend
    theme_name: typeof b.theme_name === 'string' ? b.theme_name : undefined,

    // participantAvatars are not provided here; leave undefined
  };
};

export const mapParticipantToUser = (p: BackendParticipant): User => {
  return {
    id: String(p.id),
    first_name: p.first_name,
    last_name: p.last_name,
    avatar: p.avatar || undefined,
    // Optional additional User fields left undefined
  } as unknown as User;
};
