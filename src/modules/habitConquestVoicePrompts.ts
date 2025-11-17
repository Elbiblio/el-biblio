export interface VoicePrompt {
  phase: 'affirmation' | 'meditation' | 'mercy' | 'forgiveness' | 'thanksgiving';
  timing: 'start' | 'middle' | 'end';
  text: string;
  duration?: number;
}

export const getVoicePromptsForPhase = (
  phaseId: string,
  phaseDuration: number,
  vice?: string | null,
  door?: string | null,
  pledge?: string | null
): VoicePrompt[] => {
  const middleTime = Math.floor(phaseDuration / 2);
  const endTime = Math.max(0, phaseDuration - 15);

  switch (phaseId) {
    case 'affirmation':
      return [
        {
          phase: 'affirmation',
          timing: 'start',
          text: `Take a deep breath. You are a beloved child of God. ${vice ? `Today, you are choosing freedom from ${vice.toLowerCase()}.` : ''} ${pledge ? `You will ${pledge.toLowerCase()}.` : ''} Speak this truth aloud with confidence.`,
          duration: 0
        },
        {
          phase: 'affirmation',
          timing: 'middle',
          text: 'God sees you. He knows your struggle and He is with you. You are not defined by your past. Declare your new identity in Christ.',
          duration: middleTime
        },
        {
          phase: 'affirmation',
          timing: 'end',
          text: 'Well done. You have spoken truth over yourself. Carry this identity with you today.',
          duration: endTime
        }
      ];

    case 'meditation':
      return [
        {
          phase: 'meditation',
          timing: 'start',
          text: `Close your eyes. Breathe slowly and deeply. ${door ? `If thoughts of ${door.toLowerCase()} come, simply notice them without judgment.` : 'Notice any thoughts or urges without judgment.'} Let them pass like clouds.`,
          duration: 0
        },
        {
          phase: 'meditation',
          timing: 'middle',
          text: 'You are sitting in the presence of God. He is not angry. He is not disappointed. He is here with you, offering grace and strength. Just breathe and receive.',
          duration: middleTime
        },
        {
          phase: 'meditation',
          timing: 'end',
          text: 'Slowly open your eyes. Notice how you feel. God has been renewing your mind even in this silence.',
          duration: endTime
        }
      ];

    case 'mercy':
      return [
        {
          phase: 'mercy',
          timing: 'start',
          text: 'Now, speak to God honestly. Tell Him where you feel weak. Ask Him for mercy. He delights to help you in your weakness.',
          duration: 0
        },
        {
          phase: 'mercy',
          timing: 'middle',
          text: 'God is not waiting for you to be strong enough. He is offering His strength right now. Invite Him into the places where you feel powerless.',
          duration: middleTime
        },
        {
          phase: 'mercy',
          timing: 'end',
          text: 'His mercy is new every morning. You have received it. Now, let us move to confession and forgiveness.',
          duration: endTime
        }
      ];

    case 'forgiveness':
      return [
        {
          phase: 'forgiveness',
          timing: 'start',
          text: 'Confess to God honestly. Name what you have done. He already knows, and He is ready to forgive. Do not hold back.',
          duration: 0
        },
        {
          phase: 'forgiveness',
          timing: 'middle',
          text: 'Now, receive His forgiveness. It is complete. It is finished. Any shame you feel, release it back to the Cross. It has no hold on you.',
          duration: middleTime
        },
        {
          phase: 'forgiveness',
          timing: 'end',
          text: 'You are forgiven. Fully. Completely. Walk in this freedom. The old is gone, the new has come.',
          duration: endTime
        }
      ];

    case 'thanksgiving':
      return [
        {
          phase: 'thanksgiving',
          timing: 'start',
          text: 'Give thanks to God. Thank Him for His patience. Thank Him for every small victory. Thank Him for not giving up on you.',
          duration: 0
        },
        {
          phase: 'thanksgiving',
          timing: 'middle',
          text: 'Gratitude strengthens your resolve. It shifts your focus from what you lack to what God has already done. Keep giving thanks.',
          duration: middleTime
        },
        {
          phase: 'thanksgiving',
          timing: 'end',
          text: 'Amen. You have completed this time with God. Go in His strength and peace.',
          duration: endTime
        }
      ];

    default:
      return [];
  }
};

export const getCelebrationMessage = (
  isLastSession: boolean,
  sessionsCompleted: number,
  totalSessions: number,
  clean: boolean,
  pledged: boolean
): string => {
  if (isLastSession) {
    if (clean && pledged) {
      return "🎉 Incredible! You completed all sessions today AND kept your commitments. God is doing a mighty work in you!";
    } else if (clean || pledged) {
      return "✨ Well done! You completed all sessions today. Keep pressing forward with God's grace.";
    } else {
      return "💪 You showed up today. That's what matters. Tomorrow is a new day with new mercies.";
    }
  } else {
    return `✅ Session ${sessionsCompleted}/${totalSessions} complete! You're building consistency. ${totalSessions - sessionsCompleted} more to go today.`;
  }
};

export const getPhaseInstructions = (phaseId: string): string => {
  switch (phaseId) {
    case 'affirmation':
      return 'Speak your identity in Christ aloud. Declare your pledge. Stand firm in who God says you are.';
    case 'meditation':
      return 'Sit quietly. Notice thoughts without judgment. Breathe deeply. Let God renew your mind in the silence.';
    case 'mercy':
      return 'Pray honestly. Tell God where you feel weak. Ask for His strength. He delights to help you.';
    case 'forgiveness':
      return 'Confess what you have done. Receive His complete forgiveness. Release all shame to the Cross.';
    case 'thanksgiving':
      return 'Give thanks for every small victory. Thank God for His patience and faithfulness. Gratitude strengthens you.';
    default:
      return 'Spend this time with God. He is with you.';
  }
};
