import { SQLiteDatabase, openDatabaseAsync, deleteDatabaseAsync } from 'expo-sqlite';
import * as FileSystem from 'expo-file-system';
import { BibleVersion, Book } from '@/types';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { bibleBooks } from '@/constants/bibleBooks';
import * as Asset from 'expo-asset';

const bookCodeMap: { [key: string]: string } = {
    'GEN': 'GN', 'EXO': 'EX', 'LEV': 'LV', 'NUM': 'NU', 'DEU': 'DT',
    'JOS': 'JS', 'JDG': 'JG', 'RUT': 'RT', '1SA': 'S1', '2SA': 'S2',
    '1KI': 'K1', '2KI': 'K2', '1CH': 'R1', '2CH': 'R2', 'EZR': 'ER',
    'NEH': 'NH', 'EST': 'ET', 'JOB': 'JB', 'PSA': 'PS', 'PRO': 'PR',
    'ECC': 'EC', 'SNG': 'SS', 'ISA': 'IS', 'JER': 'JR', 'LAM': 'LM',
    'EZK': 'EK', 'DAN': 'DN', 'HOS': 'HS', 'JOL': 'JL', 'AMO': 'AM',
    'OBA': 'OB', 'JON': 'JH', 'MIC': 'MC', 'NAM': 'NM', 'HAB': 'HK',
    'ZEP': 'ZP', 'HAG': 'HG', 'ZEC': 'ZC', 'MAL': 'ML',
    'MAT': 'MT', 'MRK': 'MK', 'LUK': 'LK', 'JHN': 'JN', 'ACT': 'AC',
    'ROM': 'RM', '1CO': 'C1', '2CO': 'C2', 'GAL': 'GL', 'EPH': 'EP',
    'PHP': 'PP', 'COL': 'CL', '1TH': 'H1', '2TH': 'H2', '1TI': 'T1',
    '2TI': 'T2', 'TIT': 'TT', 'PHM': 'PM', 'HEB': 'HB', 'JAS': 'JM',
    '1PE': 'P1', '2PE': 'P2', '1JN': 'J1', '2JN': 'J2', '3JN': 'J3',
    'JUD': 'JD', 'REV': 'RV',
    // Apocrypha
    'TOB': 'TB', 'JDT': 'JT', 'WIS': 'WS', 'SIR': 'SR', 'BAR': 'BR',
    '1MA': 'M1', '2MA': 'M2', '1ES': 'E1', 'MAN': 'PN', 'PS2': 'PA'
  };
  
  export function generateVPLId(bookAbbr: string, chapter: number, verse: number): string {
    const bookCode = bookCodeMap[bookAbbr.toUpperCase()];
    if (!bookCode) throw new Error(`Invalid book abbreviation: ${bookAbbr}`);
    
    return `${bookCode}${chapter}_${verse}`;
  }
  
  export function parseVPLId(vplId: string): { bookAbbr: string, chapter: number, verse: number } {
    const match = vplId.match(/^([A-Za-z]{2})(\d+)_(\d+)$/);
    if (!match) throw new Error('Invalid VPL ID format');
  
    const reverseMap = Object.fromEntries(
      Object.entries(bookCodeMap).map(([k, v]) => [v, k])
    );
  
    const bookCode = match[1].toUpperCase();
    const bookAbbr = reverseMap[bookCode];
    if (!bookAbbr) throw new Error(`Unknown book code: ${bookCode}`);
  
    return {
      bookAbbr,
      chapter: parseInt(match[2], 10),
      verse: parseInt(match[3], 10)
    };
}

const DB_PREFIX = 'bible_';
const CDN_BASE = 'https://api.elbiblio.com/dbs/';

interface VerseResult {
  verseID: string;
  verseText: string;
}

// Define user levels and corresponding verse constraints
type UserLevel = 'novice' | 'beginner' | 'intermediate' | 'advanced' | 'expert';

interface LevelConfig {
  minWords: number;
  maxWords: number;
  books: string[]; // Book abbreviations
}

// Book popularity/familiarity tiers
const popularBooks = ['JHN', 'PSA', 'PRO', 'MAT', 'ROM', 'GEN', 'LUK'];
const familiarBooks = [...popularBooks, 'MRK', 'ACT', '1CO', 'EPH', 'PHP', '1JN', 'REV', 'GAL'];
const moderateBooks = [...familiarBooks, 'EXO', 'ISA', 'HEB', '2CO', '1PE', 'JAM', 'DAN', '1SA', '2TI', 'JOS'];
// All books are available for advanced/expert levels

const levelConfigurations: Record<UserLevel, LevelConfig> = {
  novice: {
    minWords: 5,
    maxWords: 7,
    books: popularBooks
  },
  beginner: {
    minWords: 8,
    maxWords: 10,
    books: familiarBooks
  },
  intermediate: {
    minWords: 11,
    maxWords: 15,
    books: moderateBooks
  },
  advanced: {
    minWords: 16,
    maxWords: 20,
    books: [] // Empty array means all books
  },
  expert: {
    minWords: 5, // Expert can handle any length
    maxWords: 20,
    books: [] // Empty array means all books
  }
};

class BibleDBService {
  private static instances: Map<string, SQLiteDatabase> = new Map();
  private static readonly DEFAULT_VERSION = 'eng_rv_vpl';
  private static isInitialized = false;

  static async initialize(): Promise<void> {
    if (this.isInitialized) return;

    try {
      const sqliteDir = `${FileSystem.documentDirectory}SQLite`;
      const dirInfo = await FileSystem.getInfoAsync(sqliteDir);
      if (!dirInfo.exists) {
        await FileSystem.makeDirectoryAsync(sqliteDir, { intermediates: true });
      }

      const defaultDbPath = `${sqliteDir}/bible_${this.DEFAULT_VERSION}.db`;
      const dbExists = await FileSystem.getInfoAsync(defaultDbPath);
      
      if (!dbExists.exists) {
        try {
          const assets = await Asset.Asset.loadAsync(require('../../assets/bibles/rv.db'));
          const defaultBibleAsset = assets[0];
          if (!defaultBibleAsset?.localUri) {
            throw new Error('Failed to load default Bible asset');
          }
          
          await FileSystem.copyAsync({
            from: defaultBibleAsset.localUri,
            to: defaultDbPath
          });
        } catch (error) {
          console.error('Failed to copy default Bible:', error);
          throw new Error('Failed to copy default Bible database');
        }
      }

      try {
        const versionsJson = await FileSystem.readAsStringAsync(
          FileSystem.documentDirectory + 'versions.json'
        ).catch(async () => {
          const versionAssets = await Asset.Asset.loadAsync(
            require('../../assets/bibles/versions.json')
          );
          const versionsAsset = versionAssets[0];
          
          if (!versionsAsset?.localUri) {
            throw new Error('Failed to load versions asset');
          }

          const content = await FileSystem.readAsStringAsync(versionsAsset.localUri);
          
          await FileSystem.writeAsStringAsync(
            FileSystem.documentDirectory + 'versions.json',
            content
          );
          
          return content;
        });

        const versions: BibleVersion[] = JSON.parse(versionsJson);
        await AsyncStorage.setItem('bibleVersions', JSON.stringify(versions));
      } catch (error) {
        console.error('Failed to load versions:', error);
        // Load fallback versions from constant if available
        const fallbackVersions = [
          {
            englishName: "Revised Version",
            tableName: "eng_rv_vpl",
            downloadUrl: "https://api.elbiblio.com/dbs/rv.db",
            preinstalled: true
          }
        ];
        await AsyncStorage.setItem('bibleVersions', JSON.stringify(fallbackVersions));
      }

      this.isInitialized = true;
    } catch (error) {
      console.error('Failed to initialize Bible database:', error);
      throw new Error('Bible database initialization failed');
    }
  }

  static async getDatabase(version: string): Promise<SQLiteDatabase> {
    if (!this.isInitialized) {
      await this.initialize();
    }

    if (!this.instances.has(version)) {
      const dbName = `${DB_PREFIX}${version}.db`;
      const dbPath = `${FileSystem.documentDirectory}SQLite/${dbName}`;
      
      // Verify database exists
      const dbExists = await FileSystem.getInfoAsync(dbPath);
      if (!dbExists.exists) {
        if (version === this.DEFAULT_VERSION) {
          throw new Error('Default Bible database is missing');
        }
        throw new Error(`Bible version ${version} is not installed`);
      }

      try {
        const db = await openDatabaseAsync(dbName);
        // Verify database integrity
        await db.execAsync('SELECT count(*) FROM sqlite_master');
        this.instances.set(version, db);
      } catch (error) {
        console.error(`Failed to open database ${version}:`, error);
        throw new Error(`Failed to open Bible version ${version}`);
      }
    }

    return this.instances.get(version)!;
  }

  static async recordHistory(entry: {
    type: 'search' | 'verse' | 'navigation';
    version: string;
    book?: Book;
    chapter?: number;
    verse?: number;
    query?: string;
  }): Promise<void> {
    const history = await AsyncStorage.getItem('bibleHistory');
    const historyArray = history ? JSON.parse(history) : [];
    
    const newEntry = {
      ...entry,
      timestamp: Date.now(),
    };

    // Keep only the last 40 entries
    const updatedHistory = [newEntry, ...historyArray.slice(0, 39)];
    await AsyncStorage.setItem('bibleHistory', JSON.stringify(updatedHistory));
  }

  static async installVersion(version: BibleVersion): Promise<void> {
    const dbName = `${DB_PREFIX}${version.tableName}.db`;
    const localUri = `${FileSystem.documentDirectory}SQLite/${dbName}`;
    
    try {
      // Check if already installed
      const fileInfo = await FileSystem.getInfoAsync(localUri);
      if (fileInfo.exists) return;

      // Download database with progress tracking
      const downloadResumable = FileSystem.createDownloadResumable(
        version.downloadUrl,
        localUri,
        {},
        (downloadProgress) => {
          const progress = downloadProgress.totalBytesWritten / downloadProgress.totalBytesExpectedToWrite;
          console.log(`Downloading ${version.englishName}: ${Math.round(progress * 100)}%`);
        }
      );

      const result = await downloadResumable.downloadAsync();
      if (!result?.uri) {
        throw new Error('Download failed');
      }

      // Verify database integrity
      const db = await openDatabaseAsync(dbName);
      await db.execAsync('SELECT count(*) FROM sqlite_master');
      
      // Close the test connection
      await db.closeAsync();
      
      // Clear instance if it exists
      this.instances.delete(version.tableName);

    } catch (error) {
      // Cleanup on failure
      const fileInfo = await FileSystem.getInfoAsync(localUri);
      if (fileInfo.exists) {
        await FileSystem.deleteAsync(localUri);
      }
      console.error(`Failed to install Bible version ${version.englishName}:`, error);
      throw new Error(`Failed to install Bible version ${version.englishName}`);
    }
  }

  static async getVerse(
    version: string,
    bookAbbr: string,
    chapter: number,
    verse: number
  ): Promise<string> {
    const db = await this.getDatabase(version);
    const vplId = generateVPLId(bookAbbr, chapter, verse);
    
    const result = await db.getFirstAsync<{ verseText: string }>(
      `SELECT verseText FROM ${version} WHERE verseID = ?`,
      [vplId]
    );
    
    await this.recordHistory({
        type: 'verse',
        version,
        book: bibleBooks.find(b => b.abbreviation === bookAbbr),
        chapter,
        verse,
      });

    return result?.verseText || '';
  }

  static async searchVerses(
    version: string,
    query: string,
    limit: number = 100
  ): Promise<Array<{ verseID: string; verseText: string }>> {
    const db = await this.getDatabase(version);

    await this.recordHistory({
        type: 'verse',
        version,
        book: undefined,
        chapter: undefined,
        verse: undefined,
        query,

      });

    return db.getAllAsync(
      `SELECT verseID, verseText FROM ${version}
       WHERE verseText LIKE ? 
       ORDER BY canon_order ASC
       LIMIT ?`,
      [`%${query}%`, limit]
    );
  }

  static async getChapter(version: string, book: string, chapter: number): Promise<Array<{verse: number, text: string}>> {
    const db = await this.getDatabase(version);
    
    return db.getAllAsync<{verseID: string, startVerse: string, verseText: string}>(
      `SELECT verseID, startVerse, verseText 
       FROM ${version} 
       WHERE book = ? AND chapter = ? 
       ORDER BY CAST(startVerse AS INTEGER)`,
      [book, chapter]
    ).then(results => 
      results.map(({ startVerse, verseText }) => ({
        verse: parseInt(startVerse, 10),
        text: verseText.trim()
      }))
    );
  }

  static async getInstalledVersions(): Promise<string[]> {
    const dir = `${FileSystem.documentDirectory}SQLite/`;
    const files = await FileSystem.readDirectoryAsync(dir);
    return files
      .filter(f => f.startsWith(DB_PREFIX))
      .map(f => f.replace(DB_PREFIX, ''));
  }

  static async getRandomVerse(version: string = 'eng_rv_vpl'): Promise<VerseResult> {
    try {
      // Get user level from AsyncStorage (default to beginner if not found)
      const userProgressData = await AsyncStorage.getItem('userProgress');
      const userProgress = userProgressData ? JSON.parse(userProgressData) : { level: 'beginner' };
      const userLevel: UserLevel = userProgress.level || 'beginner';
      
      // Get configuration based on user level
      const config = levelConfigurations[userLevel];
      
      const db = await this.getDatabase(version);
      
      // Build the query based on level configuration
      let query = `
        SELECT verseID, verseText FROM ${version}
        WHERE length(verseText) > 10 AND length(verseText) < 200
        AND (length(verseText) - length(replace(verseText, ' ', ''))) + 1 BETWEEN ${config.minWords} AND ${config.maxWords}
      `;
      
      // Add book filter if there are specific books for this level
      if (config.books.length > 0) {
        // Convert book abbreviations to book codes for the database
        const bookCodes = config.books.map(abbr => bookCodeMap[abbr]).filter(Boolean);
        if (bookCodes.length > 0) {
          const bookPlaceholders = bookCodes.map(() => '?').join(',');
          query += ` AND SUBSTR(verseID, 1, 2) IN (${bookPlaceholders})`;
        }
      }
      
      // Add randomization and limit
      query += ' ORDER BY RANDOM() LIMIT 1';
      
      // Execute the query with parameters if needed
      let result: VerseResult | null;
      if (config.books.length > 0) {
        const bookCodes = config.books.map(abbr => bookCodeMap[abbr]).filter(Boolean);
        result = await db.getFirstAsync<VerseResult>(query, bookCodes);
      } else {
        result = await db.getFirstAsync<VerseResult>(query);
      }
      
      // If no result (perhaps due to strict filters), fall back to a more general query
      if (!result) {
        console.log('No verses found for the specified criteria, using fallback query');
        result = await db.getFirstAsync<VerseResult>(
          `SELECT verseID, verseText FROM ${version}
           WHERE length(verseText) > 10 AND length(verseText) < 200
           AND (length(verseText) - length(replace(verseText, ' ', ''))) + 1 BETWEEN 5 AND 20
           ORDER BY RANDOM()
           LIMIT 1`
        );
      }
      
      if (!result) {
        throw new Error('Failed to get random verse');
      }
      
      await this.recordHistory({
        type: 'verse',
        version,
        book: undefined,
        chapter: undefined,
        verse: undefined,
      });
      
      // Log selected verse difficulty for debugging
      const wordCount = (result.verseText.match(/\S+/g) || []).length;
      console.log(`Verse selected for ${userLevel} level: ${result.verseID} (${wordCount} words)`);
      
      return result;
    } catch (error) {
      console.error('Error in getRandomVerse:', error);
      throw error;
    }
  }
}

export default BibleDBService;