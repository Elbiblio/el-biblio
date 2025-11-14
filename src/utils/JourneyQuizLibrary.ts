import { JourneyQuizQuestion } from '@/stores/JourneyStore';

export interface JourneyQuiz {
  id: string;
  title: string;
  description: string;
  questions: JourneyQuizQuestion[];
  passingScore: number;
}

export class JourneyQuizLibrary {
  // 1️⃣ ACCEPTING JESUS — Spiritual Birth
  private static readonly ACCEPT_JESUS_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'accept-jesus-1',
      prompt: 'Do you accept Jesus died for your sins in order for you to be saved?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'accept-jesus-2',
      prompt: "Has your acceptance of Jesus brought you trust in the power of God's love, his ultimate power, his perfect justice, and his infinite mercy?",
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'accept-jesus-3',
      prompt: 'Sin could be likened to a spiritual disease, like wounds and rot attract bacteria, decay and death (James 1:14-15). Do you promise to avoid sin through God\'s grace? (1 John 3:9, 2 Tim 2:22)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'accept-jesus-4',
      prompt: 'Jesus came that we may have life in abundance. Do you promise to follow his teachings in your daily life? (Luke 6:46)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'accept-jesus-5',
      prompt: 'Do you promise to accept and work with the grace of the Holy Spirit in your daily life?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  // 2️⃣ REPENTANCE — Deep Purification
  private static readonly REPENTANCE_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'repentance-1',
      prompt: 'Do you experience genuine sorrow for sin because it grieves God, not merely guilt? (2 Corinthians 7:10)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'repentance-2',
      prompt: 'Has your repentance led to visible transformation in your speech, relationships, and habits? (Matthew 3:8)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'repentance-3',
      prompt: 'Do you invite the Holy Spirit to expose hidden motives and attitudes that oppose God’s will in your life? (Psalm 139:23–24)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'repentance-4',
      prompt: 'Do you freely forgive others as evidence that you yourself have received God’s mercy? (Matthew 6:14–15)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'repentance-5',
      prompt: 'Do you live with a tender conscience, quick to turn back to God when you stumble? (1 John 1:9)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'repentance-6',
      prompt: 'Do you rejoice in discipline, knowing it produces holiness and endurance? (Hebrews 12:10–11)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'repentance-7',
      prompt: 'Has your repentance drawn you closer to humility rather than self-righteousness? (Luke 18:13–14)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'repentance-8',
      prompt: 'Do you view repentance as a daily renewing of your mind, not a one-time act? (Romans 12:2)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'repentance-9',
      prompt: 'Do you recognize God’s correction as a sign of His love and fatherhood? (Revelation 3:19)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'repentance-10',
      prompt: 'Do you live in ongoing awareness that apart from grace, no good dwells in you? (Romans 7:18)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  // 3️⃣ HOLY SPIRIT ACTIVATION — Divine Empowerment
  private static readonly HOLY_SPIRIT_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'holy-spirit-1',
      prompt: 'Do you discern the Holy Spirit’s voice more clearly than before, especially in times of decision? (John 16:13)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'holy-spirit-2',
      prompt: 'Have you experienced moments when divine peace or conviction replaced confusion instantly? (Philippians 4:7)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'holy-spirit-3',
      prompt: 'Do you see your weaknesses as channels for the Holy Spirit’s strength? (2 Corinthians 12:9)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'holy-spirit-4',
      prompt: 'Are you aware of spiritual gifts operating through you to bless others? (1 Corinthians 12:7)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'holy-spirit-5',
      prompt: 'Do you consciously yield your emotions and impulses to the Spirit’s control daily? (Galatians 5:16)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'holy-spirit-6',
      prompt: 'Do you sense deeper love and burden for others’ salvation as the Spirit transforms your heart? (Romans 9:2–3)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'holy-spirit-7',
      prompt: 'Do you test every spirit and inner impulse by the truth of Scripture before acting? (1 John 4:1)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'holy-spirit-8',
      prompt: 'Do you notice divine timing or providence guiding your circumstances toward kingdom outcomes? (Romans 8:14)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'holy-spirit-9',
      prompt: 'Have you experienced the Spirit producing joy and endurance even in prolonged trials? (James 1:2–4)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'holy-spirit-10',
      prompt: 'Do you live in daily awareness that your body and mind are God’s temple? (1 Corinthians 6:19–20)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  // 4️⃣ BEARING FRUITS — Visible Transformation
  private static readonly FRUIT_BEARING_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'fruit-bearing-1',
      prompt: 'Do others now recognize the character of Christ in your responses and lifestyle? (Matthew 7:20)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'fruit-bearing-2',
      prompt: 'Do you see the fruit of the Spirit forming naturally through grace rather than self-effort? (Galatians 5:22–23)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'fruit-bearing-3',
      prompt: 'Do you remain peaceful and forgiving when wronged, reflecting the maturity of Christ? (Luke 23:34)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'fruit-bearing-4',
      prompt: 'Has your speech become more gracious, truthful, and Spirit-led? (Colossians 4:6)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'fruit-bearing-5',
      prompt: 'Do you find joy in serving quietly, unseen by men but known by God? (Matthew 6:4)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  // 5️⃣ STORING TREASURES IN HEAVEN — Detachment from Earthly Attachments
  private static readonly TREASURES_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'treasures-1',
      prompt: 'Do you view wealth and success as tools for God’s purposes, not personal security? (Matthew 6:19–21)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'treasures-2',
      prompt: 'Have you learned to give generously and secretly, trusting God to provide your needs? (Matthew 6:3–4)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'treasures-3',
      prompt: 'Do you find joy in giving rather than accumulating possessions? (Acts 20:35)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'treasures-4',
      prompt: 'Do you consciously invest time in things of eternal value — love, mercy, souls? (Colossians 3:2)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'treasures-5',
      prompt: 'Do you feel liberated from anxiety over material needs, trusting God’s daily provision? (Matthew 6:33–34)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  // 6️⃣ GIVING OF SELF — Complete Surrender
  private static readonly GIVING_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'giving-1',
      prompt: 'Do you see your body, time, and possessions as belonging wholly to God? (Romans 12:1)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'giving-2',
      prompt: 'Are you willing to obey even when it costs your comfort, plans, or reputation? (Luke 14:33)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'giving-3',
      prompt: 'Do you find fulfillment in sacrifice rather than recognition? (Philippians 2:3–4)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'giving-4',
      prompt: 'Have you surrendered personal ambition to serve God’s purpose through your life and suffering? (Galatians 2:20)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'giving-5',
      prompt: 'Could you release everything you own if Christ asked you, like the rich young ruler was called to? (Matthew 19:21)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  // 7️⃣ DIVINE VISIONS — Union with God
  private static readonly DIVINE_VISIONS_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'divine-visions-1',
      prompt: 'Do you perceive the world, people, and events through the mind and compassion of Christ? (1 Corinthians 2:16)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'divine-visions-2',
      prompt: 'Have you experienced moments where God revealed His heart, will, or plans beyond yourself — for others or nations? (Amos 3:7)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'divine-visions-3',
      prompt: 'Do you live in a state of continual communion where your will aligns naturally with God’s — a shared heart and purpose? (John 17:21–23)',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  // --- QUIZ MAP (SEQUENTIAL PROGRESSION) ---
  static getQuiz(phaseId: string): JourneyQuiz | null {
    const map: Record<string, JourneyQuiz> = {
      'accept-jesus': {
        id: 'accept-jesus',
        title: 'Accepting Jesus',
        description: 'New birth through faith and the surrender that makes Christ your life.',
        questions: this.ACCEPT_JESUS_QUESTIONS,
        passingScore: 80,
      },
      repentance: {
        id: 'repentance',
        title: 'Repentance',
        description: 'Purification and renewal of the heart that leads to lasting transformation.',
        questions: this.REPENTANCE_QUESTIONS,
        passingScore: 80,
      },
      'activation-holy-spirit': {
        id: 'activation-holy-spirit',
        title: 'Holy Spirit Activation',
        description: 'Walking in divine awareness and empowerment through the indwelling Spirit.',
        questions: this.HOLY_SPIRIT_QUESTIONS,
        passingScore: 80,
      },
      'bearing-fruits': {
        id: 'bearing-fruits',
        title: 'Bearing Fruits',
        description: 'Living proof of inner renewal through the visible fruit of divine character.',
        questions: this.FRUIT_BEARING_QUESTIONS,
        passingScore: 80,
      },
      'storing-treasures': {
        id: 'storing-treasures',
        title: 'Storing Treasures in Heaven',
        description: 'Reorienting values from temporal to eternal through generosity and trust.',
        questions: this.TREASURES_QUESTIONS,
        passingScore: 80,
      },
      'giving-of-self': {
        id: 'giving-of-self',
        title: 'Giving of Self',
        description: 'The ultimate surrender — your life, body, and ambitions wholly offered to God.',
        questions: this.GIVING_QUESTIONS,
        passingScore: 80,
      },
      'divine-visions': {
        id: 'divine-visions',
        title: 'Divine Visions',
        description: 'Union with God — perceiving and partaking in His eternal counsel and purposes.',
        questions: this.DIVINE_VISIONS_QUESTIONS,
        passingScore: 80,
      },
    };

    return map[phaseId] || null;
  }

  static getAllQuizzes(): JourneyQuiz[] {
    return [
      this.getQuiz('accept-jesus')!,
      this.getQuiz('repentance')!,
      this.getQuiz('activation-holy-spirit')!,
      this.getQuiz('bearing-fruits')!,
      this.getQuiz('storing-treasures')!,
      this.getQuiz('giving-of-self')!,
      this.getQuiz('divine-visions')!,
    ].filter(Boolean);
  }
}

export default JourneyQuizLibrary;
