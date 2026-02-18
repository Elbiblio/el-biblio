import 'package:flutter/material.dart';

import '../../../../shared/widgets/surface_card.dart';

class SuccessCard extends StatelessWidget {
  const SuccessCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(
            Icons.auto_awesome,
            size: 64,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          Text(
            'Sparkling Clean!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep it up! You\'re a true Kingdom Citizen.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
