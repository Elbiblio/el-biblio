import '../domain/models/faith_quiz_level.dart';

class FaithQuizLevelCatalog {
  const FaithQuizLevelCatalog._();

  static FaithQuizLevel getLevel(int level) {
    return allLevels.firstWhere((l) => l.level == level);
  }

  static const allLevels = <FaithQuizLevel>[
    // ── Foundational (Levels 1-3, difficulty 1-2) ─────────────────────
    FaithQuizLevel(
      level: 1,
      title: 'First Steps',
      description: 'Core basics every Christian should know',
      requiredCorrect: 7,
      questionIds: [
        'theo_04', // Who is the Holy Spirit (d1)
        'daily_01', // How should I pray (d1)
        'daily_05', // Personal relationship with God (d1)
        'daily_03', // Why read the Bible (d1)
        'sci_05',  // Faith and reason (d1)
        'hist_02', // Early church (d1)
        'hist_03', // Was Jesus real (d1)
        'theo_01', // Trinity (d2)
        'theo_02', // Grace vs works (d2)
        'suf_03',  // Finding God in suffering (d2)
      ],
      xpReward: 25,
    ),
    FaithQuizLevel(
      level: 2,
      title: 'Growing Roots',
      description: 'Building on the basics of Christian faith',
      requiredCorrect: 7,
      questionIds: [
        'daily_02', // Discerning God\'s will (d2)
        'daily_04', // Dealing with doubt (d2)
        'mor_02',   // Forgiveness (d2)
        'mor_03',   // Is anger wrong (d2)
        'mor_04',   // Bible and justice (d2)
        'hist_01',  // Bible reliability (d2)
        'sci_03',   // Big Bang (d2)
        'sci_04',   // Dinosaurs (d2)
        'theo_01',  // Trinity (d2)
        'suf_03',   // Finding God in suffering (d2)
      ],
      xpReward: 30,
    ),
    FaithQuizLevel(
      level: 3,
      title: 'Solid Ground',
      description: 'Deeper understanding of foundational truths',
      requiredCorrect: 7,
      questionIds: [
        'theo_02',  // Grace vs works (d2)
        'daily_01', // How to pray (d1)
        'hist_02',  // Early church (d1)
        'sci_05',   // Faith and reason (d1)
        'mor_02',   // Forgiveness (d2)
        'daily_04', // Dealing with doubt (d2)
        'hist_01',  // Bible reliability (d2)
        'mor_04',   // Bible and justice (d2)
        'sci_04',   // Dinosaurs (d2)
        'daily_05', // Personal relationship (d1)
      ],
      xpReward: 35,
    ),

    // ── Intermediate (Levels 4-6, difficulty 2-3) ─────────────────────
    FaithQuizLevel(
      level: 4,
      title: 'Pressing Deeper',
      description: 'Tackling harder questions about faith and life',
      requiredCorrect: 7,
      questionIds: [
        'suf_01',  // Why God allows suffering (d3)
        'suf_04',  // If God is good why evil (d3)
        'suf_05',  // Natural disasters (d3)
        'sci_01',  // Evolution (d3)
        'sci_02',  // Miracles (d3)
        'theo_05', // What happens when we die (d3)
        'mor_01',  // Absolute morality (d3)
        'hist_04', // Bible canon (d3)
        'daily_02', // Discerning God\'s will (d2)
        'mor_03',  // Is anger wrong (d2)
      ],
      xpReward: 40,
    ),
    FaithQuizLevel(
      level: 5,
      title: 'Faith Under Fire',
      description: 'Questions skeptics ask most often',
      requiredCorrect: 7,
      questionIds: [
        'sci_02',  // Miracles (d3)
        'suf_01',  // Why suffering (d3)
        'suf_04',  // Problem of evil (d3)
        'hist_04', // Bible canon (d3)
        'sci_01',  // Evolution (d3)
        'mor_01',  // Absolute morality (d3)
        'theo_05', // After death (d3)
        'suf_05',  // Natural disasters (d3)
        'hist_01', // Bible reliability (d2)
        'sci_03',  // Big Bang (d2)
      ],
      xpReward: 45,
    ),
    FaithQuizLevel(
      level: 6,
      title: 'Apologetics Basics',
      description: 'Defending the faith with reason and grace',
      requiredCorrect: 7,
      questionIds: [
        'sci_01',  // Evolution (d3)
        'sci_02',  // Miracles (d3)
        'sci_03',  // Big Bang (d2)
        'hist_03', // Was Jesus real (d1)
        'hist_04', // Bible canon (d3)
        'hist_01', // Bible reliability (d2)
        'suf_04',  // Problem of evil (d3)
        'mor_01',  // Absolute morality (d3)
        'sci_05',  // Faith and reason (d1)
        'theo_05', // After death (d3)
      ],
      xpReward: 50,
    ),

    // ── Advanced (Levels 7-8, difficulty 3-4) ─────────────────────────
    FaithQuizLevel(
      level: 7,
      title: 'Deep Waters',
      description: 'Complex theological and ethical questions',
      requiredCorrect: 7,
      questionIds: [
        'theo_03', // Predestination (d4)
        'suf_02',  // Innocent children suffering (d4)
        'mor_05',  // Death penalty (d4)
        'hist_05', // Crusades (d4)
        'suf_01',  // Why suffering (d3)
        'suf_04',  // Problem of evil (d3)
        'sci_01',  // Evolution (d3)
        'mor_01',  // Absolute morality (d3)
        'theo_05', // After death (d3)
        'hist_04', // Bible canon (d3)
      ],
      xpReward: 60,
    ),
    FaithQuizLevel(
      level: 8,
      title: 'Wrestling with God',
      description: 'The hardest questions faith demands we face',
      requiredCorrect: 7,
      questionIds: [
        'suf_02',  // Innocent children (d4)
        'theo_03', // Predestination (d4)
        'hist_05', // Crusades (d4)
        'mor_05',  // Death penalty (d4)
        'suf_05',  // Natural disasters (d3)
        'suf_01',  // Why suffering (d3)
        'sci_02',  // Miracles (d3)
        'mor_01',  // Absolute morality (d3)
        'suf_04',  // Problem of evil (d3)
        'theo_05', // After death (d3)
      ],
      xpReward: 70,
    ),

    // ── Scholar (Levels 9-10, difficulty 4-5) ─────────────────────────
    FaithQuizLevel(
      level: 9,
      title: 'Scholar\'s Challenge',
      description: 'Mastery of the most difficult faith questions',
      requiredCorrect: 7,
      questionIds: [
        'theo_03', // Predestination (d4)
        'suf_02',  // Innocent children (d4)
        'mor_05',  // Death penalty (d4)
        'hist_05', // Crusades (d4)
        'suf_04',  // Problem of evil (d3)
        'sci_01',  // Evolution (d3)
        'sci_02',  // Miracles (d3)
        'hist_04', // Bible canon (d3)
        'suf_01',  // Why suffering (d3)
        'mor_01',  // Absolute morality (d3)
      ],
      xpReward: 80,
    ),
    FaithQuizLevel(
      level: 10,
      title: 'Master Theologian',
      description: 'The ultimate faith knowledge challenge',
      requiredCorrect: 8,
      questionIds: [
        'theo_03', // Predestination (d4)
        'suf_02',  // Innocent children (d4)
        'mor_05',  // Death penalty (d4)
        'hist_05', // Crusades (d4)
        'suf_04',  // Problem of evil (d3)
        'suf_01',  // Why suffering (d3)
        'suf_05',  // Natural disasters (d3)
        'sci_01',  // Evolution (d3)
        'sci_02',  // Miracles (d3)
        'theo_05', // After death (d3)
      ],
      xpReward: 100,
    ),
  ];
}
