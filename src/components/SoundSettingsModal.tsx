import React, { useEffect, useState } from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet, Platform } from 'react-native';
import { BlurView } from 'expo-blur';
import SoundManager from '@/utils/SoundManager';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';

interface Props {
  visible: boolean;
  onClose: () => void;
}

const steps = [0, 0.25, 0.5, 0.75, 1];

const SoundSettingsModal: React.FC<Props> = ({ visible, onClose }) => {
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const [enabled, setEnabled] = useState(true);
  const [volume, setVolume] = useState(1);

  useEffect(() => {
    (async () => {
      await SoundManager.init();
      setEnabled(SoundManager.isEnabled());
      setVolume(SoundManager.getVolume());
    })();
  }, [visible]);

  const toggleEnabled = async () => {
    await SoundManager.toggleEnabled();
    setEnabled(SoundManager.isEnabled());
  };

  const setVol = async (v: number) => {
    await SoundManager.setVolume(v);
    setVolume(SoundManager.getVolume());
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={styles.container}>
        <BlurView intensity={30} style={StyleSheet.absoluteFill} pointerEvents="none" />
        <View style={styles.card}>
          <Text style={styles.title}>Sound Settings</Text>

          <View style={styles.row}>
            <Text style={styles.label}>Sound</Text>
            <TouchableOpacity style={[styles.toggle, enabled ? styles.toggleOn : styles.toggleOff]} onPress={toggleEnabled}>
              <View style={[styles.knob, enabled ? styles.knobOn : styles.knobOff]} />
            </TouchableOpacity>
          </View>

          <View style={styles.rowCol}>
            <Text style={styles.label}>Volume</Text>
            <View style={styles.volumeBar}>
              {steps.map((s, idx) => (
                <TouchableOpacity key={idx} style={[styles.volStep, s <= volume ? styles.volStepActive : undefined]} onPress={() => setVol(s)} />
              ))}
            </View>
            <View style={styles.actions}>
              <TouchableOpacity style={[styles.btn, styles.btnSecondary]} onPress={() => setVol(Math.max(0, volume - 0.25))}>
                <Text style={styles.btnSecondaryText}>-</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.btn, styles.btnPrimary]} onPress={() => setVol(Math.min(1, volume + 0.25))}>
                <Text style={styles.btnPrimaryText}>+</Text>
              </TouchableOpacity>
            </View>
          </View>

          <TouchableOpacity style={styles.closeBtn} onPress={onClose}>
            <Text style={styles.closeText}>Close</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: theme.spacing.lg },
  card: {
    width: '100%', maxWidth: 420, backgroundColor: theme.colors.surface, borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.xl, gap: theme.spacing.lg,
    ...Platform.select({
      ios: { shadowColor: '#000', shadowOpacity: 0.2, shadowRadius: 10, shadowOffset: { width: 0, height: 4 } },
      android: { elevation: 6 },
    })
  },
  title: { ...theme.typography.heading.medium, color: theme.colors.text.primary, textAlign: 'center' },
  row: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  rowCol: { gap: theme.spacing.sm },
  label: { ...theme.typography.body.sans, color: theme.colors.text.primary },
  toggle: { width: 60, height: 32, borderRadius: 16, padding: 4, justifyContent: 'center' },
  toggleOn: { backgroundColor: theme.colors.primary },
  toggleOff: { backgroundColor: theme.colors.input.background, borderWidth: 1, borderColor: theme.colors.input.border },
  knob: { width: 24, height: 24, borderRadius: 12, backgroundColor: theme.colors.text.inverse },
  knobOn: { alignSelf: 'flex-end' },
  knobOff: { alignSelf: 'flex-start' },
  volumeBar: { flexDirection: 'row', justifyContent: 'space-between', marginTop: theme.spacing.sm },
  volStep: { width: 50, height: 8, borderRadius: 4, backgroundColor: theme.colors.input.background, borderWidth: 1, borderColor: theme.colors.input.border },
  volStepActive: { backgroundColor: theme.colors.primary, borderColor: theme.colors.primary },
  actions: { flexDirection: 'row', gap: theme.spacing.md, justifyContent: 'center', marginTop: theme.spacing.sm },
  btn: { minWidth: 100, paddingVertical: theme.spacing.md, borderRadius: theme.borderRadius.full, alignItems: 'center' },
  btnPrimary: { backgroundColor: theme.colors.primary },
  btnSecondary: { backgroundColor: theme.colors.input.background, borderWidth: 1, borderColor: theme.colors.input.border },
  btnPrimaryText: { ...theme.typography.button.primary, color: theme.colors.text.inverse },
  btnSecondaryText: { ...theme.typography.button.secondary, color: theme.colors.text.primary },
  closeBtn: { marginTop: theme.spacing.sm, alignSelf: 'center' },
  closeText: { ...theme.typography.button.secondary, color: theme.colors.primary },
});

export default SoundSettingsModal;
