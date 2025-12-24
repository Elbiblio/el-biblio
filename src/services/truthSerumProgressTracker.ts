import AsyncStorage from '@react-native-async-storage/async-storage';
import type { TruthSerumProgress, TruthSerumQuestion } from '@/modules/habitConquestTruthSerumQuestions';
import { calculateProgress } from '@/modules/habitConquestTruthSerumQuestions';

const STORAGE_KEY_PREFIX = 'truth_serum_progress_';

export async function saveTruthSerumProgress(
  vice: string,
  date: string,
  answers: Record<string, number>,
  questions: TruthSerumQuestion[]
): Promise<void> {
  try {
    const { averageScore, categoryAverages } = calculateProgress(answers, questions);
    const progress: TruthSerumProgress = {
      date,
      answers,
      averageScore,
      categoryAverages,
    };
    
    const key = `${STORAGE_KEY_PREFIX}${vice}_${date}`;
    await AsyncStorage.setItem(key, JSON.stringify(progress));
    
    const historyKey = `${STORAGE_KEY_PREFIX}${vice}_history`;
    const historyJson = await AsyncStorage.getItem(historyKey);
    const history: string[] = historyJson ? JSON.parse(historyJson) : [];
    if (!history.includes(date)) {
      history.push(date);
      history.sort();
      await AsyncStorage.setItem(historyKey, JSON.stringify(history));
    }
  } catch (error) {
    console.warn('[truthSerumProgressTracker] Failed to save progress:', error);
  }
}

export async function getTruthSerumProgress(
  vice: string,
  date: string
): Promise<TruthSerumProgress | null> {
  try {
    const key = `${STORAGE_KEY_PREFIX}${vice}_${date}`;
    const json = await AsyncStorage.getItem(key);
    return json ? JSON.parse(json) : null;
  } catch (error) {
    console.warn('[truthSerumProgressTracker] Failed to get progress:', error);
    return null;
  }
}

export async function getTruthSerumHistory(
  vice: string
): Promise<string[]> {
  try {
    const historyKey = `${STORAGE_KEY_PREFIX}${vice}_history`;
    const historyJson = await AsyncStorage.getItem(historyKey);
    return historyJson ? JSON.parse(historyJson) : [];
  } catch (error) {
    console.warn('[truthSerumProgressTracker] Failed to get history:', error);
    return [];
  }
}

export async function getAllTruthSerumProgress(
  vice: string
): Promise<TruthSerumProgress[]> {
  try {
    const history = await getTruthSerumHistory(vice);
    const progressPromises = history.map(date => getTruthSerumProgress(vice, date));
    const progressResults = await Promise.all(progressPromises);
    return progressResults.filter((p): p is TruthSerumProgress => p !== null);
  } catch (error) {
    console.warn('[truthSerumProgressTracker] Failed to get all progress:', error);
    return [];
  }
}

export async function getAttemptNumber(
  vice: string
): Promise<number> {
  try {
    const history = await getTruthSerumHistory(vice);
    return history.length;
  } catch (error) {
    console.warn('[truthSerumProgressTracker] Failed to get attempt number:', error);
    return 0;
  }
}

export async function getPreviousAnswers(
  vice: string
): Promise<Record<string, number> | null> {
  try {
    const allProgress = await getAllTruthSerumProgress(vice);
    if (allProgress.length === 0) return null;
    
    const latest = allProgress[allProgress.length - 1];
    return latest.answers;
  } catch (error) {
    console.warn('[truthSerumProgressTracker] Failed to get previous answers:', error);
    return null;
  }
}

export async function getGrowthTrend(
  vice: string,
  questionId: string,
  days: number = 30
): Promise<Array<{ date: string; score: number }>> {
  try {
    const allProgress = await getAllTruthSerumProgress(vice);
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);
    
    const trend = allProgress
      .filter(p => new Date(p.date) >= cutoffDate)
      .map(p => ({
        date: p.date,
        score: p.answers[questionId] ?? 0,
      }))
      .filter(p => p.score > 0)
      .sort((a, b) => a.date.localeCompare(b.date));
    
    return trend;
  } catch (error) {
    console.warn('[truthSerumProgressTracker] Failed to get growth trend:', error);
    return [];
  }
}

export async function getAverageGrowth(
  vice: string,
  days: number = 30
): Promise<number> {
  try {
    const allProgress = await getAllTruthSerumProgress(vice);
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);
    
    const recentProgress = allProgress
      .filter(p => new Date(p.date) >= cutoffDate)
      .map(p => p.averageScore);
    
    if (recentProgress.length < 2) return 0;
    
    const first = recentProgress[0];
    const last = recentProgress[recentProgress.length - 1];
    return last - first;
  } catch (error) {
    console.warn('[truthSerumProgressTracker] Failed to get average growth:', error);
    return 0;
  }
}

