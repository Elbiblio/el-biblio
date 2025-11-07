import { Audio } from 'expo-av';
import * as Speech from 'expo-speech';
import { playOneShotByKey, playLoopByKey, stopByKey, getCachedSound, SoundKey } from './audio';

type ChantPhase = 'idle' | 'playing' | 'speaking' | 'paused';

interface AudioCoordinatorConfig {
  voiceKey?: SoundKey;
  instrumentalKey?: SoundKey;
  cues: string[];
  pauseDurationMs: number;
  onPhaseChange?: (phase: ChantPhase) => void;
}

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
    if (this.config.voiceKey) {
      await stopByKey(this.config.voiceKey);
    }
    if (this.config.instrumentalKey) {
      await stopByKey(this.config.instrumentalKey);
    }
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

    // Unload cached sounds
    for (const [key, sound] of this.audioCache.entries()) {
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
