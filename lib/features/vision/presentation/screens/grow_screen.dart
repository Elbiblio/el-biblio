import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../shared/widgets/safe_bottom_padding.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../../application/vision_state.dart';
import '../../domain/vision_models.dart';
import '../widgets/vision_action_tile.dart';
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
    final tokens = theme.tokens;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tokens.pageGradient,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(visionProvider.notifier).load(force: true),
            child: SafeListView(
              bottomPadding: shellChromeBottomPadding,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                _GrowHero(state: state),
                if (state.error?.isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  VisionPanel(
                    icon: LucideIcons.wifiOff,
                    title: state.isReadOnly
                        ? 'Reconnect to keep growing'
                        : 'Growth story needs a retry',
                    child: Text(
                      state.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _SpiritualAgeStory(),
                const SizedBox(height: 14),
                _JourneyTimeline(),
                const SizedBox(height: 14),
                const _DailyQuestion(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GrowHero extends ConsumerWidget {
  const _GrowHero({required this.state});

  final VisionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final tribeName = state.primaryTribe?.tribe.displayName;
    final commitmentTitle = state.activeCommitment?.plan.title;
    final compassComplete = state.journeyEvents.any(
      (event) => event.type == GrowthJourneyEventType.compassComplete,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 20),
      decoration: BoxDecoration(
        color: theme.tokens.palette.paper.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.82 : 0.9,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.tokens.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grow',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _seasonLine(tribeName, commitmentTitle),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.tokens.palette.textSecondary,
                        height: 1.42,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const VisionIllustration(
                asset: VisionIllustrationAsset.growth,
                size: 92,
                semanticLabel: 'Growth journey',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GrowStatusPill(
                icon: LucideIcons.sprout,
                label: settings.spiritualAgeScore > 0
                    ? '${settings.spiritualAgeStage} ${settings.spiritualAgeScore}/100'
                    : compassComplete
                    ? 'Compass complete'
                    : 'Compass waiting',
              ),
              _GrowStatusPill(
                icon: LucideIcons.users,
                label: tribeName ?? 'No tribe yet',
              ),
              _GrowStatusPill(
                icon: LucideIcons.flag,
                label: commitmentTitle ?? 'No commitment yet',
              ),
            ],
          ),
          if (tribeName == null || commitmentTitle == null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (tribeName == null)
                  FilledButton.tonalIcon(
                    onPressed: () => context.go(AppRoutes.tribe),
                    icon: const Icon(LucideIcons.users, size: 18),
                    label: const Text('Find tribe'),
                  ),
                if (commitmentTitle == null)
                  FilledButton.tonalIcon(
                    onPressed: () => context.go(AppRoutes.commit),
                    icon: const Icon(LucideIcons.flag, size: 18),
                    label: const Text('Choose commitment'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _seasonLine(String? tribe, String? commitment) {
    if (tribe != null && commitment != null) {
      return '$commitment - $tribe';
    }
    if (tribe != null) {
      return '$tribe joined. Choose a daily practice.';
    }
    if (commitment != null) {
      return '$commitment active. Add a tribe.';
    }
    return 'Choose tribe and commitment.';
  }
}

class _GrowStatusPill extends StatelessWidget {
  const _GrowStatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _SpiritualAgeStory extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final stage = settings.spiritualAgeStage;
    final score = settings.spiritualAgeScore;

    return VisionPanel(
      icon: LucideIcons.sprout,
      title: score > 0 ? 'Spiritual age: $stage' : 'Formation',
      trailing: score > 0 ? Text('$score/100') : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track the season through check-ins, reflection, and daily questions.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.48),
          ),
          const SizedBox(height: 14),
          const _FormationStep(
            icon: LucideIcons.sprout,
            title: 'Rooted',
            body: 'Keep the daily practice.',
          ),
          const _FormationStep(
            icon: LucideIcons.scissors,
            title: 'Pruned',
            body: 'Name the obstacle.',
          ),
          const _FormationStep(
            icon: LucideIcons.flower2,
            title: 'Fruitful',
            body: 'Watch for patience, truth, courage, and love.',
          ),
        ],
      ),
    );
  }
}

class _FormationStep extends StatelessWidget {
  const _FormationStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.tokens.palette.textSecondary,
                    height: 1.35,
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

class _JourneyTimeline extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(visionProvider).journeyEvents;
    final theme = Theme.of(context);
    return VisionPanel(
      icon: LucideIcons.map,
      title: 'Story so far',
      child: events.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Milestones appear after compass, tribe, commitment, and check-ins.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TimelineSeed(label: 'Compass'),
                    _TimelineSeed(label: 'Tribe'),
                    _TimelineSeed(label: 'Commitment'),
                    _TimelineSeed(label: 'Check-ins'),
                  ],
                ),
              ],
            )
          : Column(
              children: events.map((event) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: Icon(
                          event.icon,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event.subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.tokens.palette.textSecondary,
                                height: 1.35,
                              ),
                            ),
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

class _TimelineSeed extends StatelessWidget {
  const _TimelineSeed({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        LucideIcons.circle,
        size: 12,
        color: theme.colorScheme.primary,
      ),
      label: Text(label),
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
  final Map<int, String> _selectedAnswers = {};
  final Set<int> _expandedQuestionIds = {};
  bool _showMoreQuestions = false;

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
        child: Text('Question unavailable. Pull to retry.'),
      );
    }

    final allQuestions = dailyQuestion.packQuestions.isNotEmpty
        ? dailyQuestion.packQuestions
        : [dailyQuestion];
    final primaryQuestion = allQuestions.first;
    final extraQuestions = allQuestions.skip(1).toList(growable: false);
    final visibleQuestions = [
      primaryQuestion,
      if (_showMoreQuestions) ...extraQuestions,
    ];

    return VisionPanel(
      icon: LucideIcons.helpCircle,
      title: 'Daily faith question',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final question in visibleQuestions) ...[
            _DailyQuestionCard(
              question: question,
              controller: _controllerFor(question.id, question.answer),
              selectedAnswer: _selectedAnswers[question.id] ?? question.answer,
              onSelectAnswer: (answer) {
                setState(() {
                  _selectedAnswers[question.id] = answer;
                });
              },
              expanded: _expandedQuestionIds.contains(question.id),
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
                final selectedAnswer =
                    _selectedAnswers[question.id] ??
                    (question.answerOptions.isNotEmpty
                        ? ''
                        : _controllerFor(question.id, question.answer).text);
                final saved = await ref
                    .read(visionProvider.notifier)
                    .answerDailyQuestion(
                      selectedAnswer,
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Answer saved')));
              },
            ),
            if (question != visibleQuestions.last) const SizedBox(height: 12),
          ],
          if (extraQuestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            VisionActionTile(
              icon: _showMoreQuestions
                  ? LucideIcons.chevronUp
                  : LucideIcons.list,
              title: _showMoreQuestions ? 'Hide questions' : 'More questions',
              subtitle: '${extraQuestions.length} waiting',
              onTap: () => setState(() {
                _showMoreQuestions = !_showMoreQuestions;
              }),
              dense: true,
            ),
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
    required this.selectedAnswer,
    required this.onSelectAnswer,
    required this.expanded,
    required this.onToggleGuide,
    required this.onSave,
  });

  final DailyGrowthQuestion question;
  final TextEditingController controller;
  final String? selectedAnswer;
  final ValueChanged<String> onSelectAnswer;
  final bool expanded;
  final VoidCallback onToggleGuide;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.palette.surface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.74 : 0.9,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuestionPill(
                icon: LucideIcons.helpCircle,
                label: 'Question ${question.position ?? ''}'.trim(),
              ),
              if (question.category?.isNotEmpty == true)
                _QuestionPill(
                  icon: LucideIcons.bookOpen,
                  label: question.category!,
                ),
              if (question.answeredToday)
                const _QuestionPill(
                  icon: LucideIcons.checkCircle,
                  label: 'Answered today',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.question,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 14),
          if (question.answerOptions.isNotEmpty)
            _AnswerOptions(
              options: question.answerOptions,
              selectedAnswer: selectedAnswer,
              enabled: !question.answeredToday,
              onSelected: onSelectAnswer,
            )
          else ...[
            Text(
              'One sentence is enough.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
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
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed:
                    question.answeredToday ||
                        (question.answerOptions.isNotEmpty &&
                            (selectedAnswer == null ||
                                selectedAnswer!.trim().isEmpty))
                    ? null
                    : onSave,
                icon: Icon(
                  question.answeredToday
                      ? LucideIcons.checkCircle
                      : LucideIcons.bookmark,
                  size: 18,
                ),
                label: Text(
                  question.answeredToday
                      ? 'Answered today'
                      : question.answerOptions.isNotEmpty
                      ? 'Save choice'
                      : 'Save answer',
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
              title: 'What this means',
              body: question.conciseExplanation,
            ),
            _InsightSection(
              title: 'Why it matters',
              body: question.spiritualInsight,
            ),
            _InsightSection(
              title: 'Try this today',
              body: question.dailyLivingGuide ?? question.practicalPerspective,
            ),
            _InsightSection(
              title: 'Where this shows up',
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

class _QuestionPill extends StatelessWidget {
  const _QuestionPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerOptions extends StatelessWidget {
  const _AnswerOptions({
    required this.options,
    required this.selectedAnswer,
    required this.enabled,
    required this.onSelected,
  });

  final List<String> options;
  final String? selectedAnswer;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final growthColor = theme.tokens.palette.growthColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is true today?',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: enabled ? () => onSelected(option) : null,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selectedAnswer == option
                      ? growthColor.withValues(alpha: 0.18)
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.38,
                        ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selectedAnswer == option
                        ? growthColor
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selectedAnswer == option
                          ? LucideIcons.checkCircle
                          : LucideIcons.circle,
                      size: 18,
                      color: selectedAnswer == option
                          ? growthColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        option,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.3,
                          fontWeight: selectedAnswer == option
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    child: step.minutes == null
                        ? Icon(
                            LucideIcons.check,
                            size: 14,
                            color: theme.colorScheme.primary,
                          )
                        : Text(
                            '${step.minutes}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
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
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
        ],
      ),
    );
  }
}
