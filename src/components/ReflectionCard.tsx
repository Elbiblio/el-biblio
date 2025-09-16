import React, { useState, useRef } from 'react';
import { observer } from 'mobx-react-lite';
import {
  View,
  Text,
  Image,
  StyleSheet,
  TouchableOpacity,
  Platform,
  ViewStyle,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  interpolate,
  Extrapolation,
  SharedValue,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { Heart, MessageCircle, Share, BookmarkSimple, ChevronRight } from './Icons';
import CommentThread from './CommentThread';
import { useTheme } from '@/contexts/ThemeContext';
import { ReflectionType, type Reflection } from '@/types';
import { extractUniqueCommenters } from '@/utils/comments';
import { SCREEN_DIMENSIONS, wp } from '@/constants';
import CircleButton from './CircleButton';
import { Theme } from '@/theme';

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

  const topComment = reflection.comments[0];

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
  const renderHeader = () => (
    <View style={styles.header}>
      <Image source={{ uri: reflection.user.avatar }} style={styles.avatar} />
      <View style={styles.authorInfo}>
        <Text style={[styles.authorName, { color: theme.colors.text.primary }]}>
          {`${reflection.user.first_name} ${reflection.user.last_name}`}
        </Text>
        <Text style={[styles.reflectionType, { color: theme.colors.text.secondary }]}>
          {reflection.type === ReflectionType.Story ? 'Sharing a story' : 'Sharing an insight'}
        </Text>
      </View>
      <View style={[styles.iconContainer, { backgroundColor: theme.colors.surface }]}>
        <Text style={styles.icon}>{reflection.icon}</Text>
      </View>
    </View>
  );

  const renderContent = () => (
    <View style={styles.contentContainer}>
      <Text 
        style={[styles.contentText, { color: theme.colors.text.primary }]}
        numberOfLines={maxContentLines}
      >
        {reflection.content}
      </Text>
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
        onPress={() => setLiked(!liked)}
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
          {reflection.comments.length}
        </Text>
      </TouchableOpacity>

      {expanded && (
        <>
          <TouchableOpacity style={styles.actionButton}>
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
              {reflection.comments.map((comment) => (
                <CommentThread
                  key={comment.id}
                  comment={comment}
                  onReply={() => {}}
                  onLike={() => {}}
                />
              ))}
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