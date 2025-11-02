import React, { useCallback, useEffect, useMemo, useState, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Animated } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { ReadingPlanPhase } from '@/constants/readingPlanModes';
import * as Haptics from 'expo-haptics';

type MeditationVerseProps = {
  verses: Array<{ text: string; reference: string }>;
  phase: ReadingPlanPhase;
  isActive: boolean;
  remainingSeconds: number;
  onReturn: () => void;
  onCompletePhase: () => void;
};

const MeditationVerse: React.FC<MeditationVerseProps> = ({ verses, phase, isActive, remainingSeconds, onReturn, onCompletePhase }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  
  const [currentVerseIndex, setCurrentVerseIndex] = useState(0);
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const currentVerse = verses[currentVerseIndex] || null;

  const showNextVerse = useCallback(() => {
    fadeAnim.setValue(0);
    setCurrentVerseIndex(prev => (prev + 1) % verses.length);
    
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 1000,
      useNativeDriver: true,
    }).start();
  }, [verses.length, fadeAnim]);

  useEffect(() => {
    if (!isActive || verses.length === 0) {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
      return;
    }

    // Initial animation
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 1000,
      useNativeDriver: true,
    }).start();

    // Change verses every 5-10 seconds randomly
    const changeInterval = Math.random() * 5000 + 5000; // 5-10 seconds
    
    intervalRef.current = setInterval(() => {
      showNextVerse();
    }, changeInterval);

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    };
  }, [isActive, verses.length, showNextVerse, fadeAnim]);

  const getPhasePrompt = useCallback(() => {
    switch (phase.id) {
      case 'meditation':
        return 'Meditate on the word...';
      case 'prayer':
        return 'Pray through the word...';
      case 'contemplation':
        return 'Contemplate the meaning...';
      default:
        return 'Reflect on this word...';
    }
  }, [phase.id]);

  const formatTime = useCallback((s: number) => {
    const mins = Math.floor(s / 60);
    const secs = Math.max(0, s % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }, []);

  if (!currentVerse) {
    return null;
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.phaseLabel}>{phase.label}</Text>
        <View style={styles.headerRight}>
          <View style={styles.timerPill}>
            <Text style={styles.timerPillText}>{formatTime(Math.max(0, remainingSeconds))}</Text>
          </View>
          <TouchableOpacity 
            style={styles.returnButton} 
            onPress={() => {
              try { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); } catch {};
              onReturn();
            }}
          >
            <Text style={styles.returnButtonText}>Back to Plan</Text>
          </TouchableOpacity>
        </View>
      </View>

      <View style={styles.content}>
        <Animated.View style={[styles.verseContainer, { opacity: fadeAnim }]}>
          <Text style={styles.promptText}>{getPhasePrompt()}</Text>
          <Text style={styles.verseText}>{currentVerse.text}</Text>
          <Text style={styles.referenceText}>{currentVerse.reference}</Text>
        </Animated.View>
      </View>

      <View style={styles.footer}>
        <View style={styles.footerRow}>
          <TouchableOpacity 
            style={styles.secondaryButton} 
            onPress={() => {
              try { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); } catch {};
              showNextVerse();
            }}
          >
            <Text style={styles.secondaryButtonText}>Next Verse</Text>
          </TouchableOpacity>
          <TouchableOpacity 
            style={styles.primaryButton} 
            onPress={() => {
              try { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); } catch {};
              onCompletePhase();
            }}
          >
            <Text style={styles.primaryButtonText}>Complete</Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
};

const createStyles = (theme: ReturnType<typeof useTheme>) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.colors.background,
    },
    header: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      padding: theme.spacing.lg,
      paddingTop: theme.spacing.xl,
    },
    headerRight: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: theme.spacing.sm,
    },
    phaseLabel: {
      ...theme.typography.heading.small,
      color: theme.colors.text.primary,
      fontWeight: '600',
    },
    timerPill: {
      paddingHorizontal: theme.spacing.sm,
      paddingVertical: 6,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.text.secondary}15`,
    },
    timerPillText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
      fontVariant: ['tabular-nums'],
      fontWeight: '600',
    },
    returnButton: {
      paddingHorizontal: theme.spacing.md,
      paddingVertical: theme.spacing.sm,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.primary}15`,
    },
    returnButtonText: {
      ...theme.typography.caption.primary,
      color: theme.colors.primary,
      fontWeight: '600',
    },
    content: {
      flex: 1,
      justifyContent: 'center',
      paddingHorizontal: theme.spacing.xl,
    },
    verseContainer: {
      alignItems: 'center',
      gap: theme.spacing.lg,
    },
    promptText: {
      ...theme.typography.body.sans,
      color: theme.colors.text.secondary,
      fontStyle: 'italic',
      textAlign: 'center',
      fontSize: 16,
    },
    verseText: {
      ...theme.typography.heading.medium,
      color: theme.colors.text.primary,
      textAlign: 'center',
      lineHeight: 32,
      fontSize: 20,
    },
    referenceText: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.tertiary,
      textAlign: 'center',
      marginTop: theme.spacing.sm,
    },
    footer: {
      padding: theme.spacing.lg,
      paddingBottom: theme.spacing.xl,
    },
    footerRow: {
      flexDirection: 'row',
      gap: theme.spacing.sm,
      justifyContent: 'space-between',
    },
    secondaryButton: {
      flex: 1,
      paddingHorizontal: theme.spacing.md,
      paddingVertical: theme.spacing.md,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.primary}12`,
      alignItems: 'center',
    },
    secondaryButtonText: {
      ...theme.typography.button.primary,
      color: theme.colors.primary,
      fontWeight: '600',
    },
    primaryButton: {
      flex: 1,
      paddingHorizontal: theme.spacing.md,
      paddingVertical: theme.spacing.md,
      borderRadius: theme.borderRadius.full,
      backgroundColor: theme.colors.primary,
      alignItems: 'center',
    },
    primaryButtonText: {
      ...theme.typography.button.primary,
      color: theme.colors.text.inverse,
      fontWeight: '600',
    },
  });

export default MeditationVerse;
