import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/services/celebration_service.dart';
import '../../../../core/services/notifications/notification_service.dart';
import '../../../commit/domain/models/commitment_schedule.dart';
import '../../../commit/presentation/widgets/commitment_backdrop.dart';
import '../../../commit/data/commitment_media_catalog.dart';

class OverlayNotificationScreen extends ConsumerStatefulWidget {
  const OverlayNotificationScreen({
    super.key,
    required this.notification,
    this.category = 'growth',
  });

  final OverlayNotification notification;
  final String category;

  @override
  ConsumerState<OverlayNotificationScreen> createState() =>
      _OverlayNotificationScreenState();
}

class _OverlayNotificationScreenState
    extends ConsumerState<OverlayNotificationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController.forward();
    _playAmbientSound();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    ref.read(soundServiceProvider).stopCategoryAmbience();
    super.dispose();
  }

  void _playAmbientSound() {
    final media = CommitmentMediaCatalog.getMedia(widget.category);
    final soundPath = media.ambientSound;
    if (soundPath == null) return;

    final assetPath = soundPath.replaceFirst('assets/', '');
    ref.read(soundServiceProvider).playCategoryAmbience(
      assetPath,
      volume: 0.10,
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
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
                      'Every step of faithfulness builds who you\'re becoming.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
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
                              child: const Text('Skip for now — no pressure'),
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
        ),
      ),
    );
  }

  Future<void> _handleAction(String actionId) async {
    ref.read(soundServiceProvider).stopCategoryAmbience();
    switch (actionId) {
      case 'check_in': {
        final outcome = await NotificationService().executeDailyCheckInAction(
          payload: 'commitment_overlay|${widget.notification.commitmentId}',
        );
        if (!mounted) return;
        if (outcome == NotificationActionOutcome.success) {
          CelebrationService.instance.playDailyCheckInCompletion(context);
          context.go(AppRoutes.commit);
        } else {
          context.go(AppRoutes.home);
        }
        break;
      }
      case 'talk':
        context.go(AppRoutes.companionChat);
        break;
      case 'skip':
      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No worries. Your commitment is here when you\'re ready.',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
        context.go(AppRoutes.home);
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
