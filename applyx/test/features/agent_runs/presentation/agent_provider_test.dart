import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:applyx/features/agent_runs/presentation/providers/agent_provider.dart';
import 'package:applyx/features/agent_runs/data/agent_repository.dart';
import 'package:applyx/features/agent_runs/domain/agent_run.dart';

class FakeAgentRepository implements AgentRepository {
  AgentRun currentRun;
  List<AgentRunEvent> currentEvents;
  int pollCount = 0;

  FakeAgentRepository({
    required this.currentRun,
    this.currentEvents = const [],
  });

  @override
  Future<AgentRun> createAgentRun(String goalId, String mode) async {
    return currentRun;
  }

  @override
  Future<AgentRun> getAgentRun(String runId) async {
    pollCount++;
    return currentRun;
  }

  @override
  Future<List<AgentRunEvent>> getAgentRunEvents(String runId) async {
    return currentEvents;
  }

  @override
  Future<AgentRun> cancelAgentRun(String runId) async {
    currentRun = currentRun.copyWith(status: AgentStatus.cancelled);
    return currentRun;
  }
}

void main() {
  test('AgentRunNotifier startRun sets loading then data', () async {
    final repo = FakeAgentRepository(
      currentRun: const AgentRun(id: '1', goalId: 'g1', status: AgentStatus.running),
    );
    final container = ProviderContainer(
      overrides: [
        agentRepositoryProvider.overrideWithValue(repo),
      ],
    );

    final notifier = container.read(agentRunProvider.notifier);
    
    expect(container.read(agentRunProvider).value, isNull);

    // Call startRun
    final future = notifier.startRun('g1');
    expect(container.read(agentRunProvider), const AsyncLoading<AgentRun?>());
    
    await future;

    final state = container.read(agentRunProvider).value;
    expect(state?.id, '1');
    expect(state?.status, AgentStatus.running);

    notifier.stopPolling();
  });
}
