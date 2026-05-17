import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_animations.dart';
import '../../domain/habit_catalog.dart';

/// Phase 2 – screen 2: name the virtues you already practice.
/// We start from strength so the app can reinforce and compound what's
/// already working, instead of framing growth as "fix what's broken".
class GoodHabitsView extends ConsumerStatefulWidget {
  const GoodHabitsView({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  ConsumerState<GoodHabitsView> createState() => _GoodHabitsViewState();
}

class _GoodHabitsViewState extends ConsumerState<GoodHabitsView> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...ref.read(settingsProvider).goodHabits};
  }

  Future<void> _commit() async {
    await ref.read(settingsProvider.notifier).setGoodHabits(_selected.toList());
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'What\'s already alive in you?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Name the virtues already bearing fruit in you.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kGoodHabitOptions.map((opt) {
              final isSelected = _selected.contains(opt.key);
              return _HabitChip(
                option: opt,
                selected: isSelected,
                onTap: () {
                  HapticService.selection();
                  setState(() {
                    if (isSelected) {
                      _selected.remove(opt.key);
                    } else {
                      _selected.add(opt.key);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _commit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _commit,
              child: Text(
                _selected.isEmpty ? 'Skip — I\'ll add later' : 'Done',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _HabitChip extends StatelessWidget {
  const _HabitChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final HabitOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : theme.colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
              width: selected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(option.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                option.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
