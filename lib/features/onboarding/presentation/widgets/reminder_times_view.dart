import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/services/haptic_service.dart';

/// Phase 3 – screen 3: choose reminder times and accountability cadence.
///
/// Three anchors:
///   • Morning prayer/verse
///   • Evening review
///   • Partner check-in cadence (daily by default; weekly only if the
///     user has already demonstrated a strong baseline)
class ReminderTimesView extends ConsumerStatefulWidget {
  const ReminderTimesView({
    super.key,
    required this.onContinue,
    required this.baselineStrong,
  });

  final VoidCallback onContinue;

  /// Whether the user's christian-life baseline is strong enough to
  /// justify a weekly partner cadence instead of the daily default.
  final bool baselineStrong;

  @override
  ConsumerState<ReminderTimesView> createState() =>
      _ReminderTimesViewState();
}

class _ReminderTimesViewState extends ConsumerState<ReminderTimesView> {
  late TimeOfDay _morning;
  late TimeOfDay _evening;
  late bool _morningEnabled;
  late bool _eveningEnabled;
  late String _cadence;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _morning = _parse(s.morningTime);
    _evening = _parse(s.eveningTime);
    _morningEnabled = s.morningReminderEnabled;
    _eveningEnabled = s.eveningReminderEnabled;
    _cadence = s.accountabilityCadence;
  }

  TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 7,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isMorning}) async {
    HapticService.selection();
    final picked = await showTimePicker(
      context: context,
      initialTime: isMorning ? _morning : _evening,
    );
    if (picked == null) return;
    setState(() {
      if (isMorning) {
        _morning = picked;
      } else {
        _evening = picked;
      }
    });
  }

  Future<void> _commit() async {
    HapticService.light();
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.updateReminderPreferences(
      morningTime: _fmt(_morning),
      eveningTime: _fmt(_evening),
      morningReminderEnabled: _morningEnabled,
      eveningReminderEnabled: _eveningEnabled,
    );
    await notifier.setAccountabilityCadence(_cadence);
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'When should we find you?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Two gentle nudges a day — morning and evening — plus your partner check-in. Pick what fits your real life.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _timeTile(
            theme,
            icon: Icons.wb_sunny_outlined,
            label: 'Morning anchor',
            time: _morning,
            enabled: _morningEnabled,
            onTap: () => _pickTime(isMorning: true),
            onToggle: (v) => setState(() => _morningEnabled = v),
          ),
          const SizedBox(height: 12),
          _timeTile(
            theme,
            icon: Icons.nights_stay_outlined,
            label: 'Evening review',
            time: _evening,
            enabled: _eveningEnabled,
            onTap: () => _pickTime(isMorning: false),
            onToggle: (v) => setState(() => _eveningEnabled = v),
          ),
          const SizedBox(height: 24),
          Text(
            'PARTNER CHECK-IN',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _cadenceTile(
                  theme,
                  value: 'daily',
                  label: 'Daily',
                  sublabel: 'A small share each evening',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _cadenceTile(
                  theme,
                  value: 'weekly',
                  label: 'Weekly',
                  sublabel: widget.baselineStrong
                      ? 'Fridays at 7pm'
                      : 'Recommended once your daily rhythm is strong',
                  dim: !widget.baselineStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _commit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _timeTile(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required TimeOfDay time,
    required bool enabled,
    required VoidCallback onTap,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: enabled ? onTap : null,
                  child: Text(
                    _fmt(time),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: enabled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.35),
                      fontWeight: FontWeight.w500,
                      decoration: enabled ? TextDecoration.underline : null,
                      decorationColor: theme.colorScheme.primary
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: enabled, onChanged: onToggle),
        ],
      ),
    );
  }

  Widget _cadenceTile(
    ThemeData theme, {
    required String value,
    required String label,
    required String sublabel,
    bool dim = false,
  }) {
    final isSelected = _cadence == value;
    return GestureDetector(
      onTap: dim && !isSelected
          ? null
          : () {
              HapticService.selection();
              setState(() => _cadence = value);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.45)
                : theme.colorScheme.outline.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: dim && !isSelected
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
                    : (isSelected ? theme.colorScheme.primary : null),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sublabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
