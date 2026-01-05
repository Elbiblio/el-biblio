import React, { useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Image,
  KeyboardAvoidingView,
  Modal,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { BlurView } from 'expo-blur';
import * as Haptics from 'expo-haptics';

import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Eye, EyeOff, Sparkle } from '@/components/Icons';

interface GuestUpgradeModalProps {
  visible: boolean;
  onClose: () => void;
  onSubmit: (payload: {
    firstName: string;
    lastName: string;
    email: string;
    password: string;
    avatar?: string;
  }) => Promise<boolean>;
  onSuccess?: () => void;
  isSubmitting: boolean;
  errorMessage?: string | null;
  initialValues?: {
    firstName?: string;
    lastName?: string;
    email?: string;
    avatar?: string;
  };
}

const SAMPLE_AVATARS = Array.from({ length: 36 }, (_, index) => `https://api.elbiblio.com/avatars/${index + 1}.png`);

const GuestUpgradeModal: React.FC<GuestUpgradeModalProps> = ({
  visible,
  onClose,
  onSubmit,
  onSuccess,
  isSubmitting,
  errorMessage,
  initialValues,
}) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => createStyles(theme, insets), [theme, insets]);

  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [selectedAvatar, setSelectedAvatar] = useState<string | undefined>(undefined);
  const [validationError, setValidationError] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  useEffect(() => {
    if (visible) {
      setFirstName(initialValues?.firstName?.trim() === 'Guest' ? '' : (initialValues?.firstName ?? ''));
      setLastName(initialValues?.lastName?.startsWith('guest_') ? '' : (initialValues?.lastName ?? ''));
      setEmail(initialValues?.email ?? '');
      setSelectedAvatar(initialValues?.avatar);
      setPassword('');
      setConfirmPassword('');
      setValidationError(null);
    }
  }, [visible, initialValues]);

  const validate = () => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!firstName.trim()) {
      setValidationError('First name is required');
      return false;
    }

    if (!lastName.trim()) {
      setValidationError('Last name is required');
      return false;
    }

    if (!email.trim() || !emailRegex.test(email.trim())) {
      setValidationError('Please enter a valid email address');
      return false;
    }

    if (!password || password.length < 8) {
      setValidationError('Password must be at least 8 characters long');
      return false;
    }

    if (password !== confirmPassword) {
      setValidationError('Passwords do not match');
      return false;
    }

    if (!selectedAvatar) {
      setValidationError('Please choose an avatar to represent you');
      return false;
    }

    setValidationError(null);
    return true;
  };

  const handleSubmit = async () => {
    if (!validate() || isSubmitting) return;

    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    const success = await onSubmit({
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      password,
      avatar: selectedAvatar,
    });

    if (success) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      onSuccess?.();
      onClose();
    } else {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
    }
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
      statusBarTranslucent
    >
      <KeyboardAvoidingView
        style={styles.container}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <BlurView intensity={30} style={StyleSheet.absoluteFill} pointerEvents="none" />
        <View style={styles.overlay}>
          <View style={styles.modalContainer}>
            <BlurView intensity={10} style={styles.contentWrapper} pointerEvents="none">
              <View style={styles.header}>
                <TouchableOpacity onPress={onClose} style={styles.closeButton}>
                  <Text style={styles.closeText}>×</Text>
                </TouchableOpacity>
                <Sparkle size={40} color={theme.colors.primary} />
                <Text style={styles.title}>Upgrade Your Profile</Text>
                <Text style={styles.subtitle}>
                  Add your name, email, and choose an avatar to unlock the full community experience.
                </Text>
              </View>

              <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
                <View style={styles.row}>
                  <View style={styles.inputGroup}>
                    <Text style={styles.label}>First Name</Text>
                    <TextInput
                      value={firstName}
                      onChangeText={(text) => {
                        setFirstName(text);
                        if (validationError) setValidationError(null);
                      }}
                      style={styles.input}
                      placeholder="Enter your first name"
                      placeholderTextColor={theme.colors.text.placeholder}
                      autoCapitalize="words"
                    />
                  </View>
                  <View style={styles.inputGroup}>
                    <Text style={styles.label}>Last Name</Text>
                    <TextInput
                      value={lastName}
                      onChangeText={(text) => {
                        setLastName(text);
                        if (validationError) setValidationError(null);
                      }}
                      style={styles.input}
                      placeholder="Enter your last name"
                      placeholderTextColor={theme.colors.text.placeholder}
                      autoCapitalize="words"
                    />
                  </View>
                </View>

                <View style={styles.inputGroup}>
                  <Text style={styles.label}>Email Address</Text>
                  <TextInput
                    value={email}
                    onChangeText={(text) => {
                      setEmail(text);
                      if (validationError) setValidationError(null);
                    }}
                    style={styles.input}
                    placeholder="Enter your email"
                    placeholderTextColor={theme.colors.text.placeholder}
                    keyboardType="email-address"
                    autoCapitalize="none"
                    autoComplete="email"
                  />
                </View>

                <View style={styles.inputGroup}>
                  <Text style={styles.label}>Password</Text>
                  <View style={styles.passwordField}>
                    <TextInput
                      value={password}
                      onChangeText={(text) => {
                        setPassword(text);
                        if (validationError) setValidationError(null);
                      }}
                      style={styles.passwordInput}
                      placeholder="Create a password"
                      placeholderTextColor={theme.colors.text.placeholder}
                      secureTextEntry={!showPassword}
                      autoCapitalize="none"
                    />
                    <TouchableOpacity
                      onPress={() => setShowPassword((prev) => !prev)}
                      style={styles.eyeButton}
                    >
                      {showPassword ? (
                        <EyeOff size={20} color={theme.colors.text.secondary} />
                      ) : (
                        <Eye size={20} color={theme.colors.text.secondary} />
                      )}
                    </TouchableOpacity>
                  </View>
                </View>

                <View style={styles.inputGroup}>
                  <Text style={styles.label}>Confirm Password</Text>
                  <View style={styles.passwordField}>
                    <TextInput
                      value={confirmPassword}
                      onChangeText={(text) => {
                        setConfirmPassword(text);
                        if (validationError) setValidationError(null);
                      }}
                      style={styles.passwordInput}
                      placeholder="Confirm your password"
                      placeholderTextColor={theme.colors.text.placeholder}
                      secureTextEntry={!showConfirmPassword}
                      autoCapitalize="none"
                    />
                    <TouchableOpacity
                      onPress={() => setShowConfirmPassword((prev) => !prev)}
                      style={styles.eyeButton}
                    >
                      {showConfirmPassword ? (
                        <EyeOff size={20} color={theme.colors.text.secondary} />
                      ) : (
                        <Eye size={20} color={theme.colors.text.secondary} />
                      )}
                    </TouchableOpacity>
                  </View>
                </View>

                <View style={styles.avatarSection}>
                  <Text style={styles.label}>Choose an Avatar</Text>
                  <ScrollView
                    horizontal
                    showsHorizontalScrollIndicator={false}
                    contentContainerStyle={styles.avatarList}
                  >
                    {SAMPLE_AVATARS.map((avatar) => {
                      const isSelected = selectedAvatar === avatar;
                      return (
                        <TouchableOpacity
                          key={avatar}
                          onPress={() => {
                            setSelectedAvatar(avatar);
                            setValidationError(null);
                            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                          }}
                          style={[styles.avatarItem, isSelected && styles.selectedAvatar]}
                        >
                          <View style={styles.avatarImageWrapper}>
                            <Image source={{ uri: avatar }} style={styles.avatarImage} />
                          </View>
                        </TouchableOpacity>
                      );
                    })}
                  </ScrollView>
                </View>

                {(validationError || errorMessage) && (
                  <Text style={styles.errorText}>{validationError || errorMessage}</Text>
                )}

                <TouchableOpacity
                  style={[styles.primaryButton, (isSubmitting) && styles.disabledButton]}
                  onPress={handleSubmit}
                  disabled={isSubmitting}
                >
                  {isSubmitting ? (
                    <ActivityIndicator color={theme.colors.text.inverse} />
                  ) : (
                    <Text style={styles.primaryButtonText}>Complete Profile</Text>
                  )}
                </TouchableOpacity>
              </ScrollView>
            </BlurView>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
};

const createStyles = (theme: Theme, insets: { top: number; bottom: number }) => StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: Math.max(theme.spacing.md, insets.top),
    paddingBottom: Math.max(theme.spacing.md, insets.bottom),
  },
  overlay: {
    width: '100%',
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.xl,
    justifyContent: 'center',
    alignItems: 'center',
    flex: 1,
  },
  modalContainer: {
    width: '100%',
    maxWidth: 500,
    borderRadius: theme.borderRadius.xl,
    overflow: 'hidden',
    backgroundColor: theme.colors.background,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 6 },
        shadowOpacity: 0.2,
        shadowRadius: 16,
      },
      android: {
        elevation: 18,
      },
    }),
  },
  contentWrapper: {
    padding: theme.spacing.xl,
    backgroundColor: theme.colors.surface,
  },
  header: {
    alignItems: 'center',
    gap: theme.spacing.sm,
    marginBottom: theme.spacing.xl,
  },
  closeButton: {
    position: 'absolute',
    top: 0,
    right: 0,
    zIndex: 1,
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: theme.colors.surfaceVariant,
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeText: {
    fontSize: 24,
    color: theme.colors.text.secondary,
    lineHeight: 26,
  },
  title: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    textAlign: 'center',
  },
  subtitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
  },
  scrollContent: {
    gap: theme.spacing.lg,
    paddingBottom: theme.spacing.md,
  },
  row: {
    flexDirection: 'row',
    gap: theme.spacing.md,
  },
  inputGroup: {
    flex: 1,
    gap: theme.spacing.xs,
  },
  label: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.8,
  },
  input: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.md,
    backgroundColor: theme.colors.surfaceVariant,
  },
  passwordField: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: theme.borderRadius.md,
    backgroundColor: theme.colors.surfaceVariant,
  },
  passwordInput: {
    flex: 1,
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  eyeButton: {
    paddingHorizontal: theme.spacing.md,
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarSection: {
    gap: theme.spacing.sm,
  },
  avatarList: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
  },
  avatarItem: {
    width: 72,
    height: 72,
    borderRadius: 36,
    borderWidth: 2,
    borderColor: 'transparent',
    backgroundColor: theme.colors.surfaceVariant,
    justifyContent: 'center',
    alignItems: 'center',
  },
  selectedAvatar: {
    borderColor: theme.colors.primary,
    backgroundColor: theme.colors.surface,
  },
  avatarImageWrapper: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: theme.colors.surface,
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarImage: {
    width: 56,
    height: 56,
    borderRadius: 28,
  },
  errorText: {
    ...theme.typography.caption.primary,
    color: theme.colors.error,
    textAlign: 'center',
  },
  primaryButton: {
    backgroundColor: theme.colors.primary,
    borderRadius: theme.borderRadius.full,
    paddingVertical: theme.spacing.md,
    alignItems: 'center',
  },
  primaryButtonText: {
    ...theme.typography.button.primary,
    color: theme.colors.text.inverse,
  },
  disabledButton: {
    opacity: 0.5,
  },
});

export default GuestUpgradeModal;
