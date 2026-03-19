import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/meditation_notifier.dart';
import '../../domain/models/meditation_enums.dart';
import '../../domain/models/meditation_templates.dart';

// ── Step 0: Simplified Style Selection ─────────────────────────────────────

class SimplifiedStyleSelectionStep extends StatelessWidget {
  const SimplifiedStyleSelectionStep({
    super.key,
    required this.selectedStyle,
    required this.notifier,
    this.onSelectionChanged,
  });

  final MeditationStyle selectedStyle;
  final MeditationNotifier notifier;
  final VoidCallback? onSelectionChanged;

  static const _styleIcons = {
    MeditationStyle.quietReflection: Icons.self_improvement_rounded,
    MeditationStyle.bible: Icons.menu_book_rounded,
    MeditationStyle.affirmation: Icons.psychology_rounded,
    MeditationStyle.chant: Icons.music_note_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you like\nto meet with God?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a practice for today.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: MeditationStyle.values.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SimplifiedStyleCard(
                    style: s,
                    icon: _styleIcons[s] ?? Icons.circle_outlined,
                    selected: s == selectedStyle,
                    onTap: () {
                notifier.setStyle(s);
                onSelectionChanged?.call();
              },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimplifiedStyleCard extends StatelessWidget {
  const _SimplifiedStyleCard({
    required this.style,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final MeditationStyle style;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      style.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: theme.colorScheme.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 1: Bible Template Selection ────────────────────────────────────────

class BibleTemplateStep extends ConsumerWidget {
  const BibleTemplateStep({
    super.key,
    required this.selectedTemplate,
    required this.notifier,
    this.onSelectionChanged,
  });

  final BibleTemplate? selectedTemplate;
  final MeditationNotifier notifier;
  final VoidCallback? onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What will you\nreflect on today?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a Bible meditation focus.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: BibleTemplate.values.map((template) {
                final isSelected = template == selectedTemplate;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BibleTemplateCard(
                    template: template,
                    selected: isSelected,
                    onTap: () {
                    notifier.setBibleTemplate(template);
                    onSelectionChanged?.call();
                  },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BibleTemplateCard extends StatelessWidget {
  const _BibleTemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final BibleTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 1: Affirmation Category Selection ──────────────────────────────────

class AffirmationCategoryStep extends ConsumerWidget {
  const AffirmationCategoryStep({
    super.key,
    required this.selectedCategory,
    required this.notifier,
    this.onSelectionChanged,
  });

  final AffirmationCategory? selectedCategory;
  final MeditationNotifier notifier;
  final VoidCallback? onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What will you\nfocus on today?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Choose an affirmation direction.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: AffirmationCategory.values.map((category) {
                final isSelected = category == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _AffirmationCategoryCard(
                    category: category,
                    selected: isSelected,
                    onTap: () {
                      notifier.setAffirmationCategory(category);
                      onSelectionChanged?.call();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Virtue Affirmation Selection ───────────────────────────────────

class VirtueAffirmationStep extends ConsumerWidget {
  const VirtueAffirmationStep({
    super.key,
    required this.selectedAffirmation,
    required this.notifier,
    this.onSelectionChanged,
  });

  final VirtueAffirmation? selectedAffirmation;
  final MeditationNotifier notifier;
  final VoidCallback? onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Which virtue will you\ncultivate today?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Focus on one. Let it shape your day.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: VirtueAffirmation.values.map((affirmation) {
                final isSelected = affirmation == selectedAffirmation;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _VirtueAffirmationCard(
                    affirmation: affirmation,
                    selected: isSelected,
                    onTap: () {
                      notifier.setVirtueAffirmation(affirmation);
                      onSelectionChanged?.call();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Habit Affirmation Selection ────────────────────────────────────

class HabitAffirmationStep extends ConsumerWidget {
  const HabitAffirmationStep({
    super.key,
    required this.selectedAffirmation,
    required this.notifier,
    this.onSelectionChanged,
  });

  final HabitAffirmation? selectedAffirmation;
  final MeditationNotifier notifier;
  final VoidCallback? onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What habit will you\novercome today?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Choose grace over struggle.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: HabitAffirmation.values.map((affirmation) {
                final isSelected = affirmation == selectedAffirmation;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _HabitAffirmationCard(
                    affirmation: affirmation,
                    selected: isSelected,
                    onTap: () {
                    notifier.setHabitAffirmation(affirmation);
                    onSelectionChanged?.call();
                  },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitAffirmationCard extends StatelessWidget {
  const _HabitAffirmationCard({
    required this.affirmation,
    required this.selected,
    required this.onTap,
  });

  final HabitAffirmation affirmation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                affirmation.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                affirmation.text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 2: Custom Bible Verses Input ─────────────────────────────────────

class CustomBibleVersesStep extends ConsumerStatefulWidget {
  const CustomBibleVersesStep({
    super.key,
    required this.notifier,
  });

  final MeditationNotifier notifier;

  @override
  ConsumerState<CustomBibleVersesStep> createState() => _CustomBibleVersesStepState();
}

class _CustomBibleVersesStepState extends ConsumerState<CustomBibleVersesStep> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final currentVerses = ref.read(meditationProvider).customBibleVerses ?? '';
    _controller = TextEditingController(text: currentVerses);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your Bible verses',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add the verses you want to meditate on.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your favorite Bible verses here...\n\nExample:\nJohn 3:16 - For God so loved the world...\nProverbs 3:5-6 - Trust in the Lord with all your heart...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onChanged: (value) {
                widget.notifier.setCustomBibleVerses(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AffirmationCategoryCard extends StatelessWidget {
  const _AffirmationCategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final AffirmationCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _VirtueAffirmationCard extends StatelessWidget {
  const _VirtueAffirmationCard({
    required this.affirmation,
    required this.selected,
    required this.onTap,
  });

  final VirtueAffirmation affirmation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                affirmation.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                affirmation.text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
