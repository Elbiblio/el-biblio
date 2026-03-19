import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/constants/app_routes.dart';
import '../application/assessment_notifier.dart';
import '../domain/models/archetype_resonance.dart';
import 'widgets/shareable_archetype_card.dart';
import '../../time_diagnose/application/time_diagnose_notifier.dart';
import '../../time_diagnose/domain/models/time_diagnose_models.dart';

class AssessmentResultsScreen extends ConsumerStatefulWidget {
  const AssessmentResultsScreen({super.key});

  @override
  ConsumerState<AssessmentResultsScreen> createState() =>
      _AssessmentResultsScreenState();
}

class _AssessmentResultsScreenState
    extends ConsumerState<AssessmentResultsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _shareableCardKey = GlobalKey();
  bool _isSharing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _shareCard() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      // Capture the card as an image
      final boundary = _shareableCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        _shareText();
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _shareText();
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/work_calling_type.png');
      await file.writeAsBytes(bytes);

      final state = ref.read(assessmentProvider);
      final title =
          ShareableArchetypeCard.getCombinedTitle(state.selectedArchetypes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Work Calling Type: $title\nI took the 3-minute fear-to-calling assessment on ElBiblio.\nTake it: https://elbiblio.com/compass',
      );
    } catch (e) {
      _shareText();
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _shareText() {
    final state = ref.read(assessmentProvider);
    final title =
        ShareableArchetypeCard.getCombinedTitle(state.selectedArchetypes);
    final archetypeNames =
        state.selectedArchetypes.map((a) => a.name).join(' + ');

    Share.share(
      'Work Calling Type: $title\nSignature blend: $archetypeNames\nI took the 3-minute fear-to-calling assessment on ElBiblio.\nTake it: https://elbiblio.com/compass',
    );
  }

  void _inviteSomeone() {
    Share.share(
      'Name your work calling before your fears name it for you.\nI just took ElBiblio''s 3-minute assessment and got my result.\nTake it: https://elbiblio.com/compass',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFF4B925);
    final bgColor = isDark ? const Color(0xFF221D10) : const Color(0xFFF8F7F5);
    final textColor = isDark ? Colors.white : Colors.black87;

    final state = ref.watch(assessmentProvider);
    final archetypes = state.selectedArchetypes;
    final avgMaturity = ref.read(assessmentProvider.notifier).getAverageMaturity();

    if (archetypes.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No archetypes selected'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppRoutes.assessment),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    final combinedTitle =
        ShareableArchetypeCard.getCombinedTitle(archetypes);
    final primaryResonance = archetypes.isNotEmpty
        ? ArchetypeResonances.forArchetype(archetypes.first.name)
        : null;

    // Aggregate strengths + distortions from all selected archetypes
    final allStrengths = archetypes
        .expand((a) =>
            a.strengths.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty))
        .take(4)
        .toList();

    final allDistortions = archetypes
        .expand((a) =>
            a.distortions.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty))
        .take(3)
        .toList();

    // ── Time-calling gap from TimeDiagnose ────────────────────────
    final timeDiagnoseState = ref.watch(timeDiagnoseProvider);
    const totalMinutes = 16 * 60; // waking hours
    final spiritMinutes = timeDiagnoseState.allocations[TimePillar.spirit] ?? 0;
    final vocationMinutes = timeDiagnoseState.allocations[TimePillar.vocation] ?? 0;
    final spiritPercent = (spiritMinutes / totalMinutes * 100).round();
    final vocationPercent = (vocationMinutes / totalMinutes * 100).round();
    final bool showCallingGap = spiritMinutes < 60; // less than 1h/day
    //
    // Replace the hardcoded _CallingGapCard below with dynamic values when enabled.

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Label ──────────────────────────────────────────────
                  const Text(
                    'YOUR WORK CALLING TYPE',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    combinedTitle,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cinzel',
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (primaryResonance != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Symbolic resonance: ${primaryResonance.tribe} • ${primaryResonance.bibleCharacter}',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── THE VIRAL CARD (captured for sharing) ──────────────
                  RepaintBoundary(
                    key: _shareableCardKey,
                    child: ShareableArchetypeCard(
                      archetypes: archetypes,
                      averageMaturity: avgMaturity,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Share button (primary CTA) ─────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSharing ? null : _shareCard,
                      icon: _isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF221D10)),
                            )
                          : const Icon(Icons.ios_share_rounded, size: 18),
                      label: Text(
                        _isSharing ? 'Preparing...' : 'Share Your Calling Type',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: const Color(0xFF221D10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Invite CTA (viral loop) ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _inviteSomeone,
                      icon: const Icon(Icons.people_outline_rounded, size: 18),
                      label: const Text(
                        'Who balances your calling?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(
                          color: primaryColor.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Detailed Assessment CTA ───────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('${AppRoutes.assessment}/rating'),
                      icon: const Icon(Icons.trending_up_rounded, size: 18),
                      label: const Text(
                        'Deepen Your Assessment',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(
                          color: textColor.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Calling Gap Card (time diagnose bridge) ────────────
                  // This is the unique spiritual-worklife balance hook.
                  if (showCallingGap)
                    _CallingGapCard(
                      isDark: isDark,
                      textColor: textColor,
                      spiritPercent: spiritPercent,
                      vocationPercent: vocationPercent,
                    ),

                  const SizedBox(height: 24),

                  // ── Strengths ─────────────────────────────────────────
                  _SectionCard(
                    title: 'Your Strengths',
                    icon: Icons.star_rounded,
                    isDark: isDark,
                    textColor: textColor,
                    items: allStrengths,
                    bulletColor: primaryColor,
                  ),

                  const SizedBox(height: 16),

                  // ── Growth Areas ──────────────────────────────────────
                  _SectionCard(
                    title: 'Watch for These',
                    icon: Icons.radar_rounded,
                    isDark: isDark,
                    textColor: textColor,
                    items: allDistortions,
                    bulletColor: const Color(0xFFD4956A),
                  ),

                  const SizedBox(height: 32),

                  // ── Begin Journey CTA ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.go(AppRoutes.today),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: const Color(0xFF221D10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: primaryColor.withValues(alpha: 0.3),
                      ),
                      child: const Text(
                        'Begin Your Journey',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Retake Assessment',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Calling Gap Card ────────────────────────────────────────────────────────
// The unique bridge between spiritual identity and time allocation.
// Shows the tension between how much time someone gives to Vocation vs Spirit.
class _CallingGapCard extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  final int spiritPercent;
  final int vocationPercent;

  const _CallingGapCard({
    required this.isDark,
    required this.textColor,
    required this.spiritPercent,
    required this.vocationPercent,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF4B925);
    final isGapLarge = vocationPercent > spiritPercent + 15; // Gap > 15%

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFF4B925).withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGapLarge
              ? const Color(0xFFD4956A).withValues(alpha: 0.4)
              : primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isGapLarge ? const Color(0xFFD4956A) : primaryColor)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGapLarge
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isGapLarge ? const Color(0xFFD4956A) : primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'CALLING GAP',
                style: TextStyle(
                  color: isGapLarge
                      ? const Color(0xFFD4956A)
                      : primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isGapLarge
                ? 'Your calling is running on empty.'
                : 'Your time investment is aligned.',
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isGapLarge
                ? 'You give $vocationPercent% of your waking hours to Vocation but only $spiritPercent% to Spirit. The gifts in your signature need spiritual fuel — without it, they become striving.'
                : 'Your Spirit investment ($spiritPercent%) is supporting your calling. Keep protecting that time.',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (isGapLarge) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                // Navigate to time diagnose
                context.push(AppRoutes.timeDiagnose);
              },
              child: const Row(
                children: [
                  Text(
                    'Diagnose your time allocation',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: Color(0xFFF4B925)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section Card (Strengths / Growth Areas) ─────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final Color textColor;
  final List<String> items;
  final Color bulletColor;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.textColor,
    required this.items,
    required this.bulletColor,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF4B925);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? primaryColor.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: bulletColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: bulletColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

