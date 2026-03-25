import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../domain/models/app_category.dart';
import '../../domain/models/app_lock_config.dart';

class AppLockSetupScreen extends ConsumerStatefulWidget {
  const AppLockSetupScreen({super.key});

  @override
  ConsumerState<AppLockSetupScreen> createState() => _AppLockSetupScreenState();
}

class _AppLockSetupScreenState extends ConsumerState<AppLockSetupScreen> {
  AppCategory? _selectedCategory;
  final Set<String> _selectedPackages = {};
  int _limitMinutes = 60;

  List<PopularApp> get _appsForCategory {
    if (_selectedCategory == null) return [];
    return popularApps
        .where((a) => a.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final existingConfigs = ref.watch(appLockProvider).configs;
    final existingPackages =
        existingConfigs.map((c) => c.packageName).toSet();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tokens.pageGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Set App Limits',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step 1: Choose category
                      Text(
                        'CHOOSE A CATEGORY',
                        style: theme.textTheme.sectionHeader.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: AppCategory.values.map((category) {
                          final isSelected = _selectedCategory == category;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                                _selectedPackages.clear();
                                _limitMinutes =
                                    category.suggestedLimitMinutes;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: isSelected
                                    ? category.color.withValues(alpha: 0.15)
                                    : theme.cardColor,
                                border: Border.all(
                                  color: isSelected
                                      ? category.color
                                      : tokens.palette.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    category.icon,
                                    size: 20,
                                    color: isSelected
                                        ? category.color
                                        : tokens.palette.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category.label,
                                    style:
                                        theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? category.color
                                          : tokens.palette.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Step 2: Select apps
                      if (_selectedCategory != null) ...[
                        const SizedBox(height: 28),
                        Text(
                          'SELECT APPS',
                          style: theme.textTheme.sectionHeader.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._appsForCategory.map((app) {
                          final isSelected =
                              _selectedPackages.contains(app.packageName);
                          final alreadyAdded =
                              existingPackages.contains(app.packageName);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: alreadyAdded
                                  ? null
                                  : () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedPackages
                                              .remove(app.packageName);
                                        } else {
                                          _selectedPackages
                                              .add(app.packageName);
                                        }
                                      });
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: alreadyAdded
                                      ? tokens.palette.surface
                                          .withValues(alpha: 0.5)
                                      : isSelected
                                          ? _selectedCategory!.color
                                              .withValues(alpha: 0.1)
                                          : theme.cardColor,
                                  border: Border.all(
                                    color: isSelected
                                        ? _selectedCategory!.color
                                        : tokens.palette.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        color: _selectedCategory!.color
                                            .withValues(alpha: 0.12),
                                      ),
                                      child: Icon(
                                        app.icon,
                                        color: _selectedCategory!.color,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        app.name,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: alreadyAdded
                                              ? tokens.palette.textTertiary
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (alreadyAdded)
                                      Text(
                                        'Already added',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color:
                                              tokens.palette.textTertiary,
                                        ),
                                      )
                                    else
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? _selectedCategory!.color
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? _selectedCategory!.color
                                                : tokens.palette.border,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check_rounded,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],

                      // Step 3: Set limit
                      if (_selectedPackages.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Text(
                          'DAILY TIME LIMIT',
                          style: theme.textTheme.sectionHeader.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Suggested: ${_selectedCategory!.suggestedLimitMinutes}m for ${_selectedCategory!.label}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.palette.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: theme.cardColor,
                            border:
                                Border.all(color: tokens.palette.border),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _formatLimit(_limitMinutes),
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: tokens.palette.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'per day',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: tokens.palette.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Slider(
                                value: _limitMinutes.toDouble(),
                                min: 15,
                                max: 240,
                                divisions: 15,
                                label: _formatLimit(_limitMinutes),
                                onChanged: (value) {
                                  setState(() {
                                    _limitMinutes = value.round();
                                  });
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '15m',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color:
                                            tokens.palette.textTertiary,
                                      ),
                                    ),
                                    Text(
                                      '4h',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color:
                                            tokens.palette.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quick presets
                        Text(
                          'QUICK PRESETS',
                          style: theme.textTheme.sectionHeader.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [15, 30, 60, 90, 120].map((mins) {
                            final isSelected = _limitMinutes == mins;
                            return ChoiceChip(
                              selected: isSelected,
                              label: Text(_formatLimit(mins)),
                              onSelected: (_) {
                                setState(() => _limitMinutes = mins);
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 100), // space for bottom button
                    ],
                  ),
                ),
              ),

              // Save button
              if (_selectedPackages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(color: tokens.palette.border),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(
                        'Save ${_selectedPackages.length} App${_selectedPackages.length == 1 ? '' : 's'}',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLimit(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${minutes}m';
  }

  Future<void> _save() async {
    final notifier = ref.read(appLockProvider.notifier);

    for (final packageName in _selectedPackages) {
      final app = popularApps.firstWhere(
        (a) => a.packageName == packageName,
        orElse: () => PopularApp(
          name: packageName,
          packageName: packageName,
          category: _selectedCategory!,
          icon: Icons.apps_rounded,
        ),
      );

      final config = AppLockConfig(
        id: '${packageName}_${DateTime.now().millisecondsSinceEpoch}',
        appName: app.name,
        packageName: packageName,
        dailyLimitMinutes: _limitMinutes,
        category: _selectedCategory!.id,
      );

      await notifier.addConfig(config);
    }

    if (mounted) {
      context.pop();
    }
  }
}
