import React from 'react';
import { Modal, View, Text, TouchableOpacity, FlatList, ActivityIndicator, StyleSheet } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { VerseComparisonItem } from '@/stores/BibleStore';

interface VerseComparisonModalProps {
  visible: boolean;
  results: VerseComparisonItem[];
  isLoading?: boolean;
  error?: string | null;
  onClose: () => void;
  onRetry: () => void;
  reference?: string;
  offline?: boolean;
}

const VerseComparisonModal: React.FC<VerseComparisonModalProps> = ({
  visible,
  results,
  isLoading,
  error,
  onClose,
  onRetry,
  reference,
  offline,
}) => {
  const theme = useTheme();
  const styles = createStyles(theme);

  const renderContent = () => {
    if (isLoading) {
      return (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={theme.colors.primary} />
          <Text style={styles.loadingText}>Loading versions...</Text>
        </View>
      );
    }

    if (error) {
      return (
        <View style={styles.errorContainer}>
          <MaterialIcons name="error-outline" size={32} color={theme.colors.error} />
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={onRetry}>
            <Text style={styles.retryText}>Retry</Text>
          </TouchableOpacity>
        </View>
      );
    }

    if (!results.length) {
      return (
        <View style={styles.emptyContainer}>
          <MaterialIcons name="menu-book" size={32} color={theme.colors.text.secondary} />
          <Text style={styles.emptyText}>No versions available for comparison.</Text>
          {offline ? (
            <Text style={styles.offlineHint}>Connect to the internet to download additional versions.</Text>
          ) : null}
        </View>
      );
    }

    const renderItem = React.useCallback(({ item }: { item: VerseComparisonItem }) => (
      <View style={styles.versionCard}>
        <View style={styles.versionHeader}>
          <Text style={styles.versionTitle}>{item.englishName}</Text>
          <Text style={styles.versionSubtitle}>{item.shortName}</Text>
        </View>
        <Text style={styles.verseText}>{item.text || 'Not available'}</Text>
      </View>
    ), []);

    return (
      <View style={styles.listWrapper}>
        <FlatList
          data={results}
          keyExtractor={(item) => item.versionId}
          renderItem={renderItem}
          style={styles.list}
          contentContainerStyle={styles.listContent}
          initialNumToRender={10}
          maxToRenderPerBatch={10}
          windowSize={11}
          removeClippedSubviews
          showsVerticalScrollIndicator
        />
      </View>
    );
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <View style={styles.overlay}>
        <View style={styles.container}>
          <View style={styles.header}>
            <View>
              <Text style={styles.title}>Compare Verse</Text>
              {reference ? <Text style={styles.subtitle}>{reference}</Text> : null}
            </View>
            <TouchableOpacity onPress={onClose}>
              <MaterialIcons name="close" size={22} color={theme.colors.text.secondary} />
            </TouchableOpacity>
          </View>

          {offline ? (
            <View style={styles.offlineBanner}>
              <MaterialIcons name="wifi-off" size={16} color={theme.colors.warning} />
              <Text style={styles.offlineLabel}>Some versions may be unavailable offline.</Text>
            </View>
          ) : null}

          {renderContent()}
        </View>
      </View>
    </Modal>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.45)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme.spacing.lg,
  },
  container: {
    width: '100%',
    maxHeight: '90%',
    backgroundColor: theme.colors.background,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    gap: theme.spacing.lg,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  title: {
    ...theme.typography.body.sans,
    fontWeight: '600',
    color: theme.colors.text.primary,
    marginBottom: 2,
  },
  subtitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  offlineBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    padding: theme.spacing.sm,
    borderRadius: theme.borderRadius.md,
    backgroundColor: `${theme.colors.warning}18`,
  },
  offlineLabel: {
    ...theme.typography.caption.secondary,
    color: theme.colors.warning,
  },
  loadingContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme.spacing.xl,
    gap: theme.spacing.md,
  },
  loadingText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
  },
  errorContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme.spacing.xl,
    gap: theme.spacing.md,
  },
  errorText: {
    ...theme.typography.body.sans,
    color: theme.colors.error,
    textAlign: 'center',
  },
  retryButton: {
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: theme.colors.primary,
  },
  retryText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme.spacing.xl,
    gap: theme.spacing.sm,
  },
  emptyText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
  },
  offlineHint: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
  },
  listContent: {
    gap: theme.spacing.md,
    paddingBottom: theme.spacing.lg,
  },
  listWrapper: {
    flexGrow: 1,
    flexShrink: 1,
  },
  list: {
    flexGrow: 0,
  },
  versionCard: {
    borderRadius: theme.borderRadius.md,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: theme.spacing.md,
    backgroundColor: theme.colors.surface,
    gap: theme.spacing.sm,
  },
  versionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'baseline',
  },
  versionTitle: {
    ...theme.typography.body.sans,
    fontWeight: '600',
    color: theme.colors.text.primary,
  },
  versionSubtitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  verseText: {
    ...theme.typography.body.serif,
    color: theme.colors.text.primary,
  },
});

export default VerseComparisonModal;
