import React, { useMemo, useState } from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { observer } from 'mobx-react-lite';
import { MaterialIcons } from '@expo/vector-icons';
import { AUDIO_KEYS, playByKey, stopByKey } from '@/services/audio';

export interface ChantLibraryModalProps {
  visible: boolean;
  selectedId?: string;
  onClose: () => void;
  onSelect: (id: string) => void;
}

const CHANTS: Array<{
  id: string;
  title: string;
  subtitle?: string;
  voiceKey?: string; // SoundKey from audio service, if available
  instrumentalKey?: string; // SoundKey from audio service, if available
}> = [
  {
    id: '10000-reasons',
    title: '10,000 Reasons',
    subtitle: 'Bless the Lord',
    voiceKey: 'db/10000_reasons.mp3',
    instrumentalKey: 'db/10000_reasons_instrumental.mp3',
  },
  {
    id: '10000-reasons-african',
    title: '10,000 Reasons (African)',
    subtitle: 'Alternate vocal',
    voiceKey: 'db/10000_reasons_african.mp3',
    instrumentalKey: 'db/10000_reasons_instrumental.mp3',
  },
  {
    id: 'be-still-my-soul',
    title: 'Be Still My Soul',
    voiceKey: 'db/be_still_my_soul.mp3',
    instrumentalKey: 'db/be_still_my_soul_instrumental.mp3',
  },
  {
    id: 'soul-of-jesus-sanctify-me',
    title: 'Soul of Jesus, Sanctify Me',
    voiceKey: 'db/anima_christi.mp3',
    instrumentalKey: 'db/anima_christi_instrumental.mp3',
  },
  {
    id: 'oceans',
    title: 'Oceans (Spirit Lead Me)',
    voiceKey: 'db/oceans_voice.mp3',
    instrumentalKey: 'db/oceans_instrumental.mp3',
  },
];

const ChantLibraryModal: React.FC<ChantLibraryModalProps> = observer(({ visible, selectedId, onClose, onSelect }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const [previewingKey, setPreviewingKey] = useState<string | null>(null);

  const handlePreview = async (key?: string) => {
    if (!key) return;
    if (!AUDIO_KEYS.includes(key as any)) return;
    try {
      if (previewingKey && previewingKey !== key) {
        await stopByKey(previewingKey as any);
      }
      setPreviewingKey(key);
      await playByKey(key as any);
    } catch {}
  };

  const stopPreview = async () => {
    if (!previewingKey) return;
    try {
      await stopByKey(previewingKey as any);
    } catch {}
    setPreviewingKey(null);
  };

  if (!visible) return null;

  const handleClose = () => { stopPreview(); onClose(); };

  return (
    <Modal visible={visible} animationType="slide" transparent onRequestClose={handleClose}>
      <View style={styles.overlay}>
        <View style={styles.container}>
          <View style={styles.header}>
            <Text style={styles.title}>Chant Library</Text>
            <TouchableOpacity onPress={handleClose} style={styles.closeButton}>
              <MaterialIcons name="close" size={22} color={theme.colors.text.primary} />
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.content}>
            {CHANTS.map((c) => {
              const isSelected = c.id === selectedId;
              const canPreview = !!c.voiceKey && AUDIO_KEYS.includes(c.voiceKey as any);
              return (
                <View key={c.id} style={[styles.card, isSelected && styles.cardActive]}>
                  <View style={styles.cardHeader}>
                    <Text style={[styles.cardTitle, isSelected && styles.cardTitleActive]}>{c.title}</Text>
                    {c.subtitle ? (
                      <Text style={[styles.cardSubtitle, isSelected && styles.cardSubtitleActive]}>{c.subtitle}</Text>
                    ) : null}
                  </View>
                  <View style={styles.row}>
                    <TouchableOpacity
                      style={[styles.btn, !canPreview && styles.btnDisabled]}
                      disabled={!canPreview}
                      onPress={() => handlePreview(c.voiceKey)}
                    >
                      <MaterialIcons name="play-arrow" size={18} color={canPreview ? theme.colors.primary : theme.colors.text.secondary} />
                      <Text style={[styles.btnText, canPreview ? styles.btnTextPrimary : undefined]}>Preview Voice</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                      style={styles.btn}
                      onPress={() => onSelect(c.id)}
                    >
                      <MaterialIcons name="library-add" size={18} color={theme.colors.primary} />
                      <Text style={[styles.btnText, styles.btnTextPrimary]}>Select</Text>
                    </TouchableOpacity>
                  </View>
                </View>
              );
            })}
          </ScrollView>

          {previewingKey && (
            <TouchableOpacity style={styles.stopPreview} onPress={stopPreview}>
              <MaterialIcons name="stop" size={18} color={theme.colors.text.inverse} />
              <Text style={styles.stopPreviewText}>Stop Preview</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>
    </Modal>
  );
});

const createStyles = (theme: any) => StyleSheet.create({
  overlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', padding: 20 },
  container: { backgroundColor: theme.colors.background, borderRadius: 12, maxHeight: '88%' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 16, borderBottomWidth: 1, borderBottomColor: theme.colors.border },
  title: { ...theme.typography.h6, color: theme.colors.text.primary },
  closeButton: { padding: 4 },
  content: { padding: 16 },
  card: { borderWidth: 1, borderColor: theme.colors.border, borderRadius: 12, padding: 16, backgroundColor: theme.colors.surface, marginBottom: 12 },
  cardActive: { borderColor: theme.colors.primary, backgroundColor: `${theme.colors.primary}10`, borderWidth: 2 },
  cardHeader: { marginBottom: 8 },
  cardTitle: { ...theme.typography.subtitle2, color: theme.colors.text.primary },
  cardTitleActive: { color: theme.colors.primary },
  cardSubtitle: { ...theme.typography.caption, color: theme.colors.text.secondary, marginTop: 2 },
  cardSubtitleActive: { color: theme.colors.primary },
  row: { flexDirection: 'row', gap: 8 },
  btn: { flex: 1, paddingVertical: 10, borderRadius: 8, borderWidth: 1, borderColor: theme.colors.border, alignItems: 'center', backgroundColor: theme.colors.surface, flexDirection: 'row', justifyContent: 'center', gap: 6 },
  btnDisabled: { opacity: 0.5 },
  btnText: { ...theme.typography.body2, color: theme.colors.text.secondary, fontWeight: '600' },
  btnTextPrimary: { color: theme.colors.primary },
  stopPreview: { margin: 16, backgroundColor: theme.colors.primary, borderRadius: 8, paddingVertical: 12, alignItems: 'center', flexDirection: 'row', justifyContent: 'center', gap: 8 },
  stopPreviewText: { ...theme.typography.button, color: theme.colors.text.inverse },
});

export default ChantLibraryModal;
