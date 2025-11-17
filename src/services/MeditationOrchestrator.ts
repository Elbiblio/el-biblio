import { buildMeditationPlan, contemplativePractices } from '@/data/meditationPlans';
import { speak, readScriptureSlowly, queueSpeak, clearSpeechQueue } from '@/services/AudioCoordinator';
import { AudioCoordinator } from '@/services/AudioCoordinator';
import { getChantById } from '@/data/chantTracks';
import { playCue, playMusic, stopMusic, setMusicVolume } from '@/services/audio';

type Challenge = { title: string; description: string } | null;

type GetConfig = () => {
  selectedStyle: 'parable' | 'virtue' | 'centering' | 'jesus_prayer' | 'chant';
  promptInterval: number;
  totalMeditationSeconds: number;
  selectedChallenge: Challenge;
  centeringWord: string | null;
  centeringReadMode: 'silent' | 'aloud';
  centeringRepeatIntervalSec: number;
  chosenChantId?: string | null;
  chantReflectionPauseSec?: number;
  parableReadMode?: 'silent' | 'aloud';
  sessionCount?: number;
  selectedMinutes?: number | null;
  virtueName?: string | null;
  jesusPrayerPace?: 'slow' | 'medium' | 'fast';
  selectedBackgroundSound?: 'ambient' | 'heartbeat' | null;
};

type OrchestratorCallbacks = {
  showPrompt?: (index: number) => void;
  onComplete: () => void;
  onTick?: (elapsedSeconds: number, ratio: number) => void;
  onGuide?: (guide: MeditationGuide) => void;
  onCountdownTick?: (n: number) => void;
  onBreathPhase?: (phase: 'in' | 'hold' | 'out', durationMs: number) => void;
  onIntroComplete?: () => void;
};

type OrchestratorOptions = {
  getConfig: GetConfig;
  callbacks: OrchestratorCallbacks;
};

const BREATH_DURATIONS = {
  slow: { in: 5200, hold: 3000, out: 6000 },
  medium: { in: 4000, hold: 2000, out: 4800 },
  fast: { in: 2800, hold: 1500, out: 3200 },
} as const;

/**
 * MeditationOrchestrator manages the entire meditation session lifecycle with optimized performance
 */
export class MeditationOrchestrator {
  private getConfig: OrchestratorOptions['getConfig'];
  private callbacks: OrchestratorCallbacks;
  private sessionCfg: ReturnType<GetConfig> | null = null;

  // Timers - consolidated
  private mainInterval: number | null = null;
  private countdownInterval: number | null = null;
  private centeringInterval: number | null = null;
  private breathTimeout: number | null = null;

  // State flags
  private started = false;
  private paused = false;
  private introDone = false;
  private sessionCompleted = false;
  private challengeSpoken = false;
  private finalCountdownStarted = false;

  // Session tracking
  private activeStartMs: number = 0;
  private accumulatedMs: number = 0;
  private lastEmittedSecond: number = -1;
  private lastPromptIndex = -1;
  private spokenPrompts = new Set<number>();
  private breathCycleCount: number = 0;
  private stages = { s1: false, s2: false };
  private lastBellMs: number = 0;
  private chantFinalPromptSpoken: boolean = false;
  private parableNearEndPromptSpoken: boolean = false;
  private closingStarted: boolean = false;

  private currentGuide: MeditationGuide | null = null;
  private chantCoordinator: AudioCoordinator | null = null;
  private lastStartAt: number = 0;
  private bgActive: boolean = false;
  private chantFadedOut: boolean = false;
  private finalCountdownTimer: number | null = null;
  private closingWatchdogTimer: number | null = null;

  constructor(opts: OrchestratorOptions) {
    this.getConfig = opts.getConfig;
    this.callbacks = opts.callbacks;
  }

  private estimateSpeechSeconds(text: string, rate = 0.85) {
    const words = (text || '').trim().split(/\s+/).filter(Boolean).length;
    const wordsPerSecondAtRate1 = 2.0; // ~120 wpm conservative for contemplative pace
    const wps = Math.max(0.8, wordsPerSecondAtRate1 * rate);
    return words > 0 ? words / wps : 0;
  }

  private getClosingLeadSeconds(style: 'parable' | 'virtue' | 'centering' | 'jesus_prayer' | 'chant', challenge: Challenge | null) {
    const rate = style === 'parable' ? 0.72 : 0.85;
    const betweenPause = 0.6;
    const initialDelay = 0.5; // setTimeout used in challenge announcement
    let challengeSeconds = 0;
    if (challenge) {
      challengeSeconds = this.estimateSpeechSeconds('Your challenge is:', rate)
        + betweenPause
        + this.estimateSpeechSeconds(challenge.title || '', rate)
        + betweenPause
        + this.estimateSpeechSeconds(challenge.description || '', rate)
        + initialDelay;
    }
    const countdown = 3;
    const outro = 1.4; // 'Open your eyes'
    const buffer = 1.0;
    const lead = Math.ceil(challengeSeconds + countdown + outro + buffer);
    return Math.min(30, Math.max(7, lead));
  }

  private logDebug(...args: any[]) {
    if ((typeof __DEV__ !== 'undefined' && __DEV__) || (typeof process !== 'undefined' && process.env?.NODE_ENV === 'development')) {
      // eslint-disable-next-line no-console
      console.log('[MeditationOrchestrator]', ...args);
    }
  }

  private timeLeftSeconds(): number {
    const cfg = this.cfg();
    const now = Date.now();
    const elapsedMs = this.accumulatedMs + (this.activeStartMs ? (now - this.activeStartMs) : 0);
    const t = Math.max(0, Math.floor(elapsedMs / 1000));
    return Math.max(0, (cfg.totalMeditationSeconds || 0) - t);
  }

  // ----- PUBLIC METHODS -----

  start() {
    const now = Date.now();
    if (this.started) return;
    if (now - this.lastStartAt < 300) return;
    this.lastStartAt = now;
    this.started = true;
    this.reset();

    const cfg = this.getConfig();
    this.sessionCfg = { ...cfg };

    // Start background audio for non-chant modes
    if (cfg.selectedStyle !== 'chant') {
      this.startBackgroundAudio();
    }
    // Initialize chant coordinator for chant mode
    if (cfg.selectedStyle === 'chant') {
      const track = getChantById(cfg.chosenChantId || null);
      if (track) {
        if (!this.chantCoordinator) {
          this.chantCoordinator = new AudioCoordinator({
            voiceKey: track.voiceKey as any,
            instrumentalKey: track.instrumentalKey as any,
            cues: track.cues,
            pauseDurationMs: track.pauseDurationMs,
            getTimeLeftSeconds: () => this.timeLeftSeconds(),
            minSecondsToStartNextLoop: 72,
            finalFadeOutThresholdSec: 60,
            decayPerLoop: 0.94,
          });
        }
        this.chantCoordinator.preload().then(() => {
          if (this.started && !this.paused) {
            this.chantCoordinator?.start().catch(() => {});
          }
        }).catch(() => {});
      }
    }

    // Build and emit guide
    this.buildAndEmitGuide();

    // Start main tick loop
    this.activeStartMs = Date.now();
    this.mainInterval = setInterval(() => this.tick(), 1000) as unknown as number;
    this.scheduleClosingWatchdog();

    // Run intro sequence
    this.runIntro().catch(() => {});
  }

  startCountdown(startFrom = 5) {
    this.clearTimer('countdown');

    let n = Math.max(0, Math.floor(startFrom));

    const cfg = this.getConfig();
    if (cfg.selectedStyle === 'chant') {
      const track = getChantById(cfg.chosenChantId || null);
      if (track) {
        if (!this.chantCoordinator) {
          this.chantCoordinator = new AudioCoordinator({
            voiceKey: track.voiceKey as any,
            instrumentalKey: track.instrumentalKey as any,
            cues: track.cues,
            pauseDurationMs: track.pauseDurationMs,
            getTimeLeftSeconds: () => this.timeLeftSeconds(),
            minSecondsToStartNextLoop: 72,
            finalFadeOutThresholdSec: 60,
            decayPerLoop: 0.94,
          });
        }
        this.chantCoordinator.preload().catch(() => {});
      }
    }

    const step = async (current: number) => {
      this.callbacks.onCountdownTick?.(current);
      if (current > 0) {
        try { playCue('tickTock'); } catch {}
        try { await queueSpeak(`${current}`, 0.8); } catch {}
        this.clearTimer('countdown');
        this.countdownInterval = setTimeout(() => {
          void step(Math.max(0, current - 1));
        }, 0) as unknown as number;
      } else {
        this.clearTimer('countdown');
      }
    };

    void step(n);
  }

  pause() {
    if (!this.started || this.paused) return;
    this.paused = true;

    // Accumulate elapsed time
    if (this.activeStartMs) {
      this.accumulatedMs += Date.now() - this.activeStartMs;
      this.activeStartMs = Date.now();
    }

    // Stop all loops
    this.stopBreathingLoop();
    this.clearTimer('centering');

    // Pause background audio
    const channel = this.getBackgroundChannel();
    if (channel && this.bgActive) { stopMusic(channel); this.bgActive = false; }
    // Pause chant coordinator
    this.chantCoordinator?.pause().catch(() => {});

    // Stop and clear any TTS activity/queue while paused
    try {
      const Speech = require('expo-speech');
      Speech.stop();
    } catch {}
    try { clearSpeechQueue(); } catch {}
  }

  resume() {
    if (!this.started || !this.paused) return;
    this.paused = false;
    this.activeStartMs = Date.now();

    const cfg = this.cfg();
    
    // Resume background audio for non-chant
    if (cfg.selectedStyle !== 'chant') {
      this.startBackgroundAudio();
      this.startBreathingLoop();
      
      // Resume centering interval if needed
      if (this.introDone && cfg.selectedStyle === 'centering') {
        this.startCenteringInterval();
      }
    }
    // Resume chant if applicable
    if (cfg.selectedStyle === 'chant') {
      this.chantCoordinator?.resume().catch(() => {});
    }
  }

  stop() {
    this.clearAllTimers();
    this.stopBreathingLoop();
    
    // Stop background audio
    const channel = this.getBackgroundChannel();
    if (channel && this.bgActive) { stopMusic(channel); this.bgActive = false; }
    // Stop chant coordinator
    if (this.chantCoordinator) {
      this.chantCoordinator.stop().catch(() => {});
      this.chantCoordinator = null;
    }

    // Stop and clear any TTS activity/queue
    try {
      const Speech = require('expo-speech');
      Speech.stop();
    } catch {}
    try { clearSpeechQueue(); } catch {}

    this.started = false;
    this.paused = false;
    this.currentGuide = null;
    this.sessionCfg = null;
  }

  isStarted(): boolean {
    return this.started;
  }

  isPaused(): boolean {
    return this.paused;
  }

  // ----- STATIC METHODS -----

  static determineMeditationLevel(
    sessionCount: number,
    selectedMinutes: number | null | undefined
  ): 'foundation' | 'growth' | 'deep' {
    if (!selectedMinutes || sessionCount <= 2) return 'foundation';
    if (selectedMinutes >= 25 || sessionCount >= 8) return 'deep';
    return 'growth';
  }

  static buildGuide(args: {
    selectedStyle: 'parable' | 'virtue' | 'centering' | 'jesus_prayer' | 'chant';
    selectedMinutes?: number | null;
    selectedChallenge?: Challenge;
    sessionCount?: number;
    virtueName?: string | null;
    centeringWord?: string | null;
    chosenChantId?: string | null;
  }): MeditationGuide {
    const level = MeditationOrchestrator.determineMeditationLevel(
      Math.max(0, args.sessionCount ?? 0),
      args.selectedMinutes ?? null
    );
    const challengeText = args.selectedChallenge?.title || args.selectedChallenge?.description || null;

    // Centering Prayer
    if (args.selectedStyle === 'centering') {
      const practice = contemplativePractices.find(p => p.id === 'centering-prayer');
      const word = (args.centeringWord || 'Jesus').trim();
      const prompts = (practice?.focus ?? []).slice(0, 3);
      return {
        title: practice?.name || 'Centering Prayer',
        imagery: practice?.description || 'Choose a sacred word and rest quietly before God.',
        scripture: '',
        prompts,
        declaration: 'Return gently to your word whenever you are distracted.',
        leadIn: 'Settle your body. Allow your breath to find a natural rhythm.',
        focus: `Sacred word: ${word}`,
        breathInvitation: 'Breathe slowly and let your word bring you back to God\'s presence.',
        closingReminder: 'Close with gratitude for any subtle movements of the heart.',
        openReflection: practice?.guidance?.[0],
        guidanceTips: practice?.guidance,
      };
    }

    // Jesus Prayer
    if (args.selectedStyle === 'jesus_prayer') {
      const practice = contemplativePractices.find(p => p.id === 'jesus-prayer');
      const prompts = (practice?.focus ?? []).slice(0, 3);
      return {
        title: practice?.name || 'Jesus Prayer',
        imagery: practice?.description || 'Pray the ancient phrase in rhythm with your breath.',
        scripture: '',
        prompts,
        declaration: 'Have mercy on me, a sinner.',
        leadIn: 'Match the prayer with your inhale and exhale gently.',
        focus: '"Lord Jesus Christ, Son of God, have mercy on me."',
        breathInvitation: 'Inhale the first half, exhale the second half of the prayer.',
        closingReminder: 'Carry mercy with you into your next steps.',
        openReflection: practice?.guidance?.[0],
        guidanceTips: practice?.guidance,
      };
    }

    // Chant
    if (args.selectedStyle === 'chant') {
      const practice = contemplativePractices.find(p => p.id === 'taize-chant');
      return {
        title: practice?.name || 'Chant',
        imagery: practice?.description || 'Repeat short chants or scriptures set to simple melodies.',
        scripture: '',
        prompts: ['Singing is a deeper form of prayer'],
        declaration: 'Meditate on the words',
        leadIn: 'Begin',
        focus: '',
        breathInvitation: '',
        closingReminder: '',
        guidanceTips: practice?.guidance,
      };
    }

    // Parable / Virtue modes
    const plan = buildMeditationPlan({
      level,
      dateSeed: Date.now(),
      challengeText,
      sessionCount: Math.max(0, args.sessionCount ?? 0),
    });

    const virtueLine = args.virtueName
      ? `Notice how this connects with ${args.virtueName.toLowerCase()} in your life today.`
      : 'Notice how this story meets your life today.';

    const prompts = [
      plan.reflectionPrompts[0],
      virtueLine,
      plan.reflectionPrompts[1],
      plan.reflectionPrompts[2],
      plan.reflectionPrompts[3],
    ].filter(Boolean) as string[];

    const base: MeditationGuide = {
      title: plan.title,
      imagery: plan.overview,
      scripture: plan.scripture,
      prompts: prompts.slice(0, 4),
      declaration: plan.closingReminder,
      leadIn: `Spend a moment with the ${plan.parable}. ${plan.overview}`,
      focus: plan.breathInvitation,
      breathInvitation: plan.breathInvitation,
      closingReminder: plan.closingReminder,
      openReflection: plan.openReflection,
      guidanceTips: plan.guidanceTips,
      stageNote: plan.stageNote,
    };

    // Customize for virtue mode
    if (args.selectedStyle === 'virtue') {
      const v = args.virtueName || 'this virtue';
      base.prompts = [
        `Where in my life am I lacking the most in ${v}?`,
        `What can I do today to grow and improve in ${v}?`,
        `Thank you Jesus for helping me acknowledge my deficiencies in ${v}, may the grace and strength of your Spirit renew me today to imitate you in ${v}. Amen.`,
      ];
    } else if (args.selectedStyle === 'parable') {
      base.prompts = base.prompts.slice(0, 2);
    }

    return base;
  }

  // ----- PRIVATE METHODS -----

  private reset() {
    this.lastPromptIndex = -1;
    this.stages = { s1: false, s2: false };
    this.challengeSpoken = false;
    this.finalCountdownStarted = false;
    this.sessionCompleted = false;
    this.spokenPrompts.clear();
    this.activeStartMs = 0;
    this.accumulatedMs = 0;
    this.lastEmittedSecond = -1;
    this.breathCycleCount = 0;
    this.introDone = false;
    this.currentGuide = null;
    this.lastBellMs = 0;
    this.chantFinalPromptSpoken = false;
    this.chantFadedOut = false;
    this.closingStarted = false;
    this.parableNearEndPromptSpoken = false;
    this.clearClosingWatchdog();
  }

  private clearAllTimers() {
    this.clearTimer('main');
    this.clearTimer('countdown');
    this.clearTimer('centering');
    this.clearFinalCountdown();
    this.clearClosingWatchdog();
  }

  private clearTimer(type: 'main' | 'countdown' | 'centering') {
    if (type === 'main' && this.mainInterval) {
      clearInterval(this.mainInterval);
      this.mainInterval = null;
    } else if (type === 'countdown' && this.countdownInterval) {
      clearInterval(this.countdownInterval);
      this.countdownInterval = null;
    } else if (type === 'centering' && this.centeringInterval) {
      clearInterval(this.centeringInterval);
      this.centeringInterval = null;
    }
  }

  private getBackgroundChannel(): 'meditation' | 'heartbeat' | null {
    const s = this.cfg().selectedBackgroundSound;
    if (s === 'ambient') return 'meditation';
    if (s === 'heartbeat') return 'heartbeat';
    return null;
  }

  private startBackgroundAudio() {
    const channel = this.getBackgroundChannel();
    if (channel && !this.bgActive) { playMusic(channel, 0.6); this.bgActive = true; }
  }

  private async speakWithDuck(text: string, rate = 0.85) {
    const channel = this.getBackgroundChannel();
    try {
      if (channel) await setMusicVolume(channel, 0.2);
      await queueSpeak(text, rate);
    } finally {
      if (channel) await setMusicVolume(channel, 0.6);
    }
  }

  private maybePlayBell() {
    const now = Date.now();
    if (now - this.lastBellMs >= 30000) {
      this.lastBellMs = now;
      playCue('meditationBell');
    }
  }

  private buildAndEmitGuide() {
    const cfg = this.cfg();
    const guide = MeditationOrchestrator.buildGuide({
      selectedStyle: cfg.selectedStyle,
      selectedMinutes: cfg.selectedMinutes,
      selectedChallenge: cfg.selectedChallenge,
      sessionCount: cfg.sessionCount,
      virtueName: cfg.virtueName,
      centeringWord: cfg.centeringWord,
      chosenChantId: cfg.chosenChantId,
    });
    this.currentGuide = guide;
    this.callbacks.onGuide?.(guide);
  }

  private async runIntro() {
    if (this.introDone) return;

    const guide = this.currentGuide;
    if (!guide) return;

    const cfg = this.cfg();
    const wait = (ms: number) => new Promise<void>(r => setTimeout(r, ms));

    // Chant: minimal intro
    if (cfg.selectedStyle === 'chant') {
      this.finishIntro();
      return;
    }

    // 1) Close eyes
    await wait(200);
    await this.speakWithDuck('Close your eyes if you are able to do so...', cfg.selectedStyle === 'parable' ? 0.72 : 0.8);

    // 2) Lead-in
    await wait(1000);
    await this.speakWithDuck(guide.leadIn, cfg.selectedStyle === 'parable' ? 0.72 : 0.8);

    // 3) Mode-specific prelude
    await wait(1000);
    if (cfg.selectedStyle === 'centering') {
      const word = (cfg.centeringWord || 'Jesus').trim();
      if (cfg.centeringReadMode === 'aloud') {
        await this.speakWithDuck(word, 0.8);
      }
    } else if (cfg.selectedStyle === 'parable' && cfg.parableReadMode === 'aloud') {
      try {
        await readScriptureSlowly(guide.scripture);
        // Ensure a contemplative pause of at least 30s immediately after reading
        await wait(30000);
      } catch {}
    } else {
      await this.speakWithDuck(guide.focus, cfg.selectedStyle === 'parable' ? 0.72 : 0.8);
    }

    // 4) Bell, breath invite, insights
    await wait(1000);
    this.maybePlayBell();
    await wait(500);
    // await this.speakWithDuck(guide.breathInvitation || 'Breathe in...', cfg.selectedStyle === 'parable' ? 0.72 : 0.8);
    await this.speakWithDuck('Breathe in...', cfg.selectedStyle === 'parable' ? 0.72 : 0.8);

    const stageNote = guide.stageNote?.trim();
    const openReflection = guide.openReflection?.trim();
    const allowInsights = !(cfg.selectedStyle === 'parable' && cfg.parableReadMode === 'aloud');
    
    if (allowInsights && (stageNote || openReflection)) {
      const insights = [stageNote, openReflection].filter(Boolean) as string[];
      for (let i = 0; i < insights.length; i++) {
        await wait(i === 0 ? 400 : 600);
        await this.speakWithDuck(insights[i]!, cfg.selectedStyle === 'parable' ? 0.72 : 0.8);
      }
    }

    // 5) Hold and out
    await wait(5000);
    await this.speakWithDuck('Keep still...', cfg.selectedStyle === 'parable' ? 0.72 : 0.8);
    await wait(5000);
    await this.speakWithDuck('Breathe out...', cfg.selectedStyle === 'parable' ? 0.72 : 0.8);

    this.finishIntro();
  }

  private finishIntro() {
    this.introDone = true;
    this.callbacks.onIntroComplete?.();

    const cfg = this.cfg();
    
    // Start centering interval
    if (cfg.selectedStyle === 'centering') {
      this.startCenteringInterval();
    }

    // Start breathing loop for non-chant
    if (cfg.selectedStyle !== 'chant') {
      this.startBreathingLoop();
      
      // Speak first prompt after delay
      setTimeout(() => {
        if (this.started && !this.paused) {
          this.callbacks.showPrompt?.(0);
          this.speakPrompt(0).catch(() => {});
        }
      }, 1500);
    }
  }

  private async speakPrompt(index: number) {
    const guide = this.currentGuide;
    if (!guide) return;

    const prompts = guide.prompts || [];
    const prompt = prompts[index] || prompts[0];
    if (!prompt) return;

    const cfg = this.cfg();
    const rate = cfg.selectedStyle === 'parable' ? 0.72 : 0.85;
    if (index === 0) {
      await this.speakWithDuck(prompt, rate);
    } else {
      await this.speakWithDuck('Now...', rate);
      await new Promise(r => setTimeout(r, 800));
      await this.speakWithDuck(prompt, rate);
    }

    const isLast = index === prompts.length - 1;
    if (isLast && guide.declaration) {
      await new Promise(r => setTimeout(r, 1200));
      await this.speakWithDuck(guide.declaration, rate);
    }
  }

  private tick() {
    if (this.paused) return;

    const now = Date.now();
    if (this.activeStartMs === 0) this.activeStartMs = now;

    const cfg = this.cfg();
    const { selectedStyle, promptInterval, totalMeditationSeconds, selectedChallenge } = cfg;

    const elapsedMs = this.accumulatedMs + (now - this.activeStartMs);
    const t = Math.max(0, Math.floor(elapsedMs / 1000));

    // Emit tick
    if (this.lastEmittedSecond !== t) {
      this.lastEmittedSecond = t;
      const ratio = totalMeditationSeconds > 0 ? Math.min(1, t / totalMeditationSeconds) : 0;
      this.callbacks.onTick?.(t, ratio);
    }

    // Prompt handling (skip once closing sequence has begun)
    if (!this.closingStarted) {
      if (selectedStyle === 'virtue') {
        this.handleVirtueStages(t, totalMeditationSeconds);
      } else if (selectedStyle !== 'chant') {
        this.handlePeriodicPrompts(t, promptInterval, totalMeditationSeconds);
      }
    }

    const timeLeft = totalMeditationSeconds - t;

    // Chant-time specific controls
    if (selectedStyle === 'chant') {
      if (!this.chantFinalPromptSpoken && timeLeft === 60) {
        this.chantFinalPromptSpoken = true;
        this.speakWithDuck('As we close, connect this chant with your day today.', 0.85).catch(() => {});
      }
      // Fade out chant when under 60s
      if (!this.chantFadedOut && timeLeft < 60) {
        this.chantFadedOut = true;
        try { this.chantCoordinator?.fadeOut(2000); } catch {}
      }
    } else if (selectedStyle === 'parable') {
      const total = totalMeditationSeconds;
      const speakAtTwoMinWindow = total >= 120 && timeLeft <= 120 && timeLeft > 55;
      const speakAtOneMinWindow = total >= 90 && total < 120 && timeLeft <= 60 && timeLeft > 30;
      if (!this.parableNearEndPromptSpoken && (speakAtTwoMinWindow || speakAtOneMinWindow)) {
        this.parableNearEndPromptSpoken = true;
        this.speakWithDuck(
          'As we prepare to close, consider how this parable connects to your life today. What is one single thing you can do to become better?',
          0.72
        ).catch(() => {});
      }
    }

    this.ensureClosingWindow(timeLeft, selectedStyle, selectedChallenge);
  }

  private beginClosingSequence(style: string) {
    // Stop scheduling centering prompts beyond this point
    // Keep breathing visuals going; only halt added prompts
    try {
      // For quiet close in centering/parable, stop background audio now
      if (style === 'centering' || style === 'parable') {
        const channel = this.getBackgroundChannel();
        if (channel && this.bgActive) { stopMusic(channel); this.bgActive = false; }
      }
      if (style === 'centering') {
        // Stop repeating centering word & bell during closing window
        this.clearTimer('centering');
        // one gentle reminder for silence in last half-minute
        this.speakWithDuck('In these closing moments, rest in quiet.', 0.85).catch(() => {});
      } else if (style === 'virtue') {
        this.speakWithDuck('Take one last quiet moment to receive this virtue.', 0.85).catch(() => {});
      } else if (style === 'jesus_prayer') {
        this.speakWithDuck('Gently rest in the presence of Jesus.', 0.85).catch(() => {});
      } else if (style === 'parable') {
        this.speakWithDuck('Sit quietly with this word as we close.', 0.75).catch(() => {});
      }
    } catch {}
  }

  private handleVirtueStages(t: number, totalSeconds: number) {
    const s1 = Math.floor(totalSeconds * 2 / 5);
    const s2 = Math.floor(totalSeconds * 4 / 5);

    if (!this.stages.s1 && t >= s1 && !this.spokenPrompts.has(1)) {
      this.stages.s1 = true;
      this.spokenPrompts.add(1);
      this.callbacks.showPrompt?.(1);
      this.speakPrompt(1).catch(() => {});
    }

    if (!this.stages.s2 && t >= s2 && !this.spokenPrompts.has(2)) {
      this.stages.s2 = true;
      this.spokenPrompts.add(2);
      this.callbacks.showPrompt?.(2);
      this.speakPrompt(2).catch(() => {});
    }
  }

  private handlePeriodicPrompts(t: number, interval: number, totalSeconds: number) {
    if (interval > 0 && t > 0 && t < totalSeconds - 30) {
      const idx = Math.floor(t / interval);
      if (idx !== this.lastPromptIndex && idx < 4 && idx >= 1 && !this.spokenPrompts.has(idx)) {
        this.lastPromptIndex = idx;
        this.spokenPrompts.add(idx);
        this.callbacks.showPrompt?.(idx);
        this.speakPrompt(idx).catch(() => {});
      }
    }
  }

  private handleChallengeAnnouncement(style: string, challenge: Challenge) {
    this.challengeSpoken = true;
    if (style !== 'chant' && challenge) {
      setTimeout(() => {
        this.speakWithDuck('Your challenge is:', 0.85)
          .then(() => this.speakWithDuck(challenge.title!, 0.85))
          .then(() => this.speakWithDuck(challenge.description!, 0.85))
          .catch(() => {});
      }, 500);
    }
  }

  private startFinalCountdown() {
    if (this.finalCountdownStarted) return;

    this.finalCountdownStarted = true;
    this.logDebug('Starting final countdown sequence');

    // Stop meditative guidance loops to avoid overlap during countdown
    this.clearTimer('centering');
    this.stopBreathingLoop();

    // Ensure no pending speech keeps playing
    try {
      const Speech = require('expo-speech');
      Speech.stop();
    } catch {}

    let n = 3;
    this.clearFinalCountdown();

    const step = async () => {
      if (n > 0) {
        try { await this.speakWithDuck(`${n}`, 0.9); } catch {}
        n -= 1;
        this.clearFinalCountdown();
        this.finalCountdownTimer = setTimeout(() => { void step(); }, 0) as unknown as number;
      } else {
        if (!this.sessionCompleted) {
          this.logDebug('Final countdown reached zero – forcing completion');
          this.handleSessionComplete();
        } else {
          this.clearFinalCountdown();
        }
      }
    };

    void step();
  }

  private handleSessionComplete() {
    this.sessionCompleted = true;
    playCue('meditationBell');

    // Stop background audio
    const channel = this.getBackgroundChannel();
    if (channel && this.bgActive) { stopMusic(channel); this.bgActive = false; }

    // Full cleanup of loops and audio
    this.clearAllTimers();
    this.stopBreathingLoop();
    this.clearFinalCountdown();
    this.clearClosingWatchdog();
    try { clearSpeechQueue(); } catch {}
    if (this.chantCoordinator) {
      this.chantCoordinator.stop().catch(() => {});
      this.chantCoordinator = null;
    }
    this.started = false;
    this.paused = false;

    this.speakWithDuck('Open your eyes', 0.85)
      .then(() => this.callbacks.onComplete())
      .catch(() => this.callbacks.onComplete());
  }

  private clearFinalCountdown() {
    if (this.finalCountdownTimer) {
      clearInterval(this.finalCountdownTimer);
      this.finalCountdownTimer = null;
    }
  }

  private cfg() {
    return this.sessionCfg ?? this.getConfig();
  }

  private clearClosingWatchdog() {
    if (this.closingWatchdogTimer) {
      clearTimeout(this.closingWatchdogTimer);
      this.closingWatchdogTimer = null;
    }
  }

  private scheduleClosingWatchdog() {
    if (this.closingWatchdogTimer) return;

    const run = () => {
      this.closingWatchdogTimer = null;

      if (!this.started || this.sessionCompleted) {
        return;
      }

      try {
        const cfg = this.cfg();
        const remaining = this.timeLeftSeconds();
        this.ensureClosingWindow(remaining, cfg.selectedStyle, cfg.selectedChallenge);
      } catch (error) {
        this.logDebug('Closing watchdog error', error);
      } finally {
        if (this.started && !this.sessionCompleted) {
          this.closingWatchdogTimer = setTimeout(run, 2000) as unknown as number;
        }
      }
    };

    this.closingWatchdogTimer = setTimeout(run, 2000) as unknown as number;
  }

  private ensureClosingWindow(timeLeft: number, style: 'parable' | 'virtue' | 'centering' | 'jesus_prayer' | 'chant', challenge: Challenge | null) {
    const closingLead = this.getClosingLeadSeconds(style, challenge);
    if (!this.closingStarted && timeLeft <= Math.max(10, closingLead) && timeLeft > 0) {
      this.closingStarted = true;
      this.logDebug('Triggering closing sequence', { timeLeft });
      this.beginClosingSequence(style);
    }

    if (!this.challengeSpoken && timeLeft <= closingLead && timeLeft > 3) {
      this.logDebug('Announcing closing challenge', { timeLeft });
      this.handleChallengeAnnouncement(style, challenge);
    }

    if (!this.finalCountdownStarted && timeLeft <= 3 && timeLeft >= 0) {
      this.logDebug('Starting final countdown', { timeLeft });
      this.startFinalCountdown();
    }

    if (!this.sessionCompleted && timeLeft <= 0) {
      if (!this.finalCountdownStarted) {
        this.logDebug('Time elapsed; enforcing final countdown before completion', { timeLeft });
        this.startFinalCountdown();
      }
    }
  }

  private startCenteringInterval() {
    const { centeringWord, centeringReadMode, centeringRepeatIntervalSec } = this.cfg();
    const intervalMs = Math.max(30, Math.min(60, centeringRepeatIntervalSec)) * 1000;

    this.centeringInterval = setInterval(() => {
      const word = (centeringWord || 'Jesus').trim();
      if (centeringReadMode === 'aloud') {
        this.speakWithDuck(word, 0.85)
          .then(() => this.maybePlayBell())
          .catch(() => this.maybePlayBell());
      } else {
        this.maybePlayBell();
      }
    }, intervalMs) as unknown as number;
  }

  private startBreathingLoop() {
    this.stopBreathingLoop();

    const cfg = this.cfg();
    const pace = cfg.jesusPrayerPace || 'medium';
    const P = BREATH_DURATIONS[pace];
    const phases: Array<'in' | 'hold' | 'out'> = ['in', 'hold', 'out'];

    let index = 0;
    const schedule = () => {
      // Check both flags before scheduling
      if (!this.started || this.paused) return;

      const phase = phases[index];
      const duration = phase === 'in' ? P.in : phase === 'hold' ? P.hold : P.out;

      this.callbacks.onBreathPhase?.(phase, duration);

      if (phase === 'out' && this.breathCycleCount < 3) {
        this.maybePlayBell();
        this.breathCycleCount += 1;
      }

      this.breathTimeout = setTimeout(() => {
        // Re-check before recursing
        if (this.started && !this.paused) {
          index = (index + 1) % 3;
          schedule();
        }
      }, duration) as unknown as number;
    };

    schedule();
  }

  private stopBreathingLoop() {
    if (this.breathTimeout) {
      clearTimeout(this.breathTimeout);
      this.breathTimeout = null;
    }
  }
}

export type MeditationGuide = {
  title: string;
  imagery: string;
  scripture: string;
  prompts: string[];
  declaration: string;
  leadIn: string;
  focus: string;
  breathInvitation: string;
  closingReminder: string;
  openReflection?: string;
  guidanceTips?: string[];
  stageNote?: string;
};