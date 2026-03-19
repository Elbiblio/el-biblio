import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/models/commitment.dart';
import '../../domain/models/daily_anchors.dart';

class CommitmentSelectionDialog extends ConsumerStatefulWidget {
  const CommitmentSelectionDialog({super.key});

  @override
  ConsumerState<CommitmentSelectionDialog> createState() => _CommitmentSelectionDialogState();
}

class _CommitmentSelectionDialogState extends ConsumerState<CommitmentSelectionDialog> {
  @override
  void initState() {
    super.initState();
    // Load commitments when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get the virtue ID from the current daily anchors
      final anchors = ref.read(dailyAnchorsProvider);
      final virtueId = _getVirtueIdFromType(anchors.coreVirtue.type);
      ref.read(commitmentProvider.notifier).loadCommitmentsForVirtue(virtueId);
    });
  }

  int _getVirtueIdFromType(VirtueType virtueType) {
    switch (virtueType) {
      case VirtueType.humility:
        return 1; // Assuming humility has ID 1
      case VirtueType.love:
        return 2; // Assuming love has ID 2
      case VirtueType.faith:
        return 3; // Assuming faith has ID 3
      case VirtueType.knowledge:
        return 4; // Assuming knowledge has ID 4
    }
  }

  @override
  Widget build(BuildContext context) {
    final commitmentState = ref.watch(commitmentProvider);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.assignment_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Choose Your Commitment',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select a commitment to practice today',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                if (commitmentState.isUsingOfflineData) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 12,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Offline',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (commitmentState.isUsingOfflineData) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Using offline commitments. Connect to internet for more options.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Content
            if (commitmentState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (commitmentState.error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load commitments',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        commitmentState.error!,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              ref.read(commitmentProvider.notifier).clearError();
                              // Retry loading with current virtue
                              final anchors = ref.read(dailyAnchorsProvider);
                              final virtueId = _getVirtueIdFromType(anchors.coreVirtue.type);
                              ref.read(commitmentProvider.notifier).retryLoadCommitments(virtueId);
                            },
                            child: const Text('Retry'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(commitmentProvider.notifier).clearError();
                              // Load offline commitments directly
                              final anchors = ref.read(dailyAnchorsProvider);
                              ref.read(commitmentProvider.notifier)
                                  .setOfflineCommitments(anchors.coreVirtue.type);
                            },
                            child: const Text('Use Offline'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Commitments List
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: commitmentState.commitments.length,
                  itemBuilder: (context, index) {
                    final commitment = commitmentState.commitments[index];
                    final isSelected = commitmentState.selectedCommitment?.id == commitment.id;
                    
                    return CommitmentTile(
                      commitment: commitment,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(commitmentProvider.notifier).selectCommitment(commitment);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: commitmentState.selectedCommitment != null
                        ? () => Navigator.of(context).pop(commitmentState.selectedCommitment)
                        : null,
                    child: const Text('Start Commitment'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CommitmentTile extends StatelessWidget {
  const CommitmentTile({
    super.key,
    required this.commitment,
    required this.isSelected,
    required this.onTap,
  });

  final Commitment commitment;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    commitment.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              commitment.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // Tags and metadata row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Duration
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${commitment.durationMinutes} min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Difficulty
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(commitment.difficultyLevel).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getDifficultyText(commitment.difficultyLevel),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getDifficultyColor(commitment.difficultyLevel),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  
                  // Tags
                  ...commitment.categoryTags.map((tag) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficultyText(int level) {
    switch (level) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      case 4:
        return 'Expert';
      case 5:
        return 'Master';
      default:
        return 'Medium';
    }
  }

  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}
