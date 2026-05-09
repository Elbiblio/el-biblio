import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../shared/widgets/premium_success_dialog.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../widgets/vision_panel.dart';

class GrowScreen extends ConsumerStatefulWidget {
  const GrowScreen({super.key});

  @override
  ConsumerState<GrowScreen> createState() => _GrowScreenState();
}

class _GrowScreenState extends ConsumerState<GrowScreen> {
  final _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(visionProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Grow')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text(
            'Your growth journey',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _seasonLine(
              state.primaryTribe?.tribe.displayName,
              state.activeCommitment?.plan.title,
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: VisionIllustration(
              asset: VisionIllustrationAsset.growth,
              size: 104,
              semanticLabel: 'Growth journey',
            ),
          ),
          const SizedBox(height: 18),
          _JourneyTimeline(),
          const SizedBox(height: 16),
          _DailyQuestion(controller: _answerController),
        ],
      ),
    );
  }

  String _seasonLine(String? tribe, String? commitment) {
    if (tribe != null && commitment != null) {
      return 'Walking with $tribe through $commitment.';
    }
    if (tribe != null) return 'Walking with $tribe.';
    return 'Your story begins with belonging and one faithful path.';
  }
}

class _JourneyTimeline extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(visionProvider).journeyEvents;
    return VisionPanel(
      icon: Icons.route_rounded,
      title: 'Story so far',
      child: events.isEmpty
          ? const Text('Join a tribe and commitment to begin your story.')
          : Column(
              children: events.map((event) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        child: Icon(event.icon, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(event.subtitle),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _DailyQuestion extends ConsumerStatefulWidget {
  const _DailyQuestion({required this.controller});

  final TextEditingController controller;

  @override
  ConsumerState<_DailyQuestion> createState() => _DailyQuestionState();
}

class _DailyQuestionState extends ConsumerState<_DailyQuestion> {
  bool _showPerspective = false;

  @override
  Widget build(BuildContext context) {
    final question = ref.watch(visionProvider).dailyQuestion;
    if (question == null) {
      return const VisionPanel(
        icon: LucideIcons.helpCircle,
        title: 'Daily faith question',
        child: Text('Today\'s question is not available yet.'),
      );
    }

    return VisionPanel(
      icon: LucideIcons.helpCircle,
      title: 'Daily faith question',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            enabled: !question.answeredToday,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Your answer for today',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: question.answeredToday
                    ? null
                    : () async {
                        final saved = await ref
                            .read(visionProvider.notifier)
                            .answerDailyQuestion(widget.controller.text);
                        if (!context.mounted) return;
                        if (!saved) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'We could not save your answer. Please try again.',
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() => _showPerspective = true);
                        await PremiumSuccessDialog.show(
                          context,
                          title: 'Answer saved',
                          message:
                              'Today\'s question is now part of your growth story.',
                        );
                        widget.controller.clear();
                      },
                icon: Icon(
                  question.answeredToday
                      ? LucideIcons.checkCircle
                      : LucideIcons.bookmark,
                  size: 18,
                ),
                label: Text(
                  question.answeredToday ? 'Answered today' : 'Save answer',
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showPerspective = true),
                icon: const Icon(LucideIcons.bookOpen, size: 18),
                label: const Text('Read perspective'),
              ),
            ],
          ),
          if (question.answeredToday || _showPerspective) ...[
            const SizedBox(height: 18),
            _InsightSection(
              title: 'Concise explanation',
              body: question.conciseExplanation,
            ),
            _InsightSection(
              title: 'Spiritual insight',
              body: question.spiritualInsight,
            ),
            _InsightSection(
              title: 'Practical perspective',
              body: question.practicalPerspective,
            ),
            _InsightSection(
              title: 'Real-world context',
              body: question.realWorldContext,
            ),
            const _ApplicationPrompt(),
          ],
        ],
      ),
    );
  }
}

class _ApplicationPrompt extends StatelessWidget {
  const _ApplicationPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        'Help me apply this today: name the smallest faithful action you can still take in the next hour.',
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyLarge?.copyWith(height: 1.45)),
        ],
      ),
    );
  }
}
