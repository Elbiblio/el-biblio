import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SchedulePickerWidget extends StatefulWidget {
  const SchedulePickerWidget({
    super.key,
    this.initialTimes = const [],
    this.onChanged,
    this.maxTimes = 3,
  });

  final List<TimeOfDay> initialTimes;
  final ValueChanged<List<TimeOfDay>>? onChanged;
  final int maxTimes;

  @override
  State<SchedulePickerWidget> createState() => _SchedulePickerWidgetState();
}

class _SchedulePickerWidgetState extends State<SchedulePickerWidget> {
  late List<TimeOfDay> _times;

  @override
  void initState() {
    super.initState();
    _times = List.from(widget.initialTimes);
  }

  void _addTime() async {
    if (_times.length >= widget.maxTimes) return;

    final defaultTime = _times.isNotEmpty
        ? TimeOfDay(
            hour: _times.last.hour + 4,
            minute: 0,
          )
        : const TimeOfDay(hour: 8, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: defaultTime.hour < 24 ? defaultTime : const TimeOfDay(hour: 8, minute: 0),
      helpText: 'When should we check in?',
    );
    if (picked == null || !mounted) return;

    setState(() {
      _times.add(picked);
      _times.sort((a, b) => a.hour == b.hour
          ? a.minute.compareTo(b.minute)
          : a.hour.compareTo(b.hour));
    });
    widget.onChanged?.call(List.from(_times));
  }

  void _removeTime(int index) {
    setState(() => _times.removeAt(index));
    widget.onChanged?.call(List.from(_times));
  }

  void _editTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
      helpText: 'Adjust check-in time',
    );
    if (picked == null || !mounted) return;

    setState(() {
      _times[index] = picked;
      _times.sort((a, b) => a.hour == b.hour
          ? a.minute.compareTo(b.minute)
          : a.hour.compareTo(b.hour));
    });
    widget.onChanged?.call(List.from(_times));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Check-in times',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_times.length}/${widget.maxTimes}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'We\'ll send rich notification overlays at these times.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        if (_times.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 32,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap below to add your first check-in time',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_times.length, (i) {
            final time = _times[i];
            final label = _periodLabel(time);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            time.format(context),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.pencil, size: 16),
                      onPressed: () => _editTime(i),
                      tooltip: 'Edit time',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () => _removeTime(i),
                      tooltip: 'Remove time',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            );
          }),
        if (_times.length < widget.maxTimes) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addTime,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add check-in time'),
            ),
          ),
        ],
      ],
    );
  }

  String _periodLabel(TimeOfDay time) {
    final hour = time.hour;
    return switch (hour) {
      < 6 => 'Early morning',
      < 9 => 'Morning',
      < 12 => 'Late morning',
      < 14 => 'Noon',
      < 17 => 'Afternoon',
      < 20 => 'Evening',
      _ => 'Night',
    };
  }
}
