class ClarityCopy {
  ClarityCopy._();

  // Navigation
  static const reflectTabLabel = 'Pray';
  static const spiritualToolsHeader = 'Your Support Hub';

  // Today Dashboard
  static String greeting(String name, String timeOfDay) =>
      'Good $timeOfDay, $name. Walk with God in clarity today.';
  static const dailyProgressLabel = 'Clarity Score';
  static const dailyVerseLabel = "Today's Clarity Verse";

  // Empty states
  static const emptyCommitment = 'Choose your first clarity commitment.';
  static String emptyCommitmentWithArchetype(
    String archetype,
    String category,
  ) => 'Your $archetype identity suggests starting with $category.';
  static const emptyJournal = 'Your story of clarity is waiting to be written.';
  static const emptyGames =
      "Learn God's word through play. Every game brings you closer to clarity.";
  static const emptyMeditation =
      'Pause for prayer. Even two quiet minutes can return your heart to God.';

  // Need help
  static String needHelpWithArchetype(String archetype, String distraction) =>
      'Feeling distracted? Your $archetype tends to struggle with $distraction. Try a Soul Care session.';
  static const needHelpGeneric =
      'Feeling overwhelmed? Take two quiet minutes with Scripture and prayer.';

  // General
  static const clarityJourneyStart = 'Begin with God in clarity.';
  static const fourPillarsTitle = 'Your Four Pillars of Clarity';

  // Games Hub
  static const gamesHubTitle = 'Scripture Games';
  static const gamesHubSubtitle =
      "Learn God's word through play. Every game brings you closer to clarity.";
  static const faithQuestionsTitle = 'Faith Questions';
  static const faithQuestionsSubtitle =
      'Bring honest questions to Scripture and seek God with clarity.';

  // Alignment
  static const alignmentHubTitle = 'Spiritual Alignment';
  static const alignmentHubSubtitle =
      'Discover how your God-given identity shapes your calling and career.';

  // Commitments
  static const commitmentJourneyTitle = 'Spiritual Commitments';
  static const commitmentJourneySubtitle =
      'Build spiritual habits across three tracks: Prayer, Scripture, and Service.';
}
