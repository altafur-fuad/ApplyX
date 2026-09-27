import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/agent_run.dart';
import '../../data/agent_repository.dart';
import '../../../../core/network/api_client.dart';

final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiAgentRepository(apiClient);
});

class AgentRunNotifier extends AsyncNotifier<AgentRun?> {
  Timer? _pollingTimer;
  bool _isDisposed = false;

  @override
  Future<AgentRun?> build() async {
    ref.onDispose(() {
      _isDisposed = true;
      _pollingTimer?.cancel();
    });
    return null;
  }

  void _startPolling(String runId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_isDisposed) {
        _pollRun(runId);
      }
    });
  }

  Future<void> _pollRun(String runId) async {
    try {
      final repository = ref.read(agentRepositoryProvider);
      final run = await repository.getAgentRun(runId);
      final events = await repository.getAgentRunEvents(runId);
      
      final updatedRun = run.copyWith(events: events);
      
      if (!_isDisposed) {
        state = AsyncData(updatedRun);
      }

      if (updatedRun.status == AgentStatus.completed ||
          updatedRun.status == AgentStatus.failed ||
          updatedRun.status == AgentStatus.cancelled) {
        _pollingTimer?.cancel();
      }
    } catch (e) {
      // Ignore transient polling errors
    }
  }

  Future<void> startRun(String goalId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(agentRepositoryProvider);
      final run = await repository.createAgentRun(goalId, 'research_and_match');
      
      state = AsyncData(run);
      _startPolling(run.id);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> loadRun(String runId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(agentRepositoryProvider);
      final run = await repository.getAgentRun(runId);
      final events = await repository.getAgentRunEvents(runId);
      
      final updatedRun = run.copyWith(events: events);
      state = AsyncData(updatedRun);

      if (updatedRun.status != AgentStatus.completed &&
          updatedRun.status != AgentStatus.failed &&
          updatedRun.status != AgentStatus.cancelled) {
        _startPolling(runId);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> cancelRun() async {
    final current = state.value;
    if (current == null) return;
    
    try {
      final repository = ref.read(agentRepositoryProvider);
      final run = await repository.cancelAgentRun(current.id);
      
      // Update state optimistically or wait for poll
      state = AsyncData(run.copyWith(events: current.events));
      _pollingTimer?.cancel();
    } catch (e) {
      rethrow;
    }
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }
}

final agentRunProvider = AsyncNotifierProvider<AgentRunNotifier, AgentRun?>(() {
  return AgentRunNotifier();
});
