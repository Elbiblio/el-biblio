// screens/MainFeed.tsx
import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  Text,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedScrollHandler,
  useAnimatedStyle,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import ReflectionCard from '../components/ReflectionCard';
import CommentsOverlay from '../components/CommentsOverlay';
import ProgressIndicator from '../components/AnimatedProgress';
import { VERSE_OF_DAY, SCREEN_DIMENSIONS } from '../constants';
import { Reflection } from '../types';
import { NavigationBreadcrumb } from '@/components/NavigationBreadcrumb';
import { getCurrentTheme } from '@/theme/store';

const theme = getCurrentTheme();

const MainFeed: React.FC = () => {
  const insets = useSafeAreaInsets();
  const [currentIndex, setCurrentIndex] = useState(0);
  const [showComments, setShowComments] = useState(false);
  const scrollX = useSharedValue(0) as unknown as Animated.SharedValue<number>;

  const reflections: Reflection[] = [
    {
      id: '1',
      author: {
        id: 'user1',
        first_name: 'Sarah',
        last_name: 'Mitchell',
        avatar: 'https://example.com/avatar.jpg'
      },
      content: "In moments of uncertainty...",
      type: 'story',
      icon: '✨',
      likes: 256,
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
          content: "Great reflection!",
          likes: 5,
          timestamp: '5m ago',
          isLiked: false
        }
        // ... more comments
      ],
      isLiked: false,
      timestamp: '2h ago'
    },
    // ... more reflections
  ];

  const scrollHandler = useAnimatedScrollHandler({
    onScroll: (event) => {
      scrollX.value = event.contentOffset.x;
    },
  });

  const handleScrollEnd = ({ nativeEvent }: { nativeEvent: { contentOffset: { x: number } } }) => {
    const index = Math.round(nativeEvent.contentOffset.x / SCREEN_DIMENSIONS.width);
    setCurrentIndex(index);
  };

  const headerStyle = useAnimatedStyle(() => {
    const opacity = interpolate(
      scrollX.value,
      [0, SCREEN_DIMENSIONS.width],
      [1, 0.7],
      Extrapolation.CLAMP
    );

    return {
      opacity
    };
  });

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <StatusBar style="dark" />
      {/* <NavigationBreadcrumb 
            steps={['Feed', 'Reflection', 'Comments']} 
            currentStep={0}
          /> */}

      {/* Verse Header */}
      <Animated.View style={[styles.verseHeader, headerStyle]}>
        <Text style={styles.verseText}>
          {VERSE_OF_DAY.verse}
          <Text style={styles.verseReference}> {VERSE_OF_DAY.reference}</Text>
        </Text>
      </Animated.View>

      {/* Reflections Feed */}
      <Animated.FlatList
        data={reflections}
        renderItem={({ item, index }) => (
          <ReflectionCard
            reflection={item}
            onExpandChange={() => {}}
            onSwipeChange={() => {}}
            onCommentSwipe={() => {}}
            onCommentPress={() => setShowComments(true)}
            scrollX={scrollX}
            index={index}
          />
        )}
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        onScroll={scrollHandler}
        onMomentumScrollEnd={handleScrollEnd}
        snapToInterval={SCREEN_DIMENSIONS.width}
        decelerationRate="fast"
        keyExtractor={item => item.id}
      />

      {/* Progress Indicators */}
      <View style={[styles.progressContainer, { bottom: insets.bottom + 8 }]}>
        {reflections.map((_, index) => (
          <ProgressIndicator
            key={index}
            scrollX={scrollX}
            index={index}
            total={reflections.length}
          />
        ))}
      </View>

      {/* Comments Overlay */}
      <CommentsOverlay
        visible={showComments}
        onClose={() => setShowComments(false)}
        reflection={reflections[currentIndex]}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  verseHeader: {
    backgroundColor: theme.colors.background,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: theme.colors.border,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  verseText: {
    ...theme.typography.verse.regular,
    color: theme.colors.text.primary,
  },
  verseReference: {
    ...theme.typography.verse.emphasis,
    color: theme.colors.primary,
    fontWeight: '500',
  },
  progressContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    position: 'absolute',
    left: 0,
    right: 0,
    gap: theme.spacing.xs,
  }
});

export default MainFeed;