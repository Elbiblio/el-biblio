
import React, { useState, useCallback } from 'react';
import {
  Image,
  View,
  Text,
  Modal,
  StyleSheet,
  TouchableOpacity,
  Platform,
  ActivityIndicator,
  ScrollView,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { XCircle, Camera, Image as ImageIcon } from '@/components/Icons';
import * as ImagePicker from 'expo-image-picker';
import { toast } from 'sonner-native';
import * as Haptics from 'expo-haptics';
import { SCREEN_DIMENSIONS } from '@/constants';

interface AvatarSelectionModalProps {
  visible: boolean;
  onClose: () => void;
  onSelect: (avatarUrl: string) => Promise<void>;
}

const SAMPLE_AVATARS = Array.from({ length: 36 }, (_, i) => 
  `https://api.elbiblio.com/avatars/${i + 1}.png`
);

const AvatarSelectionModal: React.FC<AvatarSelectionModalProps> = ({
    visible,
    onClose,
    onSelect,
  }) => {
    const theme = useTheme();
    const styles = React.useMemo(() => createStyles(theme), [theme]);
    const [isLoading, setIsLoading] = useState(false);
    const [selectedAvatar, setSelectedAvatar] = useState<string | null>(null);
    const [failedImages, setFailedImages] = useState<Set<string>>(new Set());
  
    const handleImageError = (uri: string) => {
      setFailedImages(prev => new Set(prev).add(uri));
    };
  
    const pickImage = async () => {
      try {
        const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
        if (status !== 'granted') {
          toast.error('Permission to access gallery was denied');
          return;
        }
  
        const result = await ImagePicker.launchImageLibraryAsync({
          mediaTypes: ImagePicker.MediaTypeOptions.Images,
          allowsEditing: true,
          aspect: [1, 1],
          quality: 0.8,
        });
  
        if (!result.canceled) {
          setSelectedAvatar(result.assets[0].uri);
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        }
      } catch (error) {
        toast.error('Failed to pick image');
      }
    };
  
    const handleConfirm = async () => {
      if (!selectedAvatar) return;
      
      setIsLoading(true);
      try {
        await onSelect(selectedAvatar);
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      } catch (error) {
        console.error('Avatar update error:', error);
        toast.error('Failed to update avatar');
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      } finally {
        setIsLoading(false);
      }
    };
  
    const handleAvatarSelect = (avatar: string) => {
      setSelectedAvatar(avatar);
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    };
  
    return (
      <Modal
        visible={visible}
        transparent
        animationType="fade"
        onRequestClose={onClose}
        statusBarTranslucent
      >
        <View style={styles.container}>
          <BlurView intensity={20} style={StyleSheet.absoluteFill} pointerEvents="none" />
          <View style={styles.overlay}>
            <View style={styles.modalContainer}>
              <BlurView intensity={10} style={styles.modalBlur} pointerEvents="none">
                {/* Close Button */}
                <TouchableOpacity 
                  style={styles.closeButton}
                  onPress={onClose}
                  hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                >
                  <XCircle size={24} color={theme.colors.text.secondary} />
                </TouchableOpacity>
  
                <View style={styles.content}>
                  <Text style={styles.title}>Make it yours!</Text>
                  <Text style={styles.subtitle}>
                    Choose an avatar that represents you
                  </Text>
    
                  {/* Selected Avatar Preview */}
                  {selectedAvatar && (
                    <View style={styles.previewContainer}>
                      <View style={styles.previewImage}>
                        <Image 
                          source={{ uri: selectedAvatar }} 
                          style={styles.avatarPreview}
                          onError={() => handleImageError(selectedAvatar)}
                        />
                      </View>
                      <Text style={styles.previewText}>
                        {selectedAvatar.includes('api.elbiblio.com') 
                          ? 'Looking good! This avatar suits you.' 
                          : 'Great choice! Your personal touch.'}
                      </Text>
                    </View>
                  )}
  
                  {/* Image Upload Button */}
                  <View style={styles.actionButtons}>
                    <TouchableOpacity 
                      style={styles.actionButton}
                      onPress={pickImage}
                    >
                      <ImageIcon size={24} color={theme.colors.text.primary} />
                      <Text style={styles.actionText}>Upload Photo</Text>
                    </TouchableOpacity>
                  </View>
  
                  {/* Sample Avatars */}
                  <Text style={styles.sectionTitle}>
                    Or choose from our collection
                  </Text>
                  <ScrollView 
                    horizontal 
                    showsHorizontalScrollIndicator={false}
                    contentContainerStyle={styles.sampleAvatars}
                    decelerationRate="fast"
                    snapToInterval={80 + theme.spacing.md}
                    snapToAlignment="center"
                  >
                    {SAMPLE_AVATARS.map((avatar, index) => (
                      <TouchableOpacity
                        key={index}
                        style={[
                          styles.avatarOption,
                          selectedAvatar === avatar && styles.selectedAvatar
                        ]}
                        onPress={() => handleAvatarSelect(avatar)}
                      >
                        <View style={styles.avatarImageContainer}>
                          <Image 
                            source={{ uri: avatar }} 
                            style={styles.avatarImage}
                            onError={() => handleImageError(avatar)}
                          />
                        </View>
                      </TouchableOpacity>
                    ))}
                  </ScrollView>
  
                  {/* Confirm Button */}
                  <TouchableOpacity
                    style={[
                      styles.confirmButton,
                      (!selectedAvatar || isLoading) && styles.confirmButtonDisabled
                    ]}
                    onPress={handleConfirm}
                    disabled={!selectedAvatar || isLoading}
                  >
                    {isLoading ? (
                      <ActivityIndicator color={theme.colors.text.inverse} />
                    ) : (
                      <Text style={styles.confirmText}>Confirm</Text>
                    )}
                  </TouchableOpacity>
                </View>
              </BlurView>
            </View>
          </View>
        </View>
      </Modal>
    );
  };
  
  const createStyles = (theme: Theme) => StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: 'rgba(0, 0, 0, 0.75)',
    },
    overlay: {
      flex: 1,
      justifyContent: 'center',
      padding: theme.spacing.lg,
    },
    modalContainer: {
      borderRadius: theme.borderRadius.xl,
      overflow: 'hidden',
      marginVertical: SCREEN_DIMENSIONS.height * 0.1,
      backgroundColor: theme.colors.background,
      ...Platform.select({
        ios: {
          shadowColor: '#000',
          shadowOffset: { width: 0, height: 2 },
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
      backgroundColor: theme.colors.background,
    },
    content: {
      padding: theme.spacing.xl,
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
      backgroundColor: theme.colors.surface,
      borderRadius: 16,
    },
    title: {
      ...theme.typography.heading.medium,
      color: theme.colors.text.primary,
      textAlign: 'center',
      marginBottom: theme.spacing.sm,
    },
    subtitle: {
      ...theme.typography.body.sans,
      color: theme.colors.text.secondary,
      textAlign: 'center',
      marginBottom: theme.spacing.xl,
    },
    previewContainer: {
      alignItems: 'center',
      marginBottom: theme.spacing.xl,
    },
    previewImage: {
      width: 120,
      height: 120,
      borderRadius: 60,
      borderWidth: 3,
      borderColor: theme.colors.primary,
      overflow: 'hidden',
      backgroundColor: theme.colors.surface,
    },
    avatarPreview: {
      width: '100%',
      height: '100%',
    },
    previewText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
      marginTop: theme.spacing.md,
    },
    actionButtons: {
      flexDirection: 'row',
      justifyContent: 'center',
      gap: theme.spacing.lg,
      marginBottom: theme.spacing.xl,
    },
    actionButton: {
      alignItems: 'center',
      gap: theme.spacing.xs,
      backgroundColor: theme.colors.surface,
      padding: theme.spacing.md,
      borderRadius: theme.borderRadius.lg,
      minWidth: 100,
    },
    actionText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.primary,
    },
    sectionTitle: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.md,
    },
    sampleAvatars: {
      paddingHorizontal: theme.spacing.lg,
      gap: theme.spacing.md,
      paddingBottom: theme.spacing.lg,
    },
    avatarOption: {
      borderRadius: 40,
      padding: 2,
      width: 80,
      height: 80,
      backgroundColor: theme.colors.surface,
      overflow: 'hidden',
    },
    selectedAvatar: {
      borderWidth: 2,
      borderColor: theme.colors.primary,
    },
    avatarImageContainer: {
      width: '100%',
      height: '100%',
      borderRadius: 40,
      overflow: 'hidden',
      backgroundColor: theme.colors.surface,
      alignItems: 'center',
      justifyContent: 'center',
    },
    avatarImage: {
      width: '100%',
      height: '100%',
    },
    confirmButton: {
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
    confirmButtonDisabled: {
      opacity: 0.5,
    },
    confirmText: {
      ...theme.typography.button.primary,
      color: theme.colors.text.inverse,
    },
  });
  
  export default AvatarSelectionModal;