import 'package:flutter/material.dart';

import '../../domain/models/bible_content.dart';

class VerseInsightSheet extends StatefulWidget {
  const VerseInsightSheet({
    super.key,
    required this.verse,
    required this.fetchInsight,
  });

  final BibleVerseContent verse;
  final Future<Map<String, dynamic>?> Function() fetchInsight;

  @override
  State<VerseInsightSheet> createState() => _VerseInsightSheetState();
}

class _VerseInsightSheetState extends State<VerseInsightSheet> {
  late Future<Map<String, dynamic>?> _insightFuture;

  @override
  void initState() {
    super.initState();
    _insightFuture = widget.fetchInsight();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: 0.95,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: _insightFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const _VerseInsightSkeleton();
                      }

                      if (snapshot.hasError || snapshot.data == null) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Text(
                                'Unable to load insight',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.error?.toString() ?? 'Something went wrong. Please try again.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      }

                      final payload = snapshot.data!;
                      return _VerseInsightContent(
                        verse: widget.verse,
                        payload: payload,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseInsightSkeleton extends StatelessWidget {
  const _VerseInsightSkeleton();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);

    Widget line({double width = double.infinity, double height = 16, BorderRadius? radius}) {
      return _SkeletonPulseLine(
        width: width,
        height: height,
        baseColor: baseColor,
        borderRadius: radius ?? BorderRadius.circular(8),
      );
    }

    return ListView(
      children: [
        line(width: 120, height: 18),
        line(height: 18),
        line(),
        const SizedBox(height: 12),
        line(height: 80, radius: BorderRadius.circular(16)),
        const SizedBox(height: 16),
        line(width: 160, height: 18),
        line(),
        line(width: 200),
        const SizedBox(height: 16),
        line(width: 140, height: 18),
        ...List.generate(3, (_) => line()),
      ],
    );
  }
}

class _VerseInsightContent extends StatelessWidget {
  const _VerseInsightContent({
    required this.verse,
    required this.payload,
  });

  final BibleVerseContent verse;
  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verseInfo = (payload['verse'] ?? payload['data']?['verse']) as Map<String, dynamic>?;
    final quickInsight = (payload['quick_insight'] ?? payload['data']?['quick_insight']) as Map<String, dynamic>?;
    final deeperExploration = (payload['deeper_exploration'] ?? payload['data']?['deeper_exploration']) as Map<String, dynamic>?;
    final livingThisOut = (payload['living_this_out'] ?? payload['data']?['living_this_out']) as List<dynamic>?;
    final reflection = (payload['reflection_questions'] ?? payload['data']?['reflection_questions']) as Map<String, dynamic>?;
    final theologicalNotes = (payload['theological_notes'] ?? payload['data']?['theological_notes']) as List<dynamic>?;

    return ListView(
      children: [
        Text(
          verseInfo != null ? (verseInfo['reference'] as String? ?? verse.reference ?? '') : verse.reference ?? '',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          verseInfo != null ? (verseInfo['text'] as String? ?? verse.text) : verse.text,
          style: theme.textTheme.bodyLarge,
        ),
        if (verseInfo != null) ...[
          const SizedBox(height: 8),
          Text(
            verseInfo['version'] as String? ?? '',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
          ),
        ],
        const SizedBox(height: 24),
        if (quickInsight != null) ...[
          Text('Quick Insight', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _InsightCard(
            title: 'Core Meaning',
            body: quickInsight['core_meaning']?.toString() ?? '—',
            icon: Icons.lightbulb_outline,
          ),
          const SizedBox(height: 12),
          _InsightCard(
            title: 'Universal Connection',
            body: quickInsight['universal_connection']?.toString() ?? '—',
            icon: Icons.all_inclusive,
          ),
          const SizedBox(height: 24),
        ],
        if (deeperExploration != null) ...[
          Text('Deeper Exploration', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _InsightListTile(
            label: 'Historical Context',
            body: deeperExploration['historical_context']?.toString(),
          ),
          _InsightListTile(
            label: 'Original Language',
            body: deeperExploration['original_language_insight']?.toString(),
          ),
          _InsightListTile(
            label: 'Biblical Theme',
            body: deeperExploration['biblical_theme_connection']?.toString(),
          ),
          const SizedBox(height: 24),
        ],
        if (livingThisOut != null && livingThisOut.isNotEmpty) ...[
          Text('Living This Out', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...livingThisOut.map((item) {
            final map = item as Map<String, dynamic>;
            final actions = (map['actions'] as List<dynamic>?)?.cast<String>() ?? const [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _InsightCard(
                title: map['scenario']?.toString() ?? 'Scenario',
                body: actions.isEmpty ? '' : actions.map((a) => '• $a').join('\n'),
                icon: Icons.favorite_outline,
              ),
            );
          }),
        ],
        if (reflection != null) ...[
          const SizedBox(height: 8),
          Text('Reflection Questions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...?((reflection['questions'] as List<dynamic>?)?.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(q.toString())),
                  ],
                ),
              ))),
          const SizedBox(height: 24),
        ],
        if (theologicalNotes != null && theologicalNotes.isNotEmpty) ...[
          Text('Theological Notes', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...theologicalNotes.map((note) {
            final map = note as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InsightCard(
                title: map['topic']?.toString() ?? 'Note',
                body: map['note']?.toString() ?? '',
                icon: map['is_disputed'] == true ? Icons.info_outline : Icons.menu_book_outlined,
                trailing: map['is_disputed'] == true
                    ? Chip(
                        label: const Text('Disputed'),
                        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.15),
                        labelStyle: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error),
                      )
                    : null,
              ),
            );
          }),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.body,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String body;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _InsightListTile extends StatelessWidget {
  const _InsightListTile({
    required this.label,
    required this.body,
  });

  final String label;
  final String? body;

  @override
  Widget build(BuildContext context) {
    if (body == null || body!.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(body!),
        ],
      ),
    );
  }
}

class _SkeletonPulseLine extends StatefulWidget {
  const _SkeletonPulseLine({
    required this.baseColor,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final Color baseColor;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<_SkeletonPulseLine> createState() => _SkeletonPulseLineState();
}

class _SkeletonPulseLineState extends State<_SkeletonPulseLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final color = Color.lerp(baseColor, highlight, _pulse.value) ?? baseColor;
        return Container(
          width: width,
          height: height,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
          ),
        );
      },
    );
  }

  Color get baseColor => widget.baseColor;
  double get width => widget.width;
  double get height => widget.height;
  BorderRadius get borderRadius => widget.borderRadius;
}
