export type ReadingPlanMode = 'plain' | 'reading_meditation' | 'lectio_divina';

export interface ReadingPlanPhase {
  id: 'reading' | 'meditation' | 'prayer' | 'contemplation';
  label: string;
  minutes: number;
  hint?: string;
}

export const TIME_OPTIONS = [9, 15, 30] as const;
export type DailyTimeOption = typeof TIME_OPTIONS[number];

export const DEFAULT_TIME_PER_DAY: DailyTimeOption = 30;
export const DEFAULT_READING_MODE: ReadingPlanMode = 'plain';

interface ModeConfig {
  id: ReadingPlanMode;
  label: string;
  description: string;
  weights: ReadonlyArray<number>;
  phaseLabels: ReadonlyArray<ReadingPlanPhase['label']>;
  phaseIds: ReadonlyArray<ReadingPlanPhase['id']>;
  hints?: ReadonlyArray<string>;
}

const MODE_CONFIG = {
  plain: {
    id: 'plain',
    label: 'Plain Reading',
    description: 'Focus solely on Scripture reading at a steady pace.',
    weights: [1],
    phaseLabels: ['Reading'],
    phaseIds: ['reading'],
    hints: ['Read with prayer for the teaching of the Holy Spirit.'],
  },
  reading_meditation: {
    id: 'reading_meditation',
    label: 'Reading & Meditation',
    description: 'Blend Scripture reading with quiet reflection afterwards.',
    weights: [2, 3],
    phaseLabels: ['Reading', 'Meditation'],
    phaseIds: ['reading', 'meditation'],
    hints: [
      'Read attentively while praying for the Holy Spirit to read along with you.',
      'Sit quietly, inviting the Spirit to highlight the truth.',
    ],
  },
  lectio_divina: {
    id: 'lectio_divina',
    label: 'Divine Readings (Lectio Divina)',
    description: 'Move through reading, meditation, prayer, and contemplation.',
    weights: [4, 4, 2, 2],
    phaseLabels: ['Reading', 'Meditation', 'Prayer', 'Contemplation'],
    phaseIds: ['reading', 'meditation', 'prayer', 'contemplation'],
    hints: [
      'Read with the intention to be transformed by the Holy Spirit.',
      'Turn key words/verses that stood out gently in your heart.',
      'Respond to God about what you learnt or understood with honest prayer.',
      'Rest quietly in God’s presence, letting His love transform you.',
    ],
  },
} as const satisfies Record<ReadingPlanMode, ModeConfig>;

const allocateMinutes = (totalMinutes: number, weights: ReadonlyArray<number>): number[] => {
  if (totalMinutes <= 0 || !weights.length) {
    return Array(weights.length).fill(0);
  }

  const totalWeight = weights.reduce((acc, weight) => acc + weight, 0);
  const base = weights.map(weight => Math.max(0, Math.floor((totalMinutes * weight) / totalWeight)));
  let allocated = base.reduce((acc, minutes) => acc + minutes, 0);
  let remainder = totalMinutes - allocated;

  let index = 0;
  while (remainder > 0 && base.length) {
    base[index % base.length] += 1;
    remainder -= 1;
    index += 1;
  }

  return base;
};

export const getModeConfig = (mode: ReadingPlanMode): ModeConfig => MODE_CONFIG[mode];

export const getModeLabel = (mode: ReadingPlanMode): string => MODE_CONFIG[mode]?.label ?? 'Reading';

export const getModeDescription = (mode: ReadingPlanMode): string => MODE_CONFIG[mode]?.description ?? '';

export const buildPlanPhases = (mode: ReadingPlanMode, totalMinutes: number): ReadingPlanPhase[] => {
  const config = MODE_CONFIG[mode] ?? MODE_CONFIG.plain;
  const minutesAllocation = allocateMinutes(Math.max(totalMinutes, 1), config.weights);

  return config.phaseIds.map((id, index) => ({
    id,
    label: config.phaseLabels[index] ?? config.phaseLabels[config.phaseLabels.length - 1] ?? 'Reading',
    minutes: minutesAllocation[index] ?? 0,
    hint: config.hints?.[index],
  }));
};

export const getReadingMinutes = (mode: ReadingPlanMode, totalMinutes: number): number => {
  const phases = buildPlanPhases(mode, totalMinutes);
  return phases
    .filter(phase => phase.id === 'reading')
    .reduce((minutes, phase) => minutes + phase.minutes, 0);
};

export const estimateChaptersPerDay = (minutes: number): number => {
  if (minutes <= 0) return 1;
  if (minutes <= 20) return 1;
  if (minutes <= 45) return 2;
  if (minutes <= 75) return 4;
  return Math.max(4, Math.round(minutes / 15));
};

export const getModeSummaryLines = (mode: ReadingPlanMode, minutes: number): string[] => {
  const phases = buildPlanPhases(mode, minutes);
  return phases.map(phase => `${phase.label}: ${phase.minutes} min`);
};

export const READING_MODE_OPTIONS = (
  Object.values(MODE_CONFIG) as ModeConfig[]
).map(config => ({
  id: config.id,
  label: config.label,
  description: config.description,
}));
