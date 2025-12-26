import React, { useMemo, useState, useCallback } from "react"
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  FlatList,
  ActivityIndicator,
  useWindowDimensions,
  Modal,
} from "react-native"
import { useSafeAreaInsets } from "react-native-safe-area-context"
import { observer } from "mobx-react-lite"
import { useTheme } from "@/contexts/ThemeContext"
import type { Theme } from "@/theme"
import { useJourneyStore, useDailyPathStore } from "@/stores/StoreProvider"
import { useBibleStore } from "@/stores/BibleStore"
import { useNavigation } from "@react-navigation/native"
import type { NativeStackNavigationProp } from "@react-navigation/native-stack"
import type { RootStackParamList, Activity as JourneyActivity } from "@/types"
import {
  ArrowLeft,
  Check,
  Lock,
  User,
  Crown,
  Star,
  Flame,
  Heart,
  X as CrossIcon,
  Dove,
  Book,
  Lightning,
  Trophy,
  CheckCircle,
  RefreshCw,
  Sun,
  Award,
  HeartHandshake,
  Eye,
  BookIcon,
  Settings,
  BookOpen,
  NotePencil,
  Shield,
} from "@/components/Icons"
import JourneyHero from "@/components/JourneyHero"
import { Animated } from 'react-native';
import ReadingPlanSetupModal from '@/components/ReadingPlanSetupModal';
import { ReadingPlanMode, ReadingPlanPhase } from '@/constants/readingPlanModes';
import type { DailyFocusKey } from '@/stores/DailyPathStore';

const MyJourneyScreen = observer(() => {
  const insets = useSafeAreaInsets()
  const theme = useTheme()
  const styles = useMemo(() => createStyles(theme), [theme])
  const journeyStore = useJourneyStore()
  const dailyPathStore = useDailyPathStore()
  const bibleStore = useBibleStore()
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>()
  const { width } = useWindowDimensions()
  const isCompact = width < 360
  const [showConfigurationModal, setShowConfigurationModal] = useState(false)
  const [showReadingPlanModal, setShowReadingPlanModal] = useState(false)

  React.useEffect(() => {
    journeyStore.fetchActivities()
  }, [journeyStore])

  const activeQuizQuestion =
    journeyStore.quizState.currentIndex < journeyStore.quizState.questions.length
      ? journeyStore.quizState.questions[journeyStore.quizState.currentIndex]
      : null
  const activities = Array.isArray(journeyStore.activities) ? journeyStore.activities : []

  // Journey phase icons mapping with more distinct icons
  const getPhaseIcon = (phaseId: string, isCompleted = false) => {
    const iconProps = { 
      size: 20, 
      color: isCompleted ? theme.colors.success : theme.colors.text.secondary 
    }
    
    // Enhanced icon set with better visual distinction
    switch (phaseId) {
      case "accept-jesus":
        return <CrossIcon {...iconProps} />
      case "repentance":
        return <RefreshCw {...iconProps} />  // Changed from Heart to RefreshCw for better distinction
      case "activation-holy-spirit":
        return <Lightning {...iconProps} />  // More dynamic than Dove
      case "bearing-fruits":
        return <Sun {...iconProps} />  // Changed from Flame to Sun for growth metaphor
      case "storing-treasures":
        return <Award {...iconProps} />  // More specific than Crown
      case "giving-of-self":
        return <HeartHandshake {...iconProps} />  // More specific than Heart
      case "divine-visions":
        return <Eye {...iconProps} />  // More specific than Star
      default:
        return <BookIcon {...iconProps} />
    }
  }

  // Configuration module options
  const focusOptions: {
    key: DailyFocusKey;
    title: string;
    short: string;
    description: string;
    icon: React.ComponentType<{ size?: number; color?: string }>;
  }[] = [
    {
      key: 'revive',
      title: 'Revive My Spiritual Life',
      short: 'Develop a working personal relationship with God',
      description: 'Receive gentle guidance to rekindle devotion, prayer, and personal time with God.',
      icon: Flame,
    },
    {
      key: 'meditation',
      title: 'Relax & Meditate with God',
      short: 'Tame the mind and refresh the spirit',
      description: 'Use breathing, reflection, and scripture meditation to slow down with the Spirit.',
      icon: Heart,
    },
    {
      key: 'knowledge',
      title: 'Deepen My Faith Knowledge',
      short: 'Study scripture daily',
      description: 'Explore curated Bible readings and insights to strengthen your understanding.',
      icon: BookOpen,
    },
    {
      key: 'habits',
      title: 'Discipleship',
      short: 'Daily challenges',
      description: 'Set daily challenges to help others, grow your faith and gain spiritual wealth.',
      icon: NotePencil,
    },
    {
      key: 'habit_conquest',
      title: 'Conquer Harmful Habits',
      short: 'Break patterns stealing your devotion',
      description: 'Engage daily precepts that expose worldly distortions and align with God\'s design.',
      icon: Shield,
    },
  ]

  const [selectedFocuses, setSelectedFocuses] = useState<DailyFocusKey[]>(
    dailyPathStore.primaryFocus ? [dailyPathStore.primaryFocus, ...dailyPathStore.secondaryFocus.filter(item => item !== dailyPathStore.primaryFocus)] : dailyPathStore.secondaryFocus
  )
  const [enableChallenges, setEnableChallenges] = useState<boolean>(dailyPathStore.isChallengesEnabled)
  const [isSaving, setIsSaving] = useState(false)

  const toggleFocusSelection = useCallback((focus: DailyFocusKey) => {
    setSelectedFocuses(prev => {
      const exists = prev.includes(focus);
      if (exists) {
        const next = prev.filter(item => item !== focus);
        if (focus === 'habits') {
          setEnableChallenges(false);
        }
        return next;
      }
      const next = prev.length >= 4 ? [prev[1], prev[2], prev[3], focus] : [...prev, focus];
      if (focus === 'habits') {
        setEnableChallenges(true);
      }
      return next;
    });
  }, []);

  const handleSaveConfiguration = useCallback(async () => {
    if (isSaving) return;
    setIsSaving(true);
    try {
      const [firstFocus, secondFocus] = selectedFocuses;
      const remaining = selectedFocuses.slice(1);
      dailyPathStore.setFocuses(firstFocus ?? 'revive', remaining);

      if (selectedFocuses.includes('habits')) {
        dailyPathStore.setChallengesEnabled(true);
        dailyPathStore.setViewedChallengeSelection(true);
        dailyPathStore.setChallengeOnboardingCompleted(false);
        setEnableChallenges(true);
      } else {
        dailyPathStore.setChallengesEnabled(enableChallenges);
      }

      dailyPathStore.markSetupComplete();
      setShowConfigurationModal(false);
    } finally {
      setIsSaving(false);
    }
  }, [dailyPathStore, enableChallenges, selectedFocuses]);

  const handleCreatePlan = useCallback(async ({ books, timePerDay, readingMode, phases, reminderTime, presetIds, minChaptersPerDay, maxChaptersPerDay, readingPaceWpm }: { books: string[]; timePerDay: number; readingMode: ReadingPlanMode; phases: ReadingPlanPhase[]; reminderTime?: string; presetIds?: string[]; minChaptersPerDay?: number; maxChaptersPerDay?: number; readingPaceWpm?: number }) => {
    try {
      await bibleStore.createReadingPlan({
        books,
        timePerDay,
        readingMode,
        phases,
        reminderTime: reminderTime ?? null,
        presetIds,
        minChaptersPerDay,
        maxChaptersPerDay,
        readingPaceWpm,
      });
      journeyStore.setBiblePlan({
        id: bibleStore.readingPlan?.id ?? '',
        books,
        timePerDay,
        readingMode,
        phases,
        reminderTime: reminderTime ?? null,
        presetIds: presetIds ?? [],
        focusVirtue: bibleStore.readingPlan?.focusVirtue ?? null,
      } as any);
    } finally {
      setShowReadingPlanModal(false);
    }
  }, [bibleStore, journeyStore]);

  const readingPlan = bibleStore.readingPlan;
  const readingModeLabel = useMemo(() => {
    const id = readingPlan?.readingMode;
    if (id === 'lectio_divina') return 'Lectio Divina';
    if (id === 'reading_meditation') return 'Reading + Meditation';
    return id ? 'Reading' : '';
  }, [readingPlan?.readingMode]);
  const habit = dailyPathStore.state.habitConquest;
  
  // Celebration component for when a phase is completed
  const PhaseCompleteCelebration = React.memo(() => {
    if (!journeyStore.justCompletedPhase) return null;
    
    return (
      <Animated.View 
        style={[
          styles.celebrationOverlay,
          { backgroundColor: theme.colors.background + 'E6' } // Slightly transparent
        ]}
      >
        <View style={styles.celebrationContent}>
          <View style={[styles.celebrationIcon, { backgroundColor: theme.colors.primary + '20' }]}>
            <CheckCircle size={64} color={theme.colors.success} />
          </View>
          <Text style={[theme.typography.heading.medium, styles.celebrationText]}>
            Phase Complete!
          </Text>
          <Text style={[theme.typography.body.sans, styles.celebrationSubtext]}>
            You're one step closer to your spiritual growth
          </Text>
          <TouchableOpacity 
            style={[styles.celebrationButton, { backgroundColor: theme.colors.primary }]}
            onPress={() => journeyStore.clearJustCompletedPhase()}
          >
            <Text style={[theme.typography.button.primary, { color: theme.colors.text.inverse }]}>
              Continue Journey
            </Text>
          </TouchableOpacity>
        </View>
      </Animated.View>
    );
  });

  // Calculate overall progress
  const completedPhases = journeyStore.journeyPhases.filter((p) => p.status === "completed").length
  const totalPhases = journeyStore.journeyPhases.length
  const overallProgress = totalPhases > 0 ? (completedPhases / totalPhases) * 100 : 0

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>My Kingdom Journey</Text>
        <View style={styles.headerButtons}>
          <TouchableOpacity
            onPress={() => setShowConfigurationModal(true)}
            style={styles.configButton}
            accessibilityLabel="Configure daily path"
          >
            <Settings size={22} color={theme.colors.text.primary} />
          </TouchableOpacity>
          <TouchableOpacity
            onPress={() => navigation.navigate("ProfileScreen")}
            style={styles.profileButton}
            accessibilityLabel="View profile"
          >
            <User size={22} color={theme.colors.text.primary} />
          </TouchableOpacity>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.hero}>
          <View style={styles.starContainer}>
            <JourneyHero progress={overallProgress} />
          </View>
          
          <Text style={styles.heroTitle}>Your Kingdom Citizenship Journey</Text>
          <Text style={styles.heroSubtitle}>
            {completedPhases < 2 
              ? "The journey to becoming a true citizen of God's kingdom begins with understanding your inheritance."
              : completedPhases === totalPhases 
              ? "You have inherited the rights and responsibilities of Kingdom citizenship."
              : completedPhases > 5 
              ? "Your purpose is blossoming as you unite your will with God's plan."
              : `Continue submitting and uniting your will with God for your purpose to fully blossom.`
            }
          </Text>
          
          <Text style={styles.progressText}>
            {Math.round(overallProgress)}% Ready for Kingdom Citizenship • {completedPhases} of {totalPhases} phases completed
          </Text>

          {!dailyPathStore.isSetupComplete && (
            <TouchableOpacity
              style={styles.reconfigureButton}
              onPress={() => setShowConfigurationModal(true)}
              accessibilityLabel="Set up daily path"
            >
              <Text style={styles.reconfigureButtonText}>Set up daily path</Text>
            </TouchableOpacity>
          )}
          
          {dailyPathStore.isSetupComplete && (
            <TouchableOpacity
              style={styles.reconfigureButton}
              onPress={() => setShowConfigurationModal(true)}
              accessibilityLabel="Reconfigure daily path"
            >
              <Text style={styles.reconfigureButtonText}>Configure daily path</Text>
            </TouchableOpacity>
          )}
        </View>

        {/* Motivational Quote Section */}
        {/* {completedPhases > 0 && completedPhases < totalPhases && (
          <View style={styles.motivationCard}>
            <View style={styles.motivationIcon}>
              <Book size={24} color={theme.colors.primary} />
            </View>
            <Text style={styles.motivationQuote}>"The journey of a thousand miles begins with a single step."</Text>
            <Text style={styles.motivationAuthor}>- Lao Tzu</Text>
          </View>
        )} */}

        {/* Achievement Celebration */}
        {completedPhases === totalPhases && completedPhases > 0 && (
          <View style={styles.achievementCard}>
            <View style={styles.achievementIcon}>
              <Trophy size={32} color={theme.colors.success} />
            </View>
            <Text style={styles.achievementTitle}>Journey Complete!</Text>
            <Text style={styles.achievementSubtitle}>
              Congratulations on completing your spiritual journey. You've grown tremendously!
            </Text>
            <View style={styles.achievementActions}>
              <TouchableOpacity style={styles.achievementButton}>
                <Text style={styles.achievementButtonText}>Share Achievement</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        {/* Enhanced Phase Details */}
        <View style={styles.phasesSection}>
          <Text style={styles.sectionTitle}>Kingdom Citizenship Phases</Text>
          <View style={styles.phasesGrid}>
            {journeyStore.journeyPhases.map((phase) => {
              const status = phase.status
              const isActive = journeyStore.quizState.activePhaseId === phase.id && !journeyStore.quizState.isComplete
              const isCompleted = status === "completed"
              const isLocked = status === "locked"

              return (
                <TouchableOpacity
                  key={phase.id}
                  style={[
                    styles.enhancedPhaseCard,
                    isCompleted && styles.enhancedPhaseCardCompleted,
                    isActive && styles.enhancedPhaseCardActive,
                    isLocked && styles.enhancedPhaseCardLocked,
                  ]}
                  disabled={isLocked}
                  onPress={() => navigation.navigate("JourneyQuizScreen", { phaseId: phase.id })}
                >
                  <View style={styles.enhancedPhaseHeader}>
                    <View style={styles.enhancedPhaseIcon}>{getPhaseIcon(phase.id, isCompleted)}</View>
                    <View style={styles.enhancedPhaseStatus}>
                      {isCompleted ? (
                        <View style={styles.completedBadge}>
                          <Check size={14} color={theme.colors.success} />
                          <Text style={styles.completedBadgeText}>Completed</Text>
                        </View>
                      ) : isLocked ? (
                        <View style={styles.lockedBadge}>
                          <Lock size={14} color={theme.colors.text.secondary} />
                          <Text style={styles.lockedBadgeText}>Locked</Text>
                        </View>
                      ) : isActive ? (
                        <View style={styles.activeBadge}>
                          <Lightning size={14} color={theme.colors.primary} />
                          <Text style={styles.activeBadgeText}>In Progress</Text>
                        </View>
                      ) : (
                        <View style={styles.availableBadge}>
                          <Text style={styles.availableBadgeText}>Available</Text>
                        </View>
                      )}
                    </View>
                  </View>

                  <Text
                    style={[
                      styles.enhancedPhaseTitle,
                      isCompleted && styles.enhancedPhaseTitleCompleted,
                      isActive && styles.enhancedPhaseTitleActive,
                      isLocked && styles.enhancedPhaseTitleLocked,
                    ]}
                  >
                    {phase.title}
                  </Text>

                  <Text style={[styles.enhancedPhaseSummary, isLocked && styles.enhancedPhaseSummaryLocked]}>
                    {phase.summary}
                  </Text>

                  <View style={styles.enhancedPhaseFooter}>
                    <View>
                      <Text style={styles.enhancedPhaseOrder}>Phase {phase.order}</Text>
                    </View>
                    {/* Subtle: no action for completed phases to avoid noise */}
                    {!isCompleted && (
                      <TouchableOpacity
                        style={[
                          styles.enhancedPhaseAction,
                          isLocked && styles.enhancedPhaseActionDisabled,
                        ]}
                        disabled={isLocked}
                        onPress={() => navigation.navigate("JourneyQuizScreen", { phaseId: phase.id })}
                      >
                        <Text
                          style={[
                            styles.enhancedPhaseActionText,
                            (isLocked || isActive) && styles.enhancedPhaseActionTextDisabled,
                          ]}
                        >
                          {isLocked ? "Locked" : isActive ? "Resume Quiz" : "Start Quiz"}
                        </Text>
                      </TouchableOpacity>
                    )}
                  </View>
                </TouchableOpacity>
              )
            })}
          </View>
        </View>

        {/* Career Integration Section */}
        <View style={styles.careerSection}>
          <Text style={styles.sectionTitle}>Sanctify Your Work</Text>
          <View style={styles.careerCard}>
            <View style={styles.careerHeader}>
              <Award size={24} color={theme.colors.info} />
              <Text style={styles.careerTitle}>Work as Kingdom Service</Text>
            </View>
            <Text style={styles.careerDescription}>
              Your career is a vital part of your Kingdom citizenship journey. As you progress through the phases, consider how your God-given talents can be sanctified for His purpose.
            </Text>
            <View style={styles.careerProgress}>
              <Text style={styles.careerProgressText}>
                {completedPhases < 3 
                  ? "Focus on building your spiritual foundation first."
                  : completedPhases < 6 
                  ? "Begin aligning your work with your growing spiritual understanding."
                  : "Your work is becoming an expression of your Kingdom citizenship."
                }
              </Text>
            </View>
            <TouchableOpacity 
              style={styles.careerButton}
              onPress={() => navigation.navigate("ProfileScreen")}
            >
              <Text style={styles.careerButtonText}>Review Career Alignment</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Activity Section */}
        <Text style={styles.sectionTitle}>Your activity</Text>
        {journeyStore.isActivitiesLoading ? (
          <View style={styles.loadingRow}>
            <ActivityIndicator color={theme.colors.primary} />
            <Text style={styles.loadingText}>Loading recent activity...</Text>
          </View>
        ) : activities.length === 0 ? (
          <View style={styles.emptyActivity}>
            <Text style={styles.emptyActivityText}>Activity will appear here as you engage.</Text>
          </View>
        ) : (
          <FlatList
            data={activities}
            keyExtractor={(item) => item.id}
            scrollEnabled={false}
            contentContainerStyle={styles.activityList}
            renderItem={({ item }) => (
              <View style={styles.activityItem}>
                <View style={styles.activityDot} />
                <View style={styles.activityContent}>
                  <Text style={styles.activityTitle}>{formatActivityTitle(item)}</Text>
                  <Text style={styles.activityMeta}>{formatRelativeDate(item.created_at)}</Text>
                </View>
              </View>
            )}
          />
        )}
      </ScrollView>

      {/* Configuration Modal */}
      <Modal visible={showConfigurationModal} transparent animationType="slide" onRequestClose={() => setShowConfigurationModal(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Configure Daily Path</Text>
              <TouchableOpacity onPress={() => setShowConfigurationModal(false)}>
                <CrossIcon size={20} color={theme.colors.text.secondary} />
              </TouchableOpacity>
            </View>

            <ScrollView style={styles.modalContent} showsVerticalScrollIndicator={false}>
              <View style={styles.modalSection}>
                <Text style={styles.modalSectionTitle}>Growth Areas</Text>
                <Text style={styles.modalSectionDescription}>
                  Choose your focus areas for spiritual development and daily practice.
                </Text>
                <View style={styles.modalOptionGrid}>
                  {focusOptions.map(option => {
                    const Icon = option.icon;
                    const isSelected = selectedFocuses.includes(option.key);
                    return (
                      <TouchableOpacity
                        key={option.key}
                        style={[styles.modalOptionCard, isSelected && styles.modalOptionCardSelected]}
                        activeOpacity={0.85}
                        onPress={() => toggleFocusSelection(option.key)}
                      >
                        <View style={[styles.modalIconBadge, { backgroundColor: isSelected ? `${theme.colors.primary}16` : `${theme.colors.primary}10` }]}>
                          <Icon size={18} color={isSelected ? theme.colors.primary : theme.colors.text.secondary} />
                        </View>
                        <Text style={styles.modalOptionTitle}>{option.title}</Text>
                        <Text style={styles.modalOptionSubtitle}>{option.short}</Text>
                        {isSelected && (
                          <View style={[styles.modalCheckBadge, { backgroundColor: theme.colors.primary }]}>
                            <Check size={14} color={theme.colors.text.inverse} />
                          </View>
                        )}
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>

              <View style={styles.modalSection}>
                <Text style={styles.modalSectionTitle}>Current Configuration</Text>
                
                <View style={styles.summaryCard}>
                  <Text style={styles.sectionTitle}>Modules enabled</Text>
                  <Text style={styles.summaryValue}>
                    {['revive']
                      .concat(selectedFocuses.includes('habit_conquest') ? ['habit conquest'] : [])
                      .concat(selectedFocuses.includes('knowledge') ? ['Bible reading'] : [])
                      .concat(selectedFocuses.includes('meditation') ? ['meditation'] : [])
                      .concat(selectedFocuses.includes('habits') ? ['habits'] : [])
                      .concat(selectedFocuses.includes('habits') && enableChallenges ? ['challenges'] : [])
                      .join(', ') || 'None selected'}
                  </Text>
                </View>

                {selectedFocuses.includes('knowledge') && (
                  <View style={styles.summaryCard}>
                    <Text style={styles.sectionTitle}>Bible Reading</Text>
                    {readingPlan ? (
                      <>
                        <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Daily time</Text><Text style={styles.summaryValue}>{readingPlan.timePerDay} mins</Text></View>
                        <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Mode</Text><Text style={styles.summaryValue}>{readingModeLabel}</Text></View>
                        <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Books selected</Text><Text style={styles.summaryValue}>{readingPlan.books.length}</Text></View>
                        <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Reminder</Text><Text style={styles.summaryValue}>{readingPlan.reminderTime || 'None'}</Text></View>
                      </>
                    ) : (
                      <TouchableOpacity style={styles.configBtn} onPress={() => setShowReadingPlanModal(true)}>
                        <Text style={styles.configText}>Configure reading plan</Text>
                      </TouchableOpacity>
                    )}
                  </View>
                )}

                {selectedFocuses.includes('habit_conquest') && (
                  <View style={styles.summaryCard}>
                    <Text style={styles.sectionTitle}>Habit Conquest</Text>
                    {habit?.vice ? (
                      <>
                        <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Focus</Text><Text style={styles.summaryValue}>{habit.vice}</Text></View>
                        <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Door shut</Text><Text style={styles.summaryValue}>{habit.doorOfSin || 'Not set'}</Text></View>
                        <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Pledge good</Text><Text style={styles.summaryValue}>{habit.pledgeGood || 'Not set'}</Text></View>
                        <View style={styles.summaryRow}><Text style={styles.summaryLabel}>Daily minutes</Text><Text style={styles.summaryValue}>{habit.dailyMinutes} mins</Text></View>
                      </>
                    ) : (
                      <TouchableOpacity style={styles.configBtn} onPress={() => navigation.navigate('HabitConquestSetupScreen')}>
                        <Text style={styles.configText}>Configure habit conquest</Text>
                      </TouchableOpacity>
                    )}
                  </View>
                )}
              </View>
            </ScrollView>

            <View style={styles.modalActions}>
              <TouchableOpacity
                style={[styles.modalSecondary, { marginRight: theme.spacing.sm }]}
                onPress={() => setShowConfigurationModal(false)}
              >
                <Text style={styles.modalSecondaryText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalPrimary, (selectedFocuses.length === 0 || isSaving) && styles.modalPrimaryDisabled]}
                activeOpacity={0.85}
                onPress={handleSaveConfiguration}
                disabled={selectedFocuses.length === 0 || isSaving}
              >
                <Text style={styles.modalPrimaryText}>{isSaving ? 'Saving...' : 'Save Configuration'}</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      <ReadingPlanSetupModal
        visible={showReadingPlanModal}
        onClose={() => setShowReadingPlanModal(false)}
        onCreatePlan={handleCreatePlan}
      />
    </View>
  )
})

const formatActivityTitle = (activity: JourneyActivity): string => {
  if (!activity) return "Activity"
  const typeText = activity.type?.name || activity.type?.headline || "Activity"
  
  // Handle different subject types properly
  let subject = ""
  if (activity.metadata?.title) {
    subject = activity.metadata.title
  } else if (activity.subject_type) {
    // Convert backend model names to readable format
    if (activity.subject_type === "App\\Models\\GameScore") {
      subject = "Game Score"
    } else {
      // Remove App\Models\ prefix and convert to title case
      subject = activity.subject_type.replace("App\\Models\\", "").replace(/([A-Z])/g, ' $1').trim()
    }
  }
  
  return subject ? `${typeText}: ${subject}` : typeText
}

const formatRelativeDate = (iso: string): string => {
  if (!iso) return ""
  const date = new Date(iso)
  if (Number.isNaN(date.getTime())) return ""
  const now = Date.now()
  const diff = now - date.getTime()
  const minutes = Math.floor(diff / 60000)
  if (minutes < 1) return "Just now"
  if (minutes < 60) return `${minutes} min ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours} hr${hours > 1 ? "s" : ""} ago`
  const days = Math.floor(hours / 24)
  if (days < 7) return `${days} day${days > 1 ? "s" : ""} ago`
  return date.toLocaleDateString()
}

const createStyles = (theme: Theme) =>
  StyleSheet.create({
    // Celebration styles
    celebrationOverlay: {
      ...StyleSheet.absoluteFillObject,
      justifyContent: 'center',
      alignItems: 'center',
      zIndex: 1000,
      padding: theme.spacing.lg,
    },
    celebrationContent: {
      backgroundColor: theme.colors.surface,
      borderRadius: theme.borderRadius.xl,
      padding: theme.spacing.xl,
      alignItems: 'center',
      width: '100%',
      maxWidth: 340,
      shadowColor: theme.colors.text.primary,
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.1,
      shadowRadius: 12,
      elevation: 4,
    },
    celebrationIcon: {
      width: 100,
      height: 100,
      borderRadius: 50,
      justifyContent: 'center',
      alignItems: 'center',
      marginBottom: theme.spacing.lg,
    },
    celebrationText: {
      textAlign: 'center',
      marginBottom: theme.spacing.xs,
      color: theme.colors.text.primary,
    },
    celebrationSubtext: {
      textAlign: 'center',
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.lg,
    },
    celebrationButton: {
      paddingHorizontal: theme.spacing.xl,
      paddingVertical: theme.spacing.sm,
      borderRadius: theme.borderRadius.full,
      width: '100%',
      alignItems: 'center',
    },
    container: {
      flex: 1,
      backgroundColor: theme.colors.background,
    },
    profileButton: {
      width: 32,
      height: 32,
      borderRadius: 16,
      alignItems: "center",
      justifyContent: "center",
    },
    header: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingHorizontal: theme.spacing.md,
      paddingVertical: theme.spacing.sm,
    },
    headerButtons: {
      flexDirection: "row",
      alignItems: "center",
      gap: theme.spacing.sm,
    },
    configButton: {
      width: 32,
      height: 32,
      borderRadius: 16,
      alignItems: "center",
      justifyContent: "center",
    },
    title: {
      ...theme.typography.heading.small,
      color: theme.colors.text.primary,
    },
    content: {
      paddingHorizontal: theme.spacing.md,
      paddingBottom: theme.spacing.xxl,
      gap: theme.spacing.lg,
    },

    hero: {
      backgroundColor: `${theme.colors.primary}08`,
      borderRadius: theme.borderRadius.lg,
      padding: theme.spacing.lg,
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: 200,
      position: 'relative',
      overflow: 'hidden',
    },
    starContainer: {
      alignItems: 'center',
      justifyContent: 'center',
      position: 'relative',
      minHeight: 180,
      width: '100%',
    },
    heroTitle: {
      ...theme.typography.heading.medium,
      color: theme.colors.text.primary,
      fontWeight: '700',
      textAlign: 'center',
      marginTop: theme.spacing.md,
    },
    heroSubtitle: {
      ...theme.typography.body.sans,
      color: theme.colors.text.secondary,
      textAlign: 'center',
      lineHeight: 20,
      marginTop: theme.spacing.xs,
    },
    progressText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
      textAlign: 'center',
      marginTop: theme.spacing.sm,
      fontWeight: '600',
    },

    pathNode: {
      alignItems: "center",
      flex: 1,
      position: "relative",
    },
    connectionLine: {
      position: "absolute",
      top: 20,
      left: "50%",
      right: "-50%",
      height: 2,
      backgroundColor: theme.colors.border,
      zIndex: -1,
    },
    connectionLineCompleted: {
      backgroundColor: theme.colors.success,
      shadowColor: theme.colors.success,
      shadowOffset: { width: 0, height: 0 },
      shadowOpacity: 0.4,
      shadowRadius: 3,
      elevation: 2,
    },
    connectionLineActive: {
      backgroundColor: theme.colors.primary,
      shadowColor: theme.colors.primary,
      shadowOffset: { width: 0, height: 0 },
      shadowOpacity: 0.4,
      shadowRadius: 3,
      elevation: 2,
    },

    phaseNode: {
      width: 40,
      height: 40,
      borderRadius: 20,
      borderWidth: 2,
      borderColor: theme.colors.border,
      backgroundColor: theme.colors.surface,
      alignItems: "center",
      justifyContent: "center",
      position: "relative",
    },
    phaseNodeGlow: {
      position: "absolute",
      width: 50,
      height: 50,
      borderRadius: 25,
      backgroundColor: theme.colors.success,
      opacity: 0.15,
      top: -5,
      left: -5,
    },
    phaseNodeCompleted: {
      borderColor: theme.colors.success,
      backgroundColor: `${theme.colors.success}15`,
      shadowColor: theme.colors.success,
      shadowOffset: { width: 0, height: 0 },
      shadowOpacity: 0.5,
      shadowRadius: 6,
      elevation: 3,
    },
    phaseNodeActive: {
      borderColor: theme.colors.primary,
      backgroundColor: `${theme.colors.primary}15`,
      shadowColor: theme.colors.primary,
      shadowOffset: { width: 0, height: 0 },
      shadowOpacity: 0.5,
      shadowRadius: 6,
      elevation: 3,
    },
    phaseNodeLocked: {
      opacity: 0.5,
    },
    phaseNodeAvailable: {
      borderColor: `${theme.colors.primary}60`,
      backgroundColor: `${theme.colors.primary}08`,
    },
    phaseNodeIcon: {
      position: "absolute",
    },
    phaseNodeNumber: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
      fontWeight: "700",
    },
    phaseNodeNumberCompleted: {
      color: theme.colors.success,
    },
    phaseNodeNumberActive: {
      color: theme.colors.primary,
    },
    phaseNodeNumberLocked: {
      color: theme.colors.text.secondary,
    },
    achievementBadge: {
      position: "absolute",
      top: -4,
      right: -4,
      width: 16,
      height: 16,
      borderRadius: 8,
      backgroundColor: theme.colors.success,
      alignItems: "center",
      justifyContent: "center",
    },

    // Enhanced Phase Cards
    phasesSection: {
      gap: theme.spacing.md,
    },
    phasesGrid: {
      gap: theme.spacing.md,
    },
    motivationCard: {
      backgroundColor: `${theme.colors.primary}08`,
      borderRadius: theme.borderRadius.lg,
      padding: theme.spacing.lg,
      alignItems: 'center',
      gap: theme.spacing.sm,
    },
    motivationIcon: {
      width: 48,
      height: 48,
      borderRadius: 24,
      backgroundColor: `${theme.colors.primary}15`,
      alignItems: 'center',
      justifyContent: 'center',
    },
    motivationQuote: {
      ...theme.typography.body.sans,
      color: theme.colors.text.primary,
      textAlign: 'center',
      fontStyle: 'italic',
      fontWeight: '500',
    },
    motivationAuthor: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
      textAlign: 'center',
    },

    // Achievement Elements
    achievementCard: {
      backgroundColor: `${theme.colors.success}10`,
      borderRadius: theme.borderRadius.lg,
      padding: theme.spacing.lg,
      alignItems: 'center',
      gap: theme.spacing.md,
      borderWidth: 2,
      borderColor: `${theme.colors.success}30`,
    },
    achievementIcon: {
      width: 64,
      height: 64,
      borderRadius: 32,
      backgroundColor: `${theme.colors.success}20`,
      alignItems: 'center',
      justifyContent: 'center',
    },
    achievementTitle: {
      ...theme.typography.heading.medium,
      color: theme.colors.success,
      fontWeight: '700',
      textAlign: 'center',
    },
    achievementSubtitle: {
      ...theme.typography.body.sans,
      color: theme.colors.text.secondary,
      textAlign: 'center',
      lineHeight: 20,
    },
    achievementActions: {
      flexDirection: 'row',
      gap: theme.spacing.sm,
    },
    achievementButton: {
      paddingHorizontal: theme.spacing.lg,
      paddingVertical: theme.spacing.sm,
      borderRadius: theme.borderRadius.full,
      backgroundColor: theme.colors.success,
    },
    achievementButtonText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.inverse,
      fontWeight: '600',
    },
    enhancedPhaseCard: {
      borderRadius: theme.borderRadius.xl,
      borderWidth: 1,
      borderColor: theme.colors.border,
      backgroundColor: theme.colors.surface,
      padding: theme.spacing.lg,
      gap: theme.spacing.sm,
    },
    enhancedPhaseCardCompleted: {
      borderColor: `${theme.colors.success}40`,
      backgroundColor: `${theme.colors.success}05`,
    },
    enhancedPhaseCardActive: {
      borderColor: `${theme.colors.primary}60`,
      backgroundColor: `${theme.colors.primary}08`,
    },
    enhancedPhaseCardLocked: {
      opacity: 0.5,
      borderColor: `${theme.colors.border}80`,
    },
    enhancedPhaseHeader: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
    },
    enhancedPhaseIcon: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: `${theme.colors.primary}10`,
      alignItems: 'center',
      justifyContent: 'center',
    },
    enhancedPhaseStatus: {
      flex: 1,
      alignItems: 'flex-end',
    },
    completedBadge: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 4,
      paddingHorizontal: 10,
      paddingVertical: 5,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.success}12`,
    },
    completedBadgeText: {
      ...theme.typography.caption.primary,
      color: theme.colors.success,
      fontWeight: '500',
      fontSize: 11,
    },
    lockedBadge: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 4,
      paddingHorizontal: 8,
      paddingVertical: 4,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.border}50`,
    },
    lockedBadgeText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
      fontWeight: '600',
    },
    activeBadge: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 4,
      paddingHorizontal: 8,
      paddingVertical: 4,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.primary}15`,
    },
    activeBadgeText: {
      ...theme.typography.caption.primary,
      color: theme.colors.primary,
      fontWeight: '600',
    },
    availableBadge: {
      paddingHorizontal: 8,
      paddingVertical: 4,
    },
    availableBadgeText: {
      ...theme.typography.caption.primary,
      color: `${theme.colors.primary}80`,
      fontWeight: '600',
    },
    enhancedPhaseTitle: {
      ...theme.typography.heading.small,
      color: theme.colors.text.primary,
      fontWeight: '600',
      marginTop: theme.spacing.xs,
    },
    enhancedPhaseTitleCompleted: {
      color: theme.colors.success,
    },
    enhancedPhaseTitleActive: {
      color: theme.colors.primary,
    },
    enhancedPhaseTitleLocked: {
      color: `${theme.colors.text.primary}60`,
    },
    enhancedPhaseSummary: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
      lineHeight: 18,
    },
    enhancedPhaseSummaryLocked: {
      opacity: 0.7,
    },
    enhancedPhaseFooter: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      marginTop: theme.spacing.xs,
    },
    enhancedPhaseOrder: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
      fontWeight: '600',
    },
    enhancedPhaseAction: {
      paddingHorizontal: theme.spacing.md,
      paddingVertical: theme.spacing.xs,
      borderRadius: theme.borderRadius.full,
      backgroundColor: theme.colors.primary,
    },
    enhancedPhaseActionDisabled: {
      backgroundColor: theme.colors.border,
    },
    enhancedPhaseActionText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.inverse,
      fontWeight: '600',
    },
    enhancedPhaseActionTextDisabled: {
      color: theme.colors.text.inverse,
    },

    // Career Integration Styles
    careerSection: {
      gap: theme.spacing.md,
    },
    careerCard: {
      backgroundColor: `${theme.colors.info}08`,
      borderRadius: theme.borderRadius.lg,
      padding: theme.spacing.lg,
      borderWidth: 1,
      borderColor: `${theme.colors.info}20`,
      gap: theme.spacing.md,
    },
    careerHeader: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: theme.spacing.sm,
    },
    careerTitle: {
      ...theme.typography.body.sans,
      color: theme.colors.info,
      fontWeight: '600',
    },
    careerDescription: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
      lineHeight: 18,
    },
    careerProgress: {
      backgroundColor: `${theme.colors.info}10`,
      borderRadius: theme.borderRadius.md,
      padding: theme.spacing.md,
    },
    careerProgressText: {
      ...theme.typography.caption.primary,
      color: theme.colors.info,
      lineHeight: 16,
    },
    careerButton: {
      backgroundColor: theme.colors.info,
      paddingVertical: theme.spacing.sm,
      paddingHorizontal: theme.spacing.md,
      borderRadius: theme.borderRadius.lg,
      alignItems: 'center',
      alignSelf: 'flex-start',
    },
    careerButtonText: {
      ...theme.typography.button,
      color: theme.colors.text.inverse,
    },

    // Activity Styles
    sectionTitle: {
      ...theme.typography.heading.small,
      color: theme.colors.text.primary,
      marginTop: theme.spacing.sm,
    },
    loadingRow: {
      flexDirection: "row",
      alignItems: "center",
      gap: theme.spacing.sm,
    },
    loadingText: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
    },
    emptyActivity: {
      borderRadius: theme.borderRadius.lg,
      borderWidth: 1,
      borderColor: theme.colors.border,
      padding: theme.spacing.lg,
      alignItems: "center",
    },
    emptyActivityText: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
    },
    activityList: {
      gap: theme.spacing.sm,
    },
    activityItem: {
      flexDirection: "row",
      alignItems: "flex-start",
      gap: theme.spacing.sm,
      paddingVertical: theme.spacing.xs,
    },
    activityDot: {
      width: 8,
      height: 8,
      borderRadius: 4,
      backgroundColor: theme.colors.primary,
      marginTop: theme.spacing.xs,
    },
    activityContent: {
      flex: 1,
      gap: theme.spacing.xs,
    },
    activityTitle: {
      ...theme.typography.body.sans,
      color: theme.colors.text.primary,
    },
    activityMeta: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
    },
    reconfigureButton: {
      marginTop: theme.spacing.md,
      paddingHorizontal: theme.spacing.lg,
      paddingVertical: theme.spacing.xs,
      borderRadius: theme.borderRadius.full,
      backgroundColor: theme.colors.surface,
      borderWidth: 1,
      borderColor: theme.colors.border,
    },
    reconfigureButtonText: {
      ...theme.typography.caption.primary,
      color: theme.colors.primary,
      textAlign: 'center',
      fontWeight: '600',
    },

    // Configuration Modal Styles
    modalOverlay: {
      flex: 1,
      backgroundColor: 'rgba(0,0,0,0.5)',
      justifyContent: 'center',
      alignItems: 'center',
      padding: theme.spacing.lg,
    },
    modalCard: {
      backgroundColor: theme.colors.background,
      borderRadius: theme.borderRadius.xl,
      width: '100%',
      maxWidth: 500,
      maxHeight: '90%',
      borderWidth: 1,
      borderColor: theme.colors.border,
      overflow: 'hidden',
    },
    modalHeader: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: theme.spacing.lg,
      borderBottomWidth: 1,
      borderBottomColor: theme.colors.border,
    },
    modalTitle: {
      ...theme.typography.heading.small,
      color: theme.colors.text.primary,
    },
    modalContent: {
      flex: 1,
      padding: theme.spacing.lg,
    },
    modalSection: {
      marginBottom: theme.spacing.xl,
    },
    modalSectionTitle: {
      ...theme.typography.heading.small,
      color: theme.colors.text.primary,
      marginBottom: theme.spacing.sm,
    },
    modalSectionDescription: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.md,
      lineHeight: 18,
    },
    modalOptionGrid: {
      flexDirection: 'column',
      gap: theme.spacing.sm,
    },
    modalOptionCard: {
      position: 'relative',
      borderRadius: theme.borderRadius.lg,
      borderWidth: 1,
      borderColor: theme.colors.border,
      padding: theme.spacing.md,
      backgroundColor: theme.colors.surface,
    },
    modalOptionCardSelected: {
      borderColor: theme.colors.primary,
      backgroundColor: `${theme.colors.primary}05`,
    },
    modalIconBadge: {
      width: 36,
      height: 36,
      borderRadius: 18,
      alignItems: 'center',
      justifyContent: 'center',
      marginBottom: theme.spacing.sm,
    },
    modalOptionTitle: {
      ...theme.typography.body.sans,
      color: theme.colors.text.primary,
      fontWeight: '600',
      marginBottom: theme.spacing.xs,
    },
    modalOptionSubtitle: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
    },
    modalCheckBadge: {
      position: 'absolute',
      top: theme.spacing.md,
      right: theme.spacing.md,
      width: 20,
      height: 20,
      borderRadius: 10,
      alignItems: 'center',
      justifyContent: 'center',
    },
    summaryCard: {
      backgroundColor: theme.colors.surface,
      borderRadius: theme.borderRadius.lg,
      padding: theme.spacing.md,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: theme.colors.border,
      gap: theme.spacing.sm,
      marginBottom: theme.spacing.md,
    },
    configBtn: {
      paddingHorizontal: theme.spacing.md,
      paddingVertical: theme.spacing.sm,
      borderRadius: theme.borderRadius.md,
      backgroundColor: theme.colors.background,
      borderWidth: StyleSheet.hairlineWidth,
      borderColor: theme.colors.border,
      alignItems: 'center',
    },
    configText: {
      ...theme.typography.caption.primary,
      color: theme.colors.primary,
      fontWeight: '600',
    },
    summaryRow: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
    },
    summaryLabel: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
    },
    summaryValue: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.primary,
      fontWeight: '600',
    },
    modalActions: {
      flexDirection: 'row',
      padding: theme.spacing.lg,
      borderTopWidth: 1,
      borderTopColor: theme.colors.border,
      gap: theme.spacing.sm,
    },
    modalSecondary: {
      flex: 1,
      paddingVertical: theme.spacing.md,
      borderRadius: theme.borderRadius.lg,
      borderWidth: 1,
      borderColor: theme.colors.border,
      alignItems: 'center',
      backgroundColor: theme.colors.surface,
    },
    modalSecondaryText: {
      ...theme.typography.button,
      color: theme.colors.text.primary,
    },
    modalPrimary: {
      flex: 2,
      paddingVertical: theme.spacing.md,
      borderRadius: theme.borderRadius.lg,
      backgroundColor: theme.colors.primary,
      alignItems: 'center',
    },
    modalPrimaryDisabled: {
      opacity: 0.6,
    },
    modalPrimaryText: {
      ...theme.typography.button,
      color: theme.colors.text.inverse,
    },
  })

export default MyJourneyScreen
