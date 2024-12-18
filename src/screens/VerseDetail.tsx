import React, { useState, useRef, useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  Platform,
  TextInput,
  Dimensions,
  ViewToken,
  NativeScrollEvent,
  NativeSyntheticEvent,
  ScrollView,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  interpolate,
  withSequence,
  Extrapolation,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import {
  Heart,
  MessageCircle,
  Share,
  BookmarkSimple,
  ArrowLeft,
  Sparkle,
  Send,
  Copy,
} from '../components/Icons';
import ReflectionCard from '../components/ReflectionCard';
import ReflectionDivider from '../components/ReflectionDivider';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { Reflection, RootStackParamList } from '../types';
import { useTheme } from '@/contexts/ThemeContext';
import { getCurrentTheme, useThemeStore } from '@/theme/store';
import CommentsOverlay from '@/components/CommentsOverlay';
import { Theme } from '@/theme';
import { SCREEN_DIMENSIONS, wp } from '@/constants';
import ScrollIndicator from '@/components/ScrollIndicator';

type VerseDetailProps = NativeStackScreenProps<RootStackParamList, 'VerseDetail'>;

interface ViewableItemsChanged {
  viewableItems: ViewToken[];
  changed: ViewToken[];
}

const VerseDetail: React.FC<VerseDetailProps> = ({ navigation, route }) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const [currentReflectionIndex, setCurrentReflectionIndex] = useState(0);
  const [showReflectionInput, setShowReflectionInput] = useState(false);
  const [reflectionText, setReflectionText] = useState('');
  const [isBookmarked, setIsBookmarked] = useState(false);
  const [isLiked, setIsLiked] = useState(false);
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  // Animated values
  const bookmarkScale = useSharedValue(1);
  const likeScale = useSharedValue(1);
  const scrollX = useSharedValue(0);
  const scrollY = useSharedValue(0);

  // Refs
  const flatListRef = useRef<FlatList>(null);
  const reflectionInputRef = useRef<TextInput>(null);

  const verse = {
    id: route.params.verseId,
    text: "But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint.",
    reference: "Isaiah 40:31",
    translation: "NIV",
    likes: 342,
    reflections: 24,
    shares: 56,
    trending: true,
  };

  const reflections: Reflection[] = [
    {
      id: '1',
      author: {
        id: 'user1',
        first_name: 'Sarah',
        last_name: 'Mitchell',
        avatar: 'https://example.com/avatar1.jpg'
      },
      content: "This verse reminds me that in our most exhausting moments, God provides the strength we need. It's not about our own power, but about trusting in His timing and purposes.",
      timestamp: '2h ago',
      likes: 42,
      type: 'story',
      icon: '✨',
      isLiked: false,
      comments: [
        {
          id: 'comment1',
          parentId: null,
          author: {
            id: 'user2',
            first_name: 'John',
            last_name: 'Doe',
            avatar: 'https://example.com/john.jpg'
          },
          content: "Such a beautiful reminder of God's faithfulness. Thank you for sharing!",
          likes: 15,
          timestamp: '5m ago',
          isLiked: false
        }
      ],
    },
    // Add more reflections here...
  ];

  // Viewability config for FlatList
  const viewabilityConfig = useRef({
    itemVisiblePercentThreshold: 50,
    minimumViewTime: 100,
  }).current;

  const onViewableItemsChanged = useCallback(({ viewableItems }: ViewableItemsChanged) => {
    if (viewableItems.length > 0) {
      const index = viewableItems[0].index ?? 0;
      setCurrentReflectionIndex(index);
    }
  }, []);

  const viewabilityConfigCallbackPairs = useRef([
    { viewabilityConfig, onViewableItemsChanged },
  ]).current;

  // Animation styles
  const headerStyle = useAnimatedStyle(() => ({
    opacity: interpolate(
      scrollY.value,
      [0, 100],
      [1, 0.2],
      Extrapolation.CLAMP
    ),
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
      [0, 1],
      Extrapolation.CLAMP
    ),
  }));

  // Event handlers
  const handleScroll = (event: NativeSyntheticEvent<NativeScrollEvent>) => {
    const { x, y } = event.nativeEvent.contentOffset;
    scrollX.value = x;
    scrollY.value = y;
  };

  const handleBookmark = () => {
    setIsBookmarked(!isBookmarked);
    bookmarkScale.value = withSequence(
      withSpring(1.2),
      withSpring(1)
    );
  };

  const handleLike = () => {
    setIsLiked(!isLiked);
    likeScale.value = withSequence(
      withSpring(1.2),
      withSpring(1)
    );
  };

  const handleShare = async () => {
    // Implement share functionality
  };

  const handleCopyVerse = () => {
    // Implement copy functionality
  };

  const handleSubmitReflection = () => {
    if (reflectionText.trim()) {
      // Submit reflection logic
      setReflectionText('');
      setShowReflectionInput(false);
    }
  };

  const renderVerseHeader = useCallback(() => (
    <Animated.View style={[styles.verseHeader, headerStyle]}>
      <View style={styles.verseReference}>
        <Text style={styles.referenceText}>
          {verse.reference}
        </Text>
        <Text style={styles.translationText}>
          {verse.translation}
        </Text>
      </View>
      <Text style={styles.verseText}>{verse.text}</Text>

      <View style={styles.verseActions}>
        <View style={styles.actionRow}>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={handleLike}
          >
            <Animated.View style={{ transform: [{ scale: likeScale }] }}>
              <Heart
                size={24}
                color={isLiked ? theme.colors.like : theme.colors.text.secondary}
                filled={isLiked}
              />
            </Animated.View>
            <Text style={styles.actionCount}>{verse.likes}</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.actionButton}
            onPress={() => setShowReflectionInput(true)}
          >
            <MessageCircle size={24} color={theme.colors.text.secondary} />
            <Text style={styles.actionCount}>{verse.reflections}</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.actionButton}
            onPress={handleShare}
          >
            <Share size={24} color={theme.colors.text.secondary} />
            <Text style={styles.actionCount}>{verse.shares}</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.actionButton}
            onPress={handleBookmark}
          >
            <Animated.View style={{ transform: [{ scale: bookmarkScale }] }}>
              <BookmarkSimple
                size={24}
                color={isBookmarked ? theme.colors.primary : theme.colors.text.secondary}
                filled={isBookmarked}
              />
            </Animated.View>
          </TouchableOpacity>
        </View>

        <TouchableOpacity
          style={styles.copyButton}
          onPress={handleCopyVerse}
        >
          <Copy size={16} color={theme.colors.text.secondary} />
          <Text style={styles.copyText}>Copy Verse</Text>
        </TouchableOpacity>
      </View>
    </Animated.View>
  ), [verse, isLiked, isBookmarked, theme]);

  const [activeCommentReflectionId, setActiveCommentReflectionId] = useState<string | null>(null);

  const handleCommentPress = useCallback((reflectionId: string) => {
    setActiveCommentReflectionId(reflectionId);
    navigation.navigate('ReflectionDetail', { reflectionId });
  }, [navigation]);

  const renderReflection = useCallback(({ item, index }: { item: Reflection; index: number }) => (
    <View style={[
      styles.reflectionWrapper,
      { width: SCREEN_DIMENSIONS.width - theme.spacing.md * 2 }
    ]}>
      <ReflectionCard
        reflection={item}
        scrollX={scrollX}
        index={index}
        onCommentPress={() => handleCommentPress(item.id)}
        expanded={false}
        onPress={() => navigation.navigate('ReflectionDetail', { reflectionId: item.id })}
        maxContentLines={3}
      />
    </View>
  ), [theme.spacing.md, handleCommentPress, navigation]);

  const keyExtractor = useCallback((item: Reflection) => item.id, []);

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Navigation Header */}
      <Animated.View style={[styles.navigationHeader, navigationStyle]}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
      </Animated.View>
  
      {/* Main Scrollable Content */}
      <ScrollView
        style={styles.mainContent}
        onScroll={handleScroll}
        scrollEventThrottle={16}
        showsVerticalScrollIndicator={false}
      >
        {/* Verse Header */}
        {renderVerseHeader()}
        
        {/* Reflections Section */}
        <View style={styles.reflectionsContainer}>
          <Text style={styles.sectionTitle}>Reflections</Text>
          
          {/* Reflection Cards */}
          <View style={styles.reflectionsWrapper}>
            <ScrollIndicator 
              direction="left" 
              onPress={() => {
                if (currentReflectionIndex > 0) {
                  flatListRef.current?.scrollToIndex({ 
                    index: currentReflectionIndex - 1,
                    animated: true 
                  });
                }
              }}
              visible={currentReflectionIndex > 0}
            />
            
            <FlatList
              data={reflections}
              renderItem={renderReflection}
              keyExtractor={keyExtractor}
              horizontal
              pagingEnabled
              showsHorizontalScrollIndicator={false}
              onScroll={handleScroll}
              scrollEventThrottle={16}
              ref={flatListRef}
              viewabilityConfigCallbackPairs={viewabilityConfigCallbackPairs}
              snapToAlignment="center"
              ItemSeparatorComponent={() => (
                <View style={{ width: theme.spacing.md }} />
              )}
              getItemLayout={(data, index) => ({
                length: SCREEN_DIMENSIONS.width - theme.spacing.md * 2,
                offset: (SCREEN_DIMENSIONS.width - theme.spacing.md * 2) * index,
                index,
              })}
              snapToInterval={SCREEN_DIMENSIONS.width - theme.spacing.md * 2}
              decelerationRate="fast"
              contentContainerStyle={styles.reflectionsList}
            />
  
            <ScrollIndicator 
              direction="right" 
              onPress={() => {
                if (currentReflectionIndex < reflections.length - 1) {
                  flatListRef.current?.scrollToIndex({ 
                    index: currentReflectionIndex + 1,
                    animated: true 
                  });
                }
              }}
              visible={reflections.length > 1 && currentReflectionIndex < reflections.length - 1}
            />
          </View>
        </View>
        
        {/* Bottom Padding */}
        <View style={{ height: theme.spacing.xl }} />
      </ScrollView>
  
      {/* Reflection Input */}
      {showReflectionInput && (
        <BlurView intensity={20} style={styles.reflectionInputContainer}>
          <TextInput
            ref={reflectionInputRef}
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
          
    <CommentsOverlay
      visible={activeCommentReflectionId !== null}
      onClose={() => setActiveCommentReflectionId(null)}
      reflection={reflections.find(r => r.id === activeCommentReflectionId)!}
    />
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
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    gap: theme.spacing.md,
    backgroundColor: theme.colors.background,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 4,
      },
    }),
  },
  mainContent: {
    flex: 1,
  },
  reflectionsContainer: {
    paddingTop: theme.spacing.lg,
  },
  reflectionsWrapper: {
    position: 'relative',
    paddingVertical: theme.spacing.md,
  },
  sectionTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    paddingHorizontal: theme.spacing.md,
    marginBottom: theme.spacing.md,
  },
  reflectionsList: {
    paddingHorizontal: theme.spacing.md,
  },
  reflectionWrapper: {
    width: SCREEN_DIMENSIONS.width - theme.spacing.md * 2,
  },
  scrollContent: {
    paddingBottom: theme.spacing.xl,
  },
  verseHeader: {
    padding: theme.spacing.md,
    backgroundColor: theme.colors.background,
  },
  trendingBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    backgroundColor: `${theme.colors.primary}15`,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    marginBottom: theme.spacing.sm,
    gap: 4,
  },
  trendingText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.primary,
    fontSize: 12,
    fontWeight: '600',
  },
  verseText: {
    ...theme.typography.verse.regular,
    color: theme.colors.text.primary,
    fontSize: 24,
    lineHeight: 36,
    marginBottom: theme.spacing.sm,
  },
  verseReference: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    marginBottom: theme.spacing.md,
  },
  referenceText: {
    ...theme.typography.verse.emphasis,
    color: theme.colors.primary,
    fontSize: 18,
  },
  translationText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  verseActions: {
    gap: theme.spacing.sm,
  },
  actionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: theme.spacing.sm,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderColor: theme.colors.border,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    padding: theme.spacing.sm,
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
  },
  copyText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  reflectionsSection: {
    padding: theme.spacing.md,
    paddingBottom: 0,
  },
  reflectionInputContainer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: theme.spacing.md,
    backgroundColor: `${theme.colors.background}99`,
  },
  reflectionInput: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    maxHeight: 120,
    ...theme.typography.body.sans,
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