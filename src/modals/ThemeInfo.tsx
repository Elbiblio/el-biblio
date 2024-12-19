import React, { useEffect } from 'react';
import {
  View,
  Text,
  Modal,
  TouchableOpacity,
  StyleSheet,
  Platform,
  ScrollView,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { X, Sparkle } from '@/components/Icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import * as Haptics from 'expo-haptics';
import { ThemeInfo as ThemeInfoType } from '@/types';

interface ThemeInfoModalProps {
  theme: ThemeInfoType;
  visible: boolean;
  onClose: () => void;
}

const ThemeInfo: React.FC<ThemeInfoModalProps> = ({
  theme,
  visible,
  onClose,
}) => {
  const appTheme = useTheme();
  const styles = React.useMemo(() => createStyles(appTheme), [appTheme]);
  useEffect(()=>{
    console.log("theme", theme)

  }, [])

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
      statusBarTranslucent
    >
      <View style={styles.overlay}>
        <BlurView intensity={20} style={StyleSheet.absoluteFill} />
        <View style={styles.modalContainer}>
          {/* Header */}
          <View style={[
            styles.header,
            { backgroundColor: `${theme.color}10` }
          ]}>
            <View style={[
              styles.iconContainer,
              { backgroundColor: `${theme.color}15` }
            ]}>
              <theme.Icon size={32} color={theme.color} />
            </View>
            <TouchableOpacity
              style={styles.closeButton}
              onPress={() => {
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                onClose();
              }}
            >
              <X size={24} color={appTheme.colors.text.secondary} />
            </TouchableOpacity>
          </View>

          <ScrollView
            style={styles.content}            
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
          >
            {/* Title Section */}
            <Text style={[styles.title, { color: theme.color }]}>
              {theme.title}
            </Text>
            <Text style={styles.subtitle}>{theme.subtitle}</Text>

            {/* Description */}
            <Text style={styles.description}>
              {theme.description}
            </Text>

            {/* Practices */}
            <View style={styles.practicesContainer}>
              <Text style={styles.practicesTitle}>Daily Guide</Text>
              {theme.practices.map((practice, index) => (
                <View key={index} style={styles.practiceItem}>
                  <Sparkle size={16} color={theme.color} />
                  <Text style={styles.practiceText}>{practice}</Text>
                </View>
              ))}
            </View>
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  overlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    padding: theme.spacing.lg,
  },
  modalContainer: {
    width: '100%',
    maxWidth: 400,
    maxHeight: '80%',
    flex: 1,
    backgroundColor: theme.colors.background,
    borderRadius: theme.borderRadius.xl,
    overflow: 'hidden',
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.15,
        shadowRadius: 12,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  header: {
    padding: theme.spacing.lg,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  iconContainer: {
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
  },
  closeButton: {
    padding: theme.spacing.xs,
    margin: -theme.spacing.xs,
  },
  content: {
    flex: 1,
},
scrollContent: {
    padding: theme.spacing.lg,
    paddingTop: theme.spacing.md,
    paddingBottom: 32
  },
  title: {
    ...theme.typography.heading.large,
    marginBottom: theme.spacing.xs,
  },
  subtitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.lg,
  },
  description: {
    ...theme.typography.body.serif,
    color: theme.colors.text.primary,
    lineHeight: 24,
    marginBottom: theme.spacing.xl,
  },
  practicesContainer: {
    backgroundColor: theme.colors.surface,
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,
  },
  practicesTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  practiceItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  practiceText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    flex: 1,
  },
});

export default ThemeInfo;