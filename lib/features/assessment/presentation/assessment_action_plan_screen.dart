import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../application/assessment_notifier.dart';
import '../data/assessment_task_catalog.dart';

class AssessmentActionPlanScreen extends ConsumerStatefulWidget {
  const AssessmentActionPlanScreen({super.key});

  @override
  ConsumerState<AssessmentActionPlanScreen> createState() =>
      _AssessmentActionPlanScreenState();
}

class _AssessmentActionPlanScreenState
    extends ConsumerState<AssessmentActionPlanScreen> {
  final List<String> _selectedTasks = [];
  bool _isLoading = true;
  List<AssessmentActionTask> _availableTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final path = ref.read(assessmentProvider).selectedPath;
    final catalog = ref.read(assessmentTaskCatalogProvider);

    setState(() {
      _availableTasks = catalog.tasksForPath(path);
      _isLoading = false;
    });
  }

  void _toggleTask(String taskId) {
    setState(() {
      if (_selectedTasks.contains(taskId)) {
        _selectedTasks.remove(taskId);
      } else {
        if (_selectedTasks.length < 3) {
          _selectedTasks.add(taskId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only select up to 3 tasks to focus on.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  Future<void> _submitAssessmentAndContinue() async {
    final notifier = ref.read(assessmentProvider.notifier);
    final apiRepository = ref.read(assessmentApiRepositoryProvider);
    final synced = await notifier.submitCurrentAssessment(apiRepository);

    if (!mounted) return;
    if (!synced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved locally. We will sync your assessment when possible.'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    context.push('${AppRoutes.assessment}/results');
  }

  Future<void> _onComplete() async {
    if (_selectedTasks.isEmpty) return;

    // Save tasks to state
    ref.read(assessmentProvider.notifier).setTasks(_selectedTasks);

    await _submitAssessmentAndContinue();
  }

  Future<void> _onSkipForNow() async {
    ref.read(assessmentProvider.notifier).setTasks(const []);
    await _submitAssessmentAndContinue();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFF4B925);
    final bgColor = isDark ? const Color(0xFF221D10) : const Color(0xFFF8F7F5);
    final textColor = isDark ? Colors.white : Colors.black87;

    final state = ref.watch(assessmentProvider);
    final path = state.selectedPath;

    String headerText = 'ACTION PLAN';
    String titleText = 'Select Your Next Steps';
    String descriptionText =
        'Choose 1-3 practical steps you can take this week to begin your journey.';

    if (path == 'development') {
      headerText = 'DEVELOPMENT PLAN';
      titleText = 'Build Your Foundation';
    } else if (path == 'engagement') {
      headerText = 'ENGAGEMENT PLAN';
      titleText = 'Start Serving Now';
    } else if (path == 'recalibration') {
      headerText = 'RECALIBRATION PLAN';
      titleText = 'Realign Your Focus';
    }

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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryColor))
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            headerText,
                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            titleText,
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
                            descriptionText,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ..._availableTasks.map((task) {
                            final isSelected =
                                _selectedTasks.contains(task.id);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: GestureDetector(
                                onTap: () => _toggleTask(task.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor.withValues(alpha: 0.1)
                                        : (isDark
                                            ? Colors.grey[900]
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor
                                          : primaryColor.withValues(alpha: 0.2),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryColor
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? primaryColor
                                                : textColor.withValues(
                                                    alpha: 0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(Icons.check,
                                                size: 16,
                                                color: Color(0xFF221D10))
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.title,
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              task.description,
                                              style: TextStyle(
                                                color: textColor.withValues(
                                                    alpha: 0.7),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedTasks.length}/3 selected',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedTasks.isEmpty)
                              TextButton(
                                onPressed: _onSkipForNow,
                                child: const Text(
                                  'Skip for now',
                                  style: TextStyle(color: primaryColor),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                _selectedTasks.isNotEmpty ? _onComplete : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: const Color(0xFF221D10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'View Final Results →',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
