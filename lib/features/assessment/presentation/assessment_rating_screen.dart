import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../application/assessment_notifier.dart';

class AssessmentRatingScreen extends ConsumerStatefulWidget {
  const AssessmentRatingScreen({super.key});

  @override
  ConsumerState<AssessmentRatingScreen> createState() =>
      _AssessmentRatingScreenState();
}

class _AssessmentRatingScreenState
    extends ConsumerState<AssessmentRatingScreen> {
  int _currentIndex = 0;
  final Map<String, int> _instances = {};
  final Map<String, String> _fears = {};

  final List<Map<String, dynamic>> _instanceOptions = [
    {'value': 0, 'label': 'Never — not yet'},
    {'value': 3, 'label': 'A few times (1–5)'},
    {'value': 10, 'label': 'Several times (6–15)'},
    {'value': 23, 'label': 'Many times (16–30)'},
    {'value': 40, 'label': 'Very often (31–50)'},
    {'value': 60, 'label': 'Consistently (51–75)'},
    {'value': 90, 'label': 'Regularly (76–100)'},
    {'value': 120, 'label': 'Frequently (100+)'},
  ];

  final List<Map<String, String>> _fearOptions = [
    {'value': 'none', 'label': 'Not yet — still discovering'},
    {'value': 'some', 'label': 'Somewhat — aware of them'},
    {'value': 'many', 'label': 'Many times — actively wrestling'},
    {'value': 'overcome', 'label': "Overcome — they no longer control me"},
  ];

  void _onNext() {
    final state = ref.read(assessmentProvider);
    final archetypes = state.selectedArchetypes;

    if (archetypes.isEmpty) return;

    final currentArchetype = archetypes[_currentIndex];
    final instances = _instances[currentArchetype.name];
    final fears = _fears[currentArchetype.name];

    if (instances == null || fears == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer both questions to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref
        .read(assessmentProvider.notifier)
        .saveArchetypeAssessment(currentArchetype.name, instances, fears);

    if (_currentIndex < archetypes.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      context.push('${AppRoutes.assessment}/path');
    }
  }

  void _onPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFF4B925);
    final bgColor = isDark ? const Color(0xFF221D10) : const Color(0xFFF8F7F5);
    final textColor = isDark ? Colors.white : Colors.black87;

    final state = ref.watch(assessmentProvider);
    final archetypes = state.selectedArchetypes;

    if (archetypes.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentArchetype = archetypes[_currentIndex];

    final strengthsList = currentArchetype.strengths
        .split(';')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final distortionsList = currentArchetype.distortions
        .split(';')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final strengthsPreview = strengthsList.take(3).join(', ');
    final distortionsPreview = distortionsList.take(3).join(', ');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: _onPrevious,
        ),
        title: Text(
          'Archetype ${_currentIndex + 1} of ${archetypes.length}',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        // Progress indicator
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / archetypes.length,
            backgroundColor: primaryColor.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? primaryColor.withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentArchetype.name,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cinzel',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentArchetype.identity,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Enhanced Context Card with Presence UX
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor.withValues(alpha: 0.08),
                            primaryColor.withValues(alpha: 0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Presence indicator
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'TAKE A MOMENT TO REFLECT',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Archetype-specific context
                          Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.85),
                                fontSize: 15,
                                height: 1.6,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'As a ',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                TextSpan(
                                  text: currentArchetype.name.toLowerCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                TextSpan(
                                  text: ' (${currentArchetype.identity.toLowerCase()}), ${_getArchetypeSpecificContext(currentArchetype.name)}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Gentle guidance
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 16,
                                  color: primaryColor.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'There\'s no right or wrong answer. Be honest with where you are now.',
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.6),
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Enhanced Question 1: Strengths with Visual Hierarchy
                    _buildQuestionSection(
                      context,
                      questionNumber: 1,
                      icon: Icons.star_rounded,
                      iconColor: Colors.green,
                      title: 'Your Experience',
                      subtitle: _getArchetypeSpecificStrengthQuestion(currentArchetype.name, strengthsPreview),
                      child: _buildEnhancedDropdown(
                        context,
                        value: _instances[currentArchetype.name],
                        hint: 'Select your experience level...',
                        options: _instanceOptions,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _instances[currentArchetype.name] = value;
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Enhanced Question 2: Challenges with Visual Hierarchy
                    _buildQuestionSection(
                      context,
                      questionNumber: 2,
                      icon: Icons.psychology_rounded,
                      iconColor: Colors.deepOrange,
                      title: 'Your Awareness',
                      subtitle: _getArchetypeSpecificChallengeQuestion(currentArchetype.name, distortionsPreview),
                      child: _buildEnhancedDropdown(
                        context,
                        value: _fears[currentArchetype.name],
                        hint: 'Select your awareness level...',
                        options: _fearOptions,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _fears[currentArchetype.name] = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom Action
            Container(
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _instances[currentArchetype.name] != null &&
                          _fears[currentArchetype.name] != null
                      ? _onNext
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: const Color(0xFF221D10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentIndex == archetypes.length - 1
                        ? 'Complete Assessment →'
                        : 'Next Archetype →',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for enhanced UI
  
  String _getArchetypeSpecificContext(String archetypeName) {
    switch (archetypeName) {
      case 'Artisan':
        return 'you bring beauty and creativity that reflects God\'s nature into the world.';
      case 'Watchman':
        return 'you guard and protect others through spiritual discernment and alertness.';
      case 'Cultivator':
        return 'you nurture and develop potential in others through long-term investment.';
      case 'Sower':
        return 'you initiate new beginnings and inspire faith in unseen outcomes.';
      case 'Welcomer':
        return 'you create warm atmospheres where others feel valued and welcomed.';
      case 'Pillar':
        return 'you provide steady support and reliability to those around you.';
      case 'Sentinel':
        return 'you observe and pray with spiritual sensitivity in hidden places.';
      case 'Bridgebuilder':
        return 'you connect and unify diverse groups through empathy and peace.';
      case 'Healer':
        return 'you bring restoration and comfort to those who are hurting.';
      case 'Harvester':
        return 'you gather and celebrate the fruits of labor with joy and effectiveness.';
      case 'Reformer':
        return 'you courageously confront injustice and vision for transformation.';
      case 'Architect':
        return 'you build lasting systems and structures that multiply impact.';
      default:
        return 'you fulfill a unique calling in God\'s kingdom.';
    }
  }

  String _getArchetypeSpecificStrengthQuestion(String archetypeName, String strengthsPreview) {
    switch (archetypeName) {
      case 'Artisan':
        return 'How many times have you expressed ${strengthsPreview.isNotEmpty ? strengthsPreview : 'creative beauty'} that inspired others?';
      case 'Watchman':
        return 'How many times have you demonstrated ${strengthsPreview.isNotEmpty ? strengthsPreview : 'protective discernment'} for others\' safety?';
      case 'Cultivator':
        return 'How many times have you nurtured ${strengthsPreview.isNotEmpty ? strengthsPreview : 'hidden potential'} in someone\'s life?';
      case 'Sower':
        return 'How many times have you initiated ${strengthsPreview.isNotEmpty ? strengthsPreview : 'new beginnings'} with faith?';
      case 'Welcomer':
        return 'How many times have you created ${strengthsPreview.isNotEmpty ? strengthsPreview : 'welcoming atmospheres'} for others?';
      case 'Pillar':
        return 'How many times have you provided ${strengthsPreview.isNotEmpty ? strengthsPreview : 'steady support'} to others?';
      case 'Sentinel':
        return 'How many times have you prayed with ${strengthsPreview.isNotEmpty ? strengthsPreview : 'spiritual sensitivity'} for others?';
      case 'Bridgebuilder':
        return 'How many times have you brought ${strengthsPreview.isNotEmpty ? strengthsPreview : 'unity and peace'} to divided situations?';
      case 'Healer':
        return 'How many times have you offered ${strengthsPreview.isNotEmpty ? strengthsPreview : 'restorative presence'} to hurting people?';
      case 'Harvester':
        return 'How many times have you celebrated ${strengthsPreview.isNotEmpty ? strengthsPreview : 'meaningful results'} with others?';
      case 'Reformer':
        return 'How many times have you stood for ${strengthsPreview.isNotEmpty ? strengthsPreview : 'justice and transformation'}?';
      case 'Architect':
        return 'How many times have you built ${strengthsPreview.isNotEmpty ? strengthsPreview : 'lasting structures'} that serve others?';
      default:
        return 'How many times have you expressed ${strengthsPreview.isNotEmpty ? strengthsPreview : 'your unique gifts'}?';
    }
  }

  String _getArchetypeSpecificChallengeQuestion(String archetypeName, String distortionsPreview) {
    return 'How familiar are you with the challenges of ${distortionsPreview.isNotEmpty ? distortionsPreview : 'this calling'}?';
  }

  Widget _buildQuestionSection(
    BuildContext context, {
    required int questionNumber,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header with enhanced hierarchy
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.1),
                  iconColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Question $questionNumber',
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: iconColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Question subtitle with presence UX
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              subtitle,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Enhanced dropdown container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDropdown<T>(
    BuildContext context, {
    required T? value,
    required String hint,
    required List<Map<String, dynamic>> options,
    required ValueChanged<T?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    const primaryColor = Color(0xFFF4B925);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: textColor.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Text(
                hint,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          dropdownColor: isDark ? const Color(0xFF221D10) : Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryColor,
            size: 24,
          ),
          items: options.map((option) {
            return DropdownMenuItem<T>(
              value: option['value'] as T,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _getOptionIcon(option['value']),
                      size: 16,
                      color: primaryColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option['label'] as String,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  IconData _getOptionIcon(dynamic value) {
    if (value is int) {
      if (value == 0) return Icons.radio_button_unchecked;
      if (value <= 10) return Icons.trending_up;
      if (value <= 40) return Icons.show_chart;
      return Icons.trending_up;
    } else if (value is String) {
      switch (value) {
        case 'none': return Icons.explore;
        case 'some': return Icons.visibility;
        case 'many': return Icons.psychology;
        case 'overcome': return Icons.verified;
        default: return Icons.help_outline;
      }
    }
    return Icons.help_outline;
  }
}
