import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  FlatList,
  ActivityIndicator,
} from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { Comment, User } from '@/types';
import { useAuthStore } from '@/stores/StoreProvider';
import { Heart, Reply, Send } from './Icons';
import { formatDistanceToNow } from 'date-fns';

interface CommentSectionProps {
  noteId: string;
  comments: Comment[];
  onAddComment: (content: string, parentId?: string | null) => Promise<void>;
  onLikeComment: (commentId: string) => Promise<void>;
  isLoading?: boolean;
}

const CommentSection: React.FC<CommentSectionProps> = ({
  noteId,
  comments,
  onAddComment,
  onLikeComment,
  isLoading = false,
}) => {
  const theme = useTheme();
  const { user } = useAuthStore();
  const [newComment, setNewComment] = useState('');
  const [replyingTo, setReplyingTo] = useState<{ id: string; user: User } | null>(null);
  const [submitting, setSubmitting] = useState(false);
  
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  
  const handleSubmitComment = useCallback(async () => {
    if (!newComment.trim() || submitting) return;
    
    try {
      setSubmitting(true);
      await onAddComment(newComment.trim(), replyingTo?.id);
      setNewComment('');
      setReplyingTo(null);
    } catch (error) {
      console.error('Failed to add comment:', error);
    } finally {
      setSubmitting(false);
    }
  }, [newComment, replyingTo, onAddComment, submitting]);
  
  const renderComment = useCallback(({ item }: { item: Comment }) => {
    return (
      <View style={styles.commentContainer}>
        <View style={styles.commentHeader}>
          <Text style={styles.authorName}>{item.user.first_name} {item.user.last_name}</Text>
          <Text style={styles.timestamp}>
            {formatDistanceToNow(new Date(item.timestamp), { addSuffix: true })}
          </Text>
        </View>
        
        <Text style={styles.commentContent}>{item.content}</Text>
        
        <View style={styles.commentActions}>
          <TouchableOpacity 
            style={styles.actionButton}
            onPress={() => onLikeComment(item.id)}
          >
            <Heart 
              size={16} 
              color={item.isLiked ? theme.colors.like : theme.colors.text.secondary}
              filled={item.isLiked}
            />
            <Text style={[
              styles.actionText,
              item.isLiked && { color: theme.colors.like }
            ]}>
              {item.likes > 0 ? item.likes : ''}
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={styles.actionButton}
            onPress={() => setReplyingTo({ id: item.id, user: item.user })}
          >
            <Reply size={16} color={theme.colors.text.secondary} />
            <Text style={styles.actionText}>Reply</Text>
          </TouchableOpacity>
        </View>
        
        {item.replies && item.replies.length > 0 && (
          <View style={styles.repliesContainer}>
            {item.replies.map(reply => (
              <View key={reply.id} style={styles.replyContainer}>
                <View style={styles.commentHeader}>
                  <Text style={styles.authorName}>{reply.user.first_name} {reply.user.last_name}</Text>
                  <Text style={styles.timestamp}>
                    {formatDistanceToNow(new Date(reply.timestamp), { addSuffix: true })}
                  </Text>
                </View>
                
                <Text style={styles.commentContent}>{reply.content}</Text>
                
                <View style={styles.commentActions}>
                  <TouchableOpacity 
                    style={styles.actionButton}
                    onPress={() => onLikeComment(reply.id)}
                  >
                    <Heart 
                      size={16} 
                      color={reply.isLiked ? theme.colors.like : theme.colors.text.secondary} 
                      filled={reply.isLiked}
                    />
                    <Text style={[
                      styles.actionText,
                      reply.isLiked && { color: theme.colors.like }
                    ]}>
                      {reply.likes > 0 ? reply.likes : ''}
                    </Text>
                  </TouchableOpacity>
                </View>
              </View>
            ))}
          </View>
        )}
      </View>
    );
  }, [styles, onLikeComment, theme]);
  
  return (
    <View style={styles.container}>
      <Text style={styles.sectionTitle}>Comments</Text>
      
      {isLoading ? (
        <ActivityIndicator color={theme.colors.primary} style={styles.loader} />
      ) : (
        <>
          <FlatList
            data={comments.filter(c => !c.parent_id)}
            renderItem={renderComment}
            keyExtractor={item => item.id}
            contentContainerStyle={styles.commentsList}
            initialNumToRender={10}
            maxToRenderPerBatch={10}
            windowSize={11}
            removeClippedSubviews
            keyboardShouldPersistTaps="handled"
            showsVerticalScrollIndicator={false}
            ListEmptyComponent={
              <Text style={styles.emptyText}>Be the first to comment</Text>
            }
          />
          
          <View style={styles.inputContainer}>
            {replyingTo && (
              <View style={styles.replyingToContainer}>
                <Text style={styles.replyingToText}>
                  Replying to <Text style={styles.replyingToName}>{replyingTo.user.first_name}</Text>
                </Text>
                <TouchableOpacity onPress={() => setReplyingTo(null)}>
                  <Text style={styles.cancelReply}>Cancel</Text>
                </TouchableOpacity>
              </View>
            )}
            
            <View style={styles.inputRow}>
              <TextInput
                style={styles.input}
                placeholder={replyingTo ? "Write a reply..." : "Add a comment..."}
                placeholderTextColor={theme.colors.text.placeholder}
                value={newComment}
                onChangeText={setNewComment}
                multiline
              />
              
              <TouchableOpacity 
                style={[
                  styles.sendButton,
                  (!newComment.trim() || submitting) && styles.sendButtonDisabled
                ]}
                onPress={handleSubmitComment}
                disabled={!newComment.trim() || submitting}
              >
                {submitting ? (
                  <ActivityIndicator size="small" color={theme.colors.text.inverse} />
                ) : (
                  <Send size={20} color={theme.colors.text.inverse} />
                )}
              </TouchableOpacity>
            </View>
          </View>
        </>
      )}
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    padding: theme.spacing.md,
  },
  sectionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  commentsList: {
    paddingBottom: theme.spacing.lg,
  },
  commentContainer: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.md,
  },
  commentHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.xs,
  },
  authorName: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  timestamp: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.tertiary,
    fontSize: 12,
  },
  commentContent: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
  },
  commentActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.md,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  actionText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  repliesContainer: {
    marginTop: theme.spacing.md,
    paddingLeft: theme.spacing.md,
    borderLeftWidth: 1,
    borderLeftColor: `${theme.colors.border}80`,
  },
  replyContainer: {
    marginBottom: theme.spacing.sm,
    paddingTop: theme.spacing.sm,
  },
  inputContainer: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.sm,
  },
  replyingToContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.sm,
    paddingBottom: theme.spacing.xs,
  },
  replyingToText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  replyingToName: {
    fontWeight: '600',
    color: theme.colors.primary,
  },
  cancelReply: {
    ...theme.typography.caption.secondary,
    color: theme.colors.primary,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: theme.spacing.sm,
  },
  input: {
    flex: 1,
    backgroundColor: `${theme.colors.input.background}50`,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.sm,
    maxHeight: 100,
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
  },
  sendButtonDisabled: {
    opacity: 0.5,
  },
  emptyText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    padding: theme.spacing.xl,
  },
  loader: {
    padding: theme.spacing.xl,
  },
});

export default CommentSection; 