import React, { useState, useRef } from 'react';
import { observer } from 'mobx-react-lite';
import {
  View,
  Text,
  Image,
  StyleSheet,
  TouchableOpacity,
  TouchableWithoutFeedback,
  Platform,
  ViewStyle,
  FlatList,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  interpolate,
  Extrapolation,
  SharedValue,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { Video, ResizeMode, AVPlaybackStatus } from 'expo-av';
import { Share as RNShare } from 'react-native';
import { Heart, MessageCircle, Share, BookmarkSimple, ChevronRight, ArrowRightPlay, Clock } from './Icons';
import CommentThread from './CommentThread';
import { useTheme } from '@/contexts/ThemeContext';
import { ReflectionType, type Reflection, type Comment } from '@/types';
import { extractUniqueCommenters } from '@/utils/comments';
import { SCREEN_DIMENSIONS, wp } from '@/constants';
import CircleButton from './CircleButton';
import { Theme } from '@/theme';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Haptics from 'expo-haptics';

interface ReflectionCardProps {
  reflection: Reflection;
  onCommentPress: () => void;
  scrollX: SharedValue<number>;
  index: number;
  expanded?: boolean;
  onPress?: () => void;
  maxContentLines?: number;
  showComments?: boolean;
  style?: ViewStyle;
}

const ReflectionCard: React.FC<ReflectionCardProps> = ({
  reflection,
  onCommentPress,
  scrollX,
  index,
  expanded = false,
  onPress,
  maxContentLines = expanded ? undefined : 3,
  showComments = expanded,
  style,
}) => {
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const [liked, setLiked] = useState(reflection.isLiked);
  const cardElevation = useSharedValue(1);
  const videoRef = useRef<Video | null>(null);
  const overlayAlpha = useSharedValue(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const lastSavedRef = useRef<number>(0);
  const lastTapRef = useRef<number>(0);
  const heartScale = useSharedValue(0);
  const heartOpacity = useSharedValue(0);
  const [muted, setMuted] = useState<boolean>(true);

  const topComment = (reflection.comments ?? [])[0];

  // Animation configs
  const springConfig = {
    damping: 15,
    stiffness: 90,
  };

  // Animated styles
  const cardAnimatedStyle = useAnimatedStyle(() => {
    if (!expanded) return {};

    const scale = interpolate(
      cardElevation.value,
      [1, 5],
      [1, 1.02],
      Extrapolation.CLAMP
    );

    const shadowOpacity = interpolate(
      cardElevation.value,
      [1, 5],
      [0.1, 0.2],
      Extrapolation.CLAMP
    );

    return {
      transform: [{ scale }],
      shadowOpacity,
    };
  });
 
  // Card content
  const renderHeader = () => {
    const authorName = `${reflection?.user?.first_name ?? ''} ${reflection?.user?.last_name ?? ''}`.trim() || 'User';
    const avatarUri = reflection?.user?.avatar;
    return (
      <View style={styles.header}>
        {avatarUri ? (
          <Image source={{ uri: avatarUri }} style={styles.avatar} />
        ) : (
          <View style={[styles.avatar, { backgroundColor: theme.colors.surface }]} />
        )}
        <View style={styles.authorInfo}>
          <Text style={[styles.authorName, { color: theme.colors.text.primary }]}>
            {authorName}
          </Text>
          <Text style={[styles.reflectionType, { color: theme.colors.text.secondary }]}>
            {reflection.type === ReflectionType.Story ? 'Sharing a story' : 'Sharing an insight'}
          </Text>
        </View>
        <View style={[styles.iconContainer, { backgroundColor: theme.colors.surface }]}>
          <Text style={styles.icon}>{reflection.icon ?? ''}</Text>
        </View>
      </View>
    );
  };

  const formatDuration = (secs?: number | null) => {
    if (!secs || secs <= 0) return null;
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${m}:${s.toString().padStart(2, '0')}`;
  };

  const showOverlayBriefly = () => {
    overlayAlpha.value = withTiming(1, { duration: 150 });
    setTimeout(() => {
      overlayAlpha.value = withTiming(0, { duration: 300 });
    }, 1200);
  };

  const handleMediaTap = async () => {
    const now = Date.now();
    if (now - lastTapRef.current < 300) {
      // Double tap to like
      if (!liked) setLiked(true);
      triggerHeartBurst();
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      showOverlayBriefly();
      lastTapRef.current = 0;
      return;
    }
    lastTapRef.current = now;

    const inst = videoRef.current;
    if (!inst) return;
    const status = await inst.getStatusAsync();
    if ('isPlaying' in status && status.isPlaying) {
      await inst.pauseAsync();
      setIsPlaying(false);
    } else {
      await inst.playAsync();
      setIsPlaying(true);
    }
    showOverlayBriefly();
  };

  const overlayStyle = useAnimatedStyle(() => ({ opacity: overlayAlpha.value }));
  const heartBurstStyle = useAnimatedStyle(() => ({
    opacity: heartOpacity.value,
    transform: [{ scale: heartScale.value }],
  }));

  const triggerHeartBurst = () => {
    heartOpacity.value = 1;
    heartScale.value = 0.6;
    heartScale.value = withSpring(1.2, { damping: 10, stiffness: 120 });
    // fade out after brief delay
    heartOpacity.value = withTiming(0, { duration: 650 });
  };

  const handleToggleLike = () => {
    const next = !liked;
    setLiked(next);
    if (next) {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      triggerHeartBurst();
    }
  };

  const onVideoLoad = React.useCallback(async () => {
    try {
      const key = `reflection_progress_${reflection.id}`;
      const saved = await AsyncStorage.getItem(key);
      const pos = saved ? parseInt(saved, 10) : 0;
      const mutePref = await AsyncStorage.getItem('video_muted_pref');
      if (mutePref === 'true' || mutePref === 'false') setMuted(mutePref === 'true');
      if (videoRef.current && pos > 2) {
        await videoRef.current.setPositionAsync(pos * 1000);
      }
    } catch {}
  }, [reflection.id]);

  const onPlaybackUpdate = React.useCallback((status: AVPlaybackStatus) => {
    if (!status.isLoaded) return;
    const seconds = Math.floor((status.positionMillis || 0) / 1000);
    setIsPlaying(!!status.isPlaying);
    if (seconds - lastSavedRef.current >= 2) {
      lastSavedRef.current = seconds;
      AsyncStorage.setItem(`reflection_progress_${reflection.id}`, String(seconds)).catch(() => {});
    }
  }, [reflection.id]);

  React.useEffect(() => {
    return () => {
      try { videoRef.current?.pauseAsync?.(); } catch {}
      try { videoRef.current?.unloadAsync?.(); } catch {}
    };
  }, []);

  const renderContent = () => (
    <View style={styles.contentContainer}>
      {/* Video (Face2Face) if available */}
      {!!reflection.media_url && (
        <View style={styles.mediaContainer}>
          <TouchableWithoutFeedback onPress={handleMediaTap}>
            <Video
              style={styles.video}
              source={{ uri: reflection.media_url }}
              useNativeControls
              isLooping={false}
              isMuted={muted}
              posterSource={reflection.thumbnail_url ? { uri: reflection.thumbnail_url } : undefined}
              posterStyle={styles.video}
              resizeMode={ResizeMode.COVER}
              ref={(r) => (videoRef.current = r)}
              onLoad={onVideoLoad}
              onPlaybackStatusUpdate={onPlaybackUpdate}
            />
          </TouchableWithoutFeedback>
          {/* Mute toggle */}
          <View style={styles.muteChipContainer}>
            <TouchableOpacity
              style={[styles.quickBtn, { backgroundColor: `${theme.colors.background}CC` }]}
              onPress={async () => {
                const next = !muted;
                setMuted(next);
                try { await AsyncStorage.setItem('video_muted_pref', next ? 'true' : 'false'); } catch {}
              }}
            >
              <Text style={styles.quickText}>{muted ? 'Muted' : 'Sound on'}</Text>
            </TouchableOpacity>
          </View>
          {/* Play overlay (decorative) */}
          <Animated.View pointerEvents="none" style={[styles.playOverlay, overlayStyle]}>
            <View style={[styles.playButton, { backgroundColor: `${theme.colors.background}90` }]}> 
              <ArrowRightPlay size={24} color={theme.colors.text.primary} />
            </View>
          </Animated.View>
          {/* Quick actions on media */}
          <View style={styles.mediaQuickActions}>
            <TouchableOpacity style={[styles.quickBtn, { backgroundColor: `${theme.colors.background}CC` }]} onPress={handleToggleLike}>
              <Heart size={18} color={liked ? theme.colors.like : theme.colors.text.primary} filled={liked} />
              <Text style={[styles.quickText, liked && { color: theme.colors.like }]}>{reflection.likes}</Text>
            </TouchableOpacity>
            <TouchableOpacity style={[styles.quickBtn, { backgroundColor: `${theme.colors.background}CC` }]} onPress={onCommentPress}>
              <MessageCircle size={18} color={theme.colors.text.primary} />
              <Text style={styles.quickText}>{reflection.comments?.length ?? 0}</Text>
            </TouchableOpacity>
          </View>
          {/* Duration badge */}
          {typeof reflection.duration_seconds === 'number' && reflection.duration_seconds > 0 && (
            <View style={[styles.durationBadge, { backgroundColor: `${theme.colors.background}CC` }]}> 
              <Clock size={12} color={theme.colors.text.secondary} />
              <Text style={[styles.durationText, { color: theme.colors.text.primary }]}>
                {formatDuration(reflection.duration_seconds)}
              </Text>
            </View>
          )}
          {/* Heart burst overlay */}
          <Animated.View pointerEvents="none" style={[styles.heartBurstOverlay, heartBurstStyle]}>
            <Heart size={96} color={theme.colors.like} filled={true} />
          </Animated.View>
          {!!reflection.content && (
            <Text style={[styles.contentText, { color: theme.colors.text.primary, paddingTop: theme.spacing.sm }]} numberOfLines={maxContentLines}>
              {reflection.content}
            </Text>
          )}
        </View>
      )}

      {/* Text-only reflection */}
      {!reflection.media_url && (
        <Text 
          style={[styles.contentText, { color: theme.colors.text.primary }]}
          numberOfLines={maxContentLines}
        >
          {reflection.content}
        </Text>
      )}

      {!expanded && topComment && (
        <TouchableOpacity 
          style={styles.topCommentPreview}
          onPress={onPress}
        >
          <BlurView intensity={5} style={StyleSheet.absoluteFill} />
          <View style={styles.topCommentHeader}>
            <Image 
              source={{ uri: topComment.user?.avatar }} 
              style={styles.topCommentAvatar} 
            />
            <View style={styles.topCommentMeta}>
              <Text style={[styles.topCommentAuthor, { color: theme.colors.text.primary }]}>
                {`${topComment.user?.first_name ?? ''} ${topComment.user?.last_name ?? ''}`.trim()}
              </Text>
              <Text style={[styles.topCommentLabel, { color: theme.colors.text.secondary }]}>
                Top Comment
              </Text>
            </View>
            <CircleButton
              size={32}
              Icon={ChevronRight}
              style={styles.expandButton}
              onPress={onPress}
            />
          </View>
          <Text 
            style={[styles.topCommentText, { color: theme.colors.text.primary }]}
            numberOfLines={2}
          >
            {topComment.content}
          </Text>
        </TouchableOpacity>
      )}
    </View>
  );
  
  const renderActions = () => (
    <View style={[styles.actions, { borderTopColor: theme.colors.border }]}>
      <TouchableOpacity
        onPress={handleToggleLike}
        style={styles.actionButton}
      >
        <Heart
          size={!expanded ? 20 : 24}
          filled={liked}
          color={liked ? theme.colors.like : theme.colors.text.secondary}
        />
        <Text style={[
          styles.actionText, 
          liked && { color: theme.colors.like }
        ]}>
          {reflection.likes}
        </Text>
      </TouchableOpacity>

      <TouchableOpacity
        onPress={onCommentPress}
        style={styles.actionButton}
      >
        <MessageCircle size={!expanded ? 20 : 24} color={theme.colors.text.secondary} />
        <Text style={[styles.actionText, { color: theme.colors.text.secondary }]}>
          {reflection.comments?.length ?? 0}
        </Text>
      </TouchableOpacity>

      {expanded && (
        <>
          <TouchableOpacity style={styles.actionButton} onPress={async () => {
            try {
              const message = reflection.media_url
                ? `${reflection.content ?? ''}`
                : reflection.content ?? '';
              await RNShare.share({ message });
            } catch {}
          }}>
            <Share size={24} color={theme.colors.text.secondary} />
            <Text style={[styles.actionText, { color: theme.colors.text.secondary }]}>
              Share
            </Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.actionButton}>
            <BookmarkSimple size={24} color={theme.colors.text.secondary} />
            <Text style={[styles.actionText, { color: theme.colors.text.secondary }]}>
              Save
            </Text>
          </TouchableOpacity>
        </>
      )}
    </View>
  );

  return (
    <TouchableOpacity 
      activeOpacity={!expanded ? 0.8 : 1}
      onPress={!expanded ? onPress : undefined}
    >
      <Animated.View style={[
        styles.container, 
        !expanded ? styles.compactContainer : styles.fullContainer,
        cardAnimatedStyle,
        style
      ]}>
        <BlurView intensity={10} style={StyleSheet.absoluteFill} />
        <View style={[
          styles.card,
          { padding: theme.spacing.xs }
        ]}>
          {renderHeader()}
          {renderContent()}
          {expanded && showComments && (
            <View style={styles.commentSection}>
              <FlatList
                data={reflection.comments ?? []}
                keyExtractor={(item) => item.id}
                renderItem={React.useCallback(({ item }: { item: Comment }) => (
                  <CommentThread
                    comment={item}
                    onReply={() => {}}
                    onLike={() => {}}
                  />
                ), [])}
                initialNumToRender={10}
                maxToRenderPerBatch={10}
                windowSize={11}
                removeClippedSubviews
                showsVerticalScrollIndicator={false}
                contentContainerStyle={{ paddingBottom: 8 }}
              />
            </View>
          )}
          {renderActions()}
        </View>
      </Animated.View>
    </TouchableOpacity>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    borderRadius: theme.borderRadius.lg,
    overflow: 'hidden',
    ...Platform.select({
      ios: {
        shadowColor: "#000",
        shadowOffset: {
          width: 0,
          height: 2,
        },
        shadowOpacity: 0.1,
        shadowRadius: 8,
      },
      android: {
        elevation: 5,
      },
    }),
  },
  card: {
    borderRadius: theme.borderRadius.lg,
    overflow: 'hidden',
    backgroundColor: `${theme.colors.background}`,
  },
  compactContainer: {
    width: wp(90),
    marginBottom: 12,
  },
  fullContainer: {
    minWidth: '100%',
    marginHorizontal: 0,
  },
  contentContainer: {
    position: 'relative',
  },
  contentText: {
    ...theme.typography.body.serif,
    padding: theme.spacing.md,
    paddingTop: 0,
  },
  mediaContainer: {
    width: '100%',
  },
  video: {
    width: '100%',
    aspectRatio: 16/9,
    backgroundColor: theme.colors.surface,
  },
  playOverlay: {
    ...StyleSheet.absoluteFillObject as any,
    alignItems: 'center',
    justifyContent: 'center',
  },
  playButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
  },
  durationBadge: {
    position: 'absolute',
    right: 8,
    bottom: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  durationText: {
    ...theme.typography.caption.primary,
  },
  mediaQuickActions: {
    position: 'absolute',
    left: 8,
    bottom: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  quickBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 16,
  },
  quickText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  heartBurstOverlay: {
    ...StyleSheet.absoluteFillObject as any,
    alignItems: 'center',
    justifyContent: 'center',
  },
  muteChipContainer: {
    position: 'absolute',
    right: 8,
    top: 8,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    marginRight: 12,
  },
  authorInfo: {
    flex: 1,
  },
  authorName: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 2,
  },
  reflectionType: {
    fontSize: 13,
  },
  iconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  icon: {
    fontSize: 20,
  },
  commentSection: {
    paddingHorizontal: theme.spacing.md,
    paddingBottom: theme.spacing.md,
  },
  topCommentPreview: {
    margin: theme.spacing.md,
    marginTop: 0,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: `${theme.colors.surface}80`,
    overflow: 'hidden',
    position: 'relative',
  },
  topCommentHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme.spacing.sm,
  },
  topCommentAvatar: {
    width: 32,
    height: 32,
    borderRadius: 16,
    marginRight: theme.spacing.sm,
  },
  topCommentMeta: {
    flex: 1,
  },
  topCommentAuthor: {
    ...theme.typography.caption.primary,
    fontWeight: '600',
  },
  topCommentLabel: {
    ...theme.typography.caption.secondary,
  },
  topCommentText: {
    ...theme.typography.body.sans,
    fontSize: 14,
    lineHeight: 20,
  },
  expandButton: {
    position: 'absolute',
    right: 0,
    top: '50%',
    transform: [{ translateY: -16 }],
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'flex-start',
    padding: theme.spacing.md,
    borderTopWidth: StyleSheet.hairlineWidth,
    gap: theme.spacing.lg,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  actionText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
});

export default observer(ReflectionCard);