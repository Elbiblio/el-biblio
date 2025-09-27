type Listener = (payload: { points: number; title?: string }) => void;

class PointsTracker {
  private listeners: Set<Listener> = new Set();

  subscribe(fn: Listener) {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  }

  emit(points: number, title?: string) {
    if (!points || points <= 0) return;
    this.listeners.forEach((fn) => fn({ points, title }));
  }
}

export const pointsTracker = new PointsTracker();
