import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Modal,
  Animated,
  Dimensions,
  Platform,
  ScrollView,
  useWindowDimensions,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { Share as RNShare } from 'react-native';
import { Heart, MessageCircle, X, BookOpen, Lightbulb } from './Icons';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import * as Haptics from 'expo-haptics';
import type { Reflection } from '@/types';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

interface ShareReflectionModalProps {
  visible: boolean;
  reflection: Reflection | null;
  onClose: () => void;
}

const ShareReflectionModal: React.FC<ShareReflectionModalProps> = ({
  visible,
  reflection,
  onClose,
}) => {
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const sheetWidth = React.useMemo(() => Math.min(width, 480), [width]);
  const [selectedType, setSelectedType] = useState<'story' | 'insight' | null>(null);
  const slideAnim = React.useRef(new Animated.Value(0)).current;
  const fadeAnim = React.useRef(new Animated.Value(0)).current;

  React.useEffect(() => {
    if (visible) {
      Animated.parallel([
        Animated.timing(slideAnim, {
          toValue: 1,
          duration: 300,
          useNativeDriver: true,
        }),
        Animated.timing(fadeAnim, {
          toValue: 1,
          duration: 200,
          useNativeDriver: true,
        }),
      ]).start();
    } else {
      Animated.parallel([
        Animated.timing(slideAnim, {
          toValue: 0,
          duration: 250,
          useNativeDriver: true,
        }),
        Animated.timing(fadeAnim, {
          toValue: 0,
          duration: 150,
          useNativeDriver: true,
        }),
      ]).start();
      setSelectedType(null);
    }
  }, [visible]);

  const handleShare = async (type: 'story' | 'insight') => {
    if (!reflection) return;

    try {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      
      const shareType = type === 'story' ? 'Sharing a story' : 'Sharing an insight';
      const message = `${shareType}:\n\n${reflection.content || ''}\n\n— ${reflection.user?.first_name || 'Someone'} via ElBiblio`;
      
      await RNShare.share({
        message,
        url: reflection.media_url || undefined,
      });
      
      onClose();
    } catch (error) {
      console.error('Share failed:', error);
    }
  };

  const handleClose = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onClose();
  };

  const slideStyle = {
    transform: [{
      translateY: slideAnim.interpolate({
        inputRange: [0, 1],
        outputRange: [Dimensions.get('window').height, 0],
      }),
    }],
  };

  const fadeStyle = {
    opacity: fadeAnim,
  };

  if (!reflection) return null;

  return (
    <Modal
      visible={visible}
      transparent
      animationType="none"
      statusBarTranslucent
    >
      <Animated.View style={[styles.overlay, fadeStyle]}>
        <TouchableOpacity
          style={styles.backdrop}
          activeOpacity={1}
          onPress={handleClose}
        />
        
        <Animated.View style={[styles.modalContainer, slideStyle]}>
          <BlurView
            intensity={20}
            style={[
              styles.modal,
              {
                paddingBottom: Math.max(theme.spacing.xl, insets.bottom + theme.spacing.md),
                width: sheetWidth,
                alignSelf: 'center',
              },
            ]}
          >
            <ScrollView
              contentContainerStyle={{ paddingBottom: theme.spacing.md }}
              showsVerticalScrollIndicator={false}
            >
              {/* Header */}
              <View style={styles.header}>
                <Text style={styles.title}>Share Reflection</Text>
                <TouchableOpacity
                  style={styles.closeButton}
                  onPress={handleClose}
                >
                  <X size={24} color={theme.colors.text.secondary} />
                </TouchableOpacity>
              </View>

              {/* Reflection Preview */}
              <View style={styles.previewContainer}>
                {reflection.verse && (
                  <View style={styles.verseContext}>
                    <Text style={styles.verseReference}>
                      {reflection.verse.reference_display}
                    </Text>
                    {reflection.verse.theme && (
                      <Text style={styles.verseTheme}>
                        {reflection.verse.theme.display_name}
                      </Text>
                    )}
                  </View>
                )}
                <Text style={styles.previewText} numberOfLines={3}>
                  {reflection.content}
                </Text>
                <View style={styles.previewMeta}>
                  <Text style={styles.previewAuthor}>
                    — {reflection.user?.first_name} {reflection.user?.last_name}
                  </Text>
                </View>
              </View>

              {/* Share Type Selection */}
              <View style={styles.typeSelection}>
                <Text style={styles.selectionTitle}>How would you like to share this?</Text>
                
                <TouchableOpacity
                  style={[
                    styles.typeOption,
                    selectedType === 'story' && styles.typeOptionSelected,
                  ]}
                  onPress={() => {
                    setSelectedType('story');
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                  }}
                >
                  <View style={[styles.typeIcon, { backgroundColor: `${theme.colors.primary}20` }]}>
                    <BookOpen size={24} color={theme.colors.primary} />
                  </View>
                  <View style={styles.typeContent}>
                    <Text style={styles.typeTitle}>Share as Story</Text>
                    <Text style={styles.typeDescription}>
                      Share a personal experience or testimony
                    </Text>
                  </View>
                </TouchableOpacity>

                <TouchableOpacity
                  style={[
                    styles.typeOption,
                    selectedType === 'insight' && styles.typeOptionSelected,
                  ]}
                  onPress={() => {
                    setSelectedType('insight');
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                  }}
                >
                  <View style={[styles.typeIcon, { backgroundColor: `${theme.colors.secondary}20` }]}>
                    <Lightbulb size={24} color={theme.colors.secondary} />
                  </View>
                  <View style={styles.typeContent}>
                    <Text style={styles.typeTitle}>Share as Insight</Text>
                    <Text style={styles.typeDescription}>
                      Share a revelation or understanding
                    </Text>
                  </View>
                </TouchableOpacity>
              </View>

              {/* Action Buttons */}
              <View style={styles.actions}>
                <TouchableOpacity
                  style={[styles.actionButton, styles.cancelButton]}
                  onPress={handleClose}
                >
                  <Text style={styles.cancelText}>Cancel</Text>
                </TouchableOpacity>
                
                <TouchableOpacity
                  style={[
                    styles.actionButton,
                    styles.shareButton,
                    !selectedType && styles.shareButtonDisabled,
                  ]}
                  onPress={() => selectedType && handleShare(selectedType)}
                  disabled={!selectedType}
                >
                  <Text style={[
                    styles.shareText,
                    !selectedType && styles.shareTextDisabled,
                  ]}>
                    Share as {selectedType === 'story' ? 'Story' : 'Insight'}
                  </Text>
                </TouchableOpacity>
              </View>
            </ScrollView>
          </BlurView>
        </Animated.View>
      </Animated.View>
    </Modal>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'flex-end',
    alignItems: 'center',
  },
  backdrop: {
    flex: 1,
    alignSelf: 'stretch',
  },
  modalContainer: {
    width: '100%',
    maxHeight: '85%',
  },
  modal: {
    backgroundColor: theme.colors.background,
    borderTopLeftRadius: theme.borderRadius.xl,
    borderTopRightRadius: theme.borderRadius.xl,
    padding: theme.spacing.lg,
    paddingBottom: theme.spacing.xl,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.lg,
  },
  title: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
  },
  closeButton: {
    padding: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
  },
  previewContainer: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.lg,
    borderLeftWidth: 3,
    borderLeftColor: theme.colors.primary,
  },
  verseContext: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme.spacing.sm,
    gap: theme.spacing.sm,
  },
  verseReference: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  verseTheme: {
    ...theme.typography.caption.secondary,
    color: theme.colors.secondary,
    backgroundColor: `${theme.colors.secondary}20`,
    paddingHorizontal: theme.spacing.xs,
    paddingVertical: 2,
    borderRadius: theme.borderRadius.full,
  },
  previewText: {
    ...theme.typography.body.serif,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
    lineHeight: 22,
  },
  previewMeta: {
    alignItems: 'flex-end',
  },
  previewAuthor: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontStyle: 'italic',
  },
  typeSelection: {
    marginBottom: theme.spacing.xl,
  },
  selectionTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
    fontWeight: '600',
  },
  typeOption: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,
    marginBottom: theme.spacing.sm,
    backgroundColor: theme.colors.surface,
    borderWidth: 2,
    borderColor: 'transparent',
    minHeight: 80,
  },
  typeOptionSelected: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
  },
  typeIcon: {
    width: 52,
    height: 52,
    borderRadius: theme.borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: theme.spacing.lg,
  },
  typeContent: {
    flex: 1,
  },
  typeTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
    marginBottom: 2,
  },
  typeDescription: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  actions: {
    flexDirection: 'row',
    gap: theme.spacing.lg,
    marginTop: theme.spacing.lg,
  },
  actionButton: {
    flex: 1,
    paddingVertical: theme.spacing.lg,
    paddingHorizontal: theme.spacing.xl,
    borderRadius: theme.borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 52,
  },
  cancelButton: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  shareButton: {
    backgroundColor: theme.colors.primary,
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
  shareButtonDisabled: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    elevation: 0,
    shadowOpacity: 0,
  },
  cancelText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  shareText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  shareTextDisabled: {
    color: theme.colors.text.secondary,
  },
});

export default ShareReflectionModal;
