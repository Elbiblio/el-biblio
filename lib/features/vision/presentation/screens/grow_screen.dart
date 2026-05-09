import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../shared/widgets/premium_success_dialog.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../../domain/vision_models.dart';
import '../widgets/vision_panel.dart';

class GrowScreen extends ConsumerStatefulWidget {
  const GrowScreen({super.key});

  @override
  ConsumerState<GrowScreen> createState() => _GrowScreenState();
}

class _GrowScreenState extends ConsumerState<GrowScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(visionProvider.notifier).load(),
    );
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
          const _DailyQuestion(),
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
  const _DailyQuestion();

  @override
  ConsumerState<_DailyQuestion> createState() => _DailyQuestionState();
}

class _DailyQuestionState extends ConsumerState<_DailyQuestion> {
  final Map<int, TextEditingController> _answerControllers = {};
  final Set<int> _expandedQuestionIds = {};

  @override
  void dispose() {
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int questionId, String? answer) {
    final controller = _answerControllers.putIfAbsent(
      questionId,
      () => TextEditingController(text: answer ?? ''),
    );
    if ((answer ?? '').isNotEmpty && controller.text.isEmpty) {
      controller.text = answer!;
    }
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final dailyQuestion = ref.watch(visionProvider).dailyQuestion;
    if (dailyQuestion == null) {
      return const VisionPanel(
        icon: LucideIcons.helpCircle,
        title: 'Daily faith question',
        child: Text('Today\'s question is not available yet.'),
      );
    }

    final questions = dailyQuestion.packQuestions.isNotEmpty
        ? dailyQuestion.packQuestions
        : [dailyQuestion];

    return VisionPanel(
      icon: LucideIcons.helpCircle,
      title: 'Daily faith questions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Three prompts for today. Answer one deeply, or work through all three slowly.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final question in questions) ...[
            _DailyQuestionCard(
              question: question,
              controller: _controllerFor(question.id, question.answer),
              expanded:
                  question.answeredToday ||
                  _expandedQuestionIds.contains(question.id),
              onToggleGuide: () {
                setState(() {
                  if (_expandedQuestionIds.contains(question.id)) {
                    _expandedQuestionIds.remove(question.id);
                  } else {
                    _expandedQuestionIds.add(question.id);
                  }
                });
              },
              onSave: () async {
                final saved = await ref
                    .read(visionProvider.notifier)
                    .answerDailyQuestion(
                      _controllerFor(question.id, question.answer).text,
                      selectedQuestion: question,
                    );
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
                setState(() => _expandedQuestionIds.add(question.id));
                await PremiumSuccessDialog.show(
                  context,
                  title: 'Answer saved',
                  message:
                      'This question is now part of today\'s growth story.',
                );
              },
            ),
            if (question != questions.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DailyQuestionCard extends StatelessWidget {
  const _DailyQuestionCard({
    required this.question,
    required this.controller,
    required this.expanded,
    required this.onToggleGuide,
    required this.onSave,
  });

  final DailyGrowthQuestion question;
  final TextEditingController controller;
  final bool expanded;
  final VoidCallback onToggleGuide;
  final Future<void> Function() onSave;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${question.position ?? ''}'.trim(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            question.question,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
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
                onPressed: question.answeredToday ? null : onSave,
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
                onPressed: onToggleGuide,
                icon: const Icon(LucideIcons.bookOpen, size: 18),
                label: Text(expanded ? 'Hide guide' : 'Read guide'),
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 18),
            _InsightSection(
              title: 'Brief commentary',
              body: question.conciseExplanation,
            ),
            _InsightSection(
              title: 'Spiritual insight',
              body: question.spiritualInsight,
            ),
            _InsightSection(
              title: 'Daily living guide',
              body: question.dailyLivingGuide ?? question.practicalPerspective,
            ),
            _InsightSection(
              title: 'Real-world context',
              body: question.realWorldContext,
            ),
            _ActionSteps(steps: question.actionSteps),
            if (question.scriptureRefs.isNotEmpty)
              _ScriptureRefs(refs: question.scriptureRefs),
          ],
        ],
      ),
    );
  }
}

class _ActionSteps extends StatelessWidget {
  const _ActionSteps({required this.steps});

  final List<DailyFaithActionStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Action steps',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 13,
                    child: Text(
                      step.minutes == null ? '-' : '${step.minutes}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          step.instruction,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                          ),
                        ),
                        if (step.why.isNotEmpty)
                          Text(
                            step.why,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.62,
                              ),
                              height: 1.3,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScriptureRefs extends StatelessWidget {
  const _ScriptureRefs({required this.refs});

  final List<String> refs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: refs
          .map(
            (ref) => Chip(
              label: Text(ref),
              visualDensity: VisualDensity.compact,
              backgroundColor: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.45,
              ),
            ),
          )
          .toList(),
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
