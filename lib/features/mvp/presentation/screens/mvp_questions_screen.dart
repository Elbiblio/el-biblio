import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';

class MvpQuestionsScreen extends ConsumerStatefulWidget {
  const MvpQuestionsScreen({super.key});

  @override
  ConsumerState<MvpQuestionsScreen> createState() => _MvpQuestionsScreenState();
}

class _MvpQuestionsScreenState extends ConsumerState<MvpQuestionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(mvpProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = ref.watch(mvpProvider).dailyQuestion;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Questions')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          if (question == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            Icon(
              LucideIcons.helpCircle,
              size: 36,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              question.question,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            _AnswerSection(
              title: 'Concise explanation',
              body: question.conciseExplanation,
            ),
            _AnswerSection(
              title: 'Spiritual insight',
              body: question.spiritualInsight,
            ),
            _AnswerSection(
              title: 'Practical perspective',
              body: question.practicalPerspective,
            ),
            _AnswerSection(
              title: 'Real-world context',
              body: question.realWorldContext,
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerSection extends StatelessWidget {
  const _AnswerSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
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
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
