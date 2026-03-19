import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elbiblio/core/services/notifications/notification_service.dart';
import 'package:elbiblio/core/di/app_providers.dart';

class NotificationTestScreen extends ConsumerStatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  ConsumerState<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends ConsumerState<NotificationTestScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Notification Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () async {
                final now = DateTime.now();
                await _notificationService.scheduleRichNotification(
                  id: 999,
                  title: 'Morning Anchor',
                  body: 'Start your day with Scripture and reflection',
                  channel: 'morning_anchors',
                  scheduledTime: now.add(const Duration(minutes: 1)),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Morning notification scheduled for 1 minute from now')),
                );
              },
              child: const Text('Test Morning Notification (1 min)'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () async {
                final now = DateTime.now();
                await _notificationService.scheduleRichNotification(
                  id: 998,
                  title: 'Evening Review',
                  body: 'End your day with the Daily Examen',
                  channel: 'evening_review',
                  scheduledTime: now.add(const Duration(minutes: 1)),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evening notification scheduled for 1 minute from now')),
                );
              },
              child: const Text('Test Evening Notification (1 min)'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () async {
                await _notificationService.cancelNotification(999);
                await _notificationService.cancelNotification(998);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notifications cancelled')),
                );
              },
              child: const Text('Cancel Test Notifications'),
            ),
            
            const SizedBox(height: 24),
            
            const Divider(),
            
            const SizedBox(height: 12),
            
            Text(
              'Current Settings:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Morning Reminder: ${settings.morningReminderEnabled ? "Enabled" : "Disabled"}'),
            Text('Morning Time: ${settings.morningTime}'),
            Text('Evening Reminder: ${settings.eveningReminderEnabled ? "Enabled" : "Disabled"}'),
            Text('Evening Time: ${settings.eveningTime}'),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () async {
                // Trigger a sync of notifications based on current settings
                final notifier = ref.read(settingsProvider.notifier);
                await notifier.completeOnboarding(
                  primaryVirtue: settings.primaryVirtue,
                  lifestyle: settings.lifestyle,
                  morningTime: settings.morningTime,
                  eveningTime: settings.eveningTime,
                  morningReminderEnabled: settings.morningReminderEnabled,
                  eveningReminderEnabled: settings.eveningReminderEnabled,
                  socialPresenceOptIn: settings.socialPresenceOptIn,
                  contactsImported: settings.contactsImported,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications synced with current settings')),
                );
              },
              child: const Text('Sync Notifications with Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
