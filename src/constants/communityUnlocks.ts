export const COMMUNITY_STAGE_POINTS = {
  stage1: 50,
  stage2: 100,
} as const;

export type CommunityStage = 0 | 1 | 2;

interface CommunityStageParams {
  communityUnlocked?: boolean;
  totalPoints?: number | null;
}

export const deriveCommunityStage = ({
  communityUnlocked,
  totalPoints,
}: CommunityStageParams): CommunityStage => {
  if (communityUnlocked) return 2;
  const points = Number(totalPoints ?? 0);
  if (points >= COMMUNITY_STAGE_POINTS.stage2) return 2;
  if (points >= COMMUNITY_STAGE_POINTS.stage1) return 1;
  return 0;
};
