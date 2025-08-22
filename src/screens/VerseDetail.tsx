import React, { useState, useRef, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  Platform,
  TextInput,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import {
  Heart,
  MessageCircle,
  Share,
  BookmarkSimple,
  ArrowLeft,
  Send,
  Copy,
} from '../components/Icons';
import ReflectionCard from '../components/ReflectionCard';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { Reflection, RootStackParamList } from '../types';
import { useTheme } from '@/contexts/ThemeContext';
import CommentsOverlay from '@/components/CommentsOverlay';
import { Theme } from '@/theme';
import { SCREEN_DIMENSIONS } from '@/constants';
import { useVerseStore } from '@/stores/verse';
import * as Clipboard from 'expo-clipboard';
import { useAuth } from '@/stores/auth';
import { toast } from 'sonner-native';

type VerseDetailProps = NativeStackScreenProps<RootStackParamList, 'VerseDetail'>;

const VerseDetail: React.FC<VerseDetailProps> = ({ navigation, route }) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const { user } = useAuth();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  
  // Store state and actions
  const {
    currentVerse,
    isVerseLoading,
    isReflectionsLoading,
    fetchVerseById,
    createInteraction,
    createReflection,
    createBookmark
  } = useVerseStore();

  // Local state
  const [currentReflectionIndex, setCurrentReflectionIndex] = useState(0);
  const [showReflectionInput, setShowReflectionInput] = useState(false);
  const [reflectionText, setReflectionText] = useState('');
  const [reflectionType, setReflectionType] = useState<1 | 2>(1); // 1: story, 2: insight
  const [activeCommentReflectionId, setActiveCommentReflectionId] = useState<string | null>(null);

  // Animated values
  const scrollY = useSharedValue(0);
  const scrollX = useSharedValue(0);
  const headerOpacity = useSharedValue(1);

  // Refs
  const flatListRef = useRef<FlatList>(null);

  // Load verse data
  useEffect(() => {
    const loadVerse = async () => {
      // First load verse without reflections for quick display
      await fetchVerseById(route.params.verse.id);
      // Then load with reflections
      await fetchVerseById(route.params.verse.id, true);
    };
    loadVerse();
  }, [route.params.verse.id]);

  // Event handlers
  const handleLike = async () => {
    if (!currentVerse || !user) {
      toast.info('Please log in to like verses');
      return;
    }
    
    try {
      await createInteraction({
        interactable_id: currentVerse.id,
        interactable_type: 'App\\Models\\Verse',
        type: 1, // Like
        user_id: user.id
      });
      toast.success(currentVerse.isLiked ? 'Verse unliked' : 'Verse liked');
    } catch (error) {
      toast.warning('Failed to like verse');
    }
  };

  const handleBookmark = async (clipText?: string) => {
    if (!currentVerse || !user) {
      toast.info('Please log in to bookmark verses');
      return;
    }
    
    try {
      await createBookmark({
        user_id: user.id,
        bookmarkable_type: 'App\\Models\\Verse',
        bookmarkable_id: currentVerse.id,
        clip_text: clipText
      });
      toast.success(currentVerse.isBookmarked ? 'Bookmark removed' : 'Verse bookmarked');
    } catch (error) {      
      toast.error('Failed to bookmark verse');
    }
  };

  const handleShare = async () => {
    if (!currentVerse) return;
    
    try {
      await createInteraction({
        interactable_id: currentVerse.id,
        interactable_type: 'App\\Models\\Verse',
        type: 3, // Share
        user_id: user?.id || ''
      });
      
      // todo: Implement sharing
      // await Share.share({
      //   message: `${currentVerse.text} (${currentVerse.reference})`
      // });
      
    } catch (error) {
      toast.error('Failed to share verse');
    }
  };

  const handleCopyVerse = async () => {
    if (!currentVerse) return;
    
    try {
      await Clipboard.setStringAsync(
        `${currentVerse.text} (${currentVerse.reference})`
      );
      toast.success('Verse copied to clipboard');
    } catch (error) {
      toast.error('Failed to copy verse');
    }
  };

  const handleSubmitReflection = async () => {
    if (!reflectionText.trim() || !currentVerse || !user) {
      if (!user) {
        toast.info('Please log in to share reflections');
      }
      return;
    }
    
    try {
      await createReflection({
        content: reflectionText.trim(),
        type: reflectionType,
        user_id: user.id,
        verse_id: currentVerse.id
      });
      
      setReflectionText('');
      setShowReflectionInput(false);
      toast.success('Reflection shared successfully');
    } catch (error) {
      toast.error('Failed to share reflection');
    }
  };

  // Animation styles
  const headerStyle = useAnimatedStyle(() => ({
    opacity: headerOpacity.value,
    transform: [{
      translateY: interpolate(
        scrollY.value,
        [0, 60],
        [0, -10],
        Extrapolation.CLAMP
      )
    }],
  }));

  const navigationStyle = useAnimatedStyle(() => ({
    opacity: interpolate(
      scrollY.value,
      [0, 100],
      [0.8, 1],
      Extrapolation.CLAMP
    ),
    backgroundColor: `${theme.colors.background}${
      interpolate(scrollY.value, [0, 100], [0, 99], Extrapolation.CLAMP)
        .toString(16)
        .padStart(2, '0')
    }`,
  }));

  const handleScroll = useCallback(({ nativeEvent }: { nativeEvent: any }) => {
    scrollY.value = nativeEvent.contentOffset.y;
    headerOpacity.value = withTiming(
      interpolate(
        nativeEvent.contentOffset.y,
        [0, 100],
        [1, 0],
        Extrapolation.CLAMP
      )
    );
  }, []);

  // Reflection rendering
  const renderReflection = useCallback(({ item, index }: { item: Reflection; index: number }) => (
    <ReflectionCard
      reflection={item}
      scrollX={scrollX}
      index={index}
      onCommentPress={() => setActiveCommentReflectionId(item.id)}
      expanded={false}
      onPress={() => navigation.navigate('ReflectionDetail', { reflection: item })}
    />
  ), [navigation]);

  const keyExtractor = useCallback((item: Reflection) => item.id, []);

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Navigation Header */}
      <Animated.View style={[styles.navigationHeader, navigationStyle]}>
        <TouchableOpacity 
          style={styles.backButton}
          onPress={() => navigation.goBack()}
        >
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.navigationTitle}>{currentVerse?.reference}</Text>
        <View style={styles.navigationRight} />
      </Animated.View>

      {/* Main Content */}
      <ScrollView
        style={styles.mainContent}
        onScroll={handleScroll}
        scrollEventThrottle={16}
        showsVerticalScrollIndicator={false}
      >
        {isVerseLoading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator color={theme.colors.primary} size="large" />
          </View>
        ) : currentVerse ? (
          <>
            {/* Verse Content */}
            <Animated.View style={[styles.verseContent, headerStyle]}>
              <Text style={styles.verseTitle}>
                {currentVerse.reference}
                <Text style={styles.translation}> · {currentVerse.translation}</Text>
              </Text>
              <Text style={styles.verseText}>{currentVerse.text}</Text>

              {/* Verse Actions */}
              <View style={styles.actionRow}>
                <View style={styles.actionGroup}>
                  <TouchableOpacity
                    style={styles.actionButton}
                    onPress={handleLike}
                  >
                    <Heart
                      size={24}
                      color={currentVerse.isLiked ? theme.colors.like : theme.colors.text.secondary}
                      filled={currentVerse.isLiked}
                    />
                    <Text style={styles.actionCount}>{currentVerse.likes}</Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={styles.actionButton}
                    onPress={() => setShowReflectionInput(true)}
                  >
                    <MessageCircle size={24} color={theme.colors.text.secondary} />
                    <Text style={styles.actionCount}>
                      {currentVerse.reflections?.length || 0}
                    </Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={styles.actionButton}
                    onPress={handleShare}
                  >
                    <Share size={24} color={theme.colors.text.secondary} />
                  </TouchableOpacity>
                </View>

                <TouchableOpacity
                  style={styles.actionButton}
                  onPress={() => handleBookmark()}
                >
                  <BookmarkSimple
                    size={24}
                    color={currentVerse.isBookmarked ? theme.colors.primary : theme.colors.text.secondary}
                    filled={currentVerse.isBookmarked}
                  />
                </TouchableOpacity>
              </View>

              <TouchableOpacity
                style={styles.copyButton}
                onPress={handleCopyVerse}
              >
                <Copy size={16} color={theme.colors.text.secondary} />
                <Text style={styles.copyText}>Copy Verse</Text>
              </TouchableOpacity>
            </Animated.View>

            {/* Reflections Section */}
            <View style={styles.reflectionsSection}>
              <Text style={styles.sectionTitle}>Reflections</Text>
              
              {isReflectionsLoading ? (
                <ActivityIndicator color={theme.colors.primary} />
              ) : currentVerse.reflections?.length ? (
                <FlatList
                  data={currentVerse.reflections}
                  renderItem={renderReflection}
                  keyExtractor={keyExtractor}
                  horizontal
                  showsHorizontalScrollIndicator={false}
                  snapToAlignment="center"
                  snapToInterval={SCREEN_DIMENSIONS.width - theme.spacing.md * 2}
                  decelerationRate="fast"
                  ref={flatListRef}
                  contentContainerStyle={styles.reflectionsList}
                />
              ) : (
                <View style={styles.emptyState}>
                  <Text style={styles.emptyText}>
                    No reflections yet. Be the first to share your thoughts!
                  </Text>
                </View>
              )}
            </View>
          </>
        ) : null}
      </ScrollView>

      {/* Reflection Input Modal */}
      {showReflectionInput && (
        <BlurView intensity={20} style={[styles.reflectionInputContainer, {paddingBottom: theme.spacing.lg + Platform.OS === "ios" ? 20 : 0 }]}>
          <View style={styles.reflectionTypeSelector}>
            <TouchableOpacity
              style={[
                styles.typeButton,
                reflectionType === 1 && styles.typeButtonActive
              ]}
              onPress={() => setReflectionType(1)}
            >
              <Text style={[
                styles.typeButtonText,
                reflectionType === 1 && styles.typeButtonTextActive
              ]}>Story</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.typeButton,
                reflectionType === 2 && styles.typeButtonActive
              ]}
              onPress={() => setReflectionType(2)}
            >
              <Text style={[
                styles.typeButtonText,
                reflectionType === 2 && styles.typeButtonTextActive
              ]}>Insight</Text>
            </TouchableOpacity>
          </View>
          
          <TextInput
            style={styles.reflectionInput}
            placeholder="Share your reflection..."
            multiline
            maxLength={500}
            value={reflectionText}
            onChangeText={setReflectionText}
            autoFocus
          />
          
          <View style={styles.inputActions}>
            <TouchableOpacity
              style={styles.cancelButton}
              onPress={() => setShowReflectionInput(false)}
            >
              <Text style={styles.cancelText}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.submitButton,
                !reflectionText.trim() && styles.submitButtonDisabled
              ]}
              onPress={handleSubmitReflection}
              disabled={!reflectionText.trim()}
            >
              <Text style={styles.submitText}>Share</Text>
              <Send size={16} color={theme.colors.text.inverse} />
            </TouchableOpacity>
          </View>
        </BlurView>
      )}

      {/* Comments Overlay */}
      {activeCommentReflectionId && currentVerse?.reflections && (
        <CommentsOverlay
          visible={true}
          onClose={() => setActiveCommentReflectionId(null)}
          reflection={currentVerse.reflections.find(
            (r: Reflection) => r.id === activeCommentReflectionId
          )!}
        />
      )}
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  navigationHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: theme.colors.border,
  },
  backButton: {
    padding: theme.spacing.xs,
  },
  navigationTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  navigationRight: {
    width: 40, // Balance layout with back button
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme.spacing.xl * 2,
  },
  mainContent: {
    flex: 1,
  },
  verseContent: {
    padding: theme.spacing.lg,
  },
  verseTitle: {
    ...theme.typography.verse.emphasis,
    color: theme.colors.primary,
    fontSize: 20,
    marginBottom: theme.spacing.sm,
  },
  translation: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  verseText: {
    ...theme.typography.verse.regular,
    color: theme.colors.text.primary,
    fontSize: 24,
    lineHeight: 36,
    marginBottom: theme.spacing.lg,
  },
  actionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: theme.spacing.sm,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderColor: theme.colors.border,
  },
  actionGroup: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.md,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    padding: theme.spacing.xs,
  },
  actionCount: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  copyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    alignSelf: 'flex-start',
    backgroundColor: theme.colors.surface,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
    marginTop: theme.spacing.sm,
  },
  copyText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  reflectionsSection: {
    paddingTop: theme.spacing.xl,
  },
  sectionTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    paddingHorizontal: theme.spacing.lg,
    marginBottom: theme.spacing.md,
  },
  reflectionsList: {
    paddingHorizontal: theme.spacing.md,
  },
  emptyState: {
    padding: theme.spacing.xl,
    alignItems: 'center',
  },
  emptyText: {
    ...theme.typography.body.serif,
    color: theme.colors.text.secondary,
    textAlign: 'center',
  },
  reflectionInputContainer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: theme.spacing.lg,
  },
  reflectionTypeSelector: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
    marginBottom: theme.spacing.md,
  },
  typeButton: {
    flex: 1,
    padding: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
  },
  typeButtonActive: {
    backgroundColor: theme.colors.primary,
  },
  typeButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  typeButtonTextActive: {
    color: theme.colors.text.inverse,
  },
  reflectionInput: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    maxHeight: 120,
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  inputActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'center',
    gap: theme.spacing.sm,
    marginTop: theme.spacing.sm,
  },
  cancelButton: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  cancelText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  submitButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    backgroundColor: theme.colors.primary,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
  },
  submitButtonDisabled: {
    opacity: 0.5,
  },
  submitText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
});

export default VerseDetail;