import '../domain/models/archetype.dart';
import '../domain/models/calling_profile.dart';
import '../domain/models/weekly_plan.dart';

/// Service that synthesizes archetype and assessment data into
/// a structured calling profile and weekly plan.
class CallingProfileService {
  CallingProfileService();

  /// Generate a calling profile from archetype and onboarding data
  CallingProfile generateProfile({
    required Archetype archetype,
    required String commitmentCategory,
    required String missionFocus,
    required List<String> personalDistractions,
  }) {
    return CallingProfile(
      archetypeId: archetype.name,
      archetypeIdentity: archetype.identity,
      weeklyPriorities: _generateWeeklyPriorities(
        archetype,
        commitmentCategory,
      ),
      burdensAndServiceTendencies: _generateBurdensAndServiceTendencies(
        archetype,
        missionFocus,
      ),
      growthRisks: _generateGrowthRisks(archetype),
      relationalFocus: _generateRelationalFocus(archetype),
      recommendedPractices: _generateRecommendedPractices(
        archetype,
        commitmentCategory,
      ),
      personalDistractions: personalDistractions,
      commitmentCategory: commitmentCategory,
      missionFocus: missionFocus,
      createdAt: DateTime.now(),
    );
  }

  /// Generate a weekly plan from a calling profile
  WeeklyPlan generateWeeklyPlan({
    required CallingProfile profile,
    required DateTime weekStart,
    required String morningTime,
    required String eveningTime,
  }) {
    return WeeklyPlan(
      id: WeeklyPlan.generateId(weekStart),
      callingProfileId: '${profile.archetypeId}_${profile.createdAt.millisecondsSinceEpoch}',
      weekStart: weekStart,
      dailyAnchors: _generateDailyAnchors(
        profile,
        morningTime,
        eveningTime,
      ),
      weeklyCommitments: _generateWeeklyCommitments(profile),
      missionFocusForWeek: profile.missionFocus,
      accountabilityFocus: _generateAccountabilityFocus(profile),
      reflectionPrompt: _generateReflectionPrompt(profile),
      createdAt: DateTime.now(),
    );
  }

  /// Generate weekly priorities based on archetype and commitment category
  List<WeeklyPriority> _generateWeeklyPriorities(
    Archetype archetype,
    String commitmentCategory,
  ) {
    final priorities = <WeeklyPriority>[];

    // Add archetype-specific priority
    priorities.add(WeeklyPriority(
      area: _getArchetypePriorityArea(archetype.name),
      focus: _getArchetypePriorityFocus(archetype.name),
      suggestedActions: _getArchetypePriorityActions(archetype.name, commitmentCategory),
    ));

    // Add commitment category priority
    priorities.add(_getCommitmentPriority(commitmentCategory));

    // Add distraction management priority if distractions exist
    priorities.add(const WeeklyPriority(
      area: 'Freedom from Distractions',
      focus: 'Address personal distractions with grace',
      suggestedActions: [
        'Identify your trigger moments this week',
        'Practice the pause before giving in',
        'Replace the distraction with a brief prayer',
      ],
    ));

    return priorities;
  }

  /// Generate burdens and service tendencies
  List<String> _generateBurdensAndServiceTendencies(
    Archetype archetype,
    String missionFocus,
  ) {
    final tendencies = <String>[];

    // Archetype-specific burdens
    switch (archetype.name) {
      case 'Healer':
        tendencies.addAll(['Emotional pain in others', 'Mental health awareness', 'Addiction recovery']);
        break;
      case 'Welcomer':
        tendencies.addAll(['Loneliness and isolation', 'Newcomers and outsiders', 'Community belonging']);
        break;
      case 'Reformer':
        tendencies.addAll(['Injustice and systemic issues', 'Truth in culture', 'Institutional integrity']);
        break;
      case 'Cultivator':
        tendencies.addAll(['Long-term growth', 'Mentorship', 'Sustainable systems']);
        break;
      case 'Sower':
        tendencies.addAll(['New initiatives', 'Evangelism', 'Innovation in ministry']);
        break;
      case 'Architect':
        tendencies.addAll(['Building lasting structures', 'Strategic planning', 'Organizational health']);
        break;
      case 'Watchman':
        tendencies.addAll(['Spiritual protection', 'Intercession', 'Discernment']);
        break;
      case 'Sentinel':
        tendencies.addAll(['Hidden spiritual battles', 'Prayer warfare', 'Prophetic insight']);
        break;
      case 'Bridgebuilder':
        tendencies.addAll(['Reconciliation', 'Cross-cultural connection', 'Peacemaking']);
        break;
      case 'Pillar':
        tendencies.addAll(['Faithful support', 'Behind-the-scenes service', 'Reliability']);
        break;
      case 'Artisan':
        tendencies.addAll(['Creative expression for God', 'Beauty in worship', 'Artistic mentorship']);
        break;
      case 'Harvester':
        tendencies.addAll(['Results and fruitfulness', 'Mobilization', 'Celebration of progress']);
        break;
    }

    // Mission focus specific additions
    switch (missionFocus) {
      case 'service':
        tendencies.add('Practical acts of kindness');
        break;
      case 'faithSharing':
        tendencies.add('Sharing your faith story');
        break;
      case 'encouragement':
        tendencies.add('Building others up');
        break;
    }

    return tendencies;
  }

  /// Generate growth risks based on archetype distortions
  List<String> _generateGrowthRisks(Archetype archetype) {
    final risks = <String>[];

    // Parse distortions into specific risks
    final distortions = archetype.distortions.split(';');
    for (final distortion in distortions) {
      final trimmed = distortion.trim();
      if (trimmed.isNotEmpty) {
        risks.add(trimmed);
      }
    }

    // Add archetype-specific growth risks
    switch (archetype.name) {
      case 'Artisan':
        risks.add('Chasing novelty instead of depth');
        risks.add('Seeking validation through creative output');
        break;
      case 'Watchman':
        risks.add('Becoming judgmental instead of discerning');
        risks.add('Isolation under the guise of vigilance');
        break;
      case 'Healer':
        risks.add('Savior complex and burnout');
        risks.add('Neglecting your own healing');
        break;
      case 'Sower':
        risks.add('Starting but not finishing');
        risks.add('Impulsivity without wisdom');
        break;
      case 'Welcomer':
        risks.add('People-pleasing and boundary loss');
        risks.add('Avoiding necessary conflict');
        break;
      case 'Pillar':
        risks.add('Enabling instead of supporting');
        risks.add('Resentment from lack of recognition');
        break;
      case 'Cultivator':
        risks.add('Overcontrol and resistance to change');
        risks.add('Burnout from over-responsibility');
        break;
      case 'Reformer':
        risks.add('Bitterness and cynicism');
        risks.add('Tearing down without building up');
        break;
      case 'Architect':
        risks.add('Rigidity and perfectionism');
        risks.add('Control as a substitute for trust');
        break;
      case 'Harvester':
        risks.add('Metrics obsession and superficiality');
        risks.add('Exploiting relationships for results');
        break;
      case 'Sentinel':
        risks.add('Pride in spiritual insight');
        risks.add('Isolation disguised as contemplation');
        break;
      case 'Bridgebuilder':
        risks.add('Compromising truth for peace');
        risks.add('Losing your identity in others');
        break;
    }

    return risks;
  }

  /// Generate relational focus areas
  List<String> _generateRelationalFocus(Archetype archetype) {
    final focus = <String>[];

    switch (archetype.name) {
      case 'Healer':
        focus.addAll(['One-on-one presence', 'Listening without fixing', 'Walking with pain']);
        break;
      case 'Welcomer':
        focus.addAll(['Creating belonging', 'Hospitality', 'Including outsiders']);
        break;
      case 'Reformer':
        focus.addAll(['Speaking truth in love', 'Institutional engagement', 'Mentoring changemakers']);
        break;
      case 'Cultivator':
        focus.addAll(['Long-term mentorship', 'Patient investment', 'Nurturing potential']);
        break;
      case 'Sower':
        focus.addAll(['Inspiring others', 'Casting vision', 'Mobilizing initiative']);
        break;
      case 'Architect':
        focus.addAll(['Building systems', 'Strategic partnerships', 'Multiplying impact']);
        break;
      case 'Watchman':
        focus.addAll(['Intercessory prayer', 'Protective covering', 'Spiritual discernment for others']);
        break;
      case 'Sentinel':
        focus.addAll(['Sharing spiritual insights', 'Prayer partnerships', 'Prophetic encouragement']);
        break;
      case 'Bridgebuilder':
        focus.addAll(['Reconciliation', 'Cross-cultural connection', 'Peacemaking']);
        break;
      case 'Pillar':
        focus.addAll(['Faithful support', 'Behind-the-scenes encouragement', 'Reliability in relationships']);
        break;
      case 'Artisan':
        focus.addAll(['Creative collaboration', 'Artistic mentorship', 'Beauty as ministry']);
        break;
      case 'Harvester':
        focus.addAll(['Celebrating others', 'Mobilizing for results', 'Team leadership']);
        break;
    }

    return focus;
  }

  /// Generate recommended practices based on archetype and commitment category
  List<RecommendedPractice> _generateRecommendedPractices(
    Archetype archetype,
    String commitmentCategory,
  ) {
    final practices = <RecommendedPractice>[];

    // Add archetype-specific practices from commitments
    for (final commitment in archetype.growthCommitments) {
      practices.add(RecommendedPractice(
        name: _extractPracticeName(commitment),
        description: commitment,
        frequency: 'daily',
        category: 'growth',
      ));
    }

    for (final commitment in archetype.disciplineCommitments) {
      practices.add(RecommendedPractice(
        name: _extractPracticeName(commitment),
        description: commitment,
        frequency: 'daily',
        category: 'discipline',
      ));
    }

    // Filter and add charity commitments based on category
    if (commitmentCategory == 'charity') {
      for (final commitment in archetype.charityCommitments.take(2)) {
        practices.add(RecommendedPractice(
          name: _extractPracticeName(commitment),
          description: commitment,
          frequency: 'weekly',
          category: 'charity',
        ));
      }
    }

    return practices;
  }

  /// Generate daily anchors for morning and evening
  List<DailyAnchor> _generateDailyAnchors(
    CallingProfile profile,
    String morningTime,
    String eveningTime,
  ) {
    return [
      const DailyAnchor(
        timeOfDay: 'morning',
        practice: 'Scripture and Prayer',
        duration: 15,
        description: 'Start your day with Scripture reading and prayer.',
      ),
      const DailyAnchor(
        timeOfDay: 'evening',
        practice: 'Examen and Reflection',
        duration: 10,
        description: 'Review your day and notice God\'s presence.',
      ),
    ];
  }

  /// Generate weekly commitments from the calling profile
  List<WeeklyCommitment> _generateWeeklyCommitments(CallingProfile profile) {
    final commitments = <WeeklyCommitment>[];

    // Add one commitment per weekly priority
    for (final priority in profile.weeklyPriorities.take(3)) {
      commitments.add(WeeklyCommitment(
        id: WeeklyCommitment.generateId('focus', priority.area),
        type: 'focus',
        title: priority.area,
        description: priority.focus,
        targetCount: 7, // Daily attention
        currentCount: 0,
        category: profile.commitmentCategory,
      ));
    }

    // Add one practice commitment
    if (profile.recommendedPractices.isNotEmpty) {
      final practice = profile.recommendedPractices.first;
      commitments.add(WeeklyCommitment(
        id: WeeklyCommitment.generateId('practice', practice.name),
        type: 'practice',
        title: practice.name,
        description: practice.description,
        targetCount: practice.frequency == 'daily' ? 7 : 1,
        currentCount: 0,
        category: practice.category,
      ));
    }

    return commitments;
  }

  /// Generate accountability focus for the week
  String _generateAccountabilityFocus(CallingProfile profile) {
    switch (profile.commitmentCategory) {
      case 'charity':
        return 'Share one act of service with your accountability partner';
      case 'discipline':
        return 'Check in on your distraction management';
      case 'growth':
        return 'Share one insight from your Scripture reading';
      default:
        return 'Share your progress on weekly commitments';
    }
  }

  /// Generate a reflection prompt for the week
  String _generateReflectionPrompt(CallingProfile profile) {
    return 'Reflect on your ${profile.archetypeIdentity} identity this week. What did you notice about your growth?';
  }

  // Helper methods

  String _getArchetypePriorityArea(String archetype) {
    switch (archetype) {
      case 'Artisan':
        return 'Creative Expression';
      case 'Watchman':
      case 'Sentinel':
        return 'Spiritual Vigilance';
      case 'Healer':
        return 'Compassionate Presence';
      case 'Sower':
        return 'Initiative and Faith';
      case 'Welcomer':
        return 'Hospitality and Belonging';
      case 'Pillar':
        return 'Faithful Support';
      case 'Cultivator':
        return 'Long-term Growth';
      case 'Reformer':
        return 'Justice and Truth';
      case 'Architect':
        return 'Building and Structure';
      case 'Harvester':
        return 'Fruitfulness and Results';
      case 'Bridgebuilder':
        return 'Reconciliation and Connection';
      default:
        return 'Spiritual Growth';
    }
  }

  String _getArchetypePriorityFocus(String archetype) {
    switch (archetype) {
      case 'Artisan':
        return 'Set aside time for creative work';
      case 'Watchman':
        return 'Pray specifically for someone\'s protection';
      case 'Sentinel':
        return 'Practice listening in silence';
      case 'Healer':
        return 'Spend time with someone who is struggling';
      case 'Sower':
        return 'Start one new initiative';
      case 'Welcomer':
        return 'Reach out to someone new';
      case 'Pillar':
        return 'Support someone quietly';
      case 'Cultivator':
        return 'Focus on one area of growth';
      case 'Reformer':
        return 'Address one injustice constructively';
      case 'Architect':
        return 'Build one thing with excellence and patience';
      case 'Harvester':
        return 'Celebrate what God has already done';
      case 'Bridgebuilder':
        return 'Connect two people';
      default:
        return 'Focus on spiritual growth';
    }
  }

  List<String> _getArchetypePriorityActions(String archetype, String category) {
    final baseActions = <String>[];

    switch (archetype) {
      case 'Artisan':
        baseActions.addAll(['Create for 30 minutes without interruption', 'Study a master artist\'s faith']);
        break;
      case 'Watchman':
        baseActions.addAll(['Pray for protection over your family', 'Limit news to 15 minutes']);
        break;
      case 'Sentinel':
        baseActions.addAll(['Spend 30 minutes in silent listening', 'Share one insight with someone']);
        break;
      case 'Healer':
        baseActions.addAll(['Pray for yourself before others', 'Sit with someone without trying to fix']);
        break;
      case 'Sower':
        baseActions.addAll(['Finish one thing before starting another', 'Pray about your motives']);
        break;
      case 'Welcomer':
        baseActions.addAll(['Say no to one request', 'Spend 10 minutes alone with God']);
        break;
      case 'Pillar':
        baseActions.addAll(['Serve someone without credit', 'Take 30 minutes for your own calling']);
        break;
      case 'Cultivator':
        baseActions.addAll(['Trust God with one control area', 'Take a 30-minute rest break']);
        break;
      case 'Reformer':
        baseActions.addAll(['Pray for a leader you criticize', 'Do one constructive act']);
        break;
      case 'Architect':
        baseActions.addAll(['Do one thing imperfectly', 'Fast from planning for 2 hours']);
        break;
      case 'Harvester':
        baseActions.addAll(['Celebrate someone else\'s success', 'Take a full Sabbath']);
        break;
      case 'Bridgebuilder':
        baseActions.addAll(['Connect two people', 'Spend time alone remembering your identity']);
        break;
    }

    // Add category-specific action
    switch (category) {
      case 'charity':
        baseActions.add('Serve someone in need this week');
        break;
      case 'discipline':
        baseActions.add('Practice one fast from a distraction');
        break;
      case 'growth':
        baseActions.add('Study Scripture on your identity');
        break;
    }

    return baseActions;
  }

  WeeklyPriority _getCommitmentPriority(String category) {
    switch (category) {
      case 'charity':
        return const WeeklyPriority(
          area: 'Acts of Service',
          focus: 'Serve others as an expression of love',
          suggestedActions: [
            'Perform one act of kindness daily',
            'Look for opportunities to serve in your routine',
            'Pray for those you serve',
          ],
        );
      case 'discipline':
        return const WeeklyPriority(
          area: 'Spiritual Discipline',
          focus: 'Build habits that strengthen your walk',
          suggestedActions: [
            'Practice one daily discipline consistently',
            'Identify and address one distraction',
            'Create boundaries that protect your time with God',
          ],
        );
      case 'growth':
      default:
        return const WeeklyPriority(
          area: 'Personal Growth',
          focus: 'Deepen your understanding of God and yourself',
          suggestedActions: [
            'Study Scripture for 20 minutes daily',
            'Journal about your spiritual journey',
            'Learn from a mentor or resource',
          ],
        );
    }
  }

  String _extractPracticeName(String commitment) {
    // Extract first few words as a name
    final words = commitment.split(' ').take(3).join(' ');
    return words.length > 30 ? '${words.substring(0, 30)}...' : words;
  }
}
