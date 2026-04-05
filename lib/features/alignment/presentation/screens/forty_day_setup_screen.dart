import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../data/forty_day_templates.dart';
import '../../domain/models/forty_day_goal.dart';

class FortyDaySetupScreen extends ConsumerStatefulWidget {
  const FortyDaySetupScreen({super.key});

  @override
  ConsumerState<FortyDaySetupScreen> createState() =>
      _FortyDaySetupScreenState();
}

class _FortyDaySetupScreenState extends ConsumerState<FortyDaySetupScreen> {
  FortyDayGoal? _selectedTemplate;
  bool _showPreview = false;

  static const _categoryIcons = <String, IconData>{
    'Prayer Life': LucideIcons.heartHandshake,
    'Scripture Study': LucideIcons.bookOpen,
    'Service': LucideIcons.heart,
    'Gratitude': LucideIcons.sun,
    'Forgiveness': LucideIcons.heartHandshake,
    'Fasting': LucideIcons.moon,
  };

  static const _categoryColors = <String, Color>{
    'Prayer Life': Color(0xFF7B68EE),
    'Scripture Study': Color(0xFF4B82C3),
    'Service': Color(0xFFE88D67),
    'Gratitude': Color(0xFFF4C430),
    'Forgiveness': Color(0xFF5A8E67),
    'Fasting': Color(0xFF9B7DC0),
  };

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Scaffold(
      backgroundColor: tokens.palette.background,
      appBar: AppBar(
        title: Text(_showPreview ? 'Preview Plan' : '40-Day Goals'),
        backgroundColor: tokens.palette.background,
        leading: _showPreview
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showPreview = false),
              )
            : null,
      ),
      body: _showPreview && _selectedTemplate != null
          ? _buildPreview(context, tokens)
          : _buildTemplateList(context, tokens),
    );
  }

  Widget _buildTemplateList(BuildContext context, AppThemeTokens tokens) {
    final templates = FortyDayTemplates.allTemplates;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Journey',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.palette.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a 40-day spiritual transformation goal.',
            style: TextStyle(
              color: tokens.palette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          ...templates.map((template) {
            final color = _categoryColors[template.category] ?? tokens.palette.primary;
            final icon = _categoryIcons[template.category] ?? LucideIcons.target;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: tokens.palette.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.palette.border),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() {
                    _selectedTemplate = template;
                    _showPreview = true;
                  }),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: tokens.palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                template.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tokens.palette.textSecondary,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: tokens.palette.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context, AppThemeTokens tokens) {
    final template = _selectedTemplate!;
    final color =
        _categoryColors[template.category] ?? tokens.palette.primary;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.1),
                        color.withValues(alpha: 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          template.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        template.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: tokens.palette.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        template.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.palette.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(LucideIcons.calendar, size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(
                            '40 Days',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(LucideIcons.clock, size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(
                            '5-20 min/day',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Preview first 7 days
                Text(
                  'FIRST WEEK PREVIEW',
                  style: Theme.of(context).textTheme.sectionHeader.copyWith(
                        color: tokens.palette.textTertiary,
                      ),
                ),
                const SizedBox(height: 12),
                ...template.dailyTasks.take(7).map((task) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.palette.paper,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tokens.palette.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.1),
                          ),
                          child: Center(
                            child: Text(
                              '${task.dayNumber}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: tokens.palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                task.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tokens.palette.textSecondary,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${task.durationMinutes} min | ${task.relatedVerse}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: tokens.palette.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Text(
                  '... and 33 more days of growing commitments',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: tokens.palette.textTertiary,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Start button
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ref.read(fortyDayProvider.notifier).startGoal(template);
                context.go('/alignment/forty-day-progress');
              },
              style: FilledButton.styleFrom(
                backgroundColor: color,
              ),
              child: const Text('Begin This Journey'),
            ),
          ),
        ),
      ],
    );
  }
}
