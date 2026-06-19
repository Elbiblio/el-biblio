import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/notifications/notification_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../commit/domain/models/commitment_schedule.dart';
import '../../../commit/presentation/widgets/commitment_backdrop.dart';
import '../../../commit/data/commitment_media_catalog.dart';

class OverlayNotificationScreen extends StatefulWidget {
  const OverlayNotificationScreen({
    super.key,
    required this.notification,
    this.category = 'growth',
  });

  final OverlayNotification notification;
  final String category;

  @override
  State<OverlayNotificationScreen> createState() =>
      _OverlayNotificationScreenState();
}

class _OverlayNotificationScreenState
    extends State<OverlayNotificationScreen> {
  final SoundService _soundService = SoundService();

  @override
  void initState() {
    super.initState();
    _playAmbientSound();
  }

  @override
  void dispose() {
    _soundService.stopCategoryAmbience();
    super.dispose();
  }

  void _playAmbientSound() {
    final media = CommitmentMediaCatalog.getMedia(widget.category);
    final soundPath = media.ambientSound;
    if (soundPath == null) return;

    // Remove leading 'assets/' prefix for AssetSource if present
    final assetPath = soundPath.replaceFirst('assets/', '');
    _soundService.fadeInCategoryAmbience(
      assetPath,
      targetVolume: 0.10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backdrop = CommitmentMediaCatalog.getMedia(widget.category);

    return Scaffold(
      body: CommitmentBackdrop(
        category: widget.category,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: backdrop.accentColor.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _categoryIcon(widget.category),
                    color: backdrop.accentColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.notification.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.notification.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap an action below to respond.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(flex: 2),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: () => _handleAction('check_in'),
                            icon: const Icon(LucideIcons.checkCircle, size: 20),
                            label: const Text('I did this'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => _handleAction('talk'),
                            icon:
                                const Icon(LucideIcons.messageCircle, size: 18),
                            label: const Text('Talk to companion'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _handleAction('skip'),
                          child: const Text('Skip for now'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(String actionId) async {
    _soundService.stopCategoryAmbience();
    switch (actionId) {
      case 'check_in': {
        final outcome = await NotificationService().executeDailyCheckInAction(
          payload: 'commitment_overlay:${widget.notification.commitmentId}',
        );
        if (!mounted) return;
        if (outcome == NotificationActionOutcome.success) {
          context.go(AppRoutes.commit);
        } else {
          context.go(AppRoutes.today);
        }
        break;
      }
      case 'talk':
        context.go(AppRoutes.companionChat);
        break;
      case 'skip':
      default:
        context.pop();
        break;
    }
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'prayer' => LucideIcons.bookOpen,
      'bible' => LucideIcons.bookOpen,
      'discipline' => LucideIcons.shield,
      'service' => LucideIcons.heartHandshake,
      'growth' => LucideIcons.trendingUp,
      'health' => LucideIcons.heartPulse,
      'faith' => LucideIcons.sparkles,
      'relationships' => LucideIcons.users,
      _ => LucideIcons.flag,
    };
  }
}
