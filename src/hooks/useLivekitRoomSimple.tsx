import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  AudioSession,
  LiveKitRoom,
  useParticipants,
  useRoomContext,
} from '@livekit/react-native';
import {
  ConnectionState,
  DisconnectReason,
  Participant,
  Room,
  RoomConnectOptions,
  RoomEvent,
  Track,
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

export interface UseLivekitRoomSimpleCallbacks {
  onConnecting?: (hubId: string) => void;
  onConnected?: (hubId: string) => void;
  onDisconnected?: (hubId: string, reason?: string) => void;
  onError?: (hubId: string, error: Error) => void;
  onData?: (payload: Uint8Array, participant: Participant | undefined, topic?: string) => void;
}

export interface UseLivekitRoomSimpleOptions {
  connectOptions?: RoomConnectOptions;
}

export interface UseLivekitRoomSimpleResult {
  participants: AudioParticipant[];
  isConnecting: boolean;
  isConnected: boolean;
  isMuted: boolean;
  error: Error | null;
  toggleMicrophone: () => Promise<void>;
  disconnect: (reason?: string) => Promise<void>;
  LiveKitView: () => JSX.Element | null;
  room: Room | null;
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

const formatReason = (reason?: DisconnectReason | string) => {
  if (reason === undefined || reason === null) return undefined;
  if (typeof reason === 'string') return reason;
  const reasonName = DisconnectReason[reason as number] as string | undefined;
  return reasonName ?? String(reason);
};

export const useLivekitRoomSimple = (
  session: LiveKitSessionState | null,
  callbacks: UseLivekitRoomSimpleCallbacks = {},
  options: UseLivekitRoomSimpleOptions = {}
): UseLivekitRoomSimpleResult => {
  const roomRef = useRef<Room | null>(null);
  const [participants, setParticipants] = useState<AudioParticipant[]>([]);
  const [isMuted, setIsMuted] = useState(false);
  const [isConnecting, setIsConnecting] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [room, setRoom] = useState<Room | null>(null);

  const latestHubIdRef = useRef<string | null>(session?.hubId ?? null);
  const callbacksRef = useRef(callbacks);
  const optionsRef = useRef(options);

  useEffect(() => {
    latestHubIdRef.current = session?.hubId ?? null;
    callbacksRef.current = callbacks;
    optionsRef.current = options;
  }, [session, callbacks, options]);

  useEffect(() => {
    if (!session?.credentials?.url || !session?.credentials?.token) {
      roomRef.current = null;
      setParticipants([]);
      setIsMuted(false);
      setIsConnecting(false);
      setIsConnected(false);
      return;
    }

    setError(null);
    setIsConnecting(true);
    callbacksRef.current.onConnecting?.(session.hubId);
  }, [session?.credentials?.token, session?.credentials?.url, session?.hubId]);

  useEffect(() => {
    const startAudio = async () => {
      try {
        await AudioSession.startAudioSession();
      } catch (err) {
        const audioError = err instanceof Error ? err : new Error(String(err));
        console.error('[LiveKit] Failed to start audio session', audioError);
        setError(audioError);
        const hubId = latestHubIdRef.current;
        if (hubId) {
          callbacksRef.current.onError?.(hubId, audioError);
        }
      }
    };

    startAudio();

    return () => {
      void AudioSession.stopAudioSession();
    };
  }, []);

  const handleRoomReady = useCallback((room: Room | null) => {
    roomRef.current = room;
    setRoom(room);
    if (!room) {
      setParticipants([]);
      setIsConnected(false);
      setIsConnecting(false);
    }
  }, []);

  const handleParticipants = useCallback((list: AudioParticipant[], localMuted: boolean) => {
    setParticipants(list);
    setIsMuted(localMuted);
  }, []);

  const handleConnected = useCallback(() => {
    setIsConnecting(false);
    setIsConnected(true);
    const hubId = latestHubIdRef.current;
    if (hubId) {
      callbacksRef.current.onConnected?.(hubId);
    }
  }, []);

  const handleDisconnected = useCallback((reason?: DisconnectReason | string) => {
    setIsConnecting(false);
    setIsConnected(false);
    const hubId = latestHubIdRef.current;
    if (hubId) {
      callbacksRef.current.onDisconnected?.(hubId, formatReason(reason));
    }
  }, []);

  const Bridge = useMemo(() => {
    const LiveKitBridge: React.FC = () => {
      const room = useRoomContext();
      const liveParticipants = useParticipants();

      useEffect(() => {
        handleRoomReady(room ?? null);
        return () => {
          handleRoomReady(null);
        };
      }, [room]);

      useEffect(() => {
        if (!room) return;
        const mapped = liveParticipants.map((participant) =>
          mapParticipant(participant, participant === room.localParticipant)
        );
        const localMuted = room?.localParticipant ? !room.localParticipant.isMicrophoneEnabled : false;
        handleParticipants(mapped, localMuted);
      }, [handleParticipants, liveParticipants, room]);

      useEffect(() => {
        if (!room) return;

        const onConnected = () => handleConnected();
        const onDisconnected = (reason?: DisconnectReason) => handleDisconnected(reason);

        room
          .on(RoomEvent.Connected, onConnected)
          .on(RoomEvent.Reconnected, onConnected)
          .on(RoomEvent.Disconnected, onDisconnected);

        if (room.state === ConnectionState.Connected) {
          onConnected();
        }

        return () => {
          room
            .off(RoomEvent.Connected, onConnected)
            .off(RoomEvent.Reconnected, onConnected)
            .off(RoomEvent.Disconnected, onDisconnected);
        };
      }, [handleConnected, handleDisconnected, room]);

      return null;
    };

    LiveKitBridge.displayName = 'LiveKitBridge';

    return LiveKitBridge;
  }, [handleConnected, handleDisconnected, handleParticipants, handleRoomReady]);

  const LiveKitView = useCallback(() => {
    const serverUrl = session?.credentials?.url;
    const token = session?.credentials?.token;

    if (!serverUrl || !token) {
      return null;
    }

    const connectOptions: RoomConnectOptions = {
      autoSubscribe: true,
      ...(optionsRef.current.connectOptions ?? {}),
    };

    return (
      <LiveKitRoom
        serverUrl={serverUrl}
        token={token}
        connect
        connectOptions={connectOptions}
        audio={{
          echoCancellation: true,
          autoGainControl: true,
          noiseSuppression: true,
        }}
        video={false}
        onError={(roomError) => {
          const formattedError = roomError instanceof Error ? roomError : new Error(String(roomError));
          setError(formattedError);
          const hubId = latestHubIdRef.current;
          if (hubId) {
            callbacksRef.current.onError?.(hubId, formattedError);
          }
        }}
      >
        <Bridge />
      </LiveKitRoom>
    );
  }, [Bridge, session?.credentials?.token, session?.credentials?.url]);

  const toggleMicrophone = useCallback(async () => {
    const room = roomRef.current;
    if (!room) return;

    try {
      const shouldEnable = room.localParticipant.isMicrophoneEnabled ? false : true;
      await room.localParticipant.setMicrophoneEnabled(shouldEnable);
      setIsMuted(!shouldEnable);
    } catch (toggleError) {
      const formattedError = toggleError instanceof Error
        ? toggleError
        : new Error(String(toggleError));
      setError(formattedError);
      const hubId = latestHubIdRef.current;
      if (hubId) {
        callbacksRef.current.onError?.(hubId, formattedError);
      }
    }
  }, []);

  const disconnect = useCallback(async (reason?: string) => {
    const room = roomRef.current;
    if (!room) {
      return;
    }

    try {
      await room.disconnect();
    } catch (err) {
      console.warn('[LiveKit] error disconnecting', err);
    } finally {
      roomRef.current = null;
    }

    const hubId = latestHubIdRef.current;
    if (hubId) {
      callbacksRef.current.onDisconnected?.(hubId, reason);
    }

    setParticipants([]);
    setIsConnected(false);
    setIsConnecting(false);
  }, []);

  useEffect(() => {
    const room = roomRef.current;
    const onData = callbacksRef.current.onData;
    if (!room || !onData) {
      return;
    }

    const handleData = (payload: Uint8Array, participant?: Participant, _kind?: any, topic?: string) => {
      const hubId = latestHubIdRef.current;
      if (hubId) {
        callbacksRef.current.onData?.(payload, participant, topic);
      }
    };

    room.on(RoomEvent.DataReceived, handleData);

    return () => {
      room.off(RoomEvent.DataReceived, handleData);
    };
  }, [roomRef.current, callbacksRef.current.onData]);

  return useMemo<UseLivekitRoomSimpleResult>(() => ({
    participants,
    isConnecting,
    isConnected,
    isMuted,
    error,
    toggleMicrophone,
    disconnect,
    LiveKitView,
    room,
  }), [LiveKitView, disconnect, error, isConnected, isConnecting, isMuted, participants, toggleMicrophone, room]);
};
