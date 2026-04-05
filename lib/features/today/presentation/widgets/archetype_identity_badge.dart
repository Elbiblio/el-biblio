import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';

/// A compact badge showing the user's spiritual archetype in the header.
///
/// Displays a small circle with the archetype initial, the archetype name,
/// and a subtle identity label. Only renders if the user has an archetype set.
class ArchetypeIdentityBadge extends ConsumerWidget {
  const ArchetypeIdentityBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alignmentState = ref.watch(alignmentProvider);
    final settings = ref.watch(settingsProvider);

    final archetypeName = alignmentState.currentProfile?.archetypeName;
    final archetypeId = settings.primaryArchetypeId;

    // Don't render if no archetype is set
    if ((archetypeName == null || archetypeName.isEmpty) &&
        (archetypeId == null || archetypeId.isEmpty)) {
      return const SizedBox.shrink();
    }

    final displayName = archetypeName ?? _formatArchetypeId(archetypeId!);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Archetype initial circle
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Archetype name
          Text(
            displayName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7C3AED),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Converts an archetype ID like 'the_guardian' to 'The Guardian'.
  String _formatArchetypeId(String id) {
    return id
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
