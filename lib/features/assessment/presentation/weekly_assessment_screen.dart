import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_providers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../domain/models/weekly_plan.dart';

/// A lightweight 3-step weekly assessment that replaces auto-generated plans
/// with an interactive flow: Rate -> Reflect -> Set Focus.
class WeeklyAssessmentScreen extends ConsumerStatefulWidget {
  const WeeklyAssessmentScreen({super.key});

  @override
  ConsumerState<WeeklyAssessmentScreen> createState() =>
      _WeeklyAssessmentScreenState();
}

class _WeeklyAssessmentScreenState
    extends ConsumerState<WeeklyAssessmentScreen>
    with SingleTickerProviderStateMixin {
  static const _totalSteps = 3;

  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1 state
  int _weekRating = 0; // 1-5
  String? _focusArea; // growth, discipline, charity

  // Step 2 state
  final _wentWellController = TextEditingController();
  final _challengingController = TextEditingController();

  // Step 3 state
  int _dailyMinutes = 15; // 5, 15, or 30

  bool _isGenerating = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: AppAnimations.fadeCurve,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _wentWellController.dispose();
    _challengingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticService.selection();
      ref.read(soundServiceProvider).playTransition();
      _pageController.animateToPage(
        _currentStep + 1,
        duration: AppAnimations.normal,
        curve: AppAnimations.defaultCurve,
      );
    }
  }

  bool get _canAdvanceFromStep1 => _weekRating > 0 && _focusArea != null;

  Future<void> _createPlan() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    HapticService.milestone();

    try {
      final settings = ref.read(settingsProvider);
      final profile = settings.callingProfile;
      if (profile == null) {
        // No calling profile, just pop back
        if (mounted) context.pop();
        return;
      }

      final callingProfileService = ref.read(callingProfileServiceProvider);
      final now = DateTime.now();
      final weekStart = _startOfWeek(now);

      var weeklyPlan = callingProfileService.generateWeeklyPlan(
        profile: profile,
        weekStart: weekStart,
        morningTime: settings.morningTime,
        eveningTime: settings.eveningTime,
      );

      // Override the mission focus based on user's chosen focus area
      if (_focusArea != null) {
        final missionFocus = switch (_focusArea) {
          'charity' => 'service',
          'discipline' => 'faithSharing',
          'growth' => 'encouragement',
          _ => weeklyPlan.missionFocusForWeek,
        };
        weeklyPlan = weeklyPlan.copyWith(missionFocusForWeek: missionFocus);
      }

      // Adjust daily anchor durations based on time commitment
      final adjustedAnchors = weeklyPlan.dailyAnchors.map((anchor) {
        final adjusted = switch (_dailyMinutes) {
          5 => (anchor.duration * 0.5).round().clamp(3, 10),
          30 => (anchor.duration * 1.5).round().clamp(10, 30),
          _ => anchor.duration,
        };
        return DailyAnchor(
          timeOfDay: anchor.timeOfDay,
          practice: anchor.practice,
          duration: adjusted,
          description: anchor.description,
        );
      }).toList();
      weeklyPlan = weeklyPlan.copyWith(dailyAnchors: adjustedAnchors);

      // Build a reflection prompt incorporating user input
      final reflectionParts = <String>[];
      if (_wentWellController.text.trim().isNotEmpty) {
        reflectionParts.add(
          'Last week you noted: "${_wentWellController.text.trim()}"',
        );
      }
      if (_challengingController.text.trim().isNotEmpty) {
        reflectionParts.add(
          'Challenge to address: "${_challengingController.text.trim()}"',
        );
      }
      if (reflectionParts.isNotEmpty) {
        weeklyPlan = weeklyPlan.copyWith(
          reflectionPrompt:
              '${weeklyPlan.reflectionPrompt} ${reflectionParts.join('. ')}',
        );
      }

      await ref
          .read(settingsProvider.notifier)
          .setCurrentWeeklyPlan(weeklyPlan);
    } finally {
      if (mounted) {
        ref.read(soundServiceProvider).playComplete();
        setState(() => _isGenerating = false);
        context.pop();
      }
    }
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tokens.pageGradient,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                // Header with close button and progress
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => context.pop(),
                        style: IconButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const Spacer(),
                      // Progress dots
                      Row(
                        children: List.generate(_totalSteps, (i) {
                          return AnimatedContainer(
                            duration: AppAnimations.fast,
                            width: i == _currentStep ? 24 : 8,
                            height: 4,
                            margin: EdgeInsets.only(
                              right: i < _totalSteps - 1 ? 6 : 0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: i <= _currentStep
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.12),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // balance close button
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentStep = i),
                    children: [
                      _buildRateStep(theme, tokens),
                      _buildReflectStep(theme, tokens),
                      _buildFocusStep(theme, tokens),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: Rate Your Week
  // ---------------------------------------------------------------------------
  Widget _buildRateStep(ThemeData theme, AppThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            'How would you rate your\nspiritual growth this week?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // 1-5 rating circles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final value = i + 1;
              final isSelected = _weekRating == value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    setState(() => _weekRating = value);
                  },
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary
                              .withValues(alpha: 0.08),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary
                                .withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$value',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 48),

          // Focus area
          Text(
            'Which area needs the most attention?',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: [
              _buildFocusChip('Growth', 'growth', Icons.trending_up_rounded,
                  theme),
              _buildFocusChip('Discipline', 'discipline',
                  Icons.shield_outlined, theme),
              _buildFocusChip(
                  'Charity', 'charity', Icons.favorite_border_rounded, theme),
            ],
          ),

          const Spacer(flex: 3),

          // Next button
          _buildNextButton(
            theme: theme,
            label: 'Continue',
            enabled: _canAdvanceFromStep1,
            onPressed: _nextStep,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFocusChip(
      String label, String value, IconData icon, ThemeData theme) {
    final isSelected = _focusArea == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? Colors.white
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (_) {
        HapticService.selection();
        setState(() => _focusArea = value);
      },
      selectedColor: theme.colorScheme.primary,
      backgroundColor:
          theme.colorScheme.primary.withValues(alpha: 0.06),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : theme.colorScheme.primary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Reflect
  // ---------------------------------------------------------------------------
  Widget _buildReflectStep(ThemeData theme, AppThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Text(
              'Take a moment to reflect',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Both fields are optional',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 36),

            _buildTextField(
              controller: _wentWellController,
              label: 'What went well this week?',
              hint: 'e.g., Consistent morning prayer...',
              theme: theme,
              tokens: tokens,
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _challengingController,
              label: 'What was challenging?',
              hint: 'e.g., Struggled with focus...',
              theme: theme,
              tokens: tokens,
            ),
            const SizedBox(height: 48),

            _buildNextButton(
              theme: theme,
              label: 'Continue',
              enabled: true,
              onPressed: _nextStep,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ThemeData theme,
    required AppThemeTokens tokens,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            filled: true,
            fillColor: isDark
                ? theme.colorScheme.surface
                : tokens.palette.paper,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusMedium),
              borderSide: BorderSide(
                color: tokens.palette.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusMedium),
              borderSide: BorderSide(
                color: tokens.palette.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusMedium),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: Set Your Focus
  // ---------------------------------------------------------------------------
  Widget _buildFocusStep(ThemeData theme, AppThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            'Set your daily commitment',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'How much daily time can you commit?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 36),

          // Time options
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeOption(5, 'Quick\n5 min', theme),
              const SizedBox(width: 12),
              _buildTimeOption(15, 'Steady\n15 min', theme),
              const SizedBox(width: 12),
              _buildTimeOption(30, 'Deep\n30 min', theme),
            ],
          ),

          const Spacer(flex: 3),

          // Create Plan button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isGenerating ? null : _createPlan,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create My Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimeOption(int minutes, String label, ThemeData theme) {
    final isSelected = _dailyMinutes == minutes;
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        setState(() => _dailyMinutes = minutes);
      },
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0.4),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared widgets
  // ---------------------------------------------------------------------------
  Widget _buildNextButton({
    required ThemeData theme,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              theme.colorScheme.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
