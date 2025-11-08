import { Audio } from 'expo-av';
import * as Speech from 'expo-speech';
import { playOneShotByKey, playLoopByKey, stopByKey, getCachedSound, SoundKey } from './audio';
import BibleDBService from '@/utils/database';
import { bibleBooks } from '@/constants/bibleBooks';

type ChantPhase = 'idle' | 'playing' | 'speaking' | 'paused';

interface AudioCoordinatorConfig {
  voiceKey?: SoundKey;
  instrumentalKey?: SoundKey;
  cues: string[];
  pauseDurationMs: number;
  onPhaseChange?: (phase: ChantPhase) => void;
}

// ---------- Generic TTS helpers for orchestrated flows ----------

export type DuckChannel = 'meditation' | 'heartbeat';

/**
 * Speak a single text with optional rate and completion callback
 */
export const speak = async (text: string, opts?: { rate?: number; onDone?: () => void }): Promise<void> => {
  return new Promise<void>((resolve) => {
    try {
      Speech.speak(text, {
        rate: opts?.rate ?? 0.85,
        onDone: () => {
          try { opts?.onDone?.(); } catch {}
          resolve();
        },
        onError: () => resolve(),
      } as any);
    } catch {
      resolve();
    }
  });
};

// Simple speech queue to avoid overlapping TTS
class SpeechQueue {
  private queue: Array<{ text: string; rate?: number }>; 
  private processing: boolean;
  constructor() {
    this.queue = [];
    this.processing = false;
  }
  enqueue(text: string, rate?: number): Promise<void> {
    return new Promise<void>((resolve) => {
      this.queue.push({ text, rate });
      if (!this.processing) {
        this.processing = true;
        this.process().then(resolve).catch(resolve);
      } else {
        // Chain resolve when this item is spoken
        const originalLen = this.queue.length;
        const check = () => {
          if (this.queue.length < originalLen) resolve();
          else setTimeout(check, 10);
        };
        check();
      }
    });
  }
  private async process(): Promise<void> {
    while (this.queue.length) {
      const item = this.queue.shift()!;
      await speak(item.text, { rate: item.rate ?? 0.85 });
    }
    this.processing = false;
  }
  clear() {
    try { Speech.stop(); } catch {}
    this.queue = [];
    this.processing = false;
  }
}

const globalSpeechQueue = new SpeechQueue();
export const queueSpeak = (text: string, rate?: number) => globalSpeechQueue.enqueue(text, rate);
export const clearSpeechQueue = () => globalSpeechQueue.clear();

/**
 * Speak a sequence of texts with a pause in between
 */
export const speakSequence = async (
  items: string[],
  options?: { rate?: number; pauseMs?: number }
): Promise<void> => {
  const pause = Math.max(0, options?.pauseMs ?? 800);
  for (const t of items) {
    await speak(t, { rate: options?.rate ?? 0.85 });
    await new Promise(r => setTimeout(r, pause));
  }
};

/**
 * Read scripture verses slowly by splitting into sentences
 */
export const readScriptureSlowly = async (reference?: string, options?: { rate?: number; pauseMs?: number }): Promise<void> => {
  if (!reference) return;
  const m = reference.trim().match(/^([0-9I]{0,3}\s*[A-Za-z\. ]+?)\s+(\d+):(\d+)(?:-(\d+))?/);
  if (!m) return;
  const bookName = m[1].replace(/\.$/, '').trim();
  const chapter = parseInt(m[2], 10);
  const vStart = parseInt(m[3], 10);
  const vEnd = m[4] ? parseInt(m[4], 10) : vStart;
  const meta = bibleBooks.find(b => b.name.toLowerCase() === bookName.toLowerCase());
  if (!meta) return;
  try {
    const rows = await BibleDBService.getChapter('eng_rv_vpl', meta.abbreviation, chapter);
    const verses = rows.filter(r => r.verse >= vStart && r.verse <= vEnd).map(r => r.text).join(' ');
    const sentences = verses.split(/(?<=[\.!?])\s+/).filter(Boolean);
    await speakSequence(sentences, { rate: options?.rate ?? 0.75, pauseMs: options?.pauseMs ?? 1200 });
  } catch {}
};

/**
 * AudioCoordinator manages the complex interaction between chant audio playback
 * and TTS speech, ensuring smooth transitions and proper audio ducking.
 */
export class AudioCoordinator {
  private config: AudioCoordinatorConfig;
  private phase: ChantPhase = 'idle';
  private isActive = false;
  private cueIndex = 0;
  private loopTimeout: ReturnType<typeof setTimeout> | null = null;
  private audioCache: Map<SoundKey, Audio.Sound> = new Map();
  private currentVolume = 0.6;
  private duckedVolume = 0.15;

  constructor(config: AudioCoordinatorConfig) {
    this.config = config;
  }

  /**
   * Preload audio files to cache for instant playback
   */
  async preload(): Promise<void> {
    const promises: Promise<void>[] = [];

    if (this.config.voiceKey) {
      promises.push(this.loadSound(this.config.voiceKey));
    }
    if (this.config.instrumentalKey) {
      promises.push(this.loadSound(this.config.instrumentalKey));
    }

    await Promise.allSettled(promises);
  }

  /**
   * Load a sound into cache using the audio service
   */
  private async loadSound(key: SoundKey): Promise<void> {
    try {
      const sound = await getCachedSound(key);
      this.audioCache.set(key, sound);
    } catch (error) {
      console.warn(`[AudioCoordinator] Failed to preload ${key}:`, error);
    }
  }

  /**
   * Get cached sound or load it
   */
  private async getSound(key: SoundKey): Promise<Audio.Sound | null> {
    let sound = this.audioCache.get(key);
    if (!sound) {
      await this.loadSound(key);
      sound = this.audioCache.get(key);
    }
    return sound || null;
  }

  /**
   * Duck audio volume for speech
   */
  private async duckAudio(key: SoundKey): Promise<void> {
    try {
      const sound = await this.getSound(key);
      if (sound) {
        await sound.setVolumeAsync(this.duckedVolume);
      }
    } catch (error) {
      console.warn(`[AudioCoordinator] Failed to duck ${key}:`, error);
    }
  }

  /**
   * Restore audio volume after speech
   */
  private async restoreAudio(key: SoundKey): Promise<void> {
    try {
      const sound = await this.getSound(key);
      if (sound) {
        await sound.setVolumeAsync(this.currentVolume);
      }
    } catch (error) {
      console.warn(`[AudioCoordinator] Failed to restore ${key}:`, error);
    }
  }

  /**
   * Speak text with automatic audio ducking
   */
  private async speakWithDuck(text: string, audioKey?: SoundKey): Promise<void> {
    return new Promise((resolve) => {
      // Duck audio if playing
      if (audioKey) {
        this.duckAudio(audioKey).catch(() => {});
      }

      Speech.speak(text, {
        rate: 0.85,
        onDone: () => {
          // Restore audio volume
          if (audioKey) {
            this.restoreAudio(audioKey).catch(() => {});
          }
          resolve();
        },
        onError: () => {
          // Restore audio even on error
          if (audioKey) {
            this.restoreAudio(audioKey).catch(() => {});
          }
          resolve();
        },
      });
    });
  }

  /**
   * Set phase and notify listeners
   */
  private setPhase(phase: ChantPhase): void {
    this.phase = phase;
    this.config.onPhaseChange?.(phase);
  }

  /**
   * Start the audio coordination loop
   */
  async start(): Promise<void> {
    if (this.isActive) return;
    
    this.isActive = true;
    this.cueIndex = 0;
    this.setPhase('playing');

    if (this.config.voiceKey) {
      await this.startVoiceLoop();
    } else if (this.config.instrumentalKey) {
      await this.startInstrumentalLoop();
    }
  }

  /**
   * Voice chant loop: Play full track → Speak cue → Wait → Repeat
   */
  private async startVoiceLoop(): Promise<void> {
    if (!this.isActive || !this.config.voiceKey) return;

    try {
      this.setPhase('playing');
      
      // Play voice chant
      await playOneShotByKey(this.config.voiceKey, 1.0);
      
      if (!this.isActive) return;

      // Speak cue
      this.setPhase('speaking');
      const cue = this.config.cues[this.cueIndex % this.config.cues.length];
      this.cueIndex++;
      
      await this.speakWithDuck(cue);

      if (!this.isActive) return;

      // Wait before next loop
      this.loopTimeout = setTimeout(() => {
        this.startVoiceLoop();
      }, this.config.pauseDurationMs);

    } catch (error) {
      console.warn('[AudioCoordinator] Voice loop error:', error);
      // Retry after delay
      if (this.isActive) {
        this.loopTimeout = setTimeout(() => {
          this.startVoiceLoop();
        }, 1000);
      }
    }
  }

  /**
   * Instrumental loop: Continuous play with periodic ducked cues
   */
  private async startInstrumentalLoop(): Promise<void> {
    if (!this.isActive || !this.config.instrumentalKey) return;

    try {
      this.setPhase('playing');
      
      // Start looping instrumental
      await playLoopByKey(this.config.instrumentalKey, this.currentVolume);

      if (!this.isActive) return;

      // Schedule periodic cues
      this.scheduleNextCue();

    } catch (error) {
      console.warn('[AudioCoordinator] Instrumental loop error:', error);
      // Retry after delay
      if (this.isActive) {
        this.loopTimeout = setTimeout(() => {
          this.startInstrumentalLoop();
        }, 1000);
      }
    }
  }

  /**
   * Schedule next cue for instrumental mode
   */
  private scheduleNextCue(): void {
    if (!this.isActive || !this.config.instrumentalKey) return;

    this.loopTimeout = setTimeout(async () => {
      if (!this.isActive || !this.config.instrumentalKey) return;

      try {
        this.setPhase('speaking');
        
        // Get next cue
        const cue = this.config.cues[this.cueIndex % this.config.cues.length];
        this.cueIndex++;

        // Duck instrumental and speak
        await this.speakWithDuck(cue, this.config.instrumentalKey);

        if (!this.isActive) return;

        this.setPhase('playing');
        
        // Schedule next cue
        this.scheduleNextCue();

      } catch (error) {
        console.warn('[AudioCoordinator] Cue error:', error);
        if (this.isActive) {
          this.setPhase('playing');
          this.scheduleNextCue();
        }
      }
    }, this.config.pauseDurationMs);
  }

  /**
   * Pause the audio coordination
   */
  async pause(): Promise<void> {
    this.isActive = false;
    this.setPhase('paused');

    // Clear any pending timeouts
    if (this.loopTimeout) {
      clearTimeout(this.loopTimeout);
      this.loopTimeout = null;
    }

    // Stop speech
    try {
      Speech.stop();
    } catch {}

    // Stop audio
    try {
      if (this.config.voiceKey) await stopByKey(this.config.voiceKey);
    } catch {}
    try {
      if (this.config.instrumentalKey) await stopByKey(this.config.instrumentalKey);
    } catch {}
  }

  /**
   * Resume from paused state
   */
  async resume(): Promise<void> {
    if (this.phase !== 'paused') return;
    
    this.isActive = true;
    
    // Resume appropriate loop
    if (this.config.voiceKey) {
      await this.startVoiceLoop();
    } else if (this.config.instrumentalKey) {
      await this.startInstrumentalLoop();
    }
  }

  /**
   * Stop and cleanup
   */
  async stop(): Promise<void> {
    await this.pause();
    this.setPhase('idle');
    this.cueIndex = 0;

    // Unload cached sounds to free memory
    for (const sound of this.audioCache.values()) {
      try {
        await sound.unloadAsync();
      } catch {}
    }
    this.audioCache.clear();
  }

  /**
   * Get current phase
   */
  getPhase(): ChantPhase {
    return this.phase;
  }

  /**
   * Check if active
   */
  isPlaying(): boolean {
    return this.isActive && this.phase !== 'idle' && this.phase !== 'paused';
  }
}
