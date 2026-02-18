import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../../today/domain/models/daily_anchors.dart';
import '../application/onboarding_notifier.dart';
import '../application/onboarding_state.dart';
import '../../../shared/widgets/primary_button.dart';
import 'widgets/onboarding_illustrations.dart';
import 'widgets/premium_card.dart';
import 'widgets/premium_onboarding_background.dart';
import 'widgets/responsive_layout_builder.dart';

class OnboardingScreenRefactored extends ConsumerWidget {
  const OnboardingScreenRefactored({super.key});

  static const _duration = Duration(milliseconds: 320);
  static const _curve = Curves.easeOutCubic;

  String _formatTimeOfDay(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  TimeOfDay? _tryParseTimeOfDay(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23) return null;
    if (minute < 0 || minute > 59) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _stepTitle(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.welcome => 'Welcome',
      OnboardingStep.purposeFraming => 'Purpose',
      OnboardingStep.compassAssessment => 'Compass',
      OnboardingStep.dailyRhythm => 'Rhythm',
      OnboardingStep.socialPresence => 'Social',
      OnboardingStep.review => 'Review',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    final horizontalPadding = ResponsiveSpacing.getHorizontalPadding(context);
    final contentMaxWidth = ResponsiveSpacing.getContentMaxWidth(context);

    return PremiumOnboardingBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            _stepTitle(state.step),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveFontSize.getTitleLarge(context),
                ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: LinearProgressIndicator(
                value: (state.currentStepIndex + 1) / state.totalSteps,
                backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.65),
                ),
                borderRadius: BorderRadius.circular(999),
                minHeight: 3,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: AnimatedSwitcher(
                duration: _duration,
                switchInCurve: _curve,
                switchOutCurve: _curve,
                child: SingleChildScrollView(
                  key: ValueKey(state.step),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    ResponsiveSpacing.getVerticalPadding(context) * 0.6,
                    horizontalPadding,
                    ResponsiveSpacing.getVerticalPadding(context) * 0.6,
                  ),
                  child: _stepContent(context, ref, state),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _BottomNav(
          isLast: state.isLastStep,
          canGoBack: state.step != OnboardingStep.welcome,
          onBack: notifier.back,
          onNext: () async {
            if (!state.isLastStep) {
              notifier.next();
              return;
            }

            HapticFeedback.mediumImpact();
            await ref.read(soundServiceProvider).playOnboardingSuccess();

            await ref.read(settingsProvider.notifier).completeOnboarding(
                  primaryVirtue: state.primaryVirtue,
                  neglectedVirtue: state.neglectedVirtue,
                  journalReminderTime: state.journalReminderTime,
                  notificationWindow: state.notificationWindow,
                  remindersEnabled: state.remindersEnabled,
                  socialPresenceOptIn: state.socialPresenceOptIn,
                  contactsImported: state.contactsImported,
                );
          },
        ),
      ),
    );
  }

  Widget _stepContent(BuildContext context, WidgetRef ref, OnboardingState state) {
    final notifier = ref.read(onboardingProvider.notifier);

    return switch (state.step) {
      OnboardingStep.welcome => _welcome(context),
      OnboardingStep.purposeFraming => _purpose(context),
      OnboardingStep.compassAssessment => _compass(context, notifier, state),
      OnboardingStep.dailyRhythm => _rhythm(context, notifier, state),
      OnboardingStep.socialPresence => _social(context, notifier, state),
      OnboardingStep.review => _review(context, state),
    };
  }

  Widget _hero({required Widget illustration, required Widget title, Widget? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: illustration),
        SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(28)),
        title,
        if (subtitle != null) ...[
          SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(10)),
          subtitle,
        ],
      ],
    );
  }

  Widget _welcome(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(
          illustration: OnboardingIllustrations.welcomeIllustration(
            context,
            size: MediaQuery.of(context).size.width * 0.38,
          ),
          title: Text(
            'Compass OS',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.6,
                  fontSize: ResponsiveFontSize.getHeadlineLarge(context),
                ),
          ),
          subtitle: Text(
            'Your gentle companion for daily presence.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.55,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                  fontSize: ResponsiveFontSize.getBodyLarge(context),
                ),
          ),
        ),
        SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(22)),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A moment of alignment',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveFontSize.getTitleMedium(context),
                    ),
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(10)),
              Text(
                'Take a breath. You are exactly where you need to be.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
                      fontSize: ResponsiveFontSize.getBodyMedium(context),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _purpose(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(
          illustration: OnboardingIllustrations.purposeIllustration(
            context,
            size: MediaQuery.of(context).size.width * 0.30,
          ),
          title: Text(
            'What This Is',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveFontSize.getHeadlineSmall(context),
                ),
          ),
        ),
        SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(18)),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _purposeItem(context, 'Daily alignment', 'For inner, outer, and directional life'),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(14)),
              _purposeItem(context, 'Practice, not content', 'The journey matters more than the destination'),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(14)),
              _purposeItem(context, 'Gentle accountability', 'Support without pressure'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _purposeItem(BuildContext context, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
                fontSize: ResponsiveFontSize.getTitleMedium(context),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
                fontSize: ResponsiveFontSize.getBodyMedium(context),
              ),
        ),
      ],
    );
  }

  Widget _compass(BuildContext context, OnboardingNotifier notifier, OnboardingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(
          illustration: OnboardingIllustrations.compassIllustration(
            context,
            size: MediaQuery.of(context).size.width * 0.24,
          ),
          title: Text(
            'Your Compass',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveFontSize.getHeadlineSmall(context),
                ),
          ),
          subtitle: Text(
            'Gently choose where to place your awareness today.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                  fontSize: ResponsiveFontSize.getBodyLarge(context),
                ),
          ),
        ),
        SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(18)),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Primary virtue',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveFontSize.getTitleMedium(context),
                    ),
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(10)),
              DropdownButtonFormField<VirtueType>(
                initialValue: state.primaryVirtue,
                decoration: const InputDecoration(labelText: 'Where will you focus today?'),
                items: VirtueType.values
                    .map((v) => DropdownMenuItem<VirtueType>(value: v, child: Text(v.name)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  notifier.setPrimaryVirtue(value);
                },
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(18)),
              Text(
                'Neglected virtue',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveFontSize.getTitleMedium(context),
                    ),
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(10)),
              DropdownButtonFormField<VirtueType>(
                initialValue: state.neglectedVirtue,
                decoration: const InputDecoration(labelText: 'What needs gentle attention?'),
                items: VirtueType.values
                    .where((v) => v != state.primaryVirtue)
                    .map((v) => DropdownMenuItem<VirtueType>(value: v, child: Text(v.name)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  notifier.setNeglectedVirtue(value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rhythm(BuildContext context, OnboardingNotifier notifier, OnboardingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(
          illustration: OnboardingIllustrations.rhythmIllustration(
            context,
            size: MediaQuery.of(context).size.width * 0.30,
          ),
          title: Text(
            'Daily reminders',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveFontSize.getHeadlineSmall(context),
                ),
          ),
          subtitle: Text(
            'Keep a gentle rhythm — present, not pressured.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                  fontSize: ResponsiveFontSize.getBodyLarge(context),
                ),
          ),
        ),
        SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(18)),
        PremiumCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: state.remindersEnabled,
                title: const Text('Enable reminders'),
                onChanged: notifier.setRemindersEnabled,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Journal reminder time'),
                subtitle: Text(state.journalReminderTime),
                trailing: const Icon(Icons.schedule),
                onTap: state.remindersEnabled
                    ? () async {
                        final initial = _tryParseTimeOfDay(state.journalReminderTime) ??
                            const TimeOfDay(hour: 20, minute: 30);
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: initial,
                        );
                        if (picked == null) return;
                        notifier.setJournalReminderTime(_formatTimeOfDay(picked));
                      }
                    : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: state.notificationWindow,
                decoration: const InputDecoration(labelText: 'Notification window'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'gentle', child: Text('gentle')),
                  DropdownMenuItem(value: 'standard', child: Text('standard')),
                  DropdownMenuItem(value: 'strict', child: Text('strict')),
                ],
                onChanged: state.remindersEnabled
                    ? (value) {
                        if (value == null) return;
                        notifier.setNotificationWindow(value);
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _social(BuildContext context, OnboardingNotifier notifier, OnboardingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(
          illustration: OnboardingIllustrations.socialIllustration(
            context,
            size: MediaQuery.of(context).size.width * 0.32,
          ),
          title: Text(
            'You\'re Not Alone',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveFontSize.getHeadlineSmall(context),
                ),
          ),
          subtitle: Text(
            'A gentle shared presence — without comparison.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                  fontSize: ResponsiveFontSize.getBodyLarge(context),
                ),
          ),
        ),
        SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(18)),
        PremiumCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: state.socialPresenceOptIn,
                title: const Text('Connect with contacts'),
                subtitle: const Text('Find friends using Compass OS'),
                onChanged: notifier.setSocialPresenceOptIn,
              ),
              if (state.socialPresenceOptIn) ...[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Import contacts'),
                  subtitle: Text(state.contactsImported ? 'Contacts imported' : 'Tap to import'),
                  trailing: Icon(state.contactsImported ? Icons.check_circle : Icons.upload_file),
                  onTap: state.contactsImported
                      ? null
                      : () async {
                          notifier.setContactsImported(true);
                        },
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _review(BuildContext context, OnboardingState state) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: _CompletionBadge(primary: scheme.primary),
        ),
        SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(24)),
        Text(
          'All set',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveFontSize.getHeadlineSmall(context),
              ),
        ),
        SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(10)),
        Text(
          'Your compass is ready. You can refine these anytime.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                fontSize: ResponsiveFontSize.getBodyLarge(context),
              ),
        ),
        SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(18)),
        PremiumCard(
          child: Column(
            children: [
              _reviewRow(context, 'Primary virtue', state.primaryVirtue.name),
              const SizedBox(height: 10),
              _reviewRow(context, 'Neglected virtue', state.neglectedVirtue.name),
              const SizedBox(height: 10),
              _reviewRow(context, 'Reminders', state.remindersEnabled ? 'on' : 'off'),
              const SizedBox(height: 10),
              _reviewRow(context, 'Journal time', state.journalReminderTime),
              const SizedBox(height: 10),
              _reviewRow(context, 'Window', state.notificationWindow),
              const SizedBox(height: 10),
              _reviewRow(context, 'Social presence', state.socialPresenceOptIn ? 'on' : 'off'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.90),
              ),
        ),
      ],
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  const _CompletionBadge({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveSpacing.getGoldenRatioLarge(MediaQuery.of(context).size.width * 0.22);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.92 + (0.08 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.18),
                    primary.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(color: primary.withValues(alpha: 0.22), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: size * 0.62,
                  height: size * 0.62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: size * 0.34,
                    color: primary.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.isLast,
    required this.canGoBack,
    required this.onBack,
    required this.onNext,
  });

  final bool isLast;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSpacing.getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.90),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.10),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: 'Back',
              onPressed: canGoBack ? onBack : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: PrimaryButton(
              label: isLast ? 'Begin' : 'Next',
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}
