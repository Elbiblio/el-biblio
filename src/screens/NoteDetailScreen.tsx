import React, { useEffect, useMemo, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  StatusBar,
  Animated,
  Image,
  ImageBackground,
  Share,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { BlurView } from 'expo-blur';

import { ArrowLeft, Heart, Share as ShareIcon, BookOpen, User, Calendar, Pin, Globe } from '../components/Icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { RootStackParamList, Note } from '@/types';
import { formatDistanceToNow } from 'date-fns';
import FormattedContent from '@/components/NoteEditor/FormattedContent';
import { useNoteStore } from '@/stores/notes';
import { SCREEN_DIMENSIONS } from '@/constants';
import { LinearGradient } from 'expo-linear-gradient';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import Svg, { Path } from 'react-native-svg';
import FooterFlourish from '@/components/FooterFlourish';

const NoteDetailScreen: React.FC<NativeStackScreenProps<RootStackParamList, 'NoteDetail'>> =
 ({ navigation, route }) => {
  const { noteId } = route.params;
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const { notes, fetchNote, togglePin } = useNoteStore();
  const [note, setNote] = useState<Note | null>(null);
  const [loadingNote, setLoadingNote] = useState(true);
  const [scrollY] = useState(new Animated.Value(0));

  // Animation values for page turn effect
  const [pageOffset] = useState(new Animated.Value(0));
  const SVGDivider = () => (
    <Svg width="120" height="12" viewBox="0 0 120 12">
      <Path 
        d="M0 6 Q30 0 60 6 T120 6"
        stroke={theme.colors.text.secondary}
        strokeWidth="1"
        fill="none"
        strokeOpacity="0.3"
      />
  </Svg>);
  
  useEffect(() => {
    const loadNote = async () => {
      setLoadingNote(true);
      try {
        // First check if note is already in the store
        const existingNote = notes.find(n => n.id === noteId);
        if (existingNote) {
          setNote(existingNote);
        } else {
          // If not, fetch it from the server
          const fetchedNote = await fetchNote(noteId.toString(10));
          if (fetchedNote) {
            setNote(fetchedNote);
          }
        }
      } catch (error) {
        console.error('Error loading note:', error);
      } finally {
        setLoadingNote(false);
      }
    };

    loadNote();
  }, [noteId, fetchNote, notes]);

  const handleShare = async () => {
    if (!note) return;

    try {
      await Share.share({
        message: `${note.title}\n\n${note.text}\n\nShared from Virtues Journal`,
      });
    } catch (error) {
      console.error('Error sharing note:', error);
    }
  };

  const handleToggleFavorite = async () => {
    if (!note) return;
    await togglePin(note.id);
    setNote(prev => prev ? { ...prev, isPinned: !prev.isPinned } : null);
  };

  const headerOpacity = scrollY.interpolate({
    inputRange: [0, 100],
    outputRange: [0, 1],
    extrapolate: 'clamp',
  });

  const titleOpacity = scrollY.interpolate({
    inputRange: [0, 50, 100],
    outputRange: [1, 0.7, 0],
    extrapolate: 'clamp',
  });

  if (loadingNote || !note) {
    return (
      <View style={[styles.container, styles.loadingContainer]}>
        <BookOpen size={48} color={`${theme.colors.primary}80`} />
        <Text style={styles.loadingText}>Opening note...</Text>
      </View>
    );
  }

  const dateFormatted = note.updatedAt
    ? formatDistanceToNow(new Date(note.updatedAt), { addSuffix: true })
    : '';

  return (
    <View style={styles.container}>
      <StatusBar barStyle="dark-content" />

      {/* Animated header that appears when scrolling */}
      <Animated.View style={[
        styles.animatedHeader,
        { opacity: headerOpacity, paddingTop: insets.top }
      ]}>
        <BlurView intensity={80} style={StyleSheet.absoluteFill} />
        <View style={styles.headerContent}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
            <ArrowLeft size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle} numberOfLines={1}>{note.title}</Text>
          <View style={styles.spacer} />
        </View>
      </Animated.View>

      {/* Main scrollable content */}
      <Animated.ScrollView
        style={styles.scrollView}
        contentContainerStyle={[styles.scrollContent, { paddingTop: insets.top + 20 }]}
        showsVerticalScrollIndicator={false}
        onScroll={Animated.event(
          [{ nativeEvent: { contentOffset: { y: scrollY } } }],
          { useNativeDriver: true }
        )}
        scrollEventThrottle={16}
      >
        {/* Decorative book top edge */}
        <View style={styles.bookEdge}>
          <View style={styles.bookBinding} />
          <View style={styles.bookShadow} />
        </View>

        {/* Page content with paper texture */}
        <View style={styles.pageBackground}>
          <View style={[styles.pageEdgeShadow, { top: 0 }]} />
          <View style={[styles.pageEdgeShadow, { bottom: 0 }]} />
  
          <LinearGradient
            colors={['rgba(0,0,0,0.015)', 'rgba(0,0,0,0.0)', 'rgba(0,0,0,0.015)']}
            locations={[0, 0.5, 1]}
            style={StyleSheet.absoluteFill}
          />
          <View style={styles.paperOverlay} />

          <View style={styles.pageContent}>
            {/* Title section */}
            <Animated.View style={[styles.titleContainer, { opacity: titleOpacity }]}>
              <Text style={styles.noteTitle}>{note.title}</Text>

              {/* Metadata row - virtues */}
              {note.virtues && note.virtues.length > 0 && (
                <View style={styles.virtuesContainer}>
                  {note.virtues.map(virtue => (
                    <View key={virtue} style={styles.virtueBadge}>
                      <Text style={styles.virtueText}>{virtue}</Text>
                    </View>
                  ))}
                </View>
              )}

              {/* Metadata row */}
              <View style={styles.metadataContainer}>
                {note.author && (
                  <View style={styles.metadataItem}>
                    <User size={14} color={theme.colors.text.secondary} />
                    <Text style={styles.metadataText}>{note.author.first_name} {note.author.last_name}</Text>
                  </View>
                )}

                {dateFormatted && (
                  <View style={styles.metadataItem}>
                    <Calendar size={14} color={theme.colors.text.secondary} />
                    <Text style={styles.metadataText}>{dateFormatted}</Text>
                  </View>
                )}

                {note.is_public && (
                  <View style={styles.metadataItem}>
                    <Globe size={14} color={theme.colors.text.secondary} />
                    <Text style={styles.metadataText}>Public</Text>
                  </View>
                )}

                {note.isPinned && (
                  <View style={styles.metadataItem}>
                    <Pin size={14} color={theme.colors.text.secondary} />
                    <Text style={styles.metadataText}>Pinned</Text>
                  </View>
                )}
              </View>

              {/* Divider with decorative element */}
              <View style={styles.decorativeDivider}>
                <View style={styles.dividerLine} />
                <SVGDivider />
                <View style={styles.dividerLine} />
              </View>
            </Animated.View>

            {/* Note content */}
            <FormattedContent content={note.text} theme={theme} />

            {/* Footer with page number */}
            <View style={styles.pageFooter}>
              <FooterFlourish />
            </View>
          </View>
        </View>
      </Animated.ScrollView>

      {/* Bottom action bar */}
      <View style={[styles.bottomBar, { paddingBottom: insets.bottom || 16 }]}>
        <TouchableOpacity
          style={styles.backButton}
          onPress={() => navigation.goBack()}
        >
          <ArrowLeft size={20} color={theme.colors.text.primary} />
          <Text style={styles.backText}>Back</Text>
        </TouchableOpacity>

        <View style={styles.actionButtons}>
          {note.is_public && (
            <TouchableOpacity
              style={[styles.actionButton, note.isPinned && styles.actionButtonActive]}
              onPress={handleToggleFavorite}
            >
              <Heart
                size={20}
                filled={note.isPinned}
                color={note.isPinned ? theme.colors.text.inverse : theme.colors.text.primary}
              />
            </TouchableOpacity>
          )}

          <TouchableOpacity
            style={styles.actionButton}
            onPress={handleShare}
          >
            <ShareIcon size={20} color={theme.colors.text.primary} />
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  loadingContainer: {
    justifyContent: 'center',
    alignItems: 'center',
    gap: 16,
  },
  loadingText: {
    ...theme.typography.body.serif,
    color: theme.colors.text.secondary,
  },
  animatedHeader: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 10,
    height: 60,
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.md,
    height: '100%',
  },
  headerTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginLeft: theme.spacing.md,
    flex: 1,
  },
  spacer: {
    width: 24,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 100,
  },
  bookEdge: {
    height: 8,
    marginHorizontal: theme.spacing.lg,
    marginBottom: -1,
    backgroundColor: '#e0d8c0',
    borderTopLeftRadius: 4,
    borderTopRightRadius: 4,
    flexDirection: 'row',
    overflow: 'hidden',
  },
  bookBinding: {
    width: 80,
    height: '100%',
    left: '50%',
    marginLeft: -40,
    backgroundColor: '#d0c8b0',
  },
  bookShadow: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    height: '100%',
    backgroundColor: 'rgba(0,0,0,0.1)',
  },
  pageBackground: {
    marginHorizontal: theme.spacing.lg,
    borderRadius: 2,
    backgroundColor: theme.colors.paper,
    borderWidth: 1,
    borderColor: theme.colors.paperBorder,
    shadowColor: theme.colors.paperShadow,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
    elevation: 5,
    overflow: 'hidden',
  },
  paperOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.6)',
  },
  pageEdgeShadow: {
    position: 'absolute',
    height: 6,
    left: 0,
    right: 0,
    backgroundColor: 'rgba(0,0,0,0.04)',
  },
  textureImage: {
    resizeMode: 'repeat',
    opacity: 0.07,
  },
  pageContent: {
    padding: theme.spacing.lg,
    minHeight: SCREEN_DIMENSIONS.height * 0.8,
  },
  titleContainer: {
    marginBottom: theme.spacing.xl,
  },
  noteTitle: {
    ...theme.typography.heading.large,
    color: theme.colors.text.primary,
    fontFamily: 'Georgia',
    marginBottom: theme.spacing.md,
    textAlign: 'center',
  },
  virtuesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: theme.spacing.xs,
    marginBottom: theme.spacing.sm,
  },
  virtueBadge: {
    backgroundColor: `${theme.colors.primary}15`,
    paddingVertical: 4,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
  },
  virtueText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontSize: 12,
  },
  metadataContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: theme.spacing.md,
    marginVertical: theme.spacing.sm,
  },
  metadataItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  metadataText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontSize: 12,
  },
  decorativeDivider: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: theme.spacing.lg,
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: `${theme.colors.text.secondary}30`,
  },
  dividerOrnament: {
    width: 60,
    height: 20,
    resizeMode: 'contain',
    marginHorizontal: theme.spacing.md,
    tintColor: `${theme.colors.text.secondary}60`,
  },
  pageNumber: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontSize: 12,
    fontFamily: 'Georgia',
    alignSelf: 'center',
    marginTop: theme.spacing.lg,
  },
  bottomBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: theme.colors.background,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: theme.spacing.md,
    borderTopWidth: 1,
    borderTopColor: theme.colors.border,
  },
  backButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  backText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  actionButtons: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
  },
  actionButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionButtonActive: {
    backgroundColor: theme.colors.primary,
  },
  pageFooter: {
    alignItems: 'center',
    marginTop: theme.spacing.xl * 2,
  },
  footerOrnament: {
    width: 120,
    height: 30,
    resizeMode: 'contain',
    tintColor: `${theme.colors.text.secondary}40`,
  },
});

export default NoteDetailScreen; 