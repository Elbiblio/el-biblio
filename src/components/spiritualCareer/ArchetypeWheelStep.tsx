import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
} from 'react-native';
import { ChevronRight } from '@/components/Icons';
import { useTheme } from '@/contexts/ThemeContext';
import { ARCHETYPES } from '@/constants/spiritualCareer';
import type { CareerGuideState } from '@/screens/SpiritualCareerGuideScreen';
import * as Haptics from 'expo-haptics';

type Props = {
  state: CareerGuideState;
  onBack: () => void;
  onNext: () => void;
  onToggleArchetype: (index: number) => void;
  onGoToDistortions: () => void;
};

const { width: SCREEN_WIDTH } = Dimensions.get('window');
const WHEEL_SIZE = Math.min(SCREEN_WIDTH * 0.8, 320);
const CENTER_SIZE = 80;
const MAX_SELECTED_ARCHETYPES = 3;

const ArchetypeWheelStep: React.FC<Props> = ({
  state,
  onBack,
  onNext,
  onToggleArchetype,
  onGoToDistortions,
}) => {
  const theme = useTheme();
  const styles = createStyles(theme);
  const segmentAngle = 360 / ARCHETYPES.length;

  return (
    <View style={styles.contentContainer}>
      <Text style={styles.sectionTitle}>Select Your Spiritual Archetypes</Text>
      <Text style={styles.sectionSubtitle}>Choose up to 3 that resonate with you</Text>

      <TouchableOpacity
        style={styles.helperLink}
        onPress={onGoToDistortions}
      >
        <Text style={styles.helperLinkText}>
          Need help deciding? Use the distortion selector to get recommendations.
        </Text>
      </TouchableOpacity>
        
      <View style={styles.wheelContainer}>
        <View style={[styles.wheel, { width: WHEEL_SIZE, height: WHEEL_SIZE }]}>
          {ARCHETYPES.map((archetype, index) => {
            const startAngle = index * segmentAngle;
            const endAngle = (index + 1) * segmentAngle;
            const isSelected = state.selectedArchetypes.includes(archetype.name);
            
            return (
              <TouchableOpacity
                key={archetype.name}
                style={[
                  styles.archetypeSegment,
                  {
                    transform: [
                      { rotate: `${startAngle}deg` },
                      { translateX: WHEEL_SIZE / 4 },
                    ],
                    backgroundColor: isSelected ? archetype.color : `${archetype.color}33`,
                    borderColor: isSelected ? archetype.color : `${archetype.color}66`,
                  },
                ]}
                onPress={() => onToggleArchetype(index)}
              >
                <Text style={[
                  styles.archetypeLabel,
                  { 
                    transform: [{ rotate: `${-startAngle - segmentAngle / 2}deg` }],
                    color: isSelected ? '#fff' : archetype.color,
                  }
                ]}>
                  {archetype.name}
                </Text>
              </TouchableOpacity>
            );
          })}
          
          <View style={styles.wheelCenter}>
            <Text style={styles.centerText}>
              {state.selectedArchetypes.length}/{MAX_SELECTED_ARCHETYPES}
            </Text>
            <Text style={styles.centerSubtext}>Selected</Text>
          </View>
        </View>
      </View>

      <View style={styles.selectedArchetypes}>
        {state.selectedArchetypes.map((name: string) => {
          const archetype = ARCHETYPES.find(a => a.name === name);
          return (
            <View key={name} style={[styles.archetypeTag, { backgroundColor: archetype?.color }]}>
              <Text style={styles.archetypeTagText}>{name}</Text>
            </View>
          );
        })}
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
            { flex: 2, opacity: state.selectedArchetypes.length === 0 ? 0.5 : 1 }
          ]}
          onPress={() => state.selectedArchetypes.length > 0 && onNext()}
          disabled={state.selectedArchetypes.length === 0}
        >
          <Text style={styles.primaryButtonText}>Continue</Text>
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
  helperLink: {
    marginBottom: 16,
    alignItems: 'flex-start',
  },
  helperLinkText: {
    color: theme.colors.primary,
    fontSize: 14,
    textDecorationLine: 'underline',
  },
  wheelContainer: {
    alignItems: 'center',
    marginVertical: 32,
  },
  wheel: {
    position: 'relative',
    borderRadius: WHEEL_SIZE / 2,
    borderWidth: 2,
    borderColor: theme.colors.primary,
  },
  archetypeSegment: {
    position: 'absolute',
    width: WHEEL_SIZE / 2,
    height: WHEEL_SIZE / 2,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: WHEEL_SIZE / 4,
    borderWidth: 2,
    transformOrigin: 'top left',
  },
  archetypeLabel: {
    fontSize: 12,
    fontWeight: '600',
    textAlign: 'center',
    position: 'absolute',
    top: '50%',
    left: '50%',
    marginLeft: -20,
    marginTop: -10,
    width: 40,
  },
  wheelCenter: {
    position: 'absolute',
    top: WHEEL_SIZE / 2 - CENTER_SIZE / 2,
    left: WHEEL_SIZE / 2 - CENTER_SIZE / 2,
    width: CENTER_SIZE,
    height: CENTER_SIZE,
    backgroundColor: theme.colors.background,
    borderRadius: CENTER_SIZE / 2,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: theme.colors.primary,
  },
  centerText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: theme.colors.text,
  },
  centerSubtext: {
    fontSize: 12,
    color: theme.colors.textSecondary,
  },
  selectedArchetypes: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 8,
    marginBottom: 24,
  },
  archetypeTag: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  archetypeTagText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
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

export default ArchetypeWheelStep;
