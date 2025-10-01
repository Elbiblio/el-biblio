/**
 * Spiritual Career Assessment Data Service
 * 
 * This service manages all data for the Spiritual Career Craft activity.
 * Currently uses local data, but structured for easy API integration.
 */

export interface StatusOption {
  value: string;
  label: string;
  emoji: string;
  multiplier: number;
  description: string;
}

export interface StrengthQuestion {
  question: string;
  weight: number;
  contexts?: string[]; // Which statuses this question is most relevant for
}

export interface StrengthDefinition {
  key: string;
  label: string;
  icon: string;
  category: string;
  description: string;
  questions: StrengthQuestion[];
}

export interface DailyTask {
  id: string;
  text: string;
  weight: number;
  category: string;
  difficulty: 'easy' | 'medium' | 'hard';
}

export interface CareerDefinition {
  title: string;
  description: string;
  icon: string;
}

// Status options with detailed descriptions
export const STATUS_OPTIONS: StatusOption[] = [
  {
    value: 'Student',
    label: 'Student',
    emoji: '📚',
    multiplier: 1.2,
    description: 'Currently in school, college, or university - learning and growing',
  },
  {
    value: 'Working',
    label: 'Working Professional',
    emoji: '💼',
    multiplier: 1.0,
    description: 'Employed full-time or part-time in a career or job',
  },
  {
    value: 'Ministry',
    label: 'Ministry/Missions',
    emoji: '✝️',
    multiplier: 1.3,
    description: 'Serving in full-time ministry, missions, or church leadership',
  },
  {
    value: 'Retired',
    label: 'Retired/Elder',
    emoji: '🌅',
    multiplier: 1.3,
    description: 'Retired from primary career - season of wisdom and legacy',
  },
  {
    value: 'Homemaker',
    label: 'Homemaker/Parent',
    emoji: '🏡',
    multiplier: 1.1,
    description: 'Primary focus on home, family, and raising children',
  },
  {
    value: 'Seeking',
    label: 'Seeking Direction',
    emoji: '🧭',
    multiplier: 0.9,
    description: 'Between seasons, exploring options, or discerning next steps',
  },
  {
    value: 'Volunteer',
    label: 'Volunteer/Servant',
    emoji: '🤲',
    multiplier: 1.1,
    description: 'Primarily serving through volunteer work and community service',
  },
];

// Comprehensive strength definitions with realistic, context-aware questions
export const STRENGTH_DEFINITIONS: StrengthDefinition[] = [
  {
    key: 'creativity',
    label: 'Creativity',
    icon: '🎨',
    category: 'expression',
    description: 'Expressing spiritual truths through creative mediums',
    questions: [
      {
        question: 'When I read Scripture, I naturally think of creative ways to share its message (art, story, music, etc.)',
        weight: 2.5,
        contexts: ['Student', 'Working', 'Ministry'],
      },
      {
        question: 'Others have told me my creative expressions (writing, art, music) have helped them understand God better',
        weight: 2.5,
      },
      {
        question: 'I find myself doodling, writing, or creating during my personal worship or prayer time',
        weight: 2.5,
      },
      {
        question: 'I get excited about designing visuals, crafting messages, or creating content that points people to Jesus',
        weight: 2.5,
        contexts: ['Student', 'Working', 'Ministry', 'Volunteer'],
      },
    ],
  },
  {
    key: 'discernment',
    label: 'Discernment',
    icon: '👁️',
    category: 'wisdom',
    description: 'Seeing spiritual realities and distinguishing truth from deception',
    questions: [
      {
        question: 'I can usually tell when someone is being genuine versus when something feels spiritually "off"',
        weight: 2.5,
      },
      {
        question: 'Friends and family come to me when they need help making wise decisions about relationships, jobs, or life direction',
        weight: 2.5,
        contexts: ['Working', 'Retired', 'Ministry', 'Homemaker'],
      },
      {
        question: 'Before making decisions, I naturally pause to examine my own motives and pray for clarity',
        weight: 2.5,
      },
      {
        question: 'I can sense when teaching or advice contradicts Scripture, even if I can\'t immediately explain why',
        weight: 2.5,
        contexts: ['Ministry', 'Retired', 'Student'],
      },
    ],
  },
  {
    key: 'nurture',
    label: 'Nurture',
    icon: '🌱',
    category: 'care',
    description: 'Helping others grow and mature in their faith journey',
    questions: [
      {
        question: 'I genuinely enjoy spending time helping someone younger in faith understand Scripture or grow spiritually',
        weight: 2.5,
        contexts: ['Ministry', 'Retired', 'Homemaker', 'Volunteer'],
      },
      {
        question: 'I celebrate small victories in others\' spiritual lives and patiently encourage them through setbacks',
        weight: 2.5,
      },
      {
        question: 'People have told me that my investment in their life helped them take significant steps in their faith',
        weight: 2.5,
      },
      {
        question: 'I naturally look for opportunities to mentor, disciple, or coach others in spiritual practices',
        weight: 2.5,
        contexts: ['Ministry', 'Working', 'Retired'],
      },
    ],
  },
  {
    key: 'initiative',
    label: 'Initiative',
    icon: '🚀',
    category: 'action',
    description: 'Starting new things and pioneering spiritual ventures',
    questions: [
      {
        question: 'When I see a need or opportunity, I don\'t wait for someone else—I take action and start something',
        weight: 2.5,
        contexts: ['Student', 'Working', 'Ministry', 'Volunteer'],
      },
      {
        question: 'I\'ve started prayer groups, Bible studies, service projects, or ministries that didn\'t exist before',
        weight: 2.5,
      },
      {
        question: 'I\'m comfortable being the first person to try a new approach to worship, outreach, or spiritual practice',
        weight: 2.5,
        contexts: ['Ministry', 'Student', 'Working'],
      },
      {
        question: 'Others describe me as someone who blazes trails rather than follows well-worn paths',
        weight: 2.5,
      },
    ],
  },
  {
    key: 'hospitality',
    label: 'Hospitality',
    icon: '🤝',
    category: 'care',
    description: 'Creating welcoming spaces where people feel valued and safe',
    questions: [
      {
        question: 'I regularly invite people into my home, car, or personal space and make them feel genuinely welcome',
        weight: 2.5,
        contexts: ['Homemaker', 'Working', 'Retired', 'Volunteer'],
      },
      {
        question: 'Newcomers, outsiders, or shy people naturally gravitate toward me because I make them feel comfortable',
        weight: 2.5,
      },
      {
        question: 'I find joy in preparing meals, organizing gatherings, or creating environments where people can connect',
        weight: 2.5,
        contexts: ['Homemaker', 'Retired', 'Ministry'],
      },
      {
        question: 'People have told me they felt seen, heard, and valued when they were in my presence or space',
        weight: 2.5,
      },
    ],
  },
  {
    key: 'support',
    label: 'Support',
    icon: '🛡️',
    category: 'service',
    description: 'Providing reliable foundation that enables others to succeed',
    questions: [
      {
        question: 'I prefer working behind the scenes on tasks that help others shine rather than being in the spotlight myself',
        weight: 2.5,
        contexts: ['Working', 'Volunteer', 'Homemaker', 'Ministry'],
      },
      {
        question: 'When I commit to something, people know they can count on me to follow through consistently',
        weight: 2.5,
      },
      {
        question: 'I get satisfaction from being the steady, dependable person who keeps things running smoothly',
        weight: 2.5,
      },
      {
        question: 'Leaders and friends specifically ask for my help because they trust my reliability and faithfulness',
        weight: 2.5,
        contexts: ['Working', 'Ministry', 'Retired', 'Volunteer'],
      },
    ],
  },
  {
    key: 'prayer',
    label: 'Prayer Watch',
    icon: '🙏',
    category: 'spiritual',
    description: 'Maintaining vigilant, strategic prayer for others and situations',
    questions: [
      {
        question: 'I regularly spend 15+ minutes praying specifically for other people, not just my own needs',
        weight: 2.5,
      },
      {
        question: 'I\'m alert to spiritual attacks and battles, and I pray strategically against them when I sense them',
        weight: 2.5,
        contexts: ['Ministry', 'Retired', 'Volunteer'],
      },
      {
        question: 'Prayer energizes me rather than feeling like a duty—it\'s where I feel most connected to God',
        weight: 2.5,
      },
      {
        question: 'I\'ve seen specific, tangible answers to prayers I\'ve been faithfully praying over time',
        weight: 2.5,
      },
    ],
  },
  {
    key: 'peacemaking',
    label: 'Peacemaking',
    icon: '🕊️',
    category: 'wisdom',
    description: 'Reconciling conflicts and building bridges between people',
    questions: [
      {
        question: 'When I see conflict between people, I naturally step in to help them understand each other and reconcile',
        weight: 2.5,
        contexts: ['Ministry', 'Homemaker', 'Working', 'Retired'],
      },
      {
        question: 'I can see multiple perspectives in disagreements and help others find common ground',
        weight: 2.5,
      },
      {
        question: 'I\'m willing to absorb some tension or discomfort myself if it means bringing peace to a situation',
        weight: 2.5,
      },
      {
        question: 'People seek me out when relationships are strained because they know I\'ll help without taking sides',
        weight: 2.5,
        contexts: ['Retired', 'Ministry', 'Homemaker'],
      },
    ],
  },
  {
    key: 'healing',
    label: 'Healing Presence',
    icon: '💚',
    category: 'care',
    description: 'Bringing comfort and restoration to wounded hearts',
    questions: [
      {
        question: 'People tell me they feel comforted, peaceful, or restored after spending time with me',
        weight: 2.5,
      },
      {
        question: 'I can sit with someone in their pain without trying to fix them or give quick answers',
        weight: 2.5,
        contexts: ['Ministry', 'Retired', 'Homemaker', 'Volunteer'],
      },
      {
        question: 'I\'ve prayed for people and witnessed emotional, relational, or spiritual healing take place',
        weight: 2.5,
      },
      {
        question: 'Hurting people naturally open up to me because they sense I carry God\'s compassion',
        weight: 2.5,
      },
    ],
  },
  {
    key: 'harvest',
    label: 'Follow-through',
    icon: '🌾',
    category: 'action',
    description: 'Completing projects and helping others reach their goals',
    questions: [
      {
        question: 'I have a track record of finishing projects, even when they get difficult or tedious',
        weight: 2.5,
        contexts: ['Working', 'Student', 'Ministry', 'Volunteer'],
      },
      {
        question: 'I actively help others complete their goals by checking in, encouraging, and assisting them',
        weight: 2.5,
      },
      {
        question: 'I get energized by crossing finish lines and celebrating completed work, not just starting new things',
        weight: 2.5,
      },
      {
        question: 'Leaders assign me important tasks because they know I\'ll see them through to completion',
        weight: 2.5,
        contexts: ['Working', 'Ministry', 'Volunteer'],
      },
    ],
  },
  {
    key: 'reform',
    label: 'Justice/Reform',
    icon: '⚖️',
    category: 'action',
    description: 'Addressing injustice and creating positive systemic change',
    questions: [
      {
        question: 'I feel deeply burdened by injustice and actively look for ways to address it, not just feel bad about it',
        weight: 2.5,
        contexts: ['Student', 'Working', 'Ministry', 'Volunteer'],
      },
      {
        question: 'I speak up for marginalized or oppressed people even when it\'s uncomfortable or unpopular',
        weight: 2.5,
      },
      {
        question: 'I take concrete actions (volunteering, advocating, organizing) to create positive change in broken systems',
        weight: 2.5,
        contexts: ['Working', 'Ministry', 'Volunteer', 'Student'],
      },
      {
        question: 'I can envision a more just future and work persistently to make that vision a reality',
        weight: 2.5,
      },
    ],
  },
  {
    key: 'stewardship',
    label: 'Stewardship',
    icon: '📊',
    category: 'service',
    description: 'Managing resources wisely to multiply kingdom impact',
    questions: [
      {
        question: 'I\'m intentional about how I use my time, money, and talents for God\'s purposes',
        weight: 2.5,
      },
      {
        question: 'I actively look for ways to multiply the impact of resources I\'ve been given',
        weight: 2.5,
        contexts: ['Working', 'Ministry', 'Retired', 'Homemaker'],
      },
      {
        question: 'I organize, budget, and optimize resources so that kingdom work can be more effective',
        weight: 2.5,
        contexts: ['Working', 'Ministry', 'Volunteer'],
      },
      {
        question: 'People trust me with money, time, or responsibility because I manage it faithfully and wisely',
        weight: 2.5,
      },
    ],
  },
];

// Daily tasks organized by category with difficulty levels
export const DAILY_TASKS: Record<string, DailyTask[]> = {
  expression: [
    { id: 'exp_1', text: 'Create a 2-minute reflection (text/voice/art) on today\'s verse', weight: 15, category: 'expression', difficulty: 'medium' },
    { id: 'exp_2', text: 'Share a creative illustration of a spiritual truth with someone', weight: 20, category: 'expression', difficulty: 'hard' },
    { id: 'exp_3', text: 'Write a short poem, prayer, or song inspired by Scripture', weight: 15, category: 'expression', difficulty: 'medium' },
    { id: 'exp_4', text: 'Design a visual reminder of God\'s truth for your space', weight: 10, category: 'expression', difficulty: 'easy' },
    { id: 'exp_5', text: 'Lead or contribute meaningfully to worship/creative expression', weight: 25, category: 'expression', difficulty: 'hard' },
    { id: 'exp_6', text: 'Journal about how God speaks through beauty and creativity', weight: 10, category: 'expression', difficulty: 'easy' },
  ],
  wisdom: [
    { id: 'wis_1', text: 'Examine your motives for 5 minutes before a key decision', weight: 15, category: 'wisdom', difficulty: 'medium' },
    { id: 'wis_2', text: 'Pray specifically for discernment about one situation', weight: 10, category: 'wisdom', difficulty: 'easy' },
    { id: 'wis_3', text: 'Study a Proverb and apply one insight to your day', weight: 15, category: 'wisdom', difficulty: 'medium' },
    { id: 'wis_4', text: 'Seek godly counsel from a mature believer about a challenge', weight: 20, category: 'wisdom', difficulty: 'hard' },
    { id: 'wis_5', text: 'Identify and resist one spiritual deception you\'ve noticed', weight: 20, category: 'wisdom', difficulty: 'hard' },
    { id: 'wis_6', text: 'Meditate on one attribute of God\'s character for 10 minutes', weight: 15, category: 'wisdom', difficulty: 'medium' },
  ],
  care: [
    { id: 'care_1', text: 'Send a thoughtful, encouraging message to someone struggling', weight: 10, category: 'care', difficulty: 'easy' },
    { id: 'care_2', text: 'Invest 10+ minutes helping someone grow in their faith', weight: 15, category: 'care', difficulty: 'medium' },
    { id: 'care_3', text: 'Prepare a meal or practical gift for someone in need', weight: 20, category: 'care', difficulty: 'hard' },
    { id: 'care_4', text: 'Listen deeply to someone for 15+ minutes without giving advice', weight: 15, category: 'care', difficulty: 'medium' },
    { id: 'care_5', text: 'Welcome a newcomer and help them feel genuinely valued', weight: 15, category: 'care', difficulty: 'medium' },
    { id: 'care_6', text: 'Pray with someone who needs comfort or encouragement', weight: 20, category: 'care', difficulty: 'hard' },
  ],
  action: [
    { id: 'act_1', text: 'Start one new spiritual habit or discipline today', weight: 20, category: 'action', difficulty: 'hard' },
    { id: 'act_2', text: 'Invite someone to join a faith activity or spiritual practice', weight: 15, category: 'action', difficulty: 'medium' },
    { id: 'act_3', text: 'Complete one lingering task with excellence', weight: 15, category: 'action', difficulty: 'medium' },
    { id: 'act_4', text: 'Take a bold, obedient step of faith you\'ve been avoiding', weight: 25, category: 'action', difficulty: 'hard' },
    { id: 'act_5', text: 'Address one injustice with concrete, constructive action', weight: 25, category: 'action', difficulty: 'hard' },
    { id: 'act_6', text: 'Help someone finish an important project or goal', weight: 20, category: 'action', difficulty: 'hard' },
  ],
  service: [
    { id: 'srv_1', text: 'Serve behind the scenes without seeking recognition', weight: 15, category: 'service', difficulty: 'medium' },
    { id: 'srv_2', text: 'Organize or improve a resource for greater kingdom impact', weight: 20, category: 'service', difficulty: 'hard' },
    { id: 'srv_3', text: 'Follow up faithfully on a commitment others depend on', weight: 15, category: 'service', difficulty: 'medium' },
    { id: 'srv_4', text: 'Track and steward 30 minutes intentionally for God\'s glory', weight: 10, category: 'service', difficulty: 'easy' },
    { id: 'srv_5', text: 'Give financially or materially with sacrificial generosity', weight: 20, category: 'service', difficulty: 'hard' },
    { id: 'srv_6', text: 'Maintain something that enables others to thrive', weight: 15, category: 'service', difficulty: 'medium' },
  ],
  spiritual: [
    { id: 'spi_1', text: 'Intercede for 15+ minutes for a specific person or need', weight: 20, category: 'spiritual', difficulty: 'hard' },
    { id: 'spi_2', text: 'Identify and pray against one spiritual attack you sense', weight: 20, category: 'spiritual', difficulty: 'hard' },
    { id: 'spi_3', text: 'Fast from one thing to focus more fully on prayer', weight: 25, category: 'spiritual', difficulty: 'hard' },
    { id: 'spi_4', text: 'Declare Scripture aloud over a challenging situation', weight: 15, category: 'spiritual', difficulty: 'medium' },
    { id: 'spi_5', text: 'Worship in spirit and truth for 20+ minutes', weight: 20, category: 'spiritual', difficulty: 'hard' },
    { id: 'spi_6', text: 'Ask God for a prophetic word and share it appropriately', weight: 25, category: 'spiritual', difficulty: 'hard' },
  ],
};

// Career definitions by category and score tier
export const CAREER_DEFINITIONS: Record<string, CareerDefinition[]> = {
  expression: [
    { title: 'Prophetic Artist', description: 'You paint God\'s truth through creative expression, bringing beauty and revelation to the body of Christ. Your art, words, or music become windows through which others see the divine.', icon: '🎨' },
    { title: 'Worship Architect', description: 'You design spaces and moments where heaven touches earth, crafting atmospheres for divine encounter. Your creativity opens doors for others to meet God.', icon: '🎭' },
    { title: 'Kingdom Storyteller', description: 'You weave narratives that illuminate Scripture and inspire transformation in hearts. Your words and images make the invisible visible and the complex clear.', icon: '📖' },
  ],
  wisdom: [
    { title: 'Spiritual Sentinel', description: 'You stand watch over the flock, discerning spirits and guarding truth with keen spiritual insight. Your gift protects others from deception and guides them toward wisdom.', icon: '🗼' },
    { title: 'Wisdom Keeper', description: 'You hold and dispense divine wisdom, helping others navigate complex spiritual terrain. Your counsel brings clarity to confusion and light to dark paths.', icon: '🦉' },
    { title: 'Peaceweaver', description: 'You mend broken relationships and build bridges, bringing God\'s shalom to divided spaces. Your presence transforms conflict into opportunities for reconciliation.', icon: '🕊️' },
  ],
  care: [
    { title: 'Soul Gardener', description: 'You cultivate growth in others, patiently nurturing seeds of faith into flourishing trees. Your investment in people yields lasting fruit across generations.', icon: '🌳' },
    { title: 'Healing Vessel', description: 'You carry God\'s restorative presence, bringing comfort and wholeness to wounded hearts. Your compassion becomes the channel through which divine healing flows.', icon: '💚' },
    { title: 'Sanctuary Builder', description: 'You create safe havens where the weary find rest and the broken find belonging. Your hospitality reflects the Father\'s heart for His children.', icon: '🏡' },
  ],
  action: [
    { title: 'Kingdom Pioneer', description: 'You blaze new trails for the gospel, initiating movements that advance God\'s kingdom. Your courage to step into the unknown opens paths for others to follow.', icon: '🚀' },
    { title: 'Justice Champion', description: 'You stand against oppression and advocate for the marginalized, embodying God\'s heart for righteousness. Your actions bring heaven\'s justice to earth\'s injustice.', icon: '⚖️' },
    { title: 'Harvest Leader', description: 'You mobilize and equip others, turning vision into reality and bringing projects to completion. Your follow-through ensures that good intentions become lasting impact.', icon: '🌾' },
  ],
  service: [
    { title: 'Faithful Steward', description: 'You multiply resources and manage them with integrity, ensuring kingdom work is sustained and fruitful. Your faithfulness in small things qualifies you for greater responsibility.', icon: '📊' },
    { title: 'Foundation Builder', description: 'You provide essential support that enables others to soar, serving behind the scenes with excellence. Your steady faithfulness is the bedrock on which ministries are built.', icon: '🛡️' },
    { title: 'Resource Multiplier', description: 'You see potential in what others overlook, turning small investments into abundant returns. Your stewardship maximizes impact and extends kingdom reach.', icon: '💎' },
  ],
  spiritual: [
    { title: 'Intercessory Warrior', description: 'You wage war in the heavenlies, standing in the gap and shifting spiritual atmospheres through prayer. Your intercession breaks chains and opens doors for breakthrough.', icon: '⚔️' },
    { title: 'Prayer Watchman', description: 'You maintain vigilant prayer, alert to spiritual movements and faithful in intercession. Your watch on the walls protects and advances God\'s purposes.', icon: '🙏' },
    { title: 'Prophetic Voice', description: 'You hear God\'s whispers and declare His word, calling people back to divine purpose. Your words carry weight because they flow from intimate communion with the Father.', icon: '📯' },
  ],
};

/**
 * Future API Integration Points:
 * 
 * - fetchStatusOptions(): Promise<StatusOption[]>
 * - fetchStrengthDefinitions(): Promise<StrengthDefinition[]>
 * - fetchDailyTasks(category: string): Promise<DailyTask[]>
 * - fetchCareerDefinitions(): Promise<Record<string, CareerDefinition[]>>
 * - submitAssessment(data: AssessmentData): Promise<AssessmentResult>
 */

export class SpiritualCareerDataService {
  /**
   * Get all status options
   * TODO: Replace with API call
   */
  static async getStatusOptions(): Promise<StatusOption[]> {
    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 100));
    return STATUS_OPTIONS;
  }

  /**
   * Get all strength definitions
   * TODO: Replace with API call
   */
  static async getStrengthDefinitions(): Promise<StrengthDefinition[]> {
    await new Promise(resolve => setTimeout(resolve, 100));
    return STRENGTH_DEFINITIONS;
  }

  /**
   * Get daily tasks for a specific category
   * TODO: Replace with API call
   */
  static async getDailyTasks(category: string): Promise<DailyTask[]> {
    await new Promise(resolve => setTimeout(resolve, 100));
    return DAILY_TASKS[category] || [];
  }

  /**
   * Get all daily tasks
   * TODO: Replace with API call
   */
  static async getAllDailyTasks(): Promise<Record<string, DailyTask[]>> {
    await new Promise(resolve => setTimeout(resolve, 100));
    return DAILY_TASKS;
  }

  /**
   * Get career definitions
   * TODO: Replace with API call
   */
  static async getCareerDefinitions(): Promise<Record<string, CareerDefinition[]>> {
    await new Promise(resolve => setTimeout(resolve, 100));
    return CAREER_DEFINITIONS;
  }
}
