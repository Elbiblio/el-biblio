import type { HabitVice } from './habitConquestCapsules';
import { ARCHETYPES } from '@/constants/spiritualCareer';

export interface ViceStrengthMapping {
  vice: HabitVice;
  rootDistortion: string;
  distortionExplanation: string;
  relatedStrengths: {
    archetype: string;
    strengths: string[];
    howDistortionHappens: string;
    howToHarness: string;
  }[];
  kingdomImpact: string;
  prayerFocus: string;
  meditationFocus: string;
}

const VICE_STRENGTH_MAPPINGS: Record<HabitVice, ViceStrengthMapping> = {
  'Laziness & neglect': {
    vice: 'Laziness & neglect',
    rootDistortion: 'Comfort Zone Creation',
    distortionExplanation: 'Laziness and neglect arise from understanding God\'s power yet feeling helpless without His intervention. This creates a comfort zone where we shut out the world\'s troubles and stay numb or distracted. This distortion can lead to other vices like pornography, heavy gaming, drinking, etc.',
    relatedStrengths: [
      {
        archetype: 'Healer',
        strengths: ['Compassion', 'Presence in pain', 'Restorative faith', 'Patience'],
        howDistortionHappens: 'Healers have deep compassion and sensitivity to pain. When overwhelmed by the world\'s suffering and feeling powerless, they retreat into numbness to protect their hearts.',
        howToHarness: 'Channel your compassion into prayer for the new Kingdom. Your sensitivity to pain is a gift for intercession. Use your patience to build consistent habits that serve others.',
      },
      {
        archetype: 'Sentinel',
        strengths: ['Spiritual sensitivity', 'Authority in prayer', 'Discernment', 'Faithfulness in hidden places'],
        howDistortionHappens: 'Sentinels have profound spiritual awareness. When they see the depth of spiritual warfare and feel the weight of it, they can become paralyzed by the magnitude of what needs prayer and action.',
        howToHarness: 'Your spiritual sensitivity is meant for intercession. Your faithfulness in hidden places is powerful. Start with small, consistent prayer times. Your discernment will guide you to where God wants you to act.',
      },
    ],
    kingdomImpact: 'When laziness and neglect take hold, your God-given gifts of compassion and spiritual sensitivity become dormant. The Kingdom loses your intercession, your presence with the hurting, and your faithful witness in hidden places.',
    prayerFocus: 'Pray daily for the new Kingdom. Ask God to show you how your compassion and spiritual sensitivity can be channels for His work, not reasons to retreat.',
    meditationFocus: 'Meditate on your actual strengths: your ability to feel deeply, your spiritual awareness, your faithfulness. These are not weaknesses to numb—they are gifts to harness for God\'s Kingdom.',
  },
  'Recklessness & impulsiveness': {
    vice: 'Recklessness & impulsiveness',
    rootDistortion: 'Untamed Initiative',
    distortionExplanation: 'Recklessness comes from a boldness to act without waiting for God\'s timing. The strength of being an initiator becomes distorted when not anchored in prayer and discernment.',
    relatedStrengths: [
      {
        archetype: 'Sower',
        strengths: ['Boldness to start', 'Faith in unseen outcomes', 'Ability to inspire', 'Sensitivity to divine timing'],
        howDistortionHappens: 'Sowers have natural boldness and faith. When this isn\'t tempered with prayer and waiting on God, it becomes impulsiveness that jumps ahead of divine timing.',
        howToHarness: 'Your boldness is a gift. Pair it with prayer and waiting on God\'s timing. Your sensitivity to divine timing will grow as you practice stillness before acting.',
      },
    ],
    kingdomImpact: 'Recklessness wastes your boldness on things that don\'t bear fruit. Your ability to inspire becomes shallow when not rooted in God\'s timing.',
    prayerFocus: 'Pray for patience and discernment. Ask God to show you when to act and when to wait.',
    meditationFocus: 'Meditate on your gift of boldness and how it can be channeled through prayer and waiting on God.',
  },
  'Ingratitude & entitlement': {
    vice: 'Ingratitude & entitlement',
    rootDistortion: 'Blindness to Grace',
    distortionExplanation: 'Entitlement comes from forgetting that every good gift is from God. It distorts our ability to receive and give thanks.',
    relatedStrengths: [
      {
        archetype: 'Harvester',
        strengths: ['Effectiveness', 'Joy in results', 'Mobilizing others', 'Celebration'],
        howDistortionHappens: 'Harvesters see results and effectiveness. When this isn\'t grounded in gratitude to God, it becomes entitlement—thinking results are deserved rather than gifts.',
        howToHarness: 'Your effectiveness is a gift from God. Practice daily thanksgiving for every result, big or small. Let your celebration always point back to God\'s provision.',
      },
    ],
    kingdomImpact: 'Ingratitude robs the Kingdom of your joy and celebration. Your effectiveness becomes self-serving rather than Kingdom-serving.',
    prayerFocus: 'Pray with thanksgiving. Name specific gifts God has given you today, this week, this month.',
    meditationFocus: 'Meditate on God\'s generosity. Reflect on how every good thing in your life is an undeserved gift.',
  },
  'Fear & cowardice': {
    vice: 'Fear & cowardice',
    rootDistortion: 'Misplaced Protection',
    distortionExplanation: 'Fear arises when we try to protect ourselves instead of trusting God\'s protection. It distorts our courage and boldness.',
    relatedStrengths: [
      {
        archetype: 'Watchman',
        strengths: ['Sharp discernment', 'Courage to confront danger', 'Loyalty', 'Intercessory alertness'],
        howDistortionHappens: 'Watchmen have keen discernment and see dangers others miss. When this isn\'t paired with trust in God\'s protection, it becomes paralyzing fear.',
        howToHarness: 'Your discernment is a gift. Trust God\'s protection as you step forward. Your courage to confront danger is meant to protect others, not paralyze you.',
      },
      {
        archetype: 'Reformer',
        strengths: ['Righteous anger against injustice', 'Courage', 'Vision for transformation', 'Resilience'],
        howDistortionHappens: 'Reformers see injustice and want to change it. When fear of failure or opposition takes hold, their courage becomes cowardice.',
        howToHarness: 'Your righteous anger is a gift. Channel it through prayer and trust God to provide the courage to act. Your resilience grows as you step forward despite fear.',
      },
    ],
    kingdomImpact: 'Fear silences your voice against injustice. Your discernment and courage become dormant, leaving the vulnerable unprotected.',
    prayerFocus: 'Pray for courage and trust in God\'s protection. Ask Him to show you where He wants you to step forward despite fear.',
    meditationFocus: 'Meditate on God\'s perfect love that drives out fear. Reflect on your gift of courage and how it\'s meant to serve others.',
  },
  'Vanity & elitism': {
    vice: 'Vanity & elitism',
    rootDistortion: 'Identity in Performance',
    distortionExplanation: 'Vanity comes from finding identity in what others think or in our own achievements, rather than in Christ.',
    relatedStrengths: [
      {
        archetype: 'Artisan',
        strengths: ['Creativity that reflects God\'s nature', 'Ability to evoke emotion', 'Innovation', 'Prophetic symbolism'],
        howDistortionHappens: 'Artisans create beautiful things that move people. When identity gets tied to the response to their work, it becomes vanity and elitism.',
        howToHarness: 'Your creativity is a reflection of God\'s nature. Create for His glory, not for recognition. Your ability to evoke emotion is a gift to point others to God.',
      },
    ],
    kingdomImpact: 'Vanity turns your creativity into self-promotion. Your prophetic symbolism becomes about you rather than pointing to God.',
    prayerFocus: 'Pray for humility. Ask God to help you create for His glory alone, not for recognition.',
    meditationFocus: 'Meditate on your identity in Christ. Reflect on how your creativity is meant to reflect God, not elevate yourself.',
  },
  'Addiction to novelty': {
    vice: 'Addiction to novelty',
    rootDistortion: 'Restlessness in Steadiness',
    distortionExplanation: 'Addiction to novelty comes from restlessness that can\'t find peace in steady faithfulness. It distorts our ability to commit and see long-term growth.',
    relatedStrengths: [
      {
        archetype: 'Sower',
        strengths: ['Boldness to start', 'Faith in unseen outcomes', 'Ability to inspire', 'Sensitivity to divine timing'],
        howDistortionHappens: 'Sowers love to start new things. When this isn\'t balanced with commitment to see things through, it becomes an addiction to the excitement of new beginnings.',
        howToHarness: 'Your boldness to start is a gift. Pair it with commitment to faithfulness. Let your sensitivity to divine timing guide you to when it\'s time to start something new versus when to stay faithful to what you\'ve begun.',
      },
    ],
    kingdomImpact: 'Addiction to novelty prevents you from seeing the fruit of your work. Your ability to inspire becomes shallow when you never commit long enough to see transformation.',
    prayerFocus: 'Pray for faithfulness and commitment. Ask God to show you where to stay steady and where to start new things.',
    meditationFocus: 'Meditate on the value of steady faithfulness. Reflect on how God uses long-term commitment to produce lasting fruit.',
  },
  'Legalism & isolation': {
    vice: 'Legalism & isolation',
    rootDistortion: 'Protection Through Control',
    distortionExplanation: 'Legalism comes from trying to control spiritual growth through rules, and isolation from trying to protect purity by withdrawing from others.',
    relatedStrengths: [
      {
        archetype: 'Watchman',
        strengths: ['Sharp discernment', 'Courage to confront danger', 'Loyalty', 'Intercessory alertness'],
        howDistortionHappens: 'Watchmen have sharp discernment and see dangers clearly. When this isn\'t balanced with grace and community, it becomes legalism and isolation.',
        howToHarness: 'Your discernment is a gift. Use it to protect others through prayer and wise counsel, not to control them through rules. Your loyalty is meant to build community, not isolate you.',
      },
    ],
    kingdomImpact: 'Legalism and isolation cut you off from the body of Christ. Your discernment becomes judgment, and your loyalty becomes exclusion.',
    prayerFocus: 'Pray for grace and community. Ask God to show you how to use your discernment to protect and build up, not to control and exclude.',
    meditationFocus: 'Meditate on God\'s grace and how it transforms. Reflect on your need for community and how your gifts are meant to serve the body, not isolate you.',
  },
  'Manipulation & ego-driven ambition': {
    vice: 'Manipulation & ego-driven ambition',
    rootDistortion: 'Service Turned Self-Serving',
    distortionExplanation: 'Manipulation comes when our ability to influence and lead becomes about our own advancement rather than serving others and God.',
    relatedStrengths: [
      {
        archetype: 'Sower',
        strengths: ['Boldness to start', 'Faith in unseen outcomes', 'Ability to inspire', 'Sensitivity to divine timing'],
        howDistortionHappens: 'Sowers have natural ability to inspire and mobilize others. When this isn\'t grounded in serving God and others, it becomes manipulation and ego-driven ambition.',
        howToHarness: 'Your ability to inspire is a gift. Use it to point others to God and serve their calling, not your own. Let your sensitivity to divine timing guide you to when to step forward and when to step back.',
      },
      {
        archetype: 'Harvester',
        strengths: ['Effectiveness', 'Joy in results', 'Mobilizing others', 'Celebration'],
        howDistortionHappens: 'Harvesters see results and know how to mobilize others. When this becomes about personal recognition and advancement, it becomes manipulation.',
        howToHarness: 'Your effectiveness is a gift. Use it to advance God\'s Kingdom and others\' callings. Let your celebration always point to God\'s work, not your own.',
      },
    ],
    kingdomImpact: 'Manipulation and ego-driven ambition turn your gifts of influence into self-serving tools. The Kingdom loses your ability to mobilize others for God\'s purposes.',
    prayerFocus: 'Pray for humility and servant-heartedness. Ask God to show you how to use your influence to serve others and advance His Kingdom, not your own.',
    meditationFocus: 'Meditate on Jesus\' example of servant leadership. Reflect on how your gifts of influence are meant to serve others and point them to God.',
  },
};

export function getViceStrengthMapping(vice: HabitVice | string | null): ViceStrengthMapping | null {
  if (!vice) return null;
  return VICE_STRENGTH_MAPPINGS[vice as HabitVice] || null;
}

export function getTruthSerumQuestions(vice: HabitVice | string | null): Array<{
  id: string;
  question: string;
  type: 'reflection' | 'commitment' | 'understanding';
}> {
  const mapping = getViceStrengthMapping(vice);
  if (!mapping) return [];

  return [
    {
      id: 'distortion',
      question: `Have you recognized that ${mapping.vice.toLowerCase()} is a worldly distortion that comes from the fallen state, not your true nature?`,
      type: 'understanding' as const,
    },
    {
      id: 'strength1',
      question: mapping.relatedStrengths[0]
        ? `Do you see how your gift of ${mapping.relatedStrengths[0].strengths[0].toLowerCase()} is being distorted by ${mapping.vice.toLowerCase()}?`
        : `Do you recognize the strengths God has given you that are being made fruitless by this vice?`,
      type: 'understanding' as const,
    },
    {
      id: 'kingdom',
      question: `Do you understand how ${mapping.vice.toLowerCase()} is making you less fruitful for the Kingdom?`,
      type: 'understanding' as const,
    },
    {
      id: 'commitment',
      question: `Will you commit to praying daily for the new Kingdom and meditating on your actual strengths to rediscover productivity and fruitfulness?`,
      type: 'commitment' as const,
    },
    {
      id: 'harness',
      question: mapping.relatedStrengths[0]
        ? `Will you harness your ${mapping.relatedStrengths[0].strengths[0].toLowerCase()} for God's Kingdom instead of letting it be distorted?`
        : `Will you commit to using your God-given strengths for His Kingdom?`,
      type: 'commitment' as const,
    },
  ];
}

