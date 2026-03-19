import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/domain/models/activity.dart';
import '../helpers/bible_library_helpers.dart' as helpers;

class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.isLoading,
    required this.history,
    required this.primaryColor,
    required this.surfaceColor,
    required this.textColor,
    required this.textMutedColor,
    required this.borderColor,
    required this.onOpenReading,
    required this.onStartReading,
  });

  final bool isLoading;
  final List<Activity> history;
  final Color primaryColor;
  final Color surfaceColor;
  final Color textColor;
  final Color textMutedColor;
  final Color borderColor;
  final void Function(Activity activity) onOpenReading;
  final VoidCallback onStartReading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Continue Reading',
            style: Theme.of(context).textTheme.cardTitle.copyWith(color: textColor)),
        const SizedBox(height: 12),
        if (isLoading)
          _buildLoading(context)
        else if (history.isNotEmpty)
          _buildLastRead(context, history.first)
        else
          _buildStartReading(context),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text('Loading reading progress...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textMutedColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildLastRead(BuildContext context, Activity lastActivity) {
    final progress = helpers.getProgressFromActivity(lastActivity);
    return InkWell(
      onTap: () => onOpenReading(lastActivity),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    helpers.getTestamentFromActivity(lastActivity),
                    style: Theme.of(context).textTheme.metadata.copyWith(
                          color: Colors.white, letterSpacing: 1),
                  ),
                ),
                const SizedBox(height: 12),
                Text(helpers.getBookFromActivity(lastActivity),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(helpers.getChapterFromActivity(lastActivity),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500)),
              ],
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartReading(BuildContext context) {
    return InkWell(
      onTap: onStartReading,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.bookOpen, color: textMutedColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text('Start your reading journey today',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textMutedColor)),
            ),
            Icon(Icons.chevron_right, color: textMutedColor),
          ],
        ),
      ),
    );
  }
}
