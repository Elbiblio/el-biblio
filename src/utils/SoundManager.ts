import AsyncStorage from '@react-native-async-storage/async-storage';

// Simple global sound manager for enabling/disabling and volume control
// Usage:
// - await SoundManager.init();
// - if (SoundManager.isEnabled()) { /* play */ }
// - const vol = SoundManager.getVolume();
// - await SoundManager.setEnabled(false);
// - await SoundManager.setVolume(0.5);

const ENABLED_KEY = 'sound_enabled';
const VOLUME_KEY = 'sound_volume';

class SoundManager {
  private enabled = true;
  private volume = 1.0; // 0.0 - 1.0
  private initialized = false;

  async init() {
    if (this.initialized) return;
    try {
      const [enabledStr, volumeStr] = await Promise.all([
        AsyncStorage.getItem(ENABLED_KEY),
        AsyncStorage.getItem(VOLUME_KEY),
      ]);
      if (enabledStr !== null) this.enabled = enabledStr === '1';
      if (volumeStr !== null) {
        const v = parseFloat(volumeStr);
        if (!Number.isNaN(v)) this.volume = Math.min(1, Math.max(0, v));
      }
    } catch {}
    this.initialized = true;
  }

  isEnabled() {
    return this.enabled;
  }

  getVolume() {
    return this.volume;
  }

  async setEnabled(enabled: boolean) {
    this.enabled = enabled;
    try { await AsyncStorage.setItem(ENABLED_KEY, enabled ? '1' : '0'); } catch {}
  }

  async toggleEnabled() {
    await this.setEnabled(!this.enabled);
  }

  async setVolume(v: number) {
    const clamped = Math.min(1, Math.max(0, v));
    this.volume = clamped;
    try { await AsyncStorage.setItem(VOLUME_KEY, String(clamped)); } catch {}
  }
}

export default new SoundManager();
