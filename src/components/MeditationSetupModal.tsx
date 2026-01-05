import React, { useMemo, useState, useCallback, useEffect } from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet, ScrollView, TextInput, KeyboardAvoidingView, Platform } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { MaterialIcons } from '@expo/vector-icons';
import { Check, X, Heart, Bell, Flame } from '@/components/Icons';
import ChantLibraryModal from './ChantLibraryModal';
import { stopAllSounds } from '@/services/audio';
import { useMeditationStore } from '@/stores/StoreProvider';

export type MeditationStyle = 'parable' | 'virtue' | 'centering' | 'jesus_prayer' | 'chant';

const PACE_OPTIONS = [
  { id: 'slow' as const, label: 'Slow', description: 'Steady and calming' },
  { id: 'medium' as const, label: 'Medium', description: 'Balanced rhythm' },
  { id: 'fast' as const, label: 'Fast', description: 'Energising cadence' },
];

const CHANT_OPTIONS = [
  { id: '10000-reasons', label: '10,000 Reasons' },
  { id: '10000-reasons-african', label: '10,000 Reasons (African)' },
  { id: 'be-still-my-soul', label: 'Be Still My Soul' },
  { id: 'soul-of-jesus-sanctify-me', label: 'Soul of Jesus, Sanctify Me' },
  { id: 'oceans', label: 'Oceans (Spirit Lead Me)' },
];

export interface MeditationSetupValues {
  style: MeditationStyle;
  sound: string | null;
  virtueId?: string | null;
  centeringWord?: string | null;
  jesusPrayerPace?: 'slow' | 'medium' | 'fast';
  chantId?: string | null;
  parableReadMode?: 'silent' | 'aloud';
  centeringReadMode?: 'silent' | 'aloud';
  centeringRepeatIntervalSec?: number;
  chantReflectionPauseSec?: number;
}

interface MeditationSetupModalProps {
  visible: boolean;
  onClose: () => void;
  onStart: (values: MeditationSetupValues) => void | Promise<void>;
  initialValues?: Partial<MeditationSetupValues>;
  virtues?: Array<{ id: string; name: string; color_code?: string | null }>;
}

const MeditationSetupModal: React.FC<MeditationSetupModalProps> = ({ visible, onClose, onStart, initialValues, virtues = [] }) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => createStyles(theme, insets), [theme, insets]);
  const meditationStore = useMeditationStore();

  const [currentStep, setCurrentStep] = useState<'style' | 'details' | 'sound' | 'summary'>('style');
  const [styleChoice, setStyleChoice] = useState<MeditationStyle>(initialValues?.style ?? 'virtue');
  const [virtueId, setVirtueId] = useState<string | null>(initialValues?.virtueId ?? null);
  const [sound, setSound] = useState<string | null>(initialValues?.sound ?? 'ambient');
  const [centeringWord, setCenteringWord] = useState<string>(initialValues?.centeringWord ?? 'Jesus');
  const [jesusPrayerPace, setJesusPrayerPace] = useState<'slow' | 'medium' | 'fast'>(initialValues?.jesusPrayerPace ?? 'medium');
  const [chantId, setChantId] = useState<string | null>(initialValues?.chantId ?? CHANT_OPTIONS[0].id);
  const [showChantLibrary, setShowChantLibrary] = useState(false);
  const [parableReadMode, setParableReadMode] = useState<'silent' | 'aloud'>(initialValues?.parableReadMode ?? 'silent');
  const [centeringReadMode, setCenteringReadMode] = useState<'silent' | 'aloud'>(initialValues?.centeringReadMode ?? 'silent');
  const [centeringRepeatIntervalSec, setCenteringRepeatIntervalSec] = useState<number>(initialValues?.centeringRepeatIntervalSec ?? 15);
  const [chantReflectionPauseSec, setChantReflectionPauseSec] = useState<number>(initialValues?.chantReflectionPauseSec ?? 20);

  const selectedChant = useMemo(() => CHANT_OPTIONS.find(c => c.id === chantId)?.label ?? 'Chant', [chantId]);
  const selectedVirtue = useMemo(() => virtues.find(v => v.id === virtueId) ?? null, [virtueId, virtues]);

  const canContinue = useMemo(() => {
    if (currentStep === 'style') return true;
    if (currentStep === 'details') {
      if (styleChoice === 'virtue') return Boolean(virtueId);
      if (styleChoice === 'centering') return Boolean(centeringWord && centeringWord.trim().length > 0);
      if (styleChoice === 'jesus_prayer') return true;
      if (styleChoice === 'chant') return Boolean(chantId);
      if (styleChoice === 'parable') return true;
    }
    if (currentStep === 'sound') return true;
    return true;
  }, [currentStep, styleChoice, virtueId, centeringWord, chantId]);

  const headerTitle = useMemo(() => {
    if (currentStep === 'style') return 'Meditation Style';
    if (currentStep === 'details') return styleChoice === 'virtue' ? 'Choose a Virtue' : styleChoice === 'centering' ? 'Centering Options' : styleChoice === 'jesus_prayer' ? 'Prayer Pace' : styleChoice === 'chant' ? 'Choose a Chant' : 'Parable Options';
    if (currentStep === 'sound') return 'Background Sound';
    return 'Summary';
  }, [currentStep, styleChoice]);

  const handleNext = useCallback(() => {
    if (currentStep === 'style') {
      setCurrentStep('details');
    } else if (currentStep === 'details') {
      if (styleChoice === 'chant') {
        setCurrentStep('summary');
      } else {
        setCurrentStep('sound');
      }
    } else if (currentStep === 'sound') {
      try { meditationStore.setIsPreviewingSound(false); } catch {}
      try { stopAllSounds(); } catch {}
      setCurrentStep('summary');
    }
  }, [currentStep, styleChoice, meditationStore]);

  const handleBack = useCallback(() => {
    if (currentStep === 'summary') setCurrentStep(styleChoice === 'chant' ? 'details' : 'sound');
    else if (currentStep === 'sound') setCurrentStep(styleChoice === 'parable' ? 'style' : 'details');
    else if (currentStep === 'details') setCurrentStep('style');
  }, [currentStep, styleChoice]);

  const handleStart = useCallback(() => {
    try { meditationStore.setIsPreviewingSound(false); } catch {}
    try { stopAllSounds(); } catch {}
    onStart({
      style: styleChoice,
      sound: styleChoice === 'chant' ? null : sound,
      virtueId,
      centeringWord: centeringWord.trim() || null,
      jesusPrayerPace,
      chantId,
      parableReadMode,
      centeringReadMode,
      centeringRepeatIntervalSec,
      chantReflectionPauseSec,
    });
    onClose();
    setCurrentStep('style');
  }, [onStart, onClose, styleChoice, sound, virtueId, centeringWord, jesusPrayerPace, chantId, parableReadMode, centeringReadMode, centeringRepeatIntervalSec, chantReflectionPauseSec, meditationStore]);

  useEffect(() => {
    if (styleChoice === 'chant') {
      if (sound !== null) setSound(null);
      if (currentStep === 'sound') setCurrentStep('summary');
      try { meditationStore.setIsPreviewingSound(false); } catch {}
    } else {
      // Restore last non-chant sound if we are leaving chant and currently silent
      try {
        const last = (meditationStore.state as any).lastNonChantSound as string | null;
        if (sound === null && last) {
          setSound(last);
          meditationStore.setSelectedBackgroundSound(last as any);
        }
      } catch {}
    }
  }, [styleChoice, currentStep, sound, meditationStore]);

  useEffect(() => {
    try { meditationStore.setIsPreviewingSound(currentStep === 'sound' && styleChoice !== 'chant'); } catch {}
    return () => { try { meditationStore.setIsPreviewingSound(false); } catch {} };
  }, [currentStep, styleChoice, meditationStore]);

  const handleCloseModal = useCallback(() => {
    try { meditationStore.setIsPreviewingSound(false); } catch {}
    try { stopAllSounds(); } catch {}
    onClose();
  }, [meditationStore, onClose]);

  if (!visible) return null;

  return (
    <Modal visible={visible} animationType="slide" transparent onRequestClose={handleCloseModal} statusBarTranslucent>
      <KeyboardAvoidingView
        style={styles.overlay}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 20}
      >
        <View style={styles.container}>
          <View style={styles.header}>
            {currentStep !== 'style' && (
              <TouchableOpacity onPress={handleBack} style={styles.backButton}>
                <MaterialIcons name="arrow-back" size={24} color={theme.colors.text.primary} />
              </TouchableOpacity>
            )}
            <Text style={styles.title}>{headerTitle}</Text>
            <TouchableOpacity onPress={handleCloseModal} style={styles.closeButton}>
              <X size={24} color={theme.colors.text.primary} />
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.content}>
            {currentStep === 'style' && (
              <View style={styles.section}>
                <View style={styles.list}>
                  {[
                    { id: 'parable' as MeditationStyle, label: 'Parable of Jesus', description: 'Sit with one of Jesus\' parables.' },
                    { id: 'virtue' as MeditationStyle, label: 'Grow a Virtue', description: 'Focus on a single virtue such as Love or Humility.' },
                    { id: 'centering' as MeditationStyle, label: 'Centering Prayer', description: 'Choose a sacred word and rest in silence.' },
                    { id: 'jesus_prayer' as MeditationStyle, label: 'Jesus Prayer', description: 'Pray “Lord Jesus Christ… have mercy on me” with your breath.' },
                    { id: 'chant' as MeditationStyle, label: 'Chant', description: 'Meditate to a song for the purposes of Worship and drawing closer to God.' },
                  ].map(option => {
                    const isActive = option.id === styleChoice;
                    return (
                      <TouchableOpacity key={option.id} style={[styles.card, isActive && styles.cardActive]} onPress={() => setStyleChoice(option.id)}>
                        <View style={styles.cardHeader}>
                          <Text style={[styles.cardTitle, isActive && styles.cardTitleActive]}>{option.label}</Text>
                          {isActive && <Check size={20} color={theme.colors.primary} />}
                        </View>
                        <Text style={[styles.cardDescription, isActive && styles.cardDescriptionActive]}>{option.description}</Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>
            )}

            {currentStep === 'details' && styleChoice === 'virtue' && (
              <View style={styles.section}>
                <View style={styles.list}>
                  {virtues.map(v => {
                    const isActive = v.id === virtueId;
                    return (
                      <TouchableOpacity key={v.id} style={[styles.card, isActive && styles.cardActive]} onPress={() => setVirtueId(v.id)}>
                        <View style={styles.cardHeader}>
                          <Text style={[styles.cardTitle, isActive && styles.cardTitleActive]}>{v.name}</Text>
                          {isActive && <Check size={20} color={theme.colors.primary} />}
                        </View>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>
            )}

            {currentStep === 'details' && styleChoice === 'centering' && (
              <View style={styles.section}>
                <View style={styles.inputGroup}>
                  <Text style={styles.label}>Sacred Word</Text>
                  <TextInput
                    value={centeringWord}
                    onChangeText={setCenteringWord}
                    placeholder="e.g., Jesus, Abba, Mercy"
                    placeholderTextColor={theme.colors.text.secondary}
                    style={styles.input}
                  />
                </View>
                <View style={styles.quickRow}>
                  {['Jesus', 'Abba', 'Mercy', 'Peace'].map(word => (
                    <TouchableOpacity key={word} style={styles.quickPill} onPress={() => setCenteringWord(word)}>
                      <Text style={styles.quickPillText}>{word}</Text>
                    </TouchableOpacity>
                  ))}
                </View>
                <View style={{ height: 12 }} />
                <View style={styles.listInline}>
                  {[
                    { id: 'silent', label: 'Silent' },
                    { id: 'aloud', label: 'Read Aloud' },
                  ].map(opt => {
                    const isActive = opt.id === centeringReadMode;
                    return (
                      <TouchableOpacity key={opt.id} style={[styles.inlineOption, isActive && styles.inlineOptionActive]} onPress={() => setCenteringReadMode(opt.id as any)}>
                        <Text style={[styles.inlineOptionTitle, isActive && styles.inlineOptionTitleActive]}>{opt.label}</Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
                <View style={{ height: 12 }} />
                <View style={styles.listInline}>
                  {[10, 15, 20, 25, 30].map(sec => {
                    const isActive = sec === centeringRepeatIntervalSec;
                    return (
                      <TouchableOpacity key={sec} style={[styles.inlineOption, isActive && styles.inlineOptionActive]} onPress={() => setCenteringRepeatIntervalSec(sec)}>
                        <Text style={[styles.inlineOptionTitle, isActive && styles.inlineOptionTitleActive]}>{sec}s</Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>
            )}

            {currentStep === 'details' && styleChoice === 'jesus_prayer' && (
              <View style={styles.section}>
                <View style={styles.listInline}>
                  {PACE_OPTIONS.map(p => {
                    const isActive = p.id === jesusPrayerPace;
                    return (
                      <TouchableOpacity key={p.id} style={[styles.inlineOption, isActive && styles.inlineOptionActive]} onPress={() => setJesusPrayerPace(p.id)}>
                        <Text style={[styles.inlineOptionTitle, isActive && styles.inlineOptionTitleActive]}>{p.label}</Text>
                        <Text style={[styles.inlineOptionDescription, isActive && styles.inlineOptionDescriptionActive]}>{p.description}</Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>
            )}

            {currentStep === 'details' && styleChoice === 'chant' && (
              <View style={styles.section}>
                <View style={styles.list}>
                  <TouchableOpacity style={[styles.card, styles.cardActive]} onPress={() => setShowChantLibrary(true)}>
                    <View style={styles.cardHeader}>
                      <Text style={[styles.cardTitle, styles.cardTitleActive]}>Browse Chant Library</Text>
                      <MaterialIcons name="library-music" size={22} color={theme.colors.primary} />
                    </View>
                    <Text style={[styles.cardDescription, styles.cardDescriptionActive]}>
                      {selectedChant}
                    </Text>
                  </TouchableOpacity>
                </View>
                <View style={{ height: 12 }} />
                <View style={styles.listInline}>
                  {[15, 20, 30, 45, 60].map(sec => {
                    const isActive = sec === chantReflectionPauseSec;
                    return (
                      <TouchableOpacity key={sec} style={[styles.inlineOption, isActive && styles.inlineOptionActive]} onPress={() => setChantReflectionPauseSec(sec)}>
                        <Text style={[styles.inlineOptionTitle, isActive && styles.inlineOptionTitleActive]}>{sec}s pause</Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>
            )}

            {currentStep === 'details' && styleChoice === 'parable' && (
              <View style={styles.section}>
                <View style={styles.listInline}>
                  {[
                    { id: 'silent', label: 'Silent' },
                    { id: 'aloud', label: 'Read Aloud' },
                  ].map(opt => {
                    const isActive = opt.id === parableReadMode;
                    return (
                      <TouchableOpacity key={opt.id} style={[styles.inlineOption, isActive && styles.inlineOptionActive]} onPress={() => setParableReadMode(opt.id as any)}>
                        <Text style={[styles.inlineOptionTitle, isActive && styles.inlineOptionTitleActive]}>{opt.label}</Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>
            )}

            

            {currentStep === 'sound' && styleChoice !== 'chant' && (
              <View style={styles.section}>
                <View style={styles.soundRow}>
                  {[
                    { id: 'ambient', label: 'Ambient', icon: Bell },
                    { id: 'heartbeat', label: 'Heartbeat', icon: Heart },
                    { id: null, label: 'Silent', icon: Flame },
                  ].map(({ id, label, icon: Icon }) => {
                    const isActive = sound === id;
                    return (
                      <TouchableOpacity
                        key={label}
                        style={[styles.soundOption, isActive && styles.soundOptionActive]}
                        onPress={() => {
                          setSound(id as any);
                          try { meditationStore.setSelectedBackgroundSound(id as any); } catch {}
                        }}
                      >
                        <Icon size={18} color={isActive ? theme.colors.primary : theme.colors.text.secondary} />
                        <Text style={[styles.soundOptionText, isActive && styles.soundOptionTextActive]}>{label}</Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>
            )}

            {currentStep === 'summary' && (
              <View style={styles.section}>
                <View style={styles.summaryCard}>
                  <View style={styles.summaryRow}>
                    <Text style={styles.summaryLabel}>Style</Text>
                    <Text style={styles.summaryValue}>
                      {styleChoice === 'virtue' ? 'Grow a Virtue' : styleChoice === 'parable' ? 'Parable of Jesus' : styleChoice === 'centering' ? 'Centering Prayer' : styleChoice === 'jesus_prayer' ? 'Jesus Prayer' : 'Chant'}
                    </Text>
                  </View>
                  {styleChoice === 'virtue' && (
                    <View style={styles.summaryRow}>
                      <Text style={styles.summaryLabel}>Virtue</Text>
                      <Text style={styles.summaryValue}>{selectedVirtue?.name ?? '-'}</Text>
                    </View>
                  )}
                  {styleChoice === 'parable' && (
                    <View style={styles.summaryRow}>
                      <Text style={styles.summaryLabel}>Read</Text>
                      <Text style={styles.summaryValue}>{parableReadMode}</Text>
                    </View>
                  )}
                  {styleChoice === 'centering' && (
                    <View style={styles.summaryRow}>
                      <Text style={styles.summaryLabel}>Word</Text>
                      <Text style={styles.summaryValue}>{centeringWord}</Text>
                    </View>
                  )}
                  {styleChoice === 'centering' && (
                    <View style={styles.summaryRow}>
                      <Text style={styles.summaryLabel}>Mode</Text>
                      <Text style={styles.summaryValue}>{centeringReadMode} · {centeringRepeatIntervalSec}s</Text>
                    </View>
                  )}
                  {styleChoice === 'jesus_prayer' && (
                    <View style={styles.summaryRow}>
                      <Text style={styles.summaryLabel}>Pace</Text>
                      <Text style={styles.summaryValue}>{jesusPrayerPace}</Text>
                    </View>
                  )}
                  {styleChoice === 'chant' && (
                    <View style={styles.summaryRow}>
                      <Text style={styles.summaryLabel}>Chant</Text>
                      <Text style={styles.summaryValue}>{selectedChant}</Text>
                    </View>
                  )}
                  {styleChoice === 'chant' && (
                    <View style={styles.summaryRow}>
                      <Text style={styles.summaryLabel}>Pause</Text>
                      <Text style={styles.summaryValue}>{chantReflectionPauseSec}s between loops</Text>
                    </View>
                  )}
                </View>
              </View>
            )}
          </ScrollView>

          <View style={styles.footer}>
            {currentStep === 'summary' ? (
              <TouchableOpacity style={[styles.primaryBtn]} onPress={handleStart}>
                <Text style={styles.primaryBtnText}>Save</Text>
              </TouchableOpacity>
            ) : (
              <TouchableOpacity style={[styles.primaryBtn, !canContinue && styles.primaryBtnDisabled]} onPress={handleNext} disabled={!canContinue}>
                <Text style={styles.primaryBtnText}>Continue</Text>
              </TouchableOpacity>
            )}
          </View>
          <ChantLibraryModal
            visible={showChantLibrary}
            selectedId={chantId ?? undefined}
            onClose={() => setShowChantLibrary(false)}
            onSelect={(id: string) => {
              setChantId(id);
              setShowChantLibrary(false);
            }}
          />
        </View>
      </View>
      </KeyboardAvoidingView>
    </Modal>
  );
};

const createStyles = (theme: any, insets: { top: number; bottom: number }) => StyleSheet.create({
  overlay: { 
    flex: 1, 
    backgroundColor: 'rgba(0,0,0,0.5)', 
    justifyContent: 'center', 
    padding: 20,
    paddingTop: Math.max(20, insets.top),
    paddingBottom: Math.max(20, insets.bottom),
  },
  container: { 
    backgroundColor: theme.colors.background, 
    borderRadius: 12, 
    maxHeight: '92%',
  },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 16, borderBottomWidth: 1, borderBottomColor: theme.colors.border },
  title: { ...theme.typography.h6, color: theme.colors.text.primary },
  closeButton: { padding: 4 },
  backButton: { padding: 4, marginRight: 8 },
  content: { padding: 16 },
  section: { marginBottom: 24 },
  list: { gap: 12 },
  listInline: { gap: 12, flexDirection: 'row' },
  card: { borderWidth: 1, borderColor: theme.colors.border, borderRadius: 12, padding: 16, backgroundColor: theme.colors.surface },
  cardActive: { borderColor: theme.colors.primary, backgroundColor: `${theme.colors.primary}10`, borderWidth: 2 },
  cardHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 },
  cardTitle: { ...theme.typography.subtitle2, color: theme.colors.text.primary },
  cardTitleActive: { color: theme.colors.primary },
  cardDescription: { ...theme.typography.body2, color: theme.colors.text.secondary },
  cardDescriptionActive: { color: theme.colors.text.primary },
  timeRow: { flexDirection: 'row', gap: 8, marginBottom: 8 },
  timeOption: { flex: 1, paddingVertical: 12, borderRadius: 8, borderWidth: 1, borderColor: theme.colors.border, alignItems: 'center', justifyContent: 'center', backgroundColor: theme.colors.surface },
  timeOptionActive: { borderColor: theme.colors.primary, backgroundColor: `${theme.colors.primary}10`, borderWidth: 2 },
  timeOptionText: { ...theme.typography.body2, color: theme.colors.text.primary, fontWeight: '500' },
  timeOptionTextActive: { color: theme.colors.primary },
  timeOptionLabel: { ...theme.typography.caption, color: theme.colors.text.secondary, marginTop: 2 },
  timeOptionLabelActive: { color: theme.colors.primary },
  soundRow: { flexDirection: 'row', gap: 8 },
  soundOption: { flex: 1, paddingVertical: 12, borderRadius: 8, borderWidth: 1, borderColor: theme.colors.border, alignItems: 'center', justifyContent: 'center', backgroundColor: theme.colors.surface, flexDirection: 'row', gap: 8 },
  soundOptionActive: { borderColor: theme.colors.primary, backgroundColor: `${theme.colors.primary}10`, borderWidth: 2 },
  soundOptionText: { ...theme.typography.body2, color: theme.colors.text.primary, fontWeight: '600' },
  soundOptionTextActive: { color: theme.colors.primary },
  footer: { padding: 16, borderTopWidth: 1, borderTopColor: theme.colors.border },
  primaryBtn: { backgroundColor: theme.colors.primary, borderRadius: 8, padding: 16, alignItems: 'center' },
  primaryBtnDisabled: { opacity: 0.5 },
  primaryBtnText: { ...theme.typography.button, color: theme.colors.text.inverse },
  inputGroup: { gap: 8 },
  label: { ...theme.typography.body2, color: theme.colors.text.secondary },
  input: { borderWidth: 1, borderColor: theme.colors.border, borderRadius: 8, padding: 12, color: theme.colors.text.primary, ...theme.typography.body1 },
  quickRow: { flexDirection: 'row', gap: 8, marginTop: 12 },
  quickPill: { borderRadius: 16, paddingVertical: 6, paddingHorizontal: 12, backgroundColor: theme.colors.surfaceVariant },
  quickPillText: { ...theme.typography.caption, color: theme.colors.text.primary },
  inlineOption: { flex: 1, padding: 12, borderRadius: 8, borderWidth: 1, borderColor: theme.colors.border, backgroundColor: theme.colors.surface },
  inlineOptionActive: { borderColor: theme.colors.primary, backgroundColor: `${theme.colors.primary}10`, borderWidth: 2 },
  inlineOptionTitle: { ...theme.typography.body2, color: theme.colors.text.primary, fontWeight: '600' },
  inlineOptionTitleActive: { color: theme.colors.primary },
  inlineOptionDescription: { ...theme.typography.caption, color: theme.colors.text.secondary, marginTop: 2 },
  inlineOptionDescriptionActive: { color: theme.colors.text.primary },
  summaryCard: { backgroundColor: theme.colors.surface, borderRadius: 12, padding: 16, borderWidth: 1, borderColor: theme.colors.border, gap: 12 },
  summaryRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  summaryLabel: { ...theme.typography.body2, color: theme.colors.text.secondary },
  summaryValue: { ...theme.typography.body1, color: theme.colors.text.primary, fontWeight: '600' },
});

export default MeditationSetupModal;
