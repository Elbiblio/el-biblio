import type { HabitVice } from './habitConquestCapsules';

export interface TruthSerumQuestion {
  id: string;
  category: 'understanding' | 'commitment' | 'reflection' | 'accountability' | 'growth';
  question: string;
  scaleLabel: { min: string; max: string };
  insight?: string;
  relatedStrength?: string;
}

export interface TruthSerumProgress {
  date: string;
  answers: Record<string, number>;
  averageScore: number;
  categoryAverages: Record<string, number>;
}

const QUESTION_POOLS: Record<HabitVice, Record<string, TruthSerumQuestion[]>> = {
  'Laziness & neglect': {
    understanding: [
      {
        id: 'distortion-root',
        category: 'understanding',
        question: 'How clearly do you see that laziness and neglect are worldly distortions, not your true nature?',
        scaleLabel: { min: 'Not clear', max: 'Clear' },
        insight: 'Laziness arises from understanding God\'s power yet feeling helpless without His intervention. This creates a comfort zone where we shut out the world\'s troubles.',
      },
      {
        id: 'strength-awareness',
        category: 'understanding',
        question: 'How aware are you of your God-given strengths (compassion, spiritual sensitivity, faithfulness) that are being distorted by laziness?',
        scaleLabel: { min: 'Not aware', max: 'Aware' },
        relatedStrength: 'Compassion & Spiritual Sensitivity',
      },
      {
        id: 'distortion-mechanism',
        category: 'understanding',
        question: 'How well do you understand how your compassion and sensitivity lead to numbness when overwhelmed?',
        scaleLabel: { min: 'Don\'t understand', max: 'Understand' },
        insight: 'Healers and Sentinels retreat into numbness to protect their hearts from overwhelming pain and spiritual warfare.',
      },
      {
        id: 'kingdom-impact',
        category: 'understanding',
        question: 'How clearly do you see how laziness makes you less fruitful for God\'s Kingdom?',
        scaleLabel: { min: 'Not clear', max: 'Clear' },
        insight: 'When laziness takes hold, your gifts of intercession, presence with the hurting, and faithful witness become dormant.',
      },
    ],
    commitment: [
      {
        id: 'prayer-commitment',
        category: 'commitment',
        question: 'How committed are you to praying daily for the new Kingdom?',
        scaleLabel: { min: 'Not committed', max: 'Committed' },
      },
      {
        id: 'meditation-commitment',
        category: 'commitment',
        question: 'How committed are you to meditating on your strengths to find productivity again?',
        scaleLabel: { min: 'Not committed', max: 'Committed' },
      },
      {
        id: 'harness-strength',
        category: 'commitment',
        question: 'How committed are you to using your compassion and spiritual sensitivity for God\'s Kingdom?',
        scaleLabel: { min: 'Not committed', max: 'Committed' },
        relatedStrength: 'Compassion & Spiritual Sensitivity',
      },
      {
        id: 'action-commitment',
        category: 'commitment',
        question: 'How committed are you to taking small daily actions that serve others?',
        scaleLabel: { min: 'Not committed', max: 'Committed' },
      },
    ],
    reflection: [
      {
        id: 'self-awareness',
        category: 'reflection',
        question: 'How well do you recognize when you\'re retreating into numbness versus using your gifts?',
        scaleLabel: { min: 'Poor', max: 'Good' },
      },
      {
        id: 'strength-usage',
        category: 'reflection',
        question: 'How often do you use your compassion and spiritual sensitivity for prayer and service?',
        scaleLabel: { min: 'Rarely', max: 'Consistently' },
        relatedStrength: 'Compassion & Spiritual Sensitivity',
      },
      {
        id: 'prayer-practice',
        category: 'reflection',
        question: 'How consistent is your practice of praying for the new Kingdom?',
        scaleLabel: { min: 'Inconsistent', max: 'Consistent' },
      },
      {
        id: 'productivity-awareness',
        category: 'reflection',
        question: 'How aware are you of your productivity patterns and when laziness is taking hold?',
        scaleLabel: { min: 'Not aware', max: 'Aware' },
      },
    ],
    accountability: [
      {
        id: 'door-keeping',
        category: 'accountability',
        question: 'How well did you keep your door shut to temptation today?',
        scaleLabel: { min: 'Poorly', max: 'Well' },
      },
      {
        id: 'good-deeds',
        category: 'accountability',
        question: 'How well did you do something good toward being better today?',
        scaleLabel: { min: 'Not at all', max: 'Well' },
      },
      {
        id: 'strength-application',
        category: 'accountability',
        question: 'How well did you apply your strengths (compassion, spiritual sensitivity) today?',
        scaleLabel: { min: 'Poorly', max: 'Well' },
        relatedStrength: 'Compassion & Spiritual Sensitivity',
      },
      {
        id: 'prayer-follow-through',
        category: 'accountability',
        question: 'How well did you follow through on your commitment to pray for the new Kingdom today?',
        scaleLabel: { min: 'Didn\'t follow through', max: 'Followed through' },
      },
    ],
    growth: [
      {
        id: 'growth-perception',
        category: 'growth',
        question: 'How much growth do you perceive in your understanding of your vice and strengths?',
        scaleLabel: { min: 'No growth', max: 'Significant growth' },
      },
      {
        id: 'freedom-increase',
        category: 'growth',
        question: 'How much freedom from laziness and neglect have you experienced?',
        scaleLabel: { min: 'No freedom', max: 'Complete freedom' },
      },
      {
        id: 'fruitfulness-increase',
        category: 'growth',
        question: 'How much more fruitful for the Kingdom do you feel?',
        scaleLabel: { min: 'No increase', max: 'Significant increase' },
      },
      {
        id: 'strength-development',
        category: 'growth',
        question: 'How much have you developed in harnessing your strengths for God\'s Kingdom?',
        scaleLabel: { min: 'No development', max: 'Significant development' },
        relatedStrength: 'Compassion & Spiritual Sensitivity',
      },
    ],
  },
  'Recklessness & impulsiveness': {
    understanding: [
      {
        id: 'distortion-root',
        category: 'understanding',
        question: 'How clearly do you see that recklessness is a distortion of your boldness and initiative?',
        scaleLabel: { min: 'Not clear', max: 'Clear' },
        insight: 'Recklessness comes from boldness to act without waiting for God\'s timing.',
      },
      {
        id: 'timing-awareness',
        category: 'understanding',
        question: 'How aware are you of the importance of waiting on God\'s timing before acting?',
        scaleLabel: { min: 'Not aware', max: 'Aware' },
        relatedStrength: 'Sensitivity to divine timing',
      },
    ],
    commitment: [
      {
        id: 'prayer-before-action',
        category: 'commitment',
        question: 'How committed are you to pausing and praying before taking action?',
        scaleLabel: { min: 'Not committed', max: 'Committed' },
      },
      {
        id: 'patience-commitment',
        category: 'commitment',
        question: 'How committed are you to developing patience and discernment?',
        scaleLabel: { min: 'Not committed', max: 'Committed' },
      },
    ],
    reflection: [
      {
        id: 'impulse-recognition',
        category: 'reflection',
        question: 'How well do you recognize when you\'re acting on impulse versus waiting on God?',
        scaleLabel: { min: 'Poor', max: 'Good' },
      },
    ],
    accountability: [
      {
        id: 'prayer-before-decisions',
        category: 'accountability',
        question: 'How well did you pause and pray before making decisions today?',
        scaleLabel: { min: 'Didn\'t pause', max: 'Always paused' },
      },
    ],
    growth: [
      {
        id: 'patience-growth',
        category: 'growth',
        question: 'How much have you grown in patience and waiting on God\'s timing?',
        scaleLabel: { min: 'No growth', max: 'Significant growth' },
      },
    ],
  },
  'Ingratitude & entitlement': {
    understanding: [
      {
        id: 'distortion-root',
        category: 'understanding',
        question: 'How clearly do you see that entitlement comes from forgetting every good gift is from God?',
        scaleLabel: { min: 'Not clear', max: 'Clear' },
        insight: 'Entitlement distorts our ability to receive and give thanks.',
      },
    ],
    commitment: [
      {
        id: 'thanksgiving-commitment',
        category: 'commitment',
        question: 'How committed are you to practicing daily thanksgiving?',
        scaleLabel: { min: 'Not committed', max: 'Committed' },
      },
    ],
    reflection: [
      {
        id: 'gratitude-practice',
        category: 'reflection',
        question: 'How consistent is your practice of naming specific gifts God has given you?',
        scaleLabel: { min: 'Inconsistent', max: 'Consistent' },
      },
    ],
    accountability: [
      {
        id: 'thanksgiving-today',
        category: 'accountability',
        question: 'How well did you give thanks for God\'s gifts today?',
        scaleLabel: { min: 'Didn\'t give thanks', max: 'Gave thanks throughout' },
      },
    ],
    growth: [
      {
        id: 'gratitude-growth',
        category: 'growth',
        question: 'How much has your gratitude and recognition of God\'s gifts grown?',
        scaleLabel: { min: 'No growth', max: 'Significant growth' },
      },
    ],
  },
  'Fear & cowardice': {
    understanding: [
      {
        id: 'distortion-root',
        category: 'understanding',
        question: 'How clearly do you see that fear comes from trying to protect yourself instead of trusting God?',
        scaleLabel: { min: 'Not clear', max: 'Clear' },
        insight: 'Fear distorts your courage and boldness when not paired with trust in God\'s protection.',
      },
    ],
    commitment: [
      {
        id: 'courage-commitment',
        category: 'commitment',
        question: 'How committed are you to stepping forward despite fear, trusting God\'s protection?',
        scaleLabel: { min: 'Not committed', max: 'Committed' },
      },
    ],
    reflection: [
      {
        id: 'fear-recognition',
        category: 'reflection',
        question: 'How well do you recognize when fear is holding you back from obedience?',
        scaleLabel: { min: 'Poor', max: 'Good' },
      },
    ],
    accountability: [
      {
        id: 'courage-today',
        category: 'accountability',
        question: 'How well did you act with courage despite fear today?',
        scaleLabel: { min: 'Didn\'t act', max: 'Acted courageously' },
      },
    ],
    growth: [
      {
        id: 'courage-growth',
        category: 'growth',
        question: 'How much has your courage and trust in God\'s protection grown?',
        scaleLabel: { min: 'No growth', max: 'Significant growth' },
      },
    ],
  },
  'Vanity & elitism': {
    understanding: [
      {
        id: 'distortion-root',
        category: 'understanding',
        question: 'How clearly do you see that vanity comes from finding identity in achievements rather than in Christ?',
        scaleLabel: { min: 'Not clear', max: 'Clear' },
        insight: 'Vanity turns your creativity into self-promotion rather than pointing to God.',
      },
    ],
    commitment: [
      {
        id: 'humility-commitment',
        category: 'commitment',
        question: 'How committed are you to creating for God\'s glory alone, not for recognition?',
        scaleLabel: { min: 'Not committed', max: 'Committed' },
      },
    ],
    reflection: [
      {
        id: 'identity-check',
        category: 'reflection',
        question: 'How well do you check whether your identity is in Christ or in your achievements?',
        scaleLabel: { min: 'Poor', max: 'Good' },
      },
    ],
    accountability: [
      {
        id: 'humility-today',
        category: 'accountability',
        question: 'How well did you practice humility and point others to God today?',
        scaleLabel: { min: 'Didn\'t practice', max: 'Practiced well' },
      },
    ],
    growth: [
      {
        id: 'humility-growth',
        category: 'growth',
        question: 'How much has your humility and focus on God\'s glory grown?',
        scaleLabel: { min: 'No growth', max: 'Significant growth' },
      },
    ],
  },
  'Addiction to novelty': {
    understanding: [
      {
        id: 'distortion-root',
        category: 'understanding',
        question: 'How clearly do you see that addiction to novelty prevents you from seeing the fruit of your work?',
        scaleLabel: { min: 'Not clear', max: 'Clear' },
        insight: 'Addiction to novelty comes from restlessness that can\'t find peace in steady faithfulness.',
      },
    ],
    commitment: [
      {
        id: 'faithfulness-commitment',
        category: 'commitment',
        question: 'How committed are you to staying faithful to what you\'ve begun?',
        scaleLabel: { min: 'Not committed', max: 'Committed' },
      },
    ],
    reflection: [
      {
        id: 'commitment-check',
        category: 'reflection',
        question: 'How well do you recognize when you\'re seeking novelty versus staying committed?',
        scaleLabel: { min: 'Poor', max: 'Good' },
      },
    ],
    accountability: [
      {
        id: 'faithfulness-today',
        category: 'accountability',
        question: 'How well did you stay faithful to your commitments today?',
        scaleLabel: { min: 'Didn\'t stay faithful', max: 'Stayed very faithful' },
      },
    ],
    growth: [
      {
        id: 'faithfulness-growth',
        category: 'growth',
        question: 'How much has your faithfulness and commitment grown?',
        scaleLabel: { min: 'No growth', max: 'Significant growth' },
      },
    ],
  },
  'Legalism & isolation': {
    understanding: [
      {
        id: 'distortion-root',
        category: 'understanding',
        question: 'How clearly do you see that legalism comes from trying to control spiritual growth through rules?',
        scaleLabel: { min: 'Not clear', max: 'Clear' },
        insight: 'Legalism and isolation cut you off from the body of Christ.',
      },
    ],
    commitment: [
      {
        id: 'grace-commitment',
        category: 'commitment',
        question: 'How committed are you to extending grace and building community?',
        scaleLabel: { min: 'Not committed', max: 'Committed' },
      },
    ],
    reflection: [
      {
        id: 'grace-check',
        category: 'reflection',
        question: 'How well do you recognize when you\'re being legalistic versus extending grace?',
        scaleLabel: { min: 'Poor', max: 'Good' },
      },
    ],
    accountability: [
      {
        id: 'grace-today',
        category: 'accountability',
        question: 'How well did you extend grace and build community today?',
        scaleLabel: { min: 'Didn\'t extend grace', max: 'Extended grace well' },
      },
    ],
    growth: [
      {
        id: 'grace-growth',
        category: 'growth',
        question: 'How much has your grace and community-building grown?',
        scaleLabel: { min: 'No growth', max: 'Significant growth' },
      },
    ],
  },
  'Manipulation & ego-driven ambition': {
    understanding: [
      {
        id: 'distortion-root',
        category: 'understanding',
        question: 'How clearly do you see that manipulation comes when influence becomes about self-advancement?',
        scaleLabel: { min: 'Not clear', max: 'Clear' },
        insight: 'Manipulation turns your gifts of influence into self-serving tools.',
      },
    ],
    commitment: [
      {
        id: 'servant-commitment',
        category: 'commitment',
        question: 'How committed are you to using your influence to serve others and advance God\'s Kingdom?',
        scaleLabel: { min: 'Not committed', max: 'Committed' },
      },
    ],
    reflection: [
      {
        id: 'motive-check',
        category: 'reflection',
        question: 'How well do you check whether your actions serve others or yourself?',
        scaleLabel: { min: 'Poor', max: 'Good' },
      },
    ],
    accountability: [
      {
        id: 'service-today',
        category: 'accountability',
        question: 'How well did you use your influence to serve others today?',
        scaleLabel: { min: 'Didn\'t serve', max: 'Served well' },
      },
    ],
    growth: [
      {
        id: 'servant-growth',
        category: 'growth',
        question: 'How much has your servant-heartedness and humility grown?',
        scaleLabel: { min: 'No growth', max: 'Significant growth' },
      },
    ],
  },
};

export function getQuestionsForVice(
  vice: HabitVice | string | null,
  category: string,
  count: number = 2
): TruthSerumQuestion[] {
  if (!vice) return [];
  const pool = QUESTION_POOLS[vice as HabitVice]?.[category];
  if (!pool || pool.length === 0) return [];
  
  if (pool.length <= count) return pool;
  
  return pool.slice(0, count);
}

export function getAllQuestionsForVice(
  vice: HabitVice | string | null
): TruthSerumQuestion[] {
  if (!vice) return [];
  const pools = QUESTION_POOLS[vice as HabitVice];
  if (!pools) return [];
  
  return Object.values(pools).flat();
}

export function getDynamicQuestions(
  vice: HabitVice | string | null,
  previousAnswers: Record<string, number> | null,
  attemptNumber: number
): TruthSerumQuestion[] {
  if (!vice) return [];
  
  const questions: TruthSerumQuestion[] = [];
  
  if (attemptNumber === 1) {
    questions.push(...getQuestionsForVice(vice, 'understanding', 2));
    questions.push(...getQuestionsForVice(vice, 'commitment', 2));
  } else if (attemptNumber <= 10) {
    questions.push(...getQuestionsForVice(vice, 'understanding', 1));
    questions.push(...getQuestionsForVice(vice, 'reflection', 2));
    questions.push(...getQuestionsForVice(vice, 'accountability', 1));
  } else if (attemptNumber <= 30) {
    const categories = ['understanding', 'reflection', 'accountability', 'growth'];
    categories.forEach(cat => {
      questions.push(...getQuestionsForVice(vice, cat, 1));
    });
  } else {
    const allCategories = ['understanding', 'commitment', 'reflection', 'accountability', 'growth'];
    allCategories.forEach(cat => {
      const pool = QUESTION_POOLS[vice as HabitVice]?.[cat];
      if (pool && pool.length > 0) {
        const randomIndex = Math.floor(Math.random() * pool.length);
        questions.push(pool[randomIndex]);
      }
    });
  }
  
  return questions.slice(0, 5);
}

export function calculateProgress(
  answers: Record<string, number>,
  questions: TruthSerumQuestion[]
): {
  averageScore: number;
  categoryAverages: Record<string, number>;
} {
  if (Object.keys(answers).length === 0) {
    return { averageScore: 0, categoryAverages: {} };
  }
  
  const categoryScores: Record<string, number[]> = {};
  const allScores: number[] = [];
  
  Object.entries(answers).forEach(([questionId, score]) => {
    const question = questions.find(q => q.id === questionId);
    
    if (question) {
      if (!categoryScores[question.category]) {
        categoryScores[question.category] = [];
      }
      categoryScores[question.category].push(score);
      allScores.push(score);
    }
  });
  
  const categoryAverages: Record<string, number> = {};
  Object.entries(categoryScores).forEach(([category, scores]) => {
    categoryAverages[category] = scores.reduce((sum, s) => sum + s, 0) / scores.length;
  });
  
  const averageScore = allScores.reduce((sum, s) => sum + s, 0) / allScores.length;
  
  return { averageScore, categoryAverages };
}

