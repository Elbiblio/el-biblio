import 'package:flutter_test/flutter_test.dart';

import 'package:elbiblio/features/onboarding/domain/compass_discovery_catalog.dart';

void main() {
  group('CompassDiscoveryCatalog', () {
    test('season discovery is grouped into small focused clusters', () {
      expect(CompassDiscoveryCatalog.seasonClusters, hasLength(4));

      final clusteredArchetypes = CompassDiscoveryCatalog.seasonClusters
          .expand((cluster) => cluster.options)
          .map((option) => option.archetype)
          .toSet();

      expect(
        clusteredArchetypes,
        CompassDiscoveryCatalog.archetypeOrder.toSet(),
      );
      for (final cluster in CompassDiscoveryCatalog.seasonClusters) {
        expect(cluster.options.length, lessThanOrEqualTo(3));
      }
    });

    test('distortion question narrows from prior signals', () {
      final options = CompassDiscoveryCatalog.distortionOptionsFor([
        'Reformer',
        'Architect',
        'Sentinel',
      ]);

      expect(options.length, lessThanOrEqualTo(4));
      expect(
        options.map((option) => option.archetype),
        containsAll(['Reformer', 'Architect', 'Sentinel']),
      );
    });

    test('chained follow-up questions never return more than four choices', () {
      final signals = ['Welcomer', 'Bridgebuilder', 'Healer'];

      final followUps = [
        CompassDiscoveryCatalog.pressureOptionsFor(signals),
        CompassDiscoveryCatalog.postponedOptionsFor(signals),
        CompassDiscoveryCatalog.peopleNeedOptionsFor(signals),
        CompassDiscoveryCatalog.distortionOptionsFor(signals),
      ];

      for (final options in followUps) {
        expect(options.length, lessThanOrEqualTo(4));
        expect(
          options.map((option) => option.archetype).toSet().length,
          options.length,
        );
      }
    });
  });
}
