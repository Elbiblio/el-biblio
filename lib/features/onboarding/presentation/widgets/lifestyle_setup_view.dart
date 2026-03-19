import 'package:flutter/material.dart';

import '../../application/onboarding_notifier.dart';
import '../../application/onboarding_state.dart';
import 'responsive_layout_builder.dart';

class LifestyleSetupView extends StatelessWidget {
  const LifestyleSetupView({
    super.key,
    required this.notifier,
    required this.state,
    required this.isDesktop,
  });

  final OnboardingNotifier notifier;
  final OnboardingState state;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      mobile: (context, constraints) => _buildLifestyleSetupContent(context, notifier, state, isDesktop: false),
      tablet: (context, constraints) => _buildLifestyleSetupContent(context, notifier, state, isDesktop: false),
      desktop: (context, constraints) => _buildLifestyleSetupContent(context, notifier, state, isDesktop: true),
    );
  }

  Widget _buildLifestyleSetupContent(BuildContext context, OnboardingNotifier notifier, OnboardingState state, {required bool isDesktop}) {
    const horizontalPadding = 24.0;
    const contentMaxWidth = 600.0;
    
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 42.0),
              
              
              // Description
              Text(
                'Aligning your spiritual practice with your life.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                  fontSize: 16.0,
                ),
                textAlign: isDesktop ? TextAlign.center : TextAlign.start,
              ),
              const SizedBox(height: 32.0),
              
              // Lifestyle Section
              Text(
                'CURRENT LIFESTYLE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8.0),
              
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _buildLifestyleButton(context, notifier, state, 'Student'),
                  _buildLifestyleButton(context, notifier, state, 'Work from Home'),
                  _buildLifestyleButton(context, notifier, state, 'Physical Work'),
                  _buildLifestyleButton(context, notifier, state, 'Not Employed'),
                ],
              ),
              const SizedBox(height: 32.0),
              
              // Daily Rhythm Section
              Text(
                'DAILY RHYTHM',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16.0),
              
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.wb_sunny_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  title: Text(
                    'Morning Presence',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        notifier.setMorningTime('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                      }
                    },
                    child: Text(
                      state.morningTime,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.nights_stay_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  title: Text(
                    'Evening Reflection',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 18.0,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 21, minute: 00),
                      );
                      if (time != null && context.mounted) {
                        notifier.setEveningTime('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                      }
                    },
                    child: Text(
                      state.eveningTime,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLifestyleButton(BuildContext context, OnboardingNotifier notifier, OnboardingState state, String title) {
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
            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
