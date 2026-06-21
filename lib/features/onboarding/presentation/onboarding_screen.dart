import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';
import '../../../core/services/celebration_service.dart';
import '../application/onboarding_notifier.dart';
import '../application/onboarding_state.dart';
import '../../../shared/widgets/primary_button.dart';
import 'widgets/responsive_layout_builder.dart';
import 'widgets/connect_view.dart';
import 'widgets/commit_view.dart';
import 'widgets/speak_view.dart';
import 'widgets/your_account_view.dart';

final _accountSignInModeProvider = StateProvider<bool>((ref) => false);

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.easeOutCubic;

  String _stepTitle(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.connect => 'Connect',
      OnboardingStep.commit => 'Commit',
      OnboardingStep.speak => 'Speak',
      OnboardingStep.yourAccount => 'Account',
    };
  }

  String _getPrimaryButtonLabel(OnboardingState state) {
    return switch (state.step) {
      OnboardingStep.connect =>
        _canAdvanceFromAssessment(state)
            ? 'Continue to Commit'
            : 'Complete my compass',
      OnboardingStep.commit => 'Continue to Speak',
      OnboardingStep.speak => 'Create my account',
      OnboardingStep.yourAccount => 'Enter ElBiblio',
    };
  }

  bool _canAdvanceFromAssessment(OnboardingState state) {
    return state.hasFullCompassResult;
  }

  bool _canAdvance(OnboardingState state) {
    if (state.step == OnboardingStep.connect) {
      return _canAdvanceFromAssessment(state);
    }
    if (state.step == OnboardingStep.commit) {
      return state.commitmentChoice != null;
    }
    if (state.step == OnboardingStep.speak) {
      return state.selectedCompanionId != null;
    }
    return true;
  }

  String? _inviteTokenFromRoute(BuildContext context) {
    try {
      final token = GoRouterState.of(
        context,
      ).uri.queryParameters['invite_token']?.trim();
      return token?.isNotEmpty == true ? token : null;
    } catch (_) {
      return null;
    }
  }

  Widget _stepContent(
    BuildContext context,
    WidgetRef ref,
    OnboardingState state,
  ) {
    return switch (state.step) {
      OnboardingStep.connect => const ConnectView(),
      OnboardingStep.commit => const CommitView(),
      OnboardingStep.speak => const SpeakView(),
      OnboardingStep.yourAccount => YourAccountView(
        initialSignInMode: ref.watch(_accountSignInModeProvider),
        onSignUp: (name, email, password, phone) =>
            _handleSignUp(context, ref, name, email, password, phone),
        onSignIn: (email, password) =>
            _handleSignIn(context, ref, email, password),
      ),
    };
  }

  Future<void> _handleSignUp(
    BuildContext context,
    WidgetRef ref,
    String name,
    String email,
    String password,
    String phone,
  ) async {
    final onboardingState = ref.read(onboardingProvider);
    final ageBand = onboardingState.derivedAgeBand;
    final inviteToken = _inviteTokenFromRoute(context);

    HapticFeedback.mediumImpact();

    // Signup FIRST — if it fails, we don't mark onboarding complete.
    final success = await ref
        .read(authProvider.notifier)
        .signUpWithDetails(
          name: name,
          email: email,
          password: password,
          phone: phone,
          ageBand: ageBand,
          inviteToken: inviteToken,
        );

    if (!success) {
      if (!context.mounted) return;
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'We could not create your account.')),
      );
      return;
    }

    // Wipe any scheduled notifications left over from a previous tenant of
    // this device (shared phone, re-install, test accounts) so ids cannot
    // fire at the new user. Downstream calls below re-register the ones
    // this session actually wants.
    await ref.read(notificationServiceProvider).cancelAll();

    await _completeLocalOnboarding(ref, onboardingState);

    if (!context.mounted) return;
    CelebrationService.instance.playOnboardingCompletion(context);
    context.go(AppRoutes.home);
  }

  Future<void> _handleSignIn(
    BuildContext context,
    WidgetRef ref,
    String email,
    String password,
  ) async {
    final onboardingState = ref.read(onboardingProvider);

    HapticFeedback.mediumImpact();

    final success = await ref
        .read(authProvider.notifier)
        .signInWithPassword(email: email, password: password);

    if (!success) {
      if (!context.mounted) return;
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'We could not sign you in.')),
      );
      return;
    }

    await ref.read(notificationServiceProvider).cancelAll();
    await _completeLocalOnboarding(ref, onboardingState);

    if (!context.mounted) return;
    context.go(AppRoutes.home);
  }

  Future<void> _completeLocalOnboarding(
    WidgetRef ref,
    OnboardingState onboardingState,
  ) async {
    final compassPayload = onboardingState.compassSubmissionPayload;
    await ref
        .read(settingsProvider.notifier)
        .setPendingCompassSubmission(compassPayload);

    // Wipe the mid-onboarding draft so a future app-kill can't rehydrate
    // stale in-progress state over a completed account.
    await ref.read(settingsProvider.notifier).clearOnboardingDraft();

    // Atomic bundle: both pre-onboarding + onboarding flags land in a single
    // disk write. A crash between the two writes previously could leave
    // hasCompletedPreOnboarding=true and onboardingCompleted=false, stranding
    // the user on a dead route.
    await ref
        .read(settingsProvider.notifier)
        .persistOnboardingBundle(
          primaryVirtue: onboardingState.primaryVirtue,
          lifestyle: onboardingState.lifestyle,
          morningTime: onboardingState.morningTime,
          eveningTime: onboardingState.eveningTime,
          morningReminderEnabled: onboardingState.morningReminderEnabled,
          eveningReminderEnabled: onboardingState.eveningReminderEnabled,
          socialPresenceOptIn: onboardingState.socialPresenceOptIn,
          contactsImported: onboardingState.contactsImported,
          primaryArchetypeId: onboardingState.primaryArchetypeId,
          selectedArchetypeIds: onboardingState.selectedArchetypeIds,
          commitmentCategory: onboardingState.commitmentCategory,
          primaryMissionFocus: onboardingState.primaryMissionFocus,
          ageBand: onboardingState.derivedAgeBand,
          spiritualAgeScore: onboardingState.spiritualAgeScore,
          spiritualAgeStage: onboardingState.spiritualAgeStage,
          personalDistractions: onboardingState.personalDistractions,
          christianLifeBaseline: onboardingState.baselineOrNull,
        );

    try {
      await ref
          .read(assessmentApiRepositoryProvider)
          .submitAssessment(compassPayload);
      await ref.read(settingsProvider.notifier).clearPendingCompassSubmission();
    } catch (_) {
      // Keep the payload in settings so it is not lost; account entry should
      // not be blocked by a transient assessment write.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return ResponsiveLayoutBuilder(
      mobile: (context, constraints) =>
          _buildScaffold(context, ref, state, notifier, isDesktop: false),
      tablet: (context, constraints) =>
          _buildScaffold(context, ref, state, notifier, isDesktop: false),
      desktop: (context, constraints) =>
          _buildScaffold(context, ref, state, notifier, isDesktop: true),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    WidgetRef ref,
    OnboardingState state,
    OnboardingNotifier notifier, {
    required bool isDesktop,
  }) {
    const horizontalPadding = 24.0;
    const contentMaxWidth = 600.0;
    final showFooter =
        state.step != OnboardingStep.yourAccount &&
        (state.step != OnboardingStep.connect ||
            state.hasFullCompassResult);
    final bodyAlignment =
        state.step == OnboardingStep.connect
        ? Alignment.center
        : Alignment.topCenter;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      appBar: state.step == OnboardingStep.connect
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              centerTitle: isDesktop,
              title: Text(
                _stepTitle(state.step),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20.0,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                  ),
                  child: LinearProgressIndicator(
                    value: (state.currentStepIndex + 1) / state.totalSteps,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.6),
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
      body: AnimatedSwitcher(
        duration: _duration,
        switchInCurve: _curve,
        switchOutCurve: _curve,
        child: DecoratedBox(
          key: ValueKey(state.step),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface.withValues(alpha: 1.0),
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
                Theme.of(context).colorScheme.surface.withValues(alpha: 1.0),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            top: state.step == OnboardingStep.connect,
            bottom: false,
            child: Align(
              alignment: bodyAlignment,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 0),
                  child: _stepContent(context, ref, state),
                ),
              ),
            ),
          ),
        ),
      ),
      // Hide the shared footer while a step owns its own controls.
      bottomNavigationBar: !showFooter || isDesktop
          ? null
          : _buildBottomNavigationBar(context, state, notifier, ref),
      persistentFooterButtons: showFooter && isDesktop
          ? [_buildDesktopButtons(context, state, notifier, ref)]
          : null,
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
    WidgetRef ref,
  ) {
    final canAdvance = _canAdvance(state);

    if (state.step == OnboardingStep.connect) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          ResponsiveSpacing.getHorizontalPadding(context),
          14,
          ResponsiveSpacing.getHorizontalPadding(context),
          16,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 56,
                child: PrimaryButton(
                  label: _getPrimaryButtonLabel(state),
                  icon: Icons.arrow_forward_rounded,
                  onPressed: canAdvance
                      ? () {
                          ref.read(_accountSignInModeProvider.notifier).state =
                              false;
                          notifier.next();
                        }
                      : null,
                  expanded: true,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(_accountSignInModeProvider.notifier).state = true;
                  notifier.openAccount();
                },
                child: const Text('Sign in instead'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(ResponsiveSpacing.getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: <Widget>[
            // Back button (not shown on first step)
            if (state.step != OnboardingStep.connect)
              Expanded(
                child: PrimaryButton(label: 'Back', onPressed: notifier.back),
              ),
            if (state.step != OnboardingStep.connect)
              const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                label: _getPrimaryButtonLabel(state),
                onPressed: canAdvance ? notifier.next : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopButtons(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
    WidgetRef ref,
  ) {
    final canAdvance = _canAdvance(state);

    return Container(
      padding: EdgeInsets.all(ResponsiveSpacing.getHorizontalPadding(context)),
      child: TweenAnimationBuilder<double>(
        duration: _duration,
        tween: Tween(begin: 0.0, end: 1.0),
        curve: const Interval(0.6, 1.0, curve: _curve),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (state.step != OnboardingStep.connect)
                    SizedBox(
                      width: 160,
                      child: PrimaryButton(
                        label: 'Back',
                        onPressed: notifier.back,
                      ),
                    ),
                  if (state.step != OnboardingStep.connect)
                    const SizedBox(width: 24),
                  SizedBox(
                    width: 240,
                    child: PrimaryButton(
                      label: _getPrimaryButtonLabel(state),
                      onPressed: canAdvance ? notifier.next : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
