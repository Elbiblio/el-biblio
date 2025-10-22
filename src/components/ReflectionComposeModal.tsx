import React, { useEffect, useMemo, useRef, useState } from 'react';
import { View, Text, TouchableOpacity, KeyboardAvoidingView, TouchableWithoutFeedback, Keyboard, TextInput, Platform, StyleSheet } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { X, Sparkle, Send } from '@/components/Icons';

export interface ReflectionComposeModalProps {
  visible: boolean;
  onClose: () => void;
  reflectionText: string;
  onChangeText: (text: string) => void;
  reflectionType: 1 | 2;
  onChangeType: (t: 1 | 2) => void;
  isUploading: boolean;
  canSubmit: boolean;
  submitLabel: string;
  onSubmit: () => void;
  onOpenFaceTips: () => void;
  onOpenFace2Face: () => void;
}

const ReflectionComposeModal: React.FC<ReflectionComposeModalProps> = ({
  visible,
  onClose,
  reflectionText,
  onChangeText,
  reflectionType,
  onChangeType,
  isUploading,
  canSubmit,
  submitLabel,
  onSubmit,
  onOpenFaceTips,
  onOpenFace2Face,
}) => {
  const insets = useSafeAreaInsets();
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme, insets.bottom), [theme, insets.bottom]);

  const [showGuide, setShowGuide] = useState(false);
  const [guideCountdown, setGuideCountdown] = useState(30);
  const guideTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    (async () => {
      if (!visible) return;
      try {
        const seen = await AsyncStorage.getItem('vd_reflection_guide_seen');
        if (seen === '1') {
          setShowGuide(false);
          return;
        }
        setShowGuide(true);
        setGuideCountdown(30);
        if (guideTimerRef.current) clearInterval(guideTimerRef.current);
        guideTimerRef.current = setInterval(() => {
          setGuideCountdown(prev => {
            if (prev <= 1) {
              if (guideTimerRef.current) clearInterval(guideTimerRef.current);
              guideTimerRef.current = null;
              AsyncStorage.setItem('vd_reflection_guide_seen', '1').catch(() => {});
              setShowGuide(false);
              return 0;
            }
            return prev - 1;
          });
        }, 1000);
      } catch {
        setShowGuide(false);
      }
    })();
    return () => {
      if (guideTimerRef.current) clearInterval(guideTimerRef.current);
      guideTimerRef.current = null;
    };
  }, [visible]);

  if (!visible) return null;

  const isWordBiteType = reflectionType === 1;

  return (
    <View style={styles.container}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={insets.bottom + 16}
        style={styles.inner}
      >
        <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
          <View style={styles.card}>
            <View style={styles.headerRow}>
              <TouchableOpacity onPress={() => !isUploading && onClose()} style={styles.headerBtn}>
                <X size={18} color={theme.colors.text.secondary} />
              </TouchableOpacity>
              <Text style={styles.title}>Share a reflection</Text>
              <View style={styles.headerBtn} />
            </View>

            {showGuide && (
              <View style={styles.guideCard}>
                <Text style={styles.guideTitle}>Prepare your heart</Text>
                <Text style={styles.guidePrayer}>
{`“Open my eyes, that I may behold wondrous things out of your law.” (Psalm 119:18)
“Then He opened their minds to understand the Scriptures.” (Luke 24:45)

Lord, open my eyes and mind to understand Your Word. Help me see what You are saying and respond with faith, love, and obedience. Amen.`}
                </Text>
                <Text style={styles.guideCountdown}>Starting in {guideCountdown}s…</Text>
                <TouchableOpacity
                  style={styles.guideSkip}
                  onPress={() => { AsyncStorage.setItem('vd_reflection_guide_seen', '1').catch(()=>{}); setShowGuide(false); }}
                >
                  <Text style={styles.guideSkipText}>Skip</Text>
                </TouchableOpacity>
              </View>
            )}

            <View style={styles.typeSelector}>
              <TouchableOpacity
                style={[styles.typeBtn, reflectionType === 1 && styles.typeBtnActive]}
                onPress={() => onChangeType(1)}
                disabled={isUploading}
              >
                <Text style={[styles.typeBtnText, reflectionType === 1 && styles.typeBtnTextActive]}>Word Bite</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.typeBtn, reflectionType === 2 && styles.typeBtnActive]}
                onPress={() => onChangeType(2)}
                disabled={isUploading}
              >
                <Text style={[styles.typeBtnText, reflectionType === 2 && styles.typeBtnTextActive]}>Face2Face</Text>
              </TouchableOpacity>
            </View>

            <TextInput
              style={styles.input}
              placeholder={reflectionType === 1 ? 'Share a Word Bite… (≤ 50 words)' : 'Face2Face caption (optional)'}
              multiline
              maxLength={500}
              value={reflectionText}
              onChangeText={onChangeText}
              autoFocus={!showGuide}
              editable={!isUploading && !showGuide}
              placeholderTextColor={theme.colors.text.tertiary}
              textAlignVertical="top"
            />

            {reflectionType === 1 && (
              <Text style={styles.wordCount}>Keep it concise and heartfelt. Max 50 words.</Text>
            )}

            {reflectionType === 2 && (
              <View style={styles.faceRow}>
                <TouchableOpacity style={styles.faceBtn} onPress={onOpenFaceTips} disabled={isUploading}>
                  <Sparkle size={16} color={theme.colors.text.secondary} />
                  <Text style={styles.faceBtnText}>Tips</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.faceBtn} onPress={onOpenFace2Face} disabled={isUploading}>
                  <Text style={styles.faceBtnText}>Record Face2Face</Text>
                </TouchableOpacity>
              </View>
            )}

            <View style={styles.actions}>
              <TouchableOpacity style={styles.cancelBtn} onPress={() => !isUploading && onClose()} disabled={isUploading}>
                <Text style={styles.cancelText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.submitBtn, (!canSubmit || showGuide) && styles.submitBtnDisabled]}
                onPress={!showGuide && canSubmit ? onSubmit : undefined}
                disabled={!canSubmit || showGuide}
              >
                <Text style={styles.submitText}>{submitLabel}</Text>
                <Send size={16} color={theme.colors.text.inverse} />
              </TouchableOpacity>
            </View>
          </View>
        </TouchableWithoutFeedback>
      </KeyboardAvoidingView>
    </View>
  );
};

const createStyles = (theme: Theme, safeBottom: number = 0) => StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject as any,
    backgroundColor: theme.colors.background,
  },
  inner: {
    flex: 1,
    justifyContent: 'flex-start',
  },
  card: {
    flex: 1,
    paddingHorizontal: theme.spacing.lg,
    paddingTop: theme.spacing.lg,
    paddingBottom: safeBottom + theme.spacing.lg,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.md,
  },
  headerBtn: {
    width: 32,
    height: 32,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    fontWeight: '700',
  },
  guideCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.md,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: theme.colors.border,
  },
  guideTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.primary,
    marginBottom: theme.spacing.xs,
    fontWeight: '700',
  },
  guidePrayer: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.primary,
    lineHeight: 18,
  },
  guideCountdown: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.sm,
  },
  guideSkip: {
    alignSelf: 'flex-end',
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
  },
  guideSkipText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  typeSelector: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
    marginBottom: theme.spacing.md,
  },
  typeBtn: {
    flex: 1,
    padding: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
  },
  typeBtnActive: {
    backgroundColor: theme.colors.primary,
  },
  typeBtnText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  typeBtnTextActive: {
    color: theme.colors.text.inverse,
  },
  input: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    minHeight: 100,
    maxHeight: 160,
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  wordCount: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    alignSelf: 'flex-start',
    marginTop: theme.spacing.xs,
  },
  faceRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: theme.spacing.sm,
  },
  faceBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    backgroundColor: theme.colors.surface,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
  },
  faceBtnText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'center',
    gap: theme.spacing.sm,
    marginTop: theme.spacing.sm,
  },
  cancelBtn: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  cancelText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  submitBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    backgroundColor: theme.colors.primary,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
  },
  submitBtnDisabled: { opacity: 0.5 },
  submitText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
});

export default ReflectionComposeModal;
