import React, { useState, useCallback, useRef, useEffect } from 'react';
import {
  View,
  Text,
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
  interpolate,
  Extrapolation,
  withTiming,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import * as Haptics from 'expo-haptics';
import { observer } from 'mobx-react-lite';
import { ArrowLeft, MessageCircle, Send } from '../components/Icons';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { Comment, RootStackParamList } from '../types';
import { useTheme } from '@/contexts/ThemeContext';
import { useAuthStore, useReflectionStore } from '@/stores/StoreProvider';
import ReflectionCard from '../components/ReflectionCard';
import CommentThread from '../components/CommentThread';
import { Theme } from '@/theme';
import EmptyState from '@/components/EmptyState';

type ReflectionDetailProps = NativeStackScreenProps<RootStackParamList, 'ReflectionDetail'>;

const ReflectionDetail = observer(({ navigation, route }: ReflectionDetailProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const scrollViewRef = useRef<ScrollView>(null);
  const { user } = useAuthStore();
  const reflectionStore = useReflectionStore();
  
  // Local UI state
  const [showCommentInput, setShowCommentInput] = useState(false);
  const [commentText, setCommentText] = useState('');
  const [replyingTo, setReplyingTo] = useState<Comment | null>(null);

  // Destructure from MobX store
  const {
    isLoading,
    error,
    isCommentsLoading,
    commentsError,
    fetchComments,
    createComment,
    likeComment,
    clearErrors,
    comments,
  } = reflectionStore;

  // Animated values
  const scrollY = useSharedValue(0);
  const scrollX = useSharedValue(0);
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const reflection = route.params.reflection;

  // Load comments on mount and clear errors on unmount
  useEffect(() => {
    if (reflection?.id && !reflection?.media_url) {
      fetchComments(reflection.id, 1);
    }
    return () => {
      clearErrors();
    };
  }, [reflection?.id, reflection?.media_url, fetchComments, clearErrors]);

  // Handle refresh
  const handleRefresh = async () => {
    if (reflection?.id) {
      await fetchComments(reflection.id, 1);
    }
  };

  // Handle comment submission
  const handleSubmitComment = async () => {
    if (!commentText.trim() || !reflection?.id || !user?.id) return;

    const success = await createComment({
      reflection_id: reflection.id,
      content: commentText.trim(),
      user_id: user.id,
      parent_id: replyingTo?.id,
    });

    if (success) {
      setCommentText('');
      setReplyingTo(null);
      setShowCommentInput(false);
    }
  };

  // Handle like comment
  const handleLikeComment = async (commentId: string) => {
    await likeComment(commentId);
  };

  // Animation styles
  const headerStyle = useAnimatedStyle(() => ({
    backgroundColor: `${theme.colors.background}${
      interpolate(scrollY.value, [0, 100], [0, 99], Extrapolation.CLAMP)
        .toString(16)
        .padStart(2, '0')
    }`,
  }));

  // Event handlers
  const handleScroll = useCallback((event: any) => {
    scrollY.value = event.nativeEvent.contentOffset.y;
  }, []);

  const handleReply = useCallback((comment: Comment) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setReplyingTo(comment);
    setShowCommentInput(true);
  }, []);

  if (isLoading && !reflection) {
    return (
      <View style={[styles.loadingContainer, { paddingTop: insets.top }]}>
        <ActivityIndicator size="large" color={theme.colors.primary} />
      </View>
    );
  }

  if (error) {
    return (
      <View style={[styles.errorContainer, { paddingTop: insets.top }]}>
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity style={styles.retryButton} onPress={handleRefresh}>
          <Text style={styles.retryText}>Retry</Text>
        </TouchableOpacity>
      </View>
    );
  }

  if (reflection?.media_url) {
    return (
      <View style={[styles.container, { paddingTop: insets.top }]}>
        <Animated.View style={[styles.navigationHeader, headerStyle]}>
          <TouchableOpacity 
            onPress={() => {
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              navigation.goBack();
            }}
          >
            <ArrowLeft size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>
          <View style={styles.navigationTitle}>
            <Text style={styles.navigationText}>Reflection</Text>
          </View>
        </Animated.View>
        <ScrollView style={styles.mainContent} contentContainerStyle={styles.scrollContent}>
          <EmptyState
            title="Not available"
            message="This reflection is not available."
          />
        </ScrollView>
      </View>
    );
  }

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Navigation Header */}
      <Animated.View style={[styles.navigationHeader, headerStyle]}>
        <TouchableOpacity 
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            navigation.goBack();
          }}
        >
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <View style={styles.navigationTitle}>
          <Text style={styles.navigationText}>Reflection</Text>
        </View>
      </Animated.View>

      {/* Main Content */}
      <ScrollView
        ref={scrollViewRef}
        style={styles.mainContent}
        contentContainerStyle={styles.scrollContent}
        onScroll={handleScroll}
        scrollEventThrottle={16}
        showsVerticalScrollIndicator={false}
      >
        {/* Reflection Card */}
        <View style={styles.headerContainer}>
          <ReflectionCard
            reflection={reflection}
            scrollX={scrollX}
            index={0}
            onCommentPress={() => {}}
            expanded={true}
            showComments={false}
            style={styles.reflectionCard}
          />
        </View>

        {/* Comments Section */}
        <View style={styles.commentsSection}>
          <View style={styles.commentsHeader}>
            <Text style={styles.commentsTitle}>
              Comments {comments.length > 0 && `(${comments.length})`}
            </Text>
            <TouchableOpacity
              style={styles.addCommentButton}
              onPress={() => {
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                setShowCommentInput(true);
              }}
            >
              <MessageCircle size={20} color={theme.colors.primary} />
              <Text style={styles.addCommentText}>Add Comment</Text>
            </TouchableOpacity>
          </View>

          {/* Comments List */}
          {isCommentsLoading ? (
            <View style={styles.loadingComments}>
              <ActivityIndicator color={theme.colors.primary} />
            </View>
          ) : commentsError ? (
            <View style={styles.errorComments}>
              <Text style={styles.errorCommentsText}>{commentsError}</Text>
              <TouchableOpacity style={styles.retryCommentsButton} onPress={handleRefresh}>
                <Text style={styles.retryCommentsText}>Retry</Text>
              </TouchableOpacity>
            </View>
          ) : comments.length === 0 ? (
            <EmptyState
              title="No comments yet"
              message="Be the first to share your thoughts."
              ctaText="Add a comment"
              onPressCTA={() => setShowCommentInput(true)}
            />
          ) : (
            <View style={styles.commentsList}>
              {comments.map((comment: Comment) => (
                <CommentThread
                  key={comment.id}
                  comment={comment}
                  onReply={() => handleReply(comment)}
                  onLike={() => handleLikeComment(comment.id)}
                  level={0}
                />
              ))}
            </View>
          )}
        </View>

        {/* Bottom Spacing */}
        <View style={{ height: theme.spacing.xl * 2 }} />
      </ScrollView>

      {/* Comment Input */}
      {showCommentInput && (
        <BlurView intensity={20} style={styles.commentInputContainer}>
          {replyingTo && (
            <View style={styles.replyingToContainer}>
              <Text style={styles.replyingToText}>
                Replying to comment
              </Text>
              <TouchableOpacity 
                onPress={() => {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                  setReplyingTo(null);
                }}
              >
                <Text style={styles.cancelReplyText}>Cancel</Text>
              </TouchableOpacity>
            </View>
          )}
          <View style={styles.inputRow}>
            <TextInput
              style={styles.commentInput}
              placeholder={replyingTo ? "Write a reply..." : "Write a comment..."}
              multiline
              maxLength={500}
              value={commentText}
              onChangeText={setCommentText}
              autoFocus
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
        </BlurView>
      )}
    </View>
  );
});

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  loadingContainer: {
    flex: 1,
    backgroundColor: theme.colors.background,
    alignItems: 'center',
    justifyContent: 'center',
  },
  errorContainer: {
    flex: 1,
    backgroundColor: theme.colors.background,
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme.spacing.lg,
  },
  errorText: {
    ...theme.typography.body.sans,
    color: theme.colors.error,
    textAlign: 'center',
    marginBottom: theme.spacing.md,
  },
  retryButton: {
    backgroundColor: theme.colors.primary,
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
  },
  retryText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
  navigationHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: theme.colors.border,
  },
  navigationTitle: {
    flex: 1,
    alignItems: 'center',
    marginRight: 40, // To center the title accounting for the back button
  },
  navigationText: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  mainContent: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
  },
  headerContainer: {
    width: '100%',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.lg,
  },
  reflectionCard: {
    width: '100%',
  },
  commentsSection: {
    flex: 1,
    backgroundColor: theme.colors.surface,
    borderTopLeftRadius: theme.borderRadius.xl,
    borderTopRightRadius: theme.borderRadius.xl,
    paddingTop: theme.spacing.lg,
  },
  commentsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.md,
    marginBottom: theme.spacing.md,
  },
  commentsTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
  },
  addCommentButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    padding: theme.spacing.sm,
    backgroundColor: `${theme.colors.primary}15`,
    borderRadius: theme.borderRadius.full,
  },
  addCommentText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
  },
  loadingComments: {
    padding: theme.spacing.xl,
    alignItems: 'center',
  },
  emptyComments: {
    padding: theme.spacing.xl,
    alignItems: 'center',
  },
  emptyCommentsText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  emptyCommentsSubtext: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  commentsList: {
    paddingHorizontal: theme.spacing.md,
  },
  commentInputContainer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: theme.spacing.md,
    backgroundColor: `${theme.colors.background}F2`,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: theme.colors.border,
  },
  replyingToContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingBottom: theme.spacing.sm,
  },
  replyingToText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  cancelReplyText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: theme.spacing.sm,
  },
  commentInput: {
    flex: 1,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    maxHeight: 120,
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  sendButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: theme.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    ...Platform.select({
      ios: {
        shadowColor: theme.colors.primary,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 8,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  sendButtonDisabled: {
    opacity: 0.5,
  },
  errorComments: {
    padding: theme.spacing.xl,
    alignItems: 'center',
  },
  errorCommentsText: {
    ...theme.typography.body.sans,
    color: theme.colors.error,
    textAlign: 'center',
    marginBottom: theme.spacing.md,
  },
  retryCommentsButton: {
    backgroundColor: theme.colors.primary,
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
  },
  retryCommentsText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
});

export default ReflectionDetail;