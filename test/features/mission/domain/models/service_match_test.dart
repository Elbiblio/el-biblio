import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/mission/domain/models/kingdom_action_models.dart';

void main() {
  group('ServiceMatch Model Tests', () {
    test('ServiceMatch isStrongMatch returns true for score >= 0.8', () {
      const strongMatch = ServiceMatch(
        opportunityId: '1',
        title: 'Test Opportunity',
        matchScore: 0.85,
        matchReasons: ['Good fit'],
        category: 'Church',
      );

      expect(strongMatch.isStrongMatch, true);
    });

    test('ServiceMatch isStrongMatch returns false for score < 0.8', () {
      const weakMatch = ServiceMatch(
        opportunityId: '1',
        title: 'Test Opportunity',
        matchScore: 0.75,
        matchReasons: ['Okay fit'],
        category: 'Church',
      );

      expect(weakMatch.isStrongMatch, false);
    });

    test('ServiceMatch isGoodMatch returns true for score >= 0.6', () {
      const goodMatch = ServiceMatch(
        opportunityId: '1',
        title: 'Test Opportunity',
        matchScore: 0.65,
        matchReasons: ['Good fit'],
        category: 'Church',
      );

      expect(goodMatch.isGoodMatch, true);
    });

    test('ServiceMatch isGoodMatch returns false for score < 0.6', () {
      const poorMatch = ServiceMatch(
        opportunityId: '1',
        title: 'Test Opportunity',
        matchScore: 0.55,
        matchReasons: ['Poor fit'],
        category: 'Church',
      );

      expect(poorMatch.isGoodMatch, false);
    });

    test('ServiceMatch creates with all optional fields', () {
      const match = ServiceMatch(
        opportunityId: '1',
        title: 'Test Opportunity',
        matchScore: 0.9,
        matchReasons: ['Perfect fit'],
        category: 'Community',
        burdenAlignment: 'Aligns with burden for elderly',
        tendencyAlignment: 'Matches hospitality tendency',
        timeFit: 'Fits weekend availability',
        locationProximity: 2.5,
      );

      expect(match.opportunityId, '1');
      expect(match.matchScore, 0.9);
      expect(match.burdenAlignment, 'Aligns with burden for elderly');
      expect(match.tendencyAlignment, 'Matches hospitality tendency');
      expect(match.timeFit, 'Fits weekend availability');
      expect(match.locationProximity, 2.5);
    });

    test('ServiceMatch creates with only required fields', () {
      const match = ServiceMatch(
        opportunityId: '1',
        title: 'Test Opportunity',
        matchScore: 0.5,
        matchReasons: ['Some fit'],
        category: 'Church',
      );

      expect(match.opportunityId, '1');
      expect(match.matchScore, 0.5);
      expect(match.burdenAlignment, null);
      expect(match.tendencyAlignment, null);
      expect(match.timeFit, null);
      expect(match.locationProximity, null);
    });
  });
}
