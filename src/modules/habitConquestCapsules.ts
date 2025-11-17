// Simple capsule generator based on selected vice, drawing themes from kingdom.md
// Returns short 3–5 minute capsules: affirmation, reflection, precept, prayer prompts

export type HabitVice =
  | 'Laziness & neglect'
  | 'Recklessness & impulsiveness'
  | 'Ingratitude & entitlement'
  | 'Fear & cowardice'
  | 'Vanity & elitism'
  | 'Addiction to novelty'
  | 'Legalism & isolation'
  | 'Manipulation & ego-driven ambition';

export interface CapsuleItem {
  id: string;
  kind: 'affirmation' | 'reflection' | 'precept' | 'prayer';
  text: string;
  scripture?: string;
}

export function getCapsuleForVice(vice: HabitVice): CapsuleItem[] {
  switch (vice) {
    case 'Laziness & neglect':
      return [
        { id: 'a', kind: 'affirmation', text: 'I am a faithful steward of the time God gives me.' },
        { id: 'pre1', kind: 'precept', text: 'Small daily obedience outgrows sloth.', scripture: 'Proverbs 6:6-8' },
        { id: 'r', kind: 'reflection', text: 'What one good, small task can I do today?' },
        { id: 'p', kind: 'prayer', text: 'Lord, awaken diligence in me; teach my hands to work with love.' },
      ];
    case 'Recklessness & impulsiveness':
      return [
        { id: 'a', kind: 'affirmation', text: 'The Spirit gives me a sound mind and holy patience.' },
        { id: 'pre1', kind: 'precept', text: 'Pause, pray, and test desires before acting.', scripture: 'Proverbs 19:2' },
        { id: 'r', kind: 'reflection', text: 'Where can I wait on God instead of rushing ahead?' },
        { id: 'p', kind: 'prayer', text: 'Father, slow my impulses and align my will with Yours.' },
      ];
    case 'Ingratitude & entitlement':
      return [
        { id: 'a', kind: 'affirmation', text: 'Every good gift comes from the Father; I respond with thanks.' },
        { id: 'pre1', kind: 'precept', text: 'Practice daily thanksgiving to uproot entitlement.', scripture: '1 Thessalonians 5:18' },
        { id: 'r', kind: 'reflection', text: 'Name three undeserved graces I received this week.' },
        { id: 'p', kind: 'prayer', text: 'Lord, give me a grateful heart that honors Your generosity.' },
      ];
    case 'Fear & cowardice':
      return [
        { id: 'a', kind: 'affirmation', text: 'Perfect love drives out fear; I walk in courage.' },
        { id: 'pre1', kind: 'precept', text: 'Courage grows when trusting the presence of God.', scripture: 'Joshua 1:9' },
        { id: 'r', kind: 'reflection', text: 'Where am I hiding from obedience because of fear?' },
        { id: 'p', kind: 'prayer', text: 'Spirit, strengthen me to do the hard good You ask today.' },
      ];
    case 'Vanity & elitism':
      return [
        { id: 'a', kind: 'affirmation', text: 'My worth is in Christ, not comparison.' },
        { id: 'pre1', kind: 'precept', text: 'Seek humility and service over display.', scripture: 'Philippians 2:3' },
        { id: 'r', kind: 'reflection', text: 'Who can I quietly serve with no recognition?' },
        { id: 'p', kind: 'prayer', text: 'Jesus, form humility in me and free me from self-display.' },
      ];
    case 'Addiction to novelty':
      return [
        { id: 'a', kind: 'affirmation', text: 'I receive joy in steady faithfulness, not constant novelty.' },
        { id: 'pre1', kind: 'precept', text: 'Stability is fertile soil for growth.', scripture: 'Galatians 6:9' },
        { id: 'r', kind: 'reflection', text: 'What daily rhythm can anchor me in God today?' },
        { id: 'p', kind: 'prayer', text: 'Lord, root me in Your unchanging goodness.' },
      ];
    case 'Legalism & isolation':
      return [
        { id: 'a', kind: 'affirmation', text: 'Grace teaches me to walk in truth and love.' },
        { id: 'pre1', kind: 'precept', text: 'Truth without love becomes a cage; love fulfills the law.', scripture: 'Galatians 5:14' },
        { id: 'r', kind: 'reflection', text: 'Where do I need to receive grace or extend fellowship?' },
        { id: 'p', kind: 'prayer', text: 'Father, soften my heart and join me to Your people.' },
      ];
    case 'Manipulation & ego-driven ambition':
      return [
        { id: 'a', kind: 'affirmation', text: 'I seek God’s will and others’ good over self-advancement.' },
        { id: 'pre1', kind: 'precept', text: 'Ambition is purified in service, not control.', scripture: 'Mark 10:43-45' },
        { id: 'r', kind: 'reflection', text: 'How can I advance another person’s calling today?' },
        { id: 'p', kind: 'prayer', text: 'Lord, remove self-seeking and make me a servant.' },
      ];
    default:
      return [
        { id: 'a', kind: 'affirmation', text: 'God is making me whole in Christ.' },
        { id: 'pre1', kind: 'precept', text: 'Return daily to prayer, scripture, and obedience.' },
        { id: 'r', kind: 'reflection', text: 'What one faithful step can I take today?' },
        { id: 'p', kind: 'prayer', text: 'Lord, guide me in truth and love today.' },
      ];
  }
}
