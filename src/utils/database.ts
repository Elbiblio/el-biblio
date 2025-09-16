import { SQLiteDatabase, openDatabaseAsync, deleteDatabaseAsync } from 'expo-sqlite';
import * as FileSystem from 'expo-file-system';
import { BibleVersion, Book, UserLevel, VerseResult } from '@/types';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { bibleBooks } from '@/constants/bibleBooks';
import * as Asset from 'expo-asset';
import versionsList from '../../assets/bibles/versions.json';

const bookCodeMap: { [key: string]: string } = {
  'GEN': 'GN', 'EXO': 'EX', 'LEV': 'LV', 'NUM': 'NU', 'DEU': 'DT',
  'JOS': 'JS', 'JDG': 'JG', 'RUT': 'RT', '1SA': 'S1', '2SA': 'S2',
  '1KI': 'K1', '2KI': 'K2', '1CH': 'R1', '2CH': 'R2', 'EZR': 'ER',
  'NEH': 'NH', 'EST': 'ET', 'JOB': 'JB', 'PSA': 'PS', 'PRO': 'PR',
  'ECC': 'EC', 'SNG': 'SS', 'ISA': 'IS', 'JER': 'JR', 'LAM': 'LM',
  'EZK': 'EK', 'DAN': 'DN', 'HOS': 'HS', 'JOL': 'JL', 'AMO': 'AM',
  'OBA': 'OB', 'JON': 'JH', 'MIC': 'MC', 'NAM': 'NM', 'HAB': 'HK',
  'ZEP': 'ZP', 'HAG': 'HG', 'ZEC': 'ZC', 'MAL': 'ML',
  'MAT': 'MT', 'MAR': 'MK', 'LUK': 'LK', 'JHN': 'JN', 'ACT': 'AC',
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

interface LevelConfig {
  minWords: number;
  maxWords: number;
  books: string[]; // Book abbreviations
}

// Book popularity/familiarity tiers
const popularBooks = ['JOH', 'PSA', 'PRO', 'MAT', 'ROM', 'GEN', 'LUK'];
const familiarBooks = [...popularBooks, 'MAR', 'ACT', '1CO', 'EPH', 'PHP', '1JN', 'REV', 'GAL'];
const moderateBooks = [...familiarBooks, 'EXO', 'ISA', 'HEB', '2CO', '1PE', 'JAM', 'DAN', '1SA', '2TI', 'JOS'];
// All books are available for advanced/expert levels

const virtueKeywords: Record<string, string[]> = {
  love: ['love', 'loved', 'loving', 'selfless', 'self-giving'],
  faith: ['faith', 'believe', 'trust', 'faithful'],
  hope: ['hope', 'expect', 'trust', 'wait'],
  patience: ['patience', 'patient', 'endure', 'wait'],
  kindness: ['kind', 'kindness', 'gentle', 'compassion'],
  humility: ['humble', 'humility', 'meek', 'lowly'],
  courage: ['courage', 'brave', 'bold', 'fearless'],
  wisdom: ['wisdom', 'wise', 'understanding', 'knowledge'],
  justice: ['justice', 'just', 'righteous', 'fair'],
  temperance: ['temperance', 'self-control', 'moderation', 'restraint'],
};

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
  private static appStateSubscription: any = null;

  static async initialize(): Promise<void> {
    try {
      console.log("Initializing Bible database service...");
      const sqliteDir = `${FileSystem.documentDirectory}SQLite`;
      const dirInfo = await FileSystem.getInfoAsync(sqliteDir);

      if (!dirInfo.exists) {
        console.log(`Creating SQLite directory at: ${sqliteDir}`);
        await FileSystem.makeDirectoryAsync(sqliteDir, { intermediates: true });
      }

      const defaultDbPath = `${sqliteDir}/${DB_PREFIX}${this.DEFAULT_VERSION}.db`;
      const dbExists = await FileSystem.getInfoAsync(defaultDbPath);

      if (!dbExists.exists) {
        console.log(`Default Bible database not found. Copying from assets to: ${defaultDbPath}`);
        try {
          const assets = await Asset.Asset.loadAsync(require('../../assets/bibles/rv.db'));
          const defaultBibleAsset = assets[0];

          if (!defaultBibleAsset?.localUri) {
            throw new Error('Failed to load default Bible asset');
          }

          console.log(`Copying from: ${defaultBibleAsset.localUri} to: ${defaultDbPath}`);
          await FileSystem.copyAsync({
            from: defaultBibleAsset.localUri,
            to: defaultDbPath
          });

          // Verify the file was copied successfully
          const verifyDbExists = await FileSystem.getInfoAsync(defaultDbPath);
          if (!verifyDbExists.exists) {
            throw new Error(`Failed to copy Bible database to: ${defaultDbPath}`);
          }
          console.log("Default Bible database copied successfully");
        } catch (error) {
          console.error('Failed to copy default Bible:', error);
          throw new Error(`Failed to copy default Bible database: ${(error as Error).message}`);
        }
      } else {
        console.log("Default Bible database already exists");
      }

      // Load versions information from bundled JSON (avoid Asset for JSON)
      try {
        const versions: BibleVersion[] = (versionsList as unknown as BibleVersion[]);
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

      // Set up app state monitoring to handle background/foreground transitions
      this.setupAppStateMonitoring();

      this.isInitialized = true;
      console.log("Bible database service initialized successfully");
    } catch (error) {
      this.isInitialized = false;
      console.error('Failed to initialize Bible database:', error);
      throw new Error(`Bible database initialization failed: ${(error as Error).message}`);
    }
  }

  // Setup app state monitoring to handle database connections
  private static setupAppStateMonitoring(): void {
    // Import AppState only if we're in a React Native environment
    try {
      const { AppState } = require('react-native');
      
      // Clear any existing subscription
      if (this.appStateSubscription) {
        this.appStateSubscription.remove();
      }

      // Monitor app state changes
      this.appStateSubscription = AppState.addEventListener('change', (nextAppState: string) => {
        if (nextAppState === 'active') {
          console.log('App has come to the foreground, validating database connections');
          // Validate all connections when app comes to foreground
          this.validateAllConnections();
        } else if (nextAppState === 'background' || nextAppState === 'inactive') {
          console.log('App going to background, clearing database cache');
          // When app goes to background, clear our cached instances
          // We'll reestablish them when needed
          this.instances.clear();
        }
      });
    } catch (error) {
      console.log('AppState monitoring not available in this environment');
    }
  }

  // Validate all database connections
  private static async validateAllConnections(): Promise<void> {
    for (const [version, db] of this.instances.entries()) {
      try {
        // Check if connection is valid with a simple query
        await db.execAsync('SELECT 1');
        console.log(`Database connection for ${version} is valid`);
      } catch (error) {
        console.log(`Database connection for ${version} is invalid, removing from cache`);
        this.instances.delete(version);
      }
    }
  }

  // Validate a specific database connection
  private static async validateConnection(version: string, db: SQLiteDatabase): Promise<boolean> {
    try {
      await db.execAsync('SELECT 1');
      return true;
    } catch (error) {
      console.log(`Database connection for ${version} is invalid`);
      this.instances.delete(version);
      return false;
    }
  }

  // Get database with connection validation and automatic retry
  static async getDatabase(version: string, maxRetries = 2): Promise<SQLiteDatabase> {
    if (!this.isInitialized) {
      await this.initialize();
    }

    // Normalize the version string to remove .db if erroneously included
    const normalizedVersion = version.replace('.db', '');
    
    // Check if we have a cached instance
    if (this.instances.has(normalizedVersion)) {
      const db = this.instances.get(normalizedVersion)!;
      
      // Validate the existing connection before returning it
      try {
        const isValid = await this.validateConnection(normalizedVersion, db);
        if (isValid) {
          return db;
        }
        // If invalid, it was removed from instances, and we'll continue to create a new one
      } catch (error) {
        console.log(`Error validating connection for ${normalizedVersion}, creating new connection`);
        this.instances.delete(normalizedVersion);
        // Continue to create a new connection
      }
    }

    // Need to create a new connection
    let retries = 0;
    while (retries <= maxRetries) {
      try {
        const dbName = `${DB_PREFIX}${normalizedVersion}.db`;
        const dbPath = `${FileSystem.documentDirectory}SQLite/${dbName}`;

        // Verify database exists
        const dbInfo = await FileSystem.getInfoAsync(dbPath);
        if (!dbInfo.exists) {
          // Try to initialize the default version if it's the one being requested
          if (normalizedVersion === this.DEFAULT_VERSION) {
            try {
              console.log(`Attempting to initialize default Bible database at: ${dbPath}`);
              await this.initialize();

              // Check again after initialization attempt
              const dbInfoRetry = await FileSystem.getInfoAsync(dbPath);
              if (!dbInfoRetry.exists) {
                throw new Error(`Default Bible database could not be initialized at: ${dbPath}`);
              }
            } catch (error) {
              console.error('Error during database initialization:', error);
              throw new Error('Default Bible database initialization failed');
            }
          } else {
            throw new Error(`Bible version ${normalizedVersion} is not installed`);
          }
        }

        console.log(`Opening database: ${dbName}`);
        const db = await openDatabaseAsync(dbName);

        // Verify database integrity with better error handling
        try {
          await db.execAsync('SELECT count(*) FROM sqlite_master');
        } catch (integrityError) {
          console.error(`Database integrity check failed for ${normalizedVersion}:`, integrityError);

          // Attempt to recover by deleting and reinstalling
          if (normalizedVersion === this.DEFAULT_VERSION) {
            await db.closeAsync();
            await FileSystem.deleteAsync(dbPath);
            await this.initialize();
            // Try opening again
            return this.getDatabase(normalizedVersion);
          } else {
            throw new Error(`Bible database ${normalizedVersion} is corrupted`);
          }
        }

        // Store the valid connection
        this.instances.set(normalizedVersion, db);
        return db;
      } catch (error) {
        retries++;
        console.error(`Attempt ${retries} failed to open database ${normalizedVersion}:`, error);
        
        if (retries > maxRetries) {
          // If we've exhausted retries, try the default version as a last resort
          if (normalizedVersion !== this.DEFAULT_VERSION) {
            console.log(`All attempts failed, trying default version instead`);
            return this.getDatabase(this.DEFAULT_VERSION);
          } else {
            throw new Error(`Failed to open Bible version ${normalizedVersion} after multiple attempts`);
          }
        }
        
        // Wait a bit before retrying
        await new Promise(resolve => setTimeout(resolve, 200 * retries));
      }
    }

    // This should never be reached due to the throws above, but TypeScript needs it
    throw new Error(`Failed to open Bible version ${normalizedVersion}`);
  }

  // Execute database operation with retry logic
  static async executeWithRetry<T>(
    operation: (db: SQLiteDatabase) => Promise<T>,
    version: string,
    maxRetries = 2
  ): Promise<T> {
    let retries = 0;
    
    while (true) {
      try {
        const db = await this.getDatabase(version);
        return await operation(db);
      } catch (error) {
        retries++;
        const errorMessage = (error as Error).message || 'Unknown error';
        
        // If it's a "closed resource" error, clear the instance and retry
        if (errorMessage.includes('closed resource') && retries <= maxRetries) {
          console.log(`Database closed, retrying operation (attempt ${retries}/${maxRetries})`);
          this.instances.delete(version.replace('.db', ''));
          await new Promise(resolve => setTimeout(resolve, 200 * retries));
          continue;
        }
        
        // For other errors or if we've exhausted retries, throw
        if (retries > maxRetries) {
          throw new Error(`Failed after ${maxRetries} attempts: ${errorMessage}`);
        } else {
          throw error;
        }
      }
    }
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
    const vplId = generateVPLId(bookAbbr, chapter, verse);

    const result = await this.executeWithRetry(async (db) => {
      return db.getFirstAsync<{ verseText: string }>(
        `SELECT verseText FROM ${version.replace('.db', '')} WHERE verseID = ?`,
        [vplId]
      );
    }, version);

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
    const normalizedVersion = version.replace('.db', '');

    await this.recordHistory({
      type: 'verse',
      version,
      book: undefined,
      chapter: undefined,
      verse: undefined,
      query,
    });

    return this.executeWithRetry(async (db) => {
      return db.getAllAsync(
        `SELECT verseID, verseText FROM ${normalizedVersion}
         WHERE verseText LIKE ? 
         ORDER BY canon_order ASC
         LIMIT ?`,
        [`%${query}%`, limit]
      );
    }, version);
  }

  // Get distinct books available for a given version
  static async getAvailableBooks(version: string): Promise<string[]> {
    const normalizedVersion = version.replace('.db', '');
    return this.executeWithRetry(async (db) => {
      const rows = await db.getAllAsync<{ book: string }>(
        `SELECT DISTINCT book FROM ${normalizedVersion} ORDER BY book`
      );
      return rows.map(r => r.book);
    }, version);
  }

  // Get max chapter number for a given book in a given version
  static async getMaxChapter(version: string, bookAbbr: string): Promise<number> {
    const normalizedVersion = version.replace('.db', '');
    return this.executeWithRetry(async (db) => {
      const row = await db.getFirstAsync<{ maxChapter: number }>(
        `SELECT MAX(CAST(chapter AS INTEGER)) AS maxChapter FROM ${normalizedVersion} WHERE book = ?`,
        [bookAbbr]
      );
      return row?.maxChapter || 1;
    }, version);
  }

  static async getChapter(version: string, book: string, chapter: number): Promise<Array<{ verse: number, text: string }>> {
    const normalizedVersion = version.replace('.db', '');

    return this.executeWithRetry(async (db) => {
      const results = await db.getAllAsync<{ verseID: string, startVerse: string, verseText: string }>(
        `SELECT verseID, startVerse, verseText 
         FROM ${normalizedVersion} 
         WHERE book = ? AND chapter = ? 
         ORDER BY CAST(startVerse AS INTEGER)`,
        [book, chapter]
      );
      
      return results.map(({ startVerse, verseText }) => ({
        verse: parseInt(startVerse, 10),
        text: verseText.trim()
      }));
    }, version);
  }

  static async getVersesByVirtue(
    version: string,
    virtue: string,
    count: number = 10
  ): Promise<VerseResult[]> {
    try {
      // Normalize version string to remove .db if included
      const normalizedVersion = version.replace('.db', '');
      
      // Get the keywords for the requested virtue
      const keywords = virtueKeywords[virtue.toLowerCase()];
      if (!keywords || keywords.length === 0) {
        throw new Error(`No keywords defined for virtue: ${virtue}`);
      }

      // Construct the WHERE clause for searching multiple keywords
      const whereClause = keywords.map(() => 'verseText LIKE ?').join(' OR ');
      const queryParams = keywords.map(keyword => `%${keyword}%`);

      // Execute the query to fetch verses with retry logic
      try {
        return await this.executeWithRetry(async (db) => {
          const results = await db.getAllAsync<VerseResult>(
            `SELECT verseID, verseText 
             FROM ${normalizedVersion}
             WHERE ${whereClause}
             ORDER BY RANDOM() 
             LIMIT ?`,
            [...queryParams, count]
          );

          // If no results, try a simpler query with just the virtue name
          if (results.length === 0) {
            console.log(`No results for virtue ${virtue} with keywords, trying simpler query`);
            const simpleResults = await db.getAllAsync<VerseResult>(
              `SELECT verseID, verseText 
               FROM ${normalizedVersion}
               WHERE verseText LIKE ?
               ORDER BY RANDOM() 
               LIMIT ?`,
              [`%${virtue}%`, count]
            );
            
            if (simpleResults.length > 0) {
              return simpleResults;
            }
            
            // Still no results? Try getting random verses as fallback
            console.warn(`No verses found for virtue: ${virtue}, returning random verses instead`);
            return db.getAllAsync<VerseResult>(
              `SELECT verseID, verseText FROM ${normalizedVersion}
               WHERE length(verseText) > 0 
               ORDER BY RANDOM() LIMIT ?`,
              [count]
            );
          }

          return results;
        }, version);
      } catch (error) {
        console.error(`Error executing virtue verse query:`, error);
        
        // Try default version as fallback if different from requested version
        if (normalizedVersion !== this.DEFAULT_VERSION) {
          console.log(`Falling back to default version for virtue verses`);
          return this.getVersesByVirtue(this.DEFAULT_VERSION, virtue, count);
        }
        
        throw error;
      }
    } catch (error) {
      console.error(`Error fetching verses for virtue ${virtue}:`, error);
      throw error;
    }
  }

  static async getInstalledVersions(): Promise<string[]> {
    try {
      const dir = `${FileSystem.documentDirectory}SQLite/`;

      // Ensure the directory exists first
      const dirInfo = await FileSystem.getInfoAsync(dir);
      if (!dirInfo.exists) {
        return [];
      }

      // Get all files in the directory
      const files = await FileSystem.readDirectoryAsync(dir);
      const dbFiles = files.filter(f => f.startsWith(DB_PREFIX) && f.endsWith('.db'));

      // Validate each database file
      const validVersions: string[] = [];

      for (const dbFile of dbFiles) {
        try {
          // Extract version name from filename
          const versionName = dbFile.replace(DB_PREFIX, '').replace('.db', '');

          // Try opening the database to verify it works
          const db = await openDatabaseAsync(dbFile);

          // Perform a simple query to verify database integrity
          await db.execAsync('SELECT count(*) FROM sqlite_master');

          // Close the database
          await db.closeAsync();

          // Add to valid versions if no errors
          validVersions.push(versionName);
        } catch (error) {
          console.log(`Skipping invalid database file: ${dbFile}`, error);
          // Skip this file as it's not a valid database
          continue;
        }
      }

      return validVersions;
    } catch (error) {
      console.error('Error getting installed versions:', error);
      return []; // Return empty array on error
    }
  }

  static async getRandomVerses(version: string = 'eng_rv_vpl', count: number = 40): Promise<VerseResult[]> {
    try {
      // Make sure the version doesn't have .db extension
      const normalizedVersion = version.replace('.db', '');

      // Get user level from AsyncStorage
      const userProgressData = await AsyncStorage.getItem('userProgress');
      const userProgress = userProgressData ? JSON.parse(userProgressData) : { level: 'beginner' };
      const userLevel: UserLevel = userProgress.level || 'beginner';

      // Get configuration based on user level
      const config = levelConfigurations[userLevel];

      // Build query giving preference to verses with a period at the end
      let query = `
        SELECT verseID, verseText FROM ${normalizedVersion}
        WHERE length(verseText) > 10 AND length(verseText) < 200
        AND (length(verseText) - length(replace(verseText, ' ', ''))) + 1 BETWEEN ${config.minWords} AND ${config.maxWords}
      `;

      // Add book filter if there are specific books for this level
      let bookCodes: string[] = [];
      if (config.books.length > 0) {
        // Convert book abbreviations to book codes for the database
        bookCodes = config.books.map(abbr => bookCodeMap[abbr]).filter(Boolean);
        if (bookCodes.length > 0) {
          const bookPlaceholders = bookCodes.map(() => '?').join(',');
          query += ` AND SUBSTR(verseID, 1, 2) IN (${bookPlaceholders})`;
        }
      }

      // Prioritize verses ending with a period
      query += ` ORDER BY CASE WHEN verseText LIKE '%.%' THEN 1 ELSE 2 END, RANDOM() LIMIT ?`;

      // Execute query with retry logic
      return await this.executeWithRetry(async (db) => {
        try {
          let results: VerseResult[];
          
          if (bookCodes.length > 0) {
            results = await db.getAllAsync<VerseResult>(query, [...bookCodes, count]);
          } else {
            results = await db.getAllAsync<VerseResult>(query, [count]);
          }

          if (results.length === 0) {
            // Try a simpler fallback query if no results
            console.log("No results with primary query, using simpler fallback");
            results = await db.getAllAsync<VerseResult>(
              `SELECT verseID, verseText FROM ${normalizedVersion}
               WHERE length(verseText) > 0 
               ORDER BY RANDOM() LIMIT ?`,
              [count]
            );
          }

          return results;
        } catch (error) {
          console.error(`Error executing batch verse query:`, error);
          
          // Try a simpler fallback query
          console.log("Using simpler fallback query for batch");
          return await db.getAllAsync<VerseResult>(
            `SELECT verseID, verseText FROM ${normalizedVersion}
             WHERE length(verseText) > 0 
             ORDER BY RANDOM() LIMIT ?`,
            [count]
          );
        }
      }, version);
    } catch (error) {
      console.error('Error in getRandomVerses:', error);
      
      // Try default version as final fallback
      if (version !== this.DEFAULT_VERSION) {
        console.log(`Fallback to default version for random verses`);
        return this.getRandomVerses(this.DEFAULT_VERSION, count);
      }
      
      throw error;
    }
  }
  
  // Integration with app initialization
  static setupWithAppInitialization(appState: { isInitialized: boolean }): void {
    if (appState.isInitialized && !this.isInitialized) {
      console.log("App is initialized, initializing Bible database service");
      this.initialize().catch(err => {
        console.error("Failed to initialize Bible database service:", err);
      });
    }
  }
}

export default BibleDBService;