import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';

import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  FlatList,
  ScrollView,
  Alert,
  Modal,
} from 'react-native';

import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Participant, ConnectionState } from 'livekit-client';
import Feather from 'react-native-vector-icons/Feather';
import { BlurView } from 'expo-blur';
import * as Haptics from 'expo-haptics';

import {
  ArrowLeft,
  MessageCircle,
  Users,
  Clock,
  Lock,
  Send,
} from '../components/Icons';
import AvatarStack from '@/components/AvatarStack';

import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList, WordHub, WordHubMessage, User } from '@/types';
import { formatTimeLeft, formatRelativeTime } from '@/utils/schedule';
import { observer } from 'mobx-react-lite';
import { useAuthStore, useWordHubsStore } from '@/stores/StoreProvider';
import { useLiveKitAudioRoom, AudioParticipant } from '@/hooks/useLiveKitAudioRoom';

type Props = NativeStackScreenProps<RootStackParamList, 'WordHubDetailScreen'>;

const WordHubDetailScreen = observer(({ navigation, route }: Props) => {
  const { hubId } = route.params;
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const wordHubsStore = useWordHubsStore();
  const { user } = useAuthStore();
  const hub = wordHubsStore.currentHub as WordHub | null;
  const messages = wordHubsStore.hubMessages as WordHubMessage[];
  const isLoading = wordHubsStore.isHubLoading;
  const liveKitSession = wordHubsStore.activeLiveKitSession;
  const lastSocketDisconnectReason = wordHubsStore.lastSocketDisconnectReason;
  const [message, setMessage] = useState('');
  const [isVerseModalVisible, setVerseModalVisible] = useState(false);
  const [verseReference, setVerseReference] = useState<string | null>(null);
  const [verseModalLoading, setVerseModalLoading] = useState(false);
  const [verseModalError, setVerseModalError] = useState<string | null>(null);
  const [verseModalText, setVerseModalText] = useState<string>('');
  const [verseModalTranslation, setVerseModalTranslation] = useState<string>('en-kjv');

  const wordHubsStoreRef = useRef(wordHubsStore);
  const hubIdRef = useRef(hubId);

  useEffect(() => {
    wordHubsStoreRef.current = wordHubsStore;
    hubIdRef.current = hubId;
  });

  const activeLiveKitSession = useMemo(() => (
    liveKitSession?.hubId === hubId ? liveKitSession : null
  ), [liveKitSession, hubId]);

  const hostUsers = useMemo(() => (
    hub?.members
      ?.map((member) => member.user)
      .filter((candidate): candidate is User => Boolean(candidate)) ?? []
  ), [hub?.members]);

  const isMember = useMemo(() => {
    if (!user?.id) return false;
    return Boolean(hub?.members?.some((member) => member.user_id === user.id));
  }, [hub?.members, user?.id]);

  const handleAudioConnecting = useCallback((id: string) => {
    if (id === hubIdRef.current) {
      wordHubsStoreRef.current.markLiveKitConnecting(id);
    }
  }, []);

  const handleAudioConnected = useCallback((id: string) => {
    if (id === hubIdRef.current && wordHubsStoreRef.current) {
      wordHubsStoreRef.current.markLiveKitConnected(id);
      if (typeof wordHubsStoreRef.current.clearSocketDisconnectReason === 'function') {
        wordHubsStoreRef.current.clearSocketDisconnectReason();
      }
    }
  }, []);

  const handleAudioDisconnected = useCallback((id: string, reason?: string) => {
    if (id === hubIdRef.current) {
      wordHubsStoreRef.current.markLiveKitDisconnected(id, reason);
    }
  }, []);

  const handleAudioError = useCallback((id: string, err: Error) => {
    if (id === hubIdRef.current) {
      wordHubsStoreRef.current.markLiveKitDisconnected(id, err.message);
    }
  }, []);

  const handleLiveKitData = useCallback((payload: Uint8Array | string, _participant?: Participant, topic?: string) => {
    const targetTopic = 'wordhub:message';
    if (topic && topic !== targetTopic) {
      return;
    }

    let text: string | null = null;
    if (typeof payload === 'string') {
      text = payload;
    } else if (payload instanceof Uint8Array) {
      if (typeof TextDecoder !== 'undefined') {
        try {
          text = new TextDecoder().decode(payload);
        } catch (decodeError) {
          console.warn('Failed to decode LiveKit payload with TextDecoder', decodeError);
        }
      }
      if (!text) {
        text = Array.from(payload)?.map(code => String.fromCharCode(code)).join('');
      }
    }

    if (!text) {
      return;
    }

    try {
      const data = JSON.parse(text);
      if (data?.type === 'wordhub_message' && data?.hubId === hubIdRef.current && data?.message) {
        wordHubsStoreRef.current.addMessageInRealTime(data.hubId, data.message as WordHubMessage);
      }
    } catch (parseError) {
      console.warn('Failed to parse LiveKit message payload', parseError);
    }
  }, []);

  const liveKitCallbacks = useMemo(() => ({
    onConnecting: handleAudioConnecting,
    onConnected: handleAudioConnected,
    onDisconnected: handleAudioDisconnected,
    onError: handleAudioError,
    onData: handleLiveKitData,
  }), [handleAudioConnecting, handleAudioConnected, handleAudioDisconnected, handleAudioError, handleLiveKitData]);

  const {
    LiveKitView: LiveKitRoomView,
    room,
    participants,
    isConnecting: audioConnecting,
    isConnected: audioConnected,
    isMuted: audioMuted,
    error: audioError,
    toggleMicrophone,
    disconnect: disconnectAudio,
  } = useLiveKitAudioRoom(activeLiveKitSession, liveKitCallbacks);

  const handleSendMessage = useCallback(async () => {
    const trimmed = message.trim();
    if (!trimmed) return;

    setMessage('');

    const sent = await wordHubsStoreRef.current.sendMessage(hubIdRef.current, trimmed);
    if (sent) {
      if (room && room.state === ConnectionState.Connected) {
        const packet = {
          type: 'wordhub_message' as const,
          hubId: hubIdRef.current,
          message: sent,
        };

        const payloadText = JSON.stringify(packet);
        const encoded = typeof TextEncoder !== 'undefined'
          ? new TextEncoder().encode(payloadText)
          : new Uint8Array(Array.from(payloadText)?.map(char => char.charCodeAt(0)));

        try {
          await room.localParticipant.publishData(encoded, {
            topic: 'wordhub:message',
            reliable: true,
          });
        } catch (publishError) {
          console.warn('Failed to broadcast message via LiveKit', publishError);
        }
      } else if (!room) {
        console.warn('Skipping LiveKit broadcast: room not available');
      } else {
        console.warn('Skipping LiveKit broadcast: room not connected', room.state);
      }
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    } else {
      setMessage(trimmed);
    }
  }, [message, room]);

  const disconnectAudioRef = useRef(disconnectAudio);
  useEffect(() => {
    disconnectAudioRef.current = disconnectAudio;
  }, [disconnectAudio]);

  const autoConnectAttemptedRef = useRef(false);
  const audioStateRef = useRef({ connected: false, connecting: false });

  useEffect(() => {
    audioStateRef.current = {
      connected: audioConnected,
      connecting: audioConnecting,
    };
  }, [audioConnected, audioConnecting]);

  useEffect(() => {
    const loadHubData = async () => {
      try {
        await Promise.all([
          wordHubsStoreRef.current.fetchHubById(hubIdRef.current),
          wordHubsStoreRef.current.fetchHubMessages(hubIdRef.current, 1),
        ]);
      } catch (error) {
        console.error('Error loading hub detail:', error);
      }
    };

    autoConnectAttemptedRef.current = false;
    loadHubData();

    return () => {
      wordHubsStoreRef.current.clearCurrentHub();
      autoConnectAttemptedRef.current = false;
    };
  }, [hubId]);

  useEffect(() => {
    return () => {
      const { connected, connecting } = audioStateRef.current;
      if (connected || connecting) {
        disconnectAudioRef.current('screen_unmount').catch(console.error);
      }
      wordHubsStoreRef.current.clearLiveKitSession(hubIdRef.current);
    };
  }, []);

  const isExpired = useMemo(() => {
    if (!hub?.expires_at) return false;
    return new Date(hub.expires_at).getTime() <= Date.now();
  }, [hub?.expires_at]);

  const shouldAutoConnect = useMemo(() => (
    !activeLiveKitSession &&
    isMember &&
    !isExpired &&
    !autoConnectAttemptedRef.current &&
    Boolean(hub) &&
    !audioConnected &&
    !audioConnecting
  ), [activeLiveKitSession, isMember, isExpired, hub, audioConnected, audioConnecting]);

  useEffect(() => {
    if (!shouldAutoConnect) {
      return;
    }

    autoConnectAttemptedRef.current = true;

    wordHubsStoreRef.current.refreshLiveKitSession(hubIdRef.current, user?.id)
      .catch((error) => {
        console.error('Auto-connect to LiveKit failed:', error);
        autoConnectAttemptedRef.current = false;
      });
  }, [shouldAutoConnect, user?.id]);

  useEffect(() => {
    if (!lastSocketDisconnectReason) {
      return;
    }

    wordHubsStoreRef.current.fetchHubMessages(hubIdRef.current, 1, { silent: true }).catch((error) => {
      console.error('Silent resync after LiveKit disconnect failed:', error);
    });
  }, [lastSocketDisconnectReason]);

  const audioStatusLabel = useMemo(() => {
    if (isExpired) return 'Ended';
    if (audioConnected) return 'Connected';
    if (audioConnecting) return 'Connecting…';
    return 'Not connected';
  }, [audioConnected, audioConnecting, isExpired]);

  const audioStatusStyle = useMemo(() => {
    if (isExpired) return styles.statusDisconnected;
    if (audioConnected) return styles.statusConnected;
    if (audioConnecting) return styles.statusConnecting;
    return styles.statusDisconnected;
  }, [audioConnected, audioConnecting, isExpired, styles.statusConnected, styles.statusConnecting, styles.statusDisconnected]);

  const handleJoinAudio = useCallback(async () => {
    if (isExpired || audioConnecting || audioConnected) return;

    try {
      await disconnectAudioRef.current('user_reconnect').catch(() => {});
    } catch {}

    wordHubsStoreRef.current.clearLiveKitSession(hubIdRef.current);
    await new Promise(resolve => setTimeout(resolve, 100));

    try {
      await wordHubsStoreRef.current.refreshLiveKitSession(hubIdRef.current, user?.id);
    } catch (error) {
      console.error('Failed to join audio:', error);
      autoConnectAttemptedRef.current = false;
    }
  }, [audioConnected, audioConnecting, user?.id]);

  const handleLeaveAudio = useCallback(async () => {
    try {
      await disconnectAudio('user_leave');
      wordHubsStore.clearLiveKitSession(hubId);
    } catch (error) {
      console.error('Failed to leave audio:', error);
    }
  }, [disconnectAudio, hubId]); // Removed wordHubsStore

  const handleLeaveHub = useCallback(async () => {
    if (audioConnected || audioConnecting) {
      await handleLeaveAudio();
    }

    const ok = await wordHubsStoreRef.current.leaveHub(hubIdRef.current);
    if (ok) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      navigation.goBack();
    }
  }, [audioConnected, audioConnecting, handleLeaveAudio, navigation]);

  const renderParticipant = useCallback(({ item }: { item: AudioParticipant }) => (
    <View style={styles.participantItem}>
      <View style={styles.participantIcon}>
        <Feather
          name={item.isSpeaking ? 'volume-2' : 'user'}
          size={18}
          color={theme.colors.text.inverse}
        />
      </View>
      <View style={styles.participantInfo}>
        <Text style={styles.participantName} numberOfLines={1}>
          {item.name || item.identity}
        </Text>
        <Text style={styles.participantMeta}>
          {item.isLocal ? 'You' : 'Participant'} · {item.isMuted ? 'Muted' : 'Live'}
        </Text>
      </View>
      {item.isLocal && (
        <Feather
          name={audioMuted ? 'mic-off' : 'mic'}
          size={18}
          color={audioMuted ? theme.colors.error : theme.colors.success}
        />
      )}
    </View>
  ), [audioMuted, styles, theme.colors.error, theme.colors.success, theme.colors.text.inverse]);

  if (isLoading) {
    return (
      <View style={[styles.container, { paddingTop: insets.top }]}>
        <ActivityIndicator color={theme.colors.primary} />
      </View>
    );
  }

  if (!hub) {
    return (
      <View style={[styles.container, { paddingTop: insets.top }]}>
        <Text style={styles.errorText}>Failed to load hub</Text>
      </View>
    );
  }

  const timeStatusLabel = useMemo(() => {
    if (!hub?.expires_at) return 'No schedule';
    if (isExpired) {
      const startedAt = hub.created_at ? new Date(hub.created_at) : null;
      const endedAt = new Date(hub.expires_at);
      const durationMs = startedAt ? endedAt.getTime() - startedAt.getTime() : 0;
      const durationMinutes = Math.max(0, Math.round(durationMs / 60000));
      return `Ended (${durationMinutes}m)`;
    }
    return formatTimeLeft(hub.expires_at);
  }, [hub?.created_at, hub?.expires_at, isExpired]);

  const handleTimePress = useCallback(() => {
    if (!hub?.expires_at) return;
    const endedAt = new Date(hub.expires_at);
    const relative = formatRelativeTime(hub.expires_at);
    const startedAt = hub.created_at ? formatRelativeTime(hub.created_at) : null;
    const duration = hub.created_at
      ? Math.max(0, Math.round((endedAt.getTime() - new Date(hub.created_at).getTime()) / 60000))
      : null;

    Alert.alert(
      'Session ended',
      [
        `Ended ${relative}`,
        duration !== null ? `Duration ${duration} minutes` : undefined,
        startedAt ? `Started ${startedAt}` : undefined,
      ].filter(Boolean).join('\n')
    );
  }, [hub?.created_at, hub?.expires_at]);

  const extractVerseReferences = useCallback((text: string) => {
    const regex = /\b([1-3]?\s?[A-Za-z]+)\s(\d{1,3})(?::(\d{1,3})(?:-(\d{1,3}))?)?/g;
    const matches: { start: number; end: number; reference: string }[] = [];
    let match: RegExpExecArray | null;
    while ((match = regex.exec(text)) !== null) {
      const reference = match[0];
      matches.push({ start: match.index, end: regex.lastIndex, reference });
    }
    return matches;
  }, []);

  const parseVerseReference = useCallback((reference: string) => {
    const parsed = reference.trim().match(/^([1-3]?\s?[A-Za-z]+)\s(\d{1,3})(?::(\d{1,3})(?:-(\d{1,3}))?)?/);
    if (!parsed) {
      throw new Error('Unable to parse verse reference');
    }
    const book = parsed[1].replace(/\s+/g, '').toLowerCase();
    const chapter = parsed[2];
    const verse = parsed[3];
    return { book, chapter, verse };
  }, []);

  const fetchVerseContent = useCallback(async (reference: string) => {
    try {
      setVerseModalLoading(true);
      setVerseModalError(null);
      const { book, chapter, verse } = parseVerseReference(reference);
      const translation = verseModalTranslation;
      const response = await fetch(`https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles/${translation}/books/${book}/chapters/${chapter}/verses/${verse}.json`);
      if (!response.ok) {
        throw new Error('Failed to load verse');
      }
      const data = await response.json();
      setVerseModalText(data?.text ?? '');
    } catch (error) {
      setVerseModalError(error instanceof Error ? error.message : 'Failed to load verse');
      setVerseModalText('');
    } finally {
      setVerseModalLoading(false);
    }
  }, [parseVerseReference, verseModalTranslation]);

  const handleVersePress = useCallback((reference: string) => {
    setVerseReference(reference);
    setVerseModalVisible(true);
    void fetchVerseContent(reference);
  }, [fetchVerseContent]);

  const handleCloseVerseModal = useCallback(() => {
    setVerseModalVisible(false);
    setVerseReference(null);
    setVerseModalError(null);
    setVerseModalText('');
  }, []);

  const renderMessageText = useCallback((text: string) => {
    const segments = [] as { key: string; content: string; reference?: string }[];
    const matches = extractVerseReferences(text);

    if (matches.length === 0) {
      return <Text style={styles.messageText}>{text}</Text>;
    }

    let cursor = 0;
    matches.forEach((match, index) => {
      if (cursor < match.start) {
        segments.push({ key: `text-${index}-${cursor}`, content: text.slice(cursor, match.start) });
      }
      segments.push({
        key: `ref-${index}-${match.start}`,
        content: text.slice(match.start, match.end),
        reference: match.reference,
      });
      cursor = match.end;
    });

    if (cursor < text.length) {
      segments.push({ key: `tail-${cursor}`, content: text.slice(cursor) });
    }

    return (
      <Text style={styles.messageText}>
        {segments.map((segment) => (
          segment.reference ? (
            <Text
              key={segment.key}
              style={styles.verseHighlight}
              onPress={() => handleVersePress(segment.reference!)}
            >
              {segment.content}
            </Text>
          ) : (
            <Text key={segment.key}>{segment.content}</Text>
          )
        ))}
      </Text>
    );
  }, [extractVerseReferences, styles.messageText, styles.verseHighlight, handleVersePress]);

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>{hub.title}</Text>
        <TouchableOpacity onPress={handleLeaveHub}>
          <Text style={styles.leaveText}>Leave</Text>
        </TouchableOpacity>
      </View>

      {/* Hub Info */}
      <View style={styles.hubInfo}>
        <BlurView intensity={10} style={styles.hubInfoContent}>
          <View style={styles.hubHeader}>
            {hub.is_private && (
              <Lock size={16} color={theme.colors.text.secondary} />
            )}
            <Text style={styles.hubDescription}>{hub.description}</Text>
          </View>

          <View style={styles.statsContainer}>
            <View style={styles.stat}>
              <Users size={16} color={theme.colors.text.secondary} />
              <Text style={styles.statText}>{hub.members?.length ?? 0} members</Text>
            </View>
            <View style={styles.stat}>
              <MessageCircle size={16} color={theme.colors.text.secondary} />
              <Text style={styles.statText}>{hub.messages?.length ?? 0} messages</Text>
            </View>
            <TouchableOpacity style={styles.stat} onPress={handleTimePress} disabled={!hub.expires_at || isExpired}>
            <Clock size={16} color={theme.colors.text.secondary} />
            <Text style={styles.statText}>{timeStatusLabel}</Text>
          </TouchableOpacity>
          </View>

          <AvatarStack
            users={hub.authors ?? []}
            maxAvatars={5}
            size={32}
            offset={20}
            showRemaining
          />
        </BlurView>
      </View>

      {/* Audio Room */}
      {!isExpired && (
      <View style={styles.audioCard}>
        <View style={styles.audioHeader}>
          <Text style={styles.audioTitle}>Live Audio Room</Text>
          <View style={[styles.statusBadge, audioStatusStyle]}>
            {audioConnecting && !audioConnected && (
              <ActivityIndicator color={theme.colors.primary} size="small" />
            )}
            <Text style={styles.statusText}>{audioStatusLabel}</Text>
          </View>
        </View>
        {hostUsers.length > 0 && (
          <View style={styles.hostRow}>
            <Text style={styles.hostLabel}>Hosts & Speakers</Text>
            <AvatarStack
              users={hostUsers}
              maxAvatars={4}
              size={30}
              offset={18}
            />
          </View>
        )}

        <View style={styles.audioRoomContainer}>
          {LiveKitRoomView ? (
            <LiveKitRoomView />
          ) : (
            <View style={styles.audioRoomPlaceholder}>
              <Text style={styles.audioRoomPlaceholderText}>Audio room not available</Text>
            </View>
          )}
        </View>

        <FlatList
          data={participants}
          keyExtractor={(item) => item.identity}
          renderItem={renderParticipant}
          ListEmptyComponent={(
            <View style={styles.participantEmpty}>
              <Text style={styles.participantEmptyText}>
                {audioConnecting ? 'Connecting to room…' : 'No one is speaking yet.'}
              </Text>
            </View>
          )}
          style={styles.participantsList}
          contentContainerStyle={participants.length === 0 ? styles.participantsEmptyContent : undefined}
        />

        <View style={styles.audioControls}>
          {audioConnecting && !audioConnected && activeLiveKitSession?.isConnecting && (
            <View style={styles.audioLoader}>
              <ActivityIndicator color={theme.colors.primary} size="small" />
              <Text style={styles.audioLoaderText}>Joining audio room…</Text>
            </View>
          )}
          {audioConnected ? (
            <>
              <TouchableOpacity
                style={[styles.controlButton, audioMuted ? styles.controlButtonMuted : styles.controlButtonActive]}
                onPress={toggleMicrophone}
              >
                <Feather
                  name={audioMuted ? 'mic-off' : 'mic'}
                  size={20}
                  color={theme.colors.text.inverse}
                />
                <Text style={styles.controlButtonText}>{audioMuted ? 'Unmute' : 'Mute'}</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.controlButton, styles.controlButtonSecondary]}
                onPress={handleLeaveAudio}
              >
                <Feather name="phone-off" size={20} color={theme.colors.error} />
                <Text style={styles.controlButtonSecondaryText}>Leave Audio</Text>
              </TouchableOpacity>
            </>
          ) : (
            <TouchableOpacity
              style={[styles.controlButton, styles.controlButtonPrimary]}
              onPress={handleJoinAudio}
              disabled={audioConnecting}
            >
              <Feather name="headphones" size={20} color={theme.colors.text.inverse} />
              <Text style={styles.controlButtonText}>
                {audioConnecting ? 'Joining…' : 'Join Audio'}
              </Text>
            </TouchableOpacity>
          )}
        </View>
      </View>
      )}

      {/* Messages */}
      <ScrollView
        style={styles.messagesContainer}
        contentContainerStyle={styles.messagesContent}
      >
        {messages?.map((msg) => (
          <View key={msg.id} style={styles.messageItem}>
            <Text style={styles.messageAuthor}>{msg.user.name}</Text>
            {renderMessageText(msg.message)}
            <Text style={styles.messageTime}>
              {new Date(msg.created_at).toLocaleTimeString()}
            </Text>
          </View>
        ))}
      </ScrollView>

      {/* Message Input */}
      <View style={styles.inputContainer}>
        <TextInput
          style={styles.input}
          placeholder="Type your message..."
          value={message}
          onChangeText={setMessage}
          multiline
          maxLength={1024}
        />
        <TouchableOpacity
          style={[styles.sendButton, !message.trim() && styles.sendButtonDisabled]}
          onPress={handleSendMessage}
          disabled={!message.trim()}
        >
          <Send size={20} color={theme.colors.text.inverse} />
        </TouchableOpacity>
      </View>
      <Modal
        visible={isVerseModalVisible}
        transparent
        animationType="fade"
        onRequestClose={handleCloseVerseModal}
      >
        <View style={styles.verseModalOverlay}>
          <View style={styles.verseModalContainer}>
            <BlurView intensity={20} style={StyleSheet.absoluteFill} />
            <View style={styles.verseModalContent}>
              <View style={styles.verseModalHeader}>
                <Text style={styles.verseModalTitle}>{verseReference}</Text>
                <TouchableOpacity onPress={handleCloseVerseModal}>
                  <Feather name="x" size={20} color={theme.colors.text.secondary} />
                </TouchableOpacity>
              </View>
              {verseModalLoading ? (
                <ActivityIndicator color={theme.colors.primary} />
              ) : verseModalError ? (
                <Text style={styles.verseModalError}>{verseModalError}</Text>
              ) : (
                <ScrollView style={styles.verseModalScroll}>
                  <Text style={styles.verseModalText}>{verseModalText}</Text>
                  <Text style={styles.verseModalMeta}>{verseModalTranslation.toUpperCase()}</Text>
                </ScrollView>
              )}
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
});

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  title: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  leaveText: {
    ...theme.typography.caption.primary,
    color: theme.colors.error,
  },
  hubInfo: {
    padding: theme.spacing.md,
  },
  audioCard: {
    marginHorizontal: theme.spacing.md,
    marginBottom: theme.spacing.md,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    shadowColor: theme.colors.shadow,
    shadowOpacity: 0.08,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 2,
  },
  audioHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.xs,
  },
  audioTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  audioSubtitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.sm,
  },
  audioErrorText: {
    ...theme.typography.caption.primary,
    color: theme.colors.error,
    marginBottom: theme.spacing.sm,
  },
  audioRoomContainer: {
    marginTop: theme.spacing.sm,
    marginBottom: theme.spacing.sm,
    borderRadius: theme.borderRadius.md,
    overflow: 'hidden',
    backgroundColor: theme.colors.surface,
    minHeight: 140,
    justifyContent: 'center',
    alignItems: 'center',
  },
  audioRoomPlaceholder: {
    paddingVertical: theme.spacing.lg,
    paddingHorizontal: theme.spacing.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  audioRoomPlaceholderText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  verseHighlight: {
    color: theme.colors.primary,
    textDecorationLine: 'underline',
    fontWeight: '600',
  },
  verseModalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.4)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme.spacing.lg,
  },
  verseModalContainer: {
    width: '100%',
    maxWidth: 420,
    borderRadius: theme.borderRadius.lg,
    overflow: 'hidden',
  },
  verseModalContent: {
    padding: theme.spacing.lg,
    backgroundColor: `${theme.colors.surface}F2`,
    gap: theme.spacing.md,
  },
  verseModalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  verseModalTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.primary,
  },
  verseModalScroll: {
    maxHeight: 240,
  },
  verseModalText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    lineHeight: 24,
  },
  verseModalMeta: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.sm,
  },
  verseModalError: {
    ...theme.typography.caption.primary,
    color: theme.colors.error,
    textAlign: 'center',
  },
  hostRow: {
    marginTop: theme.spacing.sm,
    marginBottom: theme.spacing.sm,
    gap: theme.spacing.xs,
  },
  hostLabel: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  statusBadge: {
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
  },
  statusText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
  statusConnected: {
    backgroundColor: theme.colors.success,
  },
  statusConnecting: {
    backgroundColor: theme.colors.warning,
  },
  statusDisconnected: {
    backgroundColor: theme.colors.border,
  },
  participantsList: {
    maxHeight: 180,
  },
  participantsEmptyContent: {
    paddingVertical: theme.spacing.md,
  },
  participantItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme.spacing.sm,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: `${theme.colors.border}80`,
  },
  participantIcon: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: theme.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: theme.spacing.sm,
  },
  participantInfo: {
    flex: 1,
  },
  participantName: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  participantMeta: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  participantEmpty: {
    alignItems: 'center',
    paddingVertical: theme.spacing.sm,
  },
  participantEmptyText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  audioControls: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  audioLoader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.xs,
  },
  audioLoaderText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  controlButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
  },
  controlButtonPrimary: {
    backgroundColor: theme.colors.primary,
  },
  controlButtonActive: {
    backgroundColor: theme.colors.success,
  },
  controlButtonMuted: {
    backgroundColor: theme.colors.warning,
  },
  controlButtonSecondary: {
    backgroundColor: `${theme.colors.surface}00`,
    borderWidth: 1,
    borderColor: theme.colors.error,
  },
  controlButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  controlButtonSecondaryText: {
    ...theme.typography.caption.primary,
    color: theme.colors.error,
    fontWeight: '600',
  },
  hubInfoContent: {
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: `${theme.colors.surface}80`,
  },
  hubHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    marginBottom: theme.spacing.sm,
  },
  hubDescription: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginVertical: theme.spacing.md,
  },
  stat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  statText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  messagesContainer: {
    flex: 1,
  },
  messagesContent: {
    padding: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  messageItem: {
    backgroundColor: theme.colors.surface,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
  },
  messageAuthor: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    marginBottom: 4,
  },
  messageText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  messageTime: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: 4,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: theme.spacing.md,
    gap: theme.spacing.sm,
    borderTopWidth: 1,
    borderTopColor: theme.colors.border,
  },
  input: {
    flex: 1,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.full,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    maxHeight: 100,
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  sendButton: {
    backgroundColor: theme.colors.primary,
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sendButtonDisabled: {
    opacity: 0.5,
  },
  errorText: {
    ...theme.typography.body.sans,
    color: theme.colors.error,
    textAlign: 'center',
  },
});

export default WordHubDetailScreen;