import 'package:flutter/material.dart';

class ResponsiveLayoutBuilder extends StatelessWidget {
  const ResponsiveLayoutBuilder({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  final Widget Function(BuildContext context, BoxConstraints constraints) mobile;
  final Widget Function(BuildContext context, BoxConstraints constraints)? tablet;
  final Widget Function(BuildContext context, BoxConstraints constraints)? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200 && desktop != null) {
          return desktop!(context, constraints);
        } else if (constraints.maxWidth >= 800 && tablet != null) {
          return tablet!(context, constraints);
        } else {
          return mobile(context, constraints);
        }
      },
    );
  }
}

class ResponsiveSpacing {
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 48.0;
    if (width >= 800) return 32.0;
    return 24.0;
  }

  static double getVerticalPadding(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    if (height >= 1000) return 48.0;
    if (height >= 700) return 32.0;
    return 24.0;
  }

  static double getContentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 800.0;
    if (width >= 800) return 600.0;
    return double.infinity;
  }

  // Golden ratio calculations for perfect symmetry
  static double getGoldenRatioSmall(double dimension) => dimension * 0.618;
  static double getGoldenRatioLarge(double dimension) => dimension * 1.618;
  
  // Perfect square root proportions
  static double getSqrt2Ratio(double dimension) => dimension * 0.707;
  static double getSqrt3Ratio(double dimension) => dimension * 0.577;
}

class ResponsiveFontSize {
  static double getHeadlineLarge(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 48.0;
    if (width >= 800) return 40.0;
    return 32.0;
  }

  static double getHeadlineMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 32.0;
    if (width >= 800) return 28.0;
    return 24.0;
  }

  static double getHeadlineSmall(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 28.0;
    if (width >= 800) return 24.0;
    return 20.0;
  }

  static double getTitleLarge(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 24.0;
    if (width >= 800) return 22.0;
    return 20.0;
  }

  static double getTitleMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 20.0;
    if (width >= 800) return 18.0;
    return 16.0;
  }

  static double getBodyLarge(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 18.0;
    if (width >= 800) return 16.0;
    return 14.0;
  }

  static double getBodyMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 16.0;
    if (width >= 800) return 14.0;
    return 12.0;
  }
}

class ResponsiveBorderRadius {
  static double getSmall(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 12.0;
    if (width >= 800) return 10.0;
    return 8.0;
  }

  static double getMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 16.0;
    if (width >= 800) return 14.0;
    return 12.0;
  }

  static double getLarge(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 24.0;
    if (width >= 800) return 20.0;
    return 16.0;
  }
}
