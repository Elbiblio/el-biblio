// AuthModal.tsx
import React, { useState, useCallback, useEffect } from 'react';
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
} from 'react-native';
import { BlurView } from 'expo-blur';
import { useTheme } from '@/contexts/ThemeContext';
import { useAuthStore } from '@/stores/StoreProvider';
import { Theme } from '@/theme';
import { Eye, EyeOff, XCircle } from '@/components/Icons';
import AvatarSelectionModal from './AvatarSelectionModal';
import { SCREEN_DIMENSIONS } from '@/constants';
import * as Haptics from 'expo-haptics';
import { toast } from 'sonner-native';
import { AuthPromptIntent } from '@/stores/AuthStore';

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

  const styles = React.useMemo(() => createStyles(theme), [theme]);

  // For temporary storage during avatar selection
  const [pendingSignupData, setPendingSignupData] = useState<{
    email: string;
    password: string;
    first_name: string;
    last_name: string;
  } | null>(null);

  const validateForm = () => {
    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!formData.email.trim() || !emailRegex.test(formData.email.trim())) {
      setError('Please enter a valid email address');
      return false;
    }

    // Password validation - at least 8 characters
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
  };

  useEffect(() => {
    if (!visible) return;
    if (intent === 'reauth') {
      setIsSignUp(false);
    } else if (intent === 'guest_signup') {
      setIsSignUp(true);
    }
  }, [intent, visible]);

  useEffect(() => {
    if (!visible || !pendingEmail) return;
    setFormData((prev) => ({
      ...prev,
      email: pendingEmail,
    }));
  }, [pendingEmail, visible]);

  const intentContent = React.useMemo(() => {
    if (intent === 'reauth') {
      return {
        title: 'Sign in to continue',
        body: 'Your session expired for security reasons. Please confirm your password to keep using Elbiblio.',
      };
    }
    if (intent === 'guest_signup') {
      return {
        title: 'Create your free account',
        body: 'Guest sessions are temporary. Create an account so we can keep your history, progress, and reminders in sync.',
      };
    }
    return null;
  }, [intent]);

  const modalTitle = React.useMemo(() => {
    if (intent === 'reauth') {
      return 'Welcome back';
    }
    if (intent === 'guest_signup') {
      return 'Keep your progress';
    }
    return isSignUp ? 'Join the Community' : 'Welcome Back';
  }, [intent, isSignUp]);

  const submitLabel = React.useMemo(() => {
    if (intent === 'reauth') {
      return 'Re-authenticate';
    }
    return isSignUp ? 'Join Now' : 'Sign In';
  }, [intent, isSignUp]);

  const handleSubmit = async () => {
    try {
      Keyboard.dismiss();
      if (!validateForm()) return;

      if (isSignUp) {
        // Store signup data temporarily
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
        } catch (error: any) {
          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
          setError(error?.message || 'Login failed. Please try again.');
        }
      }
    } catch (err: any) {
      console.error('Form submission error:', err);
      setError(err?.message || 'Authentication failed. Please try again.');
    }
  };

  const handleAvatarSelect = async (avatarUrl: string) => {
    try {
      if (!pendingSignupData) {
        throw new Error('Sign up data not found');
      }

      // Attempt signup with avatar
      const result = await signUp({
        ...pendingSignupData,
        avatar: avatarUrl
      });

      // Reset states
      setPendingSignupData(null);
      setShowAvatarModal(false);
      handleClose();

      if (result) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        toast.success('Welcome to the El-biblio community! Our community is only fun when you help make it fun. Thank you and have a great journey');
      } else if (authError) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
        setError(authError || 'Failed to complete signup. Please try again.');  
      }
    } catch (error: any) {
      console.log(error);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      setError(error?.message || 'Failed to complete signup. Please try again.');
      setShowAvatarModal(false);
    }
  };

  const handleClose = () => {
    setError(null);
    setPendingSignupData(null);
    setFormData({
      email: '',
      password: '',
      firstName: '',
      lastName: '',
    });
    onClose();
  };

  const handleAvatarModalClose = () => {
    setPendingSignupData(null);
    setShowAvatarModal(false);
    // Don't clear error here to preserve any signup errors
  };

  return (
    <>
      <Modal
        visible={visible}
        transparent
        animationType="fade"
        onRequestClose={handleClose}
        statusBarTranslucent
      >
        <View style={styles.container}>
          <BlurView intensity={50} style={StyleSheet.absoluteFill} pointerEvents="none" />
          <Pressable style={styles.overlay} onPress={handleClose}>
            <KeyboardAvoidingView
              behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
              style={styles.keyboardView}
            >
              <Pressable style={styles.modalContainer} onPress={e => e.stopPropagation()}>
                <BlurView intensity={50} style={styles.modalBlur} pointerEvents="none">
                  <TouchableOpacity
                    style={styles.closeButton}
                    onPress={handleClose}
                  >
                    <XCircle size={24} color={theme.colors.text.secondary} />
                  </TouchableOpacity>

                  <View style={styles.contentContainer}>
                    <Text style={styles.title}>{modalTitle}</Text>

                    {intentContent && (
                      <View style={styles.intentBanner}>
                        <Text style={styles.intentTitle}>{intentContent.title}</Text>
                        <Text style={styles.intentBody}>{intentContent.body}</Text>
                      </View>
                    )}

                    {/* Form Fields */}
                    {isSignUp && (
                      <>
                        <TextInput
                          style={styles.input}
                          placeholder="First Name"
                          value={formData.firstName}
                          onChangeText={(text) => {
                            setError(null);
                            setFormData(prev => ({ ...prev, firstName: text }));
                          }}
                          placeholderTextColor={theme.colors.text.placeholder}
                          autoCapitalize="words"
                        />
                        <TextInput
                          style={styles.input}
                          placeholder="Last Name"
                          value={formData.lastName}
                          onChangeText={(text) => {
                            setError(null);
                            setFormData(prev => ({ ...prev, lastName: text }));
                          }}
                          placeholderTextColor={theme.colors.text.placeholder}
                          autoCapitalize="words"
                        />
                      </>
                    )}

                    <TextInput
                      style={styles.input}
                      placeholder="Email"
                      value={formData.email}
                      onChangeText={(text) => {
                        setError(null);
                        setFormData(prev => ({ ...prev, email: text }));
                      }}
                      placeholderTextColor={theme.colors.text.placeholder}
                      keyboardType="email-address"
                      autoCapitalize="none"
                      autoComplete="email"
                    />

                    <View>
                      <TextInput
                        style={styles.input}
                        placeholder="Password"
                        value={formData.password}
                        onChangeText={(text) => {
                          setError(null);
                          setFormData(prev => ({ ...prev, password: text }));
                        }}
                        placeholderTextColor={theme.colors.text.placeholder}
                        secureTextEntry={!showPassword}
                        autoCapitalize="none"
                      />
                      <TouchableOpacity onPress={() => setShowPassword(!showPassword)} style={styles.eyeIcon}>
                        {showPassword ? <EyeOff size={24} color={theme.colors.text.secondary} /> : <Eye size={24} color={theme.colors.text.secondary} />}
                      </TouchableOpacity>
                    </View>
                  </View>

                  {(error || authError) && (
                    <Text style={styles.errorText}>{error || authError}</Text>
                  )}

                  <TouchableOpacity
                    style={[styles.submitButton, isLoading && styles.submitButtonDisabled]}
                    onPress={handleSubmit}
                    disabled={isLoading}
                  >
                    {isLoading ? (
                      <ActivityIndicator color={theme.colors.text.inverse} />
                    ) : (
                      <Text style={styles.submitText}>
                        {submitLabel}
                      </Text>
                    )}
                  </TouchableOpacity>

                  {intent === null && (
                    <TouchableOpacity
                      onPress={() => {
                        setError(null);
                        setIsSignUp(!isSignUp);
                      }}
                      disabled={isLoading}
                    >
                      <Text style={styles.switchText}>
                        {isSignUp ? 'Already have an account? Sign in' : 'New here? Create account'}
                      </Text>
                    </TouchableOpacity>
                  )}
              </BlurView>
            </Pressable>
          </KeyboardAvoidingView>
        </Pressable>
      </View>
    </Modal>

    <AvatarSelectionModal
      visible={showAvatarModal}
      onClose={handleAvatarModalClose}
      onSelect={handleAvatarSelect}
    />
  </>
)};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.modal?.overlay,
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
    backgroundColor: theme.colors.modal.background,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.3,
        shadowRadius: 24,
      },
      android: {
        elevation: 24,
      },
    }),
  },
  modalBlur: {
    borderRadius: theme.borderRadius.xl,
  },
  scrollContent: {
    flex: 1,
  },
  content: {
    padding: 24,
    gap: 16,
  },
  contentContainer: {
    padding: theme.spacing.xl,
    gap: theme.spacing.md,
    minHeight: 200,
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
  },
  submitButton: {
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.md,
    paddingHorizontal: theme.spacing.xl,
    borderRadius: theme.borderRadius.full,
    alignItems: 'center',
    marginTop: theme.spacing.lg,
    ...Platform.select({
      ios: {
        shadowColor: theme.colors.primary,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.3,
        shadowRadius: 12,
      },
      android: {
        elevation: 8,
      },
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
    position: "absolute",
    right: theme.spacing.md,
    top: Platform.OS === 'ios' ? 18 : 22,
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

export default AuthModal;