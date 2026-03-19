import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../domain/models/archetype.dart';
import 'widgets/interactive_compass_wheel.dart';
import '../application/assessment_notifier.dart';

class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key});

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen>
    with TickerProviderStateMixin {
  List<Archetype> selectedArchetypes = [];
  Archetype? currentArchetype;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  int _currentStep = 1;
  final int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Custom colors based on the design
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
          'Kingdom Archetypes Compass',
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
            icon: Icon(Icons.psychology_rounded, color: textColor),
            onPressed: () => context.push(AppRoutes.assessment),
            tooltip: 'Try Fear-Based Assessment',
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: textColor),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Kingdom Archetypes Compass'),
                  content: const Text(
                    'The Kingdom Archetypes Compass helps identify your spiritual calling based on your strengths and potential distortions. Select up to 3 archetypes that resonate with you to discover your unique spiritual gifts.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Progress Steps
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: List.generate(_totalSteps, (index) {
                  final stepNumber = index + 1;
                  final isCompleted = stepNumber < _currentStep;
                  final isCurrent = stepNumber == _currentStep;
                  
                  return Expanded(
                    child: Row(
                      children: [
                        // Step circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? primaryColor
                                : isCurrent
                                    ? primaryColor.withValues(alpha: 0.8)
                                    : primaryColor.withValues(alpha: 0.2),
                            border: Border.all(
                              color: isCurrent ? primaryColor : primaryColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : Text(
                                    '$stepNumber',
                                    style: TextStyle(
                                      color: isCurrent ? const Color(0xFF221D10) : primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                        // Connector line
                        if (index < _totalSteps - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              color: isCompleted
                                  ? primaryColor
                                  : primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            
            // Enhanced Step Title with Presence UX
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withValues(alpha: 0.12),
                      primaryColor.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Step indicator with presence
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        Text(
                          'STEP $_currentStep OF $_totalSteps',
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getStepTitle(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getStepDescription(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.85),
                        fontSize: 15,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            // Enhanced Selection Counter with Presence UX
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: selectedArchetypes.isEmpty
                      ? [
                          Colors.grey.withValues(alpha: 0.1),
                          Colors.grey.withValues(alpha: 0.05),
                        ]
                      : [
                          primaryColor.withValues(alpha: 0.15),
                          primaryColor.withValues(alpha: 0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedArchetypes.isEmpty
                      ? Colors.grey.withValues(alpha: 0.3)
                      : primaryColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: selectedArchetypes.isEmpty
                    ? null
                    : [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      selectedArchetypes.isEmpty 
                          ? Icons.radio_button_unchecked_rounded
                          : Icons.check_circle_rounded,
                      key: ValueKey(selectedArchetypes.isEmpty),
                      size: 22,
                      color: selectedArchetypes.isEmpty ? Colors.grey : primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        selectedArchetypes.isEmpty 
                            ? 'Select Archetypes to Begin'
                            : 'Archetypes Selected',
                        style: TextStyle(
                          color: selectedArchetypes.isEmpty ? Colors.grey : primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${selectedArchetypes.length}/3',
                        style: TextStyle(
                          color: selectedArchetypes.isEmpty ? Colors.grey : primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main content area with wheel and info
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Interactive Compass Wheel with pulse animation
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: selectedArchetypes.isEmpty ? _pulseAnimation.value : 1.0,
                          child: SizedBox(
                            height: 350,
                            child: Center(
                              child: InteractiveCompassWheel(
                                onArchetypeSelected: _handleArchetypeSelected,
                                selectedArchetypes: selectedArchetypes,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Current Archetype Info with slide-in animation
                    if (currentArchetype != null)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? primaryColor.withValues(alpha: 0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.psychology,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentArchetype!.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '(${currentArchetype!.identity})',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: textColor.withValues(alpha: 0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoSection(
                              context,
                              'Spiritual Strengths',
                              currentArchetype!.strengths,
                              Icons.star,
                              textColor,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoSection(
                              context,
                              'Worldly Distortions',
                              currentArchetype!.distortions,
                              Icons.warning,
                              textColor,
                            ),
                          ],
                        ),
                      ),

                    // Selected Archetypes with improved chips
                    if (selectedArchetypes.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? primaryColor.withValues(alpha: 0.03)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Selections:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: selectedArchetypes.asMap().entries.map((entry) {
                                final index = entry.key;
                                final archetype = entry.value;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  child: Chip(
                                    avatar: CircleAvatar(
                                      backgroundColor: primaryColor,
                                      radius: 12,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Color(0xFF221D10),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    label: Text(archetype.name),
                                    backgroundColor:
                                        primaryColor.withValues(alpha: 0.1),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: primaryColor,
                                    ),
                                    onDeleted: () => _removeArchetype(archetype),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                    // Bottom padding for scroll
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Action (fixed at bottom)
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
                  onPressed: selectedArchetypes.isNotEmpty
                      ? () {
                          // Save archetypes to state
                          ref
                              .read(assessmentProvider.notifier)
                              .setArchetypes(selectedArchetypes);
                          // Navigate directly to rating screen (age no longer required)
                          context.push('${AppRoutes.assessment}/rating');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: const Color(0xFF221D10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    selectedArchetypes.isEmpty
                        ? 'Select Archetypes to Continue'
                        : 'Continue to Assessment',
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

  void _handleArchetypeSelected(Archetype archetype) {
    setState(() {
      currentArchetype = archetype;

      final newSelected = List<Archetype>.from(selectedArchetypes);
      if (newSelected.contains(archetype)) {
        newSelected.remove(archetype);
        _showFeedback('Archetype removed', false);
      } else if (newSelected.length < 3) {
        newSelected.add(archetype);
        _showFeedback('Archetype selected!', true);
        
        // Auto-advance to next step if 3 selected
        if (newSelected.length == 3) {
          _currentStep = 2;
        }
      } else {
        _showFeedback('Maximum 3 archetypes', false);
      }
      selectedArchetypes = newSelected;
    });
  }
  
  void _showFeedback(String message, bool isSuccess) {
    const primaryColor = Color(0xFFF4B925);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: isSuccess ? primaryColor : Colors.grey,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Discover Your Spiritual Archetypes';
      case 2:
        return 'Review Your Selections';
      case 3:
        return 'Complete Your Assessment';
      default:
        return 'Spiritual Assessment';
    }
  }
  
  String _getStepDescription() {
    switch (_currentStep) {
      case 1:
        return 'Select up to 3 archetypes that resonate with your spiritual calling';
      case 2:
        return 'Review your chosen archetypes before proceeding';
      case 3:
        return 'Receive your personalized spiritual profile';
      default:
        return 'Complete your spiritual assessment';
    }
  }
  
  Widget _buildInfoSection(BuildContext context, String title, String content, IconData icon, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: icon == Icons.star
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: icon == Icons.star
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: icon == Icons.star ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _removeArchetype(Archetype archetype) {
    setState(() {
      final newSelected = List<Archetype>.from(selectedArchetypes);
      newSelected.remove(archetype);
      selectedArchetypes = newSelected;

      if (currentArchetype == archetype) {
        currentArchetype = null;
      }
    });
  }
}
