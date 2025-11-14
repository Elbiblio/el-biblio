import { RootStackParamList } from '@/types';
import AsyncStorage from '@react-native-async-storage/async-storage';

const GUIDES_ENDPOINT = '/api/guides';

export type GuideMode = 'meditation' | 'interactive_reading_quiz' | 'reading_reflection';

export type GuideRouteName = keyof RootStackParamList;

export interface GuideSummary {
  id: string;
  title: string;
  subtitle: string;
  mode: GuideMode;
  routeName: GuideRouteName;
  ctaLabel: string;
}

export interface MeditationGuideConfig {
  mode: 'meditation';
  minutesShort: number;
  minutesLong: number;
  orchestrationKey: string;
}

export interface InteractiveReadingQuizPage {
  id: string;
  title: string;
  body: string;
}

export interface InteractiveReadingQuizQuestion {
  id: string;
  prompt: string;
  options: string[];
  correctIndex: number;
}

export interface InteractiveReadingQuizConfig {
  mode: 'interactive_reading_quiz';
  pages: InteractiveReadingQuizPage[];
  questions: InteractiveReadingQuizQuestion[];
}

export interface ReadingReflectionSection {
  id: string;
  title: string;
  body: string;
}

export interface ReadingReflectionConfig {
  mode: 'reading_reflection';
  sections: ReadingReflectionSection[];
  reflectionPrompt?: string;
}

export type GuideContentConfig =
  | MeditationGuideConfig
  | InteractiveReadingQuizConfig
  | ReadingReflectionConfig;

export interface GuideDefinition extends GuideSummary {
  content: GuideContentConfig;
}

const GUIDE_CACHE_KEY = 'GUIDE_DEFINITIONS_V2';

const LOCAL_GUIDES: GuideDefinition[] = [
  {
    id: 'how-to-pray',
    title: 'How to Pray',
    subtitle:
      'Walk through a short guide on what it means to talk with God as a child of the Kingdom.',
    mode: 'interactive_reading_quiz',
    routeName: 'HowToPrayScreen',
    ctaLabel: 'How to Pray',
    content: {
      mode: 'interactive_reading_quiz',
      pages: [
        {
          id: 'p1',
          title: 'A world that forges souls',
          body:
            'God made you in His image and placed you in a world that is both a nursery and a forge. Hard days are not proof that He has abandoned you; they are often where love, trust, and patience are formed. Sin is like torn clothes or an open wound, but when you desire to be made clean, the Father draws nearer, not farther away.',
        },
        {
          id: 'p2',
          title: 'Pray with a Kingdom mindset',
          body:
            'Through Jesus, the doors of the Kingdom are opened and your citizenship is unlocked. When you pray “Our Father”, you stand with all God’s children before Him. You seek first His Kingdom, trust Him for daily bread, and refuse to carry grudges into His presence, knowing He sees every situation with perfect justice and mercy.',
        },
        {
          id: 'p3',
          title: 'Talking to your Father each day',
          body:
            'Learning to pray is not learning magic words. It is learning who your Father is and how deeply you need Him. The conscience is a basic compass, but the Holy Spirit is given so that your true Kingdom work and talents can unfold. As you talk to God daily, He teaches you to walk with Him and to bear lasting fruit rather than simply running from sin.',
        },
      ],
      questions: [
        {
          id: 'q1',
          prompt:
            'When you face trials or difficulties, how does this guide invite you to see them?',
          options: [
            'As proof that God has abandoned you',
            'As random bad luck with no meaning',
            'As a loving forging process where God is forming your soul',
            'As punishment with no hope of healing',
          ],
          correctIndex: 2,
        },
        {
          id: 'q2',
          prompt: 'What does praying “Our Father” primarily remind us of?',
          options: [
            'That prayer is mainly about my personal success',
            'That we pray as one family, seeking God’s Kingdom together',
            'That we must impress God with perfect words',
            'That God only listens to very holy people',
          ],
          correctIndex: 1,
        },
        {
          id: 'q3',
          prompt:
            'How does the Holy Spirit help you in daily prayer, according to this guide?',
          options: [
            'By forcing you to obey without freedom',
            'By removing all suffering immediately',
            'By gently illuminating your path and helping you live your true Kingdom calling',
            'By making sure you never make another mistake',
          ],
          correctIndex: 2,
        },
      ],
    },
  },
  {
    id: 'forgiveness',
    title: 'Forgiveness',
    subtitle:
      'Move through reflection, prayer for forgiveness, and penitence with gentle prompts and scripture.',
    mode: 'meditation',
    routeName: 'ForgivenessScreen',
    ctaLabel: 'Forgiveness',
    content: {
      mode: 'meditation',
      minutesShort: 10,
      minutesLong: 20,
      orchestrationKey: 'forgiveness-default',
    },
  },
  {
    id: 'holy-spirit',
    title: 'Holy Spirit',
    subtitle:
      'Read a short teaching on the Holy Spirit and end with simple prompts for reflection and response.',
    mode: 'reading_reflection',
    routeName: 'HolySpiritScreen',
    ctaLabel: 'Holy Spirit',
    content: {
      mode: 'reading_reflection',
      sections: [
        {
          id: 'hs1',
          title: 'God with us, within us',
          body:
            'The prophets longed for the day when God would dwell with His people. In Christ, that day has come, and through the Holy Spirit, God now lives in you. The Spirit reveals God’s plan step by step and helps you trust Him in every season.',
        },
      ],
      reflectionPrompt:
        'Where do you most need to invite the Holy Spirit today – in your fears, your relationships, or your work in the Kingdom?',
    },
  },
  {
    id: 'career-discovery',
    title: 'Career Discovery',
    subtitle:
      'Explore how your spiritual gifts and everyday work fit into the Kingdom story.',
    mode: 'reading_reflection',
    routeName: 'CareerDiscoveryScreen',
    ctaLabel: 'Career Discovery',
    content: {
      mode: 'reading_reflection',
      sections: [
        {
          id: 'cd1',
          title: 'Your true career is spiritual',
          body:
            'Before any earthly job title, you are a child of God and a citizen of His Kingdom. The same Holy Spirit who raised Jesus from the dead lives in you and manifests differently in each person. Your calling is bigger than any role in a fallen world.',
        },
        {
          id: 'cd2',
          title: 'Co‑creating with God',
          body:
            'In the Kingdom, every vocation is ultimately about co‑creating with God – bringing forth justice, beauty, healing, and wisdom. Some do this directly through ministry, others through work, family, or craft, but all true careers share the same foundation: partnering with God to bring His Kingdom near.',
        },
      ],
      reflectionPrompt:
        'Ask the Lord to show you how your story, history, and gifts might point to the spiritual career He is shaping in you.',
    },
  },
];

async function fetchGuidesFromApi(): Promise<GuideDefinition[] | null> {
  try {
    const response = await fetch(GUIDES_ENDPOINT);
    if (!response.ok) {
      return null;
    }
    const data = (await response.json()) as unknown;
    if (!Array.isArray(data)) {
      return null;
    }
    return data as GuideDefinition[];
  } catch {
    return null;
  }
}

async function loadCachedGuides(): Promise<GuideDefinition[] | null> {
  try {
    const raw = await AsyncStorage.getItem(GUIDE_CACHE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as GuideDefinition[];
    if (!Array.isArray(parsed)) return null;
    return parsed;
  } catch {
    return null;
  }
}

async function saveCachedGuides(guides: GuideDefinition[]): Promise<void> {
  try {
    await AsyncStorage.setItem(GUIDE_CACHE_KEY, JSON.stringify(guides));
  } catch {
    // ignore
  }
}

async function resolveGuides(): Promise<GuideDefinition[]> {
  const apiGuides = await fetchGuidesFromApi();
  if (apiGuides && apiGuides.length > 0) {
    await saveCachedGuides(apiGuides);
    return apiGuides;
  }

  const cachedGuides = await loadCachedGuides();
  if (cachedGuides && cachedGuides.length > 0) {
    return cachedGuides;
  }

  await saveCachedGuides(LOCAL_GUIDES);
  return LOCAL_GUIDES;
}

export async function getGuides(): Promise<GuideSummary[]> {
  const guides = await resolveGuides();
  return guides.map(({ content, ...summary }) => summary);
}

export async function getGuideById(id: string): Promise<GuideDefinition | null> {
  const guides = await resolveGuides();
  const found = guides.find(guide => guide.id === id);
  return found || null;
}
