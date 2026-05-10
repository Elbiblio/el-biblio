import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../domain/vision_models.dart';

class HangoutRoomScreen extends ConsumerStatefulWidget {
  const HangoutRoomScreen({
    super.key,
    required this.hangout,
    required this.credentials,
    this.onLeave,
  });

  final CommitmentHangout hangout;
  final LiveKitRoomCredentials credentials;
  final Future<void> Function()? onLeave;

  @override
  ConsumerState<HangoutRoomScreen> createState() => _HangoutRoomScreenState();
}

class _HangoutRoomScreenState extends ConsumerState<HangoutRoomScreen> {
  late final lk.Room _room;
  bool _connecting = true;
  bool _micEnabled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _room = lk.Room();
    _room.addListener(_onRoomChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
  }

  @override
  void dispose() {
    _room.removeListener(_onRoomChanged);
    _room.disconnect();
    _room.dispose();
    super.dispose();
  }

  void _onRoomChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _connect() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      setState(() {
        _connecting = false;
        _error = 'Microphone permission is needed to join this hangout.';
      });
      return;
    }

    try {
      await _room.connect(widget.credentials.url, widget.credentials.token);
      await _room.localParticipant?.setMicrophoneEnabled(true);
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _micEnabled = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = 'We could not connect to the audio room.';
      });
    }
  }

  Future<void> _toggleMic() async {
    final next = !_micEnabled;
    await _room.localParticipant?.setMicrophoneEnabled(next);
    if (mounted) setState(() => _micEnabled = next);
  }

  Future<void> _leave() async {
    await _room.disconnect();
    await widget.onLeave?.call();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final participantCount = _room.remoteParticipants.length + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hangout.title),
        actions: [
          IconButton(
            tooltip: 'Invite someone',
            onPressed: () => context.push(
              '${AppRoutes.invite}?source=hangout&hangout_id=${widget.hangout.id}&scope_type=${Uri.encodeQueryComponent(widget.hangout.scopeType)}&scope_id=${widget.hangout.scopeId ?? ''}',
            ),
            icon: const Icon(LucideIcons.send),
          ),
          PopupMenuButton<String>(
            tooltip: 'Room safety',
            icon: const Icon(LucideIcons.shieldAlert),
            onSelected: _reportHangout,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'unsafe_or_crisis',
                child: Text('Report safety concern'),
              ),
              PopupMenuItem(
                value: 'harassment_or_shame',
                child: Text('Report harassment'),
              ),
              PopupMenuItem(
                value: 'spam_or_misuse',
                child: Text('Report spam or misuse'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _roomTitle(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _connecting
                    ? 'Connecting to audio...'
                    : _error ??
                          '$participantCount people are in the room. Speak gently and keep it honest.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              _RoomAgreementPanel(error: _error),
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: CircleAvatar(
                    radius: 74,
                    child: Icon(
                      _error == null ? LucideIcons.radio : LucideIcons.wifiOff,
                      size: 54,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _connecting
                          ? null
                          : _error != null
                          ? openAppSettings
                          : _toggleMic,
                      icon: Icon(
                        _error != null
                            ? LucideIcons.settings
                            : _micEnabled
                            ? LucideIcons.mic
                            : LucideIcons.micOff,
                        size: 18,
                      ),
                      label: Text(
                        _error != null
                            ? 'Open settings'
                            : _micEnabled
                            ? 'Mute'
                            : 'Unmute',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _leave,
                      icon: const Icon(LucideIcons.phoneOff, size: 18),
                      label: const Text('Leave'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reportHangout(String reason) async {
    final reported = await ref
        .read(visionProvider.notifier)
        .reportHangout(widget.hangout, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reported
              ? 'Thanks. We will review this room.'
              : 'We could not send the report. Please try again.',
        ),
      ),
    );
  }

  String _roomTitle() {
    return switch (widget.hangout.scopeType) {
      'tribe' => 'Tribe hangout',
      'everyone' => 'Live gathering',
      _ => 'Live gathering',
    };
  }
}

class _RoomAgreementPanel extends StatelessWidget {
  const _RoomAgreementPanel({required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error == null ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Small rooms work best with prayer, consent, and no fixing. Share only what you choose; report anything unsafe or shaming.',
            ),
          ),
        ],
      ),
    );
  }
}
