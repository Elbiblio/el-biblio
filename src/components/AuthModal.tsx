// AuthModal.tsx
import React, { useState, useCallback } from 'react';
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
import { useAuth } from '@/stores/auth';
import { Theme } from '@/theme';
import { Eye, EyeOff, XCircle } from '@/components/Icons';
import AvatarSelectionModal from './AvatarSelectionModal';
import { SCREEN_DIMENSIONS } from '@/constants';
import * as Haptics from 'expo-haptics';
import { toast } from 'sonner-native';

interface AuthModalProps {
  visible: boolean;
  onClose: () => void;
}

const AuthModal: React.FC<AuthModalProps> = ({ visible, onClose }) => {
  const theme = useTheme();
  const { login, signUp, isLoading, error: authError } = useAuth();
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

        // Show avatar selection immediately
        setShowAvatarModal(true);
      } else {
        try {
          const result = await login(formData.email.trim(), formData.password);
          if (result) {
            toast.success('Welcome back!');
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
          }
          handleClose();
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
    setError(null);
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
          <BlurView intensity={50} style={StyleSheet.absoluteFill} />
          <Pressable style={styles.overlay} onPress={handleClose}>
            <KeyboardAvoidingView
              behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
              style={styles.keyboardView}
            >
              <Pressable style={styles.modalContainer} onPress={e => e.stopPropagation()}>
                <BlurView intensity={50} style={styles.modalBlur}>
                  <TouchableOpacity
                    style={styles.closeButton}
                    onPress={handleClose}
                  >
                    <XCircle size={24} color={theme.colors.text.secondary} />
                  </TouchableOpacity>

                  <View style={styles.contentContainer}>
                    <Text style={styles.title}>
                      {isSignUp ? 'Join the Community' : 'Welcome Back'}
                    </Text>

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
                          placeholderTextColor={theme.colors.text.secondary}
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
                          placeholderTextColor={theme.colors.text.secondary}
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
                      placeholderTextColor={theme.colors.text.secondary}
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
                        placeholderTextColor={theme.colors.text.secondary}
                        secureTextEntry={!showPassword}
                        autoCapitalize="none"
                      />
                      <TouchableOpacity onPress={() => setShowPassword(!showPassword)} style={styles.eyeIcon}>
                        {showPassword ? <EyeOff size={24} color={theme.colors.text.secondary} /> : <Eye size={24} color={theme.colors.text.secondary} />}
                      </TouchableOpacity>
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
                          {isSignUp ? 'Join Now' : 'Sign In'}
                        </Text>
                      )}
                    </TouchableOpacity>

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
                  </View>
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
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)', // Dark semi-transparent background
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
    // Add a solid background color in addition to blur
    backgroundColor: Platform.OS === 'ios' ?
      'rgba(28, 28, 30, 0.9)' :
      'rgba(28, 28, 30, 0.95)',
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.25,
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
    minHeight: 200, // Ensure minimum height for content
  },
  closeButton: {
    position: 'absolute',
    top: theme.spacing.md,
    right: theme.spacing.md,
    zIndex: 1,
    width: 32,
    height: 32,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(60, 60, 67, 0.3)',
    borderRadius: theme.borderRadius.full,
  },
  title: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.inverse,
    textAlign: 'center',
    marginBottom: theme.spacing.md,
  },
  input: {
    backgroundColor: 'rgba(60, 60, 67, 0.55)',
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    fontSize: 16,
    color: theme.colors.text.inverse,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    ...Platform.select({
      android: {
        paddingVertical: theme.spacing.md,
      },
      ios: {
        paddingVertical: theme.spacing.md,
      }
    }),
  },
  errorText: {
    ...theme.typography.caption.primary,
    color: theme.colors.error,
    textAlign: 'center',
    backgroundColor: 'rgba(255, 59, 48, 0.1)',
    padding: theme.spacing.sm,
    borderRadius: theme.borderRadius.lg,
  },
  submitButton: {
    backgroundColor: theme.colors.primary,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    alignItems: 'center',
    marginTop: theme.spacing.md,
    ...Platform.select({
      ios: {
        shadowColor: theme.colors.primary,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 8,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  submitButtonDisabled: {
    opacity: 0.5,
  },
  submitText: {
    ...theme.typography.button.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  switchText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    textAlign: 'center',
    marginTop: theme.spacing.sm,
  },
  eyeIcon: {
    position: "absolute",
    color: theme.colors.text.inverse,
    right: 10,
    top: 20,
  },
});

export default AuthModal;