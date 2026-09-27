import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:applyx/features/goals/presentation/create_goal_screen.dart';
import 'package:applyx/features/goals/presentation/providers/goal_provider.dart';
import 'package:applyx/features/goals/data/goal_repository.dart';
import 'package:applyx/features/goals/domain/goal.dart';
import 'package:applyx/core/network/api_exception.dart';
import 'package:applyx/features/agent_runs/presentation/providers/agent_provider.dart';
import 'package:applyx/features/agent_runs/data/agent_repository.dart';
import 'package:applyx/features/agent_runs/domain/agent_run.dart';

class FakeGoalRepository implements GoalRepository {
  bool shouldFail = false;
  Goal? createdGoal;
  int callCount = 0;

  @override
  Future<Goal> createGoal(CreateGoalRequest request) async {
    callCount++;
    await Future.delayed(const Duration(milliseconds: 100));
    if (shouldFail) {
      throw ApiException(statusCode: 500, code: 'ERR', message: 'Failed to create');
    }
    createdGoal = Goal(
      id: 'g1',
      userId: 'u1',
      title: request.title,
      rawGoal: request.rawGoal,
      structuredConstraints: request.structuredConstraints ?? const StructuredConstraints(),
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return createdGoal!;
  }

  @override
  Future<Goal?> getActiveGoal() async => null;

  @override
  Future<Goal> getGoal(String id) async => throw UnimplementedError();

  @override
  Future<List<Goal>> getGoals() async => [];

  @override
  Future<Goal> updateGoal(String id, UpdateGoalRequest request) async => throw UnimplementedError();
}

class FakeAgentRepository implements AgentRepository {
  @override
  Future<AgentRun> createAgentRun(String goalId, String mode) async {
    return const AgentRun(id: 'r1', goalId: 'g1', status: AgentStatus.queued);
  }

  @override
  Future<AgentRun> getAgentRun(String runId) async => throw UnimplementedError();

  @override
  Future<List<AgentRunEvent>> getAgentRunEvents(String runId) async => [];

  @override
  Future<AgentRun> cancelAgentRun(String runId) async => throw UnimplementedError();
}

void main() {
  Widget createTestableWidget(FakeGoalRepository repository, [FakeAgentRepository? agentRepo]) {
    agentRepo ??= FakeAgentRepository();
    return ProviderScope(
      overrides: [
        goalRepositoryProvider.overrideWithValue(repository),
        agentRepositoryProvider.overrideWithValue(agentRepo),
      ],
      child: const MaterialApp(
        home: CreateGoalScreen(),
      ),
    );
  }

  testWidgets('Create Goal success flow', (WidgetTester tester) async {
    final repo = FakeGoalRepository();
    await tester.pumpWidget(createTestableWidget(repo));

    // Initially button is disabled because input is empty
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);

    // Enter text
    await tester.enterText(find.byType(TextField), 'Test goal');
    await tester.pumpAndSettle();

    // Button is now enabled
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNotNull);

    // Tap button
    await tester.tap(find.text('Start Agent'));
    
    // Shows loading state
    await tester.pump();
    expect(find.text('Starting...'), findsOneWidget);
    
    // Prevent duplicate submission - try tapping again
    await tester.tap(find.text('Starting...'));

    await tester.pumpAndSettle();
    
    // Only 1 API call should have occurred
    expect(repo.callCount, 1);
    expect(repo.createdGoal?.title, 'Test goal');
    
    // Note: It tries to navigate using context.push, which might throw in test without GoRouter, 
    // but the test will catch it or we can ignore the navigation error for this basic unit test.
  });

  testWidgets('Create Goal failure flow shows snackbar', (WidgetTester tester) async {
    final repo = FakeGoalRepository()..shouldFail = true;
    await tester.pumpWidget(createTestableWidget(repo));

    await tester.enterText(find.byType(TextField), 'Test goal');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Agent'));
    await tester.pump();
    
    // Finish the request
    await tester.pumpAndSettle();

    // Check if error snackbar is shown
    expect(find.text('Failed to create'), findsOneWidget);
    
    // Form is not cleared
    expect(find.text('Test goal'), findsOneWidget);
    
    // Button resets to Start Agent
    expect(find.text('Start Agent'), findsOneWidget);
  });
}
