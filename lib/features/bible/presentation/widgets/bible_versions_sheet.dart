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
                  final isSelected = version.abbreviation == bibleState.currentVersion?.abbreviation;
                  final isDownloading = bibleState.downloadingVersionId == version.abbreviation;

                  return ListTile(
                    title: Text(version.name ?? version.abbreviation),
                    subtitle: Text(version.language ?? 'Unknown'),
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
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          if (progress > 0)
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      );
    }

    if (version.isDownloaded) {
      return const Icon(Icons.download_done, color: Colors.green);
    }

    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: () => notifier.downloadVersion(version),
      tooltip: version.preinstalled ? 'Pre-installed' : 'Download for offline use',
    );
  }
}
