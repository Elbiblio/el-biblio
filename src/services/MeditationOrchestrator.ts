import { buildMeditationPlan, contemplativePractices } from '@/data/meditationPlans';
import { speak, readScriptureSlowly } from '@/services/AudioCoordinator';
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

  // Guide
  private currentGuide: MeditationGuide | null = null;

  constructor(opts: OrchestratorOptions) {
    this.getConfig = opts.getConfig;
    this.callbacks = opts.callbacks;
  }

  // ----- PUBLIC METHODS -----

  start() {
    if (this.started) return;
    this.started = true;
    this.reset();

    const cfg = this.getConfig();

    // Start background audio for non-chant modes
    if (cfg.selectedStyle !== 'chant') {
      this.startBackgroundAudio();
    }

    // Build and emit guide
    this.buildAndEmitGuide();

    // Start main tick loop
    this.activeStartMs = Date.now();
    this.mainInterval = setInterval(() => this.tick(), 500) as unknown as number;

    // Run intro sequence
    this.runIntro().catch(() => {});
  }

  startCountdown(startFrom = 5) {
    this.clearTimer('countdown');
    
    let n = Math.max(0, Math.floor(startFrom));
    
    // Emit immediately
    this.callbacks.onCountdownTick?.(n);
    if (n > 0) {
      playCue('tickTock');
      speak(`${n}`, { rate: 0.8 }).catch(() => {});
    }

    this.countdownInterval = setInterval(() => {
      n = Math.max(0, n - 1);
      this.callbacks.onCountdownTick?.(n);
      
      if (n > 0) {
        playCue('tickTock');
        speak(`${n}`, { rate: 0.8 }).catch(() => {});
      } else {
        this.clearTimer('countdown');
      }
    }, 1000) as unknown as number;
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
    if (channel) {
      stopMusic(channel);
    }
  }

  resume() {
    if (!this.started || !this.paused) return;
    this.paused = false;
    this.activeStartMs = Date.now();

    const cfg = this.getConfig();
    
    // Resume background audio for non-chant
    if (cfg.selectedStyle !== 'chant') {
      this.startBackgroundAudio();
      this.startBreathingLoop();
      
      // Resume centering interval if needed
      if (this.introDone && cfg.selectedStyle === 'centering') {
        this.startCenteringInterval();
      }
    }
  }

  stop() {
    this.clearAllTimers();
    this.stopBreathingLoop();
    
    // Stop background audio
    const channel = this.getBackgroundChannel();
    if (channel) {
      stopMusic(channel);
    }

    this.started = false;
    this.paused = false;
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
  }

  private clearAllTimers() {
    this.clearTimer('main');
    this.clearTimer('countdown');
    this.clearTimer('centering');
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
    const s = this.getConfig().selectedBackgroundSound;
    if (s === 'ambient') return 'meditation';
    if (s === 'heartbeat') return 'heartbeat';
    return null;
  }

  private startBackgroundAudio() {
    const channel = this.getBackgroundChannel();
    if (channel) {
      playMusic(channel, 0.6);
    }
  }

  private async speakWithDuck(text: string, rate = 0.85) {
    const channel = this.getBackgroundChannel();
    try {
      if (channel) await setMusicVolume(channel, 0.2);
      await speak(text, { rate });
    } finally {
      if (channel) await setMusicVolume(channel, 0.6);
    }
  }

  private buildAndEmitGuide() {
    const cfg = this.getConfig();
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

    const cfg = this.getConfig();
    const wait = (ms: number) => new Promise<void>(r => setTimeout(r, ms));

    // Chant: minimal intro
    if (cfg.selectedStyle === 'chant') {
      this.finishIntro();
      return;
    }

    // 1) Close eyes
    await wait(200);
    await this.speakWithDuck('Close your eyes if you are able to do so...', 0.8);

    // 2) Lead-in
    await wait(1000);
    await this.speakWithDuck(guide.leadIn, 0.8);

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
        await wait(1200);
      } catch {}
    } else {
      await this.speakWithDuck(guide.focus, 0.8);
    }

    // 4) Bell, breath invite, insights
    await wait(1000);
    playCue('meditationBell');
    await wait(500);
    await this.speakWithDuck(guide.breathInvitation || 'Breathe in...', 0.8);

    const stageNote = guide.stageNote?.trim();
    const openReflection = guide.openReflection?.trim();
    const allowInsights = !(cfg.selectedStyle === 'parable' && cfg.parableReadMode === 'aloud');
    
    if (allowInsights && (stageNote || openReflection)) {
      const insights = [stageNote, openReflection].filter(Boolean) as string[];
      for (let i = 0; i < insights.length; i++) {
        await wait(i === 0 ? 400 : 600);
        await this.speakWithDuck(insights[i]!, 0.8);
      }
    }

    // 5) Hold and out
    await wait(400);
    await this.speakWithDuck('Keep still...', 0.8);
    await wait(400);
    await this.speakWithDuck('Breathe out...', 0.8);

    this.finishIntro();
  }

  private finishIntro() {
    this.introDone = true;
    this.callbacks.onIntroComplete?.();

    const cfg = this.getConfig();
    
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

    if (index === 0) {
      await this.speakWithDuck(prompt, 0.85);
    } else {
      await this.speakWithDuck('Now...', 0.85);
      await new Promise(r => setTimeout(r, 800));
      await this.speakWithDuck(prompt, 0.85);
    }

    const isLast = index === prompts.length - 1;
    if (isLast && guide.declaration) {
      await new Promise(r => setTimeout(r, 1200));
      await this.speakWithDuck(guide.declaration, 0.85);
    }
  }

  private tick() {
    if (this.paused) return;

    const now = Date.now();
    if (this.activeStartMs === 0) this.activeStartMs = now;

    const cfg = this.getConfig();
    const { selectedStyle, promptInterval, totalMeditationSeconds, selectedChallenge } = cfg;

    const elapsedMs = this.accumulatedMs + (now - this.activeStartMs);
    const t = Math.max(0, Math.floor(elapsedMs / 1000));

    // Emit tick
    if (this.lastEmittedSecond !== t) {
      this.lastEmittedSecond = t;
      const ratio = totalMeditationSeconds > 0 ? Math.min(1, t / totalMeditationSeconds) : 0;
      this.callbacks.onTick?.(t, ratio);
    }

    // Prompt handling
    if (selectedStyle === 'virtue') {
      this.handleVirtueStages(t, totalMeditationSeconds);
    } else if (selectedStyle !== 'chant') {
      this.handlePeriodicPrompts(t, promptInterval, totalMeditationSeconds);
    }

    const timeLeft = totalMeditationSeconds - t;

    // Challenge announcement at 30s
    if (!this.challengeSpoken && timeLeft <= 30 && timeLeft > 3) {
      this.handleChallengeAnnouncement(selectedStyle, selectedChallenge);
    }

    // Final countdown at 3s
    if (!this.finalCountdownStarted && timeLeft === 3) {
      this.handleFinalCountdown();
    }

    // Completion
    if (!this.sessionCompleted && timeLeft === 0) {
      this.handleSessionComplete();
    }
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

  private handleFinalCountdown() {
    this.finalCountdownStarted = true;
    
    // Stop any ongoing speech
    try {
      const Speech = require('expo-speech');
      Speech.stop();
    } catch {}

    let n = 3;
    const countdownTimer = setInterval(() => {
      if (n > 0) {
        this.speakWithDuck(`${n}`, 0.9).catch(() => {});
        n -= 1;
      } else {
        clearInterval(countdownTimer);
      }
    }, 1000);
  }

  private handleSessionComplete() {
    this.sessionCompleted = true;
    playCue('meditationBell');

    // Stop background audio
    const channel = this.getBackgroundChannel();
    if (channel) {
      stopMusic(channel);
    }

    this.speakWithDuck('Open your eyes', 0.85)
      .then(() => this.callbacks.onComplete())
      .catch(() => this.callbacks.onComplete());
  }

  private startCenteringInterval() {
    const { centeringWord, centeringReadMode, centeringRepeatIntervalSec } = this.getConfig();
    const intervalMs = Math.max(10, Math.min(30, centeringRepeatIntervalSec)) * 1000;

    this.centeringInterval = setInterval(() => {
      const word = (centeringWord || 'Jesus').trim();
      if (centeringReadMode === 'aloud') {
        this.speakWithDuck(word, 0.85)
          .then(() => playCue('meditationBell'))
          .catch(() => playCue('meditationBell'));
      } else {
        playCue('meditationBell');
      }
    }, intervalMs) as unknown as number;
  }

  private startBreathingLoop() {
    this.stopBreathingLoop();

    const cfg = this.getConfig();
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
        playCue('meditationBell');
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