import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/time_diagnose_notifier.dart';
import '../../domain/models/time_diagnose_models.dart';

class TimeDiagnoseConfigureScreen extends ConsumerWidget {
  const TimeDiagnoseConfigureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeDiagnoseProvider);
    final notifier = ref.read(timeDiagnoseProvider.notifier);

    final growthGap = state.targetGrowth.minutes - state.currentGrowth.minutes;
    final growthGapPercent = (growthGap / (24 * 60) * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7), // parchment
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ELBIBLIO SPIRITUAL OS',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                          color: Colors.black38,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Growth Depth',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF333D29), // earth-charcoal
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.psychology, color: Colors.black38),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Identify your current spiritual investment, then set your intention. Mind the gap between where you are and where you wish to be.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC89F81).withValues(alpha:0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: Color(0xFFC89F81),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'CURRENT SPIRITUAL GROWTH',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: Colors.black38,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: SpiritualGrowthLevel.values.length,
                      itemBuilder: (context, index) {
                        final level = SpiritualGrowthLevel.values[index];
                        final isSelected = state.currentGrowth == level;
                        
                        return _GrowthOptionCard(
                          level: level,
                          isSelected: isSelected,
                          onTap: () => notifier.setCurrentGrowth(level),
                          selectedColor: const Color(0xFFC89F81),
                          icon: Icons.check,
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    const Center(
                      child: Icon(Icons.arrow_downward, color: Colors.black12),
                    ),
                    const SizedBox(height: 32),
                    
                    // Section 2
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA4AC86).withValues(alpha:0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '2',
                              style: TextStyle(
                                color: Color(0xFFA4AC86),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'WHERE WOULD YOU LIKE TO BE?',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: Colors.black38,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: SpiritualGrowthLevel.values.length,
                      itemBuilder: (context, index) {
                        final level = SpiritualGrowthLevel.values[index];
                        final isSelected = state.targetGrowth == level;
                        final isDisabled = level.minutes <= state.currentGrowth.minutes;
                        
                        return _GrowthOptionCard(
                          level: level,
                          isSelected: isSelected,
                          isDisabled: isDisabled,
                          onTap: isDisabled ? null : () => notifier.setTargetGrowth(level),
                          selectedColor: const Color(0xFFA4AC86),
                          icon: Icons.star,
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Bottom Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFCF7).withValues(alpha:0.95),
                border: Border(
                  top: BorderSide(color: Colors.black.withValues(alpha:0.06)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GROWTH GAP',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Colors.black38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            growthGap > 0 ? '+${growthGap}m' : '0m',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFFA4AC86), // earth-olive
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2.0),
                            child: Text(
                              '($growthGapPercent%)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: growthGap > 0 
                      ? () => context.push('/time-diagnose/analysis') 
                      : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF333D29), // earth-charcoal
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ANALYZE',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthOptionCard extends StatelessWidget {
  final SpiritualGrowthLevel level;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;
  final Color selectedColor;
  final IconData icon;

  const _GrowthOptionCard({
    required this.level,
    required this.isSelected,
    this.isDisabled = false,
    required this.onTap,
    required this.selectedColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (level.minutes / (24 * 60) * 100).toStringAsFixed(0);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
            ? selectedColor.withValues(alpha:0.1) 
            : Colors.white.withValues(alpha:0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? selectedColor 
              : Colors.black.withValues(alpha:0.06),
          ),
        ),
        foregroundDecoration: isDisabled ? BoxDecoration(
          color: Colors.white.withValues(alpha:0.6),
          borderRadius: BorderRadius.circular(12),
        ) : null,
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(icon, color: selectedColor.withValues(alpha:0.5), size: 14),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        percent,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF333D29),
                        ),
                      ),
                      const Text(
                        '%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
