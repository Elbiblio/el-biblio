import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Dimensions, Linking, Image, Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import type { Theme } from '@/theme';
import type { RootStackParamList } from '@/types';
import { ArrowLeft } from '@/components/Icons';
import { useGuideStore } from '@/stores/StoreProvider';
import { GuideErrorBoundary } from '@/components/GuideErrorBoundary';
import type {
  InteractiveReadingQuizConfig,
  InteractiveReadingQuizPage,
  ReadingReflectionConfig,
  ReadingReflectionSection,
  MeditationGuideConfig,
  GuideBlock,
  GuideProgressState,
} from '@/services/GuideService';
import { getGuideProgress, saveGuideProgress } from '@/services/GuideService';
import { telemetry } from '@/services/TelemetryService';
import { playCue } from '@/services/audio';

export type GuidePlayerScreenProps = NativeStackScreenProps<RootStackParamList, 'GuidePlayerScreen'>;

const GuidePlayerScreen = ({ navigation, route }: GuidePlayerScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  
  // Safe access to route params with validation
  const guideId = route?.params?.guideId;
  const guideStore = useGuideStore();

  const [ready, setReady] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [paramsValidated, setParamsValidated] = React.useState(false);
  const [currentStepIndex, setCurrentStepIndex] = React.useState(0);
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
  const [showTOC, setShowTOC] = React.useState(false);
  const [bookmarkedPosition, setBookmarkedPosition] = React.useState<number | null>(null);
  const bookmarkKey = React.useMemo(
    () => (guideId ? `GUIDE_BOOKMARK_${guideId}` : null),
    [guideId]
  );
  const [presentationMode, setPresentationMode] = React.useState<'guided' | 'flow'>('guided');
  const modePreferenceKey = React.useMemo(
    () => (guideId ? `GUIDE_MODE_${guideId}` : null),
    [guideId]
  );
  const [progressLoaded, setProgressLoaded] = React.useState(false);
  const [isSyncing, setIsSyncing] = React.useState(false);
  const skipSaveRef = React.useRef(true);
  const saveDebounceRef = React.useRef<ReturnType<typeof setTimeout> | null>(null);
  
  const windowWidth = Dimensions.get('window').width;

  const guide = guideId ? guideStore.definitions[guideId] : undefined;
  const mode = guide?.content.mode;

  // Initialize accordion state with first item expanded
  React.useEffect(() => {
    if (guide && guide.content.blocks) {
      const accordionBlocks = guide.content.blocks.filter(b => b.type === 'accordion');
      if (accordionBlocks.length > 0) {
        const initialAccordionState: Record<string, boolean> = {};
        accordionBlocks.forEach((block, blockIndex) => {
          if (block.items && block.items.length > 0) {
            // Auto-expand first accordion item
            initialAccordionState[`acc-${blockIndex}-${block.items[0].id}`] = true;
          }
        });
        setAccordionOpen((prev: Record<string, boolean>) => ({ ...prev, ...initialAccordionState }));
      }
    }
  }, [guide]);

  // Flatten all content into steps for step-by-step presentation
  const getContentSteps = React.useMemo(() => {
    if (!guide) return [];
    
    const steps: Array<{ type: string; content: any; title?: string }> = [];
    
    // Add initial blocks
    if (guide.content.blocks && guide.content.blocks.length > 0) {
      const blocks = guide.content.blocks;
      blocks.forEach((block, index) => {
        // Skip heading-only blocks and merge them with next content
        if (block.type === 'heading' && index < blocks.length - 1) {
          const nextBlock = blocks[index + 1];
          // Merge heading with next block if it's not another heading
          if (nextBlock && nextBlock.type !== 'heading') {
            steps.push({ 
              type: 'block', 
              content: [block, nextBlock], 
              title: block.text || `Step ${steps.length + 1}` 
            });
            return; // Skip adding the next block separately
          }
        }
        steps.push({ type: 'block', content: block, title: block.type === 'heading' ? block.text : `Step ${steps.length + 1}` });
      });
    }
    
    // Add sections for reading reflection
    if (mode === 'reading_reflection' && guide.content.sections) {
      guide.content.sections.forEach((section) => {
        steps.push({ type: 'section', content: section, title: section.title });
      });
    }
    
    // Add reflection prompt
    if (mode === 'reading_reflection' && guide.content.reflectionPrompt) {
      steps.push({ type: 'reflection', content: { prompt: guide.content.reflectionPrompt }, title: 'Reflection' });
    }
    
    // Add quiz pages for interactive reading quiz
    if (mode === 'interactive_reading_quiz' && guide.content.pages) {
      guide.content.pages.forEach((page) => {
        steps.push({ type: 'page', content: page, title: page.title });
      });
    }
    
    // Add quiz questions
    if (mode === 'interactive_reading_quiz' && guide.content.questions) {
      steps.push({ type: 'quiz', content: guide.content.questions, title: 'Check your understanding' });
    }
    
    return steps;
  }, [guide, mode]);

  const currentStep = getContentSteps[currentStepIndex];
  const totalSteps = getContentSteps.length;
  const isLastStep = currentStepIndex === totalSteps - 1;
  const isFirstStep = currentStepIndex === 0;

  // Calculate reading time for content
  const calculateReadingTime = (text: string): number => {
    const wordsPerMinute = 200; // Average reading speed
    const wordCount = text.split(/\s+/).length;
    return Math.ceil(wordCount / wordsPerMinute);
  };

  const renderFlowMode = () => {
    if (!guide) return null;
    if (mode === 'reading_reflection') {
      return renderReadingReflection(guide.content as ReadingReflectionConfig);
    }
    if (mode === 'interactive_reading_quiz') {
      return renderInteractiveReadingQuiz(guide.content as InteractiveReadingQuizConfig);
    }
    if (mode === 'meditation') {
      return renderMeditation(guide.content as MeditationGuideConfig);
    }
    return renderBlocks((guide.content as any)?.blocks || []);
  };

  const renderContent = () =>
    presentationMode === 'guided' ? renderGuidedStep() : renderFlowMode();

  const renderTableOfContents = () => {
    if (!showTOC || tableOfContents.length === 0) return null;

    return (
      <View style={styles.tocContainer}>
        <View style={styles.tocHeader}>
          <Text style={styles.tocTitle}>Guide Overview</Text>
          <TouchableOpacity
            style={styles.headerButton}
            activeOpacity={0.85}
            onPress={() => setShowTOC(false)}
          >
            <Text style={styles.headerButtonText}>Close</Text>
          </TouchableOpacity>
        </View>
        {tableOfContents.map(item => (
          <TouchableOpacity
            key={item.index}
            style={[
              styles.tocRow,
              item.isCurrent && styles.tocRowActive,
              item.isCompleted && styles.tocRowCompleted,
            ]}
            activeOpacity={0.85}
            onPress={() => goToStep(item.index)}
          >
            <View style={styles.tocRowLeft}>
              <Text style={styles.tocIndex}>{item.index + 1}</Text>
              <Text style={styles.tocText}>{item.title}</Text>
            </View>
            {item.readingTime > 0 && (
              <Text style={styles.tocReadingTime}>{item.readingTime} min</Text>
            )}
          </TouchableOpacity>
        ))}
        {bookmarkedPosition !== null && (
          <TouchableOpacity
            style={styles.tocBookmark}
            activeOpacity={0.85}
            onPress={jumpToBookmark}
          >
            <Text style={styles.tocBookmarkText}>Jump to bookmark (Step {bookmarkedPosition + 1})</Text>
          </TouchableOpacity>
        )}
      </View>
    );
  };

  // Generate table of contents with reading times
  const tableOfContents = React.useMemo(() => {
    if (!guide) return [];
    
    const toc = getContentSteps.map((step, index) => {
      let readingTime = 0;
      
      if (step.type === 'block') {
        const blocks = Array.isArray(step.content) ? step.content : [step.content];
        const text = blocks
          .filter(b => b.type === 'paragraph' || b.type === 'heading')
          .map(b => b.text || '')
          .join(' ');
        readingTime = calculateReadingTime(text);
      } else if (step.type === 'section') {
        readingTime = calculateReadingTime(step.content.body || '');
      } else if (step.type === 'page') {
        readingTime = calculateReadingTime(step.content.body || '');
      }
      
      return {
        index,
        title: step.title || `Step ${index + 1}`,
        readingTime,
        isCompleted: index < currentStepIndex,
        isCurrent: index === currentStepIndex,
      };
    });
    
    return toc;
  }, [guide, getContentSteps, currentStepIndex]);

  // Calculate total reading time
  const totalReadingTime = tableOfContents.reduce((sum, item) => sum + item.readingTime, 0);

  // Navigation functions for step-by-step presentation
  const goToNextStep = () => {
    if (!isLastStep) {
      setCurrentStepIndex(prev => prev + 1);
      telemetry.track('guide_step_next', { guideId, stepIndex: currentStepIndex + 1 });
    }
  };

  const goToPreviousStep = () => {
    if (!isFirstStep) {
      setCurrentStepIndex(prev => prev - 1);
      telemetry.track('guide_step_previous', { guideId, stepIndex: currentStepIndex - 1 });
    }
  };

  const goToStep = (index: number) => {
    setCurrentStepIndex(index);
    setShowTOC(false);
    telemetry.track('guide_step_jump', { guideId, stepIndex: index });
  };

  const toggleBookmark = React.useCallback(async () => {
    if (!bookmarkKey) return;
    try {
      if (bookmarkedPosition === currentStepIndex) {
        await AsyncStorage.removeItem(bookmarkKey);
        setBookmarkedPosition(null);
        telemetry.track('guide_bookmark_cleared', { guideId, position: currentStepIndex });
      } else {
        await AsyncStorage.setItem(bookmarkKey, String(currentStepIndex));
        setBookmarkedPosition(currentStepIndex);
        telemetry.track('guide_bookmark_saved', { guideId, position: currentStepIndex });
      }
    } catch (e) {
      console.warn('Failed to toggle bookmark', e);
    }
  }, [bookmarkKey, bookmarkedPosition, currentStepIndex, guideId]);

  const jumpToBookmark = () => {
    if (bookmarkedPosition !== null) {
      goToStep(bookmarkedPosition);
    }
  };

  // Guided/flow presentation helpers
  const renderGuidedStep = () => {
    if (!currentStep || !guide) return null;

    switch (currentStep.type) {
      case 'block':
        return renderBlocks([currentStep.content]);
      case 'section': {
        const cfg = guide.content as ReadingReflectionConfig;
        const sections = cfg.sections || [];
        const sectionIndex = sections.findIndex(s => s.id === currentStep.content?.id);
        return renderReadingSection(currentStep.content, sectionIndex);
      }
      case 'reflection':
        return renderReflectionPrompt(currentStep.content?.prompt || '');
      case 'page':
        return renderQuizPage(currentStep.content);
      case 'quiz':
        return renderQuizQuestions(guide.content as InteractiveReadingQuizConfig);
      default:
        return renderBlocks([currentStep.content]);
    }
  };

  // Progress indicator component
  const renderProgressIndicator = () => {
    if (presentationMode !== 'guided' || totalSteps <= 1) return null;
    
    const progressPercentage = ((currentStepIndex + 1) / totalSteps) * 100;
    
    return (
      <View style={styles.progressContainer}>
        <View style={styles.circularProgress}>
          <View style={styles.progressCircle}>
            <View style={styles.progressRing} />
            <Text style={styles.progressPercentage}>{Math.round(progressPercentage)}%</Text>
          </View>
        </View>
        <View style={styles.progressInfo}>
          <Text style={styles.progressText}>
            Step {currentStepIndex + 1} of {totalSteps}
          </Text>
          {totalReadingTime > 0 && (
            <Text style={styles.readingTime}>
              ~{totalReadingTime} min total
            </Text>
          )}
        </View>
        <View style={styles.progressBar}>
          <View 
            style={[
              styles.progressFill, 
              { width: `${progressPercentage}%` }
            ]} 
          />
        </View>
      </View>
    );
  };

  // Navigation buttons
  const renderNavigationButtons = () => {
    if (presentationMode !== 'guided' || totalSteps <= 1) return null;

    return (
      <View style={styles.navigationContainer}>
        <View style={styles.navigationRow}>
          {!isFirstStep && (
            <TouchableOpacity
              style={[styles.navButton, styles.previousButton]}
              onPress={goToPreviousStep}
              activeOpacity={0.8}
            >
              <Text style={styles.navButtonText}>Previous</Text>
            </TouchableOpacity>
          )}
          
          <View style={styles.spacer} />
          
          {isLastStep ? (
            <TouchableOpacity
              style={[styles.navButton, styles.finishButton]}
              onPress={() => {
                telemetry.track('guide_complete', { guideId, mode });
                navigation.goBack();
              }}
              activeOpacity={0.8}
            >
              <Text style={styles.navButtonText}>Finish</Text>
            </TouchableOpacity>
          ) : (
            <TouchableOpacity
              style={[styles.navButton, styles.nextButton]}
              onPress={goToNextStep}
              activeOpacity={0.8}
            >
              <Text style={styles.navButtonText}>Next</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>
    );
  };

  const renderBlocks = (blocks?: GuideBlock[] | GuideBlock[][]) => {
    if (!blocks || !blocks.length) return null;
    
    // Handle both single blocks and arrays of blocks (for merged content)
    const flatBlocks: GuideBlock[] = Array.isArray(blocks[0]) 
      ? (blocks as GuideBlock[][]).flat() 
      : (blocks as GuideBlock[]);
    
    return flatBlocks.map((b, idx) => {
      try {
        if (b.type === 'heading') {
          return (
            <View key={`b-${idx}`} style={styles.card}>
              <Text style={styles.cardTitle}>{b.text || ''}</Text>
            </View>
          );
        }
        if (b.type === 'paragraph') {
          return (
            <View key={`b-${idx}`} style={styles.card}>
              <Text style={styles.cardBody}>{b.text || ''}</Text>
            </View>
          );
        }
        if (b.type === 'bullet_list') {
          return (
            <View key={`b-${idx}`} style={styles.card}>
              {(b.items || []).map((it, i) => (
                <Text key={`li-${i}`} style={styles.cardBody}>• {it || ''}</Text>
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
                  try {
                    if (b.book && b.chapter) {
                      navigation.navigate('BibleScreen', { book: b.book, chapter: b.chapter, verse: b.verseFrom });
                    }
                  } catch (error) {
                    console.warn('Failed to navigate to scripture:', error);
                  }
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
                  try {
                    const a = b.action;
                    if (!a) return;
                    
                    if (a.type === 'navigate') {
                      const params = (a.params || {}) as any;
                      if (params.route) {
                        navigation.navigate(params.route as any, params.params as any);
                      }
                    } else if (a.type === 'open_bible') {
                      const params = (a.params || {}) as { book?: string; chapter?: number; verse?: number };
                      if (params.book && params.chapter) {
                        navigation.navigate('BibleScreen', { book: params.book, chapter: params.chapter, verse: params.verse });
                      }
                    } else if (a.type === 'open_url') {
                      const url = String((a.params || {}).url || '');
                      if (url) {
                        Linking.openURL(url).catch(() => console.warn('Failed to open URL:', url));
                      }
                    }
                  } catch (error) {
                    console.warn('Failed to execute CTA action:', error);
                  }
                }}
              >
                <Text style={styles.primaryButtonText}>{b.label || 'Action'}</Text>
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
                onPress={() => { 
                  try {
                    playCue(b.cue || 'meditationBell').catch((error) => console.warn('Failed to play audio cue:', error));
                  } catch (error) {
                    console.warn('Audio play error:', error);
                  }
                }}
              >
                <Text style={styles.primaryButtonText}>Play</Text>
              </TouchableOpacity>
            </View>
          );
        }
        if (b.type === 'image') {
          return (
            <View key={`b-${idx}`} style={styles.card}>
              {b.uri ? <Image source={{ uri: b.uri }} style={styles.blockImage} resizeMode="cover" /> : null}
              {b.alt ? <Text style={styles.cardBody}>{b.alt}</Text> : null}
            </View>
          );
        }
        if (b.type === 'quote') {
          return (
            <View key={`b-${idx}`} style={styles.card}>
              <Text style={styles.quoteText}>"{b.text || ''}"</Text>
              {b.attribution ? <Text style={styles.quoteAttribution}>— {b.attribution}</Text> : null}
            </View>
          );
        }
        if (b.type === 'callout') {
          return (
            <View key={`b-${idx}`} style={styles.callout}>
              <Text style={styles.cardBody}>{b.text || ''}</Text>
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
              {(b.items || []).map((it) => {
                const key = `acc-${idx}-${it.id}`;
                const open = !!accordionOpen[key];
                return (
                  <View key={it.id} style={{ marginBottom: theme.spacing.xs }}>
                    <TouchableOpacity
                      style={[styles.modeChip, open && styles.questionOptionSelected]}
                      activeOpacity={0.9}
                      onPress={() => setAccordionOpen(prev => ({ ...prev, [key]: !prev[key] }))}
                    >
                      <Text style={styles.modeText}>{it.title || ''}</Text>
                    </TouchableOpacity>
                    {open && (
                      <View style={{ marginTop: theme.spacing.xs }}>
                        <Text style={styles.cardBody}>{it.body || ''}</Text>
                      </View>
                    )}
                  </View>
                );
              })}
            </View>
          );
        }
        return null;
      } catch (error) {
        console.warn(`Error rendering block type ${b?.type} at index ${idx}:`, error);
        return (
          <View key={`b-${idx}`} style={styles.card}>
            <Text style={styles.cardBody}>Content unavailable</Text>
          </View>
        );
      }
    });
  };

  React.useEffect(() => {
    // Validate params on mount
    if (route?.params?.guideId && typeof route.params.guideId === 'string') {
      setParamsValidated(true);
    } else {
      setError('Invalid guide parameters');
      setParamsValidated(true);
    }
  }, [route?.params]);

  React.useEffect(() => {
    if (!paramsValidated || !guideId) return;
    
    let active = true;
    (async () => {
      try {
        // Validate guideId parameter
        if (!guideId || typeof guideId !== 'string') {
          throw new Error('Invalid guide ID provided');
        }

        if (!guide) {
          await guideStore.fetchGuide(guideId);
        }
        const g = guideStore.definitions[guideId];
        
        // Check if guide was successfully loaded
        if (!g) {
          throw new Error(`Guide with ID "${guideId}" not found`);
        }
        
        if (g.content.mode === 'meditation') {
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
        console.error('Error loading guide:', e);
        if (active) {
          const errorMessage = e instanceof Error ? e.message : 'Failed to load guide';
          setError(errorMessage);
        }
      }
    })();
    return () => { active = false; };
  }, [guideId, guide, paramsValidated]);

  // Load saved bookmark on mount
  React.useEffect(() => {
    if (!bookmarkKey) return;
    let active = true;
    (async () => {
      try {
        const saved = await AsyncStorage.getItem(bookmarkKey);
        if (active) {
          const parsed = saved !== null ? Number(saved) : null;
          setBookmarkedPosition(Number.isFinite(parsed ?? NaN) ? parsed : null);
        }
      } catch (e) {
        console.warn('Failed to load bookmark', e);
      }
    })();
    return () => {
      active = false;
    };
  }, [bookmarkKey]);

  // Load saved presentation mode
  React.useEffect(() => {
    if (!modePreferenceKey) return;
    let active = true;
    (async () => {
      try {
        const saved = await AsyncStorage.getItem(modePreferenceKey);
        if (active && (saved === 'guided' || saved === 'flow')) {
          setPresentationMode(saved);
        }
      } catch (e) {
        console.warn('Failed to load presentation mode', e);
      }
    })();
    return () => {
      active = false;
    };
  }, [modePreferenceKey]);

  // Sync progress from backend once guide is ready
  React.useEffect(() => {
    if (!guideId || !ready) return;
    let active = true;
    (async () => {
      try {
        setIsSyncing(true);
        const progress = await getGuideProgress(guideId);
        if (!active || !progress) {
          return;
        }

        skipSaveRef.current = true;
        if (typeof progress.current_step_index === 'number') {
          setCurrentStepIndex(progress.current_step_index);
        }
        if (typeof progress.bookmarked_step_index === 'number' || progress.bookmarked_step_index === null) {
          setBookmarkedPosition(progress.bookmarked_step_index);
          if (bookmarkKey && progress.bookmarked_step_index !== null) {
            await AsyncStorage.setItem(bookmarkKey, String(progress.bookmarked_step_index));
          }
        }
        if (progress.presentation_mode === 'guided' || progress.presentation_mode === 'flow') {
          setPresentationMode(progress.presentation_mode);
          if (modePreferenceKey) {
            await AsyncStorage.setItem(modePreferenceKey, progress.presentation_mode);
          }
        }
      } catch (error) {
        if (__DEV__) {
          console.warn('Failed to sync guide progress', error);
        }
      } finally {
        if (active) {
          setProgressLoaded(true);
          setIsSyncing(false);
          skipSaveRef.current = false;
        }
      }
    })();
    return () => {
      active = false;
    };
  }, [guideId, ready, bookmarkKey, modePreferenceKey]);

  // Persist progress changes to backend with debounce
  React.useEffect(() => {
    if (!guideId || !progressLoaded) return;
    if (skipSaveRef.current) return;

    if (saveDebounceRef.current) {
      clearTimeout(saveDebounceRef.current);
    }

    saveDebounceRef.current = setTimeout(() => {
      (async () => {
        try {
          setIsSyncing(true);
          await saveGuideProgress(guideId, {
            current_step_index: currentStepIndex,
            presentation_mode: presentationMode,
            bookmarked_step_index: bookmarkedPosition,
          });
        } catch (error) {
          if (__DEV__) {
            console.warn('Failed to persist guide progress', error);
          }
        } finally {
          setIsSyncing(false);
        }
      })();
    }, 500);

    return () => {
      if (saveDebounceRef.current) {
        clearTimeout(saveDebounceRef.current);
      }
    };
  }, [guideId, progressLoaded, currentStepIndex, presentationMode, bookmarkedPosition]);

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

  if (!paramsValidated) {
    return (
      <View style={[styles.container, { paddingTop: insets.top, alignItems: 'center', justifyContent: 'center' }]}> 
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  if (!guideId) {
    return (
      <View style={[styles.container, { paddingTop: insets.top, alignItems: 'center', justifyContent: 'center' }]}> 
        <Text style={styles.loadingText}>{error || 'Invalid guide ID'}</Text>
        <TouchableOpacity 
          style={[styles.primaryButton, { marginTop: theme.spacing.md }]} 
          activeOpacity={0.9} 
          onPress={() => navigation.goBack()}
        >
          <Text style={styles.primaryButtonText}>Go Back</Text>
        </TouchableOpacity>
      </View>
    );
  }

  if (!ready) {
    return (
      <View style={[styles.container, { paddingTop: insets.top, alignItems: 'center', justifyContent: 'center' }]}> 
        <Text style={styles.loadingText}>{error ? error : 'Loading guide...'}</Text>
        {error && (
          <TouchableOpacity 
            style={[styles.primaryButton, { marginTop: theme.spacing.md }]} 
            activeOpacity={0.9} 
            onPress={() => navigation.goBack()}
          >
            <Text style={styles.primaryButtonText}>Go Back</Text>
          </TouchableOpacity>
        )}
      </View>
    );
  }

  if (!guide) {
    return (
      <View style={[styles.container, { paddingTop: insets.top, alignItems: 'center', justifyContent: 'center' }]}> 
        <Text style={styles.loadingText}>Guide not found</Text>
        <TouchableOpacity 
          style={[styles.primaryButton, { marginTop: theme.spacing.md }]} 
          activeOpacity={0.9} 
          onPress={() => navigation.goBack()}
        >
          <Text style={styles.primaryButtonText}>Go Back</Text>
        </TouchableOpacity>
      </View>
    );
  }

  
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
              <View key={p.id || `page-${i}`} style={[styles.slide, { width: windowWidth - theme.spacing.md * 2 }]}> 
                <Text style={styles.cardTitle}>{p.title || ''}</Text>
                <Text style={styles.cardBody}>{p.body || ''}</Text>
              </View>
            ))}
          </ScrollView>
          <View style={styles.paginationRow}>
            {(cfg.pages || []).map((p, i) => (
              <View key={p.id || `dot-${i}`} style={i === pageIndex ? styles.paginationDotActive : styles.paginationDot} />
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
          {(cfg.questions || []).map((q, qi) => {
            const selected = answers[q.id] ?? null;
            const isCorrectOption = submitted ? q.correctIndex : -1;
            return (
              <View key={q.id || `question-${qi}`} style={styles.questionBlock}>
                <Text style={styles.cardBody}>{q.prompt || ''}</Text>
                {(q.options || []).map((opt, oi) => {
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

  const renderReadingSection = (section: ReadingReflectionSection, index: number) => {
    if (!section) return null;
    return (
      <View style={styles.sectionCard}>
        <View style={styles.sectionHeader}>
          <View style={styles.sectionNumber}>
            <Text style={styles.sectionNumberText}>{(index ?? 0) + 1}</Text>
          </View>
          <Text style={styles.sectionTitle}>{section.title}</Text>
        </View>
        <Text style={styles.sectionBody}>{section.body}</Text>
      </View>
    );
  };

  const renderReflectionPrompt = (prompt: string) => {
    if (!prompt) return null;
    return (
      <View style={styles.reflectionCard}>
        <View style={styles.reflectionHeader}>
          <View style={styles.reflectionIcon}>
            <Text style={styles.reflectionIconText}>💭</Text>
          </View>
          <Text style={styles.reflectionTitle}>Take a moment to reflect</Text>
        </View>
        <Text style={styles.reflectionPrompt}>{prompt}</Text>
      </View>
    );
  };

  const renderQuizPage = (page: InteractiveReadingQuizPage) => {
    if (!page) return null;
    return (
      <View style={styles.sectionCard}>
        <Text style={styles.cardTitle}>{page.title}</Text>
        <Text style={styles.sectionBody}>{page.body}</Text>
        <TouchableOpacity
          style={[styles.headerButton, { alignSelf: 'flex-start', marginTop: theme.spacing.sm }]}
          activeOpacity={0.85}
          onPress={() => setShowTOC(true)}
        >
          <Text style={styles.headerButtonText}>View all sections</Text>
        </TouchableOpacity>
      </View>
    );
  };

  const renderQuizQuestions = (cfg: InteractiveReadingQuizConfig) => {
    if (!cfg || !cfg.questions?.length) return null;
    return (
      <View style={styles.card}>
        <View style={styles.quizHeaderRow}>
          <Text style={styles.questionTitle}>Check your understanding</Text>
          <View style={styles.quizProgressPill}>
            <Text style={styles.quizProgressText}>
              {Object.values(answers).filter(v => v !== null).length}/{cfg.questions.length}
            </Text>
          </View>
        </View>
        {cfg.questions.map((q, qi) => {
          const selected = answers[q.id] ?? null;
          const isCorrectOption = submitted ? q.correctIndex : -1;
          return (
            <View key={q.id || `question-${qi}`} style={styles.questionBlock}>
              <Text style={styles.cardBody}>{q.prompt || ''}</Text>
              {(q.options || []).map((opt, oi) => {
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
                    <Text
                      style={[
                        styles.questionOptionText,
                        showCorrect && styles.questionOptionTextCorrect,
                        showIncorrect && styles.questionOptionTextIncorrect,
                      ]}
                    >
                      {opt}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          );
        })}
        <TouchableOpacity
          style={styles.primaryButton}
          activeOpacity={0.9}
          onPress={() => {
            setSubmitted(true);
            try {
              const total = cfg.questions.length;
              const correctCount = cfg.questions.reduce(
                (acc, q) => acc + ((answers[q.id] ?? null) === q.correctIndex ? 1 : 0),
                0
              );
              telemetry.track('guide_quiz_submit', {
                guideId,
                total,
                answered: Object.values(answers).filter(v => v !== null).length,
                correct: correctCount,
              });
            } catch {}
          }}
        >
          <Text style={styles.primaryButtonText}>Check answers</Text>
        </TouchableOpacity>
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
    <GuideErrorBoundary
      onError={(error, errorInfo) => {
        console.error('GuidePlayerScreen error:', error, errorInfo);
        telemetry.track('guide_error', { guideId, error: error.message });
      }}
    >
      <View style={[styles.container, { paddingTop: insets.top }]}> 
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
            <ArrowLeft size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>
          <View style={styles.titleWrapper}>
            <Text style={styles.title}>{guide.title || 'Guide'}</Text>
            <View style={styles.modeToggleRow}>
              <TouchableOpacity
                style={[
                  styles.modeToggleButton,
                  presentationMode === 'guided' && styles.modeToggleButtonActive,
                ]}
                onPress={() => {
                  setPresentationMode('guided');
                  if (modePreferenceKey) AsyncStorage.setItem(modePreferenceKey, 'guided').catch(() => {});
                }}
                activeOpacity={0.85}
              >
                <Text
                  style={[
                    styles.modeToggleText,
                    presentationMode === 'guided' && styles.modeToggleTextActive,
                  ]}
                >
                  Guided
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.modeToggleButton,
                  presentationMode === 'flow' && styles.modeToggleButtonActive,
                ]}
                onPress={() => {
                  setPresentationMode('flow');
                  if (modePreferenceKey) AsyncStorage.setItem(modePreferenceKey, 'flow').catch(() => {});
                }}
                activeOpacity={0.85}
              >
                <Text
                  style={[
                    styles.modeToggleText,
                    presentationMode === 'flow' && styles.modeToggleTextActive,
                  ]}
                >
                  Flow
                </Text>
              </TouchableOpacity>
            </View>
          </View>
          <View style={styles.headerActions}>
            <TouchableOpacity
              style={[styles.headerButton, bookmarkedPosition !== null && styles.headerButtonActive]}
              activeOpacity={0.85}
              onPress={toggleBookmark}
            >
              <Text style={styles.headerButtonText}>
                {bookmarkedPosition !== null ? 'Saved' : 'Save'}
              </Text>
            </TouchableOpacity>
            {bookmarkedPosition !== null && (
              <TouchableOpacity
                style={styles.headerButton}
                activeOpacity={0.85}
                onPress={jumpToBookmark}
              >
                <Text style={styles.headerButtonText}>Bookmark</Text>
              </TouchableOpacity>
            )}
            <TouchableOpacity
              style={[styles.headerButton, showTOC && styles.headerButtonActive]}
              activeOpacity={0.85}
              onPress={() => setShowTOC(prev => !prev)}
            >
              <Text style={styles.headerButtonText}>Guide</Text>
            </TouchableOpacity>
          </View>
        </View>

        <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
          {renderProgressIndicator()}
          {renderTableOfContents()}
          {renderContent()}
          {renderNavigationButtons()}
        </ScrollView>
      </View>
    </GuideErrorBoundary>
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
  titleWrapper: {
    flex: 1,
    marginHorizontal: theme.spacing.sm,
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  headerButton: {
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.surface,
  },
  headerButtonActive: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
  },
  headerButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  modeToggleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    marginTop: theme.spacing.xs,
  },
  modeToggleButton: {
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  modeToggleButtonActive: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}12`,
  },
  modeToggleText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    fontWeight: '600',
  },
  modeToggleTextActive: {
    color: theme.colors.primary,
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
  // Progress indicator styles
  progressContainer: {
    alignItems: 'center',
    marginBottom: theme.spacing.lg,
  },
  progressText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.sm,
  },
  progressBar: {
    width: '100%',
    height: 4,
    backgroundColor: theme.colors.border,
    borderRadius: 2,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: theme.colors.primary,
    borderRadius: 2,
  },
  // Navigation styles
  navigationContainer: {
    marginTop: theme.spacing.lg,
    paddingTop: theme.spacing.lg,
  },
  navigationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  spacer: {
    flex: 1,
  },
  navButton: {
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    minWidth: 100,
    alignItems: 'center',
  },
  previousButton: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  nextButton: {
    backgroundColor: theme.colors.primary,
  },
  finishButton: {
    backgroundColor: theme.colors.success,
  },
  navButtonText: {
    ...theme.typography.caption.primary,
    fontWeight: '600',
  },
  // Enhanced progress styles
  circularProgress: {
    marginRight: theme.spacing.md,
  },
  progressCircle: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  progressRing: {
    position: 'absolute',
    width: 40,
    height: 40,
    borderRadius: 20,
    borderWidth: 3,
    borderColor: theme.colors.border,
  },
  progressRingFill: {
    position: 'absolute',
    top: 0,
    left: 0,
  },
  progressPercentage: {
    ...theme.typography.caption.primary,
    fontSize: 10,
    fontWeight: '700',
    color: theme.colors.text.primary,
  },
  progressInfo: {
    flex: 1,
    justifyContent: 'center',
  },
  readingTime: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.tertiary,
    fontSize: 11,
  },
  tocContainer: {
    marginBottom: theme.spacing.lg,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: theme.spacing.sm,
  },
  tocHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  tocTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    fontWeight: '700',
    fontSize: theme.typography.heading.small.fontSize ? theme.typography.heading.small.fontSize - 2 : 16,
  },
  tocRow: {
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  tocRowActive: {
    backgroundColor: `${theme.colors.primary}10`,
  },
  tocRowCompleted: {
    opacity: 0.7,
  },
  tocRowLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    flex: 1,
  },
  tocIndex: {
    ...theme.typography.caption.primary,
    fontWeight: '700',
    color: theme.colors.primary,
  },
  tocText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    flex: 1,
  },
  tocReadingTime: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  tocBookmark: {
    marginTop: theme.spacing.sm,
    padding: theme.spacing.sm,
    borderRadius: theme.borderRadius.md,
    backgroundColor: `${theme.colors.primary}08`,
  },
  tocBookmarkText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
});

export default observer(GuidePlayerScreen);
