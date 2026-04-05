import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../application/faith_questions_notifier.dart';
import '../../data/faith_question_catalog.dart';
import '../widgets/faq_question_card.dart';

class FaithFaqScreen extends ConsumerStatefulWidget {
  const FaithFaqScreen({super.key});

  @override
  ConsumerState<FaithFaqScreen> createState() => _FaithFaqScreenState();
}

class _FaithFaqScreenState extends ConsumerState<FaithFaqScreen> {
  final _searchController = TextEditingController();
  final _expandedIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(faithQuestionsProvider);
    final notifier = ref.read(faithQuestionsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final questions = notifier.getFilteredQuestions();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Explore Questions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => notifier.setSearchQuery(v),
                decoration: InputDecoration(
                  hintText: 'Search questions...',
                  prefixIcon: Icon(LucideIcons.search,
                      size: 20,
                      color: isDark ? Colors.white38 : Colors.black38),
                  suffixIcon: state.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            notifier.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1e293b)
                      : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final cat in FaithQuestionCatalog.categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          FaithQuestionCatalog.categoryLabels[cat] ?? cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: state.selectedCategory == cat
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                        selected: state.selectedCategory == cat,
                        onSelected: (_) => notifier.setCategory(cat),
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: isDark
                            ? const Color(0xFF1e293b)
                            : const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        showCheckmark: false,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Questions list
            Expanded(
              child: questions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.searchX,
                              size: 48,
                              color: isDark ? Colors.white24 : Colors.black26),
                          const SizedBox(height: 12),
                          Text(
                            'No questions found',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        final isExpanded = _expandedIds.contains(question.id);
                        return FaqQuestionCard(
                          question: question,
                          isExpanded: isExpanded,
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedIds.remove(question.id);
                              } else {
                                _expandedIds.add(question.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
