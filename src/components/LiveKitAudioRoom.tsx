import React, { useEffect, useMemo } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity, ActivityIndicator } from 'react-native';
import {
  AudioSession,
  LiveKitRoom,
  useTracks,
  useParticipants,
  useRoomContext,
  TrackReferenceOrPlaceholder,
  isTrackReference,
} from '@livekit/react-native';
import { Track } from 'livekit-client';
import Feather from 'react-native-vector-icons/Feather';
import { useTheme } from '@/contexts/ThemeContext';
import type { LiveKitSessionState } from '@/stores/WordHubsStore';

interface LiveKitAudioRoomProps {
  session: LiveKitSessionState | null;
  onConnecting?: () => void;
  onConnected?: () => void;
  onDisconnected?: () => void;
  onError?: (error: Error) => void;
}

const AudioRoomContent = () => {
  const theme = useTheme();
  const room = useRoomContext();
  const participants = useParticipants();
  const tracks = useTracks([Track.Source.Microphone]);

  const renderParticipant = React.useCallback(({ item }: { item: any }) => {
    const participant = item.participant;
    if (!participant) return null;

    const isLocal = participant.identity === room?.localParticipant?.identity;
    const isMuted = !participant.isMicrophoneEnabled;
    const isSpeaking = participant.isSpeaking;

    return (
      <View style={styles.participantItem}>
        <View style={styles.participantIcon}>
          <Feather
            name={isSpeaking ? 'volume-2' : 'user'}
            size={18}
            color={theme.colors.text.inverse}
          />
        </View>
        <View style={styles.participantInfo}>
          <Text style={[styles.participantName, { color: theme.colors.text.primary }]} numberOfLines={1}>
            {participant.name || participant.identity}
          </Text>
          <Text style={[styles.participantMeta, { color: theme.colors.text.secondary }]}>
            {isLocal ? 'You' : 'Participant'} · {isMuted ? 'Muted' : 'Live'}
          </Text>
        </View>
        {isLocal && (
          <Feather
            name={isMuted ? 'mic-off' : 'mic'}
            size={18}
            color={isMuted ? theme.colors.error : theme.colors.success}
          />
        )}
      </View>
    );
  }, [theme.colors.text.inverse, theme.colors.text.primary, theme.colors.text.secondary, theme.colors.error, theme.colors.success]);

  return (
    <FlatList
      data={participants}
      keyExtractor={(item) => item.identity}
      renderItem={renderParticipant}
      ListEmptyComponent={(
        <View style={styles.emptyContainer}>
          <Text style={[styles.emptyText, { color: theme.colors.text.secondary }]}>
            No participants yet
          </Text>
        </View>
      )}
      contentContainerStyle={participants.length === 0 ? styles.emptyContent : undefined}
      initialNumToRender={10}
      maxToRenderPerBatch={10}
      windowSize={11}
      removeClippedSubviews
      showsVerticalScrollIndicator={false}
    />
  );
};

export const LiveKitAudioRoom: React.FC<LiveKitAudioRoomProps> = ({
  session,
  onConnecting,
  onConnected,
  onDisconnected,
  onError,
}) => {
  const theme = useTheme();

  useEffect(() => {
    const startAudio = async () => {
      try {
        await AudioSession.startAudioSession();
      } catch (error) {
        console.error('Failed to start audio session:', error);
        onError?.(error instanceof Error ? error : new Error(String(error)));
      }
    };

    startAudio();

    return () => {
      AudioSession.stopAudioSession();
    };
  }, [onError]);

  const serverUrl = session?.credentials?.url;
  const token = session?.credentials?.token;

  if (!serverUrl || !token) {
    return (
      <View style={styles.emptyContainer}>
        <Text style={[styles.emptyText, { color: theme.colors.text.secondary }]}>
          No active audio session
        </Text>
      </View>
    );
  }

  return (
    <LiveKitRoom
      serverUrl={serverUrl}
      token={token}
      connect={true}
      options={{
        adaptiveStream: true,
        dynacast: true,
        audioCaptureDefaults: {
          echoCancellation: true,
          autoGainControl: true,
          noiseSuppression: true,
        },
      }}
      audio={true}
      video={false}
      onConnected={() => {
        console.log('[LiveKit] Connected to room');
        onConnected?.();
      }}
      onDisconnected={() => {
        console.log('[LiveKit] Disconnected from room');
        onDisconnected?.();
      }}
      onError={(error) => {
        console.error('[LiveKit] Room error:', error);
        onError?.(error);
      }}
    >
      <AudioRoomContent />
    </LiveKitRoom>
  );
};

const styles = StyleSheet.create({
  participantItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  participantIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  participantInfo: {
    flex: 1,
  },
  participantName: {
    fontSize: 15,
    fontWeight: '600',
    marginBottom: 2,
  },
  participantMeta: {
    fontSize: 13,
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 40,
  },
  emptyContent: {
    flexGrow: 1,
    justifyContent: 'center',
  },
  emptyText: {
    fontSize: 14,
  },
});
