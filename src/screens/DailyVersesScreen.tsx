import React, { useState, useCallback, useRef } from 'react';
import {
    View,
    Text,
    ScrollView,
    TouchableOpacity,
    StyleSheet,
    Platform,
} from 'react-native';
import Animated from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import {
    ArrowLeft,
    Star,
    Sparkle,
    Info,
    Upvote,
    Check,
} from '../components/Icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import * as Haptics from 'expo-haptics';
import VerseTooltip from '../components/VerseTooltip';
import { DailyVerse, DayVerses, RootStackParamList, sampleCurrentVerses, sampleUpcomingVerses, THEMES } from '@/types';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useThemeOfDay } from '@/utils/schedule';
import { getTomorrowsTheme } from '@/utils/schedule';
import ThemeInfo from '@/modals/ThemeInfo';


const DailyVersesScreen = ({ navigation }: NativeStackScreenProps<RootStackParamList, 'DailyVersesScreen'>) => {
    const theme = useTheme();
    const insets = useSafeAreaInsets();
    const styles = React.useMemo(() => createStyles(theme), [theme]);
    const [showThemeInfo, setShowThemeInfo] = useState(false);
    const todayTheme = useThemeOfDay();
    const tomorrowTheme = getTomorrowsTheme();

    const [currentVerses, setCurrentVerses] = useState(sampleCurrentVerses);
    const [upcomingVerses, setUpcomingVerses] = useState(sampleUpcomingVerses);

    const [selectedTab, setSelectedTab] = useState<'current' | 'upcoming'>('current');
    const [selectedVerse, setSelectedVerse] = useState<DailyVerse | null>(null);
    const verseRef = useRef<View>(null);

    const selectedTheme = selectedTab === 'current' ? todayTheme : tomorrowTheme;

    const formattedTheme = {
        ...selectedTheme,
        practices: selectedTheme.practices || [],
        subtitle: selectedTheme.subtitle || '', // Add default values if needed
        description: selectedTheme.description || '',
    };

    const renderVerseCard = (verse: DailyVerse) => {
        const themeInfo = THEMES[verse.theme];

        return (
            <View
                key={verse.id}
                style={[
                    styles.verseCard,
                    { borderColor: `${themeInfo.color}20` }
                ]}
            >
                <BlurView intensity={10} style={StyleSheet.absoluteFill} />
                <TouchableOpacity
                    onPress={() => setSelectedVerse(verse)}
                    style={styles.verseContent}
                >
                    <View ref={verseRef}>
                        {/* Moderator Badge if applicable */}
                        {verse.isModerator && (
                            <View style={[
                                styles.moderatorBadge,
                                { backgroundColor: `${themeInfo.color}15` }
                            ]}>
                                <Sparkle size={12} color={themeInfo.color} />
                                <Text style={[
                                    styles.moderatorText,
                                    { color: themeInfo.color }
                                ]}>
                                    Featured
                                </Text>
                            </View>
                        )}

                        {/* Verse Content */}
                        <View style={styles.verseHeader}>
                            <Text style={[
                                styles.verseReference,
                                { color: themeInfo.color }
                            ]}>
                                {verse.reference}
                            </Text>
                            <Text style={styles.translation}>{verse.translation}</Text>
                        </View>

                        <Text style={styles.verseText}>
                            {verse.text}
                        </Text>

                        {/* Footer */}
                        <View style={styles.verseFooter}>
                            <View style={styles.voteCount}>
                                <Star size={16} color={themeInfo.color} />
                                <Text style={styles.voteText}>{verse.votes} votes</Text>
                            </View>

                            {selectedTab === 'upcoming' && (
                                <TouchableOpacity
                                    style={[
                                        styles.voteButton,
                                        verse.isVoted && styles.votedButton,
                                        {
                                            backgroundColor: verse.isVoted ?
                                                themeInfo.color :
                                                `${themeInfo.color}15`
                                        }
                                    ]}
                                    onPress={() => {
                                        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                                        // Handle vote
                                    }}
                                    disabled={verse.isVoted}
                                >
                                    {
                                        verse.isVoted ?
                                        <Check size={16}
                                        color={theme.colors.text.inverse}
                                        filled
                                        />:
                                    <Upvote
                                    size={16}
                                        color={verse.isVoted ? theme.colors.text.inverse : themeInfo.color}
                                        filled={verse.isVoted}
                                        />
                                    }
                                    <Text style={[
                                        styles.voteButtonText,
                                        { color: verse.isVoted ? theme.colors.text.inverse : themeInfo.color }
                                    ]}>
                                        {verse.isVoted ? 'Voted' : 'Vote'}
                                    </Text>
                                </TouchableOpacity>
                            )}
                        </View>
                    </View>
                </TouchableOpacity>
            </View>
        );
    };

    const verses = selectedTab === 'current' ? currentVerses : upcomingVerses;

    return (
        <>
            <View style={[styles.container, { paddingTop: insets.top }]}>
                {/* Header */}
                <View style={styles.header}>
                    <TouchableOpacity onPress={() => navigation.goBack()}>
                        <ArrowLeft size={24} color={theme.colors.text.primary} />
                    </TouchableOpacity>
                    <Text style={styles.title}>Daily Verses</Text>
                    <TouchableOpacity onPress={() => { navigation.navigate("IntroScreen") }}>
                        <Info size={24} color={theme.colors.text.primary} />
                    </TouchableOpacity>
                </View>

                {/* Tab Selector */}
                <View style={styles.tabContainer}>
                    <TouchableOpacity
                        style={[styles.tab, selectedTab === 'current' && styles.activeTab]}
                        onPress={() => setSelectedTab('current')}
                    >
                        <Text style={[
                            styles.tabText,
                            selectedTab === 'current' && styles.activeTabText
                        ]}>
                            Today's Verses
                        </Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={[styles.tab, selectedTab === 'upcoming' && styles.activeTab]}
                        onPress={() => setSelectedTab('upcoming')}
                    >
                        <Text style={[
                            styles.tabText,
                            selectedTab === 'upcoming' && styles.activeTabText
                        ]}>
                            Tomorrow's Selection
                        </Text>
                    </TouchableOpacity>
                </View>

                {/* Main Content */}
                <ScrollView
                    style={styles.scrollContent}
                    contentContainerStyle={styles.scrollContainer}
                    showsVerticalScrollIndicator={false}
                >
                    <Text style={[styles.dateText, { alignSelf: selectedTab === 'current' ? 'flex-start' : 'flex-end' }]}>{verses.date}</Text>
                    <TouchableOpacity
                        style={[styles.themeBadge, { backgroundColor: `${selectedTheme.color}15`, alignSelf: selectedTab === 'current' ? 'flex-start' : 'flex-end' }]}
                        onPress={() => setShowThemeInfo(true)}
                    >
                        <selectedTheme.Icon size={16} color={selectedTheme.color} />
                        <Text style={[styles.themeText, { color: selectedTheme.color }]}>
                            Theme: {selectedTheme.title}
                        </Text>
                    </TouchableOpacity>

                    {/* Featured Verses */}
                    <View style={styles.sectionContainer}>
                        {verses.moderatorVerses.map(renderVerseCard)}
                        {verses.randomVerses.map(renderVerseCard)}
                    </View>

                </ScrollView>

                {/* Verse Tooltip */}
                {selectedVerse && (
                    <VerseTooltip
                        verseRef={selectedVerse.reference}
                        targetRef={verseRef}
                        onClose={() => setSelectedVerse(null)}
                    />
                )}
            </View>
            {/* Theme Info Modal */}
            <ThemeInfo
                theme={formattedTheme}
                visible={showThemeInfo}
                onClose={() => setShowThemeInfo(false)}
            />
        </>
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
    tabContainer: {
        flexDirection: 'row',
        padding: theme.spacing.md,
        gap: theme.spacing.sm,
    },
    tab: {
        flex: 1,
        paddingVertical: theme.spacing.sm,
        paddingHorizontal: theme.spacing.md,
        borderRadius: theme.borderRadius.full,
        backgroundColor: theme.colors.surface,
        alignItems: 'center',
    },
    activeTab: {
        backgroundColor: theme.colors.primary,
    },
    tabText: {
        ...theme.typography.caption.primary,
        color: theme.colors.text.primary,
    },
    activeTabText: {
        color: theme.colors.text.inverse,
    },
    scrollContent: {
        flex: 1,
    },
    scrollContainer: {
        padding: theme.spacing.md,
    },
    dateText: {
        ...theme.typography.heading.small,
        color: theme.colors.text.secondary,
        marginBottom: theme.spacing.xs,
    },
    sectionContainer: {
        marginBottom: theme.spacing.lg,
    },
    sectionTitle: {
        ...theme.typography.heading.medium,
        color: theme.colors.text.primary,
        marginBottom: theme.spacing.md,
    },
    verseCard: {
        marginBottom: theme.spacing.md,
        borderRadius: theme.borderRadius.lg,
        borderWidth: 1,
        overflow: 'hidden',
        backgroundColor: theme.colors.background,
        ...Platform.select({
            ios: {
                shadowColor: theme.colors.primary,
                shadowOffset: { width: 0, height: 4 },
                shadowOpacity: 0.1,
                shadowRadius: 8,
            },
            android: {
                elevation: 4,
            },
        }),
    },
    verseContent: {
        padding: theme.spacing.md,
    },
    themeBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        alignSelf: 'flex-start',
        paddingHorizontal: theme.spacing.sm,
        paddingVertical: 6,
        borderRadius: theme.borderRadius.full,
        marginVertical: theme.spacing.md,
    },
    themeText: {
        ...theme.typography.caption.primary,
        fontSize: 12,
        marginLeft: 4,
    },
    moderatorBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        alignSelf: 'flex-start',
        paddingHorizontal: theme.spacing.sm,
        paddingVertical: 4,
        borderRadius: theme.borderRadius.full,
        marginBottom: theme.spacing.xs,
    },
    moderatorText: {
        ...theme.typography.caption.primary,
        fontSize: 12,
        marginLeft: 4,
    },
    verseHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: theme.spacing.sm,
    },
    verseReference: {
        ...theme.typography.verse.emphasis,
        fontSize: 16,
    },
    translation: {
        ...theme.typography.caption.secondary,
        color: theme.colors.text.secondary,
    },
    verseText: {
        ...theme.typography.verse.regular,
        color: theme.colors.text.primary,
        fontSize: 16,
        lineHeight: 24,
        marginBottom: theme.spacing.md,
    },
    verseFooter: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    voteCount: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: theme.spacing.xs,
    },
    voteText: {
        ...theme.typography.caption.secondary,
        color: theme.colors.text.secondary,
    },
    voteButton: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: theme.spacing.xs,
        paddingVertical: theme.spacing.xs,
        paddingHorizontal: theme.spacing.sm,
        borderRadius: theme.borderRadius.full,
    },
    votedButton: {
        opacity: 0.9,
    },
    voteButtonText: {
        ...theme.typography.caption.primary,
        fontSize: 12,
        fontWeight: '600',
    },
    toggleThemeButton: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: theme.spacing.xs,
        paddingHorizontal: theme.spacing.sm,
        borderRadius: theme.borderRadius.full,
        backgroundColor: theme.colors.surface,
    },
    toggleThemeText: {
        ...theme.typography.caption.primary,
        color: theme.colors.text.primary,
        marginRight: theme.spacing.xs,
    },
    emptyStateContainer: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
        padding: theme.spacing.xl,
    },
    emptyStateText: {
        ...theme.typography.body.serif,
        color: theme.colors.text.secondary,
        textAlign: 'center',
        marginTop: theme.spacing.md,
    },
    cardBorder: {
        borderTopWidth: 3,
        borderTopColor: 'transparent',
    },
    separatorText: {
        ...theme.typography.caption.secondary,
        color: theme.colors.text.secondary,
        textAlign: 'center',
        marginVertical: theme.spacing.md,
    },
    themeSummary: {
        marginTop: theme.spacing.md,
        padding: theme.spacing.md,
        backgroundColor: theme.colors.surface,
        borderRadius: theme.borderRadius.lg,
    },
    themeGrid: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: theme.spacing.sm,
        marginTop: theme.spacing.sm,
    },
    themeChip: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: 6,
        paddingHorizontal: theme.spacing.sm,
        borderRadius: theme.borderRadius.full,
        gap: 4,
    },
    infoIconContainer: {
        marginLeft: 'auto',
    },
    modalContainer: {
        backgroundColor: theme.colors.background,
        padding: theme.spacing.lg,
        borderRadius: theme.borderRadius.lg,
        maxWidth: '90%',
        width: 350,
    },
    modalTitle: {
        ...theme.typography.heading.medium,
        color: theme.colors.text.primary,
        marginBottom: theme.spacing.md,
    },
    modalContent: {
        ...theme.typography.body.sans,
        color: theme.colors.text.secondary,
        marginBottom: theme.spacing.lg,
    },
    closeButton: {
        alignSelf: 'flex-end',
        padding: theme.spacing.sm,
        marginTop: -theme.spacing.sm,
        marginRight: -theme.spacing.sm,
    },
});

export default React.memo(DailyVersesScreen);