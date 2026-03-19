import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../application/assessment_notifier.dart';

class AssessmentPathScreen extends ConsumerStatefulWidget {
  const AssessmentPathScreen({super.key});

  @override
  ConsumerState<AssessmentPathScreen> createState() =>
      _AssessmentPathScreenState();
}

class _AssessmentPathScreenState extends ConsumerState<AssessmentPathScreen> {
  String? _selectedPath;

  void _onContinue() {
    if (_selectedPath == null) return;
    ref.read(assessmentProvider.notifier).setPath(_selectedPath!);
    context.push('${AppRoutes.assessment}/action-plan');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFF4B925);
    final bgColor = isDark ? const Color(0xFF221D10) : const Color(0xFFF8F7F5);
    final textColor = isDark ? Colors.white : Colors.black87;

    final recommendedPath =
        ref.read(assessmentProvider.notifier).getRecommendedPath();
    final avgMaturity =
        ref.read(assessmentProvider.notifier).getAverageMaturity();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'CHOOSE YOUR PATH',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'How would you like to proceed?',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cinzel',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Based on your assessment, choose how you\'d like to proceed with your spiritual career journey.',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _PathOptionCard(
                      title: 'Develop Talent',
                      description:
                          'Create a personalized plan to develop your talent',
                      icon: '📈',
                      isSelected: _selectedPath == 'development',
                      onTap: () =>
                          setState(() => _selectedPath = 'development'),
                      primaryColor: primaryColor,
                      isDark: isDark,
                      textColor: textColor,
                      isRecommended: recommendedPath == 'development',
                      recommendationReason: avgMaturity < 50
                          ? 'Focus on developing your talents first'
                          : 'You\'re ready to apply your talents',
                    ),
                    const SizedBox(height: 16),
                    _PathOptionCard(
                      title: 'Immediate Engagement',
                      description:
                          'If you\'re currently ready to jump into serving now',
                      icon: '🚀',
                      isSelected: _selectedPath == 'engagement',
                      onTap: () => setState(() => _selectedPath = 'engagement'),
                      primaryColor: primaryColor,
                      isDark: isDark,
                      textColor: textColor,
                      isRecommended: recommendedPath == 'engagement',
                      recommendationReason: avgMaturity < 50
                          ? 'Focus on developing your talents first'
                          : 'You\'re ready to apply your talents',
                    ),
                    const SizedBox(height: 16),
                    _PathOptionCard(
                      title: 'Recalibrate Current Life',
                      description:
                          'If you\'re already engaged and need to recalibrate',
                      icon: '🔄',
                      isSelected: _selectedPath == 'recalibration',
                      onTap: () =>
                          setState(() => _selectedPath = 'recalibration'),
                      primaryColor: primaryColor,
                      isDark: isDark,
                      textColor: textColor,
                      isRecommended: recommendedPath == 'recalibration',
                      recommendationReason: avgMaturity < 50
                          ? 'Focus on developing your talents first'
                          : 'You\'re ready to apply your talents',
                    ),
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
                  onPressed: _selectedPath != null ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: const Color(0xFF221D10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue to Results →',
                    style: TextStyle(
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
}

class _PathOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;
  final Color textColor;
  final bool isRecommended;
  final String? recommendationReason;

  const _PathOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
    required this.isDark,
    required this.textColor,
    this.isRecommended = false,
    this.recommendationReason,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : (isDark ? Colors.grey[900] : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? primaryColor : primaryColor.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                if (isRecommended && recommendationReason != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.stars, size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recommendationReason!,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (isRecommended)
              Positioned(
                top: -36,
                right: -12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Color(0xFF221D10)),
                      SizedBox(width: 4),
                      Text(
                        'RECOMMENDED',
                        style: TextStyle(
                          color: Color(0xFF221D10),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
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
}
