import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:applyx/features/opportunities/presentation/providers/opportunity_provider.dart';
import 'package:applyx/features/opportunities/domain/opportunity.dart';
import 'package:applyx/features/opportunities/presentation/opportunity_results_screen.dart';

import 'package:applyx/features/goals/presentation/providers/goal_provider.dart';

import 'package:applyx/core/widgets/app_states.dart';

void main() {
  testWidgets('OpportunityResultsScreen shows loading then empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          opportunitiesProvider.overrideWith((ref) async => <Opportunity>[]),
          activeGoalProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: OpportunityResultsScreen()),
      ),
    );

    // Initial loading state
    expect(find.byType(AppLoadingState), findsOneWidget);

    await tester.pumpAndSettle();

    // Empty state
    expect(find.text('No opportunities found'), findsOneWidget);
  });

  testWidgets('OpportunityResultsScreen shows error state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          opportunitiesProvider.overrideWith(
            (ref) async => throw Exception('error'),
          ),
          activeGoalProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: OpportunityResultsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Couldn\'t load opportunities.'), findsOneWidget);
  });
}
