import * as Speech from 'expo-speech';
import type { ReadingPlanPhase } from '@/constants/readingPlanModes';
import { getVoicePromptsForPhase, getPhaseInstructions } from '@/modules/habitConquestVoicePrompts';

export type HabitConquerPhaseId =
  | 'affirmation'
  | 'meditation'
  | 'mercy'
  | 'forgiveness'
  | 'thanksgiving'
  | string;

export interface HabitConquerPhase {
  id: HabitConquerPhaseId;
  label: string;
  minutes: number;
}

export interface HabitConquerGuide {
  title: string;
  text: string;
}

export interface HabitConquerConfig {
  phases: HabitConquerPhase[];
  vice?: string | null;
  doorOfSin?: string | null;
  pledgeGood?: string | null;
  voiceEnabled?: boolean;
}

interface HabitConquerCallbacks {
  onPrompt?: (text: string) => void;
  onGuide?: (guide: HabitConquerGuide | null) => void;
}

type TimerRef = ReturnType<typeof setTimeout>;

export class HabitConquerOrchestrator {
  private getConfig: () => HabitConquerConfig;
  private callbacks: HabitConquerCallbacks;
  private promptTimers: TimerRef[] = [];
  private voiceEnabled: boolean;

  constructor(opts: { getConfig: () => HabitConquerConfig; callbacks: HabitConquerCallbacks }) {
    this.getConfig = opts.getConfig;
    this.callbacks = opts.callbacks;
    this.voiceEnabled = opts.getConfig().voiceEnabled ?? true;
  }

  static scalePhases(phases: HabitConquerPhase[], targetMinutes: number): HabitConquerPhase[] {
    const safeTarget = Math.max(0, Math.round(targetMinutes));
    const baseTotal = phases.reduce((sum, phase) => sum + Math.max(0, phase.minutes || 0), 0);
    if (!safeTarget || baseTotal <= 0 || baseTotal === safeTarget) {
      return phases.map(phase => ({ ...phase }));
    }

    const ratio = safeTarget / baseTotal;
    const prelim = phases.map(phase => ({
      ...phase,
      minutes: Math.max(0, Math.floor((phase.minutes || 0) * ratio)),
    }));
    const diffTarget = safeTarget - prelim.reduce((sum, phase) => sum + phase.minutes, 0);
    if (diffTarget <= 0) {
      return prelim;
    }
    const adjusted = prelim.map(phase => ({ ...phase }));
    let diff = diffTarget;
    let i = 0;
    while (diff > 0 && adjusted.length) {
      adjusted[i % adjusted.length].minutes += 1;
      diff -= 1;
      i += 1;
    }
    return adjusted;
  }

  static toReadingTimerPhases(phases: HabitConquerPhase[]): ReadingPlanPhase[] {
    return phases.map(phase => {
      const phaseId = HabitConquerOrchestrator.mapPhaseToReadingPhase(phase.id);
      return {
        id: phaseId,
        label: phase.label,
        minutes: phase.minutes,
        hint: getPhaseInstructions(phase.id) ?? undefined,
      };
    });
  }

  static mapPhaseToReadingPhase(phaseId: HabitConquerPhaseId): ReadingPlanPhase['id'] {
    switch (phaseId) {
      case 'meditation':
        return 'meditation';
      case 'mercy':
      case 'forgiveness':
      case 'thanksgiving':
        return 'prayer';
      case 'affirmation':
      default:
        return 'contemplation';
    }
  }

  static buildGuideForPhase(phaseId: HabitConquerPhaseId): HabitConquerGuide | null {
    switch (phaseId) {
      case 'affirmation':
        return {
          title: 'Affirmation',
          text: 'Speak your identity in Christ aloud. Declare your pledge and remember why you are choosing healing today.',
        };
      case 'meditation':
        return {
          title: 'Meditation with God',
          text: 'Sit quietly with God. Notice thoughts and urges without judgment. Breathe deeply and allow Him to renew your mind.',
        };
      case 'mercy':
        return {
          title: 'Prayer for Mercy',
          text: 'Ask God for mercy. Invite His strength to meet you in weakness and to steady every wavering place.',
        };
      case 'forgiveness':
        return {
          title: 'Prayer for Forgiveness',
          text: 'Confess honestly. Receive forgiveness fully, and release any shame back to the Cross where it belongs.',
        };
      case 'thanksgiving':
        return {
          title: 'Prayer of Thanksgiving',
          text: 'Give thanks for small victories and for the new path God is building in you. Gratitude strengthens the journey.',
        };
      default:
        return null;
    }
  }

  startPhaseByLabel(label?: string) {
    if (!label) return;
    const cfg = this.getConfig();
    const phase = cfg.phases.find(p => p.label === label || p.id === label);
    if (!phase) return;
    this.stagePhase(phase, cfg);
  }

  setVoiceEnabled(enabled: boolean) {
    this.voiceEnabled = enabled;
    if (!enabled) {
      this.stopPrompts();
    }
  }

  stopPrompts() {
    for (const timer of this.promptTimers) {
      try {
        clearTimeout(timer);
      } catch {
        // noop
      }
    }
    this.promptTimers = [];
    try {
      Speech.stop();
    } catch {
      // noop
    }
  }

  stop() {
    this.stopPrompts();
  }

  private stagePhase(phase: HabitConquerPhase, cfg: HabitConquerConfig) {
    const guide = HabitConquerOrchestrator.buildGuideForPhase(phase.id);
    if (guide) {
      this.callbacks.onGuide?.(guide);
    }
    this.schedulePrompts(phase, cfg);
  }

  private schedulePrompts(phase: HabitConquerPhase, cfg: HabitConquerConfig) {
    this.stopPrompts();
    const prompts = getVoicePromptsForPhase(
      phase.id,
      (phase.minutes || 0) * 60,
      cfg.vice,
      cfg.doorOfSin,
      cfg.pledgeGood,
    );
    const startPrompt = prompts.find(p => p.timing === 'start');
    const midPrompt = prompts.find(p => p.timing === 'middle');
    const endPrompt = prompts.find(p => p.timing === 'end');

    if (startPrompt) {
      this.callbacks.onPrompt?.(startPrompt.text);
      this.enqueueSpeak(startPrompt.text, 1200);
    }

    if (midPrompt) {
      const midpointMs = Math.max(1000, ((phase.minutes || 0) * 60 * 1000) / 2);
      const timer = setTimeout(() => {
        this.callbacks.onPrompt?.(midPrompt.text);
        this.enqueueSpeak(midPrompt.text);
      }, midpointMs);
      this.promptTimers.push(timer);
    }

    if (endPrompt) {
      const endMs = Math.max(1000, ((phase.minutes || 0) * 60 - 15) * 1000);
      const timer = setTimeout(() => {
        this.callbacks.onPrompt?.(endPrompt.text);
      }, endMs);
      this.promptTimers.push(timer);
    }
  }

  private enqueueSpeak(text: string, delayMs = 0) {
    if (!this.voiceEnabled) return;
    const timer = setTimeout(() => {
      try {
        Speech.speak(text, { language: 'en', pitch: 1.0, rate: 0.7 });
      } catch {
        // noop
      }
    }, delayMs);
    this.promptTimers.push(timer);
  }
}

export type HabitConquerOrchestratorType = HabitConquerOrchestrator;
