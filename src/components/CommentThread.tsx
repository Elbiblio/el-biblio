import React from 'react';
import {
  View,
  Text,
  Image,
  TouchableOpacity,
  StyleSheet,
  Platform,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from 'react-native-reanimated';
import { Heart, MessageCircle } from './Icons';
import { Comment } from '../types';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';

interface CommentThreadProps {
  comment: Comment;
  level?: number;
  onReply: (comment: Comment) => void;
  onLike: (commentId: string) => void;
}

const CommentThread: React.FC<CommentThreadProps> = ({
  comment,
  level = 0,
  onReply,
  onLike,
}) => {
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const scale = useSharedValue(1);

  const handleLike = () => {
    scale.value = withSpring(1.2, {}, () => {
      scale.value = withSpring(1);
    });
    onLike(comment.id);
  };

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }]
  }));

  const renderReplies = () => {
    if (!comment.replies?.length) return null;
    
    return comment.replies.map((reply) => (
      <CommentThread
        key={reply.id}
        comment={reply}
        level={level + 1}
        onReply={onReply}
        onLike={onLike}
      />
    ));
  };

  return (
    <View style={[styles.container, { marginLeft: level * theme.spacing.xl }]}>
      <View style={styles.threadLine} />
      
      <View style={styles.commentContent}>
        {/* Comment Header */}
        <View style={styles.header}>
          <View style={styles.authorSection}>
            <Image 
              source={{ uri: comment.user?.avatar }} 
              style={styles.avatar}
            />
            <View style={styles.authorInfo}>
              <Text style={styles.authorName}>
                {`${comment.user?.first_name ?? ''} ${comment.user?.last_name ?? ''}`.trim()}
              </Text>
              <Text style={styles.timestamp}>{comment.timestamp}</Text>
            </View>
          </View>
        </View>

        {/* Comment Body */}
        <View style={styles.bubble}>
          <Text style={styles.commentText}>
            {comment.content}
          </Text>
        </View>

        {/* Comment Actions */}
        <View style={styles.actions}>
          <Animated.View style={animatedStyle}>
            <TouchableOpacity
              onPress={handleLike}
              style={styles.actionButton}
              hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
            >
              <Heart 
                size={16}
                color={comment.isLiked ? theme.colors.like : theme.colors.text.secondary}
                filled={comment.isLiked}
              />
              <Text style={[
                styles.actionText,
                comment.isLiked && styles.likedText
              ]}>
                {comment.likes}
              </Text>
            </TouchableOpacity>
          </Animated.View>

          <TouchableOpacity
            onPress={() => onReply(comment)}
            style={styles.actionButton}
            hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
          >
            <MessageCircle size={16} color={theme.colors.primary} />
            <Text style={styles.replyText}>Reply</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Nested Replies */}
      {renderReplies()}
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    marginBottom: theme.spacing.lg,
    position: 'relative',
  },
  threadLine: {
    position: 'absolute',
    left: -theme.spacing.md,
    top: 40,
    bottom: 0,
    width: 2,
    backgroundColor: `${theme.colors.primary}15`,
    borderRadius: theme.borderRadius.full,
  },
  commentContent: {
    position: 'relative',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.xs,
  },
  authorSection: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  avatar: {
    width: 32,
    height: 32,
    borderRadius: 16,
    marginRight: theme.spacing.sm,
    borderWidth: 2,
    borderColor: theme.colors.background,
    ...Platform.select({
      ios: {
        shadowColor: "#000",
        shadowOffset: {
          width: 0,
          height: 2,
        },
        shadowOpacity: 0.1,
        shadowRadius: 3,
      },
      android: {
        elevation: 3,
      },
    }),
  },
  authorInfo: {
    flex: 1,
  },
  authorName: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
    marginBottom: 2,
  },
  timestamp: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontSize: 12,
  },
  bubble: {
    backgroundColor: `${theme.colors.surface}80`,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    marginLeft: theme.spacing.xl,
    marginRight: theme.spacing.md,
    ...Platform.select({
      ios: {
        shadowColor: "#000",
        shadowOffset: {
          width: 0,
          height: 2,
        },
        shadowOpacity: 0.05,
        shadowRadius: 3,
      },
      android: {
        elevation: 1,
      },
    }),
  },
  commentText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontSize: 14,
    lineHeight: 20,
  },
  actions: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: theme.spacing.xs,
    marginLeft: theme.spacing.xl,
    gap: theme.spacing.md,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingVertical: theme.spacing.xs,
  },
  actionText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontSize: 12,
  },
  likedText: {
    color: theme.colors.like,
  },
  replyText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontSize: 12,
    fontWeight: '600',
  },
});

export default React.memo(CommentThread);