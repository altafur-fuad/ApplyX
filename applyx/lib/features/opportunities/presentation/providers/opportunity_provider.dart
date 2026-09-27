import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/opportunity.dart';
import '../../data/opportunity_repository.dart';
import '../../../../core/network/api_client.dart';

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiOpportunityRepository(apiClient);
});

final opportunitiesProvider = FutureProvider<List<Opportunity>>((ref) {
  final repository = ref.watch(opportunityRepositoryProvider);
  return repository.getOpportunities();
});

final opportunityDetailProvider = FutureProvider.family<Opportunity, String>((
  ref,
  id,
) {
  final repository = ref.watch(opportunityRepositoryProvider);
  return repository.getOpportunity(id);
});

final opportunityMatchProvider = FutureProvider.family<OpportunityMatch, String>((
  ref,
  id,
) {
  final repository = ref.watch(opportunityRepositoryProvider);
  return repository.getOpportunityMatch(id);
});

final saveOpportunityProvider = StateNotifierProvider<SaveOpportunityNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(opportunityRepositoryProvider);
  return SaveOpportunityNotifier(repository);
});

class SaveOpportunityNotifier extends StateNotifier<AsyncValue<void>> {
  final OpportunityRepository _repository;

  SaveOpportunityNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> save(String id) async {
    if (state.isLoading) return;
    
    state = const AsyncValue.loading();
    try {
      await _repository.saveOpportunity(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
