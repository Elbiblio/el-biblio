import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../application/time_diagnose_notifier.dart';
import '../../domain/models/time_diagnose_models.dart';

class TimeDiagnoseStartScreen extends ConsumerWidget {
  const TimeDiagnoseStartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeDiagnoseProvider);
    final notifier = ref.read(timeDiagnoseProvider.notifier);
    
    final totalMinutes = state.totalMinutes;
    final is24Hours = state.isValid24Hours;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7), // parchment
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                        'Time Audit',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF333D29), // earth-charcoal
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.black38),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Allocate your 24 hours across the seven essential pillars of a balanced spiritual life.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Donut Chart
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    allocations: state.allocations,
                    totalMinutes: totalMinutes,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'BALANCE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: Colors.black38,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${(totalMinutes / (24 * 60) * 100).clamp(0, 100).round()}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF333D29),
                              ),
                            ),
                            const Text(
                              '%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Allocation List
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'ADJUST ALLOCATIONS',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                      itemCount: TimePillar.values.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final pillar = TimePillar.values[index];
                        final minutes = state.allocations[pillar] ?? 0;
                        
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black.withValues(alpha:0.06)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: pillar.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pillar.label,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      pillar.description,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 20),
                                    onPressed: minutes > 0 
                                      ? () => notifier.decrementAllocation(pillar) 
                                      : null,
                                    color: Colors.black38,
                                    splashRadius: 20,
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    onPressed: () => notifier.incrementAllocation(pillar),
                                    color: Colors.black38,
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
                        'TOTAL COUNT',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Colors.black38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalMinutes ~/ 60}h ${(totalMinutes % 60).toString().padLeft(2, '0')}m',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: is24Hours ? const Color(0xFF333D29) : Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: is24Hours 
                      ? () => context.push('/time-diagnose/configure') 
                      : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A8471), // sage-green
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'DIAGNOSE',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
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

class _DonutChartPainter extends CustomPainter {
  final Map<TimePillar, int> allocations;
  final int totalMinutes;

  _DonutChartPainter({
    required this.allocations,
    required this.totalMinutes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    final innerRadius = radius * 0.65;
    final strokeWidth = radius - innerRadius;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    double startAngle = -math.pi / 2; // Start from top
    
    // Total reference is 24 hours, but we draw based on actual total if > 0
    final drawTotal = totalMinutes > 0 ? math.max(totalMinutes, 24 * 60) : 24 * 60;

    for (final pillar in TimePillar.values) {
      final minutes = allocations[pillar] ?? 0;
      if (minutes == 0) continue;

      final sweepAngle = (minutes / drawTotal) * 2 * math.pi;
      paint.color = pillar.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw remaining empty space if less than 24 hours
    if (totalMinutes < 24 * 60) {
      final remainingSweep = ((24 * 60 - totalMinutes) / (24 * 60)) * 2 * math.pi;
      paint.color = Colors.black.withValues(alpha:0.05);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        remainingSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.totalMinutes != totalMinutes ||
           oldDelegate.allocations != allocations;
  }
}
