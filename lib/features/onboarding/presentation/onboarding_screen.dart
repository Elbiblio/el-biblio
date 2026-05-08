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
import 'widgets/the_noise_view.dart';
import 'widgets/the_solution_view.dart';
import 'widgets/discover_identity_view.dart';
import 'widgets/your_account_view.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.easeOutCubic;

  String _stepTitle(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.theProblem => 'The Noise',
      OnboardingStep.theSolution => 'The Solution',
      OnboardingStep.yourIdentity => 'Your Identity',
      OnboardingStep.yourAccount => 'Your Account',
    };
  }

  String _getPrimaryButtonLabel(OnboardingState state) {
    return switch (state.step) {
      OnboardingStep.theProblem => 'There must be a better way',
      OnboardingStep.theSolution => 'Show me my identity',
      OnboardingStep.yourIdentity => _canAdvanceFromAssessment(state)
          ? 'Create my account'
          : 'Answer all questions',
      OnboardingStep.yourAccount => 'Begin my clarity journey',
    };
  }

  bool _canAdvanceFromAssessment(OnboardingState state) {
    return state.miniAssessmentAnswers.length >= 3 &&
        !state.miniAssessmentAnswers.contains(-1) &&
        state.primaryArchetypeId != null;
  }

  bool _canAdvance(OnboardingState state) {
    if (state.step == OnboardingStep.yourIdentity) {
      return _canAdvanceFromAssessment(state);
    }
    return true;
  }

  Widget _stepContent(
    BuildContext context,
    WidgetRef ref,
    OnboardingState state,
  ) {
    return switch (state.step) {
      OnboardingStep.theProblem => const TheNoiseView(),
      OnboardingStep.theSolution => const TheSolutionView(),
      OnboardingStep.yourIdentity => const DiscoverIdentityView(),
      OnboardingStep.yourAccount => YourAccountView(
          onSignUp: (name, email, phone) =>
              _handleSignUp(context, ref, name, email, phone),
        ),
    };
  }

  Future<void> _handleSignUp(
    BuildContext context,
    WidgetRef ref,
    String name,
    String email,
    String phone,
  ) async {
    final onboardingState = ref.read(onboardingProvider);

    HapticFeedback.mediumImpact();

    // Signup FIRST — if it fails, we don't mark onboarding complete.
    final success = await ref.read(authProvider.notifier).signUpWithDetails(
          name: name,
          email: email,
          phone: phone,
        );

    if (!success) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create your account. Please try again.'),
        ),
      );
      return;
    }

    // Wipe any scheduled notifications left over from a previous tenant of
    // this device (shared phone, re-install, test accounts) so ids cannot
    // fire at the new user. Downstream calls below re-register the ones
    // this session actually wants.
    await ref.read(notificationServiceProvider).cancelAll();

    // Wipe the mid-onboarding draft so a future app-kill can't rehydrate
    // stale in-progress state over a completed account.
    await ref.read(settingsProvider.notifier).clearOnboardingDraft();

    // Atomic bundle: both pre-onboarding + onboarding flags land in a single
    // disk write. A crash between the two writes previously could leave
    // hasCompletedPreOnboarding=true and onboardingCompleted=false, stranding
    // the user on a dead route.
    await ref.read(settingsProvider.notifier).persistOnboardingBundle(
          primaryVirtue: onboardingState.primaryVirtue,
          lifestyle: onboardingState.lifestyle,
          morningTime: onboardingState.morningTime,
          eveningTime: onboardingState.eveningTime,
          morningReminderEnabled: onboardingState.morningReminderEnabled,
          eveningReminderEnabled: onboardingState.eveningReminderEnabled,
          socialPresenceOptIn: onboardingState.socialPresenceOptIn,
          contactsImported: onboardingState.contactsImported,
          primaryArchetypeId: onboardingState.primaryArchetypeId,
          commitmentCategory: onboardingState.commitmentCategory,
          primaryMissionFocus: onboardingState.primaryMissionFocus,
          personalDistractions: onboardingState.personalDistractions,
          christianLifeBaseline: onboardingState.baselineOrNull,
        );

    if (!context.mounted) return;
    CelebrationService.instance.playOnboardingCompletion(context);
    context.go(AppRoutes.postOnboarding);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return ResponsiveLayoutBuilder(
      mobile: (context, constraints) => _buildScaffold(context, ref, state, notifier, isDesktop: false),
      tablet: (context, constraints) => _buildScaffold(context, ref, state, notifier, isDesktop: false),
      desktop: (context, constraints) => _buildScaffold(context, ref, state, notifier, isDesktop: true),
    );
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref, OnboardingState state, OnboardingNotifier notifier, {required bool isDesktop}) {
    const horizontalPadding = 24.0;
    const contentMaxWidth = 600.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: isDesktop,
        title: Text(
          _stepTitle(state.step),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 24.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: LinearProgressIndicator(
              value: (state.currentStepIndex + 1) / state.totalSteps,
              backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
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
          child: Center(
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
      // Hide the bottom bar on yourAccount step — the view has its own buttons
      bottomNavigationBar: state.step == OnboardingStep.yourAccount
          ? null
          : (isDesktop ? null : _buildBottomNavigationBar(context, state, notifier, ref)),
      persistentFooterButtons: state.step == OnboardingStep.yourAccount
          ? null
          : (isDesktop ? [_buildDesktopButtons(context, state, notifier, ref)] : null),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, OnboardingState state, OnboardingNotifier notifier, WidgetRef ref) {
    final canAdvance = _canAdvance(state);

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
            if (state.step != OnboardingStep.theProblem)
              Expanded(
                child: PrimaryButton(
                  label: 'Back',
                  onPressed: notifier.back,
                ),
              ),
            if (state.step != OnboardingStep.theProblem)
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

  Widget _buildDesktopButtons(BuildContext context, OnboardingState state, OnboardingNotifier notifier, WidgetRef ref) {
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
                  if (state.step != OnboardingStep.theProblem)
                    SizedBox(
                      width: 160,
                      child: PrimaryButton(
                        label: 'Back',
                        onPressed: notifier.back,
                      ),
                    ),
                  if (state.step != OnboardingStep.theProblem)
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
