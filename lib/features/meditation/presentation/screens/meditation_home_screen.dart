import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../domain/models/meditation_session.dart';
import '../../domain/models/meditation_enums.dart';
import '../../application/meditation_notifier.dart';

enum _RecentSessionAction { edit, start }

class MeditationHomeScreen extends ConsumerStatefulWidget {
  const MeditationHomeScreen({super.key});

  @override
  ConsumerState<MeditationHomeScreen> createState() => _MeditationHomeScreenState();
}

class _MeditationHomeScreenState extends ConsumerState<MeditationHomeScreen> {
  List<MeditationSession> _recentSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repository = ref.read(meditationSessionRepositoryProvider);
    final sessions = repository.getAllSessions().toList()
      ..sort((a, b) {
        final aKey = int.tryParse(a.id) ?? 0;
        final bKey = int.tryParse(b.id) ?? 0;
        return bKey.compareTo(aKey);
      });

    if (mounted) {
      setState(() {
        _recentSessions = sessions.take(10).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _openSessionScreen() async {
    await context.push('${AppRoutes.meditation}/session');
    if (!mounted) return;
    await _loadData();
  }

  Future<void> _openNewSession() async {
    final notifier = ref.read(meditationProvider.notifier);
    await notifier.resetToSetup();
    if (!mounted) return;
    await _openSessionScreen();
  }

  Future<void> _openRecentSession(MeditationSession session) async {
    final notifier = ref.read(meditationProvider.notifier);

    // Restore complete configuration if available, otherwise use legacy logic
    if (session.style != null) {
      // Use stored configuration for complete restoration
      notifier.setStyle(session.style!);
      notifier.setSelectedMinutes(session.durationMinutes);
      
      if (session.backgroundSound != null) {
        notifier.setBackgroundSound(session.backgroundSound!);
      }
      if (session.breathPace != null) {
        notifier.setBreathPace(session.breathPace!);
      }
      if (session.centeringWord != null && session.centeringWord!.isNotEmpty) {
        notifier.setCenteringWord(session.centeringWord!);
      }
      if (session.virtueName != null && session.virtueName!.isNotEmpty) {
        notifier.setVirtueName(session.virtueName!);
      }
      if (session.chosenChantId != null && session.chosenChantId!.isNotEmpty) {
        notifier.setChant(session.chosenChantId!);
      }
      if (session.bibleTemplate != null) {
        notifier.setBibleTemplate(session.bibleTemplate!);
      }
      if (session.affirmationCategory != null) {
        notifier.setAffirmationCategory(session.affirmationCategory!);
      }
      if (session.virtueAffirmation != null) {
        notifier.setVirtueAffirmation(session.virtueAffirmation!);
      }
      if (session.habitAffirmation != null) {
        notifier.setHabitAffirmation(session.habitAffirmation!);
      }
      if (session.customBibleVerses != null && session.customBibleVerses!.isNotEmpty) {
        notifier.setCustomBibleVerses(session.customBibleVerses!);
      }
    } else {
      // Legacy fallback for sessions without stored configuration
      final style = session.title.contains('Chant')
          ? MeditationStyle.chant
          : (session.guided ? MeditationStyle.affirmation : MeditationStyle.quietReflection);

      notifier.setStyle(style);
      notifier.setSelectedMinutes(session.durationMinutes);
      if (style == MeditationStyle.affirmation) {
        notifier.setVirtueName(_titleCase(session.virtueType.name));
      } else {
        notifier.setVirtueName(null);
      }

      if (style == MeditationStyle.chant) {
        await notifier.resetToSetup();
        if (!mounted) return;
        await _openSessionScreen();
        return;
      }
    }

    final action = await showDialog<_RecentSessionAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start Session'),
        content: Text(
          'Start ${session.durationMinutes} min ${session.style?.label.toLowerCase() ?? "meditation"}?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _RecentSessionAction.edit),
            child: const Text('Edit'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _RecentSessionAction.start),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (action == null) return;

    if (action == _RecentSessionAction.edit) {
      await notifier.resetToSetup();
      if (!mounted) return;
      await _openSessionScreen();
      return;
    }

    await notifier.startSession();
    if (!mounted) return;
    await _openSessionScreen();
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textMutedColor = isDark ? Colors.white54 : const Color(0xFF666666);
    final borderColor = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05);

    final authState = ref.watch(authProvider);
    final userName = authState.user?.firstName ?? 'Meditator';

    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final weeklyMinutes = _recentSessions.fold<int>(0, (sum, session) {
      final millis = int.tryParse(session.id);
      if (millis == null) {
        return sum;
      }
      final completedAt = DateTime.fromMillisecondsSinceEpoch(millis);
      if (completedAt.isBefore(weekStart)) {
        return sum;
      }
      return sum + (session.durationMinutes * session.completedCount);
    });

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Icon(
                                  LucideIcons.user,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $userName',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Ready to reflect?',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: textMutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                          ),
                          child: IconButton(
                            icon: Icon(LucideIcons.settings, size: 20, color: textColor),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Weekly Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.clock,
                          color: primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time Spent Meditating',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: textMutedColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$weeklyMinutes mins',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Rolling last 7 days',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: textMutedColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Start New
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: InkWell(
                  onTap: _openNewSession,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.plus,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Meditation',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Configure a new session',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Recent Configurations
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Sessions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_recentSessions.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.history,
                          size: 48,
                          color: textMutedColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No recent sessions yet',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final session = _recentSessions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: InkWell(
                        onTap: () => _openRecentSession(session),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  LucideIcons.playCircle,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.title,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${session.durationMinutes} min - ${_titleCase(session.virtueType.name)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: textMutedColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                LucideIcons.chevronRight,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _recentSessions.length,
                ),
              ),
              
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

