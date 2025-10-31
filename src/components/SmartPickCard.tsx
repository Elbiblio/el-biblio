import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useTheme } from '@/contexts/ThemeContext';
import { Challenge } from '@/types/challenges';
import { differenceInMinutes, format } from 'date-fns';
import { Trophy, Clock, Star } from '@/components/Icons';

export type SmartPickCardProps = {
  challenge: Challenge;
  onPressJoin?: (challenge: Challenge) => void;
  onPressDismiss?: () => void;
  ctaLabel?: string;
};

const SmartPickCard: React.FC<SmartPickCardProps> = ({ challenge, onPressJoin, onPressDismiss, ctaLabel = 'Join challenge' }) => {
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const expiresAt = challenge.expiresAt ? new Date(challenge.expiresAt) : null;
  const now = new Date();
  let timeLabel = 'Starts soon';

  if (expiresAt) {
    const mins = differenceInMinutes(expiresAt, now);
    if (mins <= 0) {
      timeLabel = 'Ending now';
    } else if (mins < 90) {
      timeLabel = `Ends in ${mins} min`;
    } else if (mins < 12 * 60) {
      const hours = Math.floor(mins / 60);
      const remaining = mins % 60;
      timeLabel = `Ends in ${hours}h${remaining ? ` ${remaining}m` : ''}`;
    } else {
      timeLabel = `Ends at ${format(expiresAt, 'h:mm a')}`;
    }
  }

  return (
    <LinearGradient
      colors={[`${theme?.colors.primary}1A`, `${theme?.colors.primary}08`]}
      style={styles.container}
    >
      <View style={styles.headerRow}>
        <View style={styles.badge}>
          <Trophy size={14} color={theme?.colors.primary} />
          <Text style={styles.badgeText}>{challenge.theme_name ?? 'Recommended'}</Text>
        </View>
        {challenge.upvotes ? (
          <View style={styles.subBadge}>
            <Star size={12} color={theme?.colors.primary} />
            <Text style={styles.subBadgeText}>{challenge.upvotes} votes</Text>
          </View>
        ) : null}
      </View>

      <Text style={styles.title}>{challenge.title}</Text>
      {challenge.description ? (
        <Text style={styles.description} numberOfLines={2}>
          {challenge.description}
        </Text>
      ) : null}

      <View style={styles.metaRow}>
        <View style={styles.metaChip}>
          <Clock size={12} color={theme?.colors.text.secondary} />
          <Text style={styles.metaChipText}>{timeLabel}</Text>
        </View>
        {challenge.points ? (
          <View style={styles.metaChip}>
            <Trophy size={12} color={theme?.colors.text.secondary} />
            <Text style={styles.metaChipText}>{challenge.points} pts</Text>
          </View>
        ) : null}
      </View>

      <View style={styles.actionsRow}>
        <TouchableOpacity
          style={styles.cta}
          onPress={() => onPressJoin?.(challenge)}
          activeOpacity={0.85}
        >
          <Text style={styles.ctaText}>{ctaLabel}</Text>
        </TouchableOpacity>
        {onPressDismiss ? (
          <TouchableOpacity
            style={styles.dismissButton}
            onPress={onPressDismiss}
            activeOpacity={0.75}
          >
            <Text style={styles.dismissText}>Dismiss</Text>
          </TouchableOpacity>
        ) : null}
      </View>
    </LinearGradient>
  );
};

const createStyles = (theme: any) =>
  StyleSheet.create({
    container: {
      borderRadius: 16,
      padding: 16,
      gap: 12,
    },
    headerRow: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
    },
    badge: {
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: `${theme?.colors.primary}12`,
      paddingHorizontal: 10,
      paddingVertical: 4,
      borderRadius: 999,
      gap: 6,
    },
    badgeText: {
      ...theme?.typography.caption.primary,
      color: theme?.colors.primary,
      fontWeight: '600',
    },
    subBadge: {
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: `${theme?.colors.text.secondary}12`,
      paddingHorizontal: 8,
      paddingVertical: 4,
      borderRadius: 999,
      gap: 4,
    },
    subBadgeText: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
      fontWeight: '600',
    },
    title: {
      ...theme?.typography.heading.small,
      color: theme?.colors.text.primary,
      fontWeight: '700',
    },
    description: {
      ...theme?.typography.body.sans,
      color: theme?.colors.text.secondary,
      lineHeight: 20,
    },
    metaRow: {
      flexDirection: 'row',
      gap: 8,
      flexWrap: 'wrap',
    },
    metaChip: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 4,
      paddingHorizontal: 10,
      paddingVertical: 4,
      borderRadius: 999,
      backgroundColor: `${theme?.colors.text.secondary}10`,
    },
    metaChipText: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
    },
    actionsRow: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 12,
    },
    cta: {
      flex: 1,
      backgroundColor: theme?.colors.primary,
      paddingVertical: 10,
      borderRadius: 12,
      alignItems: 'center',
    },
    ctaText: {
      ...theme?.typography.button,
      color: theme?.colors.text.inverse,
      fontWeight: '700',
    },
    dismissButton: {
      paddingVertical: 10,
      paddingHorizontal: 12,
    },
    dismissText: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
      fontWeight: '600',
    },
  });

export default SmartPickCard;
