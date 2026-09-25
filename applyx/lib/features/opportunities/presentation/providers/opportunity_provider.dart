import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/opportunity.dart';
import '../../data/opportunity_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  return SupabaseOpportunityRepository(Supabase.instance.client);
});

final opportunitiesProvider = FutureProvider<List<Opportunity>>((ref) {
  final repository = ref.watch(opportunityRepositoryProvider);
  return repository.getOpportunities();
});

final opportunityDetailProvider = FutureProvider.family<Opportunity?, String>((
  ref,
  id,
) {
  final repository = ref.watch(opportunityRepositoryProvider);
  return repository.getOpportunityById(id);
});
