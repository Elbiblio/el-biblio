#!/usr/bin/env dart

import 'dart:io';
import 'dart:math';

/// Generate placeholder audio files for TTS fallback
/// Run with: dart scripts/generate_audio_files.dart

void main() async {
  stdout.writeln('Generating placeholder audio files...');
  
  // Generate countdown files
  for (int i = 1; i <= 10; i++) {
    await generateToneFile('assets/audio/countdown/$i.mp3', 440 + (i * 50), 1000);
    stdout.writeln('Generated: $i.mp3');
  }
  
  // Generate prompt files (using different frequencies)
  final prompts = [
    'begin_meditation.mp3',
    'focus_breath.mp3', 
    'return_awareness.mp3',
    'let_go_thoughts.mp3',
    'breathe_deeply.mp3',
    'find_comfort.mp3'
  ];
  
  for (int i = 0; i < prompts.length; i++) {
    await generateToneFile('assets/audio/prompts/${prompts[i]}', 300 + (i * 100), 2000);
    stdout.writeln('Generated: ${prompts[i]}');
  }
  
  // Generate chime file
  await generateToneFile('assets/audio/chime-gentle.mp3', 800, 500);
  stdout.writeln('Generated: chime-gentle.mp3');
  
  stdout.writeln('All audio files generated successfully!');
}

/// Generate a simple sine wave tone and save as WAV file
Future<void> generateToneFile(String path, int frequency, int durationMs) async {
  const sampleRate = 44100;
  final numSamples = (durationMs * sampleRate) ~/ 1000;
  final bytes = <int>[];
  
  // WAV header
  final header = <int>[];
  header.addAll('RIFF'.codeUnits);
  header.addAll(_intToBytes(36 + numSamples * 2, 4));
  header.addAll('WAVE'.codeUnits);
  header.addAll('fmt '.codeUnits);
  header.addAll(_intToBytes(16, 4)); // Subchunk size
  header.addAll(_intToBytes(1, 2));  // Audio format (PCM)
  header.addAll(_intToBytes(1, 2));  // Number of channels
  header.addAll(_intToBytes(sampleRate, 4)); // Sample rate
  header.addAll(_intToBytes(sampleRate * 2, 4)); // Byte rate
  header.addAll(_intToBytes(2, 2));  // Block align
  header.addAll(_intToBytes(16, 2)); // Bits per sample
  header.addAll('data'.codeUnits);
  header.addAll(_intToBytes(numSamples * 2, 4)); // Data size
  
  bytes.addAll(header);
  
  // Generate sine wave data
  for (int i = 0; i < numSamples; i++) {
    final angle = 2 * pi * frequency * i / sampleRate;
    final sample = (sin(angle) * 16383).round();
    bytes.addAll(_intToBytes(sample, 2));
  }
  
  // Ensure directory exists
  final file = File(path);
  await file.parent.create(recursive: true);
  
  // Write file
  await file.writeAsBytes(bytes);
}

List<int> _intToBytes(int value, int numBytes) {
  final bytes = <int>[];
  for (int i = 0; i < numBytes; i++) {
    bytes.add((value >> (i * 8)) & 0xFF);
  }
  return bytes;
}
