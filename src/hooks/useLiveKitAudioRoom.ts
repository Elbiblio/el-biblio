import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  ConnectionState,
  Participant,
  RemoteParticipant,
  Room,
  RoomConnectOptions,
  RoomEvent,
  Track,
  DisconnectReason,
} from 'livekit-client';
import type { LiveKitSessionState } from '@/stores/WordHubsStore';

export interface AudioParticipant {
  identity: string;
  name?: string;
  isLocal: boolean;
  isSpeaking: boolean;
  isMuted: boolean;
  audioLevel: number;
}

interface UseLiveKitAudioRoomCallbacks {
  onConnecting?: (hubId: string) => void;
  onConnected?: (hubId: string) => void;
  onDisconnected?: (hubId: string, reason?: string) => void;
  onError?: (hubId: string, error: Error) => void;
}

interface UseLiveKitAudioRoomOptions {
  autoReconnect?: boolean;
  connectOptions?: RoomConnectOptions;
}

interface UseLiveKitAudioRoomResult {
  participants: AudioParticipant[];
  isConnecting: boolean;
  isConnected: boolean;
  isMuted: boolean;
  error: Error | null;
  toggleMicrophone: () => Promise<void>;
  disconnect: (reason?: string) => Promise<void>;
}

const mapParticipant = (participant: Participant, isLocal: boolean): AudioParticipant => {
  const audioPublication = participant.getTrackPublication(Track.Source.Microphone);
  const audioLevel = typeof participant.audioLevel === 'number' ? participant.audioLevel : 0;

  return {
    identity: participant.identity,
    name: participant.name,
    isLocal,
    isSpeaking: participant.isSpeaking,
    isMuted: !!(audioPublication ? audioPublication.isMuted : !participant.isMicrophoneEnabled),
    audioLevel,
  };
};

const collectParticipants = (room: Room): AudioParticipant[] => {
  const remotes = Array.from(room.remoteParticipants.values())
    .map((participant: RemoteParticipant) => mapParticipant(participant, false));

  return [mapParticipant(room.localParticipant, true), ...remotes];
};

export const useLiveKitAudioRoom = (
  session: LiveKitSessionState | null,
  callbacks: UseLiveKitAudioRoomCallbacks = {},
  options: UseLiveKitAudioRoomOptions = {}
): UseLiveKitAudioRoomResult => {
  const roomRef = useRef<Room | null>(null);
  const [participants, setParticipants] = useState<AudioParticipant[]>([]);
  const [isMuted, setIsMuted] = useState(false);
  const [isConnecting, setIsConnecting] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const latestHubIdRef = useRef<string | null>(session?.hubId ?? null);

  useEffect(() => {
    latestHubIdRef.current = session?.hubId ?? null;
  }, [session?.hubId]);

  const formatReason = (reason?: DisconnectReason | string) => {
    if (reason === undefined || reason === null) return undefined;
    if (typeof reason === 'string') return reason;
    const reasonName = DisconnectReason[reason as number] as string | undefined;
    return reasonName ?? String(reason);
  };

  const cleanupRoom = useCallback(async (reason?: DisconnectReason | string) => {
    const room = roomRef.current;
    if (!room) return;

    try {
      if (room.state === ConnectionState.Connected || room.state === ConnectionState.Connecting) {
        await room.disconnect();
      }
    } catch (disconnectError) {
      console.warn('[LiveKit] error disconnecting room', disconnectError);
    } finally {
      room.removeAllListeners();
      roomRef.current = null;
      setParticipants([]);
      setIsConnecting(false);
      setIsConnected(false);
      const hubId = latestHubIdRef.current;
      if (hubId) {
        callbacks.onDisconnected?.(hubId, formatReason(reason));
      }
    }
  }, [callbacks, formatReason]);

  const updateParticipants = useCallback((room: Room) => {
    setParticipants(collectParticipants(room));
    const localIsMuted = !room.localParticipant.isMicrophoneEnabled;
    setIsMuted(localIsMuted);
  }, []);

  useEffect(() => {
    if (!session?.credentials?.token || !session?.credentials?.url) {
      if (roomRef.current) {
        cleanupRoom('missing_credentials').catch(() => undefined);
      }
      setError(null);
      return;
    }

    const room = new Room({
      adaptiveStream: true,
      dynacast: true,
      audioCaptureDefaults: {
        echoCancellation: true,
        autoGainControl: true,
        noiseSuppression: true,
      },
    });

    roomRef.current = room;
    setIsConnecting(true);
    setError(null);
    callbacks.onConnecting?.(session.hubId);

    const handleRoomConnected = () => {
      setIsConnecting(false);
      setIsConnected(true);
      updateParticipants(room);
      callbacks.onConnected?.(session.hubId);
    };

    const handleParticipantEvent = () => updateParticipants(room);

    const handleRoomDisconnected = (reason?: DisconnectReason) => {
      setIsConnecting(false);
      setIsConnected(false);
      callbacks.onDisconnected?.(session.hubId, formatReason(reason));
    };

    const handleRoomReconnected = () => {
      setIsConnecting(false);
      setIsConnected(true);
      updateParticipants(room);
    };

    const connectToRoom = async () => {
      try {
        const connectOptions: RoomConnectOptions = {
          autoSubscribe: true,
          ...options.connectOptions,
        };

        await room.connect(session.credentials.url, session.credentials.token, connectOptions);
        await room.localParticipant.setMicrophoneEnabled(true);
        handleRoomConnected();
      } catch (connectError) {
        const formattedError = connectError instanceof Error
          ? connectError
          : new Error(String(connectError));

        setError(formattedError);
        setIsConnecting(false);
        setIsConnected(false);
        callbacks.onError?.(session.hubId, formattedError);
        callbacks.onDisconnected?.(session.hubId, formattedError.message);
      }
    };

    room
      .on(RoomEvent.ParticipantConnected, handleParticipantEvent)
      .on(RoomEvent.ParticipantDisconnected, handleParticipantEvent)
      .on(RoomEvent.TrackMuted, handleParticipantEvent)
      .on(RoomEvent.TrackUnmuted, handleParticipantEvent)
      .on(RoomEvent.ActiveSpeakersChanged, handleParticipantEvent)
      .on(RoomEvent.TrackSubscribed, handleParticipantEvent)
      .on(RoomEvent.TrackUnsubscribed, handleParticipantEvent)
      .on(RoomEvent.Disconnected, handleRoomDisconnected)
      .on(RoomEvent.Reconnected, handleRoomReconnected);

    connectToRoom();

    return () => {
      cleanupRoom('component_disposed').catch(() => undefined);
    };
  }, [callbacks, cleanupRoom, formatReason, options.connectOptions, session, updateParticipants]);

  const toggleMicrophone = useCallback(async () => {
    const room = roomRef.current;
    if (!room) return;

    try {
      const shouldEnable = room.localParticipant.isMicrophoneEnabled ? false : true;
      await room.localParticipant.setMicrophoneEnabled(shouldEnable);
      setIsMuted(!shouldEnable);
      updateParticipants(room);
    } catch (toggleError) {
      const formattedError = toggleError instanceof Error
        ? toggleError
        : new Error(String(toggleError));
      setError(formattedError);
      const hubId = latestHubIdRef.current;
      if (hubId) {
        callbacks.onError?.(hubId, formattedError);
      }
    }
  }, [callbacks, latestHubIdRef, updateParticipants]);

  const disconnect = useCallback(async (reason?: string) => {
    await cleanupRoom(reason);
  }, [cleanupRoom]);

  return useMemo<UseLiveKitAudioRoomResult>(() => ({
    participants,
    isConnecting,
    isConnected,
    isMuted,
    error,
    toggleMicrophone,
    disconnect,
  }), [participants, isConnecting, isConnected, isMuted, error, toggleMicrophone, disconnect]);
};
