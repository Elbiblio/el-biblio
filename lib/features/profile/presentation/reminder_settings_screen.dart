import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_providers.dart';
import '../../../core/theme/app_theme_tokens.dart';

class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    
    final primaryTextColor = theme.colorScheme.onSurface;
    final mutedTextColor = tokens.palette.textSecondary;
    final surfaceColor = theme.colorScheme.surface;
    final borderColor = tokens.palette.border;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryTextColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Daily Rhythm',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: primaryTextColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR RHYTHM',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: mutedTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Set the times for your morning and evening spiritual practices. We will send you a gentle nudge to help you stay consistent.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: primaryTextColor.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Morning Anchor
              _buildReminderCard(
                context: context,
                title: 'Morning Anchor',
                description: 'Daily preparation for spiritual clarity and mindful presence.',
                time: settings.morningTime,
                isEnabled: settings.morningReminderEnabled,
                icon: Icons.wb_sunny_outlined,
                primaryTextColor: primaryTextColor,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                onToggle: (val) {
                  final current = ref.read(settingsProvider);
                  ref.read(settingsProvider.notifier).completeOnboarding(
                        primaryVirtue: current.primaryVirtue,
                        lifestyle: current.lifestyle,
                        morningTime: current.morningTime,
                        eveningTime: current.eveningTime,
                        morningReminderEnabled: val,
                        eveningReminderEnabled: current.eveningReminderEnabled,
                        socialPresenceOptIn: current.socialPresenceOptIn,
                        contactsImported: current.contactsImported,
                      );
                },
                onTimeTapped: () => _selectTime(context, settings.morningTime, (newTime) {
                  final current = ref.read(settingsProvider);
                  ref.read(settingsProvider.notifier).completeOnboarding(
                        primaryVirtue: current.primaryVirtue,
                        lifestyle: current.lifestyle,
                        morningTime: newTime,
                        eveningTime: current.eveningTime,
                        morningReminderEnabled: current.morningReminderEnabled,
                        eveningReminderEnabled: current.eveningReminderEnabled,
                        socialPresenceOptIn: current.socialPresenceOptIn,
                        contactsImported: current.contactsImported,
                      );
                }),
              ),
              
              const SizedBox(height: 16),
              
              // Evening Review
              _buildReminderCard(
                context: context,
                title: 'Evening Review',
                description: 'Reflect on your day\'s blessings, challenges, and growth opportunities.',
                time: settings.eveningTime,
                isEnabled: settings.eveningReminderEnabled,
                icon: Icons.bedtime_outlined,
                primaryTextColor: primaryTextColor,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                onToggle: (val) {
                  final current = ref.read(settingsProvider);
                  ref.read(settingsProvider.notifier).completeOnboarding(
                        primaryVirtue: current.primaryVirtue,
                        lifestyle: current.lifestyle,
                        morningTime: current.morningTime,
                        eveningTime: current.eveningTime,
                        morningReminderEnabled: current.morningReminderEnabled,
                        eveningReminderEnabled: val,
                        socialPresenceOptIn: current.socialPresenceOptIn,
                        contactsImported: current.contactsImported,
                      );
                },
                onTimeTapped: () => _selectTime(context, settings.eveningTime, (newTime) {
                  final current = ref.read(settingsProvider);
                  ref.read(settingsProvider.notifier).completeOnboarding(
                        primaryVirtue: current.primaryVirtue,
                        lifestyle: current.lifestyle,
                        morningTime: current.morningTime,
                        eveningTime: newTime,
                        morningReminderEnabled: current.morningReminderEnabled,
                        eveningReminderEnabled: current.eveningReminderEnabled,
                        socialPresenceOptIn: current.socialPresenceOptIn,
                        contactsImported: current.contactsImported,
                      );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, String currentTime, Function(String) onTimeSelected) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final formattedHour = selectedTime.hour.toString().padLeft(2, '0');
      final formattedMinute = selectedTime.minute.toString().padLeft(2, '0');
      onTimeSelected('$formattedHour:$formattedMinute');
    }
  }

  Widget _buildReminderCard({
    required BuildContext context,
    required String title,
    required String description,
    required String time,
    required bool isEnabled,
    required IconData icon,
    required Color primaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTimeTapped,
  }) {
    final timeParts = time.split(':');
    final timeOfDay = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
    final displayTime = timeOfDay.format(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: onToggle,
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: primaryTextColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: onTimeTapped,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayTime,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: primaryTextColor,
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
