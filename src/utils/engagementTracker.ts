import AsyncStorage from '@react-native-async-storage/async-storage';

const LAST_ENGAGED_KEY = 'last_engaged_at_v1';

export type EngagementKind =
  | 'meditation'
  | 'challenge'
  | 'reflection'
  | 'hub_message';

export const engagementTracker = {
  async record(_kind: EngagementKind) {
    try {
      const nowIso = new Date().toISOString();
      await AsyncStorage.setItem(LAST_ENGAGED_KEY, nowIso);
    } catch {
      // Swallow errors to avoid impacting UX
    }
  },
  async getLastEngagedAtMs(): Promise<number | null> {
    try {
      const raw = await AsyncStorage.getItem(LAST_ENGAGED_KEY);
      if (!raw) return null;
      const ts = new Date(raw).getTime();
      if (!ts || Number.isNaN(ts)) return null;
      return ts;
    } catch {
      return null;
    }
  },
};
