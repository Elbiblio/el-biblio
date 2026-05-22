import 'package:elbiblio/shared/widgets/vision_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('vision illustrations render from bundled SVG assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              VisionIllustration(asset: VisionIllustrationAsset.completion),
              VisionIllustration(asset: VisionIllustrationAsset.commitment),
              VisionIllustration(asset: VisionIllustrationAsset.belonging),
              VisionIllustration(asset: VisionIllustrationAsset.protection),
              VisionIllustration(asset: VisionIllustrationAsset.growth),
              VisionIllustration(asset: VisionIllustrationAsset.play),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(VisionIllustration), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });
}
