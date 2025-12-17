import React, { useMemo } from 'react';
import { View, Text, TouchableOpacity, Modal } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import { ReadingPlanPhase } from '@/constants/readingPlanModes';
import ReadingTimer from '@/components/ReadingTimer';
import { useBibleStore } from '@/stores/BibleStore';
import { createBibleStyles } from './styles';
import { formatSegmentLabel } from './utils';

interface TimerModalProps {
  visible: boolean;
  timerId: string | null;
  phases: ReadingPlanPhase[];
  onClose: () => void;
  onPhaseComplete: (phase: ReadingPlanPhase, elapsed: number) => void;
  onAllPhasesComplete: () => void;
}

export const TimerModal = observer(({
  visible,
  timerId,
  phases,
  onClose,
  onPhaseComplete,
  onAllPhasesComplete,
}: TimerModalProps) => {
  const theme = useTheme();
  const styles = useMemo(() => createBibleStyles(theme), [theme]);
  const bibleStore = useBibleStore();

  if (!timerId) return null;

  const segment = bibleStore.activeReadingSegment;
  const passages = segment ? [formatSegmentLabel(segment)] : undefined;

  return (
    <Modal
      visible={visible && !bibleStore.dailySession?.completed}
      animationType="slide"
      transparent
    >
      <View style={styles.timerModalBackdrop}>
        <View style={styles.timerModalCard}>
          <View style={styles.timerModalHeader}>
            <Text style={styles.timerModalTitle}>Today's Focus</Text>
            <TouchableOpacity onPress={onClose}>
              <MaterialIcons name="close" size={22} color={theme.colors.text.secondary} />
            </TouchableOpacity>
          </View>

          <ReadingTimer
            timerId={timerId}
            phases={phases}
            onPhaseComplete={onPhaseComplete}
            onAllPhasesComplete={onAllPhasesComplete}
            onStart={onClose}
            passages={passages}
          />
        </View>
      </View>
    </Modal>
  );
});
