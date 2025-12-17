import React, { useMemo } from 'react';
import { View, Text, TouchableOpacity, Modal, Alert } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import { useBibleStore } from '@/stores/BibleStore';
import { toast } from 'sonner-native';
import { createBibleStyles } from './styles';

interface AdvancedActionsModalProps {
  visible: boolean;
  onClose: () => void;
  onPlanCleared: () => void;
  onAfterStartOver?: () => void;
}

export const AdvancedActionsModal = observer(({
  visible,
  onClose,
  onPlanCleared,
  onAfterStartOver,
}: AdvancedActionsModalProps) => {
  const theme = useTheme();
  const styles = useMemo(() => createBibleStyles(theme), [theme]);
  const bibleStore = useBibleStore();

  const handleStartOver = async () => {
    const confirm = await new Promise<boolean>(resolve => {
      Alert.alert(
        'Start over',
        'This will reset your plan progress and set today as the new start date. Continue?',
        [
          { text: 'Cancel', style: 'cancel', onPress: () => resolve(false) },
          { text: 'OK', style: 'destructive', onPress: () => resolve(true) },
        ],
        { cancelable: true }
      );
    });
    if (!confirm) return;
    onClose();
    const ok = await bibleStore.startOverPlan();
    if (ok) {
      await bibleStore.focusPlanSegment();
      await bibleStore.ensureDailySessionPrepared();
      toast.success('Plan started over from today');
      onAfterStartOver?.();
    } else {
      toast.error('Unable to start over');
    }
  };

  const handleClearPlan = async () => {
    const ok = await new Promise<boolean>(resolve => {
      Alert.alert(
        'Clear plan',
        'This will remove your current reading plan. Continue?',
        [
          { text: 'Cancel', style: 'cancel', onPress: () => resolve(false) },
          { text: 'OK', style: 'destructive', onPress: () => resolve(true) },
        ],
        { cancelable: true }
      );
    });
    if (!ok) return;
    onClose();
    await bibleStore.clearReadingPlan();
    toast.success('Reading plan cleared');
    onPlanCleared();
  };

  const handleResetStartDate = async () => {
    const confirm = await new Promise<boolean>(resolve => {
      Alert.alert(
        'Reset start date',
        'This will set your plan start date to today. Your completions remain unchanged. Continue?',
        [
          { text: 'Cancel', style: 'cancel', onPress: () => resolve(false) },
          { text: 'OK', onPress: () => resolve(true) },
        ],
        { cancelable: true }
      );
    });
    if (!confirm) return;
    onClose();
    const ok = await bibleStore.resetPlanStartDateToToday();
    if (ok) {
      await bibleStore.focusPlanSegment();
      await bibleStore.ensureDailySessionPrepared();
      toast.success('Plan start date set to today');
    } else {
      toast.error('Unable to reset start date');
    }
  };

  const handleRepairPlan = async () => {
    const confirm = await new Promise<boolean>(resolve => {
      Alert.alert(
        'Repair plan to today',
        'This will mark segments as completed up to today\'s expected pace. Continue?',
        [
          { text: 'Cancel', style: 'cancel', onPress: () => resolve(false) },
          { text: 'OK', onPress: () => resolve(true) },
        ],
        { cancelable: true }
      );
    });
    if (!confirm) return;
    onClose();
    const ok = await bibleStore.repairPlanToExpectedByToday();
    if (ok) {
      await bibleStore.focusPlanSegment();
      await bibleStore.ensureDailySessionPrepared();
      toast.success('Plan repaired to expected by today');
    } else {
      toast.error('Unable to repair plan');
    }
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={styles.modalBackdrop}>
        <View style={styles.modalCard}>
          <TouchableOpacity style={styles.dangerRow} onPress={handleStartOver}>
            <MaterialIcons name="restart-alt" size={18} color={theme.colors.error} />
            <Text style={styles.dangerText}>Start over</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.dangerRow} onPress={handleClearPlan}>
            <MaterialIcons name="delete-outline" size={18} color={theme.colors.error} />
            <Text style={styles.dangerText}>Clear plan</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.modalRow} onPress={handleResetStartDate}>
            <Text style={styles.modalText}>Reset start date to today</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.modalRow} onPress={handleRepairPlan}>
            <Text style={styles.modalText}>Repair plan to expected by today</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.modalRow} onPress={onClose}>
            <Text style={styles.modalText}>Cancel</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
});
