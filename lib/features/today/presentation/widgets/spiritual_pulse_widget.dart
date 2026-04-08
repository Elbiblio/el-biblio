import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../domain/models/daily_anchors.dart';

/// Spiritual Pulse Widget - A 4-step quick check-in wizard for emotional awareness
/// 
/// Steps:
/// 1. How's your spirit? (Required) - 6 emotion chips
/// 2. What's the intensity? (Required) - 3 options
/// 3. One thing on your mind? (Optional) - 6 quick tap options
/// 4. Quick note? (Optional) - 140 character limit
class SpiritualPulseWidget extends ConsumerStatefulWidget {
  const SpiritualPulseWidget({super.key});

  @override
  ConsumerState<SpiritualPulseWidget> createState() => _SpiritualPulseWidgetState();
}

class _SpiritualPulseWidgetState extends ConsumerState<SpiritualPulseWidget> {
  final PageController _pageController = PageController();
  final TextEditingController _noteController = TextEditingController();
  
  int _currentStep = 0;
  SpiritualPulseType? _selectedType;
  String? _selectedIntensity;
  String? _selectedMindItem;
  
  final List<String> _intensities = [
    'Light',
    'Medium',
    'Strong',
  ];
  
  final List<String> _mindItems = [
    'Family',
    'Work',
    'Stress',
    'Goals',
    'Health',
    'Other',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitPulse();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOptionalStep() {
    if (_currentStep == 2) {
      setState(() {
        _selectedMindItem = null;
      });
      _nextStep();
    } else if (_currentStep == 3) {
      setState(() {
        _noteController.clear();
      });
      _submitPulse();
    }
  }

  void _submitPulse() {
    if (_selectedType == null || _selectedIntensity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an emotion and intensity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ref.read(dailyAnchorsProvider.notifier).addSpiritualPulse(
      type: _selectedType!,
      note: _noteController.text.trim().isNotEmpty 
          ? _noteController.text.trim() 
          : _selectedMindItem ?? '',
      intensity: _mapIntensityToValue(_selectedIntensity!),
      goingWell: null,
      struggling: null,
      needHelp: null,
      followUpAnswer: null,
      virtueFocus: null,
    );

    // Reset form
    setState(() {
      _currentStep = 0;
      _selectedType = null;
      _selectedIntensity = null;
      _selectedMindItem = null;
    });
    _noteController.clear();
    _pageController.jumpToPage(0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daily check-in recorded'),
        backgroundColor: Colors.green,
      ),
    );
  }

  double _mapIntensityToValue(String intensity) {
    switch (intensity) {
      case 'Light':
        return 0.33;
      case 'Medium':
        return 0.66;
      case 'Strong':
        return 1.0;
      default:
        return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with progress
          Row(
            children: [
              Text(
                'Daily Check-in',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                'Step ${_currentStep + 1} of 4',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 16),
          // Wizard content (compact height for less scroll)
          SizedBox(
            height: 240,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1Emotion(
                  selectedType: _selectedType,
                  onSelect: (type) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                  theme: theme,
                  tokens: tokens,
                  isDark: isDark,
                ),
                _Step2Intensity(
                  intensities: _intensities,
                  selectedIntensity: _selectedIntensity,
                  onSelect: (intensity) {
                    setState(() {
                      _selectedIntensity = intensity;
                    });
                  },
                  theme: theme,
                  tokens: tokens,
                ),
                _Step3MindItem(
                  mindItems: _mindItems,
                  selectedItem: _selectedMindItem,
                  onSelect: (item) {
                    setState(() {
                      _selectedMindItem = item;
                    });
                  },
                  theme: theme,
                  tokens: tokens,
                  isDark: isDark,
                ),
                _Step4Note(
                  controller: _noteController,
                  theme: theme,
                  tokens: tokens,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Navigation buttons
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusSmall),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: _currentStep > 0 ? 1 : 2,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusSmall),
                    ),
                  ),
                  child: Text(_currentStep == 3 ? 'Submit' : 'Next'),
                ),
              ),
              if (_currentStep >= 2) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _skipOptionalStep,
                  child: const Text('Skip'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Step1Emotion extends StatelessWidget {
  const _Step1Emotion({
    required this.selectedType,
    required this.onSelect,
    required this.theme,
    required this.tokens,
    required this.isDark,
  });

  final SpiritualPulseType? selectedType;
  final Function(SpiritualPulseType) onSelect;
  final ThemeData theme;
  final AppThemeTokens tokens;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "How are you feeling today?",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SpiritualPulseType.values.map((type) {
            final isSelected = selectedType == type;
            return InkWell(
              onTap: () => onSelect(type),
              borderRadius: BorderRadius.circular(tokens.radiusSmall),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(tokens.radiusSmall),
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  _getPulseTypeLabel(type),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getPulseTypeLabel(SpiritualPulseType type) {
    switch (type) {
      case SpiritualPulseType.peace:
        return 'Peace';
      case SpiritualPulseType.joy:
        return 'Joy';
      case SpiritualPulseType.gratitude:
        return 'Gratitude';
      case SpiritualPulseType.hope:
        return 'Hope';
      case SpiritualPulseType.love:
        return 'Love';
      case SpiritualPulseType.wisdom:
        return 'Wisdom';
    }
  }
}

class _Step2Intensity extends StatelessWidget {
  const _Step2Intensity({
    required this.intensities,
    required this.selectedIntensity,
    required this.onSelect,
    required this.theme,
    required this.tokens,
  });

  final List<String> intensities;
  final String? selectedIntensity;
  final Function(String) onSelect;
  final ThemeData theme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "How strong is this feeling?",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Choose how it feels",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        ...intensities.map((intensity) {
          final isSelected = selectedIntensity == intensity;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onSelect(intensity),
              borderRadius: BorderRadius.circular(tokens.radiusMedium),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                            theme.colorScheme.primary.withValues(alpha: 0.6),
                          ]
                        : [
                            theme.colorScheme.surfaceContainerHighest,
                            theme.colorScheme.surfaceContainerHighest,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  intensity,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _Step3MindItem extends StatelessWidget {
  const _Step3MindItem({
    required this.mindItems,
    required this.selectedItem,
    required this.onSelect,
    required this.theme,
    required this.tokens,
    required this.isDark,
  });

  final List<String> mindItems;
  final String? selectedItem;
  final Function(String) onSelect;
  final ThemeData theme;
  final AppThemeTokens tokens;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's on your mind?",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Optional - tap if anything stands out",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: mindItems.map((item) {
            final isSelected = selectedItem == item;
            return InkWell(
              onTap: () => onSelect(item),
              borderRadius: BorderRadius.circular(tokens.radiusSmall),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.15) : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(tokens.radiusSmall),
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  item,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Step4Note extends StatelessWidget {
  const _Step4Note({
    required this.controller,
    required this.theme,
    required this.tokens,
    required this.isDark,
  });

  final TextEditingController controller;
  final ThemeData theme;
  final AppThemeTokens tokens;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Add a quick note?",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Optional - any insights?",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          maxLength: 100,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "What's God showing you...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusSmall),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          "${controller.text.length}/100",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
