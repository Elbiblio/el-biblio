import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../domain/models/career_alignment.dart';
import '../widgets/gift_strength_bar.dart';

class CareerAlignmentScreen extends ConsumerStatefulWidget {
  const CareerAlignmentScreen({super.key});

  @override
  ConsumerState<CareerAlignmentScreen> createState() =>
      _CareerAlignmentScreenState();
}

class _CareerAlignmentScreenState extends ConsumerState<CareerAlignmentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alignmentProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final state = ref.watch(alignmentProvider);
    final career = state.careerAlignment;
    final profile = state.currentProfile;

    return Scaffold(
      backgroundColor: tokens.palette.background,
      appBar: AppBar(
        title: const Text('Career & Calling'),
        backgroundColor: tokens.palette.background,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : career == null
              ? _buildEmptyState(context, tokens)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Calling statement header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: tokens.pageGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: tokens.palette.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  color: tokens.palette.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'YOUR CALLING',
                                  style: Theme.of(context)
                                      .textTheme
                                      .sectionHeader
                                      .copyWith(color: tokens.palette.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              career.callingStatement,
                              style: Theme.of(context)
                                  .textTheme
                                  .spiritualSubtitle
                                  .copyWith(
                                    color: tokens.palette.textPrimary,
                                    fontSize: 16,
                                  ),
                            ),
                            if (profile != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.palette.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Based on your ${profile.archetypeName} archetype',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: tokens.palette.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Spiritual Gifts
                      Text(
                        'YOUR SPIRITUAL GIFTS',
                        style: Theme.of(context)
                            .textTheme
                            .sectionHeader
                            .copyWith(color: tokens.palette.textTertiary),
                      ),
                      const SizedBox(height: 12),
                      ...career.spiritualGifts.map((gift) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GiftStrengthBar(gift: gift),
                            // Biblical example
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: tokens.palette.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    LucideIcons.bookOpen,
                                    size: 14,
                                    color: tokens.palette.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      gift.biblicalExample,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: tokens.palette.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 8),

                      // Suggested Career Paths
                      Text(
                        'SUGGESTED PATHS',
                        style: Theme.of(context)
                            .textTheme
                            .sectionHeader
                            .copyWith(color: tokens.palette.textTertiary),
                      ),
                      const SizedBox(height: 12),
                      ...career.suggestedPaths.map((path) {
                        return _CareerPathCard(path: path);
                      }),
                      const SizedBox(height: 24),

                      // Next Steps
                      Text(
                        'NEXT STEPS',
                        style: Theme.of(context)
                            .textTheme
                            .sectionHeader
                            .copyWith(color: tokens.palette.textTertiary),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tokens.palette.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: tokens.palette.border),
                        ),
                        child: Column(
                          children: career.nextSteps
                              .asMap()
                              .entries
                              .map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: tokens.palette.primary
                                          .withValues(alpha: 0.1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${entry.key + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: tokens.palette.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: tokens.palette.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Resources
                      Text(
                        'RECOMMENDED RESOURCES',
                        style: Theme.of(context)
                            .textTheme
                            .sectionHeader
                            .copyWith(color: tokens.palette.textTertiary),
                      ),
                      const SizedBox(height: 12),
                      ...career.resources.map((resource) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tokens.palette.paper,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tokens.palette.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.book,
                                color: tokens.palette.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  resource,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: tokens.palette.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Disclaimer
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tokens.palette.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.info,
                              size: 14,
                              color: tokens.palette.textTertiary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'These suggestions are meant to inspire exploration, not prescribe a specific path. Your calling is unique, and God may lead you in unexpected directions.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tokens.palette.textTertiary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppThemeTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.briefcase,
              size: 64,
              color: tokens.palette.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Complete Your Profile First',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take the spiritual archetype assessment to unlock personalized career alignment insights.',
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareerPathCard extends StatelessWidget {
  const _CareerPathCard({required this.path});

  final CareerPath path;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.palette.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.arrowRight,
                size: 16,
                color: tokens.palette.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  path.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: tokens.palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            path.description,
            style: TextStyle(
              fontSize: 13,
              color: tokens.palette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          // Why it fits
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tokens.palette.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: tokens.palette.success.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.checkCircle,
                  size: 14,
                  color: tokens.palette.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    path.whyItFits,
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.palette.success,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Aligned gifts chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: path.alignedGifts.map((gift) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.palette.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  gift,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: tokens.palette.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
