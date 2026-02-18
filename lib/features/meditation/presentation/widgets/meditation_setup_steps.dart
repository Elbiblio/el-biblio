import 'package:flutter/material.dart';

import '../../application/meditation_notifier.dart';
import '../../domain/models/meditation_enums.dart';

// ── Step 0: Style selection ──────────────────────────────────────────────────

class StyleSelectionStep extends StatelessWidget {
  const StyleSelectionStep({
    super.key,
    required this.selectedStyle,
    required this.notifier,
  });

  final MeditationStyle selectedStyle;
  final MeditationNotifier notifier;

  static const _styleIcons = {
    MeditationStyle.virtue: Icons.auto_awesome_rounded,
    MeditationStyle.parable: Icons.menu_book_rounded,
    MeditationStyle.centering: Icons.spa_rounded,
    MeditationStyle.jesusPrayer: Icons.favorite_border_rounded,
    MeditationStyle.chant: Icons.music_note_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How would you like\nto meet with God?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a practice for today.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: MeditationStyle.values.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StyleCard(
                    style: s,
                    icon: _styleIcons[s] ?? Icons.circle_outlined,
                    selected: s == selectedStyle,
                    onTap: () => notifier.setStyle(s),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final MeditationStyle style;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      style.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 1a: Virtue selection ────────────────────────────────────────────────

class VirtueSelectionStep extends StatelessWidget {
  const VirtueSelectionStep({
    super.key,
    required this.selectedVirtue,
    required this.notifier,
  });

  final String? selectedVirtue;
  final MeditationNotifier notifier;

  static const _virtues = [
    'Humility', 'Love', 'Faith', 'Knowledge',
    'Patience', 'Courage', 'Gratitude', 'Temperance',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Which virtue will you\ncultivate today?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Focus on one. Let it shape your day.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: _virtues.map((v) {
                final isSelected = v == selectedVirtue;
                return _SelectionTile(
                  label: v,
                  selected: isSelected,
                  onTap: () => notifier.setVirtueName(v),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1b: Centering word selection ────────────────────────────────────────

class CenteringWordStep extends StatelessWidget {
  const CenteringWordStep({
    super.key,
    required this.selectedWord,
    required this.notifier,
  });

  final String selectedWord;
  final MeditationNotifier notifier;

  static const _words = ['Jesus', 'Abba', 'Mercy', 'Peace', 'Love'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your\nsacred word.',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This word gently returns you to God\'s presence.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _words.map((w) {
              return _SelectionTile(
                label: w,
                selected: w == selectedWord,
                onTap: () => notifier.setCenteringWord(w),
                minWidth: 100,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Step 1c: Jesus Prayer breath pace ────────────────────────────────────────

class BreathPaceStep extends StatelessWidget {
  const BreathPaceStep({
    super.key,
    required this.selectedPace,
    required this.notifier,
  });

  final BreathPace selectedPace;
  final MeditationNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set your breath pace.',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The prayer will follow your natural rhythm.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          ...BreathPace.values.map((p) {
            final isSelected = p == selectedPace;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PaceCard(
                pace: p,
                selected: isSelected,
                onTap: () => notifier.setBreathPace(p),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PaceCard extends StatelessWidget {
  const _PaceCard({
    required this.pace,
    required this.selected,
    required this.onTap,
  });

  final BreathPace pace;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pace.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pace.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 2: Duration selection ────────────────────────────────────────────────

class DurationSelectionStep extends StatelessWidget {
  const DurationSelectionStep({
    super.key,
    required this.selectedMinutes,
    required this.notifier,
  });

  final int selectedMinutes;
  final MeditationNotifier notifier;

  static const _options = [5, 10, 15, 20, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How long will you\nbe still today?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Even five minutes is a gift.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: _options.map((t) {
                final isSelected = t == selectedMinutes;
                return _DurationTile(
                  minutes: t,
                  selected: isSelected,
                  onTap: () => notifier.setSelectedMinutes(t),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$minutes',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
            Text(
              'min',
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.8)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 3: Background sound ──────────────────────────────────────────────────

class SoundSelectionStep extends StatelessWidget {
  const SoundSelectionStep({
    super.key,
    required this.selectedSound,
    required this.notifier,
  });

  final BackgroundSound selectedSound;
  final MeditationNotifier notifier;

  static const _soundIcons = {
    BackgroundSound.ambient: Icons.waves_rounded,
    BackgroundSound.heartbeat: Icons.favorite_rounded,
    BackgroundSound.silent: Icons.volume_off_rounded,
  };

  static const _soundDescriptions = {
    BackgroundSound.ambient: 'Gentle nature sounds to ease you in.',
    BackgroundSound.heartbeat: 'A steady heartbeat rhythm.',
    BackgroundSound.silent: 'Pure silence for deep stillness.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What will you\nhear during prayer?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sound can deepen your focus.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          ...BackgroundSound.values.map((s) {
            final isSelected = s == selectedSound;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SoundCard(
                sound: s,
                icon: _soundIcons[s] ?? Icons.music_note,
                description: _soundDescriptions[s] ?? '',
                selected: isSelected,
                onTap: () => notifier.setBackgroundSound(s),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SoundCard extends StatelessWidget {
  const _SoundCard({
    required this.sound,
    required this.icon,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final BackgroundSound sound;
  final IconData icon;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sound.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared selection tile ─────────────────────────────────────────────────────

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.minWidth,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: BoxConstraints(minWidth: minWidth ?? 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
