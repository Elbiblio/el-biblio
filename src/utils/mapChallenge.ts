import { Challenge } from '@/types/challenges';
import { BackendChallenge, BackendParticipant } from '@/types/challenges';
import { User } from '@/types';

export const mapChallenge = (b: BackendChallenge): Challenge => {
  const anyB = b as any;
  const challengeId = anyB?.challenge_id ?? anyB?.id;

  const normalizeDateTime = (value: any): string | undefined => {
    if (value === undefined || value === null) {
      return undefined;
    }
    const raw = String(value).trim();
    if (!raw) {
      return undefined;
    }
    if (raw.includes('-') && raw.includes(' ') && !raw.includes('T')) {
      return raw.replace(' ', 'T');
    }
    return raw;
  };

  const endDate = typeof b.end_date === 'string' && b.end_date ? b.end_date : undefined;
  const endDateAsEndOfDay = endDate ? `${endDate}T23:59:59` : undefined;
  const normalizedEndTime = normalizeDateTime(b.end_time);
  const normalizedExpiresAt = normalizeDateTime((b as any).expires_at) || normalizedEndTime || endDateAsEndOfDay || '';

  return {
    id: String(challengeId),
    title: anyB?.title,
    description: anyB?.description,
    type: (b.type as any) || 'virtue',
    category: (b.category as any) || 'personal',
    progress: typeof b.progress === 'number' ? b.progress : undefined,
    endTime: normalizedEndTime || '23:59:59',
    createdAt: normalizeDateTime(b.created_at) || new Date().toISOString(),
    expiresAt: normalizedExpiresAt,
    startDate: b.start_date,
    isCompleted: !!b.is_completed,
    userId: b.user_id !== undefined ? String(b.user_id) : (anyB?.user_id ? String(anyB.user_id) : ''),

    // New fields
    frequency: b.frequency,
    level: b.level,
    points: typeof b.effective_points === 'number' ? b.effective_points : undefined,
    finalPoints: typeof b.final_points === 'number' ? b.final_points : undefined,

    participants: typeof anyB.participants_count === 'number'
      ? anyB.participants_count
      : (typeof anyB.participants === 'number' ? anyB.participants : undefined),
    hasJoined: typeof b.is_joined === 'boolean' ? b.is_joined : undefined,

    upvotes: typeof anyB.upvotes_count === 'number'
      ? anyB.upvotes_count
      : (typeof anyB.upvotes === 'number' ? anyB.upvotes : undefined),
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
