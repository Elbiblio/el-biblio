import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/service_opportunity_repository.dart';
import '../domain/models/service_opportunity.dart';

/// Notifier for managing service opportunities state
class ServiceOpportunityNotifier extends StateNotifier<AsyncValue<List<ServiceOpportunity>>> {
  final ServiceOpportunityRepository _repository;

  ServiceOpportunityNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadOpportunities();
  }

  /// Load service opportunities from the backend
  Future<void> loadOpportunities({String? category, String? locationType}) async {
    state = const AsyncValue.loading();
    try {
      final opportunities = await _repository.getServiceOpportunities(
        category: category,
        locationType: locationType,
      );
      state = AsyncValue.data(opportunities);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh opportunities
  Future<void> refresh() async {
    await loadOpportunities();
  }
}
