import type { TruthSerumQuestion } from './habitConquestTruthSerumQuestions';
import { getViceStrengthMapping } from './habitConquestViceStrengthMapping';
import type { HabitVice } from './habitConquestCapsules';

export interface TruthSerumSummary {
  overallScore: number;
  categoryScores: Record<string, number>;
  insights: string[];
  strengths: string[];
  nextSteps: string[];
  encouragement: string;
}

export function generateSummary(
  vice: HabitVice | string | null,
  questions: TruthSerumQuestion[],
  answers: Record<string, number>
): TruthSerumSummary {
  if (!vice || questions.length === 0) {
    return {
      overallScore: 0,
      categoryScores: {},
      insights: [],
      strengths: [],
      nextSteps: [],
      encouragement: 'Keep going. Every step forward matters.',
    };
  }

  const mapping = getViceStrengthMapping(vice);
  
  const categoryScores: Record<string, number[]> = {};
  const allScores: number[] = [];

  questions.forEach(question => {
    const score = answers[question.id] ?? 0;
    if (score > 0) {
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

  const overallScore = allScores.length > 0
    ? allScores.reduce((sum, s) => sum + s, 0) / allScores.length
    : 0;

  const insights: string[] = [];
  const strengths: string[] = [];
  const nextSteps: string[] = [];

  const understandingScore = categoryAverages.understanding ?? 0;
  const commitmentScore = categoryAverages.commitment ?? 0;
  const reflectionScore = categoryAverages.reflection ?? 0;
  const accountabilityScore = categoryAverages.accountability ?? 0;
  const growthScore = categoryAverages.growth ?? 0;

  if (understandingScore < 5) {
    insights.push(`Your understanding of how ${vice.toLowerCase()} distorts your strengths is still developing. This is normal—growth takes time.`);
    nextSteps.push('Spend time reflecting on how your vice connects to your God-given strengths.');
  } else if (understandingScore < 8) {
    insights.push(`You're building a clearer picture of how ${vice.toLowerCase()} works. Keep exploring this connection.`);
    strengths.push('You have growing awareness of the distortion.');
  } else {
    insights.push(`You have strong clarity about how ${vice.toLowerCase()} distorts your strengths. This understanding is powerful.`);
    strengths.push('Clear understanding of the root issue.');
  }

  if (commitmentScore < 5) {
    insights.push('Your commitment to change is still forming. Be patient with yourself.');
    nextSteps.push('Start with small daily commitments. One prayer, one moment of meditation.');
  } else if (commitmentScore < 8) {
    insights.push('You have solid commitment. Now focus on turning that commitment into daily practice.');
    strengths.push('Strong commitment to change.');
    nextSteps.push('Build consistent daily habits around your commitments.');
  } else {
    insights.push('You have deep commitment. This is your foundation for lasting change.');
    strengths.push('Deep commitment to transformation.');
  }

  if (reflectionScore < 5) {
    insights.push('Self-reflection is a skill that grows with practice. Start noticing your patterns.');
    nextSteps.push('Set aside 5 minutes daily to reflect on how you used or avoided your strengths.');
  } else if (reflectionScore < 8) {
    insights.push('You\'re developing good self-awareness. Keep checking in with yourself regularly.');
    strengths.push('Growing self-awareness.');
  } else {
    insights.push('You have strong self-awareness. This helps you catch patterns early.');
    strengths.push('Excellent self-awareness.');
  }

  if (accountabilityScore > 0) {
    if (accountabilityScore < 5) {
      insights.push('Today was challenging. That\'s okay. Every day is a new opportunity.');
      nextSteps.push('Focus on one small action tomorrow that uses your strengths.');
    } else if (accountabilityScore < 8) {
      insights.push('You\'re making progress. Keep building on today\'s efforts.');
      strengths.push('Consistent daily effort.');
    } else {
      insights.push('You did well today. Your faithfulness is bearing fruit.');
      strengths.push('Strong daily follow-through.');
    }
  }

  if (growthScore > 0) {
    if (growthScore < 5) {
      insights.push('Growth often feels slow, but it\'s happening. Trust the process.');
    } else if (growthScore < 8) {
      insights.push('You\'re seeing real growth. Celebrate the progress you\'ve made.');
      strengths.push('Measurable growth.');
    } else {
      insights.push('You\'ve experienced significant growth. This is God at work in you.');
      strengths.push('Significant transformation.');
    }
  }

  if (mapping && mapping.relatedStrengths.length > 0) {
    const primaryStrength = mapping.relatedStrengths[0];
    strengths.push(`Your gift of ${primaryStrength.strengths[0].toLowerCase()} is waiting to be harnessed.`);
    
    if (overallScore < 5) {
      nextSteps.push(`Start praying daily: "God, show me how to use my ${primaryStrength.strengths[0].toLowerCase()} for Your Kingdom."`);
    } else if (overallScore < 8) {
      nextSteps.push(`Look for one opportunity today to use your ${primaryStrength.strengths[0].toLowerCase()} in service.`);
    } else {
      nextSteps.push(`Keep channeling your ${primaryStrength.strengths[0].toLowerCase()} into Kingdom work.`);
    }
  }

  if (nextSteps.length === 0) {
    nextSteps.push('Continue your daily practice of prayer and meditation.');
    nextSteps.push('Stay connected to your strengths and use them for God\'s Kingdom.');
  }

  let encouragement = '';
  if (overallScore < 4) {
    encouragement = 'Starting is the hardest part. You\'ve taken the first step. Keep going.';
  } else if (overallScore < 6) {
    encouragement = 'You\'re on the path. Every day you show up is progress.';
  } else if (overallScore < 8) {
    encouragement = 'You\'re making real progress. Your commitment and awareness are growing.';
  } else {
    encouragement = 'You\'re doing well. Your understanding and commitment are strong. Keep building on this foundation.';
  }

  return {
    overallScore: Math.round(overallScore * 10) / 10,
    categoryScores: categoryAverages,
    insights,
    strengths: strengths.length > 0 ? strengths : ['You\'re taking steps forward.'],
    nextSteps,
    encouragement,
  };
}

