import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Profile Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Onboarding completed: ${settings.onboardingCompleted}'),
            const SizedBox(height: 8),
            Text('Primary virtue: ${settings.primaryVirtue.name}'),
            const SizedBox(height: 8),
            Text('Neglected virtue: ${settings.neglectedVirtue.name}'),
            const SizedBox(height: 24),
            if (settings.onboardingCompleted)
              ElevatedButton(
                onPressed: () async {
                  await ref.read(settingsProvider.notifier).resetOnboarding();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Onboarding reset. Restart app to test again.')),
                    );
                  }
                },
                child: const Text('Reset Onboarding (Debug)'),
              ),
          ],
        ),
      ),
    );
  }
}
