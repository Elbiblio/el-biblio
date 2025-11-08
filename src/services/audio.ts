import { Audio } from 'expo-av';
import SoundManager from '@/utils/SoundManager';

// All sounds from assets/sounds/
const SOUNDS = {
  'bell-meditation.mp3': require('../../assets/sounds/bell-meditation.mp3'),
  'bell.wav': require('../../assets/sounds/bell.wav'),
  'cheers.mp3': require('../../assets/sounds/cheers.mp3'),
  'chime.wav': require('../../assets/sounds/chime.wav'),
  'clap.wav': require('../../assets/sounds/clap.wav'),
  'correct.mp3': require('../../assets/sounds/correct.mp3'),
  'ding.wav': require('../../assets/sounds/ding.wav'),
  'game-over.mp3': require('../../assets/sounds/game-over.mp3'),
  'heartbeat.mp3': require('../../assets/sounds/heartbeat.mp3'),
  'level-up.mp3': require('../../assets/sounds/level-up.mp3'),
  'meditation-ambient.mp3': require('../../assets/sounds/meditation-ambient.mp3'),
  'musicverse.mp3': require('../../assets/sounds/musicverse.mp3'),
  'power-up.mp3': require('../../assets/sounds/power-up.mp3'),
  'streak.wav': require('../../assets/sounds/streak.wav'),
  'success_bell.mp3': require('../../assets/sounds/success_bell.mp3'),
  'tick-tock.wav': require('../../assets/sounds/tick-tock.wav'),
  'timeout.mp3': require('../../assets/sounds/timeout.mp3'),
  'verseplay.mp3': require('../../assets/sounds/verseplay.mp3'),
  'wordhub_new.mp3': require('../../assets/sounds/wordhub_new.mp3'),
  'wrong.mp3': require('../../assets/sounds/wrong.mp3'),
  'db/10000_reasons.mp3': require('../../assets/sounds/db/10000_reasons.mp3'),
  'db/10000_reasons_african.mp3': require('../../assets/sounds/db/10000_reasons_african.mp3'),
  'db/10000_reasons_instrumental.mp3': require('../../assets/sounds/db/10000_reasons_instrumental.mp3'),
  'db/be_still_my_soul.mp3': require('../../assets/sounds/db/be_still_my_soul.mp3'),
  'db/be_still_my_soul_instrumental.mp3': require('../../assets/sounds/db/be_still_my_soul_instrumental.mp3'),
  'db/anima_christi.mp3': require('../../assets/sounds/db/anima_christi.mp3'),
  'db/anima_christi_instrumental.mp3': require('../../assets/sounds/db/anima_christi_instrumental.mp3'),
  'db/oceans_voice.mp3': require('../../assets/sounds/db/oceans_voice.mp3'),
  'db/oceans_instrumental.mp3': require('../../assets/sounds/db/oceans_instrumental.mp3'),
} as const;

export type SoundKey = keyof typeof SOUNDS;
// Cooldown tracker per sound key
const __lastPlayed: Partial<Record<SoundKey, number>> = {};

export const playOneShotByKey = async (key: SoundKey, volumeMultiplier = 1.0): Promise<void> => {
  await initAudio();
  if (!SoundManager.isEnabled()) return;
  const s = await getSound(key);
  return new Promise(async (resolve) => {
    try {
      await s.setIsLoopingAsync(false);
      const vol = SoundManager.getVolume();
      await s.setVolumeAsync(Math.max(0, Math.min(1, vol * volumeMultiplier)));
      await s.setPositionAsync(0);
      s.setOnPlaybackStatusUpdate((status) => {
        if ('didJustFinish' in status && status.didJustFinish) {
          s.setOnPlaybackStatusUpdate(null);
          resolve();
        }
      });
      await s.playAsync();
    } catch {
      resolve();
    }
  });
};

export const stopByKey = async (key: SoundKey) => {
  try {
    const s = cache.get(key);
    await s?.stopAsync();
  } catch {}
};

export const playLoopByKey = async (key: SoundKey, volumeMultiplier = 0.15) => {
  try {
    await initAudio();
    if (!SoundManager.isEnabled()) return;
    const s = await getSound(key);
    await s.setIsLoopingAsync(true);
    const vol = SoundManager.getVolume();
    await s.setVolumeAsync(Math.max(0, Math.min(1, vol * volumeMultiplier)));
    const status = await s.getStatusAsync();
    if ('isPlaying' in status && !status.isPlaying) {
      await s.playAsync();
    }
  } catch {}
};

// Human-friendly cue aliases used across the app
const CUE_ALIASES: Record<string, SoundKey> = {
  chime: 'chime.wav',
  retry: 'chime.wav',
  ding: 'ding.wav',
  correct: 'correct.mp3',
  wrong: 'wrong.mp3',
  cheers: 'cheers.mp3',
  gameOver: 'game-over.mp3',
  tickTock: 'tick-tock.wav',
  timeout: 'timeout.mp3',
  streak: 'streak.wav',
  powerup: 'power-up.mp3',
  levelup: 'level-up.mp3',
  bell: 'bell.wav',
  meditationBell: 'bell-meditation.mp3',
  successBell: 'success_bell.mp3',
  heartbeat: 'heartbeat.mp3',
  musicverse: 'musicverse.mp3',
  verseplay: 'verseplay.mp3',
  meditation: 'meditation-ambient.mp3',
  wordhubNew: 'wordhub_new.mp3',
};

const cache = new Map<SoundKey, Audio.Sound>();
let initialized = false;

// Export cache for AudioCoordinator
export const getSoundCache = () => cache;

export const initAudio = async () => {
  if (initialized) return;
  
  // Configure audio session for optimal mixing
  try {
    await Audio.setAudioModeAsync({
      playsInSilentModeIOS: true,
      allowsRecordingIOS: false,
      staysActiveInBackground: true,
      shouldDuckAndroid: true,
      playThroughEarpieceAndroid: false,
      interruptionModeIOS: 1, // DO_NOT_MIX
      interruptionModeAndroid: 1, // DO_NOT_MIX
    });
  } catch (error) {
    console.warn('[audio] Failed to set audio mode:', error);
  }
  
  await SoundManager.init();
  
  // Optionally pre-load common SFX for snappier UX
  const preload: SoundKey[] = [
    'chime.wav', 'ding.wav', 'correct.mp3', 'wrong.mp3', 'cheers.mp3', 'streak.wav', 'timeout.mp3'
  ];
  for (const key of preload) {
    await getSound(key).catch(() => {});
  }
  initialized = true;
};

const getSound = async (key: SoundKey): Promise<Audio.Sound> => {
  const existing = cache.get(key);
  if (existing) return existing;
  const sound = new Audio.Sound();
  await sound.loadAsync(SOUNDS[key]);
  cache.set(key, sound);
  return sound;
};

// Export for external use (e.g., AudioCoordinator)
export const getCachedSound = async (key: SoundKey): Promise<Audio.Sound> => {
  await initAudio();
  return getSound(key);
};

export const playSound = async (soundName: string, format?: 'mp3' | 'wav') => {
  // Backward-compatible: playSound('level-up', 'mp3')
  const key = (format ? `${soundName}.${format}` : soundName) as SoundKey;
  return playByKey(key);
};

export const playCue = async (cue: keyof typeof CUE_ALIASES | string) => {
  const key = CUE_ALIASES[cue] as SoundKey | undefined;
  if (!key) {
    console.warn(`[audio] Unknown cue: ${cue}`);
    return;
  }
  return playByKey(key);
};

// cues that shouldn't be restarted if already playing (prevents spam)
const NO_RESTART_WHEN_PLAYING: Partial<Record<SoundKey, boolean>> = {
  'tick-tock.wav': true,
};

export const playByKey = async (key: SoundKey) => {
  // Cooldown anti-spam per key
  const now = Date.now();
  const cooldownMs = key === 'tick-tock.wav' ? 900 : 200;
  if (!(__lastPlayed as any)[key]) ( __lastPlayed as any)[key] = 0;
  if (now - ( __lastPlayed as any)[key] < cooldownMs) {
    return;
  }
  ( __lastPlayed as any)[key] = now;

  await initAudio();
  if (!SoundManager.isEnabled()) return;
  let s = await getSound(key);

  const tryPlay = async (): Promise<void> => {
    const vol = SoundManager.getVolume();
    try {
      const status = await s.getStatusAsync();
      // Reload if somehow not loaded
      if ('isLoaded' in status && !status.isLoaded) {
        await s.unloadAsync().catch(() => {});
        cache.delete(key);
        s = await getSound(key);
      }
      // Avoid restarting if already playing for some cues
      if ('isPlaying' in status && status.isPlaying && NO_RESTART_WHEN_PLAYING[key]) {
        return;
      }
      await s.setVolumeAsync(vol);
      await s.setPositionAsync(0);
      await s.playAsync();
    } catch (err: any) {
      // If the player instance got invalidated, recreate and retry once
      const msg = String(err?.message || err);
      if (msg.includes('Player does not exist')) {
        try {
          await s.unloadAsync().catch(() => {});
        } catch {}
        cache.delete(key);
        s = await getSound(key);
        await s.setVolumeAsync(vol);
        await s.setPositionAsync(0);
        await s.playAsync();
      } else {
        console.warn('[audio] play error', key, err);
      }
    }
  };

  return tryPlay();
};

// Music helpers
export const playMusic = async (cue: 'musicverse' | 'verseplay' | 'meditation' | 'heartbeat', volumeMultiplier = 0.15) => {
  const key = CUE_ALIASES[cue];
  if (!key) return;
  try {
    await initAudio();
    if (!SoundManager.isEnabled()) return;
    const s = await getSound(key);
    await s.setIsLoopingAsync(true);
    const vol = SoundManager.getVolume();
    await s.setVolumeAsync(Math.max(0, Math.min(1, vol * volumeMultiplier)));
    const status = await s.getStatusAsync();
    if ('isPlaying' in status && !status.isPlaying) {
      await s.playAsync();
    }
  } catch {}
};

export const stopMusic = async (cue: 'musicverse' | 'verseplay' | 'meditation' | 'heartbeat') => {
  const key = CUE_ALIASES[cue];
  if (!key) return;
  try {
    const s = cache.get(key);
    await s?.stopAsync();
  } catch {}
};

// Preload a looping music cue without starting playback
export const preloadMusicCue = async (cue: 'musicverse' | 'verseplay' | 'meditation' | 'heartbeat') => {
  const key = CUE_ALIASES[cue];
  if (!key) return;
  try {
    await initAudio();
    await getSound(key);
  } catch {}
};

export const stopAllSounds = async () => {
  try {
    await Promise.all(
      Array.from(cache.values()).map(s => s.stopAsync().catch(() => {}))
    );
  } catch {}
};

export const AUDIO_KEYS = Object.keys(SOUNDS) as SoundKey[];

// Adjust volume of looping music cues without stopping playback
export const setMusicVolume = async (
  cue: 'meditation' | 'heartbeat',
  volumeMultiplier: number
) => {
  const key = CUE_ALIASES[cue];
  if (!key) return;
  try {
    await initAudio();
    const s = cache.get(key) || await getSound(key);
    const vol = SoundManager.getVolume();
    await s.setVolumeAsync(Math.max(0, Math.min(1, vol * volumeMultiplier)));
  } catch {}
};