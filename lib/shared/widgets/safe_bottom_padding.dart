import 'package:flutter/material.dart';

const double shellChromeBottomPadding = 132.0;

/// A simple and reliable widget to prevent bottom navigation bar overlap
/// This wraps any scrollable content and adds appropriate bottom padding
class SafeScrollableContent extends StatelessWidget {
  const SafeScrollableContent({
    super.key,
    required this.child,
    this.bottomPadding = shellChromeBottomPadding,
  });

  final Widget child;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        SizedBox(height: bottomPadding),
      ],
    );
  }
}

/// A wrapper for CustomScrollView that automatically adds bottom padding
class SafeCustomScrollView extends StatelessWidget {
  const SafeCustomScrollView({
    super.key,
    required this.slivers,
    this.bottomPadding = shellChromeBottomPadding,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.anchor = 0.0,
    this.cacheExtent,
    this.semanticChildCount,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
  });

  final List<Widget> slivers;
  final double bottomPadding;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final double anchor;
  final double? cacheExtent;
  final int? semanticChildCount;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        ...slivers,
        SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
      ],
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      anchor: anchor,
      cacheExtent: cacheExtent,
      semanticChildCount: semanticChildCount,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
    );
  }
}

/// A wrapper for ListView that automatically adds bottom padding
class SafeListView extends StatelessWidget {
  const SafeListView({
    super.key,
    required this.children,
    this.bottomPadding = shellChromeBottomPadding,
    this.padding = EdgeInsets.zero,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.itemExtent,
    this.prototypeItem,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.semanticChildCount,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
  });

  final List<Widget> children;
  final double bottomPadding;
  final EdgeInsets padding;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final double? itemExtent;
  final Widget? prototypeItem;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;
  final int? semanticChildCount;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final adjustedPadding = EdgeInsets.only(
      left: padding.left,
      top: padding.top,
      right: padding.right,
      bottom: padding.bottom + bottomPadding,
    );

    return ListView(
      padding: adjustedPadding,
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemExtent: itemExtent,
      prototypeItem: prototypeItem,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent,
      semanticChildCount: semanticChildCount,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      children: children,
    );
  }
}

/// A simple padding widget that can be added to any content
class BottomPadding extends StatelessWidget {
  const BottomPadding({super.key, this.height = shellChromeBottomPadding});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}
