import { useCallback, useRef, useState } from 'react';
import { useChallengeStore } from '@/stores/StoreProvider';

export interface FeedbackPromptOptions {
  onFinish?: () => void;
}

export const useChallengeFeedbackPrompt = () => {
  const challengeStore = useChallengeStore();
  const [isVisible, setIsVisible] = useState(false);
  const [feedbackValue, setFeedbackValue] = useState('');
  const [targetChallengeId, setTargetChallengeId] = useState<string | null>(null);
  const afterCloseRef = useRef<(() => void) | null>(null);

  const requestFeedbackPrompt = useCallback(
    (challengeId: string, options?: FeedbackPromptOptions) => {
      const shouldPrompt = challengeStore.claimFeedbackPrompt(challengeId);
      if (shouldPrompt) {
        setTargetChallengeId(challengeId);
        setFeedbackValue('');
        setIsVisible(true);
        afterCloseRef.current = options?.onFinish ?? null;
      } else if (options?.onFinish) {
        options.onFinish();
      }
      return shouldPrompt;
    },
    [challengeStore]
  );

  const closePrompt = useCallback(() => {
    setIsVisible(false);
    setFeedbackValue('');
    setTargetChallengeId(null);
    if (afterCloseRef.current) {
      afterCloseRef.current();
      afterCloseRef.current = null;
    }
  }, []);

  const skipFeedbackPrompt = useCallback(() => {
    closePrompt();
  }, [closePrompt]);

  const submitFeedbackPrompt = useCallback(async () => {
    if (targetChallengeId) {
      const trimmed = feedbackValue.trim();
      if (trimmed) {
        try {
          await challengeStore.submitCompletionFeedback(targetChallengeId, trimmed);
        } catch (error) {
          console.warn('[useChallengeFeedbackPrompt] Failed to submit feedback', error);
        }
      }
    }
    closePrompt();
  }, [challengeStore, closePrompt, feedbackValue, targetChallengeId]);

  return {
    requestFeedbackPrompt,
    isFeedbackVisible: isVisible,
    feedbackValue,
    setFeedbackValue,
    skipFeedbackPrompt,
    submitFeedbackPrompt,
    closeFeedbackPrompt: closePrompt,
    feedbackTargetId: targetChallengeId,
  };
};
