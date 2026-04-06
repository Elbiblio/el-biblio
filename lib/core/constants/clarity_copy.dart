class ClarityCopy {
  ClarityCopy._();

  // Navigation
  static const reflectTabLabel = 'Pray';
  static const spiritualToolsHeader = 'Your Support Hub';

  // Today Dashboard
  static String greeting(String name, String timeOfDay) =>
      'Good $timeOfDay, $name. Your clarity journey continues.';
  static const dailyProgressLabel = 'Clarity Score';
  static const dailyVerseLabel = "Today's Clarity Verse";

  // Empty states
  static const emptyCommitment = 'Choose your first clarity commitment.';
  static String emptyCommitmentWithArchetype(
          String archetype, String category) =>
      'Your $archetype identity suggests starting with $category.';
  static const emptyJournal =
      'Your story of clarity is waiting to be written.';
  static const emptyGames =
      "Learn God's word through play. Every game brings you closer to clarity.";
  static const emptyMeditation =
      'Take a moment to breathe. Even 2 minutes of stillness can change your day.';

  // Need help
  static String needHelpWithArchetype(
          String archetype, String distraction) =>
      'Feeling distracted? Your $archetype tends to struggle with $distraction. Try a Soul Care session.';
  static const needHelpGeneric =
      'Feeling overwhelmed? Take a Soul Care break — 2 minutes of Scripture and breathing.';

  // General
  static const clarityJourneyStart = 'Your clarity journey starts now.';
  static const fourPillarsTitle = 'Your Four Pillars of Clarity';

  // Games Hub
  static const gamesHubTitle = 'Scripture Games';
  static const gamesHubSubtitle =
      "Learn God's word through play. Every game brings you closer to clarity.";
  static const faithQuestionsTitle = 'Faith Questions';
  static const faithQuestionsSubtitle =
      'Explore the deep questions of faith and find clarity in Scripture.';

  // Alignment
  static const alignmentHubTitle = 'Spiritual Alignment';
  static const alignmentHubSubtitle =
      'Discover how your God-given identity shapes your calling and career.';

  // Commitments
  static const commitmentJourneyTitle = 'Clarity Commitments';
  static const commitmentJourneySubtitle =
      'Build spiritual habits across three tracks: Prayer, Scripture, and Service.';
}
