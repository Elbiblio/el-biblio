import { apiClient, endpoints } from '@/api/client';
import webSocketService, { WebSocketRuntimeConfig } from '@/services/websocket';

export type MobileConfigResponse = {
  websocket?: {
    host: string;
    port: number | string;
    appKey: string;
    secure: boolean;
  } | null;
};

export const loadMobileConfig = async (): Promise<void> => {
  try {
    const response = await apiClient.get<{ data: MobileConfigResponse }>(
      endpoints.public.mobileConfig,
      undefined,
      {
        headers: {
          'X-Anonymous': 'true',
        },
      },
    );

    if (!response.success || !response.data?.data?.websocket) {
      return;
    }

    const ws = response.data.data.websocket;
    const config: WebSocketRuntimeConfig = {
      host: ws.host,
      port: String(ws.port),
      appKey: ws.appKey,
      secure: !!ws.secure,
    };

    webSocketService.setConfig(config);
  } catch (error) {
    if (__DEV__) {
      console.warn('[MobileConfig] Failed to load mobile config', error);
    }
  }
};
