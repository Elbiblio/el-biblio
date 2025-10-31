const VERSE_SHARE_BASE_URL = 'https://elbiblio.com/sharing';
const APP_DOWNLOAD_URL = 'https://elbiblio.com/app';
const GAME_DOWNLOAD_URL = 'https://elbiblio.com/games';

export type VerseShareInfo = {
  text: string;
  reference?: string | null;
  reference_display?: string | null;
  book?: string | null;
  chapter?: number | null;
  verse?: number | null;
};

const slugify = (value: string) =>
  value
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-');

const sanitizePathSegment = (value: string) =>
  value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');

const extractReferenceParts = (reference?: string) => {
  if (!reference) return null;
  const match = reference.match(/^([\dA-Za-z\s]+?)\s+(\d+):(\d{1,3}(?:[-–]\d{1,3})?)/);
  if (!match) return null;

  return {
    book: match[1].trim(),
    chapter: Number(match[2]),
    verseSegment: sanitizePathSegment(match[3]),
  };
};

export const buildVerseShareLink = (verse: VerseShareInfo): string => {
  const directBook = verse.book?.trim() || null;
  const directChapter = verse.chapter ?? null;
  const directVerse = verse.verse != null ? sanitizePathSegment(String(verse.verse)) : null;

  let book = directBook ?? null;
  let chapter = directChapter;
  let verseSegment = directVerse;

  if (!book || !chapter || !verseSegment) {
    const parts = extractReferenceParts(verse.reference_display ?? verse.reference ?? undefined);
    if (parts) {
      book = book ?? parts.book;
      chapter = chapter ?? parts.chapter;
      verseSegment = verseSegment ?? parts.verseSegment;
    }
  }

  if (book && chapter && verseSegment) {
    return `${VERSE_SHARE_BASE_URL}/${slugify(book)}/${chapter}/${verseSegment}`;
  }

  if (book && chapter) {
    return `${VERSE_SHARE_BASE_URL}/${slugify(book)}/${chapter}`;
  }

  if (verse.reference_display || verse.reference) {
    const refSegment = sanitizePathSegment(verse.reference_display || verse.reference || '');
    if (refSegment) {
      return `${VERSE_SHARE_BASE_URL}/${refSegment}`;
    }
  }

  return VERSE_SHARE_BASE_URL;
};

export const formatVerseShareMessage = (verse: VerseShareInfo): string => {
  const shareUrl = buildVerseShareLink(verse);
  const reference = verse.reference_display || verse.reference;
  const base = reference ? `${verse.text} (${reference})` : verse.text;

  return [
    base,
    '',
    `Shared via @elbiblio – read it here: ${shareUrl}`,
    `Download the app: ${APP_DOWNLOAD_URL}`,
  ].join('\n');
};

const parseLinkFromResponse = async (response: Response): Promise<string | null> => {
  const raw = await response.text();
  if (!raw) return null;

  let candidate = raw.trim();

  try {
    const parsed = JSON.parse(candidate);
    candidate =
      parsed?.link ||
      parsed?.url ||
      parsed?.short_link ||
      parsed?.shortLink ||
      parsed?.data?.link ||
      parsed?.data?.url ||
      '';
  } catch {
    // Keep raw candidate if not JSON
  }

  if (typeof candidate === 'string' && candidate.startsWith('http')) {
    return candidate;
  }

  return null;
};

export const requestGameShareLink = async (
  userId: string | number,
  gameIdentifier: string,
  score: number,
): Promise<string | null> => {
  try {
    const url = `https://api.elbiblio.com/game-share/userid/${encodeURIComponent(String(userId))}/${encodeURIComponent(gameIdentifier)}/${encodeURIComponent(String(score))}`;
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
      },
    });

    if (!response.ok) {
      console.warn('Failed to generate game share link', response.status, response.statusText);
      return null;
    }

    return await parseLinkFromResponse(response);
  } catch (error) {
    console.warn('Error generating game share link', error);
    return null;
  }
};

export const formatGameShareMessage = (
  gameName: string,
  score: number,
  shareLink?: string | null,
  options?: { extraLine?: string }
): string => {
  const lines: string[] = [`I just scored ${score} in ${gameName} on elbiblio!`];

  if (options?.extraLine) {
    lines.push(options.extraLine);
  }

  if (shareLink) {
    lines.push(`See my highlights: ${shareLink}`);
    lines.push(`Play now on elbiblio: ${GAME_DOWNLOAD_URL}`);
  } else {
    lines.push(`Join me on elbiblio: ${GAME_DOWNLOAD_URL}`);
  }

  return lines.join('\n');
};

export const getAppDownloadUrl = () => APP_DOWNLOAD_URL;
export const getGameDownloadUrl = () => GAME_DOWNLOAD_URL;
