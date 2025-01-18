import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Platform,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { useTheme } from '@/contexts/ThemeContext';
import { AllVirtues, THEMES, VirtueGroups } from '@/types';
import { IconProps } from '@/components/Icons';

interface VirtuePickerProps {
  selectedVirtues: AllVirtues[];
  onVirtueSelect: (virtue: AllVirtues) => void;
  onClose: () => void;
}

const VirtuePicker: React.FC<VirtuePickerProps> = ({
  selectedVirtues,
  onVirtueSelect,
  onClose
}) => {
  const theme = useTheme();
  const styles = StyleSheet.create({
    container: {
      flex: 1,
      marginTop: 100,
      zIndex: 99,
      backgroundColor: `${theme.colors.background}CC`,
      justifyContent: 'flex-end',
    },
    content: {
      backgroundColor: theme.colors.background,
      borderTopLeftRadius: theme.borderRadius.xl,
      borderTopRightRadius: theme.borderRadius.xl,
      maxHeight: '80%',
      ...Platform.select({
        ios: {
          shadowColor: '#000',
          shadowOffset: { width: 0, height: -2 },
          shadowOpacity: 0.1,
          shadowRadius: 8,
        },
        android: {
          elevation: 8,
        },
      }),
    },
    header: {
      padding: theme.spacing.lg,
      borderBottomWidth: StyleSheet.hairlineWidth,
      borderBottomColor: theme.colors.border,
    },
    title: {
      ...theme.typography.heading.medium,
      color: theme.colors.text.primary,
      textAlign: 'center',
    },
    scrollContent: {
      padding: theme.spacing.lg,
    },
    groupTitle: {
      ...theme.typography.heading.small,
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.md,
      marginTop: theme.spacing.lg,
    },
    virtueGrid: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      gap: theme.spacing.sm,
    },
    virtueButton: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingVertical: theme.spacing.xs,
      paddingHorizontal: theme.spacing.sm,
      borderRadius: theme.borderRadius.full,
      borderWidth: 1,
      borderColor: theme.colors.border,
      gap: theme.spacing.xs,
    },
    virtueSelected: {
      backgroundColor: `${theme.colors.primary}`,
      borderColor: theme.colors.primary,
    },
    virtueTextSelected: {
      color: theme.colors.text.inverse,
      fontWeight: '600',
    },
    virtueIcon: {
      width: 20,
      height: 20,
      alignItems: 'center',
      justifyContent: 'center',
    },
    virtueText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
      textTransform: 'capitalize',
    },
    footer: {
      padding: theme.spacing.lg,
      borderTopWidth: StyleSheet.hairlineWidth,
      borderTopColor: theme.colors.border,
    },
    doneButton: {
      backgroundColor: theme.colors.primary,
      padding: theme.spacing.sm,
      borderRadius: theme.borderRadius.full,
      alignItems: 'center',
    },
    doneText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.inverse,
    },
  });

  const renderVirtueButton = (virtue: AllVirtues, icon?: React.FC<IconProps>) => {
    const isSelected = selectedVirtues.includes(virtue);
    const Icon = icon;

    return (
      <TouchableOpacity
        key={virtue}
        style={[
          styles.virtueButton,
          isSelected && styles.virtueSelected
        ]}
        onPress={() => onVirtueSelect(virtue)}
      >
        {Icon && (
          <View style={styles.virtueIcon}>
            <Icon size={16} color={isSelected ? theme.colors.text.inverse : theme.colors.text.secondary} />
          </View>
        )}
        <Text style={[
          styles.virtueText,
          isSelected && styles.virtueTextSelected
        ]}>
          {virtue}
        </Text>
      </TouchableOpacity>
    );
  };


  return (
      <BlurView intensity={20} style={StyleSheet.absoluteFill}>
      <View style={styles.content}>
        <View style={styles.header}>
          <Text style={styles.title}>Select Virtues</Text>
        </View>

        <ScrollView style={styles.scrollContent} contentContainerStyle={{paddingBottom: 30}}>
          {Object.entries(VirtueGroups).map(([key, group]) => (
            <View key={key}>
              <Text style={styles.groupTitle}>{group.title}</Text>
              <View style={styles.virtueGrid}>
                {group.virtues.map(virtue =>
                  renderVirtueButton(
                    virtue,
                    key === 'foundational' ?
                      VirtueGroups.foundational.icons[virtue as keyof typeof VirtueGroups.foundational.icons] :
                      undefined
                  )
                )}
              </View>
            </View>
          ))}
        </ScrollView>

        <View style={styles.footer}>
          <TouchableOpacity style={styles.doneButton} onPress={onClose}>
            <Text style={styles.doneText}>
              Done ({selectedVirtues.length} selected)
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </BlurView>
  );
};

export default VirtuePicker;