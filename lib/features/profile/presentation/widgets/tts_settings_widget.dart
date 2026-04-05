import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/di/app_providers.dart';

/// Widget for TTS voice selection settings
class TTSSettingsWidget extends ConsumerStatefulWidget {
  const TTSSettingsWidget({super.key});

  @override
  ConsumerState<TTSSettingsWidget> createState() => _TTSSettingsWidgetState();
}

class _TTSSettingsWidgetState extends ConsumerState<TTSSettingsWidget> {
  bool _isLoading = false;
  String? _testText;

  @override
  void initState() {
    super.initState();
    _testText = 'This is how your selected voice sounds.';
  }

  Future<void> _testVoice(String voiceKey) async {
    setState(() => _isLoading = true);
    
    try {
      final ttsService = TTSService();
      ttsService.setVoice(voiceKey);
      await ttsService.speak(_testText!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to test voice: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateVoice(String voiceKey) async {
    setState(() => _isLoading = true);
    
    try {
      await ref.read(settingsStorageProvider).updateTTSVoice(voiceKey);
      
      // Update the TTS service with new voice
      final ttsService = TTSService();
      ttsService.setVoice(voiceKey);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update voice: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.record_voice_over,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Text-to-Speech Voice',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Voice descriptions
            const Text(
              'Choose the voice for meditation guidance and Bible verse reading:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // Voice options
            ..._buildVoiceOptions(settings.selectedTTSVoice),
            
            const SizedBox(height: 16),
            
            // Test section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Current Voice',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _testText!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _isLoading ? null : () => _testVoice(settings.selectedTTSVoice),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.play_arrow),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Cache info
            FutureBuilder<Map<String, dynamic>>(
              future: () async {
                final tts = TTSService();
                await tts.initialize(selectedVoice: settings.selectedTTSVoice);
                return tts.getCacheInfo();
              }(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final cacheInfo = snapshot.data!;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, 
                             size: 16, 
                             color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Cached audio files: ${cacheInfo['cached_items']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final tts = TTSService();
                            await tts.clearCache();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cache cleared')),
                            );
                            setState(() {});
                          },
                          child: const Text('Clear Cache'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildVoiceOptions(String currentVoice) {
    final ttsService = TTSService();
    final availableVoices = ttsService.getAvailableVoices();
    
    return availableVoices.entries.map((entry) {
      final voiceKey = entry.key;
      final voiceId = entry.value;
      final isSelected = currentVoice == voiceKey;
      
      return _buildVoiceOption(
        voiceKey: voiceKey,
        voiceId: voiceId,
        isSelected: isSelected,
        currentVoice: currentVoice,
      );
    }).toList();
  }

  Widget _buildVoiceOption({
    required String voiceKey,
    required String voiceId,
    required bool isSelected,
    required String currentVoice,
  }) {
    final voiceNames = {
      'default': 'Default Voice',
      'alternative1': 'Alternative Voice 1',
      'alternative2': 'Alternative Voice 2',
    };
    
    final voiceDescriptions = {
      'default': 'Natural, balanced voice perfect for meditation',
      'alternative1': 'Deeper, more resonant voice for contemplation',
      'alternative2': 'Softer, gentler voice for relaxation',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected 
            ? Theme.of(context).colorScheme.primaryContainer 
            : null,
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade400,
        ),
        title: Text(
          voiceNames[voiceKey] ?? voiceKey,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          voiceDescriptions[voiceKey] ?? 'Voice option',
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Colors.grey.shade600,
          ),
        ),
        trailing: IconButton.filled(
          onPressed: _isLoading ? null : () => _testVoice(voiceKey),
          icon: const Icon(Icons.play_arrow),
          tooltip: 'Test voice',
        ),
        onTap: _isLoading ? null : () => _updateVoice(voiceKey),
      ),
    );
  }
}
