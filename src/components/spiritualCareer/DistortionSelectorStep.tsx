import React from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
} from 'react-native';
import { ChevronRight } from '@/components/Icons';
import { useTheme } from '@/contexts/ThemeContext';
import { DISTORTION_TAGS, ARCHETYPES } from '@/constants/spiritualCareer';
import type { CareerGuideState } from '@/screens/SpiritualCareerGuideScreen';
import type { DistortionTag } from '@/constants/spiritualCareer';

type Props = {
  state: CareerGuideState;
  onBack: () => void;
  onNext: () => void;
  onToggleDistortion: (tagId: string) => void;
  onApplyRecommended: () => void;
};

const DistortionSelectorStep: React.FC<Props> = ({
  state,
  onBack,
  onNext,
  onToggleDistortion,
  onApplyRecommended,
}) => {
  const theme = useTheme();
  const styles = createStyles(theme);

  const distortionMap = new Map<string, DistortionTag>();
  DISTORTION_TAGS.forEach(tag => distortionMap.set(tag.id, tag));

  const recommendedArchetypes = React.useMemo(() => {
    if (!state.selectedDistortions.length) return [];

    const scores = new Map<string, number>();
    state.selectedDistortions.forEach(tagId => {
      const tag = distortionMap.get(tagId);
      if (!tag) return;
      const weight = 1 / tag.archetypes.length;
      tag.archetypes.forEach(name => {
        scores.set(name, (scores.get(name) || 0) + weight);
      });
    });

    return ARCHETYPES
      .filter(archetype => scores.has(archetype.name))
      .sort((a, b) => (scores.get(b.name)! - scores.get(a.name)!))
      .slice(0, 3);
  }, [state.selectedDistortions, distortionMap]);

  return (
    <View style={styles.contentContainer}>
      <Text style={styles.sectionTitle}>What Feels Distorted?</Text>
      <Text style={styles.sectionSubtitle}>
        Tap struggles or tensions you've noticed lately. We'll suggest archetypes that redeem them.
      </Text>

      <ScrollView
        style={styles.distortionScroll}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.distortionCloud}
      >
        {DISTORTION_TAGS.map(tag => {
          const isSelected = state.selectedDistortions.includes(tag.id);
          return (
            <TouchableOpacity
              key={tag.id}
              style={[
                styles.distortionChip,
                isSelected && styles.distortionChipSelected,
              ]}
              onPress={() => onToggleDistortion(tag.id)}
            >
              <Text
                style={[
                  styles.distortionChipText,
                  isSelected && styles.distortionChipTextSelected,
                ]}
              >
                {tag.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </ScrollView>

      {recommendedArchetypes.length > 0 && (
        <View style={styles.recommendedSection}>
          <Text style={styles.recommendedTitle}>Recommended Archetypes</Text>
          <Text style={styles.recommendedSubtitle}>
            Based on the distortions you selected, these archetypes can bring restoration:
          </Text>

          <View style={styles.recommendedList}>
            {recommendedArchetypes.map(item => (
              <View key={item.name} style={styles.recommendedCard}>
                <Text style={styles.recommendedName}>{item.name}</Text>
                <Text style={styles.recommendedIdentity}>{item.identity}</Text>
                <Text style={styles.recommendedStrength}>
                  {item.strengths.split(';')[0]}
                </Text>
              </View>
            ))}
          </View>

          <TouchableOpacity
            style={styles.primaryButton}
            onPress={onApplyRecommended}
          >
            <Text style={styles.primaryButtonText}>Apply Suggested Archetypes</Text>
            <ChevronRight size={20} color="#fff" />
          </TouchableOpacity>
        </View>
      )}

      <View style={styles.buttonRow}>
        <TouchableOpacity
          style={[styles.secondaryButton, { flex: 1 }]}
          onPress={onBack}
        >
          <Text style={styles.secondaryButtonText}>Back</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.primaryButton, { flex: 2 }]}
          onPress={onNext}
        >
          <Text style={styles.primaryButtonText}>Go to Archetypes</Text>
          <ChevronRight size={20} color="#fff" />
        </TouchableOpacity>
      </View>
    </View>
  );
};

const createStyles = (theme: any) => StyleSheet.create({
  contentContainer: {
    flex: 1,
    padding: 20,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: theme.colors.text,
    textAlign: 'center',
    marginBottom: 8,
  },
  sectionSubtitle: {
    fontSize: 16,
    color: theme.colors.textSecondary,
    textAlign: 'center',
    marginBottom: 32,
    lineHeight: 24,
  },
  distortionScroll: {
    flexGrow: 0,
    marginBottom: 24,
  },
  distortionCloud: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  distortionChip: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}40`,
  },
  distortionChipSelected: {
    backgroundColor: theme.colors.primary,
    borderColor: theme.colors.primary,
  },
  distortionChipText: {
    color: theme.colors.text,
    fontSize: 13,
  },
  distortionChipTextSelected: {
    color: '#fff',
  },
  recommendedSection: {
    padding: 16,
    borderRadius: 16,
    backgroundColor: `${theme.colors.primary}10`,
    marginBottom: 24,
  },
  recommendedTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: theme.colors.text,
    marginBottom: 8,
  },
  recommendedSubtitle: {
    fontSize: 14,
    color: theme.colors.textSecondary,
    marginBottom: 16,
    lineHeight: 20,
  },
  recommendedList: {
    flexDirection: 'column',
    gap: 12,
    marginBottom: 16,
  },
  recommendedCard: {
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}30`,
    backgroundColor: theme.colors.surface,
  },
  recommendedName: {
    fontSize: 16,
    fontWeight: '600',
    color: theme.colors.text,
    marginBottom: 4,
  },
  recommendedIdentity: {
    fontSize: 13,
    color: theme.colors.textSecondary,
    marginBottom: 4,
  },
  recommendedStrength: {
    fontSize: 13,
    color: theme.colors.text,
  },
  buttonRow: {
    flexDirection: 'row',
    marginTop: 24,
  },
  primaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.primary,
    padding: 16,
    borderRadius: 12,
    marginBottom: 16,
  },
  primaryButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    marginRight: 8,
  },
  secondaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: theme.colors.primary,
    padding: 16,
    borderRadius: 12,
    marginRight: 8,
  },
  secondaryButtonText: {
    color: theme.colors.primary,
    fontSize: 16,
    fontWeight: '600',
  },
});

export default DistortionSelectorStep;
