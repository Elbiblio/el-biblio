function clamp(n: number, min: number, max: number) {
  return Math.max(min, Math.min(max, n));
}

// Map 1-5 spiritual and 1-5 effort ratings to a points estimate for UI preview.
// Higher spiritual value increases points; higher effort reduces the max attainable.
// Returns score normalized [0,1] and points on a 10-50 scale in steps of 10.
export function mapVotesToPoints({ spiritual, effort }: { spiritual: number; effort: number }) {
  const s = clamp(Math.round(spiritual), 1, 5);
  const e = clamp(Math.round(effort), 1, 5);

  // Weighted score:
  // Favor spiritual value 60%, penalize effort 40%.
  const weighted = 0.6 * ((s - 1) / 4) + 0.4 * (1 - (e - 1) / 4);
  const score = clamp(weighted, 0, 1);

  // Tiered points mapping (UI estimate only; backend authoritative)
  let points = 10;
  if (score >= 0.8) points = 50;
  else if (score >= 0.6) points = 40;
  else if (score >= 0.4) points = 30;
  else if (score >= 0.2) points = 20;

  return { score, points };
}
