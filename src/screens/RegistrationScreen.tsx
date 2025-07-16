import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { ChevronLeft, Eye, EyeOff, Sparkle } from '@/components/Icons';
import { useAuth } from '@/stores/auth';
import AvatarSelectionModal from '@/components/AvatarSelectionModal';
import * as Haptics from 'expo-haptics';
import { toast } from 'sonner-native';
import { RootStackParamList } from '@/types';
import { NativeStackScreenProps } from '@react-navigation/native-stack';

type RegistrationScreenProps = NativeStackScreenProps<RootStackParamList, 'RegistrationScreen'>;

const RegistrationScreen: React.FC<RegistrationScreenProps> = ({ navigation }) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const { signUp, isLoading, error: authError } = useAuth();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    firstName: '',
    lastName: '',
  });
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showAvatarModal, setShowAvatarModal] = useState(false);
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

    // Password validation
    if (!formData.password.trim() || formData.password.trim().length < 8) {
      setError('Password must be at least 8 characters long');
      return false;
    }

    // Confirm password
    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      return false;
    }

    // Name validation
    if (!formData.firstName.trim()) {
      setError('First name is required');
      return false;
    }
    if (!formData.lastName.trim()) {
      setError('Last name is required');
      return false;
    }

    setError(null);
    return true;
  };

  const handleSubmit = async () => {
    try {
      if (!validateForm()) return;

      setPendingSignupData({
        email: formData.email.trim(),
        password: formData.password,
        first_name: formData.firstName.trim(),
        last_name: formData.lastName.trim(),
      });
      setShowAvatarModal(true);
    } catch (err: any) {
      console.error('Form submission error:', err);
      setError(err?.message || 'Registration failed. Please try again.');
    }
  };

  const handleAvatarSelect = async (avatarUrl: string) => {
    try {
      if (!pendingSignupData) {
        throw new Error('Sign up data not found');
      }

      const result = await signUp({
        ...pendingSignupData,
        avatar: avatarUrl
      });

      setPendingSignupData(null);
      setShowAvatarModal(false);

      if (result) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        toast.success('Welcome to the El-biblio community!');
        navigation.replace('Home');
      } else if (authError) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
        setError(authError);
      }
    } catch (error: any) {
      console.error('Avatar selection error:', error);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      setError(error?.message || 'Failed to complete registration. Please try again.');
      setShowAvatarModal(false);
    }
  };

  const handleAvatarModalClose = () => {
    setPendingSignupData(null);
    setShowAvatarModal(false);
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <BlurView intensity={10} style={StyleSheet.absoluteFill} />
      
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity
          style={styles.backButton}
          onPress={() => navigation.goBack()}
        >
          <ChevronLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Create Account</Text>
        <View style={styles.placeholder} />
      </View>

      <KeyboardAvoidingView
        style={styles.content}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <ScrollView
          style={styles.scrollView}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.welcomeSection}>
            <Sparkle size={48} color={theme.colors.primary} />
            <Text style={styles.welcomeTitle}>Join the Community</Text>
            <Text style={styles.welcomeSubtitle}>
              Create your account to unlock all features and connect with fellow believers
            </Text>
          </View>

          <View style={styles.form}>
            <View style={styles.nameRow}>
              <View style={styles.nameField}>
                <Text style={styles.label}>First Name</Text>
                <TextInput
                  style={styles.input}
                  value={formData.firstName}
                  onChangeText={(text) => {
                    setError(null);
                    setFormData(prev => ({ ...prev, firstName: text }));
                  }}
                  placeholder="Enter your first name"
                  placeholderTextColor={theme.colors.text.placeholder}
                  autoCapitalize="words"
                />
              </View>
              <View style={styles.nameField}>
                <Text style={styles.label}>Last Name</Text>
                <TextInput
                  style={styles.input}
                  value={formData.lastName}
                  onChangeText={(text) => {
                    setError(null);
                    setFormData(prev => ({ ...prev, lastName: text }));
                  }}
                  placeholder="Enter your last name"
                  placeholderTextColor={theme.colors.text.placeholder}
                  autoCapitalize="words"
                />
              </View>
            </View>

            <View style={styles.field}>
              <Text style={styles.label}>Email Address</Text>
              <TextInput
                style={styles.input}
                value={formData.email}
                onChangeText={(text) => {
                  setError(null);
                  setFormData(prev => ({ ...prev, email: text }));
                }}
                placeholder="Enter your email"
                placeholderTextColor={theme.colors.text.placeholder}
                keyboardType="email-address"
                autoCapitalize="none"
                autoComplete="email"
              />
            </View>

            <View style={styles.field}>
              <Text style={styles.label}>Password</Text>
              <View style={styles.passwordContainer}>
                <TextInput
                  style={styles.passwordInput}
                  value={formData.password}
                  onChangeText={(text) => {
                    setError(null);
                    setFormData(prev => ({ ...prev, password: text }));
                  }}
                  placeholder="Create a password"
                  placeholderTextColor={theme.colors.text.placeholder}
                  secureTextEntry={!showPassword}
                  autoCapitalize="none"
                />
                <TouchableOpacity
                  onPress={() => setShowPassword(!showPassword)}
                  style={styles.eyeIcon}
                >
                  {showPassword ? (
                    <EyeOff size={20} color={theme.colors.text.secondary} />
                  ) : (
                    <Eye size={20} color={theme.colors.text.secondary} />
                  )}
                </TouchableOpacity>
              </View>
            </View>

            <View style={styles.field}>
              <Text style={styles.label}>Confirm Password</Text>
              <View style={styles.passwordContainer}>
                <TextInput
                  style={styles.passwordInput}
                  value={formData.confirmPassword}
                  onChangeText={(text) => {
                    setError(null);
                    setFormData(prev => ({ ...prev, confirmPassword: text }));
                  }}
                  placeholder="Confirm your password"
                  placeholderTextColor={theme.colors.text.placeholder}
                  secureTextEntry={!showConfirmPassword}
                  autoCapitalize="none"
                />
                <TouchableOpacity
                  onPress={() => setShowConfirmPassword(!showConfirmPassword)}
                  style={styles.eyeIcon}
                >
                  {showConfirmPassword ? (
                    <EyeOff size={20} color={theme.colors.text.secondary} />
                  ) : (
                    <Eye size={20} color={theme.colors.text.secondary} />
                  )}
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
                <Text style={styles.submitText}>Continue</Text>
              )}
            </TouchableOpacity>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>

      <AvatarSelectionModal
        visible={showAvatarModal}
        onClose={handleAvatarModalClose}
        onSelect={handleAvatarSelect}
      />
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.md,
  },
  backButton: {
    padding: theme.spacing.sm,
  },
  headerTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  placeholder: {
    width: 40,
  },
  content: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: theme.spacing.lg,
    paddingBottom: theme.spacing.xl,
  },
  welcomeSection: {
    alignItems: 'center',
    marginBottom: theme.spacing.xl,
    paddingTop: theme.spacing.lg,
  },
  welcomeTitle: {
    ...theme.typography.heading.large,
    color: theme.colors.text.primary,
    textAlign: 'center',
    marginTop: theme.spacing.md,
    marginBottom: theme.spacing.sm,
  },
  welcomeSubtitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    lineHeight: 20,
  },
  form: {
    gap: theme.spacing.lg,
  },
  nameRow: {
    flexDirection: 'row',
    gap: theme.spacing.md,
  },
  nameField: {
    flex: 1,
  },
  field: {
    gap: theme.spacing.xs,
  },
  label: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
    marginBottom: theme.spacing.xs,
  },
  input: {
    backgroundColor: theme.colors.surface,
    borderRadius: 12,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.md,
    borderWidth: 1,
    borderColor: `${theme.colors.text.secondary}20`,
    color: theme.colors.text.primary,
    fontSize: 16,
  },
  passwordContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: `${theme.colors.text.secondary}20`,
  },
  passwordInput: {
    flex: 1,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.md,
    color: theme.colors.text.primary,
    fontSize: 16,
  },
  eyeIcon: {
    padding: theme.spacing.md,
  },
  errorText: {
    ...theme.typography.caption.primary,
    color: theme.colors.error,
    textAlign: 'center',
    marginTop: theme.spacing.sm,
  },
  submitButton: {
    backgroundColor: theme.colors.primary,
    borderRadius: 12,
    paddingVertical: theme.spacing.md,
    alignItems: 'center',
    marginTop: theme.spacing.lg,
  },
  submitButtonDisabled: {
    opacity: 0.6,
  },
  submitText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.inverse,
    fontWeight: '600',
    fontSize: 16,
  },
});

export default RegistrationScreen; 