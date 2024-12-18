import { Comment, User } from '../types';

export const extractUniqueCommenters = (comments: Comment[]): User[] => {
  const uniqueCommenters = new Map<string, User>();
  
  const addCommenter = (comment: Comment) => {
    if (!uniqueCommenters.has(comment.author.id)) {
      uniqueCommenters.set(comment.author.id, comment.author);
    }
    
    // Also check replies
    comment.replies?.forEach(addCommenter);
  };
  
  comments.forEach(addCommenter);
  
  return Array.from(uniqueCommenters.values());
};