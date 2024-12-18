import React, { useState, useCallback, useRef, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Platform,
  TextInput,
  Keyboard,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  interpolate,
  withSequence,
  Extrapolation,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import * as Haptics from 'expo-haptics';
import { 
  ArrowLeft,
  MessageCircle,
  Send,
} from '../components/Icons';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { Comment, Reflection, RootStackParamList } from '../types';
import { useTheme } from '@/contexts/ThemeContext';
import ReflectionCard from '../components/ReflectionCard';
import CommentThread from '../components/CommentThread';
import { Theme } from '@/theme';

type ReflectionDetailProps = NativeStackScreenProps<RootStackParamList, 'ReflectionDetail'>;

const ReflectionDetail: React.FC<ReflectionDetailProps> = ({ navigation, route }) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const scrollViewRef = useRef<ScrollView>(null);
  
  // States
  const [isLoading, setIsLoading] = useState(true);
  const [loadingComments, setLoadingComments] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [showCommentInput, setShowCommentInput] = useState(false);
  const [commentText, setCommentText] = useState('');
  const [replyingTo, setReplyingTo] = useState<Comment | null>(null);
  const [comments, setComments] = useState<Comment[]>([]);
  const [error, setError] = useState<string | null>(null);

  // Animated values - moved outside of render cycle
  const scrollY = useSharedValue(0);
  const scrollX = useSharedValue(0);
  const headerOpacity = useSharedValue(1);
  const commentInputHeight = useSharedValue(0);
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  // Mock data - move to a data fetching hook or service in production
  const reflection: Reflection = {
    id: route.params.reflectionId,
    author: {
      id: 'user1',
      first_name: 'Sarah',
      last_name: 'Mitchell',
      avatar: 'https://example.com/avatar1.jpg'
    },
    content: "This verse reminds me that in our most exhausting moments, God provides the strength we need. It's not about our own power, but about trusting in His timing and purposes. Sometimes we need to step back and remember who is really in control.",
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
  };

  // Load initial data
  useEffect(() => {
    const loadData = async () => {
      try {
        setError(null);
        setIsLoading(false);
        setComments(reflection.comments);
        setLoadingComments(false);
      } catch (err) {
        setError('Failed to load reflection');
        setIsLoading(false);
        setLoadingComments(false);
      }
    };
    
    loadData();
  }, []);

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

  const handleRefresh = useCallback(async () => {
    try {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      setRefreshing(true);
      setError(null);
      // Add your refresh logic here
      setRefreshing(false);
    } catch (err) {
      setError('Failed to refresh');
      setRefreshing(false);
    }
  }, []);

  const handleReply = useCallback((comment: Comment) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setReplyingTo(comment);
    setShowCommentInput(true);
  }, []);

  const handleSubmitComment = useCallback(async () => {
    if (!commentText.trim()) return;
    
    try {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      
      const newComment: Comment = {
        id: `comment${Date.now()}`,
        parentId: replyingTo?.id || null,
        author: {
          id: 'currentUser',
          first_name: 'Current',
          last_name: 'User',
          avatar: 'https://example.com/current.jpg'
        },
        content: commentText,
        likes: 0,
        timestamp: 'Just now',
        isLiked: false
      };

      setComments(prev => [newComment, ...prev]);
      setCommentText('');
      setShowCommentInput(false);
      setReplyingTo(null);
      Keyboard.dismiss();
    } catch (err) {
      setError('Failed to submit comment');
    }
  }, [commentText, replyingTo]);

  const handleLikeComment = useCallback(async (commentId: string) => {
    try {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      setComments(prev => prev.map(comment => 
        comment.id === commentId 
          ? { ...comment, isLiked: !comment.isLiked, likes: comment.likes + (comment.isLiked ? -1 : 1) }
          : comment
      ));
    } catch (err) {
      setError('Failed to like comment');
    }
  }, []);

  if (isLoading) {
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
        <TouchableOpacity 
          style={styles.retryButton}
          onPress={handleRefresh}
        >
          <Text style={styles.retryText}>Retry</Text>
        </TouchableOpacity>
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
          {loadingComments ? (
            <View style={styles.loadingComments}>
              <ActivityIndicator color={theme.colors.primary} />
            </View>
          ) : comments.length === 0 ? (
            <View style={styles.emptyComments}>
              <Text style={styles.emptyCommentsText}>No comments yet</Text>
              <Text style={styles.emptyCommentsSubtext}>Be the first to share your thoughts</Text>
            </View>
          ) : (
            <View style={styles.commentsList}>
              {comments.map((comment) => (
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
                Replying to {replyingTo.author.first_name}
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
};

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
});

export default React.memo(ReflectionDetail);