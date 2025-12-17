import { BibleVerse, Book, BibleVersion, ScopedVerseParam } from '@/types';
import { ReadingPlanMode, ReadingPlanPhase } from '@/constants/readingPlanModes';
import { HistoryEntry, DailyPhaseProgress } from '@/stores/BibleStore';

export type ScopedViewState = {
  title?: string | null;
  subtitle?: string | null;
  verses: ScopedVerseParam[];
};

export type TestamentFilter = 'all' | 'ot' | 'nt';

export interface BibleScreenState {
  showVersionsModal: boolean;
  refreshing: boolean;
  showHistoryModal: boolean;
  showAdvancedActions: boolean;
  showFontModal: boolean;
  showVerseActions: boolean;
  showComparisonModal: boolean;
  showAIInsights: boolean;
  isPlanSetupVisible: boolean;
  showCompactPlan: boolean;
  planDetailsExpanded: boolean;
  showTimerModal: boolean;
  showMeditationMode: boolean;
  atEnd: boolean;
  builderReminder: string;
  showFloatingProgress: boolean;
  scopedView: ScopedViewState | null;
  showDoneOverlay: boolean;
  testamentFilter: TestamentFilter;
  meditationVerses: Array<{ text: string; reference: string }>;
  insightByKey: Record<string, string>;
}

export interface CreatePlanParams {
  books: string[];
  timePerDay: number;
  readingMode: ReadingPlanMode;
  phases: ReadingPlanPhase[];
  reminderTime?: string;
  presetIds?: string[];
  minChaptersPerDay?: number;
  maxChaptersPerDay?: number;
  readingPaceWpm?: number;
}
