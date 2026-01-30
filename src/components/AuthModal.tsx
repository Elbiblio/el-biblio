// AuthModal.tsx – React Native best practices: no BlurView, stable callbacks, ScrollView, deferred content
import React, { useState, useCallback, useEffect, useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Modal,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
  Pressable,
  Keyboard,
  ScrollView,
  InteractionManager,
} from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { useAuthStore } from '@/stores/StoreProvider';
import { Theme } from '@/theme';
import { Eye, EyeOff, XCircle } from '@/components/Icons';
import AvatarSelectionModal from './AvatarSelectionModal';
import { SCREEN_DIMENSIONS } from '@/constants';
import * as Haptics from 'expo-haptics';
import { toast } from 'sonner-native';
import { AuthPromptIntent } from '@/stores/AuthStore';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

interface AuthModalProps {
  visible: boolean;
  onClose: () => void;
  intent?: AuthPromptIntent;
  pendingEmail?: string | null;
}

const AuthModal: React.FC<AuthModalProps> = ({ visible, onClose, intent = null, pendingEmail = null }) => {
  const theme = useTheme();
  const { login, signUp, isLoading, error: authError } = useAuthStore();
  const [isSignUp, setIsSignUp] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showAvatarModal, setShowAvatarModal] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    firstName: '',
    lastName: '',
  });
  const [pendingSignupData, setPendingSignupData] = useState<{
    email: string;
    password: string;
    first_name: string;
    last_name: string;
  } | null>(null);
  const [contentReady, setContentReady] = useState(false);
  const mountRef = useRef(false);

  const styles = React.useMemo(() => createStyles(theme), [theme]);

  useEffect(() => {
    if (!visible) {
      setContentReady(false);
      return;
    }
    mountRef.current = true;
    const task = InteractionManager.runAfterInteractions(() => {
      if (mountRef.current) setContentReady(true);
    });
    return () => {
      mountRef.current = false;
      task.cancel();
    };
  }, [visible]);

  useEffect(() => {
    if (!visible) return;
    if (intent === 'reauth') setIsSignUp(false);
    else if (intent === 'guest_signup') setIsSignUp(true);
  }, [intent, visible]);

  useEffect(() => {
    if (!visible || !pendingEmail) return;
    setFormData((prev) => ({ ...prev, email: pendingEmail }));
  }, [pendingEmail, visible]);

  const intentContent = React.useMemo(() => {
    if (intent === 'reauth')
      return { title: 'Sign in to continue', body: 'Your session expired for security reasons. Please confirm your password to keep using Elbiblio.' };
    if (intent === 'guest_signup')
      return { title: 'Create your free account', body: 'Guest sessions are temporary. Create an account so we can keep your history, progress, and reminders in sync.' };
    return null;
  }, [intent]);

  const modalTitle = React.useMemo(() => {
    if (intent === 'reauth') return 'Welcome back';
    if (intent === 'guest_signup') return 'Keep your progress';
    return isSignUp ? 'Join the Community' : 'Welcome Back';
  }, [intent, isSignUp]);

  const submitLabel = React.useMemo(() => {
    if (intent === 'reauth') return 'Re-authenticate';
    return isSignUp ? 'Join Now' : 'Sign In';
  }, [intent, isSignUp]);

  const validateForm = useCallback(() => {
    if (!formData.email.trim() || !EMAIL_REGEX.test(formData.email.trim())) {
      setError('Please enter a valid email address');
      return false;
    }
    if (!formData.password.trim() || formData.password.trim().length < 8) {
      setError('Password must be at least 8 characters long');
      return false;
    }
    if (isSignUp) {
      if (!formData.firstName.trim()) {
        setError('First name is required');
        return false;
      }
      if (!formData.lastName.trim()) {
        setError('Last name is required');
        return false;
      }
    }
    setError(null);
    return true;
  }, [formData.email, formData.password, formData.firstName, formData.lastName, isSignUp]);

  const handleClose = useCallback(() => {
    setError(null);
    setPendingSignupData(null);
    setFormData({ email: '', password: '', firstName: '', lastName: '' });
    onClose();
  }, [onClose]);

  const handleAvatarModalClose = useCallback(() => {
    setPendingSignupData(null);
    setShowAvatarModal(false);
  }, []);

  const setField = useCallback(<K extends keyof typeof formData>(field: K, value: string) => {
    setError(null);
    setFormData((prev) => ({ ...prev, [field]: value }));
  }, []);

  const handleSubmit = useCallback(async () => {
    Keyboard.dismiss();
    if (!validateForm()) return;
    try {
      if (isSignUp) {
        setPendingSignupData({
          email: formData.email.trim(),
          password: formData.password,
          first_name: formData.firstName.trim(),
          last_name: formData.lastName.trim(),
        });
        setShowAvatarModal(true);
      } else {
        try {
          const result = await login(formData.email.trim(), formData.password);
          if (result) {
            toast.success('Welcome back!');
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
            handleClose();
          }
        } catch (err: unknown) {
          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
          setError(err instanceof Error ? err.message : 'Login failed. Please try again.');
        }
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Authentication failed.');
    }
  }, [validateForm, isSignUp, formData, login, handleClose]);

  const handleAvatarSelect = useCallback(async (avatarUrl: string) => {
    if (!pendingSignupData) return;
    try {
      const result = await signUp({ ...pendingSignupData, avatar: avatarUrl });
      setPendingSignupData(null);
      setShowAvatarModal(false);
      handleClose();
      if (result) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        toast.success('Welcome to the El-biblio community! Our community is only fun when you help make it fun. Thank you and have a great journey');
      } else if (authError) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
        setError(authError);
      }
    } catch (err: unknown) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      setError(err instanceof Error ? err.message : 'Failed to complete signup. Please try again.');
      setShowAvatarModal(false);
    }
  }, [pendingSignupData, signUp, handleClose, authError]);

  const toggleShowPassword = useCallback(() => setShowPassword((p) => !p), []);
  const toggleSignUp = useCallback(() => {
    setError(null);
    setIsSignUp((s) => !s);
  }, []);

  if (!visible) return null;

  return (
    <>
      <Modal visible={visible} transparent animationType="fade" onRequestClose={handleClose} statusBarTranslucent>
        <View style={styles.container}>
          <Pressable style={styles.overlay} onPress={handleClose}>
            <KeyboardAvoidingView
              behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
              style={styles.keyboardView}
              keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 20}
            >
              <Pressable style={styles.modalContainer} onPress={(e) => e.stopPropagation()}>
                <View style={styles.modalContent}>
                  <TouchableOpacity
                    style={styles.closeButton}
                    onPress={handleClose}
                    hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
                    accessibilityLabel="Close"
                  >
                    <XCircle size={24} color={theme.colors.text.secondary} />
                  </TouchableOpacity>

                  {contentReady ? (
                    <>
                      <ScrollView
                        style={styles.scrollView}
                        contentContainerStyle={styles.scrollContent}
                        keyboardShouldPersistTaps="handled"
                        showsVerticalScrollIndicator={false}
                      >
                        <Text style={styles.title}>{modalTitle}</Text>
                        {intentContent && (
                          <View style={styles.intentBanner}>
                            <Text style={styles.intentTitle}>{intentContent.title}</Text>
                            <Text style={styles.intentBody}>{intentContent.body}</Text>
                          </View>
                        )}

                        {isSignUp && (
                          <>
                            <TextInput
                              style={styles.input}
                              placeholder="First Name"
                              value={formData.firstName}
                              onChangeText={(text) => setField('firstName', text)}
                              placeholderTextColor={theme.colors.text.placeholder}
                              autoCapitalize="words"
                              editable={!isLoading}
                            />
                            <TextInput
                              style={styles.input}
                              placeholder="Last Name"
                              value={formData.lastName}
                              onChangeText={(text) => setField('lastName', text)}
                              placeholderTextColor={theme.colors.text.placeholder}
                              autoCapitalize="words"
                              editable={!isLoading}
                            />
                          </>
                        )}

                        <TextInput
                          style={styles.input}
                          placeholder="Email"
                          value={formData.email}
                          onChangeText={(text) => setField('email', text)}
                          placeholderTextColor={theme.colors.text.placeholder}
                          keyboardType="email-address"
                          autoCapitalize="none"
                          autoComplete="email"
                          editable={!isLoading}
                        />

                        <View>
                          <TextInput
                            style={styles.input}
                            placeholder="Password"
                            value={formData.password}
                            onChangeText={(text) => setField('password', text)}
                            placeholderTextColor={theme.colors.text.placeholder}
                            secureTextEntry={!showPassword}
                            autoCapitalize="none"
                            editable={!isLoading}
                          />
                          <TouchableOpacity onPress={toggleShowPassword} style={styles.eyeIcon} hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}>
                            {showPassword ? <EyeOff size={24} color={theme.colors.text.secondary} /> : <Eye size={24} color={theme.colors.text.secondary} />}
                          </TouchableOpacity>
                        </View>
                      </ScrollView>

                      {(error || authError) && <Text style={styles.errorText}>{error || authError}</Text>}

                      <TouchableOpacity
                        style={[styles.submitButton, isLoading && styles.submitButtonDisabled]}
                        onPress={handleSubmit}
                        disabled={isLoading}
                        activeOpacity={0.8}
                      >
                        {isLoading ? (
                          <ActivityIndicator color={theme.colors.text.inverse} />
                        ) : (
                          <Text style={styles.submitText}>{submitLabel}</Text>
                        )}
                      </TouchableOpacity>

                      {intent === null && (
                        <TouchableOpacity onPress={toggleSignUp} disabled={isLoading}>
                          <Text style={styles.switchText}>
                            {isSignUp ? 'Already have an account? Sign in' : 'New here? Create account'}
                          </Text>
                        </TouchableOpacity>
                      )}
                    </>
                  ) : (
                    <View style={styles.placeholder}>
                      <ActivityIndicator size="small" color={theme.colors.primary} />
                    </View>
                  )}
                </View>
              </Pressable>
            </KeyboardAvoidingView>
          </Pressable>
        </View>
      </Modal>

      <AvatarSelectionModal visible={showAvatarModal} onClose={handleAvatarModalClose} onSelect={handleAvatarSelect} />
    </>
  );
};

const createStyles = (theme: Theme) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.colors.modal?.overlay ?? 'rgba(0,0,0,0.6)',
    },
    overlay: {
      flex: 1,
      justifyContent: 'center',
      padding: theme.spacing.lg,
    },
    keyboardView: {
      flex: 1,
      justifyContent: 'center',
    },
    modalContainer: {
      borderRadius: theme.borderRadius.xl,
      overflow: 'hidden',
      marginVertical: SCREEN_DIMENSIONS.height * 0.1,
      backgroundColor: theme.colors.modal?.background ?? theme.colors.background,
      ...Platform.select({
        ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 8 }, shadowOpacity: 0.3, shadowRadius: 24 },
        android: { elevation: 24 },
      }),
    },
    modalContent: {
      padding: theme.spacing.xl,
      minHeight: 200,
    },
    scrollView: {
      maxHeight: SCREEN_DIMENSIONS.height * 0.45,
    },
    scrollContent: {
      paddingBottom: theme.spacing.md,
      gap: theme.spacing.md,
    },
    placeholder: {
      minHeight: 160,
      justifyContent: 'center',
      alignItems: 'center',
    },
    closeButton: {
      position: 'absolute',
      top: theme.spacing.md,
      right: theme.spacing.md,
      zIndex: 1,
      width: 40,
      height: 40,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: 'rgba(60, 60, 67, 0.6)',
      borderRadius: theme.borderRadius.full,
    },
    title: {
      ...theme.typography.heading.large,
      color: theme.colors.text.inverse,
      textAlign: 'center',
      marginBottom: theme.spacing.lg,
    },
    input: {
      backgroundColor: theme.colors.input.background,
      padding: theme.spacing.md,
      borderRadius: theme.borderRadius.lg,
      ...theme.typography.body.sans,
      color: theme.colors.text.inverse,
      borderWidth: 1,
      borderColor: theme.colors.input.border,
    },
    errorText: {
      ...theme.typography.caption.primary,
      color: theme.colors.error,
      textAlign: 'center',
      backgroundColor: 'rgba(255, 59, 48, 0.2)',
      padding: theme.spacing.md,
      borderRadius: theme.borderRadius.lg,
      marginTop: theme.spacing.sm,
    },
    submitButton: {
      backgroundColor: theme.colors.primary,
      paddingVertical: theme.spacing.md,
      paddingHorizontal: theme.spacing.xl,
      borderRadius: theme.borderRadius.full,
      alignItems: 'center',
      marginTop: theme.spacing.lg,
      ...Platform.select({
        ios: { shadowColor: theme.colors.primary, shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.3, shadowRadius: 12 },
        android: { elevation: 8 },
      }),
    },
    submitButtonDisabled: {
      opacity: 0.6,
    },
    submitText: {
      ...theme.typography.button.primary,
      color: theme.colors.text.inverse,
      fontSize: 16,
      fontWeight: '600',
    },
    switchText: {
      ...theme.typography.button.secondary,
      color: theme.colors.primary,
      textAlign: 'center',
      marginTop: theme.spacing.md,
    },
    intentBanner: {
      backgroundColor: 'rgba(0, 0, 0, 0.55)',
      borderRadius: theme.borderRadius.lg,
      padding: theme.spacing.md,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: 'rgba(255, 255, 255, 0.35)',
      marginBottom: theme.spacing.lg,
    },
    intentTitle: {
      ...theme.typography.body.sans,
      color: theme.colors.text.inverse,
      fontWeight: '600',
      marginBottom: theme.spacing.xs,
    },
    intentBody: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.inverse,
    },
    eyeIcon: {
      position: 'absolute',
      right: theme.spacing.md,
      top: Platform.OS === 'ios' ? 18 : 22,
      width: 40,
      height: 40,
      alignItems: 'center',
      justifyContent: 'center',
    },
  });

export default AuthModal;
