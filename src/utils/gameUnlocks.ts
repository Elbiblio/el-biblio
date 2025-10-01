import { GameId } from '@/types';

export interface GameUnlockRequirement {
  gameId: GameId;
  title: string;
  requiredPoints: number;
  unlockMessage: string;
}

// Progressive unlock system - games unlock one by one
export const GAME_UNLOCK_REQUIREMENTS: GameUnlockRequirement[] = [
  {
    gameId: 'verse_builder',
    title: 'Verse Builder',
    requiredPoints: 0, // Always unlocked (first game)
    unlockMessage: 'Available from the start',
  },
  {
    gameId: 'virtue_trivia',
    title: 'Virtue Trivia',
    requiredPoints: 1000,
    unlockMessage: 'Reach 1,000 points in Verse Builder to unlock',
  },
  {
    gameId: 'virtue_quiz',
    title: 'Virtue Quiz',
    requiredPoints: 2000,
    unlockMessage: 'Reach 2,000 total points to unlock',
  },
  {
    gameId: 'sp_career',
    title: 'Spiritual Career',
    requiredPoints: 3000,
    unlockMessage: 'Reach 3,000 total points to unlock',
  },
];

// SoulForge (Virtue Screen) unlock requirement
export const SOUL_FORGE_UNLOCK_POINTS = 100;

/**
 * Check if a game is unlocked based on user's points
 * @param gameId - The game to check
 * @param verseBuilderPoints - Points from Verse Builder specifically
 * @param totalPoints - Total points across all games
 * @returns true if unlocked
 */
export const isGameUnlocked = (
  gameId: GameId,
  verseBuilderPoints: number,
  totalPoints: number
): boolean => {
  const requirement = GAME_UNLOCK_REQUIREMENTS.find(r => r.gameId === gameId);
  
  if (!requirement) return true; // Unknown games are unlocked by default
  
  // First game (Verse Builder) uses its own points
  if (gameId === 'verse_builder') {
    return verseBuilderPoints >= requirement.requiredPoints;
  }
  
  // Virtue Trivia unlocks based on Verse Builder points
  if (gameId === 'virtue_trivia') {
    return verseBuilderPoints >= requirement.requiredPoints;
  }
  
  // Other games unlock based on total points
  return totalPoints >= requirement.requiredPoints;
};

/**
 * Check if SoulForge (Virtue Screen) is unlocked
 * @param totalPoints - Total points across all games
 * @returns true if unlocked
 */
export const isSoulForgeUnlocked = (totalPoints: number): boolean => {
  return totalPoints >= SOUL_FORGE_UNLOCK_POINTS;
};

/**
 * Get the unlock requirement for a game
 * @param gameId - The game to check
 * @returns The unlock requirement or null if not found
 */
export const getGameUnlockRequirement = (gameId: GameId): GameUnlockRequirement | null => {
  return GAME_UNLOCK_REQUIREMENTS.find(r => r.gameId === gameId) || null;
};

/**
 * Get points needed to unlock next game
 * @param totalPoints - Current total points
 * @param verseBuilderPoints - Current Verse Builder points
 * @returns Object with next game info or null if all unlocked
 */
export const getNextUnlock = (
  totalPoints: number,
  verseBuilderPoints: number
): { game: GameUnlockRequirement; pointsNeeded: number } | null => {
  for (const requirement of GAME_UNLOCK_REQUIREMENTS) {
    if (!isGameUnlocked(requirement.gameId, verseBuilderPoints, totalPoints)) {
      const pointsNeeded = requirement.gameId === 'virtue_trivia'
        ? requirement.requiredPoints - verseBuilderPoints
        : requirement.requiredPoints - totalPoints;
      
      return {
        game: requirement,
        pointsNeeded: Math.max(0, pointsNeeded),
      };
    }
  }
  
  return null; // All games unlocked
};
