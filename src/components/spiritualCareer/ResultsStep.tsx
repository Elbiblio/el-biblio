import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Modal,
} from 'react-native';
import { Brain, ChevronRight, Heart, Sparkle, X } from '@/components/Icons';
import { useTheme } from '@/contexts/ThemeContext';
import { ARCHETYPES } from '@/constants/spiritualCareer';
import type { CareerGuideState } from '@/screens/SpiritualCareerGuideScreen';
import * as Haptics from 'expo-haptics';

type Props = {
  state: CareerGuideState;
  onBack: () => void;
  onViewChallenges: () => void;
};

type PrayerStep = 'gratitude' | 'reflection' | 'commitment' | 'complete';

const ResultsStep: React.FC<Props> = ({ state, onBack, onViewChallenges }) => {
  const theme = useTheme();
  const styles = createStyles(theme);
  const [showPrayerModal, setShowPrayerModal] = useState(false);
  const [currentPrayerStep, setCurrentPrayerStep] = useState<PrayerStep>('gratitude');
  const [meditationTimer, setMeditationTimer] = useState(0);
  const [isMeditating, setIsMeditating] = useState(false);

  const handleStartPrayer = () => {
    setShowPrayerModal(true);
    setCurrentPrayerStep('gratitude');
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  };

  const handleNextPrayerStep = () => {
    const steps: PrayerStep[] = ['gratitude', 'reflection', 'commitment', 'complete'];
    const currentIndex = steps.indexOf(currentPrayerStep);
    if (currentIndex < steps.length - 1) {
      setCurrentPrayerStep(steps[currentIndex + 1]);
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
  };

  const handleStartMeditation = () => {
    setIsMeditating(true);
    setMeditationTimer(0);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    
    const interval = setInterval(() => {
      setMeditationTimer(prev => {
        if (prev >= 30) {
          setIsMeditating(false);
          clearInterval(interval);
          return 30;
        }
        return prev + 1;
      });
    }, 1000);
  };

  const handleCompletePrayer = () => {
    setShowPrayerModal(false);
    setCurrentPrayerStep('gratitude');
    setMeditationTimer(0);
    setIsMeditating(false);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  const renderPrayerModal = () => {
    if (!showPrayerModal) return null;

    return (
      <Modal
        visible={showPrayerModal}
        animationType="fade"
        presentationStyle="fullScreen"
      >
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <TouchableOpacity onPress={handleCompletePrayer}>
              <X size={24} color={theme.colors.text.primary} />
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.modalContent} showsVerticalScrollIndicator={false}>
            {currentPrayerStep === 'gratitude' && (
              <View style={styles.prayerStep}>
                <Heart size={48} color={theme.colors.primary} style={styles.prayerIcon} />
                <Text style={styles.prayerTitle}>Give Thanks</Text>
                <Text style={styles.prayerSubtitle}>
                  Take a moment to thank God for revealing your spiritual gifts and calling
                </Text>
                <View style={styles.prayerCard}>
                  <Text style={styles.prayerText}>
                    "Thank you Lord for the unique way you've created me. Thank you for the archetypes of {state.selectedArchetypes.join(', ')} that you've placed in my heart. Thank you for the opportunity to serve as a {state.selectedRoleType} in {state.selectedIndustry}."
                  </Text>
                </View>
                <TouchableOpacity style={styles.prayerButton} onPress={handleNextPrayerStep}>
                  <Text style={styles.prayerButtonText}>Continue in Prayer</Text>
                </TouchableOpacity>
              </View>
            )}

            {currentPrayerStep === 'reflection' && (
              <View style={styles.prayerStep}>
                <Brain size={48} color={theme.colors.primary} style={styles.prayerIcon} />
                <Text style={styles.prayerTitle}>Reflect & Meditate</Text>
                <Text style={styles.prayerSubtitle}>
                  Spend 30 seconds in silence, meditating on your next steps
                </Text>
                <View style={styles.meditationCard}>
                  <Text style={styles.meditationTimer}>
                    {isMeditating ? `${30 - meditationTimer}s` : '30s'}
                  </Text>
                  {!isMeditating ? (
                    <TouchableOpacity style={styles.meditationButton} onPress={handleStartMeditation}>
                      <Text style={styles.meditationButtonText}>Begin Meditation</Text>
                    </TouchableOpacity>
                  ) : (
                    <View style={styles.meditatingIndicator}>
                      <Text style={styles.meditatingText}>Meditating...</Text>
                    </View>
                  )}
                </View>
                {meditationTimer >= 30 && (
                  <TouchableOpacity style={styles.prayerButton} onPress={handleNextPrayerStep}>
                    <Text style={styles.prayerButtonText}>Continue Prayer</Text>
                  </TouchableOpacity>
                )}
              </View>
            )}

            {currentPrayerStep === 'commitment' && (
              <View style={styles.prayerStep}>
                <Sparkle size={48} color={theme.colors.primary} style={styles.prayerIcon} />
                <Text style={styles.prayerTitle}>Commit Your Path</Text>
                <Text style={styles.prayerSubtitle}>
                  Dedicate your career journey to God's glory
                </Text>
                <View style={styles.prayerCard}>
                  <Text style={styles.prayerText}>
                    "Lord, I commit my career path to you. Use my {state.selectedArchetypes.join(', ')} gifts to bring you glory in {state.selectedIndustry}. Guide my steps and help me honor you in all I do. Amen."
                  </Text>
                </View>
                <TouchableOpacity style={styles.prayerButton} onPress={handleNextPrayerStep}>
                  <Text style={styles.prayerButtonText}>Complete Prayer</Text>
                </TouchableOpacity>
              </View>
            )}

            {currentPrayerStep === 'complete' && (
              <View style={styles.prayerStep}>
                <Heart size={48} color={theme.colors.primary} style={styles.prayerIcon} />
                <Text style={styles.prayerTitle}>Prayer Complete</Text>
                <Text style={styles.prayerSubtitle}>
                  Your spiritual career journey is now blessed and committed
                </Text>
                <View style={styles.completionCard}>
                  <Text style={styles.completionText}>
                    "For I know the plans I have for you," declares the Lord, "plans to prosper you and not to harm you, plans to give you hope and a future." - Jeremiah 29:11
                  </Text>
                </View>
                <TouchableOpacity style={styles.prayerButton} onPress={handleCompletePrayer}>
                  <Text style={styles.prayerButtonText}>Begin Your Journey</Text>
                </TouchableOpacity>
              </View>
            )}
          </ScrollView>
        </View>
      </Modal>
    );
  };

  return (
    <View style={styles.contentContainer}>
      <View style={styles.headerSection}>
        <Brain size={48} color={theme.colors.primary} style={styles.headerIcon} />
        <Text style={styles.mainTitle}>Your Spiritual Career Profile</Text>
        <Text style={styles.subtitle}>
          You've completed the guide! Here's your personalized spiritual career profile
        </Text>
      </View>

      <View style={styles.profileSection}>
        <Text style={styles.profileSectionTitle}>Your Archetypes</Text>
        <View style={styles.selectedArchetypes}>
          {state.selectedArchetypes.map(name => {
            const archetype = ARCHETYPES.find(a => a.name === name);
            return (
              <View key={name} style={[styles.archetypeTag, { backgroundColor: archetype?.color }]}>
                <Text style={styles.archetypeTagText}>{name}</Text>
              </View>
            );
          })}
        </View>
      </View>

      <View style={styles.profileSection}>
        <Text style={styles.profileSectionTitle}>Work Context</Text>
        <Text style={styles.profileText}>{state.selectedRoleType} in {state.selectedIndustry}</Text>
      </View>

      <View style={styles.profileSection}>
        <Text style={styles.profileSectionTitle}>Recommended Challenges</Text>
        <Text style={styles.profileText}>{state.suggestedChallenges.length} personalized challenges ready for you</Text>
      </View>

      <TouchableOpacity 
        style={styles.prayerPromptButton}
        onPress={handleStartPrayer}
      >
        <Heart size={20} color="#fff" style={styles.prayerPromptIcon} />
        <Text style={styles.prayerPromptText}>Pray & Dedicate Your Path</Text>
        <ChevronRight size={20} color="#fff" />
      </TouchableOpacity>

      <TouchableOpacity 
        style={styles.primaryButton}
        onPress={onViewChallenges}
      >
        <Text style={styles.primaryButtonText}>View Your Challenges</Text>
        <ChevronRight size={20} color="#fff" />
      </TouchableOpacity>

      <TouchableOpacity 
        style={styles.secondaryButton}
        onPress={onBack}
      >
        <Text style={styles.secondaryButtonText}>Back to Home</Text>
      </TouchableOpacity>

      {renderPrayerModal()}
    </View>
  );
};

const createStyles = (theme: any) => StyleSheet.create({
  contentContainer: {
    flex: 1,
    padding: 20,
  },
  headerSection: {
    alignItems: 'center',
    marginBottom: 32,
  },
  headerIcon: {
    marginBottom: 16,
  },
  mainTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: theme.colors.text,
    textAlign: 'center',
    marginBottom: 12,
  },
  subtitle: {
    fontSize: 16,
    color: theme.colors.textSecondary,
    textAlign: 'center',
    lineHeight: 24,
  },
  profileSection: {
    marginBottom: 24,
  },
  profileSectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: theme.colors.text,
    marginBottom: 12,
  },
  profileText: {
    fontSize: 16,
    color: theme.colors.textSecondary,
    lineHeight: 22,
  },
  selectedArchetypes: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 8,
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
  prayerPromptButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.primary,
    padding: 16,
    borderRadius: 12,
    marginBottom: 16,
    shadowColor: theme.colors.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  prayerPromptIcon: {
    marginRight: 8,
  },
  prayerPromptText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    flex: 1,
    textAlign: 'center',
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
  },
  secondaryButtonText: {
    color: theme.colors.primary,
    fontSize: 16,
    fontWeight: '600',
  },
  // Modal styles
  modalContainer: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    padding: 20,
    paddingTop: 60,
  },
  modalContent: {
    flex: 1,
    padding: 20,
  },
  prayerStep: {
    alignItems: 'center',
    paddingTop: 40,
  },
  prayerIcon: {
    marginBottom: 24,
  },
  prayerTitle: {
    fontSize: 32,
    fontWeight: 'bold',
    color: theme.colors.text,
    textAlign: 'center',
    marginBottom: 12,
  },
  prayerSubtitle: {
    fontSize: 18,
    color: theme.colors.textSecondary,
    textAlign: 'center',
    lineHeight: 26,
    marginBottom: 32,
    paddingHorizontal: 20,
  },
  prayerCard: {
    backgroundColor: `${theme.colors.primary}10`,
    padding: 24,
    borderRadius: 16,
    marginBottom: 32,
  },
  prayerText: {
    fontSize: 16,
    color: theme.colors.text,
    lineHeight: 24,
    textAlign: 'center',
    fontStyle: 'italic',
  },
  prayerButton: {
    backgroundColor: theme.colors.primary,
    padding: 16,
    borderRadius: 12,
    minWidth: 200,
  },
  prayerButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
  meditationCard: {
    backgroundColor: `${theme.colors.primary}10`,
    padding: 32,
    borderRadius: 16,
    alignItems: 'center',
    marginBottom: 32,
  },
  meditationTimer: {
    fontSize: 48,
    fontWeight: 'bold',
    color: theme.colors.primary,
    marginBottom: 24,
  },
  meditationButton: {
    backgroundColor: theme.colors.primary,
    padding: 16,
    borderRadius: 12,
    minWidth: 200,
  },
  meditationButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
  meditatingIndicator: {
    alignItems: 'center',
  },
  meditatingText: {
    fontSize: 16,
    color: theme.colors.textSecondary,
    fontStyle: 'italic',
  },
  completionCard: {
    backgroundColor: `${theme.colors.primary}10`,
    padding: 24,
    borderRadius: 16,
    marginBottom: 32,
  },
  completionText: {
    fontSize: 16,
    color: theme.colors.text,
    lineHeight: 24,
    textAlign: 'center',
    fontStyle: 'italic',
  },
});

export default ResultsStep;
