import React, { useState, useEffect, useCallback, useMemo } from 'react';

import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  FlatList,
} from 'react-native';

import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { BlurView } from 'expo-blur';
import * as Haptics from 'expo-haptics';
import Feather from 'react-native-vector-icons/Feather';

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
import { formatTimeLeft } from '@/utils/schedule';
import { observer } from 'mobx-react-lite';
import { useWordHubsStore } from '@/stores/StoreProvider';
import { useLiveKitAudioRoom, AudioParticipant } from '@/hooks/useLiveKitAudioRoom';

type Props = NativeStackScreenProps<RootStackParamList, 'WordHubDetailScreen'>;

const WordHubDetailScreen = observer(({ navigation, route }: Props) => {
  const { hubId } = route.params;
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const wordHubsStore = useWordHubsStore();
  const hub = wordHubsStore.currentHub as WordHub | null;
  const messages = wordHubsStore.hubMessages as WordHubMessage[];
  const isLoading = wordHubsStore.isHubLoading;
  const liveKitSession = wordHubsStore.activeLiveKitSession;
  const activeLiveKitSession = useMemo(() => (
    liveKitSession?.hubId === hubId ? liveKitSession : null
  ), [liveKitSession, hubId]);
  const [message, setMessage] = useState('');
  const hostUsers = useMemo(() => (
    hub?.members
      ?.map((member) => member.user)
      .filter((user): user is User => Boolean(user)) ?? []
  ), [hub?.members]);

  const fetchHubDetails = useCallback(async () => {
    await wordHubsStore.fetchHubById(hubId);
    await wordHubsStore.fetchHubMessages(hubId, 1);
  }, [hubId, wordHubsStore]);

  const handleSendMessage = async () => {
    if (!message.trim()) return;
    const sent = await wordHubsStore.sendMessage(hubId, message.trim());
    if (sent) {
      setMessage('');
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    }
  };

  const handleLeaveHub = async () => {
    const ok = await wordHubsStore.leaveHub(hubId);
    if (ok) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      navigation.goBack();
    }
  };

  const handleAudioConnecting = useCallback((id: string) => {
    if (id === hubId) {
      wordHubsStore.markLiveKitConnecting(id);
    }
  }, [hubId, wordHubsStore]);

  const handleAudioConnected = useCallback((id: string) => {
    if (id === hubId) {
      wordHubsStore.markLiveKitConnected(id);
    }
  }, [hubId, wordHubsStore]);

  const handleAudioDisconnected = useCallback((id: string, reason?: string) => {
    if (id === hubId) {
      wordHubsStore.markLiveKitDisconnected(id, reason);
    }
  }, [hubId, wordHubsStore]);

  const handleAudioError = useCallback((id: string, err: Error) => {
    if (id === hubId) {
      wordHubsStore.markLiveKitDisconnected(id, err.message);
    }
  }, [hubId, wordHubsStore]);

  const {
    participants,
    isConnecting: audioConnecting,
    isConnected: audioConnected,
    isMuted: audioMuted,
    error: audioError,
    toggleMicrophone,
    disconnect: disconnectAudio,
  } = useLiveKitAudioRoom(activeLiveKitSession, {
    onConnecting: handleAudioConnecting,
    onConnected: handleAudioConnected,
    onDisconnected: handleAudioDisconnected,
    onError: handleAudioError,
  });

  useEffect(() => {
    fetchHubDetails();
    return () => {
      disconnectAudio('screen_unmount').catch(() => undefined);
      wordHubsStore.clearLiveKitSession(hubId);
      wordHubsStore.clearCurrentHub();
    };
  }, [fetchHubDetails, disconnectAudio, wordHubsStore, hubId]);

  const audioStatusLabel = useMemo(() => {
    if (audioConnected) return 'Connected';
    if (audioConnecting) return 'Connecting…';
    return 'Not connected';
  }, [audioConnected, audioConnecting]);

  const audioStatusStyle = useMemo(() => {
    if (audioConnected) return styles.statusConnected;
    if (audioConnecting) return styles.statusConnecting;
    return styles.statusDisconnected;
  }, [audioConnected, audioConnecting, styles.statusConnected, styles.statusConnecting, styles.statusDisconnected]);

  const handleJoinAudio = useCallback(async () => {
    await wordHubsStore.refreshLiveKitSession(hubId);
  }, [wordHubsStore, hubId]);

  const handleLeaveAudio = useCallback(async () => {
    await disconnectAudio('user_leave');
    wordHubsStore.clearLiveKitSession(hubId);
  }, [disconnectAudio, wordHubsStore, hubId]);

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
              <Text style={styles.statText}>{hub.memberCount} members</Text>
            </View>
            <View style={styles.stat}>
              <MessageCircle size={16} color={theme.colors.text.secondary} />
              <Text style={styles.statText}>{hub.messageCount} messages</Text>
            </View>
            <View style={styles.stat}>
              <Clock size={16} color={theme.colors.text.secondary} />
              <Text style={styles.statText}>{formatTimeLeft(hub.expires_at)}</Text>
            </View>
          </View>

          <AvatarStack
            users={hub.authors}
            maxAvatars={5}
            size={32}
            offset={20}
            showRemaining
          />
        </BlurView>
      </View>

      {/* Audio Room */}
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
        {audioError && (
          <Text style={styles.audioErrorText}>
            {audioError.message}
          </Text>
        )}

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

      {/* Messages */}
      <ScrollView
        style={styles.messagesContainer}
        contentContainerStyle={styles.messagesContent}
      >
        {messages.map((msg) => (
          <View key={msg.id} style={styles.messageItem}>
            <Text style={styles.messageAuthor}>{msg.user.name}</Text>
            <Text style={styles.messageText}>{msg.message}</Text>
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