import 'package:flutter/material.dart';

class CommitmentMediaCatalog {
  const CommitmentMediaCatalog._();

  static CommitmentMedia getMedia(String category) {
    return _media[category] ?? _media['growth']!;
  }

  static const Map<String, CommitmentMedia> _media = {
    'prayer': CommitmentMedia(
      category: 'prayer',
      backgroundImage: 'assets/images/backdrops/prayer.jpg',
      ambientSound: 'assets/audio/ambient/stars.mp3',
      accentColor: Color(0xFFFFB74D),
      mood: 'contemplative',
    ),
    'bible': CommitmentMedia(
      category: 'bible',
      backgroundImage: 'assets/images/backdrops/bible.jpg',
      ambientSound: 'assets/audio/ambient/field.mp3',
      accentColor: Color(0xFF81C784),
      mood: 'peaceful',
    ),
    'discipline': CommitmentMedia(
      category: 'discipline',
      backgroundImage: 'assets/images/backdrops/mountain.jpg',
      ambientSound: 'assets/audio/ambient/mountain.mp3',
      accentColor: Color(0xFF64B5F6),
      mood: 'determined',
    ),
    'service': CommitmentMedia(
      category: 'service',
      backgroundImage: 'assets/images/backdrops/community.jpg',
      ambientSound: 'assets/audio/ambient/community.mp3',
      accentColor: Color(0xFFFF8A65),
      mood: 'warm',
    ),
    'growth': CommitmentMedia(
      category: 'growth',
      backgroundImage: 'assets/images/backdrops/garden.jpg',
      ambientSound: 'assets/audio/ambient/ambient-today.mp3',
      accentColor: Color(0xFF4CAF50),
      mood: 'hopeful',
    ),
    'health': CommitmentMedia(
      category: 'health',
      backgroundImage: 'assets/images/backdrops/forest.jpg',
      ambientSound: 'assets/audio/ambient/forest.mp3',
      accentColor: Color(0xFF66BB6A),
      mood: 'refreshed',
    ),
    'faith': CommitmentMedia(
      category: 'faith',
      backgroundImage: 'assets/images/backdrops/stars.jpg',
      ambientSound: 'assets/audio/ambient/stars.mp3',
      accentColor: Color(0xFF7E57C2),
      mood: 'awe',
    ),
    'relationships': CommitmentMedia(
      category: 'relationships',
      backgroundImage: 'assets/images/backdrops/sunset.jpg',
      ambientSound: 'assets/audio/ambient/sunset.mp3',
      accentColor: Color(0xFFEC407A),
      mood: 'tender',
    ),
  };
}

class CommitmentMedia {
  final String category;
  final String backgroundImage;
  final String? ambientSound;
  final Color accentColor;
  final String mood;

  const CommitmentMedia({
    required this.category,
    required this.backgroundImage,
    this.ambientSound,
    required this.accentColor,
    required this.mood,
  });
}
