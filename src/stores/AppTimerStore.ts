import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';

export type TimerPhaseDef = { id: string; label: string; plannedSeconds: number };
export type TimerSummary = { id: string; label: string; plannedSeconds: number; elapsedSeconds: number };

export type TimerState = {
  id: string;
  phases: TimerPhaseDef[];
  currentPhaseIndex: number;
  elapsedInCurrentPhase: number; // Track elapsed instead of end time
  isActive: boolean;
  completed: boolean;
  summaries: TimerSummary[];
  lastTickAt: number | null; // Track when we last updated
};

const STORAGE_PREFIX = 'APP_TIMER:';

class AppTimerStore {
  now: number = Date.now();
  private tickRef: any = null;
  timers: Map<string, TimerState> = new Map();

  constructor() {
    makeAutoObservable(this, {}, { autoBind: true });
  }

  private key(id: string) { return `${STORAGE_PREFIX}${id}`; }

  private startGlobalTick() {
    if (this.tickRef) return;
    
    this.tickRef = setInterval(() => {
      runInAction(() => { 
        this.now = Date.now(); 
      });
      
      // Update all active timers
      this.timers.forEach((timer) => {
        if (!timer.isActive || timer.completed) return;
        
        const deltaMs = timer.lastTickAt ? (this.now - timer.lastTickAt) : 0;
        const deltaSeconds = Math.floor(deltaMs / 1000);
        
        if (deltaSeconds > 0) {
          this.updateTimerElapsed(timer.id, deltaSeconds);
        }
      });
    }, 1000);
  }

  private stopGlobalTick() {
    if (this.tickRef) {
      clearInterval(this.tickRef);
      this.tickRef = null;
    }
  }

  private updateTimerElapsed(id: string, deltaSeconds: number) {
    const timer = this.timers.get(id);
    if (!timer || !timer.isActive) return;

    runInAction(() => {
      const phase = timer.phases[timer.currentPhaseIndex];
      if (!phase) return;

      const plannedSeconds = Math.max(0, phase.plannedSeconds);
      timer.elapsedInCurrentPhase += deltaSeconds;
      timer.lastTickAt = this.now;

      // Auto-advance when phase completes
      if (timer.elapsedInCurrentPhase >= plannedSeconds) {
        this.advancePhase(id);
      }
    });
  }

  async load(id: string) {
    try {
      const raw = await AsyncStorage.getItem(this.key(id));
      if (!raw) return null;
      const parsed = JSON.parse(raw) as TimerState;
      runInAction(() => {
        this.timers.set(id, parsed);
      });
      if (parsed.isActive) {
        this.startGlobalTick();
      }
      return parsed;
    } catch {
      return null;
    }
  }

  private async persist(id: string) {
    const state = this.timers.get(id);
    try {
      if (!state) {
        await AsyncStorage.removeItem(this.key(id));
        return;
      }
      await AsyncStorage.setItem(this.key(id), JSON.stringify(state));
    } catch {}
  }

  get(id: string) { return this.timers.get(id) ?? null; }

  ensure(id: string, phases: TimerPhaseDef[]) {
    let timer = this.timers.get(id);
    if (!timer) {
      timer = {
        id,
        phases,
        currentPhaseIndex: 0,
        elapsedInCurrentPhase: 0,
        isActive: false,
        completed: false,
        summaries: [],
        lastTickAt: null,
      };
      this.timers.set(id, timer);
      void this.persist(id);
    } else if (phases && phases.length) {
      // Update phases but preserve state
      timer.phases = phases.map((p) => ({ 
        id: p.id, 
        label: p.label, 
        plannedSeconds: Math.max(0, p.plannedSeconds) 
      }));
    }
    return timer;
  }

  start(id: string, phases: TimerPhaseDef[], startIndex = 0) {
    const timer = this.ensure(id, phases);
    const idx = Math.max(0, Math.min(startIndex, phases.length - 1));
    
    runInAction(() => {
      timer.currentPhaseIndex = idx;
      timer.elapsedInCurrentPhase = 0;
      timer.isActive = true;
      timer.completed = false;
      timer.lastTickAt = Date.now();
    });
    
    void this.persist(id);
    this.startGlobalTick();
  }

  pause(id: string) {
    const timer = this.timers.get(id);
    if (!timer || !timer.isActive) return;
    
    runInAction(() => {
      timer.isActive = false;
      timer.lastTickAt = null;
    });
    
    void this.persist(id);
    
    // Stop global tick if no active timers
    const hasActiveTimers = Array.from(this.timers.values()).some(t => t.isActive);
    if (!hasActiveTimers) {
      this.stopGlobalTick();
    }
  }

  resume(id: string) {
    const timer = this.timers.get(id);
    if (!timer || timer.completed) return;
    
    const remaining = this.remainingInPhase(id);
    if (remaining <= 0) return;
    
    runInAction(() => {
      timer.isActive = true;
      timer.lastTickAt = Date.now();
    });
    
    void this.persist(id);
    this.startGlobalTick();
  }

  setFromSnapshot(
    id: string, 
    phases: TimerPhaseDef[], 
    currentPhaseIndex: number, 
    secondsRemainingInPhase: number, 
    summaries: TimerSummary[], 
    isActive: boolean, 
    completed: boolean
  ) {
    const timer = this.ensure(id, phases);
    const idx = Math.max(0, Math.min(currentPhaseIndex, phases.length - 1));
    const phase = phases[idx];
    const plannedSeconds = phase ? Math.max(0, phase.plannedSeconds) : 0;
    const elapsed = Math.max(0, plannedSeconds - Math.max(0, secondsRemainingInPhase));
    
    runInAction(() => {
      timer.currentPhaseIndex = idx;
      timer.elapsedInCurrentPhase = elapsed;
      timer.summaries = summaries.map(s => ({ 
        ...s, 
        plannedSeconds: Math.max(0, s.plannedSeconds), 
        elapsedSeconds: Math.max(0, s.elapsedSeconds) 
      }));
      timer.completed = Boolean(completed);
      timer.isActive = Boolean(isActive) && !timer.completed;
      timer.lastTickAt = timer.isActive ? Date.now() : null;
    });
    
    void this.persist(id);
    
    if (timer.isActive) {
      this.startGlobalTick();
    }
  }

  advancePhase(id: string) {
    const timer = this.timers.get(id);
    if (!timer || timer.completed) return false;

    const idx = timer.currentPhaseIndex;
    const phase = timer.phases[idx];
    const plannedSeconds = phase ? Math.max(0, phase.plannedSeconds) : 0;
    const elapsed = Math.min(plannedSeconds, timer.elapsedInCurrentPhase);

    const summary: TimerSummary = {
      id: phase?.id ?? `phase-${idx}`,
      label: phase?.label ?? `Phase ${idx + 1}`,
      plannedSeconds,
      elapsedSeconds: elapsed,
    };

    const newSummaries = [...timer.summaries];
    newSummaries[idx] = summary;

    const isLast = idx >= timer.phases.length - 1;
    
    runInAction(() => {
      timer.summaries = newSummaries;
      
      if (isLast) {
        timer.isActive = false;
        timer.completed = true;
        timer.lastTickAt = null;
      } else {
        timer.currentPhaseIndex = idx + 1;
        timer.elapsedInCurrentPhase = 0;
        timer.lastTickAt = Date.now();
        // Keep isActive state - timer continues automatically
      }
    });
    
    void this.persist(id);
    
    // Stop tick if all timers are done
    if (isLast) {
      const hasActiveTimers = Array.from(this.timers.values()).some(t => t.isActive);
      if (!hasActiveTimers) {
        this.stopGlobalTick();
      }
    }
    
    return true;
  }

  completeAll(id: string) {
    const timer = this.timers.get(id);
    if (!timer) return;
    
    runInAction(() => {
      timer.isActive = false;
      timer.completed = true;
      timer.lastTickAt = null;
      
      // Finalize all remaining phases
      for (let i = timer.currentPhaseIndex; i < timer.phases.length; i++) {
        const phase = timer.phases[i];
        const plannedSeconds = Math.max(0, phase?.plannedSeconds ?? 0);
        const existingSummary = timer.summaries[i];
        
        timer.summaries[i] = {
          id: phase.id,
          label: phase.label,
          plannedSeconds,
          elapsedSeconds: i === timer.currentPhaseIndex 
            ? timer.elapsedInCurrentPhase 
            : (existingSummary?.elapsedSeconds ?? 0),
        };
      }
    });
    
    void this.persist(id);
    
    const hasActiveTimers = Array.from(this.timers.values()).some(t => t.isActive);
    if (!hasActiveTimers) {
      this.stopGlobalTick();
    }
  }

  remainingInPhase(id: string): number {
    const timer = this.timers.get(id);
    if (!timer || timer.completed) return 0;
    
    const phase = timer.phases[timer.currentPhaseIndex];
    if (!phase) return 0;
    
    const plannedSeconds = Math.max(0, phase.plannedSeconds);
    return Math.max(0, plannedSeconds - timer.elapsedInCurrentPhase);
  }

  totalRemaining(id: string): number | null {
    const timer = this.timers.get(id);
    if (!timer) return null;
    if (timer.completed) return 0;
    
    const currentRemaining = this.remainingInPhase(id);
    let total = currentRemaining;
    
    for (let i = timer.currentPhaseIndex + 1; i < timer.phases.length; i++) {
      const phase = timer.phases[i];
      const plannedSeconds = Math.max(0, phase?.plannedSeconds ?? 0);
      const summary = timer.summaries[i];
      const elapsed = Math.max(0, summary?.elapsedSeconds ?? 0);
      total += Math.max(0, plannedSeconds - elapsed);
    }
    
    return total;
  }
}

export const appTimerStore = new AppTimerStore();
export default AppTimerStore;