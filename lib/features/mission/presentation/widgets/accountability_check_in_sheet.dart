import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../assessment/domain/models/weekly_plan.dart';
import '../../domain/models/check_in_request.dart';

/// Enhanced check-in sheet with partner confirmation and shared commitment visibility
class AccountabilityCheckInSheet extends ConsumerStatefulWidget {
  const AccountabilityCheckInSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AccountabilityCheckInSheet(),
    );
  }

  @override
  ConsumerState<AccountabilityCheckInSheet> createState() =>
      _AccountabilityCheckInSheetState();
}

class _AccountabilityCheckInSheetState
    extends ConsumerState<AccountabilityCheckInSheet> {
  final _noteController = TextEditingController();
  final Set<String> _selectedCommitments = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final mission = ref.watch(missionProvider);
    final partner = mission.accountabilityPartner;
    final weeklyPlan = ref.watch(settingsProvider).currentWeeklyPlan;
    final pendingRequest = partner?.pendingCheckInRequest;

    if (partner == null) {
      return _buildNoPartnerView(theme);
    }

    // If there's a pending request, show the confirmation view (for the partner)
    if (pendingRequest != null && pendingRequest.isPending) {
      return _buildConfirmationView(
        theme: theme,
        tokens: tokens,
        partner: partner,
        request: pendingRequest,
        weeklyPlan: weeklyPlan,
      );
    }

    // Otherwise show the request view (for the user requesting check-in)
    return _buildRequestView(
      theme: theme,
      tokens: tokens,
      partner: partner,
      weeklyPlan: weeklyPlan,
    );
  }

  Widget _buildNoPartnerView(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Add an Accountability Partner',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your commitments and progress with a trusted friend or mentor.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.growTogether);
              },
              child: const Text('Find an Accountability Partner'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestView({
    required ThemeData theme,
    required AppThemeTokens tokens,
    required partner,
    required WeeklyPlan? weeklyPlan,
  }) {
    final commitments = weeklyPlan?.weeklyCommitments ?? [];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.mark_chat_read_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Check-in',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Share your progress with ${partner.name}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Weekly Streak
              if (partner.weeklyStreak > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${partner.weeklyStreak} week streak!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              if (partner.weeklyStreak > 0) const SizedBox(height: 16),

              // This Week's Commitments
              if (commitments.isNotEmpty) ...[
                Text(
                  'This Week\'s Commitments',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...commitments.map((commitment) {
                  final isSelected = _selectedCommitments.contains(
                    commitment.id,
                  );
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedCommitments.add(commitment.id);
                        } else {
                          _selectedCommitments.remove(commitment.id);
                        }
                      });
                    },
                    title: Text(commitment.title),
                    subtitle: Text(
                      '${commitment.currentCount}/${commitment.targetCount} completed',
                      style: theme.textTheme.bodySmall,
                    ),
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: commitment.isComplete
                            ? Colors.green.withValues(alpha: 0.2)
                            : theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        commitment.isComplete
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: commitment.isComplete
                            ? Colors.green
                            : theme.colorScheme.primary,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    activeColor: theme.colorScheme.primary,
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Check-in Note
              Text(
                'Message to ${partner.name}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share what you accomplished this week, challenges you faced, or prayer requests...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          await _submitRequest();
                        },
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting
                      ? 'Sending...'
                      : 'Request Check-in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationView({
    required ThemeData theme,
    required AppThemeTokens tokens,
    required partner,
    required CheckInRequest request,
    required WeeklyPlan? weeklyPlan,
  }) {
    final confirmationController = TextEditingController();
    final Set<String> verifiedCommitments = {...request.verifiedCommitments};

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.verified_rounded,
                          color: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirm Check-in',
                              style:
                                  theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Verify ${partner.name}\'s progress',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Their Message
                  if (request.note != null && request.note!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Their Message:',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            request.note!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Verify Commitments
                  Text(
                    'Verify Completed Commitments',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...request.verifiedCommitments.map((commitmentId) {
                    final commitment = weeklyPlan?.weeklyCommitments
                        .where((c) => c.id == commitmentId)
                        .firstOrNull;
                    if (commitment == null) return const SizedBox.shrink();

                    final isVerified = verifiedCommitments.contains(commitmentId);
                    return CheckboxListTile(
                      value: isVerified,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            verifiedCommitments.add(commitmentId);
                          } else {
                            verifiedCommitments.remove(commitmentId);
                          }
                        });
                      },
                      title: Text(commitment.title),
                      subtitle: const Text('They reported completing this'),
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  const SizedBox(height: 16),

                  // Your Response
                  Text(
                    'Your Response',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmationController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add encouragement, feedback, or prayer...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Later'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await ref
                                .read(missionProvider.notifier)
                                .confirmCheckIn(
                                  confirmationNote:
                                      confirmationController.text.trim(),
                                  verifiedCommitmentIds:
                                      verifiedCommitments.toList(),
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Check-in confirmed!'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('Confirm Check-in'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitRequest() async {
    setState(() => _isSubmitting = true);

    await ref.read(missionProvider.notifier).requestCheckIn(
          note: _noteController.text.trim(),
          completedCommitmentIds: _selectedCommitments.toList(),
        );

    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in request sent!'),
        ),
      );
    }
  }
}
