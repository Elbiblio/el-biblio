import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/alignment_repository.dart';
import '../domain/models/spiritual_profile.dart';
import '../domain/models/career_alignment.dart';
import '../../assessment/domain/models/archetype.dart';

class AlignmentState {
  final SpiritualProfile? currentProfile;
  final List<SpiritualProfile> previousProfiles;
  final CareerAlignment? careerAlignment;
  final bool isLoading;
  final String? error;

  const AlignmentState({
    this.currentProfile,
    this.previousProfiles = const [],
    this.careerAlignment,
    this.isLoading = false,
    this.error,
  });

  AlignmentState copyWith({
    SpiritualProfile? currentProfile,
    List<SpiritualProfile>? previousProfiles,
    CareerAlignment? careerAlignment,
    bool? isLoading,
    String? error,
  }) {
    return AlignmentState(
      currentProfile: currentProfile ?? this.currentProfile,
      previousProfiles: previousProfiles ?? this.previousProfiles,
      careerAlignment: careerAlignment ?? this.careerAlignment,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AlignmentNotifier extends StateNotifier<AlignmentState> {
  AlignmentNotifier(this._repository) : super(const AlignmentState());

  final AlignmentRepository _repository;

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repository.getSpiritualProfile();
      final previous = await _repository.getPreviousProfiles();
      CareerAlignment? career;
      if (profile != null) {
        career = _repository.getCareerAlignment(profile.archetypeName);
      }
      state = state.copyWith(
        currentProfile: profile,
        previousProfiles: previous,
        careerAlignment: career,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveProfile(SpiritualProfile profile) async {
    state = state.copyWith(isLoading: true);
    await _repository.saveSpiritualProfile(profile);
    await loadProfile();
  }

  /// Build a SpiritualProfile from archetype assessment data.
  SpiritualProfile buildProfileFromArchetypes(
    List<Archetype> archetypes,
    Map<String, int> maturityScores,
  ) {
    if (archetypes.isEmpty) {
      return SpiritualProfile(
        archetypeId: 'unknown',
        archetypeName: 'Unknown',
        description: 'Complete the assessment to discover your spiritual archetype.',
        dimensions: {},
        strengths: [],
        weaknesses: [],
        growthAreas: [],
        assessedAt: DateTime.now(),
      );
    }

    final primary = archetypes.first;
    final allStrengths = <String>[];
    final allWeaknesses = <String>[];
    final dimensions = <String, double>{};

    // Build dimensions from archetypes
    for (final archetype in archetypes) {
      final maturity = (maturityScores[archetype.name] ?? 50) / 100.0;
      dimensions[archetype.name] = maturity;

      // Parse strengths and weaknesses
      for (final s in archetype.strengths.split(';')) {
        final trimmed = s.trim().replaceAll(RegExp(r'^,\s*'), '');
        if (trimmed.isNotEmpty) allStrengths.add(trimmed);
      }
      for (final d in archetype.distortions.split(';')) {
        final trimmed = d.trim().replaceAll(RegExp(r'^,\s*'), '');
        if (trimmed.isNotEmpty) allWeaknesses.add(trimmed);
      }
    }

    // Add spiritual dimension categories
    dimensions['Faith'] = _avgDimension(dimensions.values);
    dimensions['Service'] = _avgDimension(dimensions.values) * 0.85;
    dimensions['Wisdom'] = _avgDimension(dimensions.values) * 0.9;
    dimensions['Compassion'] = _avgDimension(dimensions.values) * 0.95;
    dimensions['Courage'] = _avgDimension(dimensions.values) * 0.88;
    dimensions['Discipline'] = _avgDimension(dimensions.values) * 0.82;

    final growthAreas = allWeaknesses.take(3).map((w) {
      return 'Work on overcoming: $w';
    }).toList();

    return SpiritualProfile(
      archetypeId: primary.name.toLowerCase(),
      archetypeName: primary.name,
      description: '${primary.identity} - ${primary.strengths.split(',').first.trim()}',
      dimensions: dimensions,
      strengths: allStrengths.take(6).toList(),
      weaknesses: allWeaknesses.take(6).toList(),
      growthAreas: growthAreas,
      assessedAt: DateTime.now(),
    );
  }

  double _avgDimension(Iterable<double> values) {
    if (values.isEmpty) return 0.5;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
