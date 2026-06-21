import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../shared/widgets/ambient_scope.dart';
import '../../application/spiritual_aid_notifier.dart';
import '../../domain/models/faith_prompt.dart';
import '../widgets/category_chips.dart';
import '../widgets/faith_prompt_card.dart';

class FaithDiscussScreen extends ConsumerStatefulWidget {
  const FaithDiscussScreen({super.key});

  @override
  ConsumerState<FaithDiscussScreen> createState() => _FaithDiscussScreenState();
}

class _FaithDiscussScreenState extends ConsumerState<FaithDiscussScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spiritualAidProvider.notifier).loadDailyPrompt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spiritualAidProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return AmbientScope(
      asset: SoundService.ambientPrayerAsset,
      volume: 0.08,
      child: Scaffold(
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
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Faith Discuss',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Today's prompt
              if (state.dailyPrompt != null)
                SliverToBoxAdapter(
                  child: FaithPromptCard(
                    prompt: state.dailyPrompt!,
                    isFeatured: true,
                    onJournalTap: () => _navigateToJournal(state.dailyPrompt!),
                    onShareTap: () => _sharePrompt(state.dailyPrompt!),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Browse more section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Browse More Prompts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Category filter
              SliverToBoxAdapter(
                child: CategoryChips(
                  categories: FaithPrompt.categories,
                  selected: state.activePromptCategory,
                  onSelected: (cat) {
                    ref.read(spiritualAidProvider.notifier).filterPromptsByCategory(cat);
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Prompt list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final prompt = state.allPrompts[index];
                    return FaithPromptCard(
                      prompt: prompt,
                      onJournalTap: () => _navigateToJournal(prompt),
                      onShareTap: () => _sharePrompt(prompt),
                    );
                  },
                  childCount: state.allPrompts.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _navigateToJournal(FaithPrompt prompt) {
    context.push(
      '${AppRoutes.journal}/new',
      extra: {
        'initialTitle': 'Reflection: ${prompt.question}',
        'initialText': '${prompt.question}\n\n'
            '${prompt.context}\n\n'
            '"${prompt.relatedScripture}" - ${prompt.scriptureReference}\n\n'
            'My thoughts:\n',
      },
    );
  }

  void _sharePrompt(FaithPrompt prompt) {
    final text = '${prompt.question}\n\n'
        '"${prompt.relatedScripture}"\n'
        '- ${prompt.scriptureReference}\n\n'
        'Shared via ElBiblio';
    Share.share(text);
  }
}
