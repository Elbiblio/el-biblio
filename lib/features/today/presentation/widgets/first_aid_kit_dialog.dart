import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../../../meditation/application/meditation_notifier.dart';

class FirstAidKitDialog extends ConsumerStatefulWidget {
  const FirstAidKitDialog({super.key});

  @override
  ConsumerState<FirstAidKitDialog> createState() => _FirstAidKitDialogState();
}

class _FirstAidKitDialogState extends ConsumerState<FirstAidKitDialog> {
  @override
  Widget build(BuildContext context) {
    final allTools = _getAllTools();
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              children: [
                Icon(
                  Icons.medical_services_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'First Aid Kit',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a tool for immediate support',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            
            // All available tools
            ...allTools.map((tool) => _buildToolButton(context, tool)),
            
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<QuickHelpTool> _getAllTools() {
    return [
      QuickHelpTool(
        icon: Icons.air_rounded,
        title: 'Take a breather',
        subtitle: 'Instant calm with 3 breaths',
        action: _showBreathingReset,
      ),
      QuickHelpTool(
        icon: Icons.church_rounded,
        title: 'Quick Prayer',
        subtitle: 'General guidance',
        action: _showQuickPrayer,
      ),
      QuickHelpTool(
        icon: Icons.menu_book_rounded,
        title: 'Random Verses',
        subtitle: 'Quick inspiration',
        action: _showRandomVerses,
      ),
      QuickHelpTool(
        icon: Icons.self_improvement_rounded,
        title: '1 minute Reflection',
        subtitle: 'Start your day with purpose',
        action: _startAffirmation,
      ),
    ];
  }

  Widget _buildToolButton(BuildContext context, QuickHelpTool tool) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          tool.action();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  tool.icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      tool.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startAffirmation() {
    final settings = ref.read(settingsProvider);
    final meditationNotifier = ref.read(meditationProvider.notifier);
    
    // Start a 1-minute affirmation meditation
    meditationNotifier.startQuickAffirmation(settings.primaryVirtue);
    
    // Navigate to meditation screen
    context.push('/meditation');
  }


  void _showQuickPrayer() {
    _showPrayerDialog(
      title: 'Quick Prayer',
      prayer: _getQuickPrayer(),
    );
  }

  void _showPrayerDialog({required String title, required String prayer}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            prayer,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRandomVerses() async {
    try {
      final bibleRepository = ref.read(bibleRepositoryProvider);
      final verses = await bibleRepository.getRandomVerses(3);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Random Verses'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: verses.map((verse) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verse.text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        verse.reference ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading verses: $e')),
        );
      }
    }
  }

  void _showBreathingReset() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BreathingResetDialog(
        onComplete: () => Navigator.of(context).pop(),
      ),
    );
  }



  String _getQuickPrayer() {
    return '''Lord, hear my prayer.

You know my heart, my needs, and my struggles.
I trust in your love and wisdom.
Guide me, protect me, and give me peace.
Help me to know you are with me always.

In Jesus' name,
Amen.''';
  }
}

class QuickHelpTool {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback action;

  QuickHelpTool({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });
}

class BreathingResetDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const BreathingResetDialog({super.key, required this.onComplete});

  @override
  State<BreathingResetDialog> createState() => _BreathingResetDialogState();
}

class _BreathingResetDialogState extends State<BreathingResetDialog>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  int _currentBreath = 0;
  String _instruction = 'Breathe In';
  bool _isInhaling = true;

  @override
  void initState() {
    super.initState();
    
    _breathController = AnimationController(
      duration: const Duration(seconds: 4), // 4 seconds per breath
      vsync: this,
    );
    
    _breathAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOut,
    ));

    _startBreathing();
  }

  void _startBreathing() {
    if (_currentBreath >= 3) {
      widget.onComplete();
      return;
    }

    setState(() {
      _instruction = _isInhaling ? 'Breathe In' : 'Breathe Out';
    });

    _breathController.forward().then((_) {
      setState(() {
        _instruction = _isInhaling ? 'Breathe Out' : 'Breathe In';
        _isInhaling = !_isInhaling;
      });

      _breathController.reverse().then((_) {
        _currentBreath++;
        if (_currentBreath < 3) {
          _startBreathing();
        } else {
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '3-Breath Reset',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _breathAnimation,
              builder: (context, child) {
                return Container(
                  width: 80 * _breathAnimation.value,
                  height: 80 * _breathAnimation.value,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.air_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32 * _breathAnimation.value,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              _instruction,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Breath ${_currentBreath + 1} of 3',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
