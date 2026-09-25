import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/opportunity.dart';
import '../../data/opportunity_repository.dart';

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  return MockOpportunityRepository();
});

final opportunitiesProvider = FutureProvider<List<Opportunity>>((ref) {
  final repository = ref.watch(opportunityRepositoryProvider);
  return repository.getOpportunities();
});

final opportunityDetailProvider = FutureProvider.family<Opportunity?, String>((ref, id) {
  final repository = ref.watch(opportunityRepositoryProvider);
  return repository.getOpportunityById(id);
});
