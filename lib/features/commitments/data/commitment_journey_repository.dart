import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../domain/models/commitment_journey.dart';

/// Repository for managing commitment journeys with prayer intentions,
/// milestones, and daily progress tracking.
class CommitmentJourneyRepository {
  CommitmentJourneyRepository(this._logger);

  final Logger _logger;
  Box<String>? _box;

  static const _boxName = 'commitment_journeys';
  static const _activeJourneyKey = 'journey_active';
  static const _completedJourneysKey = 'journeys_completed';
  static const _partnerResponseKey = 'partner_response';

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  /// Get the currently active journey, if any.
  Future<ActiveJourney?> getActiveJourney() async {
    try {
      final box = await _getBox();
      final json = box.get(_activeJourneyKey);
      if (json == null || json.isEmpty) return null;

      final map = jsonDecode(json) as Map<String, dynamic>;
      return ActiveJourney.fromJson(map);
    } catch (e, st) {
      _logger.e('Error loading active journey', error: e, stackTrace: st);
      return null;
    }
  }

  /// Start a new journey with prayer intention.
  Future<ActiveJourney> startJourney({
    required String journeyId,
    required String prayerIntention,
  }) async {
    final journey = ActiveJourney(
      journeyId: journeyId,
      startedAt: DateTime.now(),
      prayerIntention: prayerIntention,
      currentDay: 1,
    );

    await _saveActiveJourney(journey);
    _logger.i('Started journey: $journeyId');
    return journey;
  }

  /// Check in for today - marks current day as completed.
  Future<ActiveJourney> checkInToday() async {
    final current = await getActiveJourney();
    if (current == null) throw StateError('No active journey');

    final updated = current.checkInToday();
    await _saveActiveJourney(updated);
    return updated;
  }

  /// Advance to the next day (called at midnight).
  Future<ActiveJourney> advanceDay() async {
    final current = await getActiveJourney();
    if (current == null) throw StateError('No active journey');

    final updated = current.advanceDay();
    await _saveActiveJourney(updated);
    return updated;
  }

  /// Mark a milestone as reached.
  Future<ActiveJourney> reachMilestone(int milestoneDay) async {
    final current = await getActiveJourney();
    if (current == null) throw StateError('No active journey');

    final updated = current.reachMilestone(milestoneDay);
    await _saveActiveJourney(updated);
    return updated;
  }

  /// Complete the journey and move to completed list.
  Future<void> completeJourney(String journeyId) async {
    final current = await getActiveJourney();
    if (current == null || current.journeyId != journeyId) {
      throw StateError('Journey mismatch');
    }

    // Add to completed list
    final completed = await getCompletedJourneys();
    completed.add(current);
    await _saveCompletedJourneys(completed);

    // Clear active journey
    final box = await _getBox();
    await box.delete(_activeJourneyKey);
  }

  /// Abandon the current journey.
  Future<void> abandonJourney(String journeyId) async {
    final current = await getActiveJourney();
    if (current == null || current.journeyId != journeyId) return;

    final box = await _getBox();
    await box.delete(_activeJourneyKey);
    _logger.i('Abandoned journey: $journeyId');
  }

  /// Get all completed journeys.
  Future<List<ActiveJourney>> getCompletedJourneys() async {
    try {
      final box = await _getBox();
      final json = box.get(_completedJourneysKey);
      if (json == null || json.isEmpty) return [];
      
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => ActiveJourney.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logger.e('Error loading completed journeys', error: e, stackTrace: st);
      return [];
    }
  }

  /// Get available journeys for selection.
  /// In a real app, this would come from the backend API.
  Future<List<CommitmentJourney>> getAvailableJourneys() async {
    // Return sample journeys - in production, fetch from API
    return _sampleJourneys;
  }

  /// Get a specific journey by ID.
  Future<CommitmentJourney> getJourneyById(String id) async {
    final journeys = await getAvailableJourneys();
    return journeys.firstWhere(
      (j) => j.id == id,
      orElse: () => throw StateError('Journey not found: $id'),
    );
  }

  /// Get recommendations based on struggles and virtue focus.
  Future<List<CommitmentJourney>> getRecommendations({
    List<String>? struggles,
    String? virtueFocus,
  }) async {
    final all = await getAvailableJourneys();
    
    if (struggles == null || struggles.isEmpty) {
      return all;
    }

    // Score journeys based on struggle tag matches
    final scored = all.map((journey) {
      int score = 0;
      for (final struggle in struggles) {
        if (journey.struggleTags.contains(struggle)) score += 2;
        if (journey.virtueAlignment.toLowerCase() == virtueFocus?.toLowerCase()) {
          score += 1;
        }
      }
      return (journey, score);
    }).toList();

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((s) => s.$1).toList();
  }

  /// Check if partner has responded today (6pm-8pm window).
  Future<bool> hasPartnerRespondedToday() async {
    try {
      final box = await _getBox();
      final json = box.get(_partnerResponseKey);
      if (json == null) return false;

      final map = jsonDecode(json) as Map<String, dynamic>;
      final dateStr = map['date'] as String?;
      if (dateStr == null) return false;

      final responseDate = DateTime.parse(dateStr);
      final today = DateTime.now();

      // Check if it's the same day
      return responseDate.year == today.year &&
          responseDate.month == today.month &&
          responseDate.day == today.day;
    } catch (e, st) {
      _logger.e('Failed to check partner response', error: e, stackTrace: st);
      return false;
    }
  }

  /// Record partner response for today.
  Future<void> recordPartnerResponse({
    required bool confirmed,
    String? note,
  }) async {
    try {
      final box = await _getBox();
      final data = {
        'date': DateTime.now().toIso8601String(),
        'confirmed': confirmed,
        'note': note,
      };
      await box.put(_partnerResponseKey, jsonEncode(data));
    } catch (e) {
      _logger.e('Error recording partner response', error: e);
    }
  }

  // Private helpers

  Future<void> _saveActiveJourney(ActiveJourney journey) async {
    final box = await _getBox();
    await box.put(_activeJourneyKey, jsonEncode(journey.toJson()));
  }

  Future<void> _saveCompletedJourneys(List<ActiveJourney> journeys) async {
    final box = await _getBox();
    final list = journeys.map((j) => j.toJson()).toList();
    await box.put(_completedJourneysKey, jsonEncode(list));
  }

  // Sample data for development - will be replaced with API calls
  static final List<CommitmentJourney> _sampleJourneys = [
    // 3-Day Seeds
    CommitmentJourney(
      id: 'seed_prayer_morning',
      title: 'Morning Prayer',
      description: 'Begin each day with intentional time with God before touching your phone.',
      duration: CommitmentDuration.seed3Day,
      virtueAlignment: 'Prayer',
      struggleTags: ['phone_addiction', 'restless_mornings'],
      baseRequirement: 'Pray for 10 minutes before checking phone',
      tips: [
        'Place your Bible by your bed',
        'Set your alarm 15 minutes earlier',
        'Use the app if that helps you focus',
      ],
    ),
    CommitmentJourney(
      id: 'seed_gratitude_journal',
      title: 'Daily Gratitude',
      description: 'Record three things you are grateful for each evening.',
      duration: CommitmentDuration.seed3Day,
      virtueAlignment: 'Gratitude',
      struggleTags: ['negativity', 'anxiety'],
      baseRequirement: 'Write three gratitudes before bed',
      tips: [
        'Keep your journal visible on your nightstand',
        'Include small things: a warm meal, a kind word',
        'Thank God for each item specifically',
      ],
    ),
    
    // 10-Day Paths
    CommitmentJourney(
      id: 'path_social_fast',
      title: 'Social Media Fast',
      description: 'Remove social media to create space for deeper connection with God and others.',
      duration: CommitmentDuration.path10Day,
      virtueAlignment: 'Temperance',
      struggleTags: ['social_media', 'distraction', 'comparison'],
      baseRequirement: 'No social media apps or websites',
      milestones: [
        CommitmentMilestone(
          day: 3,
          description: 'Remove apps from your phone',
          newRequirement: 'Delete social apps, use browser only if needed',
        ),
        CommitmentMilestone(
          day: 7,
          description: 'Deepen the fast',
          newRequirement: 'No social media even via browser',
        ),
      ],
      tips: [
        'Delete apps now, not later',
        'Tell close friends how to reach you',
        'Fill the void with prayer or scripture',
      ],
    ),
    CommitmentJourney(
      id: 'path_generosity',
      title: 'Practicing Generosity',
      description: 'Cultivate a generous heart through daily acts of giving.',
      duration: CommitmentDuration.path10Day,
      virtueAlignment: 'Generosity',
      struggleTags: ['selfishness', 'materialism'],
      baseRequirement: 'One act of generosity each day',
      milestones: [
        CommitmentMilestone(
          day: 5,
          description: 'Increase your giving',
          newRequirement: 'Add financial giving to your daily generosity',
        ),
      ],
      tips: [
        'Generosity includes time, attention, and money',
        'Look for the overlooked person each day',
        'Give without expecting thanks',
      ],
    ),
    
    // 40-Day Journeys
    CommitmentJourney(
      id: 'journey_fasting',
      title: 'The Discipline of Fasting',
      description: 'A graduated fasting practice to strengthen self-control and deepen prayer.',
      duration: CommitmentDuration.journey40Day,
      virtueAlignment: 'Temperance',
      struggleTags: ['overeating', 'lack_of_discipline', 'gluttony'],
      baseRequirement: 'Fast until 12pm daily',
      milestones: [
        CommitmentMilestone(
          day: 10,
          description: 'Extend your fast',
          newRequirement: 'Fast until 3pm daily',
        ),
        CommitmentMilestone(
          day: 20,
          description: 'Full day fasting',
          newRequirement: 'Fast one full day per week (dawn to dusk)',
        ),
        CommitmentMilestone(
          day: 30,
          description: ' intensified practice',
          newRequirement: 'Fast until 3pm daily, two full days per week',
        ),
      ],
      tips: [
        'Drink plenty of water during fasting hours',
        'Use hunger pangs as prayer reminders',
        'Break fast with gratitude, not gluttony',
      ],
    ),
    CommitmentJourney(
      id: 'journey_scripture',
      title: 'Deep in the Word',
      description: 'Immerse yourself in Scripture through lectio divina and study.',
      duration: CommitmentDuration.journey40Day,
      virtueAlignment: 'Knowledge',
      struggleTags: ['biblical_illiteracy', 'distraction'],
      baseRequirement: '30 minutes of Scripture reading and reflection',
      milestones: [
        CommitmentMilestone(
          day: 10,
          description: 'Add memorization',
          newRequirement: 'Read 30 min + memorize one verse daily',
        ),
        CommitmentMilestone(
          day: 20,
          description: 'Study deeper',
          newRequirement: 'Add commentary or study notes reading',
        ),
        CommitmentMilestone(
          day: 30,
          description: 'Share what you learn',
          newRequirement: 'Share one insight with someone each day',
        ),
      ],
      tips: [
        'Choose one book of the Bible to read through',
        'Write down questions that arise',
        'Let Scripture read you, not just you reading it',
      ],
    ),
    CommitmentJourney(
      id: 'journey_service',
      title: 'Called to Serve',
      description: 'Live out your faith through consistent acts of service to others.',
      duration: CommitmentDuration.journey40Day,
      virtueAlignment: 'Charity',
      struggleTags: ['selfishness', 'isolation'],
      baseRequirement: 'One act of service each day',
      milestones: [
        CommitmentMilestone(
          day: 10,
          description: 'Serve strangers',
          newRequirement: 'Include one stranger or acquaintance in your service',
        ),
        CommitmentMilestone(
          day: 20,
          description: 'Commit to a place',
          newRequirement: 'Volunteer weekly at a shelter, church, or nonprofit',
        ),
        CommitmentMilestone(
          day: 30,
          description: 'Mentor someone',
          newRequirement: 'Begin mentoring or discipling one person',
        ),
      ],
      tips: [
        'Service can be small: a smile, holding a door, a listening ear',
        'Look for needs in your existing circles first',
        'Serve without seeking recognition',
      ],
    ),
  ];
}
