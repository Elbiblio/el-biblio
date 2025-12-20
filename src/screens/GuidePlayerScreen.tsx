import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Dimensions, Linking, Image, Platform } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import type { Theme } from '@/theme';
import type { RootStackParamList } from '@/types';
import { ArrowLeft } from '@/components/Icons';
import { useGuideStore } from '@/stores/StoreProvider';
import type { InteractiveReadingQuizConfig, ReadingReflectionConfig, MeditationGuideConfig, GuideBlock } from '@/services/GuideService';
import { telemetry } from '@/services/TelemetryService';
import { playCue } from '@/services/audio';

export type GuidePlayerScreenProps = NativeStackScreenProps<RootStackParamList, 'GuidePlayerScreen'>;

const GuidePlayerScreen = ({ navigation, route }: GuidePlayerScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const { guideId } = route.params;
  const guideStore = useGuideStore();

  const [ready, setReady] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [pageIndex, setPageIndex] = React.useState(0);
  const [answers, setAnswers] = React.useState<Record<string, number | null>>({});
  const [submitted, setSubmitted] = React.useState(false);
  const [medMode, setMedMode] = React.useState<'short' | 'long'>('short');
  const [activeStepId, setActiveStepId] = React.useState<string | null>(null);
  const [elapsed, setElapsed] = React.useState<Record<string, number>>({});
  const [isTimerRunning, setIsTimerRunning] = React.useState(false);
  const timerRef = React.useRef<ReturnType<typeof setInterval> | null>(null);
  const [selectedPassageId, setSelectedPassageId] = React.useState<string | null>(null);
  const [accordionOpen, setAccordionOpen] = React.useState<Record<string, boolean>>({});

  const windowWidth = Dimensions.get('window').width;

  const guide = guideStore.definitions[guideId];

  const renderBlocks = (blocks?: GuideBlock[]) => {
    if (!blocks || !blocks.length) return null;
    return blocks.map((b, idx) => {
      if (b.type === 'heading') {
        return (
          <View key={`b-${idx}`} style={styles.card}>
            <Text style={styles.cardTitle}>{b.text}</Text>
          </View>
        );
      }
      if (b.type === 'paragraph') {
        return (
          <View key={`b-${idx}`} style={styles.card}>
            <Text style={styles.cardBody}>{b.text}</Text>
          </View>
        );
      }
      if (b.type === 'bullet_list') {
        return (
          <View key={`b-${idx}`} style={styles.card}>
            {(b.items || []).map((it, i) => (
              <Text key={`li-${i}`} style={styles.cardBody}>• {it}</Text>
            ))}
          </View>
        );
      }
      if (b.type === 'scripture') {
        return (
          <View key={`b-${idx}`} style={styles.card}>
            <Text style={styles.cardTitle}>{b.label || 'Scripture'}</Text>
            <TouchableOpacity
              style={styles.primaryButton}
              activeOpacity={0.9}
              onPress={() => {
                navigation.navigate('BibleScreen', { book: b.book, chapter: b.chapter, verse: b.verseFrom });
              }}
            >
              <Text style={styles.primaryButtonText}>Open in Bible</Text>
            </TouchableOpacity>
          </View>
        );
      }
      if (b.type === 'cta') {
        return (
          <View key={`b-${idx}`} style={styles.card}>
            <TouchableOpacity
              style={styles.primaryButton}
              activeOpacity={0.9}
              onPress={() => {
                const a = b.action;
                if (a.type === 'navigate') {
                  const params = (a.params || {}) as any;
                  navigation.navigate(params.route as any, params.params as any);
                } else if (a.type === 'open_bible') {
                  const params = (a.params || {}) as { book?: string; chapter?: number; verse?: number };
                  navigation.navigate('BibleScreen', { book: params.book, chapter: params.chapter, verse: params.verse });
                } else if (a.type === 'open_url') {
                  const url = String((a.params || {}).url || '');
                  if (url) Linking.openURL(url).catch(() => undefined);
                }
              }}
            >
              <Text style={styles.primaryButtonText}>{b.label}</Text>
            </TouchableOpacity>
          </View>
        );
      }
      if (b.type === 'audio') {
        return (
          <View key={`b-${idx}`} style={styles.card}>
            <Text style={styles.cardTitle}>{b.label || 'Audio'}</Text>
            <TouchableOpacity
              style={styles.primaryButton}
              activeOpacity={0.9}
              onPress={() => { playCue(b.cue || 'meditationBell').catch(() => undefined); }}
            >
              <Text style={styles.primaryButtonText}>Play</Text>
            </TouchableOpacity>
          </View>
        );
      }
      if (b.type === 'image') {
        return (
          <View key={`b-${idx}`} style={styles.card}>
            <Image source={{ uri: b.uri }} style={styles.blockImage} resizeMode="cover" />
            {b.alt ? <Text style={styles.cardBody}>{b.alt}</Text> : null}
          </View>
        );
      }
      if (b.type === 'quote') {
        return (
          <View key={`b-${idx}`} style={styles.card}>
            <Text style={styles.quoteText}>“{b.text}”</Text>
            {b.attribution ? <Text style={styles.quoteAttribution}>— {b.attribution}</Text> : null}
          </View>
        );
      }
      if (b.type === 'callout') {
        return (
          <View key={`b-${idx}`} style={styles.callout}>
            <Text style={styles.cardBody}>{b.text}</Text>
          </View>
        );
      }
      if (b.type === 'divider') {
        return <View key={`b-${idx}`} style={[styles.divider, b.size === 'sm' && { height: 1 }, b.size === 'md' && { height: 2 }, b.size === 'lg' && { height: 3 }]} />;
      }
      if (b.type === 'spacer') {
        return <View key={`b-${idx}`} style={{ height: Math.max(4, Math.min(64, b.height || 12)) }} />;
      }
      if (b.type === 'accordion') {
        return (
          <View key={`b-${idx}`} style={styles.card}>
            {b.items.map((it) => {
              const key = `acc-${idx}-${it.id}`;
              const open = !!accordionOpen[key];
              return (
                <View key={it.id} style={{ marginBottom: theme.spacing.xs }}>
                  <TouchableOpacity
                    style={[styles.modeChip, open && styles.questionOptionSelected]}
                    activeOpacity={0.9}
                    onPress={() => setAccordionOpen(prev => ({ ...prev, [key]: !prev[key] }))}
                  >
                    <Text style={styles.modeText}>{it.title}</Text>
                  </TouchableOpacity>
                  {open && (
                    <View style={{ marginTop: theme.spacing.xs }}>
                      <Text style={styles.cardBody}>{it.body}</Text>
                    </View>
                  )}
                </View>
              );
            })}
          </View>
        );
      }
      return null;
    });
  };

  React.useEffect(() => {
    let active = true;
    (async () => {
      try {
        if (!guide) {
          await guideStore.fetchGuide(guideId);
        }
        const g = guideStore.definitions[guideId];
        if (g && g.content.mode === 'meditation') {
          const cfg = g.content as MeditationGuideConfig;
          if (!activeStepId && cfg.steps && cfg.steps.length > 0) {
            setActiveStepId(cfg.steps[0].id);
          }
          if (!selectedPassageId && cfg.passages && cfg.passages.length > 0) {
            setSelectedPassageId(cfg.passages[0].id);
          }
        }
        if (g && active) {
          telemetry.track('guide_open', { guideId: g.id, mode: g.content.mode });
        }
        if (active) setReady(true);
      } catch (e) {
        if (active) setError('Failed to load guide');
      }
    })();
    return () => { active = false; };
  }, [guideId]);

  React.useEffect(() => {
    if (!isTimerRunning) {
      if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
      return;
    }
    timerRef.current = setInterval(() => {
      setElapsed(prev => {
        const key = activeStepId || 'default';
        const next = { ...prev, [key]: (prev[key] ?? 0) + 1 };
        return next;
      });
    }, 1000);
    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
    };
  }, [isTimerRunning, activeStepId]);

  React.useEffect(() => {
    if (activeStepId) {
      telemetry.track('guide_step_view', { guideId, stepId: activeStepId });
    }
  }, [activeStepId, guideId]);

  if (!ready || !guide) {
    return (
      <View style={[styles.container, { paddingTop: insets.top, alignItems: 'center', justifyContent: 'center' }]}> 
        <Text style={styles.loadingText}>{error ? error : 'Loading guide...'}</Text>
      </View>
    );
  }

  const mode = guide.content.mode;

  const renderInteractiveReadingQuiz = (cfg: InteractiveReadingQuizConfig) => {
    return (
      <View>
        {renderBlocks(cfg.blocks)}
        <View style={styles.carouselContainer}>
          <ScrollView horizontal pagingEnabled showsHorizontalScrollIndicator={false}
            onMomentumScrollEnd={(e) => {
              const { contentOffset, layoutMeasurement } = e.nativeEvent;
              const next = Math.round(contentOffset.x / layoutMeasurement.width);
              setPageIndex(next);
              try {
                const pid = cfg.pages?.[next]?.id;
                if (pid) telemetry.track('guide_page_view', { guideId, pageId: pid });
              } catch {}
            }}
          >
            {cfg.pages?.map((p, i) => (
              <View key={p.id} style={[styles.slide, { width: windowWidth - theme.spacing.md * 2 }]}> 
                <Text style={styles.cardTitle}>{p.title}</Text>
                <Text style={styles.cardBody}>{p.body}</Text>
              </View>
            ))}
          </ScrollView>
          <View style={styles.paginationRow}>
            {(cfg.pages || []).map((p, i) => (
              <View key={p.id} style={i === pageIndex ? styles.paginationDotActive : styles.paginationDot} />
            ))}
          </View>
        </View>

        <View style={styles.card}>
          <View style={styles.quizHeaderRow}>
            <Text style={styles.questionTitle}>Check your understanding</Text>
            {cfg.questions.length > 0 && (
              <View style={styles.quizProgressPill}>
                <Text style={styles.quizProgressText}>
                  {Object.values(answers).filter(v => v !== null).length}/{cfg.questions.length}
                </Text>
              </View>
            )}
          </View>
          {cfg.questions.map((q, qi) => {
            const selected = answers[q.id] ?? null;
            const isCorrectOption = submitted ? q.correctIndex : -1;
            return (
              <View key={q.id} style={styles.questionBlock}>
                <Text style={styles.cardBody}>{q.prompt}</Text>
                {q.options.map((opt, oi) => {
                  const selectedNow = selected === oi;
                  const showCorrect = submitted && oi === isCorrectOption;
                  const showIncorrect = submitted && selectedNow && oi !== isCorrectOption;
                  return (
                    <TouchableOpacity
                      key={oi}
                      style={[
                        styles.questionOption,
                        selectedNow && styles.questionOptionSelected,
                        showCorrect && styles.questionOptionCorrect,
                        showIncorrect && styles.questionOptionIncorrect,
                      ]}
                      activeOpacity={0.85}
                      onPress={() => {
                        setSubmitted(false);
                        setAnswers(prev => ({ ...prev, [q.id]: oi }));
                      }}
                    >
                      <Text style={[
                        styles.questionOptionText,
                        showCorrect && styles.questionOptionTextCorrect,
                        showIncorrect && styles.questionOptionTextIncorrect,
                      ]}>{opt}</Text>
                    </TouchableOpacity>
                  );
                })}
              </View>
            );
          })}
          <TouchableOpacity style={styles.primaryButton} activeOpacity={0.9} onPress={() => {
            setSubmitted(true);
            try {
              const total = cfg.questions.length;
              const correctCount = cfg.questions.reduce((acc, q) => acc + ((answers[q.id] ?? null) === q.correctIndex ? 1 : 0), 0);
              telemetry.track('guide_quiz_submit', { guideId, total, answered: Object.values(answers).filter(v => v !== null).length, correct: correctCount });
            } catch {}
          }}>
            <Text style={styles.primaryButtonText}>Check answers</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  const renderReadingReflection = (cfg: ReadingReflectionConfig) => {
    return (
      <View>
        {renderBlocks(cfg.blocks)}
        {(cfg.sections || []).map((s, index) => (
          <View key={s.id} style={styles.sectionCard}>
            <View style={styles.sectionHeader}>
              <View style={styles.sectionNumber}>
                <Text style={styles.sectionNumberText}>{index + 1}</Text>
              </View>
              <Text style={styles.sectionTitle}>{s.title}</Text>
            </View>
            <Text style={styles.sectionBody}>{s.body}</Text>
          </View>
        ))}
        {cfg.reflectionPrompt ? (
          <View style={styles.reflectionCard}>
            <View style={styles.reflectionHeader}>
              <View style={styles.reflectionIcon}>
                <Text style={styles.reflectionIconText}>💭</Text>
              </View>
              <Text style={styles.reflectionTitle}>Take a moment to reflect</Text>
            </View>
            <Text style={styles.reflectionPrompt}>{cfg.reflectionPrompt}</Text>
          </View>
        ) : null}
      </View>
    );
  };

  const renderMeditation = (cfg: MeditationGuideConfig) => {
    const shortLabel = cfg.minutesShort ? `About ${cfg.minutesShort} min` : '';
    const longLabel = cfg.minutesLong ? `About ${cfg.minutesLong} min` : '';
    const steps = cfg.steps || [];
    const currentStep = steps.find(s => s.id === (activeStepId || '')) || steps[0];
    const currentSeconds = elapsed[activeStepId || (currentStep?.id || 'default')] ?? 0;
    const mm = Math.floor(currentSeconds / 60).toString().padStart(2, '0');
    const ss = (currentSeconds % 60).toString().padStart(2, '0');

    return (
      <View>
        {renderBlocks(cfg.blocks)}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Choose a mode</Text>
          <View style={styles.modeRow}>
            <TouchableOpacity
              style={[styles.modeChip, medMode === 'short' && styles.questionOptionSelected]}
              activeOpacity={0.9}
              onPress={() => setMedMode('short')}
            >
              <Text style={styles.modeText}>Short • {shortLabel}</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.modeChip, medMode === 'long' && styles.questionOptionSelected]}
              activeOpacity={0.9}
              onPress={() => setMedMode('long')}
            >
              <Text style={styles.modeText}>Long • {longLabel}</Text>
            </TouchableOpacity>
          </View>
          {steps.length > 0 && (
            <View style={styles.modeRow}>
              {steps.map(step => (
                <TouchableOpacity
                  key={step.id}
                  style={[styles.modeChip, (currentStep?.id === step.id) && styles.questionOptionSelected]}
                  activeOpacity={0.9}
                  onPress={() => { setActiveStepId(step.id); setIsTimerRunning(false); }}
                >
                  <Text style={styles.modeText}>{step.title}</Text>
                  <Text style={styles.cardBody}>{medMode === 'short' ? (step.suggestedMinutesShort || '') : (step.suggestedMinutesLong || '')}</Text>
                </TouchableOpacity>
              ))}
            </View>
          )}
          {currentStep?.body ? (
            <Text style={[styles.cardBody, { marginTop: 6 }]}>{currentStep.body}</Text>
          ) : null}
          <View style={[styles.modeRow, { alignItems: 'center', justifyContent: 'space-between' }]}>
            <Text style={styles.questionTitle}>Time • {mm}:{ss}</Text>
            <View style={styles.modeRow}>
              <TouchableOpacity style={styles.primaryButton} activeOpacity={0.9} onPress={() => {
                setIsTimerRunning(v => !v);
                telemetry.track('guide_timer_toggle', { guideId, isRunning: !isTimerRunning });
              }}>
                <Text style={styles.primaryButtonText}>{isTimerRunning ? 'Pause' : 'Start'}</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.modeChip]} activeOpacity={0.85} onPress={() => {
                const key = currentStep?.id || 'default';
                setElapsed(prev => ({ ...prev, [key]: 0 }));
                setIsTimerRunning(false);
                telemetry.track('guide_timer_reset', { guideId });
              }}>
                <Text style={styles.modeText}>Reset</Text>
              </TouchableOpacity>
            </View>
          </View>
          {steps.length > 0 && (
            <View style={styles.modeRow}>
              <TouchableOpacity
                style={[styles.modeChip]}
                activeOpacity={0.9}
                onPress={() => {
                  if (!currentStep) return;
                  const idx = steps.findIndex(s => s.id === currentStep.id);
                  if (idx > 0) { setActiveStepId(steps[idx - 1].id); setIsTimerRunning(false); }
                }}
              >
                <Text style={styles.modeText}>Previous</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modeChip]}
                activeOpacity={0.9}
                onPress={() => {
                  if (!currentStep) return;
                  const idx = steps.findIndex(s => s.id === currentStep.id);
                  if (idx !== -1 && idx < steps.length - 1) { setActiveStepId(steps[idx + 1].id); setIsTimerRunning(false); }
                }}
              >
                <Text style={styles.modeText}>Next</Text>
              </TouchableOpacity>
            </View>
          )}
        </View>

        {(() => { const passages = cfg.passages || []; return passages.length > 0; })() && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Scripture</Text>
            <View style={styles.modeRow}>
              {(cfg.passages || []).map(p => {
                const selected = p.id === selectedPassageId;
                return (
                  <TouchableOpacity key={p.id} style={[styles.modeChip, selected && styles.questionOptionSelected]} activeOpacity={0.85} onPress={() => setSelectedPassageId(p.id)}>
                    <Text style={styles.modeText}>{p.label}</Text>
                  </TouchableOpacity>
                );
              })}
            </View>
            <TouchableOpacity
              style={styles.primaryButton}
              activeOpacity={0.9}
              onPress={() => {
                const passages = cfg.passages || [];
                const p = passages.find(pp => pp.id === selectedPassageId) || passages[0];
                if (!p) return;
                navigation.navigate('BibleScreen', { book: p.book, chapter: p.chapter, verse: p.verse });
              }}
            >
              <Text style={styles.primaryButtonText}>Open selected passage in Bible</Text>
            </TouchableOpacity>
          </View>
        )}

        <View style={styles.card}>
          <TouchableOpacity style={styles.primaryButton} activeOpacity={0.9} onPress={() => { telemetry.track('guide_complete', { guideId, mode: 'meditation' }); navigation.goBack(); }}>
            <Text style={styles.primaryButtonText}>Finish</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}> 
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>{guide.title}</Text>
        <View style={{ width: 24 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        {mode === 'interactive_reading_quiz' && renderInteractiveReadingQuiz(guide.content as InteractiveReadingQuizConfig)}
        {mode === 'reading_reflection' && renderReadingReflection(guide.content as ReadingReflectionConfig)}
        {mode === 'meditation' && renderMeditation(guide.content as MeditationGuideConfig)}
      </ScrollView>
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  title: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  content: {
    padding: theme.spacing.md,
    paddingBottom: theme.spacing.xl,
    gap: theme.spacing.md,
  },
  loadingText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  card: {
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: theme.spacing.sm,
  },
  cardTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '700',
  },
  cardBody: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  carouselContainer: {
    marginTop: theme.spacing.sm,
  },
  slide: {
    marginRight: theme.spacing.sm,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: theme.spacing.sm,
  },
  paginationRow: {
    marginTop: theme.spacing.sm,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 6,
  },
  paginationDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: theme.colors.border,
  },
  paginationDotActive: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: theme.colors.primary,
  },
  quizHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  quizProgressPill: {
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    backgroundColor: `${theme.colors.primary}10`,
  },
  quizProgressText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
    fontVariant: ['tabular-nums'],
  },
  questionTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
    marginBottom: theme.spacing.xs,
  },
  questionBlock: {
    marginTop: theme.spacing.sm,
    gap: theme.spacing.xs,
  },
  questionOption: {
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.md,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.background,
  },
  questionOptionSelected: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
  },
  questionOptionText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  questionOptionCorrect: {
    borderColor: theme.colors.success,
    backgroundColor: `${theme.colors.success}15`,
  },
  questionOptionIncorrect: {
    borderColor: theme.colors.error,
    backgroundColor: `${theme.colors.error}10`,
  },
  questionOptionTextCorrect: {
    color: theme.colors.success,
    fontWeight: '600',
  },
  questionOptionTextIncorrect: {
    color: theme.colors.error,
  },
  primaryButton: {
    marginTop: theme.spacing.md,
    alignSelf: 'flex-start',
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.primary,
  },
  primaryButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  blockImage: {
    width: '100%',
    height: 180,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  modeRow: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
  },
  modeChip: {
    flex: 1,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.background,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  modeText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '500',
  },
  quoteText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontStyle: 'italic',
  },
  quoteAttribution: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: 4,
    textAlign: 'right',
  },
  callout: {
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: `${theme.colors.primary}10`,
    borderWidth: 1,
    borderColor: theme.colors.primary,
    gap: theme.spacing.xs,
  },
  divider: {
    width: '100%',
    height: 1,
    backgroundColor: theme.colors.border,
    marginVertical: theme.spacing.xs,
  },
  sectionCard: {
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.xl,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: `${theme.colors.border}90`,
    marginBottom: theme.spacing.lg,
    ...Platform.select({
      ios: {
        shadowColor: "#000",
        shadowOffset: {
          width: 0,
          height: 2,
        },
        shadowOpacity: 0.08,
        shadowRadius: 8,
      },
      android: {
        elevation: 3,
      },
    }),
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  sectionNumber: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: theme.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sectionNumberText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '700',
    fontSize: 14,
  },
  sectionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    flex: 1,
    fontWeight: '700',
  },
  sectionBody: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    lineHeight: 22,
  },
  reflectionCard: {
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.xl,
    backgroundColor: `${theme.colors.primary}08`,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}20`,
    marginBottom: theme.spacing.lg,
  },
  reflectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  reflectionIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: `${theme.colors.primary}15`,
    alignItems: 'center',
    justifyContent: 'center',
  },
  reflectionIconText: {
    fontSize: 20,
  },
  reflectionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    fontWeight: '700',
  },
  reflectionPrompt: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    lineHeight: 22,
    fontStyle: 'italic',
  },
});

export default observer(GuidePlayerScreen);
