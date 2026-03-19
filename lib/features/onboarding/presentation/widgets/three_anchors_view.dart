import 'package:flutter/material.dart';

import 'responsive_layout_builder.dart';

class ThreeAnchorsView extends StatelessWidget {
  const ThreeAnchorsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      mobile: (context, constraints) => _buildThreeAnchorsContent(context, isDesktop: false),
      tablet: (context, constraints) => _buildThreeAnchorsContent(context, isDesktop: false),
      desktop: (context, constraints) => _buildThreeAnchorsContent(context, isDesktop: true),
    );
  }

  Widget _buildThreeAnchorsContent(BuildContext context, {required bool isDesktop}) {
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
              const SizedBox(height: 32.0),              
              
              // Description
              Text(
                'A gentle framework for daily alignment.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                  fontSize: 18.0,
                ),
                textAlign: isDesktop ? TextAlign.center : TextAlign.start,
              ),
              const SizedBox(height: 32.0),
              
              // Description
              Text(
                'Pray for a committment. Practice it for at least 4 hours. Review how you did.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                  fontSize: 16.0,
                  fontStyle: FontStyle.italic
                ),
                textAlign: isDesktop ? TextAlign.center : TextAlign.start,
              ),
              const SizedBox(height: 32.0),
              
              // Anchors List
              _buildAnchorItem(
                context,
                icon: Icons.diamond_outlined,
                title: 'Pray',
                subtitle: 'Intentional Living',
              ),
              const SizedBox(height: 16),
              
              _buildAnchorItem(
                context,
                icon: Icons.water_drop_outlined,
                title: 'Practice',
                subtitle: 'Commit to Intention',
              ),
              const SizedBox(height: 16),
              
              _buildAnchorItem(
                context,
                icon: Icons.directions_walk_outlined,
                title: 'Review',
                subtitle: 'Learn and Grow',
              ),
              
              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnchorItem(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
