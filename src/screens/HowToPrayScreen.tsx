import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Dimensions, NativeScrollEvent, NativeSyntheticEvent } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import type { Theme } from '@/theme';
import type { RootStackParamList } from '@/types';
import { ArrowLeft } from '@/components/Icons';
import { getGuideById, InteractiveReadingQuizConfig } from '@/services/GuideService';
import Animated, { FadeInDown, FadeIn } from 'react-native-reanimated';

export type HowToPrayScreenProps = NativeStackScreenProps<RootStackParamList, 'HowToPrayScreen'>;

const HowToPrayScreen = ({ navigation }: HowToPrayScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const windowWidth = Dimensions.get('window').width;
  const [pageIndex, setPageIndex] = React.useState(0);
  const [pages, setPages] = React.useState<InteractiveReadingQuizConfig['pages']>([]);
  const [questions, setQuestions] = React.useState<InteractiveReadingQuizConfig['questions']>([]);
  const [howAnswers, setHowAnswers] = React.useState<Record<string, number | null>>({});
  const [howSubmitted, setHowSubmitted] = React.useState(false);

  React.useEffect(() => {
    let isActive = true;

    const loadGuide = async () => {
      try {
        const guide = await getGuideById('how-to-pray');
        if (!guide) return;
        if (guide.content.mode !== 'interactive_reading_quiz') return;
        const cfg = guide.content as InteractiveReadingQuizConfig;
        if (isActive) {
          setPages(cfg.pages || []);
          setQuestions(cfg.questions || []);
        }
      } catch {
        // ignore
      }
    };

    void loadGuide();

    return () => {
      isActive = false;
    };
  }, []);

  const handleScrollEnd = (event: NativeSyntheticEvent<NativeScrollEvent>) => {
    const { contentOffset, layoutMeasurement } = event.nativeEvent;
    const index = Math.round(contentOffset.x / layoutMeasurement.width);
    setPageIndex(index);
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}> 
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>How to Pray</Text>
        <View style={{ width: 24 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <Text style={styles.introTitle}>Quiet your heart before the Lord</Text>
        <Text style={styles.introBody}>
          Walk slowly through a few short reflections, then answer questions to check that
          you have really received the heart of this guide.
        </Text>

        <View style={styles.carouselContainer}>
          <ScrollView
            horizontal
            pagingEnabled
            showsHorizontalScrollIndicator={false}
            onMomentumScrollEnd={handleScrollEnd}
          >
            {pages.map((page, index) => (
              <Animated.View
                key={page.id}
                entering={FadeInDown.delay(index * 80).duration(300)}
                style={[styles.slide, { width: windowWidth - theme.spacing.md * 2 }]}
              > 
                <Text style={styles.cardTitle}>{page.title}</Text>
                <Text style={styles.cardBody}>{page.body}</Text>
              </Animated.View>
            ))}
          </ScrollView>
          <View style={styles.paginationRow}>
            {pages.map((page, index) => (
              <View
                key={page.id}
                style={index === pageIndex ? styles.paginationDotActive : styles.paginationDot}
              />
            ))}
          </View>
        </View>

        <View style={styles.questionCard}>
          <View style={styles.quizHeaderRow}>
            <Text style={styles.questionTitle}>Check your understanding</Text>
            {questions.length > 0 && (
              <View style={styles.quizProgressPill}>
                <Text style={styles.quizProgressText}>
                  {Object.values(howAnswers).filter(v => v !== null).length}/{questions.length}
                </Text>
              </View>
            )}
          </View>
          {questions.map((question, index) => {
            const selected = howAnswers[question.id] ?? null;
            return (
              <Animated.View
                key={question.id}
                entering={FadeIn.delay(100 + index * 60).duration(250)}
                style={styles.questionBlock}
              >
                <Text style={styles.cardBody}>{question.prompt}</Text>
                {question.options.map((option, index) => {
                  const isSelected = selected === index;
                  const isCorrectOption = howSubmitted && index === question.correctIndex;
                  const isIncorrectSelected =
                    howSubmitted && isSelected && index !== question.correctIndex;
                  return (
                    <TouchableOpacity
                      key={index}
                      style={[
                        styles.questionOption,
                        isSelected && styles.questionOptionSelected,
                        isCorrectOption && styles.questionOptionCorrect,
                        isIncorrectSelected && styles.questionOptionIncorrect,
                      ]}
                      activeOpacity={0.85}
                      onPress={() => {
                        setHowSubmitted(false);
                        setHowAnswers(prev => ({ ...prev, [question.id]: index }));
                      }}
                    >
                      <Text
                        style={[
                          styles.questionOptionText,
                          isCorrectOption && styles.questionOptionTextCorrect,
                          isIncorrectSelected && styles.questionOptionTextIncorrect,
                        ]}
                      >
                        {option}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
                {howSubmitted && selected !== null && (
                  <Text
                    style={
                      selected === question.correctIndex
                        ? styles.questionFeedbackCorrect
                        : styles.questionFeedbackIncorrect
                    }
                  >
                    {selected === question.correctIndex
                      ? 'Beautiful - this lines up with the heart of this guide.'
                      : 'Pause and reread the reflections above, then try again.'}
                  </Text>
                )}
              </Animated.View>
            );
          })}
          <TouchableOpacity
            style={styles.primaryButton}
            activeOpacity={0.9}
            onPress={() => setHowSubmitted(true)}
          >
            <Text style={styles.primaryButtonText}>Check answers</Text>
          </TouchableOpacity>
        </View>
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
  introTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  introBody: {
    ...theme.typography.caption.secondary,
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
  cardPrayerHeading: {
    marginTop: theme.spacing.sm,
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  cardPrayer: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
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
  questionCard: {
    marginTop: theme.spacing.md,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: theme.spacing.sm,
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
  questionFeedbackCorrect: {
    ...theme.typography.caption.primary,
    color: theme.colors.success,
  },
  questionFeedbackIncorrect: {
    ...theme.typography.caption.primary,
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
});

export default observer(HowToPrayScreen);
