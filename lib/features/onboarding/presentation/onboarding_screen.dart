import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/di/app_providers.dart';
import '../application/onboarding_notifier.dart';
import '../application/onboarding_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../today/domain/models/daily_anchors.dart';
import 'widgets/responsive_layout_builder.dart';
import 'widgets/onboarding_illustrations.dart';
import 'widgets/micro_interactions.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.easeOutCubic;

  String _formatTimeOfDay(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _buildCompletionCheckBadge(BuildContext context, {double? size}) {
    final colorScheme = Theme.of(context).colorScheme;
    final actualSize = size ?? ResponsiveSpacing.getGoldenRatioLarge(MediaQuery.of(context).size.width * 0.22);

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
              width: actualSize,
              height: actualSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.18),
                    colorScheme.primary.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: actualSize * 0.62,
                  height: actualSize * 0.62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: actualSize * 0.34,
                    color: colorScheme.primary.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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

  Widget _stepContent(
    BuildContext context,
    WidgetRef ref,
    OnboardingState state,
  ) {
    final notifier = ref.read(onboardingProvider.notifier);

    return switch (state.step) {
      OnboardingStep.welcome => _buildWelcome(context, notifier),
      OnboardingStep.purposeFraming => _buildPurposeFraming(context, notifier),
      OnboardingStep.compassAssessment => _buildCompassAssessment(context, notifier, state),
      OnboardingStep.dailyRhythm => _buildDailyRhythm(context, notifier, state),
      OnboardingStep.socialPresence => _buildSocialPresence(context, notifier, state),
      OnboardingStep.review => _buildReview(context, notifier, state),
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
    final horizontalPadding = ResponsiveSpacing.getHorizontalPadding(context);
    final contentMaxWidth = ResponsiveSpacing.getContentMaxWidth(context);
    
    return AnimatedContainer(
      duration: _duration,
      curve: _curve,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: ResponsiveSpacing.getVerticalPadding(context) * 0.8),
                
                // Illustration
                if (isDesktop) ...[
                  Center(
                    child: MicroInteractions.breathe(
                      child: OnboardingIllustrations.welcomeIllustration(context),
                    ),
                  ),
                  SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(48)),
                ] else ...[
                  Center(
                    child: MicroInteractions.breathe(
                      child: OnboardingIllustrations.welcomeIllustration(
                        context,
                        size: MediaQuery.of(context).size.width * 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                
                // Title
                TweenAnimationBuilder<double>(
                  duration: _duration,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Text(
                          'Compass OS',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.2,
                            fontSize: ResponsiveFontSize.getHeadlineLarge(context),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(24)),
                
                // Subtitle
                TweenAnimationBuilder<double>(
                  duration: _duration,
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Interval(0.2, 1.0, curve: _curve),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Text(
                          'Your gentle companion for daily presence.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                            height: 1.6,
                            fontSize: ResponsiveFontSize.getBodyLarge(context),
                          ),
                          textAlign: isDesktop ? TextAlign.center : TextAlign.start,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(48)),
                
                // Message card
                TweenAnimationBuilder<double>(
                  duration: _duration,
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Interval(0.4, 1.0, curve: _curve),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: InteractiveCard(
                          borderRadius: ResponsiveBorderRadius.getMedium(context),
                          child: Container(
                            padding: EdgeInsets.all(ResponsiveSpacing.getGoldenRatioSmall(24)),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getMedium(context)),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'A moment of alignment',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w400,
                                    fontSize: ResponsiveFontSize.getTitleMedium(context),
                                  ),
                                ),
                                SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(12)),
                                Text(
                                  'Take a breath. You are exactly where you need to be.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    height: 1.5,
                                    fontSize: ResponsiveFontSize.getBodyMedium(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPurposeFraming(BuildContext context, OnboardingNotifier notifier) {
    return ResponsiveLayoutBuilder(
      mobile: (context, constraints) => _buildPurposeFramingContent(context, notifier, isDesktop: false),
      tablet: (context, constraints) => _buildPurposeFramingContent(context, notifier, isDesktop: false),
      desktop: (context, constraints) => _buildPurposeFramingContent(context, notifier, isDesktop: true),
    );
  }

  Widget _buildPurposeFramingContent(BuildContext context, OnboardingNotifier notifier, {required bool isDesktop}) {
    final horizontalPadding = ResponsiveSpacing.getHorizontalPadding(context);
    final contentMaxWidth = ResponsiveSpacing.getContentMaxWidth(context);
    
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: ResponsiveSpacing.getVerticalPadding(context) * 0.8),
              
              // Illustration
              Center(
                child: OnboardingIllustrations.purposeIllustration(
                  context,
                  size: isDesktop ? null : MediaQuery.of(context).size.width * 0.3,
                ),
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(32)),
              
              // Title
              Text(
                'What This Is',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: ResponsiveFontSize.getHeadlineSmall(context),
                ),
                textAlign: isDesktop ? TextAlign.center : TextAlign.start,
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(24)),
              
              // Purpose items container
              Container(
                padding: EdgeInsets.all(ResponsiveSpacing.getGoldenRatioSmall(20)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getMedium(context)),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPurposeItem(
                      context,
                      'Daily alignment',
                      'For inner, outer, and directional life',
                    ),
                    SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(16)),
                    _buildPurposeItem(
                      context,
                      'Practice, not content',
                      'The journey matters more than the destination',
                    ),
                    SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(16)),
                    _buildPurposeItem(
                      context,
                      'Gentle accountability',
                      'Support without pressure',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurposeItem(BuildContext context, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.primary,
            fontSize: ResponsiveFontSize.getTitleMedium(context),
          ),
        ),
        SizedBox(height: ResponsiveSpacing.getSqrt2Ratio(4)),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.4,
            fontSize: ResponsiveFontSize.getBodyMedium(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCompassAssessment(BuildContext context, OnboardingNotifier notifier, OnboardingState state) {
    return ResponsiveLayoutBuilder(
      mobile: (context, constraints) => _buildCompassAssessmentContent(context, notifier, state, isDesktop: false),
      tablet: (context, constraints) => _buildCompassAssessmentContent(context, notifier, state, isDesktop: false),
      desktop: (context, constraints) => _buildCompassAssessmentContent(context, notifier, state, isDesktop: true),
    );
  }

  Widget _buildCompassAssessmentContent(BuildContext context, OnboardingNotifier notifier, OnboardingState state, {required bool isDesktop}) {
    final horizontalPadding = ResponsiveSpacing.getHorizontalPadding(context);
    final contentMaxWidth = ResponsiveSpacing.getContentMaxWidth(context);
    
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: ResponsiveSpacing.getVerticalPadding(context) * 0.8),
              
              // Illustration
              Center(
                child: OnboardingIllustrations.compassIllustration(
                  context,
                  size: isDesktop ? null : MediaQuery.of(context).size.width * 0.25,
                ),
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(32)),
              
              // Title
              Text(
                'Your Compass',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: ResponsiveFontSize.getHeadlineSmall(context),
                ),
                textAlign: isDesktop ? TextAlign.center : TextAlign.start,
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(16)),
              
              // Description
              Text(
                'Gently choose where to place your awareness today.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                  fontSize: ResponsiveFontSize.getBodyLarge(context),
                ),
                textAlign: isDesktop ? TextAlign.center : TextAlign.start,
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(32)),
              
              // Assessment form
              Container(
                padding: EdgeInsets.all(ResponsiveSpacing.getGoldenRatioSmall(20)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getMedium(context)),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary virtue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveFontSize.getTitleMedium(context),
                      ),
                    ),
                    SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(12)),
                    DropdownButtonFormField<VirtueType>(
                      initialValue: state.primaryVirtue,
                      decoration: InputDecoration(
                        labelText: 'Where will you focus today?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getSmall(context)),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getSmall(context)),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getSmall(context)),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      items: VirtueType.values
                          .map(
                            (v) => DropdownMenuItem<VirtueType>(
                              value: v,
                              child: Text(v.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        notifier.setPrimaryVirtue(value);
                      },
                    ),
                    SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(24)),
                    Text(
                      'Neglected virtue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveFontSize.getTitleMedium(context),
                      ),
                    ),
                    SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(12)),
                    DropdownButtonFormField<VirtueType>(
                      initialValue: state.neglectedVirtue,
                      decoration: InputDecoration(
                        labelText: 'What needs gentle attention?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getSmall(context)),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getSmall(context)),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getSmall(context)),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      items: VirtueType.values
                          .where((v) => v != state.primaryVirtue)
                          .map(
                            (v) => DropdownMenuItem<VirtueType>(
                              value: v,
                              child: Text(v.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        notifier.setNeglectedVirtue(value);
                      },
                    ),
                    SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(16)),
                    Container(
                      padding: EdgeInsets.all(ResponsiveSpacing.getSqrt2Ratio(12)),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getSmall(context)),
                      ),
                      child: Text(
                        'Primary: ${state.primaryVirtue.name} • Neglected: ${state.neglectedVirtue.name}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: ResponsiveFontSize.getBodyMedium(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyRhythm(BuildContext context, OnboardingNotifier notifier, OnboardingState state) {
    return ResponsiveLayoutBuilder(
      mobile: (context, constraints) => _buildDailyRhythmContent(context, notifier, state, isDesktop: false),
      tablet: (context, constraints) => _buildDailyRhythmContent(context, notifier, state, isDesktop: false),
      desktop: (context, constraints) => _buildDailyRhythmContent(context, notifier, state, isDesktop: true),
    );
  }

  Widget _buildDailyRhythmContent(BuildContext context, OnboardingNotifier notifier, OnboardingState state, {required bool isDesktop}) {
    final horizontalPadding = ResponsiveSpacing.getHorizontalPadding(context);
    final contentMaxWidth = ResponsiveSpacing.getContentMaxWidth(context);
    
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: ResponsiveSpacing.getVerticalPadding(context) * 0.8),
              
              // Illustration
              Center(
                child: OnboardingIllustrations.rhythmIllustration(
                  context,
                  size: isDesktop ? null : MediaQuery.of(context).size.width * 0.3,
                ),
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(32)),
              
              // Title
              Text(
                'Daily reminders',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: ResponsiveFontSize.getTitleLarge(context),
                ),
                textAlign: isDesktop ? TextAlign.center : TextAlign.start,
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(8)),
              
              // Settings container
              Container(
                padding: EdgeInsets.all(ResponsiveSpacing.getGoldenRatioSmall(20)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getMedium(context)),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: state.remindersEnabled,
                      title: Text(
                        'Enable reminders',
                        style: TextStyle(fontSize: ResponsiveFontSize.getBodyLarge(context)),
                      ),
                      onChanged: notifier.setRemindersEnabled,
                    ),
                    SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(12)),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Journal reminder time',
                        style: TextStyle(fontSize: ResponsiveFontSize.getBodyLarge(context)),
                      ),
                      subtitle: Text(
                        state.journalReminderTime,
                        style: TextStyle(fontSize: ResponsiveFontSize.getBodyMedium(context)),
                      ),
                      trailing: const Icon(Icons.schedule),
                      onTap: state.remindersEnabled
                          ? () async {
                              final initial =
                                  _tryParseTimeOfDay(state.journalReminderTime) ??
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
                    SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(12)),
                    DropdownButtonFormField<String>(
                      initialValue: state.notificationWindow,
                      decoration: InputDecoration(
                        labelText: 'Notification window',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getSmall(context)),
                        ),
                      ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildSocialPresence(BuildContext context, OnboardingNotifier notifier, OnboardingState state) {
    return ResponsiveLayoutBuilder(
      mobile: (context, constraints) => _buildSocialPresenceContent(context, notifier, state, isDesktop: false),
      tablet: (context, constraints) => _buildSocialPresenceContent(context, notifier, state, isDesktop: false),
      desktop: (context, constraints) => _buildSocialPresenceContent(context, notifier, state, isDesktop: true),
    );
  }

  Widget _buildSocialPresenceContent(BuildContext context, OnboardingNotifier notifier, OnboardingState state, {required bool isDesktop}) {
    final horizontalPadding = ResponsiveSpacing.getHorizontalPadding(context);
    final contentMaxWidth = ResponsiveSpacing.getContentMaxWidth(context);
    
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: ResponsiveSpacing.getVerticalPadding(context) * 0.8),
              
              // Illustration
              Center(
                child: OnboardingIllustrations.socialIllustration(
                  context,
                  size: isDesktop ? null : MediaQuery.of(context).size.width * 0.3,
                ),
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(32)),
              
              // Title
              Text(
                'You\'re Not Alone',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: ResponsiveFontSize.getTitleLarge(context),
                ),
                textAlign: isDesktop ? TextAlign.center : TextAlign.start,
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(12)),
              
              // Description
              Text(
                'Gentle shared presence without comparison or pressure.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: ResponsiveFontSize.getBodyLarge(context),
                ),
                textAlign: isDesktop ? TextAlign.center : TextAlign.start,
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(16)),
              
              Text(
                'See when friends are reflecting today — without seeing who or what they did.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: ResponsiveFontSize.getBodyLarge(context),
                ),
                textAlign: isDesktop ? TextAlign.center : TextAlign.start,
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(24)),
              
              // Settings container
              Container(
                padding: EdgeInsets.all(ResponsiveSpacing.getGoldenRatioSmall(20)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getMedium(context)),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: state.socialPresenceOptIn,
                      title: Text(
                        'Connect with contacts',
                        style: TextStyle(fontSize: ResponsiveFontSize.getBodyLarge(context)),
                      ),
                      subtitle: Text(
                        'Find friends using Compass OS',
                        style: TextStyle(fontSize: ResponsiveFontSize.getBodyMedium(context)),
                      ),
                      onChanged: notifier.setSocialPresenceOptIn,
                    ),
                    if (state.socialPresenceOptIn) ...[
                      SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(12)),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Import contacts',
                          style: TextStyle(fontSize: ResponsiveFontSize.getBodyLarge(context)),
                        ),
                        subtitle: Text(
                          state.contactsImported ? 'Contacts imported' : 'Tap to import',
                          style: TextStyle(fontSize: ResponsiveFontSize.getBodyMedium(context)),
                        ),
                        trailing: Icon(
                          state.contactsImported ? Icons.check_circle : Icons.upload_file,
                        ),
                        onTap: state.contactsImported
                            ? null
                            : () async {
                                // Simulate contacts import
                                notifier.setContactsImported(true);
                              },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReview(BuildContext context, OnboardingNotifier notifier, OnboardingState state) {
    return ResponsiveLayoutBuilder(
      mobile: (context, constraints) => _buildReviewContent(context, notifier, state, isDesktop: false),
      tablet: (context, constraints) => _buildReviewContent(context, notifier, state, isDesktop: false),
      desktop: (context, constraints) => _buildReviewContent(context, notifier, state, isDesktop: true),
    );
  }

  Widget _buildReviewContent(BuildContext context, OnboardingNotifier notifier, OnboardingState state, {required bool isDesktop}) {
    final horizontalPadding = ResponsiveSpacing.getHorizontalPadding(context);
    final contentMaxWidth = ResponsiveSpacing.getContentMaxWidth(context);
    
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: ResponsiveSpacing.getVerticalPadding(context) * 0.8),
              
              // Illustration
              Center(
                child: _buildCompletionCheckBadge(
                  context,
                  size: isDesktop ? null : MediaQuery.of(context).size.width * 0.28,
                ),
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(32)),
              
              // Title
              Text(
                'Review',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: ResponsiveFontSize.getTitleLarge(context),
                ),
                textAlign: isDesktop ? TextAlign.center : TextAlign.start,
              ),
              SizedBox(height: ResponsiveSpacing.getGoldenRatioLarge(24)),
              
              // Review items container
              Container(
                padding: EdgeInsets.all(ResponsiveSpacing.getGoldenRatioSmall(20)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getMedium(context)),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReviewItem(
                      context,
                      'Primary virtue',
                      state.primaryVirtue.name,
                    ),
                    SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(8)),
                    _buildReviewItem(
                      context,
                      'Neglected virtue',
                      state.neglectedVirtue.name,
                    ),
                    SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(8)),
                    _buildReviewItem(
                      context,
                      'Reminders',
                      state.remindersEnabled ? 'on' : 'off',
                    ),
                    SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(8)),
                    _buildReviewItem(
                      context,
                      'Journal time',
                      state.journalReminderTime,
                    ),
                    SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(8)),
                    _buildReviewItem(
                      context,
                      'Window',
                      state.notificationWindow,
                    ),
                    SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(8)),
                    _buildReviewItem(
                      context,
                      'Social presence',
                      state.socialPresenceOptIn ? 'on' : 'off',
                    ),
                    if (state.socialPresenceOptIn) ...[
                      SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(8)),
                      _buildReviewItem(
                        context,
                        'Contacts',
                        state.contactsImported ? 'imported' : 'skipped',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveFontSize.getBodyMedium(context),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontSize: ResponsiveFontSize.getBodyMedium(context),
          ),
        ),
      ],
    );
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
    final horizontalPadding = ResponsiveSpacing.getHorizontalPadding(context);
    final contentMaxWidth = ResponsiveSpacing.getContentMaxWidth(context);

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
            fontSize: ResponsiveFontSize.getTitleLarge(context),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
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
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: TweenAnimationBuilder<double>(
        duration: _duration,
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Interval(0.6, 1.0, curve: _curve),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: PrimaryButton(
                      label: 'Back',
                      onPressed: state.step == OnboardingStep.welcome ? null : notifier.back,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      label: state.isLastStep ? 'Begin' : 'Next',
                      onPressed: () async {
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopButtons(BuildContext context, OnboardingState state, OnboardingNotifier notifier, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSpacing.getHorizontalPadding(context)),
      child: TweenAnimationBuilder<double>(
        duration: _duration,
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Interval(0.6, 1.0, curve: _curve),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 200,
                    child: PrimaryButton(
                      label: 'Back',
                      onPressed: state.step == OnboardingStep.welcome ? null : notifier.back,
                    ),
                  ),
                  const SizedBox(width: 32),
                  SizedBox(
                    width: 200,
                    child: PrimaryButton(
                      label: state.isLastStep ? 'Begin' : 'Next',
                      onPressed: () async {
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
