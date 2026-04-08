import 'package:flutter/foundation.dart';

import '../../../core/network/dio_client.dart';
import '../domain/models/faith_question.dart';
import 'faith_question_catalog.dart';

/// Repository that fetches faith questions from the API with offline fallback.
///
/// Tries the backend first. If the API fails (offline, error, etc.),
/// falls back to the hardcoded [FaithQuestionCatalog].
class FaithQuestionRepository {
  FaithQuestionRepository(this._dioClient);

  final DioClient _dioClient;
  List<FaithQuestion>? _cachedQuestions;

  /// Fetch all questions. Tries API first, falls back to local catalog.
  Future<List<FaithQuestion>> fetchQuestions({String? category}) async {
    // Return cache if available
    if (_cachedQuestions != null && _cachedQuestions!.isNotEmpty) {
      return _filterByCategory(_cachedQuestions!, category);
    }

    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;

      final response = await _dioClient.get(
        '/faith-questions',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items = data is Map ? (data['data'] as List) : (data as List);
        final questions = items
            .map((item) => FaithQuestion.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (questions.isNotEmpty) {
          _cachedQuestions = questions;
          return _filterByCategory(questions, category);
        }
      }
    } catch (e) {
      debugPrint('FaithQuestionRepository: API fetch failed, using offline catalog: $e');
    }

    // Fallback to local catalog
    final local = FaithQuestionCatalog.allQuestions;
    _cachedQuestions = local;
    return _filterByCategory(local, category);
  }

  /// Get a single question by ID.
  Future<FaithQuestion?> fetchById(String id) async {
    final questions = await fetchQuestions();
    try {
      return questions.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clear the cache to force a fresh API fetch next time.
  void clearCache() {
    _cachedQuestions = null;
  }

  List<FaithQuestion> _filterByCategory(List<FaithQuestion> questions, String? category) {
    if (category == null) return questions;
    return questions.where((q) => q.category == category).toList();
  }
}
