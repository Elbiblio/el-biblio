import { format } from 'date-fns';

export const getTimeRemaining = (endTime: string): string => {
  try {
    const now = new Date();

    const raw = (endTime || '').trim();
    let target: Date | null = null;

    if (raw.includes('-')) {
      const isoCandidate = raw.includes('T') ? raw : raw.replace(' ', 'T');
      const parsed = new Date(isoCandidate);
      if (!Number.isNaN(parsed.getTime())) {
        target = parsed;
      }
    }

    if (!target) {
      const parts = raw.split(':').map(Number);
      if (parts.length >= 2 && parts.every((p) => !Number.isNaN(p))) {
        const [hours, minutes, seconds] = [parts[0], parts[1], parts[2] ?? 0];
        const t = new Date(now);
        t.setHours(hours, minutes, seconds, 0);
        target = t;
      }
    }

    if (!target) {
      return 'Ends soon';
    }

    if (target <= now) {
      return 'Expired';
    }

    const minutesDiff = Math.max(0, Math.floor((target.getTime() - now.getTime()) / (1000 * 60)));
    if (minutesDiff < 90) {
      const displayMinutes = Math.max(1, minutesDiff);
      return `Ends in ${displayMinutes} min`;
    }

    if (minutesDiff < 12 * 60) {
      const hoursLeft = Math.floor(minutesDiff / 60);
      const remainingMinutes = minutesDiff % 60;
      return `Ends in ${hoursLeft}h${remainingMinutes ? ` ${remainingMinutes}m` : ''}`;
    }

    return `Ends at ${format(target, 'h:mm a')}`;
  } catch {
    return 'Ends soon';
  }
};

export const getFrequencyLabel = (freq?: string): string => {
  switch (freq) {
    case 'd':
      return 'Daily';
    case 'w':
      return 'Weekly';
    case 'm':
      return 'Monthly';
    default:
      return 'Daily';
  }
};

export const validateEndTime = (rawEnd: string): { valid: boolean; error?: string } => {
  const trimmed = String(rawEnd || '').trim();
  if (!trimmed) {
    return { valid: true };
  }
  
  const m = trimmed.match(/^(\d{1,2}):(\d{2})(?::(\d{2}))?$/);
  if (!m) {
    return { valid: false, error: 'Please enter a valid end time (HH:MM)' };
  }
  
  const hh = Number(m[1]);
  const mm = Number(m[2]);
  const ss = m[3] !== undefined ? Number(m[3]) : 0;
  
  if (hh < 0 || hh > 23 || mm < 0 || mm > 59 || ss < 0 || ss > 59) {
    return { valid: false, error: 'Please enter a valid end time (HH:MM)' };
  }
  
  return { valid: true };
};
