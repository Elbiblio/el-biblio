export type ChantId = '10000-reasons' | '10000-reasons-african' | 'be-still-my-soul' | 'soul-of-jesus-sanctify-me' | 'oceans';

export type ChantTrack = {
  id: ChantId;
  label: string;
  voiceKey?: string; // SoundKey
  instrumentalKey?: string; // SoundKey
  cues: string[];
  pauseDurationMs: number;
};

export const CHANT_TRACKS: Record<ChantId, ChantTrack> = {
  '10000-reasons': {
    id: '10000-reasons',
    label: '10,000 Reasons',
    voiceKey: 'db/10000_reasons.mp3',
    instrumentalKey: 'db/10000_reasons_instrumental.mp3',
    cues: ['Bless the Lord, O my soul', 'Worship His holy name'],
    pauseDurationMs: 12000,
  },
  '10000-reasons-african': {
    id: '10000-reasons-african',
    label: '10,000 Reasons (African)',
    voiceKey: 'db/10000_reasons_african.mp3',
    instrumentalKey: 'db/10000_reasons_instrumental.mp3',
    cues: ['Bless the Lord, O my soul', 'Worship His holy name'],
    pauseDurationMs: 12000,
  },
  'be-still-my-soul': {
    id: 'be-still-my-soul',
    label: 'Be Still My Soul',
    voiceKey: 'db/be_still_my_soul.mp3',
    instrumentalKey: 'db/be_still_my_soul_instrumental.mp3',
    cues: ['Be still my soul', 'Wait patiently before God'],
    pauseDurationMs: 14000,
  },
  'soul-of-jesus-sanctify-me': {
    id: 'soul-of-jesus-sanctify-me',
    label: 'Soul of Jesus, Sanctify Me',
    voiceKey: 'db/anima_christi.mp3',
    instrumentalKey: 'db/anima_christi_instrumental.mp3',
    cues: ['Anima Christi, sanctifica me', 'Corpus Christi, salva me'],
    pauseDurationMs: 14000,
  },
  oceans: {
    id: 'oceans',
    label: 'Oceans (Spirit Lead Me)',
    voiceKey: 'db/oceans_voice.mp3',
    instrumentalKey: 'db/oceans_instrumental.mp3',
    cues: ['Spirit lead me', 'Where my trust is without borders'],
    pauseDurationMs: 13000,
  },
};

export const getChantById = (id?: string | null): ChantTrack | null => {
  if (!id) return null;
  const key = id as ChantId;
  return (CHANT_TRACKS as any)[key] || null;
};
