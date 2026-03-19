import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../domain/models/archetype.dart';
import '../domain/models/archetype_resonance.dart';
import '../application/assessment_notifier.dart';

/// Fear-first assessment screen - matches sophisticated web version
/// Uses actual archetype distortions translated to user-friendly language
/// Creates smart mapping between fears and related archetypes
class FearFirstAssessmentScreen extends ConsumerStatefulWidget {
  const FearFirstAssessmentScreen({super.key});

  @override
  ConsumerState<FearFirstAssessmentScreen> createState() =>
      _FearFirstAssessmentScreenState();
}

class _FearFirstAssessmentScreenState
    extends ConsumerState<FearFirstAssessmentScreen> {
  static const int _minimumFearSelections = 5;

  final List<SelectedFear> _selectedFears = [];
  final TextEditingController _fearSearchController = TextEditingController();
  late final List<FearItem> _allFears;
  String _fearSearchQuery = '';
  List<Archetype> _suggestedArchetypes = [];
  bool _showArchetypes = false;
  int _developmentMaturity = 3; // 1-5 scale, default middle

  // Modern fear translations for 18-30 age group
  static const Map<String, String> _fearTranslations = {
    'Vanity': 'Obsessed with likes, followers, and what people think online',
    'Elitism': 'Thinking you\'re better than everyone else',
    'Addiction to novelty': 'Always chasing the next trend or dopamine hit',
    'Compromise for popularity': 'Changing yourself to fit in with the cool kids',
    'Legalism': 'Being super judgmental about rules and other people\'s choices',
    'Paranoia': 'Constantly worrying people are talking about you or judging you',
    'Isolation': 'Ghosting people and avoiding real connections',
    'Resistance to grace': 'Too proud to admit when you\'re wrong or need help',
    'Overcontrol': 'Trying to micromanage everything in your life',
    'Fear of change': 'Stuck in your comfort zone, afraid to try new things',
    'Burnout': 'Running on empty from hustle culture and endless grinding',
    'Resistance to pruning': 'Holding onto toxic relationships or dead-end jobs',
    'Impulsiveness': 'Making rash decisions you regret later',
    'Shallow roots': 'Never committing to anything - jobs, relationships, or goals',
    'Ego-driven ambition': 'Chasing clout and validation instead of purpose',
    'Manipulation disguised as inspiration': 'Being controlling but calling it "leadership"',
    'People-pleasing': 'Saying yes to everything to avoid disappointing anyone',
    'Neglect of self-care': 'Pouring from an empty cup, ignoring your own needs',
    'Hospitality for personal gain': 'Being nice just to get something in return',
    'Avoidance of truth to keep comfort': 'Ghosting difficult conversations instead of being honest',
    'Neglect of own calling': 'Putting everyone else\'s dreams before your own purpose',
    'Enabling unhealthy dependence': 'Being the "fixer" in toxic relationships',
    'Resentment from lack of recognition': 'Feeling invisible and unappreciated for your efforts',
    'Fear of stepping forward': 'Playing small because you\'re afraid of failure or judgment',
    'Pride in insight': 'Thinking you\'re the smartest person in every room',
    'Neglect of action': 'All talk, no action - just posting about change without doing anything',
    'Fear of exposure': 'Hiding your true self because you\'re afraid of rejection',
    'Compromise': 'Dropping your standards and values to avoid rocking the boat',
    'Avoidance of conflict': 'Being a conflict-avoider at all costs',
    'Loss of identity': 'Losing yourself trying to be what others want you to be',
    'Savior complex': 'Trying to fix everyone\'s problems instead of focusing on yourself',
    'Emotional detachment': 'Shutting down feelings because vulnerability feels weak',
    'Avoidance of hard truths': 'Living in denial instead of facing reality',
    'Exploitation': 'Using people for connections, clout, or personal gain',
    'Obsession with metrics': 'Obsessing over followers, engagement rates, and validation numbers',
    'Superficiality': 'Keeping everything surface-level to avoid real intimacy',
    'Pride in results': 'Taking all the credit when success was a team effort',
    'Pride': 'Being too arrogant to learn or grow',
    'Bitterness': 'Holding grudges and letting past hurts poison your present',
    'Destructive rebellion': 'Rejecting everything just to be edgy or different',
    'Idolizing change': 'Chasing constant change without any real direction',
    'Rigid systems': 'Following rules even when they clearly don\'t work anymore',
    'Excessive control disguised as order': 'Being controlling but calling it "being organized"',
    'Perfectionism that stifles growth': 'Paralyzed by perfectionism, never actually starting',
    'Inflexibility in methods': 'Refusing to adapt or try new approaches even when failing',
    'Comparison trap': 'Constantly comparing your life to others\' highlight reels',
    'Fear of missing out (FOMO)': 'Anxiety from seeing everyone else\'s "perfect" lives online',
    'Analysis paralysis': 'Overthinking everything to the point of inaction',
    'Imposter syndrome': 'Feeling like a fraud despite your accomplishments',
    'Comfort zone addiction': 'Choosing safety over growth every single time',
    'External validation dependency': 'Needing constant praise and approval to feel worthy',
    'Toxic productivity': 'Wearing burnout as a badge of honor',
    'Fear of vulnerability': 'Keeping walls up because being real feels too risky',
    'Perfectionistic procrastination': 'Not starting because you can\'t guarantee perfect results',
    'People-pleasing burnout': 'Exhausted from saying yes to everyone but yourself',
  };

  @override
  void initState() {
    super.initState();
    _allFears = _extractFearsFromArchetypes();
    _allFears.shuffle();
  }

  @override
  void dispose() {
    _fearSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFF4B925);
    final bgColor = isDark ? const Color(0xFF221D10) : const Color(0xFFF8F7F5);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor.withValues(alpha: 0.8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Discover Your Work Calling',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.explore_rounded, color: textColor),
            onPressed: () => context.push('${AppRoutes.assessment}/compass'),
            tooltip: 'Try Compass Wheel',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with count
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'What\'s Holding You Back?',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Select the challenges and fears you\'ve faced or are facing. This helps us understand your unique work calling pattern. You can select ones you\'ve overcome or ones you\'re still working through.',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 16,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedFears.length >= _minimumFearSelections
                                  ? primaryColor.withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedFears.length >= _minimumFearSelections
                                    ? primaryColor.withValues(alpha: 0.3)
                                    : Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Selected: ${_selectedFears.length}/$_minimumFearSelections',
                              style: TextStyle(
                                color: _selectedFears.length >= _minimumFearSelections
                                    ? const Color(0xFFF4B925)
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedFears.length < _minimumFearSelections
                                ? 'Select at least ${_minimumFearSelections - _selectedFears.length} more to continue'
                                : 'Great! You can now analyze your patterns',
                            style: TextStyle(
                              color: _selectedFears.length < _minimumFearSelections
                                  ? Colors.red.withValues(alpha: 0.7)
                                  : Colors.green.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          
                          // Alternative approach toggle
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.help_outline_rounded,
                                  size: 16,
                                  color: textColor.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Prefer a visual approach?',
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.6),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => context.push('${AppRoutes.assessment}/compass'),
                                  child: const Text(
                                    'Try Compass Wheel',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Fear cloud or archetypes
                    if (!_showArchetypes)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildFearCloud(),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildRecommendedArchetypes(),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Action buttons pinned to bottom
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_showArchetypes)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _selectedFears.length >= _minimumFearSelections
                              ? _analyzeFears
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _selectedFears.length >= _minimumFearSelections
                                ? primaryColor
                                : Colors.grey,
                            foregroundColor: const Color(0xFF221D10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: primaryColor.withValues(alpha: 0.4),
                          ),
                          child: const Text(
                            'Analyze My Patterns',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Development Maturity Collection
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'How mature are you in your personal development?',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'This helps us tailor your growth journey',
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: List.generate(5, (index) {
                                    final value = index + 1;
                                    final isSelected = _developmentMaturity == value;
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _developmentMaturity = value),
                                        child: Container(
                                          margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? primaryColor 
                                                : Colors.grey.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected 
                                                  ? primaryColor 
                                                  : Colors.grey.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '$value',
                                                style: TextStyle(
                                                  color: isSelected 
                                                      ? const Color(0xFF221D10)
                                                      : textColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _getMaturityLabel(value),
                                                style: TextStyle(
                                                  color: isSelected 
                                                      ? const Color(0xFF221D10)
                                                      : textColor.withValues(alpha: 0.6),
                                                  fontSize: 11,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _applyRecommendedArchetypes,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: const Color(0xFF221D10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: primaryColor.withValues(alpha: 0.4),
                              ),
                              child: const Text(
                                'Use These Calling Types',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _backToFearSelection,
                            child: Text(
                              '<- Back to Fear Selection',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFearCloud() {
    final query = _fearSearchQuery.trim().toLowerCase();
    final visibleFears = query.isEmpty
        ? _allFears
        : _allFears
            .where((fear) =>
                fear.text.toLowerCase().contains(query) ||
                fear.originalText.toLowerCase().contains(query))
            .toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFd8e0d0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Which of these challenges do you still face today?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Be honest with yourself - select patterns that still affect your work and life',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            query.isEmpty
                ? '${_allFears.length} distinct distortion patterns available'
                : 'Showing ${visibleFears.length} of ${_allFears.length} distortion patterns',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fearSearchController,
            onChanged: (value) {
              setState(() {
                _fearSearchQuery = value;
              });
            },
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'Search fears (e.g., pulling away, not wanting to be seen)',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _fearSearchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _fearSearchController.clear();
                        setState(() {
                          _fearSearchQuery = '';
                        });
                      },
                    ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF638B6C).withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF638B6C).withValues(alpha: 0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF638B6C)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleFears.map((fear) {
              final isSelected =
                  _selectedFears.any((sf) => sf.key == fear.key);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _toggleFear(fear),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF4B925).withValues(alpha: 0.2)
                          : const Color(0xFF638B6C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF4B925)
                            : const Color(0xFF638B6C).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      fear.text,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFF4B925)
                            : const Color(0xFF4A6B51),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedArchetypes() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFd8e0d0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Top 2 Work Calling Types',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cinzel',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Based on the challenges you\'ve selected, these are the work calling types that most likely resonate with you:',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ..._suggestedArchetypes.map((archetype) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFf2f5e9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF638B6C)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          archetype.name,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cinzel',
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4B925).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            archetype.identity,
                            style: const TextStyle(
                              color: Color(0xFFF4B925),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      archetype.strengths.split(';')[0].trim(),
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    if (ArchetypeResonances.forArchetype(archetype.name) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Tribe: ${ArchetypeResonances.forArchetype(archetype.name)!.tribe} | Character: ${ArchetypeResonances.forArchetype(archetype.name)!.bibleCharacter}',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<FearItem> _extractFearsFromArchetypes() {
    const allArchetypes = Archetype.allArchetypes;
    final fearMap = <String, FearItem>{};

    for (final archetype in allArchetypes) {
      final distortionGroups = archetype.distortions
          .split(';')
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty);

      for (final group in distortionGroups) {
        final individualFears = group
            .split(',')
            .map((f) => f.trim())
            .where((f) => f.isNotEmpty);

        for (final fear in individualFears) {
          final translatedText = _fearTranslations[fear] ?? fear;
          final key = fear;

          if (!fearMap.containsKey(key)) {
            fearMap[key] = FearItem(
              key: key,
              text: translatedText,
              originalText: fear,
              archetypes: [],
            );
          }

          final fearItem = fearMap[key]!;
          if (!fearItem.archetypes.contains(archetype.name)) {
            fearItem.archetypes.add(archetype.name);
          }
        }
      }
    }

    final fears = fearMap.values.toList();
    final displayCount = <String, int>{};
    for (final fear in fears) {
      displayCount[fear.text] = (displayCount[fear.text] ?? 0) + 1;
    }

    final disambiguated = fears.map((fear) {
      if ((displayCount[fear.text] ?? 0) <= 1) {
        return fear;
      }

      return FearItem(
        key: fear.key,
        text: '${fear.text} (${fear.originalText})',
        originalText: fear.originalText,
        archetypes: fear.archetypes,
      );
    }).toList();

    disambiguated.sort((a, b) => a.text.compareTo(b.text));
    return disambiguated;
  }

  void _toggleFear(FearItem fear) {
    setState(() {
      final existingIndex =
          _selectedFears.indexWhere((sf) => sf.key == fear.key);
      
      if (existingIndex >= 0) {
        _selectedFears.removeAt(existingIndex);
      } else {
        _selectedFears.add(SelectedFear(
          key: fear.key,
          text: fear.text,
          archetypes: fear.archetypes,
        ));
      }
    });
  }

  void _analyzeFears() {
    if (_selectedFears.length < _minimumFearSelections) return;
    
    final suggestedArchetypes = _calculateTopArchetypesFromFears();
    
    setState(() {
      _suggestedArchetypes = suggestedArchetypes;
      _showArchetypes = true;
    });
  }

  List<Archetype> _calculateTopArchetypesFromFears() {
    if (_selectedFears.isEmpty) return [];

    const allArchetypes = Archetype.allArchetypes;
    final archetypeScores = <String, int>{};

    // Calculate scores based on fear-archetype associations
    for (final selectedFear in _selectedFears) {
      for (final archetypeName in selectedFear.archetypes) {
        archetypeScores[archetypeName] = (archetypeScores[archetypeName] ?? 0) + 1;
      }
    }

    // Sort by score and take top 2 for focus
    final sortedEntries = archetypeScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .take(2)
        .map((entry) => allArchetypes.firstWhere((a) => a.name == entry.key))
        .toList();
  }

  void _applyRecommendedArchetypes() {
    ref.read(assessmentProvider.notifier).setArchetypes(_suggestedArchetypes);
    // Store maturity level for results screen
    ref.read(assessmentProvider.notifier).setDevelopmentMaturity(_developmentMaturity);
    context.push('${AppRoutes.assessment}/quick-results');
  }

  String _getMaturityLabel(int value) {
    switch (value) {
      case 1: return 'Just Starting';
      case 2: return 'Exploring';
      case 3: return 'Growing';
      case 4: return 'Maturing';
      case 5: return 'Mature';
      default: return 'Growing';
    }
  }

  void _backToFearSelection() {
    setState(() {
      _suggestedArchetypes = [];
      _showArchetypes = false;
    });
  }
}

class FearItem {
  final String key;
  final String text;
  final String originalText;
  final List<String> archetypes;

  FearItem({
    required this.key,
    required this.text,
    required this.originalText,
    required this.archetypes,
  });
}

class SelectedFear {
  final String key;
  final String text;
  final List<String> archetypes;

  SelectedFear({
    required this.key,
    required this.text,
    required this.archetypes,
  });
}
