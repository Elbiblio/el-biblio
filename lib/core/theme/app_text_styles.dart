import 'package:flutter/material.dart';

extension AppTextStyles on TextTheme {
  /// Section headers (e.g., "DAILY RHYTHM", "APPEARANCE")
  TextStyle get sectionHeader => labelSmall!.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  /// Card titles for lists and grids
  TextStyle get cardTitle => titleMedium!.copyWith(fontWeight: FontWeight.w600);

  /// Verse numbers in biblical content
  TextStyle get verseNumber => bodySmall!.copyWith(fontWeight: FontWeight.bold);

  /// User profile name display (ceremonial/brand)
  TextStyle get profileName =>
      headlineLarge!.copyWith(fontStyle: FontStyle.italic);

  /// Large display numbers (stats, points)
  TextStyle get displayNumber => displayLarge!.copyWith(height: 1.0);

  /// Medium display numbers (stats, metrics)
  TextStyle get mediumNumber =>
      headlineMedium!.copyWith(fontStyle: FontStyle.italic);

  /// Small metadata text
  TextStyle get metadata => labelSmall!.copyWith(
    fontSize: 9,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );

  /// Journal titles (ceremonial/brand)
  TextStyle get journalTitle =>
      headlineMedium!.copyWith(fontWeight: FontWeight.w300, height: 1.3);

  /// Journal body text (readable content)
  TextStyle get journalBody =>
      bodyMedium!.copyWith(fontWeight: FontWeight.w300, height: 1.6);

  /// Button text
  TextStyle get buttonText => labelLarge!.copyWith(fontWeight: FontWeight.w600);

  /// Chip/Filter text
  TextStyle get chipText => labelMedium!.copyWith(fontWeight: FontWeight.w500);

  /// Ceremonial headings (spiritual milestones, achievements)
  TextStyle get ceremonialHeading =>
      displaySmall!.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0);

  /// Brand identity elements (app titles, major section headers)
  TextStyle get brandTitle =>
      headlineLarge!.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0);

  /// Spiritual content subtitles
  TextStyle get spiritualSubtitle => titleMedium!.copyWith(
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    height: 1.4,
  );
}
