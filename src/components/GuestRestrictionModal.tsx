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
import { Lock, Users, Sparkle } from '@/components/Icons';
import * as Haptics from 'expo-haptics';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RootStackParamList } from '@/types';

interface GuestRestrictionModalProps {
  visible: boolean;
  onClose: () => void;
  feature?: string;
}

type NavigationProp = NativeStackNavigationProp<RootStackParamList>;

const GuestRestrictionModal: React.FC<GuestRestrictionModalProps> = ({
  visible,
  onClose,
  feature = 'this feature',
}) => {
  const theme = useTheme();
  const navigation = useNavigation<NavigationProp>();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const handleCreateAccount = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    onClose();
    navigation.navigate('RegistrationScreen');
  };

  const handleMaybeLater = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onClose();
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
              <View style={styles.iconContainer}>
                <Lock size={32} color={theme.colors.primary} />
              </View>
              <Text style={styles.title}>Feature Locked</Text>
              <Text style={styles.subtitle}>
                {feature} requires a registered account
              </Text>
            </View>

            <View style={styles.features}>
              <Text style={styles.featuresTitle}>Create an account to unlock:</Text>
              
              <View style={styles.featureList}>
                <View style={styles.featureItem}>
                  <Users size={20} color={theme.colors.primary} />
                  <Text style={styles.featureText}>Share notes & reflections</Text>
                </View>
                
                <View style={styles.featureItem}>
                  <Sparkle size={20} color={theme.colors.primary} />
                  <Text style={styles.featureText}>Join community challenges</Text>
                </View>
                
                <View style={styles.featureItem}>
                  <Users size={20} color={theme.colors.primary} />
                  <Text style={styles.featureText}>Comment & interact with others</Text>
                </View>
                
                <View style={styles.featureItem}>
                  <Sparkle size={20} color={theme.colors.primary} />
                  <Text style={styles.featureText}>View learning spotlights</Text>
                </View>
                
                <View style={styles.featureItem}>
                  <Users size={20} color={theme.colors.primary} />
                  <Text style={styles.featureText}>Access leaderboards</Text>
                </View>
              </View>
            </View>

            <View style={styles.actions}>
              <TouchableOpacity
                style={styles.primaryButton}
                onPress={handleCreateAccount}
                activeOpacity={0.8}
              >
                <Text style={styles.primaryButtonText}>Create Account</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.secondaryButton}
                onPress={handleMaybeLater}
              >
                <Text style={styles.secondaryButtonText}>Maybe Later</Text>
              </TouchableOpacity>
            </View>
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
  iconContainer: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: `${theme.colors.primary}15`,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme.spacing.md,
  },
  title: {
    ...theme.typography.heading.large,
    color: theme.colors.text.primary,
    textAlign: 'center',
    marginBottom: theme.spacing.sm,
  },
  subtitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    lineHeight: 20,
  },
  features: {
    marginBottom: theme.spacing.xl,
  },
  featuresTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  featureList: {
    gap: theme.spacing.sm,
  },
  featureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  featureText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    flex: 1,
  },
  actions: {
    gap: theme.spacing.md,
  },
  primaryButton: {
    backgroundColor: theme.colors.primary,
    borderRadius: 12,
    paddingVertical: theme.spacing.md,
    alignItems: 'center',
  },
  primaryButtonText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.inverse,
    fontWeight: '600',
    fontSize: 16,
  },
  secondaryButton: {
    paddingVertical: theme.spacing.md,
    alignItems: 'center',
  },
  secondaryButtonText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    fontWeight: '500',
  },
});

export default GuestRestrictionModal; 