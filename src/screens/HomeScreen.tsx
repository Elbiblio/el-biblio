import React, { useCallback, useState } from 'react';
import {
  View,
  ScrollView,
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  Platform,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withSequence,
  withTiming,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { BlurView } from 'expo-blur';
import {
  BookOpen,
  BookmarkSimple,
  NotePencil,
  Users,
  MessageSquare,
  Star,
  ChevronRight,
  Sparkle,
  Bible,
} from './../components/Icons';
import { LinearGradient } from 'expo-linear-gradient';
import { Reflection, RootStackParamList, sampleDailyVerses, User, Verse } from '@/types';
import AvatarStack from '@/components/AvatarStack';
import CircleButton from '@/components/CircleButton';
import { getTheme, Theme } from '@/theme';
import { getCurrentTheme } from '@/theme/store';
import { useTheme } from '@/contexts/ThemeContext';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { SCREEN_DIMENSIONS } from '@/constants';

const AnimatedBlurView = Animated.createAnimatedComponent(BlurView);
const CARD_WIDTH = SCREEN_DIMENSIONS.width * 0.9;

const QuickActionCard = ({ action, index, actionStyles, navigation }: { action: any; index: number, actionStyles: any, navigation: any }) => {
  return (
    <TouchableOpacity
      style={actionStyles.actionCard}
      activeOpacity={0.7}
      onPress={() => {
        navigation.navigate(action.route);
      }}
    >
      <LinearGradient
        colors={[`${action.color}08`, `${action.color}03`]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={actionStyles.actionGradient}
      />
      <View style={actionStyles.actionContent}>
        <View style={[actionStyles.iconContainer, { backgroundColor: `${action.color}15` }]}>
          <action.icon size={20} color={action.color} />
        </View>
        <Text style={[actionStyles.actionText, { color: action.color }]}>
          {action.label}
        </Text>
      </View>
    </TouchableOpacity>
  );
};

type HomeProps = NativeStackScreenProps<RootStackParamList, 'Home'>;

const HomeScreen: React.FC<HomeProps> = ({navigation}) => {
  const insets = useSafeAreaInsets();
  const pointsScale = useSharedValue(1);
  const [activeVerse, setActiveVerse] = useState<string | null>(null);
  const cardScale = useSharedValue(1);
  const scrollY = useSharedValue(0);
  const [currentVerseIndex, setCurrentVerseIndex] = useState(0);
  const scrollX = useSharedValue(0);

  const theme = useTheme()
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const actionStyles = React.useMemo(() => createActionStyles(theme), [theme]);
  const themeText = {color: theme?.colors.primary};
  const [dailyVerses, setDailyVerses] = useState<Verse[]>(sampleDailyVerses);


  const headerAnimatedStyle = useAnimatedStyle(() => ({
    transform: [
      {
        translateY: interpolate(
          scrollY.value,
          [0, 100],
          [0, -50],
          Extrapolation.CLAMP
        ),
      },
    ],
    opacity: interpolate(
      scrollY.value,
      [0, 100],
      [1, 0],
      Extrapolation.CLAMP
    ),
  }));

  const ScrollIndicators = () => {
    return (
      <View style={styles.indicatorContainer}>
        {dailyVerses.map((_, index) => {
          const animatedStyle = useAnimatedStyle(() => {
            const width = interpolate(
              scrollX.value,
              [
                (index - 1) * (CARD_WIDTH + theme?.spacing.sm),
                index * (CARD_WIDTH + theme?.spacing.sm),
                (index + 1) * (CARD_WIDTH + theme?.spacing.sm),
              ],
              [8, 24, 8],
              Extrapolation.CLAMP
            );

            const opacity = interpolate(
              scrollX.value,
              [
                (index - 1) * (CARD_WIDTH + theme?.spacing.sm),
                index * (CARD_WIDTH + theme?.spacing.sm),
                (index + 1) * (CARD_WIDTH + theme?.spacing.sm),
              ],
              [0.5, 1, 0.5],
              Extrapolation.CLAMP
            );

            return {
              width,
              opacity,
            };
          });

          return (
            <Animated.View
              key={index}
              style={[styles.indicator, animatedStyle]}
            />
          );
        })}
      </View>
    );
  };

  const handleScroll = (event: any) => {
    scrollY.value = event.nativeEvent.contentOffset.y;
  };

  const handleVersePress = (verse: Verse) => {
    setActiveVerse(verse.id);
    cardScale.value = withSequence(
      withTiming(0.95, { duration: 100 }),
      withTiming(1, { duration: 100 })
    );
    navigation.navigate("VerseDetail", {verse});
  };

  const handleVerseScroll = useCallback((event: any) => {
    const x = event.nativeEvent.contentOffset.x;
    scrollX.value = x;
    const newIndex = Math.round(x / (CARD_WIDTH + theme?.spacing.sm));
    setCurrentVerseIndex(newIndex);
  }, []);

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <ScrollView
        onScroll={handleScroll}
        scrollEventThrottle={16}
        contentContainerStyle={styles.scrollContent}
      >
        {/* Animated Header */}
        <Animated.View style={[styles.header, headerAnimatedStyle]}>
          <View>
            <Text style={styles.greeting}>Good morning, Sarah</Text>
            <Text style={styles.subGreeting}>Ready for today's reflection?</Text>
          </View>
          <TouchableOpacity
            style={styles.pointsContainer}
            onPress={() => {
              pointsScale.value = withSequence(
                withSpring(1.1),
                withSpring(1)
              );
            }}
          >
            <Animated.View style={[styles.points, { transform: [{ scale: pointsScale }] }]}>
              <LinearGradient
                colors={[theme?.colors.primary, theme?.colors.primaryLight]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.pointsGradient}
              >
                <Star size={20} color="#FFF" />
                <Text style={styles.pointsText}>2,450</Text>
              </LinearGradient>
            </Animated.View>
          </TouchableOpacity>
        </Animated.View>

        <View style={actionStyles.quickActionsContainer}>
          <View style={actionStyles.quickActionsHeader}>
            <Text style={actionStyles.quickActionsTitle}>Quick Actions</Text>
          </View>
          <View style={actionStyles.actionGrid}>
            {[
              { icon: NotePencil, label: 'Notes', color: theme?.colors.primary, route: 'NotesScreen' },
              { icon: BookmarkSimple, label: 'Saved', color: theme?.colors.secondary, route: 'SavedItemsScreen' },
              { icon: Users, label: 'Word Hubs', color: theme?.colors.primaryDark, route: 'WordHubsScreen' },
              { icon: MessageSquare, label: 'One-on-One', color: theme?.colors.like, route: 'MatchScreen' },
            ].map((action, index) => (
              <QuickActionCard
                key={action.label}
                action={action}
                actionStyles={actionStyles}
                index={index}
                navigation={navigation}
              />
            ))}
          </View>
        </View>

        {/* Daily Verses Section */}
        <View style={styles.versesSection}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Today's Verses</Text>
            <TouchableOpacity style={styles.seeAllButton} onPress={() => navigation.navigate('DailyVersesScreen')}>
              <Text style={[styles.seeAllText, themeText]}>See all</Text>
              <ChevronRight size={16} color={theme?.colors.primary} />
            </TouchableOpacity>
          </View>

          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.versesScrollContent}
            decelerationRate="fast"
            snapToInterval={CARD_WIDTH + theme?.spacing.sm}
            onScroll={handleVerseScroll}
            scrollEventThrottle={16}
            pagingEnabled
          >
            {dailyVerses.map((verse: Verse) => (
              <Animated.View
                key={verse.id}
                style={[
                  styles.verseCardContainer,
                  { transform: [{ scale: activeVerse === verse.id ? cardScale : 1 }] }
                ]}
              >
                <TouchableOpacity
                  onPress={() => handleVersePress(verse)}
                  activeOpacity={0.9}
                >
                  <AnimatedBlurView intensity={10} style={styles.verseCard}>
                    <View style={styles.verseSymbol}>
                      <LinearGradient
                        colors={[`${theme?.colors.primary}20`, `${theme?.colors.primary}05`]}
                        style={styles.symbolGradient}
                        start={{ x: 0, y: 0 }}
                        end={{ x: 1, y: 1 }}
                      >
                        <Bible size={24} color={theme?.colors.primary} />
                      </LinearGradient>
                    </View>

                    <View style={styles.verseContent}>
                      {verse.trending && (
                        <View style={styles.trendingBadge}>
                          <Sparkle size={12} color={theme?.colors.primary} />
                          <Text style={[styles.trendingText, themeText]}>345 reactions</Text>
                        </View>
                      )}

                      <Text style={styles.verseText} numberOfLines={3}>
                        {verse.text}
                      </Text>

                      <View style={styles.verseFooter}>
                        <Text style={[styles.verseReference, themeText]}>
                          {verse.reference}
                        </Text>

                        {/* Scroll Indicators */}
                        <View style={styles.indicatorsWrapper}>
                          <ScrollIndicators />
                        </View>
                      </View>


                      <View style={styles.interactionsContainer}>
                        <View style={styles.reflectionMeta}>
                          <AvatarStack
                            users={verse.reflections.map((reflection: Reflection) => reflection.author)}
                            maxAvatars={3}
                            size={24}
                          />
                          <Text style={styles.reflectionCount}>
                            {" "} +{verse.reflections.length - 3}  others  sharing
                          </Text>

                        </View>
                        
                        <CircleButton
                            size={32}
                            style={styles.expandButton}
                            Icon={ChevronRight}
                            onPress={() => { }}
                          />

                      </View>
                    </View>

                    <LinearGradient
                      colors={['transparent', `${theme?.colors.background}40`]}
                      style={styles.cardGradient}
                      start={{ x: 0, y: 0 }}
                      end={{ x: 0, y: 1 }}
                    />
                  </AnimatedBlurView>
                </TouchableOpacity>
              </Animated.View>
            ))}
          </ScrollView>
        </View>
      </ScrollView>
    </View>
  );
};


const createActionStyles = (theme: Theme) => StyleSheet.create({
  quickActionsContainer: {
    marginTop: theme?.spacing.md,
    paddingHorizontal: theme?.spacing.md,
    marginBottom: theme?.spacing.xl,
  },
  quickActionsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme?.spacing.md,
  },
  quickActionsTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
  },
  actionGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme?.spacing.sm,
  },
  actionCard: {
    flex: 1,
    minWidth: '47%', // Slightly less than 50% to account for gap
    aspectRatio: 2.5,
    borderRadius: theme?.borderRadius.lg,
    backgroundColor: theme?.colors.background,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: theme?.colors.border,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 4,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  actionGradient: {
    ...StyleSheet.absoluteFillObject,
  },
  actionContent: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.md,
    gap: theme?.spacing.sm,
  },
  iconContainer: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionText: {
    ...theme?.typography.caption.primary,
    fontSize: 13,
    fontWeight: '600',
  },
});

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme?.colors.background,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.lg,
    backgroundColor: theme?.colors.background,
  },
  greeting: {
    ...theme?.typography.heading.large,
    color: theme?.colors.text.primary,
  },
  subGreeting: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginTop: 4,
  },
  pointsContainer: {
    overflow: 'hidden',
    borderRadius: theme?.borderRadius.full,
  },
  pointsGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    gap: theme?.spacing.xs,
  },
  points: {
    borderRadius: theme?.borderRadius.full,
    ...Platform.select({
      ios: {
        shadowColor: theme?.colors.primary,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 8,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  pointsText: {
    ...theme?.typography.caption.primary,
    color: '#FFF',
    fontWeight: '600',
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingLeft: theme?.spacing.md,
    paddingRight: theme?.spacing.lg,
    paddingVertical: theme?.spacing.md,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: theme?.colors.border,
    marginTop: 'auto', // Push to bottom
  },

  footerStats: {
    flex: 1,
    marginRight: theme?.spacing.md,
  },

  scrollContent: {
    paddingBottom: theme?.spacing.xl,
  },
  quickActions: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    gap: theme?.spacing.sm,
  },
  actionCard: {
    flex: 1,
    minWidth: '45%',
    aspectRatio: 1.5,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.md,
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme?.spacing.sm,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 3,
      },
    }),
  },
  actionText: {
    ...theme?.typography.caption.primary,
    textAlign: 'center',
    fontWeight: '600',
  },
  versesSection: {
    padding: theme?.spacing.md,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme?.spacing.md,
  },
  sectionTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
  },
  seeAllButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.xs,
  },
  seeAllText: {
    ...theme?.typography.caption.primary
  },
  cardContent: {
    flex: 1,
    padding: theme?.spacing.lg,
  },
  versesScrollContent: {
    paddingRight: theme?.spacing.md,
    gap: theme?.spacing.md,
  },
  verseCardContainer: {
    width: CARD_WIDTH,
    marginRight: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
  },
  verseCard: {
    height: 300,
    backgroundColor: theme?.colors.background,
    borderRadius: theme?.borderRadius.xl,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: `${theme?.colors.primary}15`,
    ...Platform.select({
      ios: {
        shadowColor: theme?.colors.primary,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.1,
        shadowRadius: 12,
      },
      android: {
        elevation: 4,
      },
    }),
  },
  trendingBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    backgroundColor: `${theme?.colors.primary}10`,
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: theme?.spacing.xs,
    borderRadius: theme?.borderRadius.full,
    marginBottom: theme?.spacing.md,
    gap: 4,
  },
  trendingText: {
    ...theme?.typography.caption.secondary,
    fontSize: 12,
    fontWeight: '600',
  },
  verseContent: {
    flex: 1,
    padding: theme?.spacing.lg,
    justifyContent: 'space-between',
  },
  verseText: {
    ...theme?.typography.verse.regular,
    fontSize: 20,
    lineHeight: 32,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.lg,
    textAlign: 'left',
  },
  verseFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 'auto',
  },
  verseReference: {
    ...theme?.typography.verse.emphasis,
    fontSize: 16,
  },
  verseMeta: {
    gap: theme?.spacing.md,
  },
  indicatorContainer: {
    position: 'absolute',
    bottom: theme?.spacing.md,
    left: 0,
    right: 0,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: theme?.spacing.xs,
  },
  indicator: {
    height: 3,
    backgroundColor: theme?.colors.primary,
    borderRadius: theme?.borderRadius.full,
    opacity: 0.6,
  },
  interactionsContainer: {
    marginTop: theme?.spacing.md,
    paddingTop: theme?.spacing.md,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: theme?.colors.border,
    gap: theme?.spacing.sm,
  },
  interactionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.sm,
  },
  reflectionMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.sm,
  },
  reflectionCount: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginTop: 0 - theme?.spacing.sm,
    fontSize: 12,
  },
  indicatorsWrapper: {
    position: 'absolute',
    bottom: -20,
    left: 0,
    right: 0,
    alignItems: 'center',
  },
  interactionButton: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.full,
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: 6,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 3,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  interactionButtonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  interactionCount: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontSize: 12,
    fontWeight: '600',
  },
  metaText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontSize: 12,
  },
  animatedProgressBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 3,
    backgroundColor: theme?.colors.primary,
  },
  gradientOverlay: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 80,
  },
  expandButton: {
    position: 'absolute',
    bottom: 0,
    alignSelf: 'flex-end',
    backgroundColor: theme?.colors.primary,
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.xs,
    ...Platform.select({
      ios: {
        shadowColor: theme?.colors.primary,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.3,
        shadowRadius: 8,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  expandButtonText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.inverse,
    fontWeight: '600',
  },
  sectionDivider: {
    height: 8,
    backgroundColor: theme?.colors.surface,
    marginBottom: theme?.spacing.lg,
  },

  verseSymbol: {
    position: 'absolute',
    top: theme?.spacing.md,
    right: theme?.spacing.md,
    zIndex: 2,
  },
  symbolGradient: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  footerContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.sm,
  },
  cardGradient: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 100,
  },

});

export default HomeScreen;