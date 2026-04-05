import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../application/meditation_notifier.dart';

/// A two-step prompt shown after meditation completion.
///
/// Asks the user "Did you sense God speaking to you?" with Yes/No buttons.
/// - Yes: navigates to the journal editor with a specialized "God spoke" template.
/// - No: shows encouragement and offers generic journaling.
class GodSpokePrompt extends ConsumerStatefulWidget {
  const GodSpokePrompt({super.key});

  @override
  ConsumerState<GodSpokePrompt> createState() => _GodSpokePromptState();
}

class _GodSpokePromptState extends ConsumerState<GodSpokePrompt>
    with SingleTickerProviderStateMixin {
  /// null = initial prompt, true = yes selected, false = no selected
  bool? _answer;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onYes() {
    setState(() => _answer = true);
    _fadeController.forward();
  }

  void _onNo() {
    setState(() => _answer = false);
    _fadeController.forward();
  }

  void _navigateToGodSpokeJournal() {
    final state = ref.read(meditationProvider);
    final notifier = ref.read(meditationProvider.notifier);

    final now = DateTime.now();
    final dateStr = '${now.month}/${now.day}/${now.year}';
    final styleLabel = state.style.label;

    final title = 'God Spoke to Me - $styleLabel Meditation ($dateStr)';

    final initialText =
        'During my ${state.selectedMinutes}-minute $styleLabel meditation, '
        'I sensed God speaking to me.\n\n'
        'What I heard:\n\n\n'
        'How it made me feel:\n\n\n'
        'What I believe God wants me to do:\n\n';

    final virtues = <String>['faith'];
    if (state.virtueName != null && state.virtueName!.isNotEmpty) {
      virtues.add(state.virtueName!);
    }

    notifier.resetToSetup();
    if (context.mounted) {
      context.push('${AppRoutes.journal}/new', extra: {
        'initialTitle': title,
        'initialText': initialText,
        'initialVirtues': virtues,
        'meditationSessionId': state.guide?.title ?? '',
      });
    }
  }

  void _navigateToGenericJournal() {
    final state = ref.read(meditationProvider);
    final notifier = ref.read(meditationProvider.notifier);

    final now = DateTime.now();
    final dateStr = '${now.month}/${now.day}/${now.year}';
    final styleLabel = state.style.label;

    final title = '$styleLabel Meditation - $dateStr';
    var initialText =
        'Reflections from my ${state.selectedMinutes}-minute $styleLabel meditation:\n\n';

    if (state.virtueName != null && state.virtueName!.isNotEmpty) {
      initialText += 'Focus: ${state.virtueName}\n\n';
    }

    initialText +=
        'What I noticed:\n\n\nWhat I\'m grateful for:\n\n\nHow I want to carry this forward:\n\n';

    final virtues = state.virtueName != null && state.virtueName!.isNotEmpty
        ? [state.virtueName!]
        : <String>[];

    notifier.resetToSetup();
    if (context.mounted) {
      context.push('${AppRoutes.journal}/new', extra: {
        'initialTitle': title,
        'initialText': initialText,
        'initialVirtues': virtues,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_answer == null) {
      return _buildPrompt(theme);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _answer == true
          ? _buildYesResponse(theme)
          : _buildNoResponse(theme),
    );
  }

  Widget _buildPrompt(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.hearing_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Did you sense God speaking to you?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a moment to reflect on your experience.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _onYes,
                  icon: const Icon(Icons.favorite_rounded, size: 18),
                  label: const Text('Yes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _onNo,
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  label: const Text('Not Today'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYesResponse(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'That is wonderful!',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture what you heard. Writing it down helps you remember '
            'and respond to what God is saying.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _navigateToGodSpokeJournal,
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: const Text('Write What God Said'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResponse(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.spa_rounded,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'That is okay.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'God is always near, even in the silence. '
            'Your faithfulness in showing up matters. '
            'Would you like to journal about your experience?',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _navigateToGenericJournal,
              icon: const Icon(Icons.edit_note_outlined, size: 20),
              label: const Text('Journal About This'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
