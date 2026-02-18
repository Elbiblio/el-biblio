import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/models/bible_version.dart';

class BibleVersionsSheet extends ConsumerWidget {
  const BibleVersionsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bibleState = ref.watch(bibleProvider);
    final notifier = ref.read(bibleProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Bible Versions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (bibleState.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  bibleState.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: bibleState.availableVersions.length,
                itemBuilder: (context, index) {
                  final version = bibleState.availableVersions[index];
                  final isSelected = version.id == bibleState.currentVersion?.id;
                  final isDownloading = bibleState.downloadingVersionId == version.id;

                  return ListTile(
                    title: Text(version.name),
                    subtitle: Text(version.language),
                    leading: isSelected
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                        : null,
                    trailing: _buildTrailing(context, version, isDownloading, bibleState.downloadProgress, notifier),
                    onTap: () {
                      notifier.selectVersion(version);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrailing(
    BuildContext context,
    BibleVersion version,
    bool isDownloading,
    double progress,
    dynamic notifier,
  ) {
    if (isDownloading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2,
        ),
      );
    }

    if (version.isDownloaded) {
      return const Icon(Icons.download_done, color: Colors.green);
    }

    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: () => notifier.downloadVersion(version),
    );
  }
}
