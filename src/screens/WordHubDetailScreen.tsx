import React, { useState, useEffect, useCallback } from 'react';

import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Platform,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import * as Haptics from 'expo-haptics';
import {
  ArrowLeft,
  MessageCircle,
  Users,
  Clock,
  Star,
  Lock,
  Send,
  BookmarkSimple,
  Share,
} from '../components/Icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList, WordHub, WordHubMessage } from '@/types';
import { formatTimeLeft } from '@/utils/schedule';
import AvatarStack from '@/components/AvatarStack';
import { observer } from 'mobx-react-lite';
import { useWordHubsStore } from '@/stores/StoreProvider';

type Props = NativeStackScreenProps<RootStackParamList, 'WordHubDetailScreen'>;

const WordHubDetailScreen: React.FC<Props> = observer(({ navigation, route }) => {
  const { hubId } = route.params;
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const wordHubsStore = useWordHubsStore();
  const hub = wordHubsStore.currentHub as WordHub | null;
  const messages = wordHubsStore.hubMessages as WordHubMessage[];
  const isLoading = wordHubsStore.isHubLoading;
  const [message, setMessage] = useState('');

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

  useEffect(() => {
    fetchHubDetails();
    return () => {
      wordHubsStore.clearCurrentHub();
    };
  }, [fetchHubDetails, wordHubsStore]);

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
};

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