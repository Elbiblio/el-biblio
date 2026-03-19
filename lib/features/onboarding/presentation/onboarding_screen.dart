import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';
import '../../../core/services/celebration_service.dart';
import '../application/onboarding_notifier.dart';
import '../application/onboarding_state.dart';
import '../../../shared/widgets/primary_button.dart';
import 'widgets/responsive_layout_builder.dart';
import 'widgets/welcome_header.dart';
import 'widgets/welcome_content.dart';
import 'widgets/lifestyle_setup_view.dart';
import 'widgets/three_anchors_view.dart';
import 'widgets/sample_habits_view.dart';
import 'widgets/social_presence_view.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.easeOutCubic;

  String _stepTitle(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.welcome => 'Welcome to Elbiblio',
      OnboardingStep.threeAnchors => 'The Three Anchors',
      OnboardingStep.sampleHabits => 'Grow Every Day',
      OnboardingStep.lifestyleSetup => 'Lifestyle',
      OnboardingStep.socialPresence => 'Social Presence',
    };
  }

  String _getPrimaryButtonLabel(OnboardingState state) {
    if (state.step == OnboardingStep.socialPresence) {
      return 'Connect Now';
    }
    if (state.step == OnboardingStep.welcome) {
      return 'Begin Your Journey';
    }
    return state.isLastStep ? 'Begin' : 'Next';
  }

  Widget _stepContent(
    BuildContext context,
    WidgetRef ref,
    OnboardingState state,
  ) {
    final notifier = ref.read(onboardingProvider.notifier);

    return switch (state.step) {
      OnboardingStep.welcome => _buildWelcome(context, notifier),
      OnboardingStep.threeAnchors => _buildThreeAnchors(context, notifier),
      OnboardingStep.sampleHabits => _buildSampleHabits(context, ref, notifier),
      OnboardingStep.lifestyleSetup => _buildLifestyleSetup(context, notifier, state),
      OnboardingStep.socialPresence => _buildSocialPresence(context, notifier, state),
    };
  }

  Widget _buildWelcome(BuildContext context, OnboardingNotifier notifier) {
    return ResponsiveLayoutBuilder(
      mobile: (context, constraints) => _buildWelcomeMobile(context, notifier),
      tablet: (context, constraints) => _buildWelcomeTablet(context, notifier),
      desktop: (context, constraints) => _buildWelcomeDesktop(context, notifier),
    );
  }

  Widget _buildWelcomeMobile(BuildContext context, OnboardingNotifier notifier) {
    return _buildWelcomeContent(context, notifier, isDesktop: false);
  }

  Widget _buildWelcomeTablet(BuildContext context, OnboardingNotifier notifier) {
    return _buildWelcomeContent(context, notifier, isDesktop: false);
  }

  Widget _buildWelcomeDesktop(BuildContext context, OnboardingNotifier notifier) {
    return _buildWelcomeContent(context, notifier, isDesktop: true);
  }

  Widget _buildWelcomeContent(BuildContext context, OnboardingNotifier notifier, {required bool isDesktop}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 420 : 360,
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WelcomeHeader(),
                  SizedBox(height: 24),
                  WelcomeContent(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLifestyleSetup(BuildContext context, OnboardingNotifier notifier, OnboardingState state) {
    return LifestyleSetupView(
      notifier: notifier,
      state: state,
      isDesktop: false,
    );
  }

  Widget _buildThreeAnchors(BuildContext context, OnboardingNotifier notifier) {
    return const ThreeAnchorsView();
  }

  Widget _buildSampleHabits(BuildContext context, WidgetRef ref, OnboardingNotifier notifier) {
    return const SampleHabitsView();
  }

  Widget _buildSocialPresence(BuildContext context, OnboardingNotifier notifier, OnboardingState state) {
    return SocialPresenceView(
      notifier: notifier,
      state: state,
      isDesktop: false,
    );
  }

  Future<void> _connectContacts(BuildContext context, WidgetRef ref) async {
    ref.read(onboardingProvider.notifier).setSocialPresenceOptIn(true);

    try {
      // Request contact permissions
      final permission = await Permission.contacts.request();

      if (!permission.isGranted) {
        if (context.mounted) {
          if (permission.isPermanentlyDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Contact permission is permanently denied. Enable it in Settings to sync contacts.'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact permission denied. You can still continue without syncing contacts.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      if (!context.mounted) return;
      await _completeOnboarding(context, ref, contactsImported: false);
      return;
    }

    final contactNotifier = ref.read(contactProvider.notifier);
    final syncFullySuccessful = await contactNotifier.importContacts();
    final importedState = ref.read(contactProvider);

    String? connectError;
    if (importedState.potentialContacts.isNotEmpty) {
      try {
        await contactNotifier.connectAll(importedState.potentialContacts);
      } catch (e) {
        connectError = e.toString();
      }
    }

    final finalContactState = ref.read(contactProvider);
    final importedCount = finalContactState.deviceContacts.length;
    final connectedCount = finalContactState.connectedContacts.length;
    final hasImportedContacts = importedCount > 0;

    if (!context.mounted) return;

    final statusText = importedCount == 0
        ? 'No contacts with phone/email were found.'
        : 'Imported $importedCount contacts and connected $connectedCount.';
    final syncText = (syncFullySuccessful && connectError == null)
        ? ''
        : ' Some server sync actions failed.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$statusText$syncText'),
        backgroundColor: (syncFullySuccessful && connectError == null) ? Colors.green : Colors.orange,
      ),
    );

    await _completeOnboarding(
      context,
      ref,
      contactsImported: hasImportedContacts,
    );
  } catch (e) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error connecting contacts: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
    await _completeOnboarding(context, ref, contactsImported: false);
  }
  }

  Future<void> _completeOnboarding(BuildContext context, WidgetRef ref, {bool contactsImported = false}) async {
    final state = ref.read(onboardingProvider);

    HapticFeedback.mediumImpact();
    CelebrationService.instance.playOnboardingCompletion(context);

    await ref.read(settingsProvider.notifier).completeOnboarding(
          primaryVirtue: state.primaryVirtue,
          lifestyle: state.lifestyle,
          morningTime: state.morningTime,
          eveningTime: state.eveningTime,
          morningReminderEnabled: state.morningReminderEnabled,
          eveningReminderEnabled: state.eveningReminderEnabled,
          socialPresenceOptIn: state.socialPresenceOptIn,
          contactsImported: contactsImported,
        );

    if (!context.mounted) return;
    final authState = ref.read(authProvider);
    final settings = ref.read(settingsProvider);
    final targetRoute = (authState.isAuthenticated || settings.hasCompletedPreOnboarding)
        ? AppRoutes.today
        : '/pre-onboarding';
    context.go(targetRoute);
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
      extendBodyBehindAppBar: true,
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
      bottomNavigationBar: isDesktop ? null : _buildBottomNavigationBar(context, state, notifier, ref),
      persistentFooterButtons: isDesktop ? [_buildDesktopButtons(context, state, notifier, ref)] : null,
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, OnboardingState state, OnboardingNotifier notifier, WidgetRef ref) {
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
            // Show Skip button for social presence step, otherwise show Back button
            if (state.step == OnboardingStep.socialPresence)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _completeOnboarding(context, ref),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              )
            else if (state.step != OnboardingStep.welcome)
              Expanded(
                child: PrimaryButton(
                  label: 'Back',
                  onPressed: notifier.back,
                ),
              ),
            if (state.step != OnboardingStep.welcome && state.step != OnboardingStep.socialPresence) const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                label: _getPrimaryButtonLabel(state),
                onPressed: state.step == OnboardingStep.socialPresence 
                    ? () => _connectContacts(context, ref)
                    : notifier.next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopButtons(BuildContext context, OnboardingState state, OnboardingNotifier notifier, WidgetRef ref) {
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
                  // Show Skip button for social presence step, otherwise show Back button
                  if (state.step == OnboardingStep.socialPresence)
                    SizedBox(
                      width: 160,
                      child: OutlinedButton(
                        onPressed: () => _completeOnboarding(context, ref),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    )
                  else if (state.step != OnboardingStep.welcome)
                    SizedBox(
                      width: 160,
                      child: PrimaryButton(
                        label: 'Back',
                        onPressed: notifier.back,
                      ),
                    ),
                  if (state.step != OnboardingStep.welcome && state.step != OnboardingStep.socialPresence) const SizedBox(width: 24),
                  SizedBox(
                    width: 160,
                    child: PrimaryButton(
                      label: _getPrimaryButtonLabel(state),
                      onPressed: state.step == OnboardingStep.socialPresence 
                          ? () => _connectContacts(context, ref)
                          : notifier.next,
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
