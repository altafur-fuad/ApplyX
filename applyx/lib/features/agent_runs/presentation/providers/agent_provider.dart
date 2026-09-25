import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/agent_run.dart';
import '../../data/agent_repository.dart';

final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return MockAgentRepository();
});

class AgentRunNotifier extends AsyncNotifier<AgentRun?> {
  @override
  Future<AgentRun?> build() async {
    final repository = ref.watch(agentRepositoryProvider);
    return repository.getActiveRun();
  }

  void simulateProgress() {
    final currentState = state.value;
    if (currentState == null) return;

    final steps = List<AgentStep>.from(currentState.steps);
    final runningIndex = steps.indexWhere(
      (s) => s.status == AgentStatus.running,
    );
    if (runningIndex == -1) return;

    steps[runningIndex] = steps[runningIndex].copyWith(
      status: AgentStatus.completed,
    );

    if (runningIndex + 1 < steps.length) {
      steps[runningIndex + 1] = steps[runningIndex + 1].copyWith(
        status: AgentStatus.running,
      );
    }

    final isComplete = steps.every((s) => s.status == AgentStatus.completed);

    state = AsyncData(
      currentState.copyWith(
        steps: steps,
        status: isComplete ? AgentStatus.completed : AgentStatus.running,
      ),
    );
  }
}

final agentRunProvider = AsyncNotifierProvider<AgentRunNotifier, AgentRun?>(() {
  return AgentRunNotifier();
});
