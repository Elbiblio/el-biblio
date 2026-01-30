import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Modal,
  Pressable,
  useWindowDimensions,
} from 'react-native';

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
  const { width, height } = useWindowDimensions();
  const isSmallWidth = width < 360;
  const isTabletish = width >= 768;
  const styles = React.useMemo(() => createStyles(theme, { isSmallWidth, isTabletish }), [theme, isSmallWidth, isTabletish]);

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
        <Pressable style={styles.container} onStartShouldSetResponder={() => true}>
          <View style={styles.content}>
            <View style={styles.header}>
              <Sparkle size={32} color={theme.colors.primary} />
              <Text style={styles.title}>Welcome to El-biblio</Text>
              <Text style={styles.subtitle}>How would you like to start?</Text>
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
                  <Text style={styles.optionTitle}>Create account</Text>
                  <Text style={styles.optionDescription}>Join the community and unlock all features.</Text>
                  <View style={styles.features}>
                    <Text style={styles.feature}>✓ Full access</Text>
                    <Text style={styles.feature}>✓ Share notes</Text>
                    <Text style={styles.feature}>✓ Community growth</Text>
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
                  <Text style={styles.optionTitle}>Continue as guest</Text>
                  <Text style={styles.optionDescription}>Explore now with limited features. You can register anytime.</Text>
                  <View style={styles.features}>
                    <Text style={styles.feature}>• Some features locked</Text>
                    <Text style={styles.feature}>• No community tools</Text>
                  </View>
                </View>
              </TouchableOpacity>
            </View>

            <TouchableOpacity
              style={styles.cancelButton}
              onPress={onClose}
            >
              <Text style={styles.cancelText}>Maybe later</Text>
            </TouchableOpacity>
          </View>
        </Pressable>
      </Pressable>
    </Modal>
  );
};

const createStyles = (theme: Theme, opts: { isSmallWidth: boolean; isTabletish: boolean }) => StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  container: {
    width: opts.isTabletish ? '70%' : '90%',
    maxWidth: opts.isTabletish ? 520 : 420,
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
    padding: opts.isSmallWidth ? theme.spacing.lg : theme.spacing.xl,
  },
  header: {
    alignItems: 'center',
    marginBottom: opts.isSmallWidth ? theme.spacing.lg : theme.spacing.xl,
  },
  title: {
    ...theme.typography.heading.large,
    color: theme.colors.text.primary,
    textAlign: 'center',
    marginTop: opts.isSmallWidth ? theme.spacing.sm : theme.spacing.md,
    marginBottom: opts.isSmallWidth ? theme.spacing.xs : theme.spacing.sm,
  },
  subtitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    lineHeight: opts.isSmallWidth ? 18 : 20,
  },
  options: {
    gap: opts.isSmallWidth ? theme.spacing.md : theme.spacing.lg,
    marginBottom: opts.isSmallWidth ? theme.spacing.lg : theme.spacing.xl,
  },
  option: {
    flexDirection: 'row',
    padding: opts.isSmallWidth ? theme.spacing.md : theme.spacing.lg,
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
    width: opts.isSmallWidth ? 40 : 48,
    height: opts.isSmallWidth ? 40 : 48,
    borderRadius: opts.isSmallWidth ? 20 : 24,
    backgroundColor: theme.colors.background,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: opts.isSmallWidth ? theme.spacing.sm : theme.spacing.md,
  },
  optionContent: {
    flex: 1,
  },
  optionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: opts.isSmallWidth ? 2 : theme.spacing.xs,
  },
  optionDescription: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    lineHeight: opts.isSmallWidth ? 16 : 18,
    marginBottom: opts.isSmallWidth ? theme.spacing.xs : theme.spacing.sm,
  },
  features: {
    gap: opts.isSmallWidth ? 1 : 2,
  },
  feature: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    fontSize: opts.isSmallWidth ? 11 : 12,
  },
  cancelButton: {
    alignItems: 'center',
    paddingVertical: opts.isSmallWidth ? theme.spacing.sm : theme.spacing.md,
  },
  cancelText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    fontWeight: '500',
  },
});

export default GuestChoiceModal;