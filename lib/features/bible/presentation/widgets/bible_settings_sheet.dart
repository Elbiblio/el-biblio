import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';

class BibleSettingsSheet extends ConsumerStatefulWidget {
  const BibleSettingsSheet({super.key});

  @override
  ConsumerState<BibleSettingsSheet> createState() => _BibleSettingsSheetState();
}

class _BibleSettingsSheetState extends ConsumerState<BibleSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final bibleState = ref.watch(bibleProvider);
    final notifier = ref.read(bibleProvider.notifier);
    final fontSize = bibleState.fontSize;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Text(
            'Font Size',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: fontSize,
                  min: 12,
                  max: 32,
                  divisions: 10,
                  label: fontSize.round().toString(),
                  onChanged: (value) {
                    notifier.setFontSize(value);
                  },
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 16),
          // Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'In the beginning God created the heavens and the earth.',
              style: TextStyle(fontSize: fontSize),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

