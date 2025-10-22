import React, { useMemo } from "react"
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  FlatList,
  ActivityIndicator,
  useWindowDimensions,
} from "react-native"
import { useSafeAreaInsets } from "react-native-safe-area-context"
import { observer } from "mobx-react-lite"
import { useTheme } from "@/contexts/ThemeContext"
import type { Theme } from "@/theme"
import { useJourneyStore } from "@/stores/StoreProvider"
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
  Cross,
  Dove,
  Book,
  Lightning,
  Trophy,
} from "@/components/Icons"
import JourneyHero from "@/components/JourneyHero"

const MyJourneyScreen = observer(() => {
  const insets = useSafeAreaInsets()
  const theme = useTheme()
  const styles = useMemo(() => createStyles(theme), [theme])
  const journeyStore = useJourneyStore()
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>()
  const { width } = useWindowDimensions()
  const isCompact = width < 360

  React.useEffect(() => {
    journeyStore.fetchActivities()
  }, [journeyStore])

  const activeQuizQuestion =
    journeyStore.quizState.currentIndex < journeyStore.quizState.questions.length
      ? journeyStore.quizState.questions[journeyStore.quizState.currentIndex]
      : null
  const activities = Array.isArray(journeyStore.activities) ? journeyStore.activities : []

  // Journey phase icons mapping
  const getPhaseIcon = (phaseId: string, isCompleted = false) => {
    const iconProps = { size: 20, color: isCompleted ? theme.colors.success : theme.colors.text.secondary }
    switch (phaseId) {
      case "accept-jesus":
        return <Cross {...iconProps} />
      case "repentance":
        return <Heart {...iconProps} />
      case "activation-holy-spirit":
        return <Dove {...iconProps} />
      case "bearing-fruits":
        return <Flame {...iconProps} />
      case "storing-treasures":
        return <Crown {...iconProps} />
      case "giving-of-self":
        return <Heart {...iconProps} />
      case "divine-visions":
        return <Star {...iconProps} filled={isCompleted} />
      default:
        return <Book {...iconProps} />
    }
  }

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
        <Text style={styles.title}>My Journey</Text>
        <TouchableOpacity
          onPress={() => navigation.navigate("ProfileScreen")}
          style={styles.profileButton}
          accessibilityLabel="View profile"
        >
          <User size={22} color={theme.colors.text.primary} />
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.hero}>
          <View style={styles.starContainer}>
            <JourneyHero progress={overallProgress} />
          </View>
          
          <Text style={styles.heroTitle}>Your Spiritual Journey</Text>
          <Text style={styles.heroSubtitle}>
            {completedPhases < 2 
              ? "The journey of a thousand miles begins with one step."
              : completedPhases === totalPhases 
              ? "Luke 10:20"
              : `Forge on and do not look back.`
            }
          </Text>
          
          <Text style={styles.progressText}>
            {Math.round(overallProgress)}% Complete • {completedPhases} of {totalPhases} phases
          </Text>
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
          <Text style={styles.sectionTitle}>Miles</Text>
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
                  disabled={isLocked || isActive}
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
                          (isLocked || isActive) && styles.enhancedPhaseActionDisabled,
                        ]}
                        disabled={isLocked || isActive}
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
    </View>
  )
})

const formatActivityTitle = (activity: JourneyActivity): string => {
  if (!activity) return "Activity"
  const typeText = activity.type ? String(activity.type) : "Activity"
  const subject = activity.metadata?.title || activity.subject_type || ""
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
      borderRadius: theme.borderRadius.lg,
      borderWidth: 1,
      borderColor: theme.colors.border,
      backgroundColor: theme.colors.surface,
      padding: theme.spacing.md,
      gap: theme.spacing.sm,
      shadowColor: theme.colors.text.primary,
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.1,
      shadowRadius: 4,
      elevation: 2,
    },
    enhancedPhaseCardCompleted: {
      borderColor: theme.colors.success,
      backgroundColor: `${theme.colors.success}08`,
    },
    enhancedPhaseCardActive: {
      borderColor: theme.colors.primary,
      backgroundColor: `${theme.colors.primary}10`,
    },
    enhancedPhaseCardLocked: {
      opacity: 0.7,
    },
    enhancedPhaseHeader: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
    },
    enhancedPhaseIcon: {
      width: 32,
      height: 32,
      borderRadius: 16,
      backgroundColor: `${theme.colors.primary}15`,
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
      paddingHorizontal: 8,
      paddingVertical: 4,
      borderRadius: theme.borderRadius.full,
      backgroundColor: `${theme.colors.success}15`,
    },
    completedBadgeText: {
      ...theme.typography.caption.primary,
      color: theme.colors.success,
      fontWeight: '600',
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
      paddingVertical: theme.spacing.sm,
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
      color: theme.colors.text.secondary,
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
  })

export default MyJourneyScreen
