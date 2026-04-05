import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../domain/services/bible_reference_parser.dart';

/// An intermediate screen shown after successful game completion that
/// encourages the user to read the source Bible passage.
class PostGameReadingScreen extends StatelessWidget {
  final String bibleReference;
  final int xpEarned;
  final String gameTitle;

  const PostGameReadingScreen({
    super.key,
    required this.bibleReference,
    required this.xpEarned,
    required this.gameTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parsed = BibleReferenceParser.parse(bibleReference);
    final allRefs = BibleReferenceParser.parseAll(bibleReference);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A2332), const Color(0xFF0F172A)]
                : [const Color(0xFFF0F7EE), const Color(0xFFFFFBF5)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Celebration icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF5e7153), Color(0xFF7a9b6d)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5e7153).withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 28),

                // Congratulations text
                Text(
                  'Well Done!',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1a1c1e),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  gameTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ),

                const SizedBox(height: 20),

                // XP Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDAA520).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFDAA520).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: Color(0xFFDAA520),
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+$xpEarned XP',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDAA520),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Bible reference card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1e293b)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 32,
                        color: isDark
                            ? const Color(0xFF7a9b6d)
                            : const Color(0xFF5e7153),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This game was based on',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bibleReference,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1a1c1e),
                        ),
                      ),
                      if (allRefs.length > 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Navigating to ${allRefs.first}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Deepen your understanding by reading\nthe original passage.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Read the Passage button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: parsed != null
                        ? () {
                            final queryParams = <String, String>{
                              'book': parsed.book,
                              'chapter': parsed.chapter.toString(),
                            };
                            if (parsed.verse != null) {
                              queryParams['verse'] = parsed.verse.toString();
                            }
                            final uri = Uri(
                              path: AppRoutes.bibleReader,
                              queryParameters: queryParams,
                            );
                            context.go(uri.toString());
                          }
                        : null,
                    icon: const Icon(Icons.menu_book_rounded, size: 20),
                    label: const Text(
                      'Read the Passage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5e7153),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Skip button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      context.go(AppRoutes.games);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Skip for Now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
