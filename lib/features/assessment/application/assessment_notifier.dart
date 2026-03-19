import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/assessment_api_repository.dart';
import '../domain/models/archetype.dart';

class ArchetypeAssessmentData {
  final int instances;
  final String fears; // 'none', 'some', 'many', 'overcome'
  final int maturity; // 0-100

  const ArchetypeAssessmentData({
    required this.instances,
    required this.fears,
    required this.maturity,
  });

  ArchetypeAssessmentData copyWith({
    int? instances,
    String? fears,
    int? maturity,
  }) {
    return ArchetypeAssessmentData(
      instances: instances ?? this.instances,
      fears: fears ?? this.fears,
      maturity: maturity ?? this.maturity,
    );
  }
}

class AssessmentState {
  final List<Archetype> selectedArchetypes;
  final Map<String, ArchetypeAssessmentData> assessmentData;
  final String? selectedPath; // 'development', 'engagement', 'recalibration'
  final List<String> selectedTasks;
  final int developmentMaturity; // 1-5 scale from fear assessment
  final bool isSyncing;
  final String? syncError;
  final DateTime? lastSyncedAt;

  const AssessmentState({
    this.selectedArchetypes = const [],
    this.assessmentData = const {},
    this.selectedPath,
    this.selectedTasks = const [],
    this.developmentMaturity = 3,
    this.isSyncing = false,
    this.syncError,
    this.lastSyncedAt,
  });

  AssessmentState copyWith({
    List<Archetype>? selectedArchetypes,
    Map<String, ArchetypeAssessmentData>? assessmentData,
    String? selectedPath,
    List<String>? selectedTasks,
    int? developmentMaturity,
    bool? isSyncing,
    String? syncError,
    DateTime? lastSyncedAt,
  }) {
    return AssessmentState(
      selectedArchetypes: selectedArchetypes ?? this.selectedArchetypes,
      assessmentData: assessmentData ?? this.assessmentData,
      selectedPath: selectedPath ?? this.selectedPath,
      selectedTasks: selectedTasks ?? this.selectedTasks,
      developmentMaturity: developmentMaturity ?? this.developmentMaturity,
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: syncError,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class AssessmentSubmission {
  const AssessmentSubmission({
    required this.archetypes,
    required this.assessmentData,
    required this.averageMaturity,
    required this.developmentMaturity,
    this.selectedPath,
    this.selectedTasks = const [],
  });

  final List<String> archetypes;
  final Map<String, Map<String, dynamic>> assessmentData;
  final int averageMaturity;
  final int developmentMaturity;
  final String? selectedPath;
  final List<String> selectedTasks;

  Map<String, dynamic> toJson() {
    return {
      'selected_archetypes': archetypes,
      'assessment_data': assessmentData,
      'selected_path': selectedPath,
      'selected_tasks': selectedTasks,
      'average_maturity': averageMaturity,
      'development_maturity': developmentMaturity,
      'completed_at': DateTime.now().toIso8601String(),
    };
  }
}

class AssessmentNotifier extends StateNotifier<AssessmentState> {
  AssessmentNotifier() : super(const AssessmentState());

  void setArchetypes(List<Archetype> archetypes) {
    state = state.copyWith(selectedArchetypes: archetypes);
  }

  void setDevelopmentMaturity(int maturity) {
    state = state.copyWith(developmentMaturity: maturity);
  }

  /// Maturity is derived from how many times the talent was used (instances)
  /// plus a bonus for having faced and wrestled with the archetype's distortions.
  /// No age required — lived experience speaks for itself.
  int _calculateMaturity(int instances, String fears) {
    double instanceScore;
    if (instances == 0) {
      instanceScore = 0;
    } else if (instances <= 3) {
      instanceScore = 15;
    } else if (instances <= 10) {
      instanceScore = 30;
    } else if (instances <= 23) {
      instanceScore = 45;
    } else if (instances <= 40) {
      instanceScore = 55;
    } else if (instances <= 60) {
      instanceScore = 65;
    } else if (instances <= 90) {
      instanceScore = 75;
    } else {
      instanceScore = 80;
    }

    final double fearBonus = switch (fears) {
      'overcome' => 20.0,
      'many' => 10.0,
      'some' => 5.0,
      _ => 0.0,
    };

    return (instanceScore + fearBonus).clamp(0.0, 100.0).round();
  }

  int getAverageMaturity() {
    if (state.selectedArchetypes.isEmpty || state.assessmentData.isEmpty) {
      return 0;
    }

    int totalMaturity = 0;
    int count = 0;

    for (final archetype in state.selectedArchetypes) {
      final data = state.assessmentData[archetype.name];
      if (data != null) {
        totalMaturity += data.maturity;
        count++;
      }
    }

    return count > 0 ? (totalMaturity / count).round() : 0;
  }

  String getRecommendedPath() {
    final avgMaturity = getAverageMaturity();
    return avgMaturity < 50 ? 'development' : 'recalibration';
  }

  void saveArchetypeAssessment(String archetypeName, int instances, String fears) {
    final maturity = _calculateMaturity(instances, fears);

    final newData = Map<String, ArchetypeAssessmentData>.from(state.assessmentData);
    newData[archetypeName] = ArchetypeAssessmentData(
      instances: instances,
      fears: fears,
      maturity: maturity,
    );

    state = state.copyWith(assessmentData: newData);
  }

  void setPath(String path) {
    state = state.copyWith(selectedPath: path);
  }

  void setTasks(List<String> tasks) {
    state = state.copyWith(selectedTasks: tasks);
  }

  void reset() {
    state = const AssessmentState();
  }

  AssessmentSubmission buildSubmission() {
    final mappedAssessmentData = <String, Map<String, dynamic>>{};
    state.assessmentData.forEach((archetypeName, data) {
      mappedAssessmentData[archetypeName] = {
        'instances': data.instances,
        'fears': data.fears,
        'maturity': data.maturity,
      };
    });

    return AssessmentSubmission(
      archetypes: state.selectedArchetypes.map((a) => a.name).toList(),
      assessmentData: mappedAssessmentData,
      selectedPath: state.selectedPath,
      selectedTasks: state.selectedTasks,
      averageMaturity: getAverageMaturity(),
      developmentMaturity: state.developmentMaturity,
    );
  }

  Future<bool> submitCurrentAssessment(AssessmentApiRepository apiRepository) async {
    if (state.selectedArchetypes.isEmpty) {
      return false;
    }

    state = state.copyWith(isSyncing: true, syncError: null);
    try {
      await apiRepository.submitAssessment(buildSubmission().toJson());
      state = state.copyWith(
        isSyncing: false,
        syncError: null,
        lastSyncedAt: DateTime.now(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        syncError: e.toString(),
      );
      return false;
    }
  }
}

final assessmentProvider =
    StateNotifierProvider<AssessmentNotifier, AssessmentState>((ref) {
  return AssessmentNotifier();
});
