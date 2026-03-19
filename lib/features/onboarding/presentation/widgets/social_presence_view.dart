import 'package:flutter/material.dart';

import '../../application/onboarding_notifier.dart';
import '../../application/onboarding_state.dart';
import 'responsive_layout_builder.dart';

class SocialPresenceView extends StatelessWidget {
  const SocialPresenceView({
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
      mobile: (context, constraints) => _buildSocialPresenceContent(context, notifier, state, isDesktop: false),
      tablet: (context, constraints) => _buildSocialPresenceContent(context, notifier, state, isDesktop: false),
      desktop: (context, constraints) => _buildSocialPresenceContent(context, notifier, state, isDesktop: true),
    );
  }

  Widget _buildSocialPresenceContent(BuildContext context, OnboardingNotifier notifier, OnboardingState state, {required bool isDesktop}) {
    const horizontalPadding = 24.0;
    const contentMaxWidth = 400.0; // Smaller max width to match design
    
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 32.0),
              
              // Title
              Text(
                'Share Elbiblio with Others',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 40.0,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64.0),
              
              // Features list
              _buildFeatureItem(
                context,
                icon: Icons.visibility_off_outlined,
                title: 'Anonymous',
                description: 'No names, faces, or profiles',
              ),
              const SizedBox(height: 24.0),
              
              _buildFeatureItem(
                context,
                icon: Icons.spa_outlined,
                title: 'Pure Practice',
                description: 'No likes, feeds, or distractions',
              ),
              const SizedBox(height: 40.0),
              
              // Friends activity card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: const Color(0xFFA3B59A), // sage-glow
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C8B74).withValues(alpha: 0.1), // sage-primary/10
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.group_outlined,
                        color: Color(0xFF5A6654), // sage-dark
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '3 friends checked in today',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.wb_twilight_outlined,
                                    size: 14,
                                    color: Color(0xFF5C5852), // ink-secondary
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '3 morning',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      color: const Color(0xFF5C5852),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5C5852).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.dark_mode_outlined,
                                    size: 14,
                                    color: Color(0xFF5C5852), // ink-secondary
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '1 evening',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      color: const Color(0xFF5C5852),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF7C8B74).withValues(alpha: 0.1), // sage-primary/10
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF5A6654), // sage-dark
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 15,
                  height: 1.4,
                  color: const Color(0xFF5C5852), // ink-secondary
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
