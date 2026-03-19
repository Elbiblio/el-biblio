import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/archetype.dart';
import '../../domain/models/archetype_resonance.dart';

/// The viral card — designed to be screenshot and shared on social media.
/// Framed as "Work Calling Type" for universal appeal while keeping spiritual depth.
/// Wrap with a [RepaintBoundary] (key: shareableCardKey) in the parent
/// to capture it as an image for sharing.
class ShareableArchetypeCard extends StatelessWidget {
  final List<Archetype> archetypes;
  final int averageMaturity;

  const ShareableArchetypeCard({
    super.key,
    required this.archetypes,
    required this.averageMaturity,
  });

  /// Universal framing - "Work Calling Type" instead of "Kingdom Archetypes"
  static String getCombinedTitle(List<Archetype> archetypes) {
    if (archetypes.isEmpty) return 'Work Calling Explorer';
    if (archetypes.length == 1) return archetypes[0].identity;

    const modifiers = {
      'Artisan': 'Creative',
      'Watchman': 'Vigilant',
      'Cultivator': 'Growing',
      'Sower': 'Pioneering',
      'Welcomer': 'Connecting',
      'Pillar': 'Grounding',
      'Sentinel': 'Protecting',
      'Bridgebuilder': 'Unifying',
      'Healer': 'Restoring',
      'Harvester': 'Gathering',
      'Reformer': 'Transforming',
      'Architect': 'Building',
    };

    final primary = archetypes[0].identity;
    final secondary = archetypes[1].name;
    final modifier = modifiers[secondary] ?? 'Integrated';
    return '$modifier $primary';
  }

  /// Universal calling statements - work-focused with spiritual depth
  static String getCallingStatement(List<Archetype> archetypes) {
    if (archetypes.isEmpty) return 'Your work calling awaits discovery.';
    const statements = {
      'Artisan': 'Turn chaos into meaning people can feel.',
      'Watchman': 'See what others miss, and sound the alarm in time.',
      'Cultivator': 'Grow people and systems until they bear real fruit.',
      'Sower': 'Start what matters before certainty arrives.',
      'Welcomer': 'Make room for people to become their bravest selves.',
      'Pillar': 'Hold the weight so others can rise with confidence.',
      'Sentinel': 'Protect what is sacred when pressure says compromise.',
      'Bridgebuilder': 'Unite divided people to unlock impossible outcomes.',
      'Healer': 'Restore what pain tried to permanently break.',
      'Harvester': 'Turn effort into momentum, then momentum into legacy.',
      'Reformer': 'Confront what is broken and rebuild it with courage.',
      'Architect': 'Design structures that outlive your own effort.',
    };
    return statements[archetypes[0].name] ?? 'Walk faithfully in your work calling.';
  }

  static String getShadowWarning(List<Archetype> archetypes) {
    if (archetypes.isEmpty) return 'Unowned fear will sabotage your calling.';

    final candidates = archetypes.first.distortions
        .split(RegExp(r'[;,]'))
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toList();

    if (candidates.isEmpty) {
      return 'Unowned fear will sabotage your calling.';
    }

    final shadow = candidates.first;
    return 'Shadow to watch: $shadow';
  }

  static String getSymbolicResonance(List<Archetype> archetypes) {
    if (archetypes.isEmpty) return '';
    
    if (archetypes.length == 2) {
      // Use gamified dual combination for 2 archetypes
      final dualCharacter = ArchetypeResonances.getDualCombination(
        archetypes.first.name, 
        archetypes.last.name
      );
      if (dualCharacter != null) {
        final primaryResonance = ArchetypeResonances.forArchetype(archetypes.first.name);
        final tribe = primaryResonance?.tribe ?? 'Unknown Tribe';
        return 'Your Biblical Archetype: $dualCharacter • Tribe: $tribe';
      }
    }
    
    // Fallback to single archetype
    final resonance = ArchetypeResonances.forArchetype(archetypes.first.name);
    if (resonance == null) return '';
    return 'Symbolic resonance: ${resonance.tribe} - ${resonance.bibleCharacter}';
  }

  /// Maturity label shown on the card.
  static String getMaturityLabel(int maturity) {
    if (maturity < 20) return 'Emerging';
    if (maturity < 40) return 'Developing';
    if (maturity < 60) return 'Established';
    if (maturity < 80) return 'Maturing';
    return 'Seasoned';
  }

  @override
  Widget build(BuildContext context) {
    final title = getCombinedTitle(archetypes);
    final callingStatement = getCallingStatement(archetypes);
    final shadowWarning = getShadowWarning(archetypes);
    final symbolicResonance = getSymbolicResonance(archetypes);
    final maturityLabel = getMaturityLabel(averageMaturity);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F0E0F), // Darker, more premium
            Color(0xFF1A1618),
            Color(0xFF2D1B1B), // Warm accent
          ],
        ),
        border: Border.all(
          color: const Color(0xFFF4B925).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF4B925).withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Large compass/mandala background for visual appeal
            const Positioned(
              top: -80,
              right: -80,
              child: _ViralCompassDecoration(size: 280),
            ),
            
            // Subtle grid pattern for texture
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Universal header - "Work Calling Type"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4B925).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFF4B925).withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'WORK CALLING TYPE',
                          style: TextStyle(
                            color: Color(0xFFF4B925),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          'ELBIBLIO',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Archetype badges - more prominent
                  _ViralArchetypeBadges(archetypes: archetypes),

                  const SizedBox(height: 28),

                  // Main title - bigger, more dramatic
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cinzel',
                      height: 1.1,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Calling statement - more prominent
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4B925).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFF4B925).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '"$callingStatement"',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    shadowWarning,
                    style: TextStyle(
                      color: const Color(0xFFD4956A).withValues(alpha: 0.95),
                      fontSize: 12,
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (symbolicResonance.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      symbolicResonance,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 11,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Tension/contrast element
                  _TensionIndicator(
                    maturity: averageMaturity,
                    label: maturityLabel,
                  ),

                  const SizedBox(height: 24),

                  // Footer - more prominent call to action
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Take the 3-minute assessment',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'elbiblio.com/compass',
                          style: TextStyle(
                            color: Color(0xFFF4B925),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
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

class _ViralArchetypeBadges extends StatelessWidget {
  final List<Archetype> archetypes;

  const _ViralArchetypeBadges({required this.archetypes});

  static const List<Color> _badgeColors = [
    Color(0xFFF4B925),
    Color(0xFFD4956A),
    Color(0xFFA4AC86),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(archetypes.length, (i) {
        final archetype = archetypes[i];
        final color = _badgeColors[i % _badgeColors.length];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                archetype.name,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TensionIndicator extends StatelessWidget {
  final int maturity;
  final String label;

  const _TensionIndicator({
    required this.maturity,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CALLING MATURITY',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFF4B925),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: maturity / 100.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF4B925), Color(0xFFD4956A)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$maturity% Developed',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViralCompassDecoration extends StatelessWidget {
  final double size;

  const _ViralCompassDecoration({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ViralCompassPainter(),
    );
  }
}

class _ViralCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFF4B925).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw multiple concentric circles for mandala effect
    for (int i = 1; i <= 4; i++) {
      final radius = (size.width / 2) * (i / 4);
      canvas.drawCircle(center, radius, paint);
    }

    // Draw radial lines
    final linePaint = Paint()
      ..color = const Color(0xFFF4B925).withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (math.pi / 180);
      final start = center;
      final end = Offset(
        center.dx + math.cos(angle) * size.width / 2,
        center.dy + math.sin(angle) * size.height / 2,
      );
      canvas.drawLine(start, end, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
