import '../domain/models/daily_anchors.dart';
import '../domain/models/mood.dart';

class ActionableAction {
  const ActionableAction({
    required this.title,
    required this.description,
    required this.timeRequired,
    required this.context,
    required this.canDoNow,
  });

  final String title;
  final String description;
  final int timeRequired; // in seconds
  final String context;
  final bool canDoNow;

  ActionableAction copyWith({
    String? title,
    String? description,
    int? timeRequired,
    String? context,
    bool? canDoNow,
  }) {
    return ActionableAction(
      title: title ?? this.title,
      description: description ?? this.description,
      timeRequired: timeRequired ?? this.timeRequired,
      context: context ?? this.context,
      canDoNow: canDoNow ?? this.canDoNow,
    );
  }
}

class ActionableIntelligence {
  static ActionableAction getCurrentAction({
    required VirtueType virtueType,
    required MoodType? moodType,
    required TimeContext timeContext,
  }) {
    final mood = moodType ?? MoodType.neutral;

    // Spiritual mood actions - flow from spirit, not work
    final spiritualActions = {
      MoodType.peaceful: {
        TimeContext.morning: const ActionableAction(
          title: 'Begin day with peaceful presence',
          description: 'Take 3 deep breaths and surrender today to God',
          timeRequired: 30,
          context: 'Perfect time for morning presence',
          canDoNow: true,
        ),
        TimeContext.midday: const ActionableAction(
          title: 'Find peaceful moment in busy day',
          description: 'Pause for 2 minutes of quiet surrender',
          timeRequired: 120,
          context: 'During lunch break',
          canDoNow: true,
        ),
        TimeContext.evening: const ActionableAction(
          title: 'Peaceful reflection and gratitude',
          description: 'Review the day with thankful heart',
          timeRequired: 300,
          context: 'After work, before dinner',
          canDoNow: true,
        ),
        TimeContext.night: const ActionableAction(
          title: 'Peaceful surrender before sleep',
          description: 'Release today to God\'s care',
          timeRequired: 60,
          context: 'In bed, before sleep',
          canDoNow: true,
        ),
      },
      MoodType.thankful: {
        TimeContext.morning: const ActionableAction(
          title: 'Express gratitude for new day',
          description: 'Thank God for breath, life, and opportunity',
          timeRequired: 45,
          context: 'Before starting daily activities',
          canDoNow: true,
        ),
        TimeContext.midday: const ActionableAction(
          title: 'Pause to give thanks',
          description: 'Quick gratitude prayer during lunch',
          timeRequired: 120,
          context: 'During lunch break',
          canDoNow: true,
        ),
        TimeContext.evening: const ActionableAction(
          title: 'Count blessings and give thanks',
          description: 'Write down 3 things you\'re grateful for today',
          timeRequired: 180,
          context: 'After dinner, before evening activities',
          canDoNow: true,
        ),
        TimeContext.night: const ActionableAction(
          title: 'Thankful surrender',
          description: 'Thank God for His presence throughout the day',
          timeRequired: 60,
          context: 'In bed, before sleep',
          canDoNow: true,
        ),
      },
      MoodType.joyful: {
        TimeContext.morning: const ActionableAction(
          title: 'Start day with joyful praise',
          description: 'Sing or declare God\'s goodness with joy',
          timeRequired: 60,
          context: 'Before starting daily activities',
          canDoNow: true,
        ),
        TimeContext.midday: const ActionableAction(
          title: 'Find joy in present moment',
          description: 'Notice one beautiful thing and thank God',
          timeRequired: 90,
          context: 'During work breaks',
          canDoNow: true,
        ),
        TimeContext.evening: const ActionableAction(
          title: 'Celebrate God\'s goodness',
          description: 'Share one joyful moment with someone',
          timeRequired: 240,
          context: 'After work, during dinner conversation',
          canDoNow: true,
        ),
        TimeContext.night: const ActionableAction(
          title: 'Joyful rest',
          description: 'Rest in God\'s joy and peace',
          timeRequired: 60,
          context: 'In bed, before sleep',
          canDoNow: true,
        ),
      },
      MoodType.divine: {
        TimeContext.morning: const ActionableAction(
          title: 'Connect with divine presence',
          description: 'Meditate on God\'s wonder and mystery',
          timeRequired: 180,
          context: 'Before starting daily activities',
          canDoNow: true,
        ),
        TimeContext.midday: const ActionableAction(
          title: 'Notice God\'s presence in ordinary',
          description: 'Find divine fingerprint in something routine',
          timeRequired: 120,
          context: 'During daily activities',
          canDoNow: true,
        ),
        TimeContext.evening: const ActionableAction(
          title: 'Ponder divine mysteries',
          description: 'Reflect on God\'s love and grace today',
          timeRequired: 300,
          context: 'After work, in quiet time',
          canDoNow: true,
        ),
        TimeContext.night: const ActionableAction(
          title: 'Divine rest',
          description: 'Rest in God\'s mysterious presence',
          timeRequired: 90,
          context: 'In bed, before sleep',
          canDoNow: true,
        ),
      },
      MoodType.neutral: {
        TimeContext.morning: const ActionableAction(
          title: 'Set spiritual intention',
          description: 'Choose one virtue focus for today',
          timeRequired: 60,
          context: 'Before starting daily activities',
          canDoNow: true,
        ),
        TimeContext.midday: const ActionableAction(
          title: 'Check spiritual alignment',
          description: 'Quick review: are you aligned with your intention?',
          timeRequired: 90,
          context: 'During work breaks',
          canDoNow: true,
        ),
        TimeContext.evening: const ActionableAction(
          title: 'Review spiritual growth',
          description: 'Note one area of growth today',
          timeRequired: 180,
          context: 'After work, before evening activities',
          canDoNow: true,
        ),
        TimeContext.night: const ActionableAction(
          title: 'Prepare for tomorrow',
          description: 'Set intention for tomorrow\'s spiritual focus',
          timeRequired: 60,
          context: 'In bed, before sleep',
          canDoNow: true,
        ),
      },
      MoodType.struggling: {
        TimeContext.morning: const ActionableAction(
          title: 'Surrender struggles',
          description: 'Give your burdens to God before starting',
          timeRequired: 90,
          context: 'Before starting daily activities',
          canDoNow: true,
        ),
        TimeContext.midday: const ActionableAction(
          title: 'Release and find peace',
          description: 'Take 3 deep breaths and release one worry',
          timeRequired: 60,
          context: 'When feeling overwhelmed',
          canDoNow: true,
        ),
        TimeContext.evening: const ActionableAction(
          title: 'Let go of day\'s worries',
          description: 'Write down concerns and give them to God',
          timeRequired: 240,
          context: 'After work, before evening activities',
          canDoNow: true,
        ),
        TimeContext.night: const ActionableAction(
          title: 'Peaceful surrender',
          description: 'Release today\'s struggles to God\'s care',
          timeRequired: 90,
          context: 'In bed, before sleep',
          canDoNow: true,
        ),
      },
    };

    return spiritualActions[mood]?[timeContext] ??
        spiritualActions[MoodType.neutral]?[timeContext] ??
        const ActionableAction(
          title: 'Take a moment for presence',
          description: 'Pause, pray, and notice God\'s presence',
          timeRequired: 60,
          context: 'Right now',
          canDoNow: true,
        );
  }

  static List<UpcomingAction> getUpcomingActions({
    required VirtueType virtueType,
    required MoodType? moodType,
    required TimeContext currentTimeContext,
    String? journalTime,
  }) {
    final upcoming = <UpcomingAction>[];

    // Define standard time slots based on current time context
    final timeSlots = switch (currentTimeContext) {
      TimeContext.morning => [
        const TimeSlot('12:30 PM', 'Lunch Break'),
        const TimeSlot('6:00 PM', 'After Work'),
        TimeSlot(journalTime ?? '9:00 PM', 'Evening Reflection'),
      ],
      TimeContext.midday => [
        const TimeSlot('6:00 PM', 'After Work'),
        TimeSlot(journalTime ?? '9:00 PM', 'Evening Reflection'),
      ],
      TimeContext.evening => [
        TimeSlot(journalTime ?? '9:00 PM', 'Evening Reflection'),
      ],
      TimeContext.night => [const TimeSlot('7:30 AM', 'Tomorrow Morning')],
    };

    for (final slot in timeSlots) {
      upcoming.add(
        UpcomingAction(
          time: slot.time,
          context: slot.context,
          action: _getUpcomingActionForTime(virtueType, moodType, slot),
        ),
      );
    }

    return upcoming;
  }

  static String _getUpcomingActionForTime(
    VirtueType virtueType,
    MoodType? moodType,
    TimeSlot timeSlot,
  ) {
    final mood = moodType ?? MoodType.neutral;

    return switch (timeSlot.context) {
      'Lunch Break' => switch (mood) {
        MoodType.peaceful => 'Quick gratitude prayer',
        MoodType.thankful => 'Count blessings during meal',
        MoodType.joyful => 'Share joyful moment',
        MoodType.divine => 'Notice God\'s provision',
        MoodType.neutral => 'Spiritual check-in',
        MoodType.struggling => 'Release one worry',
      },
      'After Work' => switch (mood) {
        MoodType.peaceful => '10-minute intentional walk',
        MoodType.thankful => 'Thank someone for their help',
        MoodType.joyful => 'Celebrate day\'s blessings',
        MoodType.divine => 'Notice beauty in transition',
        MoodType.neutral => 'Review spiritual progress',
        MoodType.struggling => 'Let go of work stress',
      },
      'Evening' => switch (mood) {
        MoodType.peaceful => 'Evening reflection journal',
        MoodType.thankful => 'Write 3 gratitudes',
        MoodType.joyful => 'Share joy with family',
        MoodType.divine => 'Contemplate God\'s presence',
        MoodType.neutral => 'Plan tomorrow\'s focus',
        MoodType.struggling => 'Release day to God',
      },
      'Tomorrow Morning' => switch (mood) {
        MoodType.peaceful => 'Morning surrender prayer',
        MoodType.thankful => 'Thank God for new day',
        MoodType.joyful => 'Start with praise',
        MoodType.divine => 'Connect with divine presence',
        MoodType.neutral => 'Set spiritual intention',
        MoodType.struggling => 'Surrender tomorrow\'s concerns',
      },
      _ => 'Spiritual practice',
    };
  }
}

class TimeSlot {
  const TimeSlot(this.time, this.context);

  final String time;
  final String context;
}

class UpcomingAction {
  const UpcomingAction({
    required this.time,
    required this.context,
    required this.action,
  });

  final String time;
  final String context;
  final String action;
}
