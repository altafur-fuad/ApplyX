import '../../../core/network/api_client.dart';
import '../domain/opportunity.dart';

abstract class OpportunityRepository {
  Future<List<Opportunity>> getOpportunities({
    String? q,
    String? opportunityType,
    String? location,
    bool? remote,
    String? status,
    int limit = 20,
    String? cursor,
  });

  Future<Opportunity> getOpportunity(String id);
  Future<OpportunityMatch> getOpportunityMatch(String id);
  Future<void> saveOpportunity(String id);
}

class ApiOpportunityRepository implements OpportunityRepository {
  final ApiClient _apiClient;

  ApiOpportunityRepository(this._apiClient);

  @override
  Future<List<Opportunity>> getOpportunities({
    String? q,
    String? opportunityType,
    String? location,
    bool? remote,
    String? status,
    int limit = 20,
    String? cursor,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (q != null) queryParams['q'] = q;
    if (opportunityType != null) queryParams['opportunity_type'] = opportunityType;
    if (location != null) queryParams['location'] = location;
    if (remote != null) queryParams['remote'] = remote.toString();
    if (status != null) queryParams['status'] = status;
    if (cursor != null) queryParams['cursor'] = cursor;

    final uri = Uri(path: '/opportunities', queryParameters: queryParams);
    final response = await _apiClient.get(uri.toString());
    final items = response['items'] as List<dynamic>;
    return items.map((json) => Opportunity.fromJson(json)).toList();
  }

  @override
  Future<Opportunity> getOpportunity(String id) async {
    final response = await _apiClient.get('/opportunities/$id');
    return Opportunity.fromJson(response);
  }

  @override
  Future<OpportunityMatch> getOpportunityMatch(String id) async {
    final response = await _apiClient.get('/opportunities/$id/match');
    return OpportunityMatch.fromJson(response);
  }

  @override
  Future<void> saveOpportunity(String id) async {
    await _apiClient.post('/opportunities/$id/save', body: {});
  }
}
