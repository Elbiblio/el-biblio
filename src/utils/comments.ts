import { Comment, User } from '../types';

export const extractUniqueCommenters = (comments: Comment[]): User[] => {
  const uniqueCommenters = new Map<string, User>();
  
  const addCommenter = (comment: Comment) => {
    if (comment.user?.id && !uniqueCommenters.has(comment.user.id)) {
      uniqueCommenters.set(comment.user.id, comment.user);
    }
    
    // Also check replies
    comment.replies?.forEach(addCommenter);
  };
  
  comments.forEach(addCommenter);
  
  return Array.from(uniqueCommenters.values());
};