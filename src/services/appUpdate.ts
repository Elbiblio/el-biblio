import Constants from 'expo-constants';
import { Platform } from 'react-native';

type RemoteVersionPayload = {
  minSupportedAndroid?: string;
  latestAndroid?: string;
  androidStoreUrl?: string;
  message?: string;
};

export interface VersionCheckResult {
  currentVersion: string;
  latestVersion: string;
  minSupportedVersion: string;
  needsMandatoryUpdate: boolean;
  hasOptionalUpdate: boolean;
  storeUrl?: string;
  message?: string;
}

const DEFAULT_EXTRAS = {
  APP_VERSION_CHECK_URL: 'https://api.elbiblio.com/public/mobile-version',
  MIN_SUPPORTED_ANDROID: '1.0.0',
  LATEST_ANDROID: '1.0.0',
  ANDROID_STORE_URL: 'https://play.google.com/store/apps/details?id=com.elbiblio.app',
} as const;

const getExtras = () => {
  const expoConfig = (Constants as any)?.expoConfig;
  const manifestExtra = (Constants as any)?.manifest?.extra;
  const raw = expoConfig?.extra ?? manifestExtra ?? {};
  return { ...DEFAULT_EXTRAS, ...(raw || {}) };
};

const parseVersion = (value?: string): string => {
  if (!value || typeof value !== 'string') {
    return '0.0.0';
  }
  return value.trim();
};

const compareVersions = (left: string, right: string): number => {
  const sanitize = (version: string) => version.split(/[^0-9A-Za-z]+/).filter(Boolean);
  const a = sanitize(parseVersion(left));
  const b = sanitize(parseVersion(right));
  const length = Math.max(a.length, b.length);

  for (let index = 0; index < length; index += 1) {
    const leftPart = Number.parseInt(a[index] ?? '0', 10);
    const rightPart = Number.parseInt(b[index] ?? '0', 10);

    if (Number.isNaN(leftPart) && Number.isNaN(rightPart)) {
      continue;
    }

    if (Number.isNaN(leftPart)) {
      return -1;
    }

    if (Number.isNaN(rightPart)) {
      return 1;
    }

    if (leftPart > rightPart) {
      return 1;
    }
    if (leftPart < rightPart) {
      return -1;
    }
  }

  return 0;
};

const fetchRemoteVersionPayload = async (url?: string): Promise<RemoteVersionPayload | null> => {
  if (!url) {
    return null;
  }

  try {
    const response = await fetch(url, {
      headers: {
        Accept: 'application/json',
      },
    });

    if (!response.ok) {
      return null;
    }

    const data = (await response.json()) as RemoteVersionPayload | undefined;
    return data ?? null;
  } catch (error) {
    console.warn('[AppUpdate] Failed to fetch remote version payload', error);
    return null;
  }
};

const resolveCurrentVersion = (): string => {
  const expoConfigVersion = (Constants as any)?.expoConfig?.version;
  const manifestVersion = (Constants as any)?.manifest?.version;
  return parseVersion(expoConfigVersion ?? manifestVersion);
};

export const checkForAppUpdate = async (): Promise<VersionCheckResult> => {
  const extras = getExtras();
  const remotePayload = await fetchRemoteVersionPayload(extras.APP_VERSION_CHECK_URL);

  const minSupportedVersion = parseVersion(
    remotePayload?.minSupportedAndroid ?? extras.MIN_SUPPORTED_ANDROID,
  );
  const latestVersion = parseVersion(remotePayload?.latestAndroid ?? extras.LATEST_ANDROID);
  const storeUrl = remotePayload?.androidStoreUrl ?? extras.ANDROID_STORE_URL;
  const message = remotePayload?.message;

  const currentVersion = resolveCurrentVersion();

  let needsMandatoryUpdate = false;
  let hasOptionalUpdate = false;

  if (Platform.OS === 'android') {
    if (compareVersions(currentVersion, minSupportedVersion) < 0) {
      needsMandatoryUpdate = true;
    } else if (compareVersions(currentVersion, latestVersion) < 0) {
      hasOptionalUpdate = true;
    }
  }

  return {
    currentVersion,
    latestVersion,
    minSupportedVersion,
    needsMandatoryUpdate,
    hasOptionalUpdate,
    storeUrl,
    message,
  };
};
