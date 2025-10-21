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

const foundationPlans: PlanCollection = [
  {
    id: 'sower',
    title: 'Listening with the Sower',
    parable: 'Parable of the Sower',
    scripture: 'Luke 8:4-8',
    overview: 'Picture Jesus describing the farmer scattering seeds. Notice the different soils and let one scene catch your attention.',
    breathInvitation: 'Breathe slowly and imagine the rhythm of planting—steady, patient, hopeful.',
    reflectionPrompts: [
      'Which soil feels most familiar to life right now, and what do you want to do with that insight?',
      'Ask Jesus where you sense new growth trying to break through.',
      'Consider a simple habit that could help you keep what you are receiving today.',
      'Notice any part of the story that surprises you and sit with it for a few breaths.'
    ],
    focusOptions: [
      'Pay attention to one word or phrase from the parable that stays with you.',
      'Think about someone you could encourage with hope from this story.',
      'Let the picture of good soil shape how you want to show up after this time.'
    ],
    challengePrompt: 'How could this story speak into the challenge you brought with you today?',
    closingReminder: 'Carry the image of seed and soil with you, adjusting the ground of your day as you go.',
    openReflection: 'Pause for a moment and tell Jesus which soil you long to become.',
    guidanceTips: [
      'Keep today simple—notice one response you can actually follow through on.',
      'Let curiosity lead instead of pressure if distractions appear.',
    ],
    stageNote: 'Beginning to listen and receive well.',
  },
  {
    id: 'mustard-seed',
    title: 'Trusting the Mustard Seed',
    parable: 'Parable of the Mustard Seed',
    scripture: 'Matthew 13:31-32',
    overview: 'Imagine holding a small seed in your hand while Jesus describes how it becomes a tree. Let the size difference stir quiet confidence.',
    breathInvitation: 'Inhale slowly as you picture planting the seed, exhale imagining its future branches.',
    reflectionPrompts: [
      'Where do you see small beginnings in your life that deserve more care?',
      'Invite Jesus to show you one next step that matches the size of the seed.',
      'How could you create space for steady growth instead of instant results?',
      'Notice any resistance to smallness and talk honestly with Him about it.'
    ],
    focusOptions: [
      'Consider what kind of shelter you hope this seed becomes for others.',
      'Name the support you might need while the seed is still hidden underground.',
      'Simply rest in gratitude for the small things that are already growing.'
    ],
    challengePrompt: 'Let the seed speak into your current pressure—what small faithful action fits today?',
    closingReminder: 'Leave the seed planted and return to your day with permission to grow at a gentle pace.',
    openReflection: 'Ask where you sense quiet resilience already forming in your life.',
    guidanceTips: [
      'Practice a single breath prayer whenever you feel rushed.',
      'Write down small wins so you can celebrate them later.',
    ],
    stageNote: 'Exploring slow, faithful beginnings.',
  },
  {
    id: 'good-samaritan',
    title: 'Walking with the Good Samaritan',
    parable: 'Parable of the Good Samaritan',
    scripture: 'Luke 10:25-37',
    overview: 'Visualize the road to Jericho. Walk through the story slowly and notice where you want to pause.',
    breathInvitation: 'Breathe in compassion, breathe out hurry. Let each breath slow your pace on the road.',
    reflectionPrompts: [
      'Which character do you identify with today, and why?',
      'Ask Jesus who might be waiting on the roadside of your attention.',
      'What would it look like to receive help instead of giving it in this season?',
      'Choose one gentle action of care you could offer after this session.'
    ],
    focusOptions: [
      'Imagine Jesus kneeling beside someone in need and notice what He invites you into.',
      'Reflect on how love can look practical and ordinary today.',
      'Let the story reshape the way you plan to move through your tasks.'
    ],
    challengePrompt: 'Where does this story invite you to show up differently in the situation you’re facing?',
    closingReminder: 'Step back onto your road aware that mercy can meet people—and you—in simple steps.',
    openReflection: 'Name one place you long to receive mercy as freely as you give it.',
    guidanceTips: [
      'Notice intersections in your day where you can slow down to see people.',
      'Try journaling one sentence about where you saw compassion in action.',
    ],
    stageNote: 'Learning to respond with compassion.',
  },
  {
    id: 'lost-sheep',
    title: 'Resting with the Lost Sheep',
    parable: 'Parable of the Lost Sheep',
    scripture: 'Luke 15:1-7',
    overview: 'See the Shepherd searching across hills until your name is found. Notice how He carries you back.',
    breathInvitation: 'Inhale as you imagine being lifted, exhale as you rest on His shoulders.',
    reflectionPrompts: [
      'Where do you feel lost or unseen right now?',
      'How does it feel to be carried without earning it?',
      'What does celebration look like when you let yourself be found?',
      'Who could you celebrate with this week to remember grace?',
    ],
    focusOptions: [
      'Picture the Shepherd calling your name out loud.',
      'Let joy rise as you imagine the celebration in heaven.',
      'Plan a small act of gratitude for the One who found you.',
    ],
    challengePrompt: 'Let being carried reshape the way you face your current challenge.',
    closingReminder: 'Walk back into your day knowing you are worth searching for every time.',
    openReflection: 'Notice what shifts when you picture His delight over you.',
    guidanceTips: [
      'Keep a gratitude note about moments you felt seen today.',
      'Practice telling yourself the Shepherd is near whenever anxiety rises.',
    ],
    stageNote: 'Opening to belonging and being found.',
  },
  {
    id: 'wise-builder',
    title: 'Steadying with the Wise Builder',
    parable: 'Parable of the Wise and Foolish Builders',
    scripture: 'Matthew 7:24-27',
    overview: 'Imagine storms arriving as you stand on the rock that does not move. Feel the stability under your feet.',
    breathInvitation: 'Breathe in strength, breathe out tension, keeping steady like a foundation.',
    reflectionPrompts: [
      'Where is your daily routine resting on shifting sand?',
      'What practice helps you anchor in Jesus when storms show up?',
      'How can you respond differently the next time wind hits plans?',
      'Name a truth you want to build into your week like a sturdy beam.',
    ],
    focusOptions: [
      'Visualize the foundation forming under each obedient step.',
      'Invite Jesus to show you a wise builder to learn from.',
      'Commit to one grounded response when pressure rises.',
    ],
    challengePrompt: 'Let the firm foundation guide how you meet today’s challenge.',
    closingReminder: 'Carry the sense of steady ground into every conversation today.',
    openReflection: 'Ask what needs to be rebuilt slowly instead of rushed.',
    guidanceTips: [
      'Repeat a grounding scripture while you breathe through uncertainty.',
      'Share your plan with a friend who can encourage your steady steps.',
    ],
    stageNote: 'Stabilizing rhythms and responses.',
  }
];

const growthPlans: PlanCollection = [
  {
    id: 'prayer-persistence',
    title: 'Keeping Company with the Persistent Friend',
    parable: 'Parable of the Friend at Midnight',
    scripture: 'Luke 11:5-10',
    overview: 'Imagine knocking on a friend’s door at night, trusting that your need will be heard.',
    breathInvitation: 'Breathe in courage, breathe out hesitation, keeping a gentle rhythm as you knock.',
    reflectionPrompts: [
      'What request have you been tempted to stop bringing to God?',
      'How might persistence look like steady trust instead of striving?',
      'Notice any invitation to ask for help from people around you.',
      'Consider how you can keep your heart open while you wait.'
    ],
    focusOptions: [
      'Name one thing you will keep asking for this week.',
      'Imagine Jesus opening the door and listen for His welcome.',
      'Choose a simple practice that helps you stay attentive between asks.'
    ],
    challengePrompt: 'Let this picture reshape how you face the challenge in front of you right now.',
    closingReminder: 'Walk away knowing the door is never closed to a persistent child of God.',
    openReflection: 'Tell God the request you almost stopped mentioning and wait in the quiet.',
    guidanceTips: [
      'Set a gentle reminder to check in with God about this request daily.',
      'Notice when you confuse persistence with striving and soften your approach.',
    ],
    stageNote: 'Strengthening trust through steady asking.',
  },
  {
    id: 'talents',
    title: 'Investing the Talents',
    parable: 'Parable of the Talents',
    scripture: 'Matthew 25:14-30',
    overview: 'See yourself receiving something valuable from the Master. Notice your first response.',
    breathInvitation: 'With each breath, release comparison and welcome courage.',
    reflectionPrompts: [
      'What resource or gift feels buried right now?',
      'Ask Jesus how you might take one small step of faithful investment.',
      'What fear keeps you holding back, and how might love respond?',
      'Imagine celebrating with the Master after a day of steady stewardship.'
    ],
    focusOptions: [
      'Write down one practical risk you can take in the next week.',
      'Consider who could encourage you while you invest what you have.',
      'Let gratitude for what’s already in your hands be your focus.'
    ],
    challengePrompt: 'How does this story invite you to respond to your current challenge with hope?',
    closingReminder: 'Step back into your day ready to invest what you’ve been trusted with.',
    openReflection: 'Ask which faithful risk would bring joy to the Master today.',
    guidanceTips: [
      'Name a mentor or friend who can check in on your next step.',
      'Break big ideas into smaller experiments you can learn from.',
    ],
    stageNote: 'Practicing courageous stewardship.',
  },
  {
    id: 'unforgiving-servant',
    title: 'Breathing through Forgiveness',
    parable: 'Parable of the Unforgiving Servant',
    scripture: 'Matthew 18:21-35',
    overview: 'Walk through the story noticing the drastic gap between mercy received and mercy withheld.',
    breathInvitation: 'Inhale grace received, exhale grace offered, even if only in intention today.',
    reflectionPrompts: [
      'Where do you feel the weight of an unpaid debt in your relationships?',
      'How does remembering your own release shift your posture?',
      'What boundary might help you forgive while staying healthy?',
      'Imagine offering kindness without ignoring wisdom or safety.',
    ],
    focusOptions: [
      'Write a statement releasing the person to God’s care.',
      'Pray blessing over someone it is hard to bless.',
      'Receive compassion for yourself as you learn to forgive.',
    ],
    challengePrompt: 'Let forgiveness reshape how you navigate today’s tension.',
    closingReminder: 'Move forward lighter, aware that mercy keeps the heart wide open.',
    openReflection: 'Notice what surfaces when you picture handing the debt to the King.',
    guidanceTips: [
      'Practice a breath prayer: “Mercy received, mercy released.”',
      'Journal one step that keeps you safe while moving toward forgiveness.',
    ],
    stageNote: 'Stretching capacity for mercy.',
  },
  {
    id: 'ten-virgins',
    title: 'Staying Ready with the Bridesmaids',
    parable: 'Parable of the Ten Virgins',
    scripture: 'Matthew 25:1-13',
    overview: 'Stand among the bridesmaids and feel the difference between oil running low and lamps burning steady.',
    breathInvitation: 'Breathe in expectancy, breathe out preparation as you tend your lamp.',
    reflectionPrompts: [
      'What does staying awake look like in your current season?',
      'Where do you sense oil reserves running low and needing renewal?',
      'How can you respond wisely without rescuing everyone else?',
      'Imagine greeting Jesus with a lamp that stayed lit through the night.',
    ],
    focusOptions: [
      'List small rhythms that keep your faith bright.',
      'Invite the Spirit to highlight distractions that drain your oil.',
      'Plan a moment of worship that fills your reserves this week.',
    ],
    challengePrompt: 'Let readiness inform how you meet the task before you today.',
    closingReminder: 'Return to your day attentive, keeping oil in your lamp.',
    openReflection: 'Ask how you can partner with Jesus while you wait for the next door to open.',
    guidanceTips: [
      'Check in with a friend about how they tend their spiritual reserves.',
      'Schedule intentional rest so you do not burn out while waiting.',
    ],
    stageNote: 'Forming resilient expectancy.',
  },
  {
    id: 'vineyard-workers',
    title: 'Working beside the Vineyard Workers',
    parable: 'Parable of the Workers in the Vineyard',
    scripture: 'Matthew 20:1-16',
    overview: 'Spend the day in the vineyard noticing generosity given at every hour.',
    breathInvitation: 'Breathe in gratitude for grace, breathe out comparisons that creep in.',
    reflectionPrompts: [
      'Where do you feel comparison stealing joy from your work?',
      'Ask Jesus how He sees your contribution today.',
      'How can you celebrate others’ gifts without losing sight of your own calling?',
      'What fresh perspective on justice or generosity are you receiving?',
    ],
    focusOptions: [
      'Thank God out loud for someone else’s blessing.',
      'List the ways you have been provided for unexpectedly.',
      'Choose cooperation over competition in one concrete situation.',
    ],
    challengePrompt: 'Let kingdom generosity inform how you approach your challenge.',
    closingReminder: 'Leave the vineyard walking in gratitude instead of comparison.',
    openReflection: 'Notice how grace levels the field for everyone—including you.',
    guidanceTips: [
      'Pause when comparison starts and replace it with a gratitude breath.',
      'Share one story of grace with someone you trust this week.',
    ],
    stageNote: 'Balancing zeal with grace.',
  }
];

const deepPlans: PlanCollection = [
  {
    id: 'treasure-field',
    title: 'Discovering Treasure in the Field',
    parable: 'Parable of the Hidden Treasure',
    scripture: 'Matthew 13:44',
    overview: 'Picture stumbling upon a treasure hidden in a field. Let the discovery reshape your priorities.',
    breathInvitation: 'Breathe deeply as you imagine holding the treasure close.',
    reflectionPrompts: [
      'What part of following Jesus currently feels priceless to you?',
      'Is there anything you sense Him inviting you to release so you can receive more?',
      'How might you protect wonder and gratitude in this next season?',
      'Let the treasure spark joy that you carry into your relationships today.'
    ],
    focusOptions: [
      'Notice how your desires are shifting as you treasure His kingdom.',
      'Imagine sharing the discovery with someone who needs encouragement.',
      'Hold space for mystery and let awe settle in your breathing.'
    ],
    challengePrompt: 'Ask how this treasure changes the way you see your present challenge.',
    closingReminder: 'Return to your routines carrying the quiet joy of what you have found.',
    openReflection: 'Let gratitude rise as you describe the treasure to Jesus.',
    guidanceTips: [
      'Keep a list of sacred moments you do not want to forget.',
      'Share one insight with someone who longs for hope.',
    ],
    stageNote: 'Guarding sacred wonder.',
  },
  {
    id: 'true-vine',
    title: 'Abiding with the True Vine',
    parable: 'Metaphor of the Vine and Branches',
    scripture: 'John 15:1-11',
    overview: 'Feel the life of the Vine flowing into every branch. Notice where pruning has made space for fruit.',
    breathInvitation: 'Inhale abiding presence, exhale anything that keeps you from remaining.',
    reflectionPrompts: [
      'What fruit do you see emerging from previous pruning?',
      'Where do you sense the Father inviting deeper trust?',
      'How can you remain in love when results are still unseen?',
      'Name a practice that helps you stay connected when storms pass through.',
    ],
    focusOptions: [
      'Visualize the sap of His Spirit flowing through you.',
      'Plan a rhythm that keeps abiding central this week.',
      'Invite the Gardener to tend hidden parts of your heart.',
    ],
    challengePrompt: 'Let abiding presence reshape how you face this challenge.',
    closingReminder: 'Return knowing His life continues to bear fruit through you.',
    openReflection: 'Ask what joy looks like as you remain in His love.',
    guidanceTips: [
      'Schedule pockets of silence to listen for the Vine’s whisper.',
      'Share with a trusted friend where you sense pruning happening.',
    ],
    stageNote: 'Sustaining mature abiding.',
  },
  {
    id: 'prodigal-father',
    title: 'Standing with the Restoring Father',
    parable: 'Parable of the Prodigal Son',
    scripture: 'Luke 15:11-32',
    overview: 'Watch the reunion from the Father’s perspective and notice His embrace for both sons.',
    breathInvitation: 'Breathe in welcome, breathe out resentment, allowing the Father’s compassion to steady you.',
    reflectionPrompts: [
      'Where do you identify with each son in this season?',
      'What does mature reconciliation look like in your relationships?',
      'How might celebration and repentance coexist in your story?',
      'Name a way you can extend the Father’s embrace to someone else.',
    ],
    focusOptions: [
      'Imagine the Father running toward you and listen for His words.',
      'Let compassion rise for someone who is still far off.',
      'Commit to one act that reflects the Father’s welcoming heart.',
    ],
    challengePrompt: 'Allow the Father’s mercy to inform how you respond to today’s tension.',
    closingReminder: 'Walk back into your day carrying the robe of His acceptance.',
    openReflection: 'Ask where celebration is needed alongside sober honesty.',
    guidanceTips: [
      'Practice examen in the evening to notice both sons within you.',
      'Invite accountability as you live out reconciled compassion.',
    ],
    stageNote: 'Integrating maturity with mercy.',
  },
  {
    id: 'pearl-merchant',
    title: 'Trading with the Pearl Merchant',
    parable: 'Parable of the Pearl of Great Price',
    scripture: 'Matthew 13:45-46',
    overview: 'Stand with the merchant as he weighs every possession against a single pearl worth everything.',
    breathInvitation: 'Inhale surrender, exhale attachment as you hold the pearl close.',
    reflectionPrompts: [
      'What costly exchange is God inviting you to consider?',
      'How do you discern the difference between sacrifice and striving?',
      'Where have you already seen the value of choosing His kingdom?',
      'What legacy are you preparing through the way you live now?',
    ],
    focusOptions: [
      'List attachments you sense Him loosening in love.',
      'Bless someone who is taking a costly step of obedience.',
      'Rest in the worth of the One you have found.',
    ],
    challengePrompt: 'Let kingdom value guide the decision you face.',
    closingReminder: 'Leave carrying confidence in the treasure you have chosen.',
    openReflection: 'Ask how this pearl is shaping the story you hand to others.',
    guidanceTips: [
      'Engage in a generosity practice that reflects surrendered trust.',
      'Reflect weekly on what you traded and what you received in return.',
    ],
    stageNote: 'Choosing costly obedience with joy.',
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
