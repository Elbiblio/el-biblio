export type MeditationLevel = 'foundation' | 'growth' | 'deep';

export type RosaryMysteryType = 'joyful' | 'luminous' | 'sorrowful' | 'glorious';

export interface RosaryMystery {
  id: string;
  title: string;
  scripture: string;
  overview: string;
  meditationFocus: string[];
  prayerIntentions: string[];
  mysteryType: RosaryMysteryType;
  order: number;
}

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

// Rosary Mysteries Collections - Bible-focused meditation
const joyfulMysteries: RosaryMystery[] = [
  {
    id: 'annunciation',
    title: 'The Annunciation',
    scripture: 'Luke 1:26-38',
    overview: 'The angel Gabriel announces to Mary that she will give birth to Jesus, the Son of God.',
    meditationFocus: [
      'God\'s messenger bringing good news',
      'Mary\'s willing response to God\'s call',
      'The promise of God\'s presence among us',
      'Faith responding to divine revelation'
    ],
    prayerIntentions: [
      'For openness to God\'s messages in our lives',
      'For courage to say yes to God\'s calling',
      'For awareness of God working in our world',
      'For trust in God\'s promises and timing'
    ],
    mysteryType: 'joyful',
    order: 1,
  },
  {
    id: 'visitation',
    title: 'The Visitation',
    scripture: 'Luke 1:39-56',
    overview: 'Mary visits Elizabeth, and both women recognize God\'s work in their lives through the power of the Holy Spirit.',
    meditationFocus: [
      'Sharing joy in God\'s blessings',
      'The Holy Spirit\'s work in people\'s lives',
      'Celebrating God\'s goodness together',
      'Recognizing God\'s hand in everyday moments'
    ],
    prayerIntentions: [
      'For sharing our faith experiences with others',
      'For seeing God at work in people around us',
      'For building supportive faith communities',
      'For gratitude for God\'s blessings in our lives'
    ],
    mysteryType: 'joyful',
    order: 2,
  },
  {
    id: 'nativity',
    title: 'The Nativity',
    scripture: 'Luke 2:1-20',
    overview: 'Jesus is born in Bethlehem, and angels announce this good news to shepherds watching their flocks.',
    meditationFocus: [
      'God entering human history in humility',
      'Heavenly messengers declaring good news',
      'The wonder of new life and new beginnings',
      'God meeting us in our ordinary circumstances'
    ],
    prayerIntentions: [
      'For wonder at God\'s presence in our world',
      'For openness to hearing God\'s messages',
      'For gratitude for new beginnings and fresh starts',
      'For finding God in our everyday lives'
    ],
    mysteryType: 'joyful',
    order: 3,
  },
  {
    id: 'presentation',
    title: 'The Presentation',
    scripture: 'Luke 2:22-40',
    overview: 'Mary and Joseph present Jesus in the Temple, where Simeon and Anna recognize Him as the fulfillment of God\'s promises.',
    meditationFocus: [
      'Dedicating our lives and families to God',
      'Recognizing God\'s fulfillment of promises',
      'Wisdom that comes with age and experience',
      'The peace of knowing God\'s purposes'
    ],
    prayerIntentions: [
      'For dedication to following God\'s ways',
      'For eyes to see God\'s faithfulness in our lives',
      'For wisdom and discernment in daily decisions',
      'For peace in trusting God\'s timing and purposes'
    ],
    mysteryType: 'joyful',
    order: 4,
  },
  {
    id: 'finding-temple',
    title: 'Finding Jesus in the Temple',
    scripture: 'Luke 2:41-52',
    overview: 'Mary and Joseph find Jesus in the Temple discussing God\'s truth with the religious teachers.',
    meditationFocus: [
      'Growing in understanding of God\'s ways',
      'The importance of learning and wisdom',
      'Being in the right place to encounter God',
      'The natural process of spiritual growth'
    ],
    prayerIntentions: [
      'For growth in understanding God\'s truth',
      'For wisdom in studying and learning',
      'For finding God in places of worship and study',
      'For patience in the process of spiritual growth'
    ],
    mysteryType: 'joyful',
    order: 5,
  }
];

const luminousMysteries: RosaryMystery[] = [
  {
    id: 'baptism-jordan',
    title: 'The Baptism in the Jordan',
    scripture: 'Matthew 3:13-17',
    overview: 'Jesus is baptized by John in the Jordan River, and God\'s voice affirms Jesus as His beloved Son.',
    meditationFocus: [
      'The importance of baptism and new beginnings',
      'God\'s affirmation and love for His children',
      'The presence of the Holy Spirit in our lives',
      'Jesus\' example of humility and obedience'
    ],
    prayerIntentions: [
      'For understanding the meaning of baptism',
      'For awareness of God\'s love and affirmation',
      'For openness to the Holy Spirit\'s guidance',
      'For humility in following Jesus\' example'
    ],
    mysteryType: 'luminous',
    order: 1,
  },
  {
    id: 'wedding-cana',
    title: 'The Wedding at Cana',
    scripture: 'John 2:1-11',
    overview: 'Jesus performs His first miracle at a wedding, turning water into wine when the need arises.',
    meditationFocus: [
      'Jesus\' compassion for human needs and celebrations',
      'The abundance of God\'s grace and provision',
      'The role of prayer in times of need',
      'God\'s timing and unexpected provision'
    ],
    prayerIntentions: [
      'For compassion toward others\' needs and celebrations',
      'For trust in God\'s abundant provision',
      'For faithful prayer in times of need',
      'For patience in waiting for God\'s timing'
    ],
    mysteryType: 'luminous',
    order: 2,
  },
  {
    id: 'proclamation-kingdom',
    title: 'The Proclamation of the Kingdom',
    scripture: 'Mark 1:14-15',
    overview: 'Jesus begins His public ministry, announcing that God\'s kingdom is near and calling people to turn to God.',
    meditationFocus: [
      'The good news that God\'s kingdom is available to all',
      'The call to turn toward God and new life',
      'The nearness of God\'s presence and power',
      'Jesus\' authority to forgive and heal'
    ],
    prayerIntentions: [
      'For sharing the good news of God\'s kingdom',
      'For willingness to turn toward God',
      'For awareness of God\'s presence in our lives',
      'For trust in Jesus\' authority and power'
    ],
    mysteryType: 'luminous',
    order: 3,
  },
  {
    id: 'transfiguration',
    title: 'The Transfiguration',
    scripture: 'Matthew 17:1-9',
    overview: 'Jesus is revealed in divine glory before Peter, James, and John, showing His true nature as God\'s Son.',
    meditationFocus: [
      'The reality of Jesus\' divine nature',
      'The importance of prayer and sacred moments',
      'God\'s affirmation of Jesus\' mission',
      'The glimpse of heavenly reality breaking into earth'
    ],
    prayerIntentions: [
      'For deeper understanding of who Jesus is',
      'For meaningful times of prayer and reflection',
      'For confidence in God\'s purposes',
      'For hope in the reality beyond what we see'
    ],
    mysteryType: 'luminous',
    order: 4,
  },
  {
    id: 'eucharist',
    title: 'The Last Supper',
    scripture: 'Matthew 26:26-30',
    overview: 'Jesus shares a final meal with His disciples and institutes a memorial of His sacrifice.',
    meditationFocus: [
      'The importance of remembering Jesus\' sacrifice',
      'The call to love and serve one another',
      'The promise of Jesus\' ongoing presence',
      'The unity found in shared faith and fellowship'
    ],
    prayerIntentions: [
      'For gratitude for Jesus\' sacrifice',
      'For love and service toward others',
      'For awareness of Jesus\' presence in our lives',
      'For unity in faith and fellowship'
    ],
    mysteryType: 'luminous',
    order: 5,
  }
];

const sorrowfulMysteries: RosaryMystery[] = [
  {
    id: 'agony-garden',
    title: 'The Agony in the Garden',
    scripture: 'Matthew 26:36-46',
    overview: 'Jesus prays in deep distress in the Garden of Gethsemane, accepting God\'s will even in suffering.',
    meditationFocus: [
      'The reality of human suffering and prayer',
      'Trusting God even when facing hardship',
      'The importance of prayer in difficult times',
      'Finding strength through surrender to God'
    ],
    prayerIntentions: [
      'For comfort in times of suffering and distress',
      'For trust in God during difficult circumstances',
      'For faithfulness in prayer during trials',
      'For strength to accept God\'s will'
    ],
    mysteryType: 'sorrowful',
    order: 1,
  },
  {
    id: 'scourging',
    title: 'The Scourging',
    scripture: 'Matthew 27:26',
    overview: 'Jesus endures physical suffering and injustice at the hands of those in authority.',
    meditationFocus: [
      'The reality of injustice and suffering in our world',
      'Jesus\' willingness to endure pain for others',
      'The strength found in trusting God through injustice',
      'God\'s presence even in the midst of cruelty'
    ],
    prayerIntentions: [
      'For those suffering injustice and persecution',
      'For strength to endure hardship for what is right',
      'For trust in God during times of suffering',
      'For compassion toward those who are hurting'
    ],
    mysteryType: 'sorrowful',
    order: 2,
  },
  {
    id: 'crowning-thorns',
    title: 'The Crowning with Thorns',
    scripture: 'Matthew 27:27-31',
    overview: 'Jesus is mocked and humiliated by soldiers who crown Him with thorns and ridicule His kingship.',
    meditationFocus: [
      'The pain of rejection and humiliation',
      'The contrast between earthly and heavenly power',
      'Finding dignity in the midst of mockery',
      'God\'s strength in moments of human weakness'
    ],
    prayerIntentions: [
      'For comfort when facing rejection or ridicule',
      'For understanding true strength and power',
      'For dignity in the face of humiliation',
      'For inner strength during times of weakness'
    ],
    mysteryType: 'sorrowful',
    order: 3,
  },
  {
    id: 'carrying-cross',
    title: 'The Carrying of the Cross',
    scripture: 'Matthew 27:32',
    overview: 'Jesus carries His cross through the streets, showing determination even under the weight of suffering.',
    meditationFocus: [
      'The weight of burdens we carry in life',
      'Finding help and support in times of need',
      'Perseverance through difficult circumstances',
      'The journey toward hope despite hardship'
    ],
    prayerIntentions: [
      'For strength to carry life\'s burdens',
      'For openness to receive help from others',
      'For perseverance during difficult times',
      'For hope in the midst of hardship'
    ],
    mysteryType: 'sorrowful',
    order: 4,
  },
  {
    id: 'crucifixion',
    title: 'The Crucifixion',
    scripture: 'Matthew 27:33-50',
    overview: 'Jesus is crucified, offering forgiveness to His persecutors and completing His mission of love.',
    meditationFocus: [
      'The depth of love that endures suffering',
      'The power of forgiveness even toward enemies',
      'Completing our calling despite opposition',
      'Finding meaning in sacrifice and surrender'
    ],
    prayerIntentions: [
      'For the ability to love even those who hurt us',
      'For the grace to forgive our enemies',
      'For faithfulness to our calling',
      'For understanding the meaning of sacrifice'
    ],
    mysteryType: 'sorrowful',
    order: 5,
  }
];

const gloriousMysteries: RosaryMystery[] = [
  {
    id: 'resurrection',
    title: 'The Resurrection',
    scripture: 'Matthew 28:1-10',
    overview: 'Jesus rises from death, conquering the power of sin and death and bringing hope of new life.',
    meditationFocus: [
      'The power of God to overcome death',
      'The hope of new life and new beginnings',
      'The empty tomb as a sign of victory',
      'The transformation possible through faith'
    ],
    prayerIntentions: [
      'For faith in God\'s power over death',
      'For hope in new beginnings and fresh starts',
      'For victory over sin and brokenness',
      'For transformation in our lives through faith'
    ],
    mysteryType: 'glorious',
    order: 1,
  },
  {
    id: 'ascension',
    title: 'The Ascension',
    scripture: 'Acts 1:6-11',
    overview: 'Jesus returns to heaven, promising to send the Holy Spirit and prepare a place for His followers.',
    meditationFocus: [
      'Jesus\' return to His heavenly home',
      'The promise of the Holy Spirit\'s presence',
      'Our eternal destiny and hope',
      'Jesus\' ongoing work on our behalf'
    ],
    prayerIntentions: [
      'For trust in Jesus\' heavenly work',
      'For openness to the Holy Spirit\'s guidance',
      'For hope in our eternal home',
      'For awareness of Jesus\' ongoing presence'
    ],
    mysteryType: 'glorious',
    order: 2,
  },
  {
    id: 'pentecost',
    title: 'The Coming of the Holy Spirit',
    scripture: 'Acts 2:1-13',
    overview: 'The Holy Spirit descends on Jesus\' followers, empowering them to share God\'s message with people from all nations.',
    meditationFocus: [
      'The gift and power of the Holy Spirit',
      'The call to share faith with others',
      'Unity despite differences and diversity',
      'The birth and growth of faith communities'
    ],
    prayerIntentions: [
      'For the Holy Spirit\'s gifts and power in our lives',
      'For courage to share our faith with others',
      'For unity and understanding among diverse people',
      'For the growth of faith communities'
    ],
    mysteryType: 'glorious',
    order: 3,
  },
  {
    id: 'assumption',
    title: 'Mary, the new ark of the covenant',
    scripture: 'Luke 1:28, Luke 1:39-56, Rev 11:19-12:1',
    overview: 'Mary was a living vessel that carried the living God and thus the new ark of the covenant. Such grace preserved her from sin and bodily decay.',
    meditationFocus: [
      'The hope of eternal life with God',
      'The abundant compassion, love and mercy of God',
      'The peace of knowing God\'s eternal purposes'
    ],
    prayerIntentions: [
      'For faithfulness in our daily living',
      'For hope in eternal life with God',
      'For lives that bring honor to God',
      'For peace in trusting God\'s eternal plans'
    ],
    mysteryType: 'glorious',
    order: 4,
  },
  {
    id: 'coronation',
    title: 'Mary crowned in Heaven',
    scripture: 'Based on Revelation 12:1 and Psalm 45:9',
    overview: 'Mary is honored in heaven for her faithful response to God\'s calling and her role in God\'s plan.',
    meditationFocus: [
      'The honor given to faithful servants',
      'The importance of our response to God\'s call',
      'The communion of believers across time',
      'The maternal care God provides through faithful people'
    ],
    prayerIntentions: [
      'For faithfulness in responding to God\'s call',
      'For honor and recognition of faithful living',
      'For connection with believers throughout history',
      'For God\'s caring guidance in our lives'
    ],
    mysteryType: 'glorious',
    order: 5,
  }
];

// Helper function to get rosary mysteries by type
export const getRosaryMysteries = (type: RosaryMysteryType): RosaryMystery[] => {
  switch (type) {
    case 'joyful': return joyfulMysteries;
    case 'luminous': return luminousMysteries;
    case 'sorrowful': return sorrowfulMysteries;
    case 'glorious': return gloriousMysteries;
    default: return [];
  }
};

// Helper function to get a specific mystery by ID
export const getRosaryMystery = (id: string): RosaryMystery | undefined => {
  return [
    ...joyfulMysteries,
    ...luminousMysteries,
    ...sorrowfulMysteries,
    ...gloriousMysteries
  ].find(mystery => mystery.id === id);
};

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
