import { bibleBooks } from '@/constants/bibleBooks';

/**
 * Convert internal verse reference (e.g., "K110_5") to user-friendly format
 * Maps book codes to full book names and formats chapter:verse properly
 */
export const formatVerseReference = (reference: string | null | undefined): string => {
  if (!reference) return '';
  
  // Handle cases like "1ES4_39" or "K110_5" - extract book code and chapter:verse
  const match = reference.match(/^([1-3]?[A-Z]+)(\d+)_(\d+)$/);
  if (match) {
    const [, bookCode, chapter, verse] = match;
    
    // Find the book by abbreviation
    const book = bibleBooks.find(b => b.abbreviation === bookCode);
    if (book) {
      return `${book.name} ${chapter}:${verse}`;
    }
  }
  
  // Handle standard "Book Chapter:Verse" format
  const standardMatch = reference.match(/^([1-3]?[A-Z][a-z]+)\s+(\d+):(\d+)$/);
  if (standardMatch) {
    const [, bookName, chapter, verse] = standardMatch;
    return `${bookName} ${chapter}:${verse}`;
  }
  
  // Return original if no transformation needed
  return reference;
};

/**
 * Get book name from abbreviation
 */
export const getBookName = (abbreviation: string): string => {
  const book = bibleBooks.find(b => b.abbreviation === abbreviation);
  return book?.name || abbreviation;
};

/**
 * Get book abbreviation from name
 */
export const getBookAbbreviation = (name: string): string => {
  const book = bibleBooks.find(b => b.name.toLowerCase() === name.toLowerCase());
  return book?.abbreviation || name;
};
