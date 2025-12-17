import React, { useMemo } from 'react';
import { View, Text, TouchableOpacity, Modal, ScrollView, SafeAreaView } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { useTheme } from '@/contexts/ThemeContext';
import { ScopedViewState } from './types';
import { createBibleStyles } from './styles';

interface ScopedViewModalProps {
  scopedView: ScopedViewState | null;
  onClose: () => void;
}

export const ScopedViewModal = ({ scopedView, onClose }: ScopedViewModalProps) => {
  const theme = useTheme();
  const styles = useMemo(() => createBibleStyles(theme), [theme]);

  if (!scopedView) return null;

  return (
    <Modal
      visible={!!scopedView}
      animationType="slide"
      presentationStyle="fullScreen"
      onRequestClose={onClose}
    >
      <SafeAreaView style={styles.scopedContainer}>
        <View style={styles.scopedHeader}>
          <View style={styles.scopedHeaderText}>
            {scopedView.title ? (
              <Text style={styles.scopedTitle}>{scopedView.title}</Text>
            ) : null}
            {scopedView.subtitle ? (
              <Text style={styles.scopedSubtitle}>{scopedView.subtitle}</Text>
            ) : null}
          </View>
          <TouchableOpacity style={styles.scopedDismissButton} onPress={onClose}>
            <MaterialIcons name="close" size={20} color={theme.colors.text.secondary} />
            <Text style={styles.scopedDismissText}>Dismiss</Text>
          </TouchableOpacity>
        </View>

        <ScrollView
          style={styles.scopedScroll}
          contentContainerStyle={styles.scopedScrollContent}
          showsVerticalScrollIndicator={false}
        >
          {scopedView.verses.map((verse, index) => (
            <View
              key={`${verse.text}-${index}`}
              style={[styles.scopedVerseCard, verse.isPrimary && styles.scopedVersePrimary]}
            >
              {verse.reference ? (
                <Text style={styles.scopedReference}>{verse.reference}</Text>
              ) : null}
              <Text style={styles.scopedVerseText}>{verse.text}</Text>
            </View>
          ))}
        </ScrollView>
      </SafeAreaView>
    </Modal>
  );
};
