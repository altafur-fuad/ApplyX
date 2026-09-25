import '../domain/agent_run.dart';

abstract class AgentRepository {
  Future<AgentRun?> getActiveRun();
}

class MockAgentRepository implements AgentRepository {
  final AgentRun _activeRun = const AgentRun(
    id: 'run1',
    goalId: 'g1',
    status: AgentStatus.running,
    steps: [
      AgentStep(
        id: 's1',
        title: 'Goal received',
        description: 'Processing your goal request.',
        status: AgentStatus.completed,
      ),
      AgentStep(
        id: 's2',
        title: 'Plan created',
        description: 'Breaking goal into research and analysis tasks.',
        status: AgentStatus.completed,
      ),
      AgentStep(
        id: 's3',
        title: 'Searching opportunities',
        description: 'Querying approved sources for matching opportunities.',
        status: AgentStatus.completed,
      ),
      AgentStep(
        id: 's4',
        title: 'Checking eligibility',
        description: 'Comparing requirements against your profile.',
        status: AgentStatus.running,
      ),
      AgentStep(
        id: 's5',
        title: 'Comparing your profile',
        description: 'Analyzing skill and experience fit.',
        status: AgentStatus.queued,
      ),
      AgentStep(
        id: 's6',
        title: 'Preparing documents',
        description: 'Drafting tailored application materials.',
        status: AgentStatus.queued,
      ),
      AgentStep(
        id: 's7',
        title: 'Verification',
        description: 'Verifying claims and source freshness.',
        status: AgentStatus.queued,
      ),
    ],
  );

  @override
  Future<AgentRun?> getActiveRun() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _activeRun;
  }
}
