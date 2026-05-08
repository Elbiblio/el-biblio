import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../mission/presentation/widgets/accountability_check_in_sheet.dart';

/// Shown on Today when a check-in request is pending partner confirmation.
/// Tapping opens the check-in sheet directly; dismiss removes it for the session.
class PendingCheckInCard extends ConsumerStatefulWidget {
  const PendingCheckInCard({super.key});

  @override
  ConsumerState<PendingCheckInCard> createState() => _PendingCheckInCardState();
}

class _PendingCheckInCardState extends ConsumerState<PendingCheckInCard> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final partner = ref.watch(missionProvider.select((s) => s.accountabilityPartner));
    final pending = partner?.pendingCheckInRequest;

    if (partner == null || pending == null || !pending.isPending) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Theme-aware pending palette — amber-like in light, copper-like in dark.
    final pendingBg = scheme.tertiaryContainer;
    final pendingBorder = scheme.tertiary.withValues(alpha: 0.4);
    final pendingTextStrong = scheme.onTertiaryContainer;
    final pendingTextSoft = scheme.onTertiaryContainer.withValues(alpha: 0.8);
    final pendingAccent = scheme.tertiary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: pendingBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: pendingBorder, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.pending_actions_rounded,
                color: pendingAccent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Awaiting ${partner.name}\'s confirmation',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: pendingTextStrong,
                    ),
                  ),
                  Text(
                    'Your check-in was sent. Tap to review or confirm.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: pendingTextSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await AccountabilityCheckInSheet.show(context);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: pendingAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'View',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => setState(() => _dismissed = true),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close,
                    size: 16,
                    color: pendingAccent.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
