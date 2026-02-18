import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/meditation_notifier.dart';
import '../domain/models/meditation_enums.dart';
import 'widgets/meditation_active_view.dart';
import 'widgets/meditation_complete_view.dart';
import 'widgets/meditation_countdown_view.dart';
import 'widgets/meditation_paused_view.dart';
import 'widgets/meditation_setup_view.dart';

class MeditationScreen extends ConsumerStatefulWidget {
  const MeditationScreen({super.key});

  @override
  ConsumerState<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends ConsumerState<MeditationScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final phase = ref.read(meditationProvider).phase;
    if (state == AppLifecycleState.paused &&
        (phase == MeditationPhase.active ||
            phase == MeditationPhase.countdown)) {
      ref.read(meditationProvider.notifier).pause();
    }
  }

  Future<bool> _onWillPop() async {
    final phase = ref.read(meditationProvider).phase;
    if (phase == MeditationPhase.active ||
        phase == MeditationPhase.countdown) {
      final shouldEnd = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('End meditation?'),
          content: const Text(
            'Your meditation is currently running. Do you want to end it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Going'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: const Text('End Session'),
            ),
          ],
        ),
      );
      if (shouldEnd == true) {
        ref.read(meditationProvider.notifier).endSession();
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meditationProvider);
    final theme = Theme.of(context);
    final isInSession = state.phase == MeditationPhase.active ||
        state.phase == MeditationPhase.countdown ||
        state.phase == MeditationPhase.paused;

    return PopScope(
      canPop: !isInSession,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final canLeave = await _onWillPop();
          if (canLeave && context.mounted) {
            context.pop();
          }
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // ── Header (only in setup) ────────────────────────────
                if (state.phase == MeditationPhase.setup)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Daily Meditation',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),

                // ── Body ──────────────────────────────────────────────
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: switch (state.phase) {
                      MeditationPhase.setup =>
                        const MeditationSetupView(key: ValueKey('setup')),
                      MeditationPhase.countdown =>
                        const MeditationCountdownView(key: ValueKey('countdown')),
                      MeditationPhase.active =>
                        const MeditationActiveView(key: ValueKey('active')),
                      MeditationPhase.paused =>
                        const MeditationPausedView(key: ValueKey('paused')),
                      MeditationPhase.complete =>
                        const MeditationCompleteView(key: ValueKey('complete')),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
