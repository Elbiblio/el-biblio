import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../commitments/domain/models/commitment_category.dart';

class VirtueFocusBadge extends ConsumerWidget {
  const VirtueFocusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    final archetypeName = settings.primaryArchetypeId;
    final categoryName = settings.commitmentCategory;
    final category = categoryName == null
        ? null
        : CommitmentCategory.fromString(categoryName);

    // Build a singular identity line: "Artisan · Charity" or just the category
    String identityLine;
    if (archetypeName != null && archetypeName.isNotEmpty && category != null) {
      final categoryLabel = category.label;
      identityLine = '$archetypeName · $categoryLabel';
    } else if (archetypeName != null && archetypeName.isNotEmpty) {
      identityLine = archetypeName;
    } else if (category != null) {
      identityLine = category.label;
    } else {
      identityLine = 'Discover your identity';
    }

    final categoryColor = _getCategoryColor(categoryName, tokens);

    return GestureDetector(
      onTap: () {
        _showVirtueSelectionDialog(context, ref);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(categoryName),
            size: 20,
            color: categoryColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              identityLine,
              style: theme.textTheme.titleSmall?.copyWith(
                color: categoryColor,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: categoryColor.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? category, AppThemeTokens tokens) {
    return switch (category) {
      'growth' => tokens.palette.growthColor,
      'discipline' => tokens.palette.distractionColor,
      'charity' => tokens.palette.commitmentColor,
      _ => tokens.palette.primary,
    };
  }

  IconData _getCategoryIcon(String? category) {
    return switch (category) {
      'growth' => Icons.trending_up_rounded,
      'discipline' => Icons.shield_rounded,
      'charity' => Icons.volunteer_activism_rounded,
      _ => Icons.explore_rounded,
    };
  }

  void _showVirtueSelectionDialog(BuildContext context, WidgetRef ref) {
    final currentCategory = ref.read(settingsProvider).commitmentCategory;
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    final categories = [
      ('growth', 'Growth', 'Strengthen your spiritual muscles', Icons.trending_up_rounded, tokens.palette.growthColor),
      ('discipline', 'Discipline', 'Build holy habits that anchor your day', Icons.shield_rounded, tokens.palette.distractionColor),
      ('charity', 'Charity', 'Fight addiction through grace and giving', Icons.volunteer_activism_rounded, tokens.palette.commitmentColor),
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Your Path'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories.map((cat) {
              final isSelected = cat.$1 == currentCategory;
              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cat.$5.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: cat.$5, width: 2) : null,
                  ),
                  child: Icon(cat.$4, size: 18, color: cat.$5),
                ),
                title: Text(
                  cat.$2,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: cat.$5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(cat.$3, style: Theme.of(context).textTheme.bodySmall),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: cat.$5, size: 20)
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setCommitmentCategory(cat.$1);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
