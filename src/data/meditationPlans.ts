import { foundationParablePlans, growthParablePlans, deepParablePlans } from '@/lib/parableMeditations';

export type MeditationLevel = 'foundation' | 'growth' | 'deep';

export interface MeditationPlan {
  id: string;
  title: string;
  parable: string;
  scripture: string;
  overview: string;
  breathInvitation: string;
  reflectionPrompts: string[];
  focusOptions: string[];
  challengePrompt: string;
  closingReminder: string;
  openReflection?: string;
  guidanceTips?: string[];
  stageNote?: string;
}

interface BuildMeditationPlanArgs {
  level: MeditationLevel;
  dateSeed?: number;
  challengeText?: string | null;
  sessionCount?: number;
}

type PlanCollection = MeditationPlan[];

const foundationPlans: PlanCollection = foundationParablePlans;

const growthPlans: PlanCollection = growthParablePlans;

const deepPlans: PlanCollection = deepParablePlans;

export interface ContemplativePractice {
  id: string;
  name: string;
  description: string;
  focus: string[];
  guidance: string[];
  tags: string[];
}

export const contemplativePractices: ContemplativePractice[] = [
  {
    id: 'centering-prayer',
    name: 'Centering Prayer',
    description: 'Choose a sacred word and rest quietly before God, letting the word return you to His presence whenever thoughts wander.',
    focus: [
      'Sacred word anchoring your attention',
      'Opening to God beyond thoughts and emotions',
      'Practicing gentle surrender when distractions appear'
    ],
    guidance: [
      'Set a timer for 5–20 minutes based on your capacity.',
      'Gently repeat your sacred word whenever you notice your attention drifting.',
      'Close with gratitude, acknowledging any subtle movements of the heart.'
    ],
    tags: ['sacred-word', 'stilling', 'silent-prayer']
  },
  {
    id: 'silent-communion',
    name: 'Silent Communion',
    description: 'Sit in receptive stillness, imagining yourself with Jesus and allowing quiet communion to deepen trust.',
    focus: [
      'Imagining the nearness of Jesus',
      'Letting silence soften restless thoughts',
      'Listening for gentle impressions'
    ],
    guidance: [
      'Find a posture that lets you remain present yet relaxed.',
      'Breathe slowly and picture resting beside Jesus.',
      'Close by noting one feeling or word that surfaced during the silence.'
    ],
    tags: ['stillness', 'presence', 'listening']
  },
  {
    id: 'jesus-prayer',
    name: 'Jesus Prayer',
    description: 'Pray the ancient phrase “Lord Jesus Christ, Son of God, have mercy on me” in rhythm with your breath.',
    focus: [
      'Breathing in the first half of the prayer',
      'Breathing out the second half of the prayer',
      'Leaning into mercy and compassion'
    ],
    guidance: [
      'Match the words to your inhale and exhale gently.',
      'If distractions come, return to the rhythm without judgment.',
      'Consider dedicating the prayer to someone who needs mercy.'
    ],
    tags: ['breath-prayer', 'mercy', 'compassion']
  },
  {
    id: 'breath-focus',
    name: 'Breath & Focus',
    description: 'Use simple breathing cues to notice God’s steadying presence and release tension in body and mind.',
    focus: [
      'Intentional inhale and exhale counts',
      'Relaxing muscle groups as you breathe',
      'Inviting God into areas of anxiety'
    ],
    guidance: [
      'Try a four-count inhale, four-count hold, and six-count exhale.',
      'Scan your body, relaxing one area with each exhale.',
      'End by asking God for one word to carry into your next task.'
    ],
    tags: ['breathing', 'calming', 'embodied-prayer']
  },
  {
    id: 'daily-examen',
    name: 'Daily Examen',
    description: 'Review the day with God, celebrating moments of grace and noticing where His presence felt distant.',
    focus: [
      'Gratitude for concrete gifts',
      'Owning your emotions and reactions',
      'Inviting God into tomorrow’s choices'
    ],
    guidance: [
      'Start with gratitude for two or three moments.',
      'Review your day slowly, asking where you sensed God strongly or faintly.',
      'Ask for help living tomorrow with deeper awareness.'
    ],
    tags: ['reflection', 'gratitude', 'discernment']
  },
  {
    id: 'self-reflection',
    name: 'Self-Reflection',
    description: 'Hold a specific question before God, journaling honest thoughts and listening for gentle correction or affirmation.',
    focus: [
      'Naming present emotions truthfully',
      'Seeking God’s perspective on your story',
      'Responding with one practical shift'
    ],
    guidance: [
      'Frame a single question such as “Where am I resisting grace?”',
      'Journal freely for a few minutes without editing.',
      'Summarize one small response you can take today.'
    ],
    tags: ['journaling', 'awareness', 'growth']
  },
  {
    id: 'journaling-tracking',
    name: 'Journaling & Growth Tracking',
    description: 'Capture insights, emotions, and commitments so you can see patterns of growth over time.',
    focus: [
      'Recording what resonated in prayer or Scripture',
      'Naming habits that help or hinder growth',
      'Celebrating incremental change'
    ],
    guidance: [
      'Keep a dedicated section for wins, questions, and prayers.',
      'Review entries weekly to notice recurring themes.',
      'Identify one area of growth and one area needing attention.'
    ],
    tags: ['journaling', 'tracking', 'celebration']
  },
  {
    id: 'taize-chant',
    name: 'Taizé Chant',
    description: 'Repeat short chants or scriptures set to simple melodies, letting the repetition settle truth into your heart.',
    focus: [
      'Singing or speaking phrases slowly',
      'Allowing melody to shape your breath',
      'Letting the refrain move from head to heart'
    ],
    guidance: [
      'Sing quietly or hum along in prayer.',
      'Let the refrain linger.',
      'Close by resting in silence.'
    ],
    tags: ['worship', 'chant', 'music']
  },
  {
    id: 'worship-emotion',
    name: 'Worship & Emotion',
    description: 'Pair worship music with honest emotional expression, letting God meet you in joy, lament, or longing.',
    focus: [
      'Selecting songs that match your current season',
      'Naming emotions openly before God',
      'Inviting God to shape your response'
    ],
    guidance: [
      'Create a short playlist reflecting your present emotions.',
      'Sing or journal along with the lyrics that stand out.',
      'Note any shifts in perspective or sense of God’s nearness.'
    ],
    tags: ['worship', 'emotion', 'processing']
  },
  {
    id: 'theme-library',
    name: 'Theme & Chant Library',
    description: 'Explore curated themes, scriptures, and chants that match the season you are in, building a personal reservoir of hope.',
    focus: [
      'Matching themes to current challenges',
      'Collecting scriptures and phrases that ground you',
      'Sharing selections with friends or community'
    ],
    guidance: [
      'Select one theme for the week (e.g., hope, trust, courage).',
      'Gather scriptures, prayers, and music that reinforce the theme.',
      'Revisit the theme daily; listen for God\'s guidance.'
    ],
    tags: ['library', 'resource', 'community']
  }
];

const levelMap: Record<MeditationLevel, PlanCollection> = {
  foundation: foundationPlans,
  growth: growthPlans,
  deep: deepPlans,
};

const normalizeSeed = (seed?: number) => {
  if (!seed || Number.isNaN(seed)) {
    return Date.now();
  }
  return seed;
};

const resolvePlanIndex = (plans: PlanCollection, seed: number, sessionCount?: number) => {
  if (!plans.length) {
    return 0;
  }
  const seedOffset = seed % plans.length;
  if (sessionCount === undefined || sessionCount < 0) {
    return seedOffset;
  }
  const bucket = Math.min(plans.length - 1, Math.floor(sessionCount / 3));
  return (bucket + seedOffset) % plans.length;
};

export const buildMeditationPlan = ({ level, dateSeed, challengeText, sessionCount }: BuildMeditationPlanArgs): MeditationPlan => {
  const seed = normalizeSeed(dateSeed);
  const plans = levelMap[level] ?? foundationPlans;
  const planIndex = resolvePlanIndex(plans, seed, sessionCount);
  const plan = plans[planIndex];
  const challengeLine = challengeText?.trim().length
    ? `${plan.challengePrompt} Consider “${challengeText.trim()}” as you reflect.`
    : plan.challengePrompt;

  return {
    ...plan,
    challengePrompt: challengeLine,
  };
};
