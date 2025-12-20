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
import { INDUSTRIES, ROLE_TYPES } from '@/constants/spiritualCareer';
import type { CareerGuideState } from '@/screens/SpiritualCareerGuideScreen';

type Props = {
  state: CareerGuideState;
  onBack: () => void;
  onNext: () => void;
  onSelectIndustry: (industry: string) => void;
  onSelectRoleType: (roleType: string) => void;
};

const ContextSelectionStep: React.FC<Props> = ({
  state,
  onBack,
  onNext,
  onSelectIndustry,
  onSelectRoleType,
}) => {
  const theme = useTheme();
  const styles = createStyles(theme);

  return (
    <View style={styles.contentContainer}>
      <Text style={styles.sectionTitle}>Your Work Context</Text>
      <Text style={styles.sectionSubtitle}>Help us personalize your journey</Text>

      <View style={styles.selectionSection}>
        <Text style={styles.selectionLabel}>Industry</Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.horizontalScroll}>
          {INDUSTRIES.map(industry => (
            <TouchableOpacity
              key={industry}
              style={[
                styles.selectionChip,
                state.selectedIndustry === industry && styles.selectionChipSelected,
              ]}
              onPress={() => onSelectIndustry(industry)}
            >
              <Text
                style={[
                  styles.selectionChipText,
                  state.selectedIndustry === industry && styles.selectionChipTextSelected,
                ]}
              >
                {industry}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>

      <View style={styles.selectionSection}>
        <Text style={styles.selectionLabel}>Role Type</Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.horizontalScroll}>
          {ROLE_TYPES.map(roleType => (
            <TouchableOpacity
              key={roleType}
              style={[
                styles.selectionChip,
                state.selectedRoleType === roleType && styles.selectionChipSelected,
              ]}
              onPress={() => onSelectRoleType(roleType)}
            >
              <Text
                style={[
                  styles.selectionChipText,
                  state.selectedRoleType === roleType && styles.selectionChipTextSelected,
                ]}
              >
                {roleType}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>

      <View style={styles.buttonRow}>
        <TouchableOpacity 
          style={[styles.secondaryButton, { flex: 1 }]}
          onPress={onBack}
        >
          <Text style={styles.secondaryButtonText}>Back</Text>
        </TouchableOpacity>
        
        <TouchableOpacity 
          style={[
            styles.primaryButton, 
            { flex: 2, opacity: !state.selectedIndustry || !state.selectedRoleType ? 0.5 : 1 }
          ]}
          onPress={() => {
            if (state.selectedIndustry && state.selectedRoleType) {
              onNext();
            }
          }}
          disabled={!state.selectedIndustry || !state.selectedRoleType}
        >
          <Text style={styles.primaryButtonText}>Get Recommendations</Text>
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
  },
  selectionSection: {
    marginBottom: 32,
  },
  selectionLabel: {
    fontSize: 18,
    fontWeight: '600',
    color: theme.colors.text,
    marginBottom: 16,
  },
  horizontalScroll: {
    flexGrow: 0,
  },
  selectionChip: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}40`,
    marginRight: 12,
    backgroundColor: theme.colors.surface,
  },
  selectionChipSelected: {
    backgroundColor: theme.colors.primary,
    borderColor: theme.colors.primary,
  },
  selectionChipText: {
    fontSize: 14,
    fontWeight: '500',
    color: theme.colors.text,
  },
  selectionChipTextSelected: {
    color: '#fff',
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
    marginLeft: 8,
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
  },
  secondaryButtonText: {
    color: theme.colors.primary,
    fontSize: 16,
    fontWeight: '600',
  },
});

export default ContextSelectionStep;
