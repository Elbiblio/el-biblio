export type Archetype = {
  name: string;
  identity: string;
  strengths: string;
  distortions: string;
  color: string;
  related: string[];
};

const DISTORTION_TRANSLATIONS: Record<string, string> = {
  Vanity: 'Worrying too much about what others think',
  Elitism: 'Feeling superior to others',
  'Addiction to novelty': 'Always needing something new',
  'Compromise for popularity': 'Changing yourself to fit in',
  Legalism: 'Being too strict with rules',
  Paranoia: 'Constantly worrying about threats',
  Isolation: 'Pulling away from others',
  'Resistance to grace': 'Hard to accept help or forgiveness',
  Overcontrol: 'Trying to control everything',
  'Fear of change': 'Resisting new things',
  Burnout: 'Feeling exhausted and overwhelmed',
  'Resistance to pruning': 'Holding onto things that should be let go',
  Impulsiveness: 'Jumping into things too quickly',
  'Shallow roots': 'Not sticking with things long enough',
  'Ego-driven ambition': 'Doing things for recognition',
  'Manipulation disguised as inspiration': "Trying to control others' choices",
  'People-pleasing': 'Always trying to make others happy',
  'Neglect of self-care': 'Putting others first, forgetting yourself',
  'Hospitality for personal gain': 'Being nice to get something',
  'Avoidance of truth to keep comfort': 'Avoiding difficult conversations',
  'Neglect of own calling': "Putting others' needs before your own purpose",
  'Enabling unhealthy dependence': 'Letting others rely on you too much',
  'Resentment from lack of recognition': 'Feeling unappreciated',
  'Fear of stepping forward': 'Holding back from taking action',
  'Pride in insight': 'Thinking you know better than others',
  'Neglect of action': 'Seeing problems but not doing anything',
  'Fear of exposure': 'Afraid of being seen or known',
  Compromise: 'Giving up what matters to avoid conflict',
  'Avoidance of conflict': 'Avoiding difficult conversations',
  'Loss of identity': 'Losing yourself to please others',
  'Savior complex': "Trying to fix everyone else's problems",
  'Emotional detachment': 'Shutting down your feelings',
  'Avoidance of hard truths': 'Avoiding difficult conversations',
  Exploitation: 'Using others for your own gain',
  'Obsession with metrics': 'Focusing too much on results',
  Superficiality: 'Staying on the surface, avoiding depth',
  'Pride in results': 'Taking too much credit for success',
  Pride: 'Thinking too highly of yourself',
  Bitterness: 'Holding onto past hurts',
  'Destructive rebellion': 'Fighting against everything',
  'Idolizing change': 'Making change the goal instead of improvement',
  'Rigid systems': "Sticking to rules even when they don't work",
  'Excessive control disguised as order': 'Controlling others while calling it organization',
  'Perfectionism that stifles growth': 'Demanding perfection that stops progress',
  'Inflexibility in methods': 'Refusing to try new approaches',
};

export const ARCHETYPES: Archetype[] = [
  {
    name: 'Artisan',
    identity: 'Creator',
    strengths: "Creativity that reflects God's nature, Ability to evoke emotion; Innovation; Prophetic symbolism",
    distortions: 'Vanity, Elitism; Addiction to novelty; Compromise for popularity',
    color: '#638B6C',
    related: ['Sower', 'Healer'],
  },
  {
    name: 'Watchman',
    identity: 'Guardian',
    strengths: "Sharp discernment, Courage to confront danger, Loyalty, Intercessory alertness",
    distortions: 'Legalism; Paranoia, Isolation, Resistance to grace',
    color: '#8B6B47',
    related: ['Sentinel', 'Reformer'],
  },
  {
    name: 'Cultivator',
    identity: 'Nurturer',
    strengths: 'Long-term investment mindset, Empathy, Ability to see hidden potential; Faithfulness in the mundane',
    distortions: 'Overcontrol; Fear of change; Burnout, Resistance to pruning',
    color: '#6B8B6B',
    related: ['Pillar', 'Healer'],
  },
  {
    name: 'Sower',
    identity: 'Initiator',
    strengths: 'Boldness to start without full clarity, Faith in unseen outcomes; Ability to inspire, Sensitivity to divine timing',
    distortions: 'Impulsiveness, Shallow roots; Ego-driven ambition; Manipulation disguised as inspiration',
    color: '#8B7B6B',
    related: ['Reformer', 'Artisan'],
  },
  {
    name: 'Welcomer',
    identity: 'Host',
    strengths: 'Generosity, Warmth, Attentiveness, Ability to set atmosphere for God\'s work',
    distortions: 'People-pleasing; Neglect of self-care, Hospitality for personal gain, Avoidance of truth to keep comfort',
    color: '#7B8B8B',
    related: ['Healer', 'Bridgebuilder'],
  },
  {
    name: 'Pillar',
    identity: 'Supporter',
    strengths: 'Loyalty, Humility, Perseverance; Reliability',
    distortions: 'Neglect of own calling, Enabling unhealthy dependence, Resentment from lack of recognition; Fear of stepping forward',
    color: '#6B6B8B',
    related: ['Cultivator', 'Bridgebuilder'],
  },
  {
    name: 'Sentinel',
    identity: 'Observer',
    strengths: 'Spiritual sensitivity, Authority in prayer, Discernment, Faithfulness in hidden places',
    distortions: 'Isolation; Pride in insight, Neglect of action; Fear of exposure',
    color: '#8B6B6B',
    related: ['Watchman', 'Bridgebuilder'],
  },
  {
    name: 'Bridgebuilder',
    identity: 'Connector',
    strengths: 'Empathy; Peacemaking; Unifying diverse groups, Humility',
    distortions: 'People-pleasing, Compromise; Avoidance of conflict, Loss of identity',
    color: '#7B8B6B',
    related: ['Welcomer', 'Pillar', 'Sentinel'],
  },
  {
    name: 'Healer',
    identity: 'Restorer',
    strengths: 'Compassion; Presence in pain; Restorative faith; Patience',
    distortions: 'Savior complex; Emotional detachment, Burnout, Avoidance of hard truths',
    color: '#8B7B7B',
    related: ['Welcomer', 'Artisan', 'Cultivator'],
  },
  {
    name: 'Harvester',
    identity: 'Gatherer',
    strengths: 'Effectiveness, Joy in results, Mobilizing others, Celebration',
    distortions: 'Exploitation; Obsession with metrics; Superficiality, Pride in results',
    color: '#6B8B7B',
    related: ['Architect', 'Sower'],
  },
  {
    name: 'Reformer',
    identity: 'Changer',
    strengths: 'Righteous anger against injustice; Courage; Vision for transformation; Resilience',
    distortions: 'Pride; Bitterness, Destructive rebellion, Idolizing change',
    color: '#7B6B8B',
    related: ['Sower', 'Watchman'],
  },
  {
    name: 'Architect',
    identity: 'Builder',
    strengths: 'Integrity, Strategic thinking, Faithfulness, Ability to multiply and sustain',
    distortions: 'Rigid systems; Excessive control disguised as order; Perfectionism that stifles growth; Inflexibility in methods',
    color: '#6B7B8B',
    related: ['Harvester', 'Cultivator'],
  },
];

export const INDUSTRIES = [
  'Education',
  'Healthcare',
  'Technology',
  'Finance',
  'Non-Profit',
  'Ministry',
  'Business',
  'Government',
  'Media',
  'Arts',
  'Retail',
  'Hospitality',
  'Manufacturing',
  'Construction',
  'Agriculture',
  'Legal',
  'Consulting',
  'Real Estate',
  'Transportation',
  'Energy',
] as const;

export const ROLE_TYPES = ['Management', 'Employee', 'Staff', 'Volunteer'] as const;
export type RoleType = typeof ROLE_TYPES[number];

export type DistortionTag = {
  id: string;
  label: string;
  original: string;
  archetypes: string[];
};

const normalizeId = (value: string) => value.toLowerCase().replace(/[^a-z0-9]+/g, '-');

const buildDistortionTags = (): DistortionTag[] => {
  const tags = new Map<string, DistortionTag>();

  ARCHETYPES.forEach((archetype) => {
    const rawTokens = archetype.distortions
      .split(/[,;]/)
      .map((token) => token.trim())
      .filter(Boolean);

    rawTokens.forEach((token) => {
      const id = normalizeId(token);
      const existing = tags.get(id);
      const label = DISTORTION_TRANSLATIONS[token] || token;

      if (existing) {
        if (!existing.archetypes.includes(archetype.name)) {
          existing.archetypes.push(archetype.name);
        }
        return;
      }

      tags.set(id, {
        id,
        label,
        original: token,
        archetypes: [archetype.name],
      });
    });
  });

  return Array.from(tags.values()).sort((a, b) => a.label.localeCompare(b.label));
};

export const DISTORTION_TAGS = buildDistortionTags();
