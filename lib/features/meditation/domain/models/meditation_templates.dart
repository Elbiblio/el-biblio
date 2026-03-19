/// Templates for Bible meditation style
enum BibleTemplate {
  parables('Parables', 'Stories Jesus told to teach spiritual truths'),
  profoundVerses('Daily Nuggets', 'Deep spiritual truths in single verses'),
  blessedProverbs('Blessed Proverbs', 'Virtues and rewards from Proverbs'),
  psalmsOfComfort('Psalms of Comfort', 'Songs that steady the heart with God\'s presence'),
  promisesOfHope('Promises of Hope', 'Declarations of God\'s faithfulness in every season'),
  miraclesOfJesus('Miracles of Jesus', 'Encounters where Jesus restores, heals, and provides'),
  kingdomEthics('Kingdom Ethics', 'Teachings that reframe how we love, forgive, and serve'),
  lettersOfEncouragement('Letters of Encouragement', 'Pauline and general epistles that strengthen perseverance'),
  custom('Custom', 'Choose your own Bible verses');

  const BibleTemplate(this.label, this.description);
  final String label;
  final String description;
}

/// Categories for Affirmation meditation style
enum AffirmationCategory {
  growVirtue('Grow a Virtue', 'Cultivate positive spiritual qualities'),
  stopHabit('Stop a Bad Habit', 'Overcome negative patterns through grace');

  const AffirmationCategory(this.label, this.description);
  final String label;
  final String description;
}

/// Specific affirmation templates for growing virtues
enum VirtueAffirmation {
  selfControl('Control over Senses', 'I am growing in self-control by the grace of God.'),
  humility('Humility - Others First', 'I realize everyone around me is part of the struggle of life and needs my support and patience to get through life.'),
  compassion('Compassion', 'My heart mirrors Christ\'s tenderness, seeing every person with mercy.'),
  courage('Holy Courage', 'With the Spirit\'s strength I take faithful risks even when I feel small.'),
  gratitude('Gratitude', 'I rehearse God\'s goodness and let thankfulness reshape my outlook.'),
  patience('Patient Endurance', 'I wait without resentment because God\'s timing is kind and intentional.'),
  hope('Living Hope', 'My confidence rests in God\'s promises, not in what I can control.'),
  faithfulness('Faithfulness', 'I show up with consistency, offering my best and trusting God with the rest.'),
  joy('Joy', 'I welcome holy joy into ordinary moments because the Lord delights over me.');

  const VirtueAffirmation(this.title, this.text);
  final String title;
  final String text;
}

/// Specific affirmation templates for stopping bad habits
enum HabitAffirmation {
  lust('Lust', 'I recognize the apple of the garden in all sexual allures of life and by the grace of God, I choose eternal life over carnal knowledge every single time.'),
  anger('Anger', 'I realize that God is love and that no man is without sin but by the grace of God. I therefore choose mercy over justice whenever I can.'),
  fear('Fear', 'Perfect love casts out the fear that tries to shrink my life—I breathe in God\'s courage.'),
  comparison('Comparison', 'I release jealousy and celebrate that God\'s story for me is already blessed.'),
  complaining('Complaining', 'I trade grumbling for gratitude, choosing to speak life over every situation.'),
  pride('Pride', 'I lay down the need to be first and gladly honor others above myself.'),
  procrastination('Procrastination', 'I respond promptly to God\'s invitations and steward today with diligence.'),
  escapism('Escapism', 'I stop running from discomfort and invite Jesus to meet me right where I am.'),
  resentment('Resentment', 'I refuse to rehearse old wounds and instead practice forgiveness as a daily rhythm.');

  const HabitAffirmation(this.title, this.text);
  final String title;
  final String text;
}
