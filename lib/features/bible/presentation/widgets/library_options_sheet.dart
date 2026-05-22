import 'package:flutter/material.dart';

import '../../../../../core/constants/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'bible_versions_sheet.dart';
import 'reading_history_sheet.dart';
import 'reading_stats_sheet.dart';
import '../../../../shared/domain/models/activity.dart';

class LibraryOptionsSheet {
  const LibraryOptionsSheet._();

  static Future<void> show(
    BuildContext context, {
    required void Function(Activity activity) onOpenReading,
  }) {
    final parentContext = context;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 6,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: Theme.of(sheetContext).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Library Settings',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Reminder Settings'),
                subtitle: const Text('Configure daily reading reminders'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  parentContext.push(AppRoutes.reminders);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Download Management'),
                subtitle: const Text('Manage offline Bible versions'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showModalBottomSheet(
                    context: parentContext,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) => const BibleVersionsSheet(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_outlined),
                title: const Text('Reading History'),
                subtitle: const Text('View your complete reading history'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ReadingHistorySheet.show(
                    parentContext,
                    onOpenReading: onOpenReading,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_outlined),
                title: const Text('Reading Stats'),
                subtitle: const Text(
                  'View your reading progress and statistics',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ReadingStatsSheet.show(parentContext);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
