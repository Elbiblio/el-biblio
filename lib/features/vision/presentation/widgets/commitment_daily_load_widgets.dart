import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../../domain/vision_models.dart';

class CommitmentSnapshotBanner extends StatelessWidget {
  const CommitmentSnapshotBanner({
    super.key,
    required this.active,
    this.asset = VisionIllustrationAsset.commitment,
  });

  final CommitmentSeason active;
  final VisionIllustrationAsset asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final progress = active.progress.clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.28),
            tokens.palette.growthColor.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day ${active.currentDay}/${active.plan.durationDays}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tokens.palette.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  active.completionPercentLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 0.98,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${active.completedTodayItemCount}/${active.totalRequiredItemCount} today - ${active.dailyLoadLabel}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.palette.textSecondary,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox.square(
            dimension: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.square(
                  dimension: 92,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    backgroundColor: theme.colorScheme.surface.withValues(
                      alpha: 0.78,
                    ),
                  ),
                ),
                VisionIllustration(
                  asset: asset,
                  size: 66,
                  semanticLabel: active.plan.title,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommitmentProgressStrip extends StatelessWidget {
  const CommitmentProgressStrip({super.key, required this.active});

  final CommitmentSeason active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatPill(
          icon: LucideIcons.calendarDays,
          label: 'Day ${active.currentDay}/${active.plan.durationDays}',
        ),
        _StatPill(
          icon: LucideIcons.percent,
          label: active.completionPercentLabel,
        ),
        _StatPill(
          icon: LucideIcons.listChecks,
          label:
              '${active.completedTodayItemCount}/${active.totalRequiredItemCount} today',
        ),
        _StatPill(
          icon: LucideIcons.layers,
          label: active.dailyLoadLabel,
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }
}

class CommitmentDailyChecklist extends StatelessWidget {
  const CommitmentDailyChecklist({
    super.key,
    required this.items,
    this.onItemTap,
  });

  final List<CommitmentDailyItem> items;
  final ValueChanged<CommitmentDailyItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.isEmpty
        ? const <CommitmentDailyItem>[]
        : items.take(3).toList(growable: false);
    if (visibleItems.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < visibleItems.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ChecklistRow(item: visibleItems[i], onTap: onItemTap),
        ],
      ],
    );
  }
}

class DailyLoadSelector extends StatelessWidget {
  const DailyLoadSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LoadChoice(
          count: 1,
          label: 'Light',
          detail: '1 action today',
          selected: value == 1,
          enabled: enabled,
          onTap: () => onChanged(1),
        ),
        const SizedBox(height: 8),
        _LoadChoice(
          count: 2,
          label: 'Steady',
          detail: '2 actions today',
          selected: value == 2,
          enabled: enabled,
          onTap: () => onChanged(2),
        ),
        const SizedBox(height: 8),
        _LoadChoice(
          count: 3,
          label: 'Deep',
          detail: '3 actions today',
          selected: value == 3,
          enabled: enabled,
          onTap: () => onChanged(3),
        ),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.item, this.onTap});

  final CommitmentDailyItem item;
  final ValueChanged<CommitmentDailyItem>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final completed = item.completedToday;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(item),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: completed
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.22)
                : theme.colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: completed
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : tokens.palette.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                completed ? LucideIcons.checkCircle : LucideIcons.circle,
                size: 19,
                color: completed
                    ? theme.colorScheme.primary
                    : tokens.palette.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    if (item.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.palette.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadChoice extends StatelessWidget {
  const _LoadChoice({
    required this.count,
    required this.label,
    required this.detail,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int count;
  final String label;
  final String detail;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.34)
              : theme.colorScheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.42)
                : theme.tokens.palette.border,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: selected ? 0.18 : 0.1,
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(detail, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (selected)
              Icon(
                LucideIcons.checkCircle,
                size: 20,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.primary;
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
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
