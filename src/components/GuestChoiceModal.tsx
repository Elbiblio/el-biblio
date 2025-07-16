import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Modal,
  Pressable,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { User, Users, Sparkle } from '@/components/Icons';
import * as Haptics from 'expo-haptics';

interface GuestChoiceModalProps {
  visible: boolean;
  onClose: () => void;
  onRegister: () => void;
  onContinueAsGuest: () => void;
}

const GuestChoiceModal: React.FC<GuestChoiceModalProps> = ({
  visible,
  onClose,
  onRegister,
  onContinueAsGuest,
}) => {
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const handleRegister = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    onRegister();
  };

  const handleGuest = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onContinueAsGuest();
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <Pressable style={styles.overlay} onPress={onClose}>
        <Pressable style={styles.container}>
          <BlurView intensity={20} style={StyleSheet.absoluteFill} />
          <View style={styles.content}>
            <View style={styles.header}>
              <Sparkle size={32} color={theme.colors.primary} />
              <Text style={styles.title}>Welcome to El-biblio</Text>
              <Text style={styles.subtitle}>
                Choose how you'd like to start your spiritual journey
              </Text>
            </View>

            <View style={styles.options}>
              <TouchableOpacity
                style={[styles.option, styles.registerOption]}
                onPress={handleRegister}
                activeOpacity={0.8}
              >
                <View style={styles.optionIcon}>
                  <Users size={28} color={theme.colors.primary} />
                </View>
                <View style={styles.optionContent}>
                  <Text style={styles.optionTitle}>Create Account</Text>
                  <Text style={styles.optionDescription}>
                    Join the community, share notes, participate in discussions, and access all features
                  </Text>
                  <View style={styles.features}>
                    <Text style={styles.feature}>✓ Full community access</Text>
                    <Text style={styles.feature}>✓ Share notes & reflections</Text>
                    <Text style={styles.feature}>✓ Grow with community</Text>
                  </View>
                </View>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.option, styles.guestOption]}
                onPress={handleGuest}
                activeOpacity={0.8}
              >
                <View style={styles.optionIcon}>
                  <User size={28} color={theme.colors.text.secondary} />
                </View>
                <View style={styles.optionContent}>
                  <Text style={styles.optionTitle}>Continue as Guest</Text>
                  <Text style={styles.optionDescription}>
                    Start exploring immediately with limited features. You can always register later
                  </Text>
                  <View style={styles.features}>
                    <Text style={styles.feature}>✗ Access to meditation</Text>
                    <Text style={styles.feature}>✗ No community features</Text>
                  </View>
                </View>
              </TouchableOpacity>
            </View>

            <TouchableOpacity
              style={styles.cancelButton}
              onPress={onClose}
            >
              <Text style={styles.cancelText}>Maybe Later</Text>
            </TouchableOpacity>
          </View>
        </Pressable>
      </Pressable>
    </Modal>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  container: {
    width: '90%',
    maxWidth: 400,
    backgroundColor: theme.colors.background,
    borderRadius: 20,
    overflow: 'hidden',
    elevation: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 12,
  },
  content: {
    padding: theme.spacing.xl,
  },
  header: {
    alignItems: 'center',
    marginBottom: theme.spacing.xl,
  },
  title: {
    ...theme.typography.heading.large,
    color: theme.colors.text.primary,
    textAlign: 'center',
    marginTop: theme.spacing.md,
    marginBottom: theme.spacing.sm,
  },
  subtitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    lineHeight: 20,
  },
  options: {
    gap: theme.spacing.lg,
    marginBottom: theme.spacing.xl,
  },
  option: {
    flexDirection: 'row',
    padding: theme.spacing.lg,
    borderRadius: 16,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  registerOption: {
    backgroundColor: `${theme.colors.primary}10`,
    borderColor: theme.colors.primary,
  },
  guestOption: {
    backgroundColor: `${theme.colors.text.secondary}08`,
    borderColor: `${theme.colors.text.secondary}20`,
  },
  optionIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: theme.colors.background,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: theme.spacing.md,
  },
  optionContent: {
    flex: 1,
  },
  optionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  optionDescription: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    lineHeight: 18,
    marginBottom: theme.spacing.sm,
  },
  features: {
    gap: 2,
  },
  feature: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    fontSize: 12,
  },
  cancelButton: {
    alignItems: 'center',
    paddingVertical: theme.spacing.md,
  },
  cancelText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    fontWeight: '500',
  },
});

export default GuestChoiceModal; 