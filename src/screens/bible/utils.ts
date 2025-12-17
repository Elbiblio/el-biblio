import { BibleVerse } from '@/types';
import { parseVPLId } from '@/utils/database';

export const getLocalMidnightMs = (date: Date) => {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d.getTime();
};

export const makeVerseKey = (chapter: number | string | null | undefined, verse: number | string | null | undefined) =>
  `${chapter ?? ''}:${verse ?? ''}`;

export const parseVerseAddress = (verse: BibleVerse, fallbackChapter?: number) => {
  try {
    const { chapter, verse: verseNumber } = parseVPLId(verse.id);
    return { chapter, verse: verseNumber };
  } catch {
    const ref = verse.reference ?? '';
    const refMatch = ref.match(/(\d+):(\d+)/);
    const chapter = refMatch ? Number(refMatch[1]) : fallbackChapter ?? NaN;
    const verseNumber = refMatch ? Number(refMatch[2]) : NaN;
    return { chapter, verse: verseNumber };
  }
};

export const makeSegmentRangeToken = (segment?: { chapterStart?: number | null; chapterEnd?: number | null; verseStart?: number | null; verseEnd?: number | null } | null) => {
  if (!segment) return '';
  const startChapter = segment.chapterStart ?? '';
  const endChapter = segment.chapterEnd ?? segment.chapterStart ?? '';
  const startVerse = segment.verseStart ?? '';
  const endVerse = segment.verseEnd ?? '';
  return `${startChapter}:${startVerse}-${endChapter}:${endVerse}`;
};

export const NEW_TESTAMENT_ABBREVIATIONS = new Set([
  'MAT', 'MRK', 'LUK', 'JHN', 'ACT', 'ROM', '1CO', '2CO', 'GAL', 'EPH',
  'PHP', 'COL', '1TH', '2TH', '1TI', '2TI', 'TIT', 'PHM', 'HEB', 'JAS',
  '1PE', '2PE', '1JN', '2JN', '3JN', 'JUD', 'REV',
]);

export const isNewTestamentAbbr = (abbreviation: string) => 
  NEW_TESTAMENT_ABBREVIATIONS.has(abbreviation.toUpperCase());

export const TESTAMENT_FILTER_KEY = 'bible_testament_filter';

export const formatSegmentLabel = (seg: any) => {
  if (!seg) return 'Next segment';
  const vs = seg.verseStart ?? seg.startVerse ?? seg.start_verse ?? null;
  const ve = seg.verseEnd ?? seg.endVerse ?? seg.end_verse ?? null;
  const sameChapter = (seg.chapterEnd ?? seg.chapterStart) === seg.chapterStart;
  if (vs || ve) {
    if (sameChapter) {
      const right = ve ? `-${ve}` : '';
      const left = vs ? `:${vs}` : '';
      return `${seg.bookName} ${seg.chapterStart}${left}${right}`;
    }
    const left = vs ? `:${vs}` : '';
    const right = ve ? `:${ve}` : '';
    return `${seg.bookName} ${seg.chapterStart}${left}-${seg.chapterEnd}${right}`;
  }
  return `${seg.bookName} ${seg.chapterStart}${(seg.chapterEnd ?? seg.chapterStart) !== seg.chapterStart ? `-${seg.chapterEnd}` : ''}`;
};

export const formatTime = (seconds: number) => {
  const mins = Math.floor(Math.max(0, seconds) / 60);
  const secs = Math.max(0, Math.floor(Math.max(0, seconds) % 60));
  return `${mins}:${String(secs).padStart(2, '0')}`;
};
