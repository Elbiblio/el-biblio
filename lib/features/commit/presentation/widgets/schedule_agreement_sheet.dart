import 'package:flutter/material.dart';

import '../../domain/models/commitment_schedule.dart';

class ScheduleAgreementSheet extends StatefulWidget {
  const ScheduleAgreementSheet({
    super.key,
    required this.commitmentId,
  });

  final int commitmentId;

  @override
  State<ScheduleAgreementSheet> createState() => _ScheduleAgreementSheetState();
}

class _ScheduleAgreementSheetState extends State<ScheduleAgreementSheet> {
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  final List<int> _activeDays = List.generate(7, (i) => i + 1);
  int _skipDays = 2;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 32, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'When should we check in?',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Set 1-3 times per day. We\'ll send a rich notification overlay you need to respond to.',
              style: textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text('Check-in Times', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...List.generate(_times.length, (i) => _TimePickerRow(
              index: i,
              time: _times[i],
              canRemove: _times.length > 1,
              onChange: (t) => setState(() => _times[i] = t),
              onRemove: () => setState(() => _times.removeAt(i)),
            )),
            if (_times.length < 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    final last = _times.last;
                    _times.add(TimeOfDay(
                      hour: last.hour + 4 > 23 ? last.hour : last.hour + 4,
                      minute: last.minute,
                    ));
                  }),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add another time'),
                ),
              ),
            const SizedBox(height: 24),
            Text('Active Days', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Which days should we check in?',
              style: textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final dayNum = i + 1;
                final selected = _activeDays.contains(dayNum);
                return FilterChip(
                  label: Text(_dayLabels[i]),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) { _activeDays.add(dayNum); _activeDays.sort(); }
                    else if (_activeDays.length > 1) { _activeDays.remove(dayNum); }
                  }),
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                );
              }),
            ),
            const SizedBox(height: 24),
            Text('Skip Days', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'How many days per week can you skip without penalty?',
              style: textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _SkipDaysButton(
                  label: '0', subtitle: 'Strict',
                  selected: _skipDays == 0,
                  onTap: () => setState(() => _skipDays = 0),
                ),
                const SizedBox(width: 8),
                _SkipDaysButton(
                  label: '1-2', subtitle: 'Flexible',
                  selected: _skipDays == 2,
                  onTap: () => setState(() => _skipDays = 2),
                ),
                const SizedBox(width: 8),
                _SkipDaysButton(
                  label: '3', subtitle: 'Gentle',
                  selected: _skipDays == 3,
                  onTap: () => setState(() => _skipDays = 3),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  final schedule = CommitmentSchedule(
                    commitmentId: widget.commitmentId,
                    checkInTimes: _times,
                    activeDays: _activeDays,
                    skipDaysAllowed: _skipDays,
                    overlayEnabled: true,
                  );
                  Navigator.of(context).pop(schedule);
                },
                child: const Text('Save schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  const _TimePickerRow({
    required this.index,
    required this.time,
    required this.canRemove,
    required this.onChange,
    required this.onRemove,
  });

  final int index;
  final TimeOfDay time;
  final bool canRemove;
  final ValueChanged<TimeOfDay> onChange;
  final VoidCallback onRemove;

  String _display(TimeOfDay t) {
    final hour = t.hourOfPeriod;
    final amPm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:${t.minute.toString().padLeft(2, '0')} $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: time);
                if (picked != null) onChange(picked);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(_display(time), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          if (canRemove)
            IconButton(
              icon: Icon(Icons.remove_circle_outline, size: 20, color: theme.colorScheme.error),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _SkipDaysButton extends StatelessWidget {
  const _SkipDaysButton({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary.withValues(alpha: 0.08) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.14),
            ),
          ),
          child: Column(
            children: [
              Text(label, style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: selected ? theme.colorScheme.primary : null,
              )),
              Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
