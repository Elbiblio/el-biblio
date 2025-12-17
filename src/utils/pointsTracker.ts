type Listener = (payload: { points: number; title?: string }) => void;

class PointsTracker {
  private listeners: Set<Listener> = new Set();
  private last?: { points: number; title?: string; at: number };

  subscribe(fn: Listener) {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  }

  emit(points: number, title?: string) {
    if (!points || points <= 0) return;
    const now = Date.now();
    const last = this.last;
    if (last && last.points === points && last.title === title && now - last.at < 1500) {
      return;
    }
    this.last = { points, title, at: now };
    this.listeners.forEach((fn) => fn({ points, title }));
  }
}

export const pointsTracker = new PointsTracker();
