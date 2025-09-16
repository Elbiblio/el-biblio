import { useAuthStore } from '@/stores/StoreProvider';

export const useGuestRestrictions = () => {
  const { isGuest, user } = useAuthStore();

  const restrictions = {
    // Community features
    canComment: !isGuest,
    canPostNotes: !isGuest,
    canJoinCommunityChallenges: !isGuest,
    canViewNotes: !isGuest,
    canViewLearningSpotlights: !isGuest,
    canViewCommunityContent: !isGuest,
    
    // Personal features (allowed for guests)
    canSaveVerses: true,
    canSaveBookmarks: true,
    canPlayGames: true,
    canDoPersonalChallenges: true,
    canMeditate: true,
    canTrackProgress: true,
    
    // Account features
    canUpdateProfile: !isGuest,
    canChangeAvatar: !isGuest,
    canAccessLeaderboard: !isGuest,
  };

  const getRestrictionMessage = (feature: keyof typeof restrictions) => {
    if (!restrictions[feature]) {
      return 'This feature requires a registered account. Please create an account to access this feature.';
    }
    return null;
  };

  const showGuestUpgradePrompt = () => {
    // This could be used to show a modal prompting guests to upgrade
    return {
      title: 'Upgrade Your Account',
      message: 'Create a free account to unlock all features and join the community!',
      features: [
        'Share notes and reflections',
        'Join community challenges',
        'View learning spotlights',
        'Comment and interact with others',
        'Access leaderboards',
      ],
    };
  };

  return {
    isGuest,
    restrictions,
    getRestrictionMessage,
    showGuestUpgradePrompt,
  };
}; 