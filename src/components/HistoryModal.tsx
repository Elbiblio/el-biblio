import React from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet, FlatList, ActivityIndicator } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';

export type HistoryModalEntry = {
  id: string;
  type: 'search' | 'verse' | 'navigation';
  label: string;
  subLabel?: string;
  timestamp: number;
  data?: unknown;
};

interface HistoryModalProps {
  visible: boolean;
  entries: HistoryModalEntry[];
  isLoading?: boolean;
  onClose: () => void;
  onSelect: (entry: HistoryModalEntry) => void;
  onClear?: () => void;
}

const HistoryModal: React.FC<HistoryModalProps> = ({ visible, entries, isLoading, onClose, onSelect, onClear }) => {
  const theme = useTheme();
  const styles = createStyles(theme);

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
            <Text style={styles.title}>History</Text>
            {entries.length > 0 && onClear ? (
              <TouchableOpacity style={styles.clearButton} onPress={onClear}>
                <MaterialIcons name="delete" size={20} color={theme.colors.error} />
                <Text style={styles.clearButtonText}>Clear</Text>
              </TouchableOpacity>
            ) : null}
            <TouchableOpacity onPress={onClose}>
              <MaterialIcons name="close" size={24} color={theme.colors.text.secondary} />
            </TouchableOpacity>
          </View>

          {isLoading ? (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color={theme.colors.primary} />
            </View>
          ) : (
            <FlatList
              data={entries}
              keyExtractor={(item) => item.id}
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={styles.entry}
                  onPress={() => onSelect(item)}
                >
                  <View style={styles.entryIcon}>
                    <MaterialIcons
                      name={item.type === 'search' ? 'search' : item.type === 'navigation' ? 'history' : 'book'}
                      size={20}
                      color={theme.colors.primary}
                    />
                  </View>
                  <View style={styles.entryContent}>
                    <Text style={styles.entryLabel}>{item.label}</Text>
                    {item.subLabel ? (
                      <Text style={styles.entrySubLabel}>{item.subLabel}</Text>
                    ) : null}
                  </View>
                  <View style={styles.badge}>
                    <Text style={styles.badgeText}>{item.type === 'search' ? 'Search' : item.type === 'navigation' ? 'Nav' : 'Verse'}</Text>
                  </View>
                  <MaterialIcons name="chevron-right" size={20} color={theme.colors.text.secondary} />
                </TouchableOpacity>
              )}
              ListEmptyComponent={() => (
                <View style={styles.emptyState}>
                  <MaterialIcons name="history" size={32} color={theme.colors.text.secondary} />
                  <Text style={styles.emptyStateText}>No recent history yet.</Text>
                </View>
              )}
            />
          )}
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
    maxHeight: '80%',
    backgroundColor: theme.colors.background,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.2,
    shadowRadius: 12,
    elevation: 4,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingBottom: theme.spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  title: {
    ...theme.typography.body.sans,
    fontWeight: '600',
    color: theme.colors.text.primary,
  },
  clearButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    marginRight: theme.spacing.sm,
  },
  clearButtonText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.error,
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme.spacing.xl,
  },
  entry: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme.spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  entryIcon: {
    width: 36,
    alignItems: 'center',
  },
  entryContent: {
    flex: 1,
    paddingHorizontal: theme.spacing.sm,
  },
  entryLabel: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  entrySubLabel: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: 2,
  },
  badge: {
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: `${theme.colors.primary}12`,
    marginRight: theme.spacing.sm,
  },
  badgeText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontSize: 11,
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme.spacing.xl,
    gap: theme.spacing.sm,
  },
  emptyStateText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
  },
});

export default HistoryModal;
