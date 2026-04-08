import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../assessment/domain/models/archetype.dart';
import '../../commitments/domain/models/commitment_category.dart';
import '../../commitments/domain/models/commitment_journey.dart';
import '../../mission/domain/models/mission_focus.dart';

/// Post-onboarding guided flow that runs immediately after account creation.
///
/// 5 pages: Identity Reveal → Mission & Struggles → First Commitment → Stronger Together → Launch
/// Feels like a continuation of onboarding, not a separate feature.
class PostOnboardingFlowScreen extends ConsumerStatefulWidget {
  const PostOnboardingFlowScreen({super.key});

  @override
  ConsumerState<PostOnboardingFlowScreen> createState() =>
      _PostOnboardingFlowScreenState();
}

class _PostOnboardingFlowScreenState
    extends ConsumerState<PostOnboardingFlowScreen>
    with TickerProviderStateMixin {
  static const _totalPages = 5;

  final _pageController = PageController();
  int _currentPage = 0;

  // Page 2 state (Mission & Struggles)
  String? _selectedMissionFocus;
  final Set<String> _selectedDistractions = {};

  static const _commonDistractions = [
    'Social Media',
    'Gaming',
    'Pornography',
    'Alcohol',
    'Gambling',
    'Overeating',
    'Shopping',
    'Gossip',
  ];

  // Page 3 state (Commitment)
  CommitmentDuration _selectedDuration = CommitmentDuration.seed3Day;
  CommitmentJourney? _selectedJourney;
  bool _skipCommitment = false;

  // Page 1 animation
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
      CurvedAnimation(parent: _revealController, curve: AppAnimations.bounceCurve),
    );
    _revealFade = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
    );

    // Load journeys and trigger reveal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commitmentJourneyProvider.notifier).loadAvailableJourneys();

      // Pre-fill mission focus from settings if available
      final settings = ref.read(settingsProvider);
      if (settings.primaryMissionFocus != null) {
        _selectedMissionFocus = settings.primaryMissionFocus;
      }

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

  void _nextPage() {
    // Save mission/distractions when leaving page 2
    if (_currentPage == 1) {
      _saveMissionAndDistractions();
    }
    _goToPage(_currentPage + 1);
  }

  void _saveMissionAndDistractions() {
    final notifier = ref.read(settingsProvider.notifier);
    if (_selectedMissionFocus != null) {
      notifier.setPrimaryMissionFocus(_selectedMissionFocus!);
    }
    if (_selectedDistractions.isNotEmpty) {
      // Save personal distractions to settings via onboarding state
      // These are already captured in the settings during completeOnboarding
    }
  }

  Future<void> _finish() async {
    HapticService.milestone();

    // Start the selected journey if one was chosen
    if (!_skipCommitment && _selectedJourney != null) {
      await ref.read(commitmentJourneyProvider.notifier).startJourney(
            journeyId: _selectedJourney!.id,
            prayerIntention: 'Guide me on this journey, Lord.',
          );
    }

    // Mark post-onboarding as complete
    await ref.read(settingsProvider.notifier).markPostOnboardingComplete();

    if (!mounted) return;
    context.go(AppRoutes.today);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final settings = ref.watch(settingsProvider);

    // Resolve archetype
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
              // Progress dots
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                child: Row(
                  children: List.generate(_totalPages, (i) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: AppAnimations.fast,
                        height: 3,
                        margin: EdgeInsets.only(right: i < _totalPages - 1 ? 8 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i <= _currentPage
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildWelcomePage(theme, archetype),
                    _buildMissionAndStrugglesPage(theme, archetype),
                    _buildCommitmentPage(theme, archetype, recommendedCategory),
                    _buildPartnerPage(theme),
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

  // ---------------------------------------------------------------------------
  // Page 1: Welcome / Identity Reveal
  // ---------------------------------------------------------------------------

  Widget _buildWelcomePage(ThemeData theme, Archetype? archetype) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 32),
          FadeTransition(
            opacity: _revealFade,
            child: Text(
              'Welcome Home',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w300,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Archetype badge
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

                // Strengths summary
                if (archetype != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star_outline, size: 16, color: theme.colorScheme.primary),
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
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Vice awareness
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
                            Icon(Icons.visibility_outlined, size: 16, color: Colors.orange.shade700),
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
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

          // Subtle retake link
          Center(
            child: TextButton(
              onPressed: () => context.push(AppRoutes.assessment),
              child: Text(
                'Not quite right? Take the full assessment',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  decoration: TextDecoration.underline,
                  decorationColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
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
              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page 2: Mission Focus & Struggles (moved from onboarding Your Path)
  // ---------------------------------------------------------------------------

  Widget _buildMissionAndStrugglesPage(ThemeData theme, Archetype? archetype) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Your Mission',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How do you want your calling to show up in daily life?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Mission Focus chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: MissionFocusType.values.map((focus) {
              final isSelected = _selectedMissionFocus == focus.name;
              return ChoiceChip(
                label: Text(focus.label),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedMissionFocus = focus.name),
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                labelStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              );
            }).toList(),
          ),
          if (_selectedMissionFocus != null) ...[
            const SizedBox(height: 10),
            Text(
              MissionFocusTypeX.fromStorage(_selectedMissionFocus).description,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],

          // Archetype-specific distractions info
          if (archetype != null && archetype.typicalDistractions.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Common pitfalls for a ${archetype.name}:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...archetype.typicalDistractions.take(3).map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\u2022 ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error.withValues(alpha: 0.5),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              d,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Personal struggles picker
          const SizedBox(height: 24),
          Text(
            'STRUGGLES TO OVERCOME',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select any that apply — we\'ll help you stay aware.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonDistractions.map((distraction) {
              final isSelected = _selectedDistractions.contains(distraction);
              return FilterChip(
                selected: isSelected,
                label: Text(distraction),
                labelStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDistractions.add(distraction);
                    } else {
                      _selectedDistractions.remove(distraction);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _nextPage,
              child: Text(
                'Skip for now',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page 3: First Commitment
  // ---------------------------------------------------------------------------

  Widget _buildCommitmentPage(ThemeData theme, Archetype? archetype, CommitmentCategory category) {
    final journeyState = ref.watch(commitmentJourneyProvider);
    final filteredJourneys = journeyState.availableJourneys
        .where((j) => j.duration == _selectedDuration && j.category == category)
        .toList();

    // Auto-select first if none selected
    if (_selectedJourney == null && filteredJourneys.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedJourney = filteredJourneys.first);
      });
    }

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

          // Recommended category chip
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

          // Duration selector
          Row(
            children: CommitmentDuration.values.map((d) {
              final isSelected = _selectedDuration == d;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    setState(() {
                      _selectedDuration = d;
                      _selectedJourney = null;
                    });
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
                            color: isSelected ? theme.colorScheme.primary : null,
                          ),
                        ),
                        Text(
                          'days',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Journey cards
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
                          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              journey.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              journey.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

          // Continue / Skip
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _selectedJourney != null ? 'Continue' : 'Skip for now',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page 4: Stronger Together (with teaser + 3-strikes)
  // ---------------------------------------------------------------------------

  Widget _buildPartnerPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            'Stronger Together',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Growth multiplies when shared. See how your Today screen looks with accountability partners.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // --- Teaser mockup card ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity summary
                Row(
                  children: [
                    Icon(Icons.people_rounded, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Community Activity',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Teaser check-in stats
                _teaserRow(theme, Icons.check_circle_outline, '4 contacts checked in today',
                    theme.colorScheme.primary),
                const SizedBox(height: 10),
                _teaserRow(theme, Icons.emoji_events_outlined, '1 contact completed a 3-day commitment',
                    Colors.amber.shade700),
                const SizedBox(height: 10),
                _teaserRow(theme, Icons.handshake_outlined, '2 partners prayed for each other this morning',
                    theme.colorScheme.secondary),

                const SizedBox(height: 16),

                // Anonymous note
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_off_outlined, size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anonymous — partners only see activity, not details',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Invite button
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
            ),
          ),

          // 3-strikes info
          const SizedBox(height: 16),
          Text(
            'Partners who miss 3 check-ins are automatically removed to keep accountability strong.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 32),

          // Continue
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _nextPage,
            child: Text(
              'Skip for now',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _teaserRow(ThemeData theme, IconData icon, String text, Color color) {
    return Row(
      children: [
        // Fake avatar dots
        SizedBox(
          width: 28,
          height: 20,
          child: Stack(
            children: [
              Positioned(left: 0, child: _miniAvatar(theme, color.withValues(alpha: 0.3))),
              Positioned(left: 10, child: _miniAvatar(theme, color.withValues(alpha: 0.5))),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniAvatar(ThemeData theme, Color color) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.surface, width: 1.5),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page 5: Launch
  // ---------------------------------------------------------------------------

  Widget _buildLaunchPage(ThemeData theme, Archetype? archetype, CommitmentCategory category) {
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
          Text(
            'Your Day Begins',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // Summary card
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
                  value: '${archetype?.name ?? 'Explorer'} — The ${archetype?.identity ?? 'Seeker'}',
                ),
                if (!_skipCommitment && _selectedJourney != null) ...[
                  const SizedBox(height: 16),
                  _summaryRow(
                    theme,
                    icon: Icons.flag_outlined,
                    label: 'Commitment',
                    value: '${_selectedJourney!.title} (${_selectedDuration.days} days)',
                  ),
                ],
                const SizedBox(height: 16),
                _summaryRow(
                  theme,
                  icon: Icons.route_outlined,
                  label: 'Path',
                  value: '${category.icon} ${category.label} — ${category.tagline}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Launch CTA
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _finish,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _summaryRow(ThemeData theme, {required IconData icon, required String label, required String value}) {
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
