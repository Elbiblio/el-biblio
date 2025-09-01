import React, { useEffect } from 'react';
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
import { observer } from 'mobx-react-lite';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { ChevronLeft, Eye, EyeOff, Sparkle } from '@/components/Icons';
import { useAuthStore } from '@/stores/AuthStore';
import { useRegistrationStore } from '@/stores/RegistrationStore';
import AvatarSelectionModal from '@/components/AvatarSelectionModal';
import * as Haptics from 'expo-haptics';
import { toast } from 'sonner-native';
import { RootStackParamList } from '@/types';
import { NativeStackScreenProps } from '@react-navigation/native-stack';

type RegistrationScreenProps = NativeStackScreenProps<RootStackParamList, 'RegistrationScreen'>;

const RegistrationScreen: React.FC<RegistrationScreenProps> = observer(({ navigation }) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const authStore = useAuthStore();
  const registrationStore = useRegistrationStore();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const {
    formData,
    confirmPassword,
    showPassword,
    showConfirmPassword,
    error,
    showAvatarModal,
  } = registrationStore.state;

  useEffect(() => {
    // Reset store on unmount
    return () => {
      registrationStore.reset();
    };
  }, [registrationStore]);

  const handleSubmit = () => {
    registrationStore.submit();
  };

  const handleAvatarSelect = async (avatarUrl: string) => {
    const success = await registrationStore.selectAvatar(avatarUrl);
    if (success) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Welcome to the El-biblio community!');
      navigation.replace('Home');
    } else {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
    }
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
                  value={formData.first_name}
                  onChangeText={(text) => registrationStore.setFormField('first_name', text)}
                  placeholder="Enter your first name"
                  placeholderTextColor={theme.colors.text.placeholder}
                  autoCapitalize="words"
                />
              </View>
              <View style={styles.nameField}>
                <Text style={styles.label}>Last Name</Text>
                <TextInput
                  style={styles.input}
                  value={formData.last_name}
                  onChangeText={(text) => registrationStore.setFormField('last_name', text)}
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
                onChangeText={(text) => registrationStore.setFormField('email', text)}
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
                  onChangeText={(text) => registrationStore.setFormField('password', text)}
                  placeholder="Create a password"
                  placeholderTextColor={theme.colors.text.placeholder}
                  secureTextEntry={!showPassword}
                  autoCapitalize="none"
                />
                <TouchableOpacity
                  onPress={registrationStore.togglePasswordVisibility}
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
                  value={confirmPassword}
                  onChangeText={registrationStore.setConfirmPassword}
                  placeholder="Confirm your password"
                  placeholderTextColor={theme.colors.text.placeholder}
                  secureTextEntry={!showConfirmPassword}
                  autoCapitalize="none"
                />
                <TouchableOpacity
                  onPress={registrationStore.toggleConfirmPasswordVisibility}
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

            {(error || authStore.error) && (
              <Text style={styles.errorText}>{error || authStore.error}</Text>
            )}

            <TouchableOpacity
              style={[styles.submitButton, authStore.isLoading && styles.submitButtonDisabled]}
              onPress={handleSubmit}
              disabled={authStore.isLoading}
            >
              {authStore.isLoading ? (
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
        onClose={registrationStore.closeAvatarModal}
        onSelect={handleAvatarSelect}
      />
    </View>
  );
});

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