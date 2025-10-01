import type { LiveKitSessionState } from '@/stores/WordHubsStore';
import {
  AudioParticipant,
  useLivekitRoomSimple,
  UseLivekitRoomSimpleCallbacks,
  UseLivekitRoomSimpleOptions,
  UseLivekitRoomSimpleResult,
} from './useLivekitRoomSimple';

export type { AudioParticipant };

export interface UseLiveKitAudioRoomCallbacks extends UseLivekitRoomSimpleCallbacks {}

export interface UseLiveKitAudioRoomOptions extends UseLivekitRoomSimpleOptions {}

export interface UseLiveKitAudioRoomResult extends UseLivekitRoomSimpleResult {}

export const useLiveKitAudioRoom = (
  session: LiveKitSessionState | null,
  callbacks: UseLiveKitAudioRoomCallbacks = {},
  options: UseLiveKitAudioRoomOptions = {}
): UseLiveKitAudioRoomResult => {
  return useLivekitRoomSimple(session, callbacks, options);
};
