import React, { useState, useEffect, useRef, useCallback } from 'react';
import { observer } from 'mobx-react-lite';
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
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '@/contexts/ThemeContext';
import { X, Send } from './Icons';
import CommentThread from './CommentThread';
import { SCREEN_DIMENSIONS } from '@/constants';
import { Theme } from '@/theme';
import { useReflectionStore, useAuthStore } from '@/stores/StoreProvider';

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
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const { user } = useAuthStore();
  const { createComment, likeComment } = useReflectionStore();
  
  // Local state
  const [commentText, setCommentText] = useState('');
  const [replyingTo, setReplyingTo] = useState<Comment | null>(null);
  
  // Animation values
  const translateY = useSharedValue(visible ? 0 : SCREEN_DIMENSIONS.height);

  // Update animation when visibility changes
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

  const handleReply = useCallback((comment: Comment) => {
    setReplyingTo(comment);
  }, []);

  const handleSubmitComment = useCallback(async () => {
    if (!commentText.trim() || !user || !reflection) return;
    
    try {
      await createComment({
        content: commentText.trim(),
        reflection_id: reflection.id,
        parent_id: replyingTo?.id,
        user_id: user.id
      });
      
      // Clear input and reply state
      setCommentText('');
      setReplyingTo(null);
    } catch (error) {
      console.error('Error submitting comment:', error);
      // Optionally show error toast
    }
  }, [commentText, replyingTo, user, reflection, createComment]);

  const handleClose = useCallback(() => {
    // Reset states
    setCommentText('');
    setReplyingTo(null);
    onClose();
  }, [onClose]);

  const renderItem = React.useCallback(({ item }: { item: Comment }) => (
    <CommentThread
      comment={item}
      onReply={handleReply}
      onLike={async () => {
        if (!user) return;
        await likeComment(item.id);
      }}
    />
  ), [handleReply, likeComment, user]);

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={[styles.overlay, !visible && styles.hidden]}
    >
      <BlurView intensity={20} style={StyleSheet.absoluteFill} pointerEvents="none" />
      <TouchableOpacity
        style={styles.backdrop}
        onPress={handleClose}
        activeOpacity={1}
      />

      <Animated.View style={[styles.commentsContainer, overlayStyle]}>
        <View style={styles.header}>
          <View style={styles.headerContent}>
            <Text style={styles.title}>Comments</Text>
            <Text style={styles.subtitle}>
              {reflection?.comments?.length || 0} responses
            </Text>
          </View>
          <TouchableOpacity onPress={handleClose} style={styles.closeButton}>
            <X size={24} color={theme.colors.text.secondary} />
          </TouchableOpacity>
        </View>

        <FlatList
          data={reflection?.comments || []}
          renderItem={renderItem}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.commentsList}
          initialNumToRender={10}
          maxToRenderPerBatch={10}
          windowSize={11}
          removeClippedSubviews
          showsVerticalScrollIndicator={false}
          keyboardShouldPersistTaps="handled"
        />

        <View style={[styles.inputContainer, { paddingBottom: (insets.bottom || 0) + theme.spacing.md }]}>
          {replyingTo && (
            <View style={styles.replyingTo}>
              <Text style={styles.replyingToText}>
                Replying to {replyingTo.user?.first_name}
              </Text>
              <TouchableOpacity onPress={() => setReplyingTo(null)}>
                <Text style={styles.cancelReply}>Cancel</Text>
              </TouchableOpacity>
            </View>
          )}
          <View style={styles.inputRow}>
            <TextInput
              style={styles.input}
              placeholder="Add a comment..."
              multiline
              value={commentText}
              onChangeText={setCommentText}
            />
            <TouchableOpacity 
              style={[
                styles.sendButton,
                !commentText.trim() && styles.sendButtonDisabled
              ]}
              onPress={handleSubmitComment}
              disabled={!commentText.trim()}
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

export default observer(CommentsOverlay);    