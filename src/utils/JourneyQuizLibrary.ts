import { JourneyQuizQuestion } from '@/stores/JourneyStore';

export interface JourneyQuiz {
  id: string;
  title: string;
  description: string;
  questions: JourneyQuizQuestion[];
  passingScore: number; // percentage (0-100)
}

/**
 * Dedicated library for Journey quizzes
 * Contains all quiz data and logic for spiritual journey phases
 */
export class JourneyQuizLibrary {
  private static readonly ACCEPT_JESUS_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'accept-jesus-1',
      prompt: 'Do you accept Jesus died for your sins in order for you to be saved?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'accept-jesus-2',
      prompt: 'Do you pledge to serve and follow Jesus, his teachings/examples to gain life in abundance?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'accept-jesus-3',
      prompt: 'Do you trust in the infinite and ultimate power of God, his divine Justice and his perfect love for all?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'accept-jesus-4',
      prompt: 'Do you renounce the devil and all his works and empty promises?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'accept-jesus-5',
      prompt: 'Do you promise to accept and work with the grace of the Holy Spirit who saves you?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  private static readonly REPENTANCE_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'repentance-1',
      prompt: 'Do you acknowledge that you have sinned and fallen short of God\'s glory?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'repentance-2',
      prompt: 'Do you commit to turning away from sinful behaviors and toward righteous living?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'repentance-3',
      prompt: 'Do you believe that God\'s forgiveness through Jesus Christ is sufficient for your salvation?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'repentance-4',
      prompt: 'Do you commit to regular confession of sins and seeking God\'s forgiveness?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'repentance-5',
      prompt: 'Do you desire to live a life that honors God and reflects His character?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  private static readonly HOLY_SPIRIT_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'holy-spirit-1',
      prompt: 'Do you believe the Holy Spirit is a person of the Trinity, equal to God the Father and Jesus Christ?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'holy-spirit-2',
      prompt: 'Do you desire to be filled with the Holy Spirit and guided by His wisdom?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'holy-spirit-3',
      prompt: 'Do you acknowledge that the Holy Spirit gives spiritual gifts for the edification of the church?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'holy-spirit-4',
      prompt: 'Do you commit to listening to and following the Holy Spirit\'s guidance in your daily life?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'holy-spirit-5',
      prompt: 'Do you believe that the Holy Spirit convicts believers of sin and leads them to righteousness?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  private static readonly FRUIT_BEARING_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'fruit-bearing-1',
      prompt: 'Do you understand that bearing fruit means demonstrating the character of Christ through your actions?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'fruit-bearing-2',
      prompt: 'Do you commit to cultivating the fruit of the Spirit: love, joy, peace, patience, kindness, goodness, faithfulness, gentleness, and self-control?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'fruit-bearing-3',
      prompt: 'Do you recognize that spiritual fruit is evidence of a genuine relationship with Jesus Christ?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'fruit-bearing-4',
      prompt: 'Do you desire to be used by God to produce lasting fruit that brings glory to His name?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'fruit-bearing-5',
      prompt: 'Do you understand that without Christ, you can do nothing of eternal value?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  private static readonly TREASURES_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'treasures-1',
      prompt: 'Do you understand that storing up treasures in heaven means investing in eternal things rather than temporary earthly possessions?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'treasures-2',
      prompt: 'Do you commit to using your resources (time, money, talents) for God\'s kingdom purposes?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'treasures-3',
      prompt: 'Do you recognize that your heart follows where you invest your treasures?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'treasures-4',
      prompt: 'Do you desire to be rich toward God rather than accumulating earthly wealth?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'treasures-5',
      prompt: 'Do you understand that giving to others is like lending to the Lord?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  private static readonly GIVING_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'giving-1',
      prompt: 'Do you understand that giving of yourself means offering your time, talents, and resources sacrificially to others?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'giving-2',
      prompt: 'Do you commit to practicing generosity as a reflection of God\'s generous nature toward you?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'giving-3',
      prompt: 'Do you recognize that cheerful giving brings joy to both the giver and the receiver?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'giving-4',
      prompt: 'Do you desire to excel in the grace of giving as part of your spiritual growth?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'giving-5',
      prompt: 'Do you understand that God loves a cheerful giver?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  private static readonly DIVINE_VISIONS_QUESTIONS: JourneyQuizQuestion[] = [
    {
      id: 'divine-visions-1',
      prompt: 'Do you believe that God has a specific calling and purpose for your life?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'divine-visions-2',
      prompt: 'Do you commit to seeking God\'s vision for your life through prayer and Scripture?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
    {
      id: 'divine-visions-3',
      prompt: 'Do you desire to steward well the gifts and opportunities God has given you?',
      options: ['Yes', 'No'],
      correctIndex: 0,
    },
  ];

  /**
   * Get quiz for a specific journey phase
   */
  static getQuiz(phaseId: string): JourneyQuiz | null {
    const quizMap: Record<string, JourneyQuiz> = {
      'accept-jesus': {
        id: 'accept-jesus',
        title: 'Accepting Jesus',
        description: 'Foundation of faith and commitment to Christ',
        questions: this.ACCEPT_JESUS_QUESTIONS,
        passingScore: 100, // Must answer all correctly to pass
      },
      'repentance': {
        id: 'repentance',
        title: 'Repentance',
        description: 'Turning from sin toward a transformed life',
        questions: this.REPENTANCE_QUESTIONS,
        passingScore: 80,
      },
      'activation-holy-spirit': {
        id: 'activation-holy-spirit',
        title: 'Holy Spirit Activation',
        description: 'Inviting and responding to the Holy Spirit\'s leadership',
        questions: this.HOLY_SPIRIT_QUESTIONS,
        passingScore: 80,
      },
      'bearing-fruits': {
        id: 'bearing-fruits',
        title: 'Bearing Fruits',
        description: 'Demonstrating growth through spiritual fruit',
        questions: this.FRUIT_BEARING_QUESTIONS,
        passingScore: 80,
      },
      'storing-treasures': {
        id: 'storing-treasures',
        title: 'Storing Treasures in Heaven',
        description: 'Investing in eternal impact and kingdom priorities',
        questions: this.TREASURES_QUESTIONS,
        passingScore: 80,
      },
      'giving-of-self': {
        id: 'giving-of-self',
        title: 'Giving of Self',
        description: 'Offering time, talent, and treasure sacrificially',
        questions: this.GIVING_QUESTIONS,
        passingScore: 80,
      },
      'divine-visions': {
        id: 'divine-visions',
        title: 'Divine Visions',
        description: 'Pursuing the fullness of God\'s calling and revelation',
        questions: this.DIVINE_VISIONS_QUESTIONS,
        passingScore: 80,
      },
    };

    return quizMap[phaseId] || null;
  }

  /**
   * Get all available quizzes
   */
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

  /**
   * Validate if a quiz answer is correct
   */
  static validateAnswer(question: JourneyQuizQuestion, selectedIndex: number): boolean {
    return selectedIndex === question.correctIndex;
  }

  /**
   * Calculate quiz score percentage
   */
  static calculateScore(questions: JourneyQuizQuestion[], answers: number[]): number {
    if (questions.length === 0) return 0;

    const correctAnswers = questions.reduce((count, question, index) => {
      return count + (this.validateAnswer(question, answers[index]) ? 1 : 0);
    }, 0);

    return Math.round((correctAnswers / questions.length) * 100);
  }

  /**
   * Check if a quiz is passed based on the passing score
   */
  static isQuizPassed(quiz: JourneyQuiz, score: number): boolean {
    return score >= quiz.passingScore;
  }
}

export default JourneyQuizLibrary;
