import React, { memo } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Modal } from 'react-native';
import { Star } from '@/components/Icons';
import { Theme } from '@/theme';
import { Challenge } from '@/types/challenges';

export interface VoteModalProps {
  visible: boolean;
  theme: Theme;
  targetChallenge: Challenge | null;
  voteSpiritual: number;
  voteEffort: number;
  isLoading: boolean;
  onChangeSpiritual: (value: number) => void;
  onChangeEffort: (value: number) => void;
  onSubmit: () => void;
  onClose: () => void;
}

const VoteModal = memo(({
  visible,
  theme,
  targetChallenge,
  voteSpiritual,
  voteEffort,
  isLoading,
  onChangeSpiritual,
  onChangeEffort,
  onSubmit,
  onClose,
}: VoteModalProps) => {
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const tier = (targetChallenge as any)?.tier;
  const points = (targetChallenge as any)?.points;
  const createdAt = targetChallenge ? new Date((targetChallenge as any).createdAt || new Date()) : new Date();
  const now = new Date();
  const remainingMs = Math.max(0, (createdAt.getTime() + 3*24*60*60*1000) - now.getTime());
  const remainingDays = Math.floor(remainingMs / (24*60*60*1000));
  const remainingHours = Math.floor((remainingMs % (24*60*60*1000)) / (60*60*1000));
  const votes = (targetChallenge?.upvotes || 0);

  return (
    <Modal visible={visible} animationType="fade" transparent onRequestClose={onClose}>
      <View style={styles.modalBackdrop}>
        <View style={styles.modalCard}>
          <Text style={styles.modalTitle}>Rate this Suggestion</Text>
          
          {(tier || points) && (
            <View style={{ marginBottom: theme?.spacing.md }}>
              {!!tier && (
                <View style={[styles.badge, { alignSelf: 'flex-start', backgroundColor: `${theme?.colors.primary}10` }]}> 
                  <Star size={14} color={theme?.colors.primary} />
                  <Text style={[styles.badgeText, { color: theme?.colors.primary }]}>Community suggested tier: {tier}</Text>
                </View>
              )}
              {!!points && !tier && (
                <View style={[styles.badge, { alignSelf: 'flex-start', backgroundColor: `${theme?.colors.primary}10` }]}> 
                  <Star size={14} color={theme?.colors.primary} />
                  <Text style={[styles.badgeText, { color: theme?.colors.primary }]}>Community suggested points: {points}</Text>
                </View>
              )}
              <Text style={[styles.voteWindowText, { marginTop: theme?.spacing.sm }]}>
                Voting is open for 3 days or until 100 votes are reached · {votes}/100
              </Text>
              {!!remainingMs && (
                <Text style={[styles.voteWindowText, { opacity: 0.8 }]}>Time left: {remainingDays}d {remainingHours}h</Text>
              )}
            </View>
          )}

          <Text style={styles.voteLabel}>Spiritual Value / Growth</Text>
          <View style={styles.pillRow}>
            {[1,2,3,4,5].map((n) => (
              <TouchableOpacity key={n} style={[styles.pill, voteSpiritual === n && styles.pillActive]} onPress={() => onChangeSpiritual(n)}>
                <Text style={[styles.pillText, voteSpiritual === n && styles.pillTextActive]}>{n}</Text>
              </TouchableOpacity>
            ))}
          </View>

          <Text style={[styles.voteLabel, { marginTop: theme?.spacing.md }]}>Effort Required</Text>
          <View style={styles.pillRow}>
            {[1,2,3,4,5].map((n) => (
              <TouchableOpacity key={n} style={[styles.pill, voteEffort === n && styles.pillActive]} onPress={() => onChangeEffort(n)}>
                <Text style={[styles.pillText, voteEffort === n && styles.pillTextActive]}>{n}</Text>
              </TouchableOpacity>
            ))}
          </View>

          <View style={[styles.formActions, { marginTop: theme?.spacing.md }]}> 
            <TouchableOpacity style={[styles.formButton, styles.cancelButton]} onPress={onClose}>
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.formButton, styles.createButton, isLoading && { opacity: 0.7 }]}
              onPress={onSubmit}
              disabled={isLoading}
            >
              <Text style={styles.createButtonText}>Submit Vote</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
});

const createStyles = (theme: Theme) => StyleSheet.create({
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.3)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme?.spacing.md,
  },
  modalCard: {
    width: '100%',
    maxWidth: 520,
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.lg,
    borderWidth: 1,
    borderColor: theme?.colors.border,
  },
  modalTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.md,
  },
  voteLabel: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.secondary,
    marginBottom: theme?.spacing.xs,
  },
  voteWindowText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontSize: 12,
  },
  pillRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  pill: {
    flex: 1,
    marginHorizontal: 4,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    alignItems: 'center',
  },
  pillActive: {
    backgroundColor: `${theme?.colors.primary}15`,
    borderColor: `${theme?.colors.primary}40`,
  },
  pillText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
  },
  pillTextActive: {
    color: theme?.colors.primary,
  },
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: 6,
    borderRadius: theme?.borderRadius.full,
    gap: 6,
  },
  badgeText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
  },
  formActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  formButton: {
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.lg,
    borderRadius: theme?.borderRadius.full,
    marginLeft: theme?.spacing.sm,
  },
  cancelButton: {
    backgroundColor: `${theme?.colors.text.secondary}10`,
  },
  cancelButtonText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
  },
  createButton: {
    backgroundColor: theme?.colors.primary,
  },
  createButtonText: {
    ...theme?.typography.body.sans,
    color: '#FFF',
    fontWeight: '600',
  },
});

VoteModal.displayName = 'VoteModal';

export default VoteModal;
