import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_notifier.dart';
import '../../../commitments/domain/models/commitment_category.dart';

/// Step 8: Ready — final launch screen before entering the app.
class ReadyView extends ConsumerStatefulWidget {
  const ReadyView({super.key});

  @override
  ConsumerState<ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends ConsumerState<ReadyView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final archetype = notifier.primaryArchetype;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            const SizedBox(height: 48),
            // Checkmark circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 44,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your clarity journey\nstarts now.',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            if (archetype != null)
              Text(
                'As a ${archetype.name}, your path to focus is unique.\nElbiblio will guide you every step of the way.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              )
            else
              Text(
                'Elbiblio will guide your spiritual growth\nevery step of the way.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 40),
            // Summary of what's set up
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Your setup',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (archetype != null)
                    _buildSummaryRow(
                      context,
                      Icons.person_outline,
                      'Identity',
                      '${archetype.name} (${archetype.identity})',
                    ),
                  if (state.commitmentCategory != null)
                    _buildSummaryRow(
                      context,
                      Icons.flag_outlined,
                      'Starting path',
                      CommitmentCategory.fromString(state.commitmentCategory!).label,
                    ),
                  _buildSummaryRow(
                    context,
                    Icons.wb_sunny_outlined,
                    'Morning',
                    state.morningTime,
                  ),
                  _buildSummaryRow(
                    context,
                    Icons.nightlight_round,
                    'Evening',
                    state.eveningTime,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
