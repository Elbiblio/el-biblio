import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../application/meditation_notifier.dart';
import '../../domain/models/meditation_enums.dart';
import '../../domain/models/chant_tracks.dart';
import '../../data/services/improved_audio_service.dart';
import '../../data/services/global_audio_manager.dart';

// Shared widgets for duration, sound, and chant selection steps.

// ── Step 2: Duration selection ────────────────────────────────────────────────

class DurationSelectionStep extends StatelessWidget {
  const DurationSelectionStep({
    super.key,
    required this.selectedMinutes,
    required this.notifier,
    this.onSelectionChanged,
  });

  final int selectedMinutes;
  final MeditationNotifier notifier;
  final VoidCallback? onSelectionChanged;

  static const _options = [5, 10, 15, 20, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
          const SizedBox(height: 4),
          Text(
            'Even five minutes is a gift.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _options.map((t) {
                final isSelected = t == selectedMinutes;
                return _DurationTile(
                  minutes: t,
                  selected: isSelected,
                  onTap: () {
                  notifier.setSelectedMinutes(t);
                  onSelectionChanged?.call();
                },
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
    this.onSelectionChanged,
  });

  final BackgroundSound selectedSound;
  final MeditationNotifier notifier;
  final VoidCallback? onSelectionChanged;

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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SingleChildScrollView(
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
            const SizedBox(height: 4),
            Text(
              'Sound can deepen your focus.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            ...BackgroundSound.values.map((s) {
              final isSelected = s == selectedSound;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SoundCard(
                  sound: s,
                  icon: _soundIcons[s] ?? Icons.music_note,
                  description: _soundDescriptions[s] ?? '',
                  selected: isSelected,
                  onTap: () {
                notifier.setBackgroundSound(s);
                onSelectionChanged?.call();
              },
                ),
              );
            }),
          ],
        ),
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

/// Chant selection step for chant meditation style
class ChantSelectionStep extends ConsumerWidget {
  const ChantSelectionStep({
    super.key,
    required this.notifier,
  });

  final MeditationNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final chants = ChantTracks.allTracks;
    final selectedChantId = ref.watch(meditationProvider.select((state) => state.chosenChantId));
    
    Logger().d('🎵 Building chant selection step with ${chants.length} chants');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a Chant',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select a chant to guide your meditation. Each chant includes voice and instrumental versions.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: ListView.builder(
              itemCount: chants.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final chant = chants[index];
                final isSelected = selectedChantId == chant.id.value;
                Logger().d('🎵 Building chant option $index: ${chant.label} (selected: $isSelected)');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ChantOption(
                    chant: chant,
                    isSelected: isSelected,
                    onTap: () {
                      Logger().d('🎵 Tapped chant: ${chant.label} (${chant.id.value})');
                      notifier.setChant(chant.id.value);
                      Logger().d('🎵 Notified chant selection: ${chant.id.value}');
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChantOption extends StatefulWidget {
  const _ChantOption({
    required this.chant,
    required this.isSelected,
    required this.onTap,
  });

  final ChantTrack chant;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ChantOption> createState() => _ChantOptionState();
}

class _ChantOptionState extends State<_ChantOption> {
  bool _isPreviewing = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  late ImprovedAudioService _audioService;
  String? _preloadedPath;
  final GlobalAudioManager _globalAudioManager = GlobalAudioManager();
  StreamSubscription<void>? _stopSubscription;
  int _activePreviewId = 0;

  @override
  void initState() {
    super.initState();
    _audioService = _globalAudioManager.getAudioService();
    _stopSubscription = _globalAudioManager.onAudioStopped.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPreviewing = false;
        _isDownloading = false;
        _downloadProgress = 0.0;
        _preloadedPath = null;
        _activePreviewId = 0;
        _audioService = _globalAudioManager.getAudioService();
      });
    });
    Logger().d('🎵 Initialized improved audio service for chant: ${widget.chant.label}');
  }

  @override
  void dispose() {
    _stopSubscription?.cancel();
    super.dispose();
  }

  // Preload chant when user long presses or hovers (optional enhancement)
  Future<void> _preloadChant() async {
    if (widget.chant.voiceKey == null || _preloadedPath != null) return;

    final urlOrAsset = widget.chant.voiceKey!;
    Logger().d('🎵 Preloading chant for instant playback: ${widget.chant.label}');

    _preloadedPath = await _audioService.preloadChant(urlOrAsset);
  }

  Future<void> _previewVoice() async {
    if (widget.chant.voiceKey == null) {
      Logger().d('🎵 No voice key for chant: ${widget.chant.label}');
      return;
    }
    
    Logger().d('🎵 Starting instant preview for: ${widget.chant.label}');
    
    // Stop any existing preview audio first
    await _globalAudioManager.stopAllAudio();
    _audioService = _globalAudioManager.getAudioService();
    final previewId = DateTime.now().microsecondsSinceEpoch;
    _activePreviewId = previewId;
    
    if (mounted) {
      setState(() {
        _isPreviewing = true;
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }

    final urlOrAsset = widget.chant.voiceKey!;
    final filename = urlOrAsset.split('/').last;

    try {
      Logger().d('🎵 Playing chant from: $urlOrAsset');
      
      // For asset files, play directly
      if (urlOrAsset.startsWith('assets/')) {
        final played = await _audioService.playChant(urlOrAsset, filename);
        if (!played) {
          throw Exception('Failed to play chant from asset');
        }
      } else {
        // Try preloaded source first for instant playback
        if (_preloadedPath != null) {
          Logger().d('🎵 Using preloaded source for instant playback');
          final played = await _audioService.playPreloadedChant(_preloadedPath!);
          if (!played) {
            throw Exception('Failed to play preloaded chant');
          }
        } else {
          // For remote URLs, stream directly for instant preview
          Logger().d('🎵 Streaming chant from: $urlOrAsset');
          
          // Try streaming first for instant playback
          final streamed = await _audioService.playStreamingAudio(urlOrAsset);
          if (!streamed) {
            // If streaming fails, fallback to download + play
            Logger().d('🎵 Streaming failed, downloading for playback');
            if (mounted) {
              setState(() {
                _isDownloading = true;
                _downloadProgress = 0.0;
              });
            }
            
            final success = await _audioService.downloadAudio(
              urlOrAsset,
              filename,
              isChant: true,
              onProgress: (received, total) {
                if (total > 0 && mounted) {
                  setState(() {
                    _downloadProgress = received / total;
                  });
                }
              },
            );
            
            if (!success) {
              throw Exception('Failed to download chant');
            }
            
            Logger().d('🎵 Download complete, playing preview');
            if (mounted) {
              setState(() {
                _isDownloading = false;
              });
            }
            
            final played = await _audioService.playChant(urlOrAsset, filename, isVoice: true);
            if (!played) {
              throw Exception('Failed to play chant');
            }
          }
        }
      }
      
      // Auto-stop after 15 seconds
      await Future.delayed(const Duration(seconds: 15));
      if (!mounted || _activePreviewId != previewId) {
        return;
      }
      Logger().d('🎵 Auto-stopping preview after 15 seconds');
      await _globalAudioManager.stopAllAudio();
    } catch (e) {
      Logger().e('🎵 Error during preview: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isPreviewing = false;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Audio playback failed'),
                const SizedBox(height: 4),
                Text(
                  'The audio file may be temporarily unavailable or there may be network issues.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (urlOrAsset.startsWith('http'))
                  Text(
                    'File: ${urlOrAsset.split('/').last}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 4),
                Text(
                  'Trying alternative playback methods...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                _previewVoice(); // Retry the preview
              },
            ),
          ),
        );
      }
    }
  }

  void _stopPreview() async {
    _activePreviewId = 0;
    await _globalAudioManager.stopAllAudio();
    if (mounted) {
      setState(() {
        _isPreviewing = false;
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }
    Logger().d('🎵 Preview stopped');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.isSelected 
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        border: Border.all(
          color: widget.isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.8)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: widget.isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Selection indicator
                  if (widget.isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  else
                    Icon(
                      Icons.music_note_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.chant.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: widget.isSelected 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  // Preview button
                  if (widget.chant.voiceKey != null)
                    _isDownloading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: _downloadProgress,
                            ),
                          )
                        : GestureDetector(
                            onLongPress: _preloadChant,
                            child: IconButton(
                              onPressed: () {
                                // When preview is pressed, also select the chant
                                if (!widget.isSelected) {
                                  widget.onTap();
                                }
                                if (_isPreviewing) {
                                  _stopPreview();
                                } else {
                                  _previewVoice();
                                }
                              },
                              icon: Icon(
                                _isPreviewing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              tooltip: _isPreviewing ? 'Stop preview' : 'Preview chant (long press to preload)',
                            ),
                          ),
                ],
              ),
              const SizedBox(height: 6),
              // Show first cue only to save space
              if (widget.chant.cues.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    widget.chant.cues.first,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 4),
              // Audio type indicators
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Row(
                  children: [
                    if (widget.chant.voiceKey != null) ...[
                      Icon(
                        Icons.mic_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Voice',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    if (widget.chant.voiceKey != null && widget.chant.instrumentalKey != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.piano_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Instrumental',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

