import { AuthStore } from './AuthStore';
import { MeditationStore } from './MeditationStore';
import { matchStore } from './MatchStore';
import { preferencesStore } from './PreferencesStore';
import { ReflectionStore } from './ReflectionStore';
import { LeaderboardStore } from './LeaderboardStore';
import { VirtueStore } from './VirtueStore';
import { VerseStore } from './VerseStore';
import { VerseBuilderStore } from './VerseBuilderStore';
import { NotesStore } from './NotesStore';
import { ChallengeStore } from './ChallengeStore';
import { PrayerRequestsStore } from './PrayerRequestsStore';
import { WordHubsStore } from './WordHubsStore';
import { CommunityStore } from './CommunityStore';
import { GameStore } from './GameStore';
import { VirtueQuizStore } from './VirtueQuizStore';
import { RegistrationStore } from './RegistrationStore';
import { BookmarkStore } from './BookmarkStore';
import { JourneyStore } from './JourneyStore';
import { DailyPathStore } from './DailyPathStore';
import { GuideStore } from './GuideStore';
import { FeatureSuggestionsStore } from './FeatureSuggestionsStore';

export class RootStore {
  authStore: AuthStore;
  meditationStore: MeditationStore;
  matchStore = matchStore;
  preferencesStore = preferencesStore;
  reflectionStore: ReflectionStore;
  leaderboardStore: LeaderboardStore;
  virtueStore: VirtueStore;
  verseBuilderStore: VerseBuilderStore;
  verseStore: VerseStore;
  notesStore: NotesStore;
  challengeStore: ChallengeStore;
  prayerRequestsStore: PrayerRequestsStore;
  wordHubsStore: WordHubsStore;
  gameStore: GameStore;
  virtueQuizStore: VirtueQuizStore;
  communityStore: CommunityStore;
  featureSuggestionsStore: FeatureSuggestionsStore;
  registrationStore: RegistrationStore;
  bookmarkStore: BookmarkStore;
  journeyStore: JourneyStore;
  dailyPathStore: DailyPathStore;
  guideStore: GuideStore;

  constructor() {
    this.authStore = new AuthStore();
    this.reflectionStore = new ReflectionStore();
    this.leaderboardStore = new LeaderboardStore();
    this.virtueStore = new VirtueStore();
    this.verseStore = new VerseStore();
    this.notesStore = new NotesStore();
    this.challengeStore = new ChallengeStore();
    this.prayerRequestsStore = new PrayerRequestsStore();
    this.wordHubsStore = new WordHubsStore();
    this.gameStore = new GameStore();
    this.virtueQuizStore = new VirtueQuizStore(this);
    this.verseBuilderStore = new VerseBuilderStore(this.verseStore, this.gameStore);
    this.communityStore = new CommunityStore();
    this.featureSuggestionsStore = new FeatureSuggestionsStore();
    this.registrationStore = new RegistrationStore(this.authStore);
    this.bookmarkStore = new BookmarkStore();
    this.journeyStore = new JourneyStore(this.authStore);
    this.dailyPathStore = new DailyPathStore();
    this.meditationStore = new MeditationStore(this.authStore, this.challengeStore);
    this.guideStore = new GuideStore();
    // Attach cross-store dependencies after all are constructed
    this.virtueStore.attachStores(this.leaderboardStore, this.journeyStore);
  }
}
