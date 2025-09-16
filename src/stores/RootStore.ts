import { authStore } from './AuthStore';
import { meditationStore } from './MeditationStore';
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

export class RootStore {
  authStore = authStore;
  meditationStore = meditationStore;
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
  registrationStore: RegistrationStore;
  bookmarkStore: BookmarkStore;

  constructor() {
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
    this.registrationStore = new RegistrationStore(this.authStore);
    this.bookmarkStore = new BookmarkStore();
  }
}
