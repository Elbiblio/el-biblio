import AsyncStorage from '@react-native-async-storage/async-storage';

export type TelemetryEvent = {
  name: string;
  ts: number;
  payload?: Record<string, any>;
};

const STORAGE_KEY = 'telemetry_queue_v1';

async function enqueue(event: TelemetryEvent) {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    const list: TelemetryEvent[] = raw ? JSON.parse(raw) : [];
    list.push(event);
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(list.slice(-200)));
  } catch {}
}

export const telemetry = {
  async track(name: string, payload?: Record<string, any>) {
    const evt: TelemetryEvent = { name, ts: Date.now(), payload };
    if (__DEV__) {
      // eslint-disable-next-line no-console
      console.log('[telemetry]', evt);
    }
    await enqueue(evt);
  },
};
