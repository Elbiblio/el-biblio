import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../commitments/domain/models/commitment_category.dart';
import '../../application/onboarding_notifier.dart';
import '../../application/onboarding_state.dart';

/// Step 4: Your Path — merges commitment category selection, personal
/// distraction picker, and lifestyle/schedule setup into one view.
class YourPathView extends ConsumerStatefulWidget {
  const YourPathView({super.key});

  @override
  ConsumerState<YourPathView> createState() => _YourPathViewState();
}

class _YourPathViewState extends ConsumerState<YourPathView> {
  static const _categoryDescriptions = {
    'growth': 'Strengthen your spiritual muscles daily',
    'discipline': 'Build holy habits that anchor your day',
    'charity': 'Fight addiction through grace and giving',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final archetype = notifier.primaryArchetype;

    final selectedCategory = state.commitmentCategory;
    final recommended = archetype != null
        ? CommitmentCategory.recommendedForArchetype(archetype.name)
        : CommitmentCategory.growth;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Pick one path to start with.',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (archetype != null) ...[
            const SizedBox(height: 4),
            Text(
              'Recommended for ${archetype.name}: ${recommended.label}',
              style: textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // ---------- Commitment category cards ----------
          ...CommitmentCategory.values.map((category) {
            final isSelected = selectedCategory == category.name;
            final isRecommended = category == recommended;
            final description =
                _categoryDescriptions[category.name] ?? category.description;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      notifier.setCommitmentCategory(category.name),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? category.color.withValues(alpha: 0.1)
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? category.color.withValues(alpha: 0.4)
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(category.icon,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Text(
                              category.label,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? category.color
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            if (isRecommended) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: category.color
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Recommended',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: category.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // ---------- Lifestyle & schedule ----------
          const SizedBox(height: 20),
          Text(
            'LIFESTYLE',
            style: textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildLifestyleButton(context, notifier, state, 'Student'),
              _buildLifestyleButton(
                  context, notifier, state, 'Work from Home'),
              _buildLifestyleButton(
                  context, notifier, state, 'Physical Work'),
              _buildLifestyleButton(
                  context, notifier, state, 'Not Employed'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'SCHEDULE',
            style: textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.wb_sunny_outlined,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.7)),
              title: Text(
                'Morning Presence',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 18.0,
                ),
              ),
              trailing: TextButton(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 7, minute: 30),
                  );
                  if (time != null && context.mounted) {
                    notifier.setMorningTime(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                  }
                },
                child: Text(
                  state.morningTime,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 18.0,
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.nights_stay_outlined,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.7)),
              title: Text(
                'Evening Reflection',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 18.0,
                ),
              ),
              trailing: TextButton(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 21, minute: 0),
                  );
                  if (time != null && context.mounted) {
                    notifier.setEveningTime(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                  }
                },
                child: Text(
                  state.eveningTime,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 18.0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You can change this anytime. All three paths are always available.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLifestyleButton(
    BuildContext context,
    OnboardingNotifier notifier,
    OnboardingState state,
    String title,
  ) {
    final isSelected = state.lifestyle == title;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => notifier.setLifestyle(title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
