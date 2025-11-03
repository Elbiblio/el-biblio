import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import Animated from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import { Check, Bell } from '@/components/Icons';
import SmartPickCard from '@/components/SmartPickCard';
import type { Challenge } from '@/types/challenges';
import type { Virtue } from '@/types';
import type { MeditationStyle } from '@/components/MeditationSetupModal';
import type { Theme } from '@/theme';

interface Props {
  theme: Theme;
  styles: any;
  selectedStyle: MeditationStyle;
  smartPickChallenge?: Challenge | null;
  smartPickDismissed: boolean;
  onDismissSmartPick: () => void;
  onJoinSmartPick: (challenge: Challenge) => void;
  onActivateChallenge: () => void;
  selectedChallenge?: Challenge | null;
  challengeExpanded: boolean;
  onToggleChallengeExpand: () => void;
  selectedTime: number | null;
  currentVirtue?: Virtue;
  bellButtonStyle: any;
  onFinish: () => void;
}

const MeditationCompleteView: React.FC<Props> = ({
  theme,
  styles,
  selectedStyle,
  smartPickChallenge,
  smartPickDismissed,
  onDismissSmartPick,
  onJoinSmartPick,
  onActivateChallenge,
  selectedChallenge,
  challengeExpanded,
  onToggleChallengeExpand,
  selectedTime,
  currentVirtue,
  bellButtonStyle,
  onFinish,
}) => {
  return (
    <View style={styles.completeContainer}>
      <View style={styles.completeBanner}>
        <Text style={styles.completeTitle}>Meditation Complete</Text>
        <View style={styles.checkmarkContainer}>
          <View style={styles.checkCircle}>
            <Check size={36} color="#FFFFFF" />
          </View>
        </View>
        <Text style={styles.completeSubtitle}>Take a moment to thank God for your experience.</Text>
      </View>

      {selectedStyle === 'virtue' && !smartPickDismissed && smartPickChallenge ? (
        <View style={styles.smartPickWrapper}>
          <SmartPickCard
            challenge={smartPickChallenge}
            onPressJoin={onJoinSmartPick}
            onPressDismiss={onDismissSmartPick}
            ctaLabel={smartPickChallenge.hasJoined ? 'View challenge' : 'Join challenge'}
          />
        </View>
      ) : null}

      {selectedStyle === 'virtue' && (
        <TouchableOpacity style={styles.bellButton} onPress={onActivateChallenge} activeOpacity={0.85}>
          <Animated.View style={[styles.bellIconContainer, bellButtonStyle]}>
            <Bell size={40} color={currentVirtue?.color_code || theme.colors.primary} />
          </Animated.View>
          <Text style={styles.bellText}>Activate Daily Challenge</Text>
        </TouchableOpacity>
      )}

      {selectedStyle === 'virtue' && selectedChallenge ? (
        <TouchableOpacity
          style={styles.challengeSummaryContainer}
          onPress={onToggleChallengeExpand}
          activeOpacity={0.85}
        >
          <View style={styles.challengeSummaryHeader}>
            <Text style={styles.challengeSummaryTitle}>Your Selected Challenge</Text>
            <Text style={styles.challengeToggleLabel}>
              {challengeExpanded ? 'Hide details ▴' : 'Tap for details ▾'}
            </Text>
          </View>
          <View style={styles.challengeSummaryCard}>
            <LinearGradient
              colors={[`${currentVirtue?.color_code}15`, `${currentVirtue?.color_code}05`]}
              style={StyleSheet.absoluteFillObject}
            />
            <Text style={styles.challengeSummaryText}>{selectedChallenge.title}</Text>
            <Text style={styles.challengeDuration}>
              For the next {selectedTime} {selectedTime === 1 ? 'hour' : 'hours'}
            </Text>

            {challengeExpanded ? (
              <View style={styles.expandedChallengeInfo}>
                <Text style={styles.expandedChallengeDescription}>
                  {selectedChallenge.description}
                </Text>
                {currentVirtue ? (
                  <View style={styles.virtueTagContainer}>
                    <View style={[styles.virtueTag, { backgroundColor: `${currentVirtue.color_code}20` }] }>
                      <Text style={[styles.virtueTagText, { color: currentVirtue.color_code }]}>
                        {currentVirtue.name}
                      </Text>
                    </View>
                  </View>
                ) : null}
              </View>
            ) : null}
          </View>
        </TouchableOpacity>
      ) : null}

      <TouchableOpacity style={styles.finishButton} onPress={onFinish} activeOpacity={0.85}>
        <Text style={styles.finishButtonText}>Finish</Text>
      </TouchableOpacity>
    </View>
  );
};

export default MeditationCompleteView;
