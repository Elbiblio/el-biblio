import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/tts_service.dart';
import '../../../companion/application/companion_notifier.dart';
import '../../../companion/domain/models/companion_character.dart';
import '../../../companion/domain/models/companion_mood.dart';
import '../../../companion/presentation/widgets/companion_orb.dart';
import '../../application/spiritual_aid_notifier.dart';
import '../../domain/models/verse_moment.dart';
import '../widgets/verse_reveal_animation.dart';

class SpeakToMeScreen extends ConsumerStatefulWidget {
  const SpeakToMeScreen({super.key});

  @override
  ConsumerState<SpeakToMeScreen> createState() => _SpeakToMeScreenState();
}

class _SpeakToMeScreenState extends ConsumerState<SpeakToMeScreen>
    with TickerProviderStateMixin {
  final _ttsService = TTSService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _bgController;
  late Animation<Color?> _bgAnimation1;
  late Animation<Color?> _bgAnimation2;
  bool _showHistory = false;
  bool _verseRevealed = false;
  final GlobalKey<VerseRevealAnimationState> _revealKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _bgAnimation1 = ColorTween(
      begin: const Color(0xFF1a1040),
      end: const Color(0xFF2d1b69),
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _bgAnimation2 = ColorTween(
      begin: const Color(0xFF0d0d2b),
      end: const Color(0xFF1a0f3e),
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bgController.dispose();
    _ttsService.stop();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spiritualAidProvider);
    final verse = state.currentVerse;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _bgAnimation1.value ?? const Color(0xFF1a1040),
                  _bgAnimation2.value ?? const Color(0xFF0d0d2b),
                ],
              ),
            ),
            child: SafeArea(
              child: _showHistory
                  ? _buildHistoryView(state)
                  : _buildMainView(verse, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainView(VerseMoment? verse, SpiritualAidState state) {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showHistory = true),
                icon: const Icon(Icons.history_rounded, color: Colors.white70),
              ),
            ],
          ),
        ),

        // Main content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: verse == null
                ? _buildEmptyState(state.isVerseLoading)
                : _buildVerseDisplay(verse, state),
          ),
        ),

        // Bottom action
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
          child: Column(
            children: [
              if (verse != null) ...[
                // Action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      Icons.volume_up_rounded,
                      'Listen',
                      () => _ttsService.speak(verse.verseText, isBibleVerse: true),
                    ),
                    _buildActionButton(
                      verse.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      verse.isBookmarked ? 'Saved' : 'Save',
                      () {
                        // Find the current verse's index in history
                        final history = state.verseHistory;
                        final index = history.indexWhere(
                          (v) => v.reference == verse.reference && v.verseText == verse.verseText,
                        );
                        if (index >= 0) {
                          ref.read(spiritualAidProvider.notifier).toggleVerseBookmark(index);
                        }
                      },
                    ),
                    _buildActionButton(
                      Icons.share_rounded,
                      'Share',
                      () => _shareVerse(verse),
                    ),
                    _buildActionButton(
                      Icons.lightbulb_outline_rounded,
                      'Explain',
                      state.isExplanationLoading
                          ? null
                          : () => ref.read(spiritualAidProvider.notifier).explainCurrentVerse(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Generate button
              ScaleTransition(
                scale: _pulseAnimation,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: state.isVerseLoading ? null : _generateVerse,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: state.isVerseLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white70),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome_rounded, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                verse == null ? 'Speak to Me' : 'Another Verse',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isLoading) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 24),
          Text(
            'Speak to Me, Lord',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to receive\na verse from God\'s Word',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseDisplay(VerseMoment verse, SpiritualAidState state) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Verse text with word-by-word animation
          VerseRevealAnimation(
            key: _revealKey,
            text: verse.verseText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              height: 1.7,
            ),
            wordDuration: const Duration(milliseconds: 100),
            onComplete: () {
              if (mounted) setState(() => _verseRevealed = true);
            },
          ),
          const SizedBox(height: 24),

          // Reference
          AnimatedOpacity(
            opacity: _verseRevealed ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(
                verse.reference,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

          if (verse.bookContext != null) ...[
            const SizedBox(height: 8),
            AnimatedOpacity(
              opacity: _verseRevealed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Text(
                'From the book of ${verse.bookContext}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
            ),
          ],

          // Explanation — rendered in the companion's voice when one is selected.
          if (verse.explanation != null) ...[
            const SizedBox(height: 24),
            _ExplanationCard(explanation: verse.explanation!),
          ] else if (state.isExplanationLoading) ...[
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white38),
              ),
            ),
          ] else if (state.error != null && (state.error?.contains('explain') ?? false)) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Explanation unavailable right now. Try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Colors.white70, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView(SpiritualAidState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _showHistory = false),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
              ),
              const SizedBox(width: 4),
              const Text(
                'Verse History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.verseHistory.isEmpty
              ? Center(
                  child: Text(
                    'No verses generated yet',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.verseHistory.length,
                  itemBuilder: (context, index) {
                    final verse = state.verseHistory[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  verse.reference,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (verse.isBookmarked)
                                Icon(
                                  Icons.bookmark_rounded,
                                  color: Colors.amber.shade300,
                                  size: 18,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            verse.verseText,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(verse.generatedAt),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _generateVerse() {
    setState(() => _verseRevealed = false);
    HapticFeedback.mediumImpact();
    ref.read(spiritualAidProvider.notifier).generateRandomVerse();
  }

  void _shareVerse(VerseMoment verse) {
    Share.share(
      '"${verse.verseText}"\n\n- ${verse.reference}\n\nShared via ElBiblio',
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Renders the verse explanation. When a companion is selected, swaps the
/// generic "Understanding" header for the companion's orb + name + tagline
/// so the explanation reads as *their* voice speaking to the user.
class _ExplanationCard extends ConsumerWidget {
  const _ExplanationCard({required this.explanation});

  final String explanation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = ref.watch(
      companionProvider.select((s) => s.activeCharacter),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (character != null)
            _CompanionHeader(character: character)
          else
            Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.amber.shade300,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Understanding',
                  style: TextStyle(
                    color: Colors.amber.shade300,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Text(
            explanation,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionHeader extends StatelessWidget {
  const _CompanionHeader({required this.character});
  final CompanionCharacter character;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CompanionOrb(
          character: character,
          mood: CompanionMood.warm,
          size: 28,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${character.displayName} reflects',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              character.tagline,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
