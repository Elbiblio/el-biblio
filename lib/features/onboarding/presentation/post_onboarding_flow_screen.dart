import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/light_rays_reveal.dart';
import '../../assessment/domain/models/archetype.dart';
import '../../commitments/domain/models/commitment_category.dart';
import '../../commitments/domain/models/commitment_journey.dart';
import '../../companion/application/companion_chat_notifier.dart';
import '../../companion/application/companion_notifier.dart';
import '../../companion/domain/models/christian_life_baseline.dart';
import '../../companion/domain/models/companion_character.dart';
import '../../companion/presentation/screens/companion_selection_screen.dart';
import '../application/onboarding_notifier.dart';
import 'widgets/christian_life_baseline_view.dart';
import 'widgets/good_habits_view.dart';
import 'widgets/reminder_times_view.dart';
import 'widgets/struggles_view.dart';

/// Post-signup guided flow.
///
/// Eight pages across Phase 2 (spiritual state evaluation) and Phase 3
/// (commitment + companion + reminders), exactly as the user described:
///
/// 1. Welcome / Identity Reveal — light-rays moment on "Welcome Home"
/// 2. Faith Baseline — Christian-life snapshot (Word, church, prayer, scores)
/// 3. Good Habits — what's already alive in the user
/// 4. Struggles — what they're currently fighting
/// 5. Companion — Raziel / Naomi / James
/// 6. First Commitment — category-aware short journey
/// 7. Reminder Times — morning/evening anchors + adaptive partner cadence
/// 8. Launch — "Your Day Begins" with a light-rays moment
class PostOnboardingFlowScreen extends ConsumerStatefulWidget {
  const PostOnboardingFlowScreen({super.key});

  @override
  ConsumerState<PostOnboardingFlowScreen> createState() =>
      _PostOnboardingFlowScreenState();
}

class _PostOnboardingFlowScreenState
    extends ConsumerState<PostOnboardingFlowScreen>
    with TickerProviderStateMixin {
  // Page indices used for side-effects on page change.
  static const int _pageBaseline = 1;
  static const int _pageCommitment = 5;
  static const int _totalPages = 8;

  final _pageController = PageController();
  int _currentPage = 0;

  // Commitment-page state
  CommitmentDuration _selectedDuration = CommitmentDuration.seed3Day;
  CommitmentJourney? _selectedJourney;
  bool _skipCommitment = false;

  // Page 1 reveal animation
  late final AnimationController _revealController;
  late final Animation<double> _revealScale;
  late final Animation<double> _revealFade;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: AppAnimations.reveal,
    );
    _revealScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: AppAnimations.bounceCurve,
      ),
    );
    _revealFade = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(commitmentJourneyProvider.notifier).loadAvailableJourneys();
      Future.delayed(AppAnimations.normal, () {
        if (mounted) _revealController.forward();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    HapticService.selection();
    _pageController.animateToPage(
      page,
      duration: AppAnimations.normal,
      curve: AppAnimations.defaultCurve,
    );
  }

  void _nextPage() => _goToPage(_currentPage + 1);

  /// Fires whenever a page settles. Performs any side-effects that belong
  /// to *leaving* the previous page (mostly persistence).
  void _onPageChanged(int page) {
    setState(() => _currentPage = page);

    // Persist the baseline as soon as the user leaves it — the post-onboarding
    // flow can be abandoned mid-way and we want a best-effort snapshot kept.
    if (page > _pageBaseline) {
      final baseline = ref.read(onboardingProvider).baselineOrNull;
      if (baseline != null) {
        ref.read(settingsProvider.notifier).setChristianLifeBaseline(baseline);
      }
    }

    // Auto-seed first commitment when the commitment page becomes visible.
    if (page == _pageCommitment && _selectedJourney == null) {
      _autoSelectFirstJourney();
    }
  }

  void _autoSelectFirstJourney() {
    final archetypeId = ref.read(settingsProvider).primaryArchetypeId;
    final category = archetypeId != null
        ? CommitmentCategory.recommendedForArchetype(archetypeId)
        : CommitmentCategory.growth;
    final journeys = ref
        .read(commitmentJourneyProvider)
        .availableJourneys
        .where((j) => j.duration == _selectedDuration && j.category == category)
        .toList();
    if (journeys.isNotEmpty) {
      setState(() => _selectedJourney = journeys.first);
    }
  }

  /// Seeds the companion chat with a warm opener keyed to the active
  /// character plus the user's weakest baseline dimension.
  Future<void> _seedCompanionOpener() async {
    final settings = ref.read(settingsProvider);
    final character = ref.read(companionProvider).activeCharacter ??
        CompanionCharacter.naomi;
    final baseOpener = character.warmOpener();
    final weakest = settings.christianLifeBaseline?.weakestDimension;
    final baselineNote = weakest == null
        ? ''
        : '\n\nAnd thank you for being honest about ${weakest.humanLabel} — that\'s exactly where we\'ll start, gently.';
    final opener = '$baseOpener$baselineNote';

    const chatKey = CompanionChatKey(threadKey: 'welcome');
    await ref
        .read(companionChatProvider(chatKey).notifier)
        .seedAssistantOpener(opener);
  }

  /// True when the baseline suggests a user who's already walking a steady
  /// rhythm — enough to justify a weekly (rather than daily) partner cadence.
  bool _isBaselineStrong() {
    final baseline = ref.read(settingsProvider).christianLifeBaseline ??
        ref.read(onboardingProvider).baselineOrNull;
    if (baseline == null) return false;
    final avg = (baseline.bibleReadingCadence.normalizedScore +
            baseline.lastChurchAttendance.normalizedScore +
            baseline.prayerRhythm.normalizedScore +
            baseline.sovereigntyScore / 5.0 +
            baseline.charityScore / 5.0 +
            baseline.trustScore / 5.0) /
        6.0;
    return avg >= 0.7;
  }

  Future<void> _finish() async {
    HapticService.milestone();
    final settings = ref.read(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final notificationService = ref.read(notificationServiceProvider);

    // Start the selected journey if one was chosen.
    if (!_skipCommitment && _selectedJourney != null) {
      await ref.read(commitmentJourneyProvider.notifier).startJourney(
            journeyId: _selectedJourney!.id,
            prayerIntention: 'Guide me on this journey, Lord.',
            source: 'post_onboarding',
          );
    }

    // Resolve cadence — user's reminder page persists this; fall back to
    // the baseline-derived default.
    final cadence = settings.accountabilityCadence.isEmpty
        ? (_isBaselineStrong() ? 'weekly' : 'daily')
        : settings.accountabilityCadence;
    await notifier.setAccountabilityCadence(cadence);

    // Schedule the partner check-in at the resolved cadence. The companion
    // itself stands in as the default AI partner for day one.
    final companion = ref.read(companionProvider).activeCharacter ??
        CompanionCharacter.naomi;
    await notificationService.scheduleAccountabilityPartnerCheckIn(
      partnerName: companion.displayName,
      cadence: cadence,
      isAiCompanion: true,
    );

    // Schedule the first daily-verse shell in the companion's voice.
    final firstBook = companion.dailyVerseBookPriority.first;
    await notificationService.scheduleCompanionDailyVerse(
      companionCode: companion.code,
      companionDisplayName: companion.displayName,
      deliveryTime: settings.morningTime,
      verseReference: '$firstBook 1:1',
      verseText:
          'A word from ${companion.displayName} — open the app for today\'s passage.',
    );

    await notifier.markPostOnboardingComplete();

    if (!mounted) return;
    context.go(AppRoutes.today);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final settings = ref.watch(settingsProvider);

    // Persist baseline the moment it becomes complete, not only on page-leave.
    // If the user app-kills on page 2 after answering all six prompts, the
    // snapshot survives.
    ref.listen(onboardingProvider, (previous, next) {
      final prevBaseline = previous?.baselineOrNull;
      final nextBaseline = next.baselineOrNull;
      if (nextBaseline == null) return;
      final prevKey = prevBaseline == null
          ? null
          : '${prevBaseline.bibleReadingCadence.storageValue}|'
              '${prevBaseline.lastChurchAttendance.storageValue}|'
              '${prevBaseline.prayerRhythm.storageValue}|'
              '${prevBaseline.sovereigntyScore}|'
              '${prevBaseline.charityScore}|'
              '${prevBaseline.trustScore}';
      final nextKey =
          '${nextBaseline.bibleReadingCadence.storageValue}|'
          '${nextBaseline.lastChurchAttendance.storageValue}|'
          '${nextBaseline.prayerRhythm.storageValue}|'
          '${nextBaseline.sovereigntyScore}|'
          '${nextBaseline.charityScore}|'
          '${nextBaseline.trustScore}';
      if (prevKey == nextKey) return;
      ref.read(settingsProvider.notifier).setChristianLifeBaseline(nextBaseline);
    });

    final archetypeId = settings.primaryArchetypeId;
    final archetype = archetypeId != null
        ? Archetype.allArchetypes.cast<Archetype?>().firstWhere(
              (a) => a?.name == archetypeId,
              orElse: () => null,
            )
        : null;

    final recommendedCategory = archetypeId != null
        ? CommitmentCategory.recommendedForArchetype(archetypeId)
        : CommitmentCategory.growth;

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
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                child: Row(
                  children: List.generate(_totalPages, (i) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: AppAnimations.fast,
                        height: 3,
                        margin: EdgeInsets.only(
                          right: i < _totalPages - 1 ? 6 : 0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i <= _currentPage
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.12),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const _BackOnlySwipePhysics(),
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildWelcomePage(theme, archetype),
                    _buildBaselinePage(theme),
                    _buildGoodHabitsPage(),
                    _buildStrugglesPage(),
                    _buildCompanionPage(),
                    _buildCommitmentPage(theme, archetype, recommendedCategory),
                    _buildRemindersPage(),
                    _buildLaunchPage(theme, archetype, recommendedCategory),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page 1: Welcome / Identity Reveal ────────────────────────────────────

  Widget _buildWelcomePage(ThemeData theme, Archetype? archetype) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 32),
          FadeTransition(
            opacity: _revealFade,
            child: LightRaysReveal(
              delay: const Duration(milliseconds: 200),
              maxOpacity: 0.5,
              rayCount: 12,
              expandBeyond: 80,
              child: Text(
                'Welcome Home',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ScaleTransition(
            scale: _revealScale,
            child: FadeTransition(
              opacity: _revealFade,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.colorScheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    archetype?.name[0] ?? '?',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _revealFade,
            child: Column(
              children: [
                Text(
                  'You are a',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  archetype?.name ?? 'Explorer',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'The ${archetype?.identity ?? 'Seeker'}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (archetype != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star_outline,
                                size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Your Strengths',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          archetype.strengths,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (archetype?.primaryVice != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.visibility_outlined,
                                size: 16, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Watch For',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${archetype!.primaryVice!.label} — ${archetype.primaryVice!.description.split('.').first}.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.push(AppRoutes.assessment),
              child: Text(
                'Not quite right? Take the full assessment',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  decoration: TextDecoration.underline,
                  decorationColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Page 2: Faith Baseline ───────────────────────────────────────────────

  Widget _buildBaselinePage(ThemeData theme) {
    return Column(
      children: [
        const Expanded(child: ChristianLifeBaselineView()),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Page 3: Good Habits ──────────────────────────────────────────────────

  Widget _buildGoodHabitsPage() {
    return GoodHabitsView(onContinue: _nextPage);
  }

  // ─── Page 4: Struggles ────────────────────────────────────────────────────

  Widget _buildStrugglesPage() {
    return StrugglesView(onContinue: _nextPage);
  }

  // ─── Page 5: Companion ────────────────────────────────────────────────────

  Widget _buildCompanionPage() {
    return CompanionSelectionScreen(
      onContinue: () async {
        await _seedCompanionOpener();
        if (!mounted) return;
        _nextPage();
      },
      onSkip: () async {
        await _seedCompanionOpener();
        if (!mounted) return;
        _nextPage();
      },
    );
  }

  // ─── Page 6: First Commitment ─────────────────────────────────────────────

  Widget _buildCommitmentPage(
    ThemeData theme,
    Archetype? archetype,
    CommitmentCategory category,
  ) {
    final journeyState = ref.watch(commitmentJourneyProvider);
    final filteredJourneys = journeyState.availableJourneys
        .where((j) => j.duration == _selectedDuration && j.category == category)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Your First Step',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Every journey starts with a single commitment. We recommend starting small.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${category.icon} ${category.label} path — ${category.tagline}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: category.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: CommitmentDuration.values.map((d) {
              final isSelected = _selectedDuration == d;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: '${d.days} day commitment',
                  child: GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    setState(() {
                      _selectedDuration = d;
                      _selectedJourney = null;
                    });
                    _autoSelectFirstJourney();
                  },
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.4)
                            : theme.colorScheme.outline.withValues(alpha: 0.15),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${d.days}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color:
                                isSelected ? theme.colorScheme.primary : null,
                          ),
                        ),
                        Text(
                          'days',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (filteredJourneys.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No journeys available for this duration yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            )
          else
            ...filteredJourneys.take(3).map((journey) {
              final isSelected = _selectedJourney?.id == journey.id;
              return GestureDetector(
                onTap: () {
                  HapticService.selection();
                  setState(() => _selectedJourney = journey);
                },
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.08)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.4)
                          : theme.colorScheme.outline.withValues(alpha: 0.12),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    journey.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (journey.source != CommitmentSource.remote)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Icon(
                                      Icons.cloud_off_outlined,
                                      size: 14,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              journey.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _selectedJourney != null ? 'Continue' : 'Skip for now',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (_selectedJourney != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _skipCommitment = true;
                    _selectedJourney = null;
                  });
                  _nextPage();
                },
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Page 7: Reminder Times + Partner Cadence ─────────────────────────────

  Widget _buildRemindersPage() {
    return ReminderTimesView(
      baselineStrong: _isBaselineStrong(),
      onContinue: _nextPage,
    );
  }

  // ─── Page 8: Launch ───────────────────────────────────────────────────────

  Widget _buildLaunchPage(
    ThemeData theme,
    Archetype? archetype,
    CommitmentCategory category,
  ) {
    final companion = ref.watch(companionProvider).activeCharacter ??
        CompanionCharacter.naomi;
    final cadence = ref.watch(settingsProvider).accountabilityCadence;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.wb_sunny_outlined,
            size: 48,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 20),
          LightRaysReveal(
            delay: const Duration(milliseconds: 180),
            maxOpacity: 0.45,
            rayCount: 10,
            expandBeyond: 72,
            child: Text(
              'Your Day Begins',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                _summaryRow(
                  theme,
                  icon: Icons.fingerprint,
                  label: 'Identity',
                  value:
                      '${archetype?.name ?? 'Explorer'} — The ${archetype?.identity ?? 'Seeker'}',
                ),
                const SizedBox(height: 16),
                _summaryRow(
                  theme,
                  icon: Icons.auto_awesome_outlined,
                  label: 'Companion',
                  value: companion.displayName,
                ),
                if (!_skipCommitment && _selectedJourney != null) ...[
                  const SizedBox(height: 16),
                  _summaryRow(
                    theme,
                    icon: Icons.flag_outlined,
                    label: 'Commitment',
                    value:
                        '${_selectedJourney!.title} (${_selectedDuration.days} days)',
                  ),
                ],
                const SizedBox(height: 16),
                _summaryRow(
                  theme,
                  icon: Icons.route_outlined,
                  label: 'Path',
                  value:
                      '${category.icon} ${category.label} — ${category.tagline}',
                ),
                const SizedBox(height: 16),
                _summaryRow(
                  theme,
                  icon: Icons.handshake_outlined,
                  label: 'Partner check-in',
                  value: cadence == 'weekly'
                      ? 'Weekly — Fridays at 7pm'
                      : 'Daily — evenings at 7pm',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticService.light();
                Share.share(
                  'I\'m using El-Biblio to grow spiritually and stay accountable. Walk with me — download it here: https://elbiblio.com',
                );
              },
              icon: const Icon(Icons.share_outlined, size: 20),
              label: const Text('Invite a Friend'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _finish,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Let's go",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _summaryRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Allows horizontal back-swipe only. Forward-swipe is rejected so users can't
/// bypass the current page's validation — `_nextPage()` (button-driven) still
/// works because `animateToPage` bypasses physics.
class _BackOnlySwipePhysics extends ClampingScrollPhysics {
  const _BackOnlySwipePhysics({super.parent});

  @override
  _BackOnlySwipePhysics applyTo(ScrollPhysics? ancestor) {
    return _BackOnlySwipePhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (offset > 0) return 0;
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if (velocity > 0) return null;
    return super.createBallisticSimulation(position, velocity);
  }
}
