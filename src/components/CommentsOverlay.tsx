import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  TextInput,
  KeyboardAvoidingView,
  Platform,
  StyleSheet,
  FlatList,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { Comment, Reflection } from '../types';
import { useTheme } from '@/contexts/ThemeContext';
import { X, Send } from './Icons';
import CommentThread from './CommentThread';
import { getCurrentTheme, useThemeStore } from '@/theme/store';
import { SCREEN_DIMENSIONS } from '@/constants';
import { Theme } from '@/theme';

interface CommentsOverlayProps {
  visible: boolean;
  onClose: () => void;
  reflection: Reflection;
}

const CommentsOverlay: React.FC<CommentsOverlayProps> = ({
  visible,
  onClose,
  reflection,
}) => {
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const [activeComment, setActiveComment] = useState<string | null>(null);
  const [newComment, setNewComment] = useState('');
  const translateY = useSharedValue(visible ? 0 : SCREEN_DIMENSIONS.height);

  React.useEffect(() => {
    translateY.value = withSpring(visible ? 0 : SCREEN_DIMENSIONS.height, {
      damping: 15,
      stiffness: 90,
    });
  }, [visible]);

  const overlayStyle = useAnimatedStyle(() => {
    const opacity = interpolate(
      translateY.value,
      [SCREEN_DIMENSIONS.height, SCREEN_DIMENSIONS.height * 0.5, 0],
      [0, 0.5, 1],
      Extrapolation.CLAMP
    );

    return {
      transform: [{ translateY: translateY.value }],
      opacity,
    };
  });

  const handleReply = useCallback((commentId: string) => {
    setActiveComment(commentId);
  }, []);

  const handleSubmit = useCallback(() => {
    if (newComment.trim()) {
      // Add comment logic here
      setNewComment('');
      setActiveComment(null);
    }
  }, [newComment]);

  const renderComment = useCallback(({ item }: { item: Comment }) => (
    <CommentThread
      comment={item}
      onReply={handleReply}
      onLike={() => {}}
    />
  ), [handleReply]);

  if (!reflection) return null;

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={[styles.overlay, !visible && styles.hidden]}
    >
      <BlurView intensity={20} style={StyleSheet.absoluteFill}>
        <TouchableOpacity
          style={styles.backdrop}
          onPress={onClose}
          activeOpacity={1}
        />
      </BlurView>

      <Animated.View style={[styles.commentsContainer, overlayStyle]}>
        <View style={styles.header}>
          <View style={styles.headerContent}>
            <Text style={styles.title}>Comments</Text>
            <Text style={styles.subtitle}>
              {reflection.comments.length} responses
            </Text>
          </View>
          <TouchableOpacity onPress={onClose} style={styles.closeButton}>
            <X size={24} color={theme.colors.text.secondary} />
          </TouchableOpacity>
        </View>

        <FlatList
          data={reflection.comments}
          renderItem={renderComment}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.commentsList}
        />

        <View style={styles.inputContainer}>
          {activeComment && (
            <View style={styles.replyingTo}>
              <Text style={styles.replyingToText}>
                Replying to comment
              </Text>
              <TouchableOpacity onPress={() => setActiveComment(null)}>
                <Text style={styles.cancelReply}>Cancel</Text>
              </TouchableOpacity>
            </View>
          )}
          <View style={styles.inputRow}>
            <TextInput
              style={styles.input}
              placeholder="Add a comment..."
              multiline
              value={newComment}
              onChangeText={setNewComment}
            />
            <TouchableOpacity 
              style={[
                styles.sendButton,
                !newComment.trim() && styles.sendButtonDisabled
              ]}
              onPress={handleSubmit}
              disabled={!newComment.trim()}
            >
              <Send size={20} color={theme.colors.text.inverse} />
            </TouchableOpacity>
          </View>
        </View>
      </Animated.View>
    </KeyboardAvoidingView>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  hidden: {
    display: 'none',
  },
  backdrop: {
    flex: 1,
  },
  closeButton: {
    padding: theme.spacing.sm,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: theme.spacing.sm,
  },
  sendButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: theme.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sendButtonDisabled: {
    opacity: 0.5,
  },
  commentsContainer: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    maxHeight: '80%',
    backgroundColor: theme.colors.background,
    borderTopLeftRadius: theme.borderRadius.lg,
    borderTopRightRadius: theme.borderRadius.lg,
    ...theme.shadows.md,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: theme.spacing.md,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: theme.colors.border,
  },
  headerContent: {
    flex: 1,
  },
  title: {
    ...theme.typography.heading,
    color: theme.colors.text.primary,
  },
  subtitle: {
    ...theme.typography.caption,
    color: theme.colors.text.secondary,
    marginTop: 2,
  },
  commentsList: {
    padding: theme.spacing.md,
  },
  commentContainer: {
    marginBottom: theme.spacing.md,
  },
  inputContainer: {
    padding: theme.spacing.md,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: theme.colors.border,
    backgroundColor: theme.colors.background,
  },
  replyingTo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    backgroundColor: theme.colors.surface,
  },
  replyingToText: {
    ...theme.typography.caption,
    color: theme.colors.text.secondary,
  },
  cancelReply: {
    ...theme.typography.caption,
    color: theme.colors.primary,
    fontWeight: '500',
  },
  input: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.full,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    maxHeight: 100,
    ...theme.typography.body,
  },
});

export default React.memo(CommentsOverlay);    