import React, { useCallback, useEffect, useMemo, useState, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Animated } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { useTheme } from '@/contexts/ThemeContext';
import { ReadingPlanPhase, ReadingPlanMode } from '@/constants/readingPlanModes';
import * as Haptics from 'expo-haptics';
import * as Speech from 'expo-speech';

type MeditationVerseProps = {
  verses: Array<{ text: string; reference: string }>;
  phase: ReadingPlanPhase;
  isActive: boolean;
  remainingSeconds: number;
  onReturn: () => void;
  onCompletePhase: () => void;
  readingMode?: ReadingPlanMode;
  focusVirtueTerms?: string[] | null;
  onPauseAtVerse?: (verse: { text: string; reference: string }) => void;
  pausedKeys?: string[] | null;
  onDeletePausedVerse?: (verse: { text: string; reference: string }) => void;
  insightByKey?: Record<string, string>;
};

const MeditationVerse: React.FC<MeditationVerseProps> = ({ verses, phase, isActive, remainingSeconds, onReturn, onCompletePhase, readingMode, focusVirtueTerms, onPauseAtVerse, pausedKeys, onDeletePausedVerse, insightByKey }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  
  const [currentVerseIndex, setCurrentVerseIndex] = useState(0);
  const [isPaused, setIsPaused] = useState(false);
  const [prayerPromptIndex, setPrayerPromptIndex] = useState(0);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const advanceTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const allocatedSecondsRef = useRef<number>(Math.max(1, Math.round((phase.minutes || 0) * 60)));
  const remainingSecondsRef = useRef(Math.max(0, remainingSeconds));

  const currentVerse = verses[currentVerseIndex] || null;

  const versesCount = verses.length;

  const clearScheduledAdvance = useCallback(() => {
    if (advanceTimeoutRef.current) {
      clearTimeout(advanceTimeoutRef.current);
      advanceTimeoutRef.current = null;
    }
  }, []);

  const showNextVerse = useCallback(() => {
    if (versesCount <= 1) return;
    fadeAnim.setValue(0);
    setCurrentVerseIndex(prev => {
      if (prev >= versesCount - 1) {
        return prev;
      }
      return prev + 1;
    });
  }, [versesCount, fadeAnim]);

  const scheduleNextAdvance = useCallback(() => {
    clearScheduledAdvance();
    if (!isActive || isPaused || versesCount === 0) return;

    // Stop cycling verses during Lectio Divina prayer phase
    if (readingMode === 'lectio_divina' && phase.id === 'prayer') {
      return;
    }

    // Reserve the last 2 minutes of contemplation for silence (no cycling)
    if (phase.id === 'contemplation' && Math.max(0, remainingSecondsRef.current) <= 120) {
      return;
    }

    const versesRemainingIncludingCurrent = versesCount - currentVerseIndex;
    if (versesRemainingIncludingCurrent <= 1) return;

    const totalSeconds = remainingSecondsRef.current > 0
      ? remainingSecondsRef.current
      : allocatedSecondsRef.current;
    const perVerseSeconds = totalSeconds / Math.max(versesRemainingIncludingCurrent, 1);
    const durationMs = Math.max(perVerseSeconds * 1000, 1500);

    advanceTimeoutRef.current = setTimeout(() => {
      showNextVerse();
    }, durationMs);
  }, [clearScheduledAdvance, currentVerseIndex, isActive, isPaused, showNextVerse, versesCount]);

  useEffect(() => {
    scheduleNextAdvance();
    return clearScheduledAdvance;
  }, [scheduleNextAdvance, clearScheduledAdvance]);

  useEffect(() => {
    if (!isActive) {
      clearScheduledAdvance();
    }
  }, [isActive, clearScheduledAdvance]);

  useEffect(() => {
    const planned = Math.max(0, Math.round((phase.minutes || 0) * 60));
    allocatedSecondsRef.current = planned > 0 ? planned : Math.max(versesCount, 1) * 12;
  }, [phase.id, phase.minutes, versesCount]);

  useEffect(() => {
    remainingSecondsRef.current = Math.max(0, remainingSeconds);
  }, [remainingSeconds]);

  // Lectio divina prayer prompts at 0%, 25%, 50%, 75%
  const isLectioPrayer = readingMode === 'lectio_divina' && phase.id === 'prayer';
  const prayerPrompts = useMemo(
    () => [
      'Adore and thank God for His words revealed to you.',
      'Pray to receive the meaning of the words and for them to bear fruit.',
      'Pray to receive grace and sanctification through contemplating these words.',
      'Sing or pray for blessings and guidance with a psalm related to this reading.',
    ],
    []
  );

  useEffect(() => {
    if (!isLectioPrayer) return;
    const total = allocatedSecondsRef.current || 1;
    const elapsed = Math.max(0, total - remainingSecondsRef.current);
    const ratio = Math.max(0, Math.min(1, elapsed / total));
    const idx = ratio >= 0.75 ? 3 : ratio >= 0.5 ? 2 : ratio >= 0.25 ? 1 : 0;
    setPrayerPromptIndex(idx);
  }, [isLectioPrayer, remainingSeconds]);

  const speakPrompt = useCallback((text: string) => {
    try { Haptics.selectionAsync(); } catch {}
    try {
      if (isSpeaking) {
        Speech.stop();
        setIsSpeaking(false);
        return;
      }
      setIsSpeaking(true);
      Speech.speak(text, {
        language: 'en-US',
        rate: isLectioPrayer ? 0.72 : 0.85,
        onDone: () => setIsSpeaking(false),
        onStopped: () => setIsSpeaking(false),
        onError: () => setIsSpeaking(false),
      });
    } catch {
      setIsSpeaking(false);
    }
  }, [isSpeaking, isLectioPrayer]);

  useEffect(() => {
    fadeAnim.setValue(0);
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 750,
      useNativeDriver: true,
    }).start();
  }, [fadeAnim, currentVerseIndex, versesCount]);

  useEffect(() => {
    return clearScheduledAdvance;
  }, [clearScheduledAdvance]);

  useEffect(() => {
    setCurrentVerseIndex(0);
    setIsPaused(false);
    clearScheduledAdvance();
  }, [phase.id, versesCount, clearScheduledAdvance]);

  useEffect(() => {
    if (!isActive && isPaused) {
      setIsPaused(false);
    }
  }, [isActive, isPaused]);

  const handlePausePress = useCallback(() => {
    if (isPaused || !isActive) return;
    try { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); } catch {}
    clearScheduledAdvance();
    setIsPaused(true);
    if (onPauseAtVerse && currentVerse) {
      onPauseAtVerse(currentVerse);
    }
  }, [clearScheduledAdvance, isActive, isPaused]);

  const handleNextPress = useCallback(() => {
    try { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); } catch {}
    clearScheduledAdvance();
    if (isPaused) {
      setIsPaused(false);
    }
    showNextVerse();
  }, [clearScheduledAdvance, isPaused, showNextVerse]);

  const isLastVerse = currentVerseIndex >= versesCount - 1;
  const nextButtonLabel = isPaused ? 'Resume' : 'Next Verse';

  const isVirtuePhase = phase.id === 'prayer' || phase.id === 'contemplation';

  const buildHighlightRegex = useCallback((terms?: string[] | null) => {
    if (!terms || !terms.length) return null;
    const escaped = terms
      .map(t => t.trim())
      .filter(Boolean)
      .map(t => t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
    if (!escaped.length) return null;
    const pattern = `\\b(${escaped.join('|')})\\b`;
    try {
      return new RegExp(pattern, 'gi');
    } catch {
      return null;
    }
  }, []);

  const virtueRegex = useMemo(() => buildHighlightRegex(focusVirtueTerms), [buildHighlightRegex, focusVirtueTerms]);

  const renderHighlightedText = useCallback((text: string) => {
    if (!isVirtuePhase || !virtueRegex) return <Text style={styles.verseText}>{text}</Text>;
    const parts: Array<{ text: string; match: boolean }> = [];
    let lastIndex = 0;
    let m: RegExpExecArray | null;
    const input = text ?? '';
    const rx = new RegExp(virtueRegex.source, virtueRegex.flags);
    while ((m = rx.exec(input)) !== null) {
      if (m.index > lastIndex) {
        parts.push({ text: input.slice(lastIndex, m.index), match: false });
      }
      parts.push({ text: m[0], match: true });
      lastIndex = m.index + (m[0]?.length || 0);
    }
    if (lastIndex < input.length) {
      parts.push({ text: input.slice(lastIndex), match: false });
    }
    return (
      <Text style={styles.verseText}>
        {parts.map((p, idx) => (
          <Text key={idx} style={p.match ? styles.virtueHighlight : undefined}>{p.text}</Text>
        ))}
      </Text>
    );
  }, [isVirtuePhase, virtueRegex, styles.verseText, styles.virtueHighlight]);

  const currentKey = useMemo(() => currentVerse ? `${currentVerse.reference}::${currentVerse.text}` : '', [currentVerse]);
  const isCurrentPaused = useMemo(() => !!(pausedKeys && currentKey && pausedKeys.includes(currentKey)), [pausedKeys, currentKey]);
  const currentInsight = useMemo(() => (currentKey && insightByKey ? insightByKey[currentKey] : undefined), [currentKey, insightByKey]);

  const getPhasePrompt = useCallback(() => {
    switch (phase.id) {
      case 'meditation':
        return 'Meditate on the word...';
      case 'prayer':
        if (isLectioPrayer) {
          return prayerPrompts[prayerPromptIndex] ?? prayerPrompts[0];
        }
        return 'Pray through the word...';
      case 'contemplation':
        // If in the last 2 minutes, guide silence
        if (Math.max(0, remainingSecondsRef.current) <= 120) {
          return 'Be still. Keep quiet and listen to the Holy Spirit.';
        }
        return 'Contemplate the meaning...';
      default:
        return 'Reflect on this word...';
    }
  }, [phase.id, isLectioPrayer, prayerPromptIndex, prayerPrompts]);

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
          {isLectioPrayer && (
            <TouchableOpacity
              style={styles.iconButton}
              onPress={() => speakPrompt(getPhasePrompt())}
              accessibilityRole="button"
              accessibilityLabel={isSpeaking ? 'Stop reading prompt' : 'Read prayer prompt aloud'}
            >
              <MaterialIcons name={isSpeaking ? 'stop' : 'volume-up'} size={20} color={theme.colors.text.secondary} />
            </TouchableOpacity>
          )}
          {phase.id === 'contemplation' && currentInsight && (
            <TouchableOpacity
              style={styles.iconButton}
              onPress={() => speakPrompt(currentInsight)}
              accessibilityRole="button"
              accessibilityLabel={isSpeaking ? 'Stop reading insight' : 'Read insight aloud'}
            >
              <MaterialIcons name={isSpeaking ? 'stop' : 'record-voice-over'} size={20} color={theme.colors.text.secondary} />
            </TouchableOpacity>
          )}
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
          {/* Hide verse cycling display during lectio prayer or contemplation silence window */}
          {!(isLectioPrayer || (phase.id === 'contemplation' && Math.max(0, remainingSecondsRef.current) <= 120)) && (
            <>
              {renderHighlightedText(currentVerse.text)}
              <Text style={styles.referenceText}>{currentVerse.reference}</Text>
            </>
          )}
        </Animated.View>
      </View>

      <View style={styles.footer}>
        <View style={styles.footerRow}>
          {isVirtuePhase && isCurrentPaused && (
            <TouchableOpacity
              style={styles.iconButton}
              onPress={() => {
                try { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); } catch {}
                if (onDeletePausedVerse && currentVerse) onDeletePausedVerse(currentVerse);
              }}
              accessibilityRole="button"
              accessibilityLabel="Remove paused verse"
            >
              <MaterialIcons name="delete-outline" size={20} color={theme.colors.text.secondary} />
            </TouchableOpacity>
          )}
          <TouchableOpacity
            style={[styles.pauseButton, (!isActive || isPaused) && styles.pauseButtonDisabled]}
            onPress={handlePausePress}
            disabled={!isActive || isPaused}
            accessibilityRole="button"
            accessibilityLabel="Pause verse rotation"
          >
            <MaterialIcons name="pause" size={20} color={(!isActive || isPaused) ? theme.colors.text.tertiary : theme.colors.text.primary} />
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.secondaryButton, isLastVerse && styles.secondaryButtonDisabled]}
            onPress={handleNextPress}
            disabled={isLastVerse}
          >
            <Text style={styles.secondaryButtonText}>{nextButtonLabel}</Text>
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
    virtueHighlight: {
      color: theme.colors.primary,
      fontWeight: '700',
      backgroundColor: `${theme.colors.primary}10`,
      borderRadius: 4,
      paddingHorizontal: 2,
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
    pauseButton: {
      width: 48,
      height: 48,
      borderRadius: theme.borderRadius.full,
      borderWidth: 1,
      borderColor: `${theme.colors.text.secondary}40`,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: `${theme.colors.text.secondary}10`,
    },
    iconButton: {
      width: 44,
      height: 44,
      borderRadius: theme.borderRadius.full,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: `${theme.colors.text.secondary}08`,
    },
    pauseButtonDisabled: {
      opacity: 0.5,
    },
    secondaryButton: {
      flex: 1,
      paddingHorizontal: theme.spacing.md,
      paddingVertical: theme.spacing.md,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.primary}12`,
      alignItems: 'center',
    },
    secondaryButtonDisabled: {
      opacity: 0.5,
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
