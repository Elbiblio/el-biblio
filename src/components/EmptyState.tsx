import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { Sparkle, Info } from '@/components/Icons';

export type EmptyStateProps = {
  title?: string;
  message?: string;
  ctaText?: string;
  onPressCTA?: () => void;
  IconComponent?: React.FC<{ size?: number; color?: string }>;
};

const EmptyState: React.FC<EmptyStateProps> = ({
  title = 'Nothing here yet',
  message = 'Be the first to create something inspiring for others.',
  ctaText,
  onPressCTA,
  IconComponent,
}) => {
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const Icon = IconComponent || Sparkle;

  return (
    <View style={styles.container}>
      <View style={[styles.iconWrap, { backgroundColor: `${theme.colors.primary}10` }]}> 
        <Icon size={56} color={theme.colors.primary} />
      </View>
      {!!title && <Text style={styles.title}>{title}</Text>}
      {!!message && <Text style={styles.message}>{message}</Text>}
      {ctaText && onPressCTA && (
        <TouchableOpacity style={styles.ctaButton} onPress={onPressCTA}>
          <Info size={16} color={theme.colors.text.inverse} />
          <Text style={styles.ctaText}>{ctaText}</Text>
        </TouchableOpacity>
      )}
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    paddingVertical: theme.spacing.xl,
    paddingHorizontal: theme.spacing.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconWrap: {
    width: 96,
    height: 96,
    borderRadius: 48,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme.spacing.md,
  },
  title: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    textAlign: 'center',
  },
  message: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginTop: theme.spacing.xs,
  },
  ctaButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: theme.colors.primary,
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    marginTop: theme.spacing.md,
  },
  ctaText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    marginLeft: 6,
    fontWeight: '600',
  },
});

export default EmptyState;
