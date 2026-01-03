import { StyleSheet } from 'react-native';
import { Theme } from '@/theme';

const createStyles = (theme: Theme) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.colors.background,
      padding: theme.spacing.md,
    },
    gradientBg: {
      ...StyleSheet.absoluteFillObject,
    },

    // Loading and Error
    loadingOverlay: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: 'rgba(0,0,0,0.5)',
      justifyContent: 'center',
      alignItems: 'center',
      zIndex: 10,
    },
    loadingText: {
      color: theme.colors.primary,
      marginTop: theme.spacing.sm,
    },
    errorContainer: {
      padding: theme.spacing.md,
      backgroundColor: `${theme.colors.error}20`,
      borderRadius: theme.borderRadius.md,
      marginVertical: theme.spacing.lg,
      alignItems: 'center',
    },
    errorText: {
      color: theme.colors.error,
      marginBottom: theme.spacing.md,
      textAlign: 'center',
    },

    // Virtue Selector
    virtueSelectorContainer: {
      padding: theme.spacing.md,
      alignItems: 'center',
    },
    title: {
      fontSize: 24,
      fontWeight: 'bold',
      color: theme.colors.text.primary,
      marginBottom: theme.spacing.xs,
      textAlign: 'center',
    },
    subtitle: {
      fontSize: 16,
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.lg,
      textAlign: 'center',
    },
    virtueGrid: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      justifyContent: 'center',
      gap: theme.spacing.sm,
    },
    virtueButton: {
      backgroundColor: theme.colors.surface,
      paddingVertical: theme.spacing.md,
      paddingHorizontal: theme.spacing.lg,
      borderRadius: theme.borderRadius.md,
      margin: theme.spacing.xs,
      minWidth: 120,
      alignItems: 'center',
      position: 'relative',
    },
    virtueButtonText: {
      color: theme.colors.text.primary,
      fontSize: 16,
      fontWeight: '500',
    },
    completedVirtueButton: {
      backgroundColor: `${theme.colors.success}20`,
    },
    completedVirtueText: {
      color: theme.colors.success,
    },
    completedBadge: {
      position: 'absolute',
      top: -5,
      right: -5,
      backgroundColor: theme.colors.success,
      width: 20,
      height: 20,
      borderRadius: 10,
      justifyContent: 'center',
      alignItems: 'center',
    },
    completedBadgeText: {
      color: '#FFF',
      fontSize: 12,
      fontWeight: 'bold',
    },
    virtueScoreText: {
      fontSize: 12,
      color: theme.colors.text.secondary,
      marginTop: 4,
    },

    // Level Info
    levelInfoContainer: {
      width: '100%',
      padding: theme.spacing.md,
      marginBottom: theme.spacing.lg,
      backgroundColor: `${theme.colors.primary}10`,
      borderRadius: theme.borderRadius.md,
      alignItems: 'center',
    },
    levelText: {
      fontSize: 18,
      fontWeight: '600',
      color: theme.colors.primary,
      marginBottom: theme.spacing.sm,
    },
    levelProgressText: {
      fontSize: 14,
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.sm,
    },
    levelProgressBarContainer: {
      width: '100%',
      height: 8,
      backgroundColor: `${theme.colors.primary}20`,
      borderRadius: 4,
      overflow: 'hidden',
    },
    levelProgressBar: {
      height: '100%',
      backgroundColor: theme.colors.primary,
    },

    // Header
    header: {
      marginBottom: theme.spacing.lg,
    },
    headerTopRow: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginBottom: theme.spacing.sm,
    },
    headerTitle: {
      fontSize: 20,
      fontWeight: '700',
      color: theme.colors.text.primary,
    },
    soundButton: {
      paddingVertical: 6,
      paddingHorizontal: theme.spacing.sm,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.primary}20`,
    },
    soundButtonText: {
      color: theme.colors.primary,
      fontWeight: '600',
    },
    metricRow: {
      flexDirection: 'row',
      gap: theme.spacing.sm,
    },
    metricCard: {
      flex: 1,
      backgroundColor: `${theme.colors.surface}D0`,
      borderRadius: theme.borderRadius.lg,
      paddingVertical: theme.spacing.md,
      paddingHorizontal: theme.spacing.md,
      alignItems: 'center',
      justifyContent: 'center',
      overflow: 'hidden',
      borderWidth: 1,
      borderColor: `${theme.colors.primary}20`,
    },
    metricGradient: {
      ...StyleSheet.absoluteFillObject,
    },
    metricLabel: {
      fontSize: 12,
      textTransform: 'uppercase',
      letterSpacing: 1,
      marginTop: theme.spacing.xs,
      color: 'rgba(255,255,255,0.9)',
    },
    metricValue: {
      fontSize: 20,
      fontWeight: '800',
      color: '#FFF',
      marginTop: 4,
    },
    newBadge: {
      position: 'absolute',
      top: 8,
      right: 8,
      backgroundColor: 'rgba(255,255,255,0.15)',
      borderRadius: theme.borderRadius.full,
      paddingVertical: 2,
      paddingHorizontal: 8,
    },
    newBadgeText: {
      fontSize: 10,
      letterSpacing: 0.8,
      color: '#FFF',
      fontWeight: '700',
    },

    // Timer
    timerContainer: {
      marginBottom: theme.spacing.md,
    },
    timerLabel: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
      marginBottom: theme.spacing.xs,
    },
    timerText: {
      marginLeft: theme.spacing.xs,
      color: theme.colors.text.primary,
      fontWeight: '600',
    },
    progressBarContainer: {
      height: 4,
      width: '100%',
      backgroundColor: `${theme.colors.text.secondary}20`,
      borderRadius: theme.borderRadius.full,
      overflow: 'hidden',
    },
    progressBar: {
      height: '100%',
      borderRadius: theme.borderRadius.full,
    },

    // Question
    progressHeader: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      marginBottom: theme.spacing.md,
    },
    progressText: {
      color: theme.colors.text.secondary,
      fontSize: 14,
    },
    scoreText: {
      color: theme.colors.primary,
      fontWeight: '500',
      fontSize: 14,
    },
    questionContainer: {
      backgroundColor: theme.colors.surface,
      borderRadius: theme.borderRadius.lg,
      padding: theme.spacing.md,
      marginBottom: theme.spacing.md,
      ...theme.shadows.md,
    },
    questionText: {
      fontSize: 18,
      fontWeight: '500',
      color: theme.colors.text.primary,
      marginBottom: theme.spacing.md,
      textAlign: 'center',
    },
    verseContainer: {
      backgroundColor: `${theme.colors.primary}08`,
      borderRadius: theme.borderRadius.md,
      padding: theme.spacing.md,
      marginBottom: theme.spacing.lg,
    },
    verseText: {
      fontSize: 16,
      lineHeight: 24,
      color: theme.colors.text.primary,
      fontStyle: 'italic',
      textAlign: 'center',
    },
    optionsContainer: {
      gap: theme.spacing.sm,
    },
    nextButtonRow: {
      marginTop: theme.spacing.md,
      alignItems: 'center',
    },
    nextButton: {
      marginTop: theme.spacing.sm,
      alignSelf: 'center',
      paddingVertical: theme.spacing.sm,
      paddingHorizontal: theme.spacing.lg,
      borderRadius: theme.borderRadius.full,
      backgroundColor: theme.colors.primary,
    },
    nextButtonText: {
      ...theme.typography.body.sans,
      color: '#FFF',
      fontWeight: '700',
    },
    optionButton: {
      backgroundColor: `${theme.colors.surface}80`,
      borderWidth: 1,
      borderColor: `${theme.colors.primary}30`,
      borderRadius: theme.borderRadius.md,
      padding: theme.spacing.md,
      alignItems: 'center',
    },
    optionText: {
      fontSize: 16,
      color: theme.colors.text.primary,
      fontWeight: '500',
    },
    correctOption: {
      backgroundColor: `${theme.colors.success}20`,
      borderColor: theme.colors.success,
    },
    correctOptionText: {
      color: theme.colors.success,
      fontWeight: 'bold',
    },
    incorrectOption: {
      backgroundColor: `${theme.colors.error}20`,
      borderColor: theme.colors.error,
    },
    incorrectOptionText: {
      color: theme.colors.error,
      fontWeight: 'bold',
    },
    correctAnswerText: {
      marginTop: theme.spacing.md,
      color: theme.colors.success,
      fontWeight: '500',
      textAlign: 'center',
    },

    // Success Overlay
    successOverlay: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: 'rgba(0,0,0,0.3)',
      justifyContent: 'center',
      alignItems: 'center',
      zIndex: 5,
    },
    successContent: {
      ...theme.shadows.md,
      backgroundColor: 'rgba(255,255,255,0.9)',
      paddingVertical: theme.spacing.md,
      paddingHorizontal: theme.spacing.lg,
      borderRadius: theme.borderRadius.lg,
      elevation: 5,
    },
    successText: {
      color: theme.colors.success,
      fontSize: 24,
      fontWeight: 'bold',
    },

    // Game Over
    gameOverContainer: {
      flex: 1,
      backgroundColor: theme.colors.surface,
      borderRadius: theme.borderRadius.lg,
      padding: theme.spacing.lg,
      alignItems: 'center',
      justifyContent: 'space-between',
      shadowColor: theme.colors.shadow,
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.1,
      shadowRadius: 4,
      elevation: 2,
    },
    gameOverTitle: {
      fontSize: 28,
      fontWeight: 'bold',
      color: theme.colors.primary,
      marginBottom: theme.spacing.lg,
    },
    resultsSummary: {
      width: '100%',
      alignItems: 'center',
      backgroundColor: `${theme.colors.background}80`,
      borderRadius: theme.borderRadius.md,
      padding: theme.spacing.md,
      marginBottom: theme.spacing.lg,
    },
    virtueResultText: {
      fontSize: 18,
      color: theme.colors.text.primary,
      marginBottom: theme.spacing.md,
    },
    highlightText: {
      color: theme.colors.primary,
      fontWeight: '600',
    },
    finalScoreText: {
      fontSize: 24,
      fontWeight: 'bold',
      color: theme.colors.primary,
      marginBottom: theme.spacing.md,
    },
    correctnessContainer: {
      width: '100%',
      marginBottom: theme.spacing.md,
    },
    correctnessText: {
      fontSize: 16,
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.sm,
      textAlign: 'center',
    },
    correctnessBar: {
      width: '100%',
      height: 8,
      backgroundColor: `${theme.colors.text.secondary}20`,
      borderRadius: 4,
      overflow: 'hidden',
    },
    correctnessProgress: {
      height: '100%',
      backgroundColor: theme.colors.primary,
    },
    passedContainer: {
      padding: theme.spacing.sm,
      backgroundColor: `${theme.colors.success}20`,
      borderRadius: theme.borderRadius.md,
      alignItems: 'center',
      width: '100%',
    },
    passedText: {
      color: theme.colors.success,
      fontWeight: '600',
    },
    failedContainer: {
      padding: theme.spacing.sm,
      backgroundColor: `${theme.colors.warning}20`,
      borderRadius: theme.borderRadius.md,
      alignItems: 'center',
      width: '100%',
    },
    failedText: {
      color: theme.colors.warning,
      fontWeight: '600',
    },
    statsContainer: {
      width: '100%',
      marginVertical: theme.spacing.md,
      alignItems: 'center',
    },
    statsText: {
      fontSize: 16,
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.xs,
    },
    levelProgressInfoContainer: {
      width: '100%',
      padding: theme.spacing.md,
      backgroundColor: `${theme.colors.primary}10`,
      borderRadius: theme.borderRadius.md,
      marginBottom: theme.spacing.md,
      alignItems: 'center',
    },
    levelProgressInfoText: {
      color: theme.colors.text.primary,
      marginBottom: theme.spacing.xs,
      textAlign: 'center',
    },
    levelMaxText: {
      color: theme.colors.primary,
      fontWeight: '600',
      textAlign: 'center',
    },
    retryButton: {
      backgroundColor: theme.colors.primary,
      paddingVertical: theme.spacing.md,
      paddingHorizontal: theme.spacing.lg,
      borderRadius: theme.borderRadius.full,
      marginTop: theme.spacing.md,
    },
    retryButtonText: {
      color: '#FFF',
    },
  });

export default createStyles;
