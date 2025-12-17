import React, { useMemo } from 'react';
import { View, Text, TouchableOpacity, Modal, ScrollView, ActivityIndicator } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import { useBibleStore } from '@/stores/BibleStore';
import { createBibleStyles } from './styles';

interface AIInsightsModalProps {
  visible: boolean;
  onClose: () => void;
}

export const AIInsightsModal = observer(({ visible, onClose }: AIInsightsModalProps) => {
  const theme = useTheme();
  const styles = useMemo(() => createBibleStyles(theme), [theme]);
  const bibleStore = useBibleStore();

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <View style={styles.aiModalContainer}>
        <View style={styles.aiModalHeader}>
          <View style={{ flex: 1 }}>
            <Text style={styles.aiModalTitle}>AI Insights</Text>
            {bibleStore.aiInsightReference ? (
              <Text style={styles.aiModalReference}>{bibleStore.aiInsightReference}</Text>
            ) : null}
          </View>
          <TouchableOpacity onPress={onClose}>
            <MaterialIcons name="close" size={24} color={theme.colors.text.secondary} />
          </TouchableOpacity>
        </View>

        {bibleStore.isAIInsightLoading ? (
          <View style={styles.aiModalLoading}>
            <ActivityIndicator size="large" color={theme.colors.primary} />
            <Text style={styles.aiModalLoadingText}>Gathering historical context...</Text>
          </View>
        ) : bibleStore.aiInsightError ? (
          <View style={styles.aiModalError}>
            <MaterialIcons name="error-outline" size={20} color={theme.colors.error} />
            <Text style={styles.aiModalErrorText}>{bibleStore.aiInsightError}</Text>
          </View>
        ) : (
          <ScrollView contentContainerStyle={styles.aiModalContent}>
            {bibleStore.aiInsightSections.length ? (
              bibleStore.aiInsightSections.map(section => (
                <View key={`${section.title}-${section.content.slice(0, 20)}`} style={styles.aiSection}>
                  <Text style={styles.aiSectionTitle}>{section.title}</Text>
                  <Text style={styles.aiSectionBody}>{section.content}</Text>
                </View>
              ))
            ) : (
              <Text style={styles.aiModalPlaceholder}>No insights available for this verse yet.</Text>
            )}
          </ScrollView>
        )}
      </View>
    </Modal>
  );
});
