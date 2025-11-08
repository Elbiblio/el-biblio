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

// ---------- TTS HELPERS ----------

/**
 * Speak single text with optional rate and timeout
 */
export const speak = async (
  text: string,
  opts?: { rate?: number; onDone?: () => void; timeout?: number }
): Promise<void> => {
  const timeoutMs = opts?.timeout ?? 10000;

  return Promise.race([
    new Promise<void>((resolve) => {
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
    }),
    new Promise<void>((resolve) => setTimeout(resolve, timeoutMs)),
  ]);
};

/**
 * Simple speech queue to prevent overlapping TTS
 */
class SpeechQueue {
  private queue: Array<{ text: string; rate?: number; resolve: () => void }> = [];
  private processing = false;

  enqueue(text: string, rate?: number): Promise<void> {
    return new Promise<void>((resolve) => {
      this.queue.push({ text, rate, resolve });
      if (!this.processing) { void this.process(); }
    });
  }

  private async process(): Promise<void> {
    if (this.processing) return;
    this.processing = true;

    while (this.queue.length > 0) {
      const item = this.queue.shift();
      if (!item) break;
      try {
        await speak(item.text, { rate: item.rate ?? 0.85, timeout: 8000 });
      } catch {}
      try { item.resolve(); } catch {}
    }

    this.processing = false;
  }

  clear() {
    try { Speech.stop(); } catch {}
    while (this.queue.length > 0) {
      const item = this.queue.shift();
      try { item?.resolve(); } catch {}
    }
    this.processing = false;
  }
}

const globalSpeechQueue = new SpeechQueue();

export const queueSpeak = (text: string, rate?: number) => globalSpeechQueue.enqueue(text, rate);
export const clearSpeechQueue = () => globalSpeechQueue.clear();

/**
 * Speak sequence of texts with pauses
 */
export const speakSequence = async (
  items: string[],
  options?: { rate?: number; pauseMs?: number }
): Promise<void> => {
  const pause = Math.max(0, options?.pauseMs ?? 800);
  for (const t of items) {
    await speak(t, { rate: options?.rate ?? 0.85, timeout: 8000 });
    await new Promise(r => setTimeout(r, pause));
  }
};

/**
 * Read scripture verses slowly
 */
export const readScriptureSlowly = async (
  reference?: string,
  options?: { rate?: number; pauseMs?: number }
): Promise<void> => {
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
    const verses = rows
      .filter(r => r.verse >= vStart && r.verse <= vEnd)
      .map(r => r.text)
      .join(' ');

    const sentences = verses.split(/(?<=[\.!?])\s+/).filter(Boolean);
    await speakSequence(sentences, {
      rate: options?.rate ?? 0.75,
      pauseMs: options?.pauseMs ?? 1200,
    });
  } catch {}
};

// ---------- AUDIO COORDINATOR ----------

/**
 * AudioCoordinator manages chant playback with TTS coordination
 * Optimized for performance and reliability
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
   * Preload audio files to cache
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
   * Start the coordination loop
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
   * Pause coordination
   */
  async pause(): Promise<void> {
    this.isActive = false;
    this.setPhase('paused');

    // Clear timeout
    if (this.loopTimeout) {
      clearTimeout(this.loopTimeout);
      this.loopTimeout = null;
    }

    // Stop speech
    try { Speech.stop(); } catch {}

    // Stop audio
    try {
      if (this.config.voiceKey) await stopByKey(this.config.voiceKey);
      if (this.config.instrumentalKey) await stopByKey(this.config.instrumentalKey);
    } catch {}
  }

  /**
   * Resume from paused state
   */
  async resume(): Promise<void> {
    if (this.phase !== 'paused') return;

    this.isActive = true;

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

    // Unload cached sounds
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

  // ----- PRIVATE METHODS -----

  private async loadSound(key: SoundKey): Promise<void> {
    try {
      const sound = await getCachedSound(key);
      this.audioCache.set(key, sound);
    } catch (error) {
      console.warn(`[AudioCoordinator] Failed to preload ${key}:`, error);
    }
  }

  private async getSound(key: SoundKey): Promise<Audio.Sound | null> {
    let sound = this.audioCache.get(key);
    if (!sound) {
      await this.loadSound(key);
      sound = this.audioCache.get(key);
    }
    return sound || null;
  }

  private async duckAudio(key: SoundKey): Promise<void> {
    try {
      const sound = await this.getSound(key);
      if (sound) {
        await sound.setVolumeAsync(this.duckedVolume);
      }
    } catch {}
  }

  private async restoreAudio(key: SoundKey): Promise<void> {
    try {
      const sound = await this.getSound(key);
      if (sound) {
        await sound.setVolumeAsync(this.currentVolume);
      }
    } catch {}
  }

  private async speakWithDuck(text: string, audioKey?: SoundKey): Promise<void> {
    if (audioKey) {
      await this.duckAudio(audioKey);
    }

    try {
      await speak(text, { rate: 0.85, timeout: 8000 });
    } finally {
      if (audioKey) {
        await this.restoreAudio(audioKey);
      }
    }
  }

  private setPhase(phase: ChantPhase): void {
    this.phase = phase;
    this.config.onPhaseChange?.(phase);
  }

  /**
   * Voice loop: Play full track → Speak cue → Wait → Repeat
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
   * Instrumental loop: Continuous play with periodic cues
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

        // Duck and speak
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
}
