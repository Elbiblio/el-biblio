import React, { useEffect, useMemo, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, ActivityIndicator, Alert } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList, User } from '@/types';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { useChallengeStore } from '@/stores/ChallengeStore';
import { ArrowLeft, ArrowUp, Users, Clock, Star, X } from '@/components/Icons';
import { LinearGradient } from 'expo-linear-gradient';


type Props = NativeStackScreenProps<RootStackParamList, 'ChallengeDetail'>;

const ChallengeDetailScreen = ({ route, navigation }: Props) => {
  const { id } = route.params;
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const store = useChallengeStore();

  // Gather challenge from any list in the store
  const challenge = useMemo(() => {
    return (
      store.state.personalChallenges.find(c => c.id === id) ||
      store.state.communityChallenges.find(c => c.id === id) ||
      store.state.suggestedChallenges.find(c => c.id === id)
    );
  }, [store.state.personalChallenges, store.state.communityChallenges, store.state.suggestedChallenges, id]);

  const [loadingParticipants, setLoadingParticipants] = useState(false);

  useEffect(() => {
    navigation.setOptions?.({ headerShown: false });
  }, [navigation]);

  const handleJoinLeave = async () => {
    if (!challenge) return;
    try {
      if (challenge.hasJoined) {
        await store.leaveChallenge(challenge.id);
      } else {
        await store.joinChallenge(challenge.id);
      }
    } catch (e) {
      Alert.alert('Error', 'Unable to update challenge membership.');
    }
  };

  const handleUpvote = async () => {
    if (!challenge) return;
    try {
      await store.upvoteChallenge(challenge.id);
    } catch (e) {
      Alert.alert('Error', 'Unable to upvote challenge.');
    }
  };

  const refreshParticipants = async () => {
    if (!challenge) return;
    try {
      setLoadingParticipants(true);
      await store.fetchChallengeParticipants(challenge.id);
    } catch (e) {
      // already handled in store
    } finally {
      setLoadingParticipants(false);
    }
  };

  if (!challenge) {
    return (
      <View style={[styles.container, { paddingTop: 48 }] }>
        <View style={styles.header}>
          <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
            <ArrowLeft size={24} color={theme?.colors.text.primary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Challenge</Text>
          <View style={{ width: 40 }} />
        </View>
        <View style={styles.centerArea}>
          <ActivityIndicator color={theme?.colors.primary} />
          <Text style={styles.muted}>Loading challenge...</Text>
        </View>
      </View>
    );
  }

  const isVirtue = challenge.type === 'virtue';
  const color = isVirtue ? theme?.colors.success : theme?.colors.error;

  return (
    <View style={[styles.container, { paddingTop: 48 }] }>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme?.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Challenge</Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.card}>
          <LinearGradient colors={[`${color}10`, `${color}03`]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.cardGradient} />

          <View style={styles.rowBetween}>
            <View style={[styles.typeTag, { backgroundColor: `${color}15` }]}>
              {isVirtue ? <Star size={14} color={color} /> : <X size={14} color={color} />}
              <Text style={[styles.typeText, { color }]}>{isVirtue ? 'Virtue' : 'Vice'}</Text>
            </View>

            <View style={styles.rowCenter}>
              <Clock size={14} color={theme?.colors.text.secondary} />
              <Text style={styles.timeText}>{challenge.endTime || 'Today'}</Text>
            </View>
          </View>

          <Text style={styles.title}>{challenge.title}</Text>
          {!!challenge.description && (
            <Text style={styles.description}>{challenge.description}</Text>
          )}

          {challenge.category === 'community' && (
            <View style={[styles.rowBetween, { marginTop: theme?.spacing.md }]}>
              <View style={styles.rowCenter}>
                <Users size={16} color={theme?.colors.text.secondary} />
                <Text style={styles.muted}>{challenge.participants || 0} joined</Text>
              </View>
              <TouchableOpacity style={[styles.pill, { backgroundColor: `${theme?.colors.text.secondary}10` }]} onPress={refreshParticipants}>
                {loadingParticipants ? (
                  <ActivityIndicator size="small" color={theme?.colors.text.secondary} />
                ) : (
                  <Text style={styles.pillText}>Refresh</Text>
                )}
              </TouchableOpacity>
            </View>
          )}
        </View>

        <View style={styles.actions}>
          <TouchableOpacity style={[styles.actionBtn, { backgroundColor: `${theme?.colors.primary}15` }]} onPress={handleUpvote}>
            <ArrowUp size={18} color={theme?.colors.primary} />
            <Text style={[styles.actionText, { color: theme?.colors.primary }]}>Upvote</Text>
          </TouchableOpacity>

          <TouchableOpacity style={[styles.actionBtn, { backgroundColor: challenge.hasJoined ? `${theme?.colors.error}15` : `${theme?.colors.success}15` }]} onPress={handleJoinLeave}>
            <Text style={[styles.actionText, { color: challenge.hasJoined ? theme?.colors.error : theme?.colors.success }]}>
              {challenge.hasJoined ? 'Leave' : 'Join'}
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme?.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme?.spacing.md,
    paddingBottom: theme?.spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: theme?.colors.border,
  },
  backButton: {
    padding: theme?.spacing.sm,
  },
  headerTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
  },
  content: {
    padding: theme?.spacing.md,
  },
  card: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
  },
  cardGradient: {
    ...StyleSheet.absoluteFillObject,
    borderTopLeftRadius: theme?.borderRadius.lg,
    borderTopRightRadius: theme?.borderRadius.lg,
  },
  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  rowCenter: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.xs,
  },
  typeTag: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: theme?.spacing.xs,
    borderRadius: theme?.borderRadius.full,
  },
  typeText: {
    ...theme?.typography.caption.primary,
    marginLeft: theme?.spacing.xs,
    fontWeight: '600',
  },
  timeText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginLeft: theme?.spacing.xs,
  },
  title: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
    marginTop: theme?.spacing.sm,
  },
  description: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    marginTop: theme?.spacing.sm,
  },
  muted: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginTop: theme?.spacing.sm,
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: theme?.spacing.sm,
    marginTop: theme?.spacing.lg,
  },
  pill: {
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.xs,
    borderRadius: theme?.borderRadius.full,
  },
  pillText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
    color: theme?.colors.text.secondary,
  },
  actionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
    gap: theme?.spacing.xs,
  },
  actionText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
  },
  centerArea: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

export default ChallengeDetailScreen;
