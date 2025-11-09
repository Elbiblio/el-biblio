export type ReadingPlanPreset = {
  id: string;
  label: string;
  books: string[];
  description: string;
};

export const PLAN_PRESETS: ReadingPlanPreset[] = [
  {
    id: 'gospels',
    label: 'Journey through the Gospels',
    books: ['Matthew', 'Mark', 'Luke', 'John'],
    description: 'Walk with Jesus across the four gospel accounts.',
  },
  {
    id: 'wisdom',
    label: 'Grow in Wisdom',
    books: ['Psalms', 'Proverbs', 'Ecclesiastes'],
    description: 'Sit with songs, proverbs, and reflections for the heart.',
  },
  {
    id: 'grow-in-faith',
    label: 'Grow in Faith',
    books: ['Hebrews', 'Romans', 'Genesis', 'Daniel'],
    description: 'Deepen trust in God through stories of faith and powerful teaching on belief.',
  },
  {
    id: 'grow-in-love',
    label: 'Grow in Love',
    books: ['1 John', '1 Corinthians', 'John', 'Romans'],
    description: 'Learn sacrificial, Christlike love through teaching and the life of Jesus.',
  },
  {
    id: 'grow-in-humility',
    label: 'Grow in Humility',
    books: ['Philippians', 'James', '1 Peter', 'Matthew'],
    description: "Embrace servant-hearted living through Christ's example and apostolic wisdom.",
  },
];

export interface VirtueFocusMeta {
  presetId: string;
  virtue: string;
  displayLabel: string;
  matchTerms: string[];
}

const VIRTUE_FOCUS_MAP: Record<string, VirtueFocusMeta> = {
  wisdom: {
    presetId: 'wisdom',
    virtue: 'Wisdom',
    displayLabel: 'Grow in Wisdom',
    matchTerms: [
      'wisdom',
      'wise',
      'wisely',
      'wisest',
      'insight',
      'understanding',
      'discernment',
      'prudence',
      'knowledge',
      'perception',
    ],
  },
  'grow-in-faith': {
    presetId: 'grow-in-faith',
    virtue: 'Faith',
    displayLabel: 'Grow in Faith',
    matchTerms: [
      'faith',
      'faithful',
      'faithfulness',
      'belief',
      'believe',
      'trust',
      'trusting',
      'confidence',
      'assurance',
      'steadfast',
    ],
  },
  'grow-in-love': {
    presetId: 'grow-in-love',
    virtue: 'Love',
    displayLabel: 'Grow in Love',
    matchTerms: [
      'love',
      'loving',
      'beloved',
      'charity',
      'compassion',
      'affection',
      'kindness',
      'mercy',
      'grace',
      'devotion',
    ],
  },
  'grow-in-humility': {
    presetId: 'grow-in-humility',
    virtue: 'Humility',
    displayLabel: 'Grow in Humility',
    matchTerms: [
      'humble',
      'humility',
      'humbleness',
      'meek',
      'meekness',
      'lowly',
      'lowliness',
      'gentle',
      'gentleness',
      'servant',
    ],
  },
};

export const getVirtueFocusByPresetId = (presetId?: string | null): VirtueFocusMeta | null => {
  if (!presetId) return null;
  return VIRTUE_FOCUS_MAP[presetId] ?? null;
};

export const getVirtueFocusFromPresets = (presetIds?: readonly string[] | null): VirtueFocusMeta | null => {
  if (!presetIds?.length) return null;
  for (const id of presetIds) {
    const meta = getVirtueFocusByPresetId(id);
    if (meta) {
      return meta;
    }
  }
  return null;
};

export const VIRTUE_PRESET_IDS = Object.freeze(Object.keys(VIRTUE_FOCUS_MAP));
