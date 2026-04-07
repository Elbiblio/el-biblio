import 'package:elbiblio/features/mission/domain/models/kingdom_action_models.dart';

/// Test fixtures for providing mock data for tests
class TestFixtures {
  /// Creates a mock person commitment
  static PersonCommitment createMockPersonCommitment({
    String id = 'person_1',
    String name = 'John Doe',
    String relationship = 'Friend',
  }) {
    return PersonCommitment(
      id: id,
      name: name,
      relationship: relationship,
      createdAt: DateTime(2024, 1, 1),
      notes: 'Met at church',
      needs: 'Spiritual guidance',
      tags: ['evangelism', 'friendship'],
    );
  }

  /// Creates a mock generosity record
  static GenerosityRecord createMockGenerosityRecord({
    String id = 'generosity_1',
  }) {
    return GenerosityRecord(
      id: id,
      type: GenerosityType.financial,
      description: 'Monthly tithe',
      date: DateTime(2024, 1, 1),
      amount: 100.0,
    );
  }

  /// Creates a mock evangelism conversation
  static EvangelismConversation createMockEvangelismConversation({
    String id = 'conversation_1',
    String personName = 'Jane Smith',
  }) {
    return EvangelismConversation(
      id: id,
      personName: personName,
      method: 'in-person',
      date: DateTime(2024, 1, 1),
      responseType: 'interested',
    );
  }

  /// Creates a mock service match
  static ServiceMatch createMockServiceMatch({
    String opportunityId = 'opportunity_1',
    String title = 'Volunteer at Food Bank',
    double matchScore = 0.85,
  }) {
    return ServiceMatch(
      opportunityId: opportunityId,
      title: title,
      matchScore: matchScore,
      matchReasons: [
        'Aligns with your burden for the hungry',
        'Matches your service tendency',
      ],
      category: 'Community',
      burdenAlignment: 'Aligns with burden for the hungry',
      tendencyAlignment: 'Matches service tendency',
    );
  }

  /// Creates a list of mock service matches
  static List<ServiceMatch> createMockServiceMatches({int count = 3}) {
    return List.generate(count, (index) => createMockServiceMatch(
      opportunityId: 'opportunity_$index',
      title: 'Service Opportunity $index',
      matchScore: 0.9 - (index * 0.1),
    ));
  }
}
