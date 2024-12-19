import { AllVirtues, THEMES } from '@/types';

// Get the dominant virtue from a list of virtues, prioritizing foundational virtues
export const getDominantVirtue = (virtues: AllVirtues[]): keyof typeof THEMES => {
  const foundationalVirtues = ['love', 'faith', 'knowledge', 'humility'] as const;
  
  // First try to find a foundational virtue
  const dominant = virtues.find(virtue => 
    foundationalVirtues.includes(virtue as typeof foundationalVirtues[number])
  );

  if (dominant) {
    return dominant as keyof typeof THEMES;
  }

  // If no foundational virtue, map to related foundational virtue
  const virtueMap: Record<string, keyof typeof THEMES> = {
    // Knowledge-related
    wisdom: 'knowledge',
    discernment: 'knowledge',
    growth: 'knowledge',
    
    // Humility-related
    'self-control': 'humility',
    'self-restraint': 'humility',
    patience: 'humility',
    gentleness: 'humility',
    obedience: 'humility',
    
    // Faith-related
    trust: 'faith',
    hope: 'faith',
    perseverance: 'faith',
    courage: 'faith',
    fortitude: 'faith',
    
    // Love-related
    compassion: 'love',
    kindness: 'love',
    generosity: 'love',
    goodness: 'love',
    selflessness: 'love',
    
    // Compound virtues default mappings
    righteousness: 'faith',
    justice: 'love',
    joy: 'love',
    peace: 'faith',
    gratitude: 'faith',
    respect: 'humility',
    honesty: 'knowledge'
  };

  return virtueMap[virtues[0]] || 'knowledge';
};

// Get a pastel color based on virtues
export const getNotePastel = (virtues: AllVirtues[]): string => {
  const dominantVirtue = getDominantVirtue(virtues);
  const baseColor = THEMES[dominantVirtue].color;
  
  // Convert hex to RGB
  const r = parseInt(baseColor.slice(1, 3), 16);
  const g = parseInt(baseColor.slice(3, 5), 16);
  const b = parseInt(baseColor.slice(5, 7), 16);
  
  // Lighten to create pastel
  const lighten = (c: number) => Math.floor(((c + 255 * 2) / 3));
  
  return `rgb(${lighten(r)}, ${lighten(g)}, ${lighten(b)})`;
};

const BIBLE_VERSE_PATTERN = /(\d?\s*[A-Za-z]+\s+\d+:\d+(?:-\d+)?)/g;

// Extends markdown parsing with lists and quotes
export const parseMarkdown = (text: string): string => {
  // Handle Bible verse references first
  text = text.replace(BIBLE_VERSE_PATTERN, '«$1»');

  return text
    // Bold
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    // Italic
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    // Underline
    .replace(/\_(.+?)\_/g, '<u>$1</u>')
    // Blockquotes
    .replace(/^>\s(.+)$/gm, '<blockquote>$1</blockquote>')
    // Bible verse quotes (special styling)
    .replace(/«(.+?)»/g, '<span class="verse-reference">$1</span>')
    // Unordered lists
    .replace(/^[-*•]\s(.+)$/gm, '<li>$1</li>')
    // Ordered lists
    .replace(/^\d+\.\s(.+)$/gm, '<li>$1</li>')
    // Group list items
    .replace(/(<li>.*<\/li>)\n/g, '<ul>$1</ul>')
    // Clean up multiple adjacent lists
    .replace(/<\/ul>\n?<ul>/g, '')
    // Line breaks
    .replace(/\n/g, '<br />');
};

// Convert HTML back to markdown
export const htmlToMarkdown = (html: string): string => {
  return html
    .replace(/<strong>(.+?)<\/strong>/g, '**$1**')
    .replace(/<em>(.+?)<\/em>/g, '*$1*')
    .replace(/<u>(.+?)<\/u>/g, '_$1_')
    .replace(/<blockquote>(.+?)<\/blockquote>/g, '> $1')
    .replace(/<span class="verse-reference">(.+?)<\/span>/g, '$1')
    .replace(/<li>(.+?)<\/li>/g, '• $1')
    .replace(/<br \/>/g, '\n')
    .replace(/<\/?ul>/g, '');
};

// Enhanced format help text with new features
export const formatHelpText = `
Formatting Tips:
• Use **text** for bold
• Use *text* for italic
• Use _text_ for underline
• Start a line with > for quotes
• Start a line with • or - for bullet points
• Start a line with 1. for numbered lists
• Bible references (e.g., John 3:16) are auto-detected

Example:
> This is a quote
• This is a bullet point
1. This is a numbered item
John 3:16 will be styled automatically
`.trim();

// Auto-detect verse references in text
export const detectVerseReferences = (text: string): string[] => {
  return text.match(BIBLE_VERSE_PATTERN) || [];
};

// Check if a line should be auto-formatted
export const shouldAutoFormat = (line: string): { type: 'quote' | 'bullet' | 'number' | null; text: string } => {
  if (line.startsWith('>')) {
    return { type: 'quote', text: line.substring(1).trim() };
  }
  if (line.match(/^[-*•]\s/)) {
    return { type: 'bullet', text: line.substring(1).trim() };
  }
  if (line.match(/^\d+\.\s/)) {
    return { type: 'number', text: line.substring(line.indexOf('.') + 1).trim() };
  }
  return { type: null, text: line };
};