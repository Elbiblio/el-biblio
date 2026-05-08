import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/vision_models.dart';

class HangoutRoomScreen extends StatefulWidget {
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
  State<HangoutRoomScreen> createState() => _HangoutRoomScreenState();
}

class _HangoutRoomScreenState extends State<HangoutRoomScreen> {
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
      appBar: AppBar(title: Text(widget.hangout.title)),
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
                      onPressed: _connecting || _error != null
                          ? null
                          : _toggleMic,
                      icon: Icon(
                        _micEnabled ? LucideIcons.mic : LucideIcons.micOff,
                        size: 18,
                      ),
                      label: Text(_micEnabled ? 'Mute' : 'Unmute'),
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

  String _roomTitle() {
    return switch (widget.hangout.scopeType) {
      'tribe' => 'Tribe hangout',
      'everyone' => 'Open hangout',
      _ => 'Commitment hangout',
    };
  }
}
