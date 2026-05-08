import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../application/companion_notifier.dart';
import '../../domain/models/companion_character.dart';
import '../../domain/models/companion_mood.dart';
import 'companion_orb.dart';

/// Shown on Today when:
///   - a companion is selected, AND
///   - no human accountability partner is set
///
/// One-tap: sets the companion as AI accountability partner (schedules the
/// Friday 7 PM weekly check-in notification). Renders nothing otherwise.
class AiPartnerInviteCard extends ConsumerStatefulWidget {
  const AiPartnerInviteCard({super.key});

  @override
  ConsumerState<AiPartnerInviteCard> createState() =>
      _AiPartnerInviteCardState();
}

class _AiPartnerInviteCardState extends ConsumerState<AiPartnerInviteCard> {
  bool _dismissed = false;
  bool _enabling = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final companion = ref.watch(
      companionProvider.select((s) => s.activeCharacter),
    );
    final partner = ref.watch(
      missionProvider.select((s) => s.accountabilityPartner),
    );

    if (companion == null || _dismissed) return const SizedBox.shrink();
    if (partner != null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CompanionOrb(
              character: companion,
              mood: CompanionMood.warm,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Walk with ${companion.displayName} until a human partner joins',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Friday check-ins, three questions, always there.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                FilledButton(
                  onPressed: _enabling
                      ? null
                      : () => _enable(companion),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _enabling
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Yes'),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () => setState(() => _dismissed = true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    child: Text(
                      'Not now',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enable(CompanionCharacter companion) async {
    setState(() => _enabling = true);
    await ref.read(missionProvider.notifier).enableAiAccountabilityPartner(
          companionCode: companion.code,
          companionDisplayName: companion.displayName,
        );
    if (!mounted) return;
    setState(() {
      _enabling = false;
      _dismissed = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${companion.displayName} will check in with you each Friday.',
        ),
      ),
    );
  }
}
