import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applyx/features/auth/data/auth_repository.dart';
import 'package:applyx/features/profile/data/profile_repository.dart';
import 'package:applyx/features/profile/domain/profile.dart';
import 'package:applyx/features/goals/data/goal_repository.dart';
import 'package:applyx/features/goals/domain/goal.dart';
import 'package:applyx/features/opportunities/data/opportunity_repository.dart';
import 'package:applyx/features/applications/data/application_repository.dart';
import 'package:applyx/features/documents/data/document_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Integration Tests', () {
    late SupabaseClient supabase;
    late SupabaseAuthRepository authRepo;
    late SupabaseProfileRepository profileRepo;
    late SupabaseGoalRepository goalRepo;
    late SupabaseOpportunityRepository opportunityRepo;
    late SupabaseApplicationRepository applicationRepo;
    late SupabaseDocumentRepository documentRepo;

    final testEmail =
        'integration_test_${DateTime.now().millisecondsSinceEpoch}@gmail.com';
    final testPassword = 'testpassword123';

    setUpAll(() async {
      HttpOverrides.global = null;
      SharedPreferences.setMockInitialValues({});

      await dotenv.load(fileName: ".env");
      final url = dotenv.env['SUPABASE_URL']!;
      final publishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY']!;

      await Supabase.initialize(url: url, publishableKey: publishableKey);
      supabase = Supabase.instance.client;

      authRepo = SupabaseAuthRepository(supabase);
      profileRepo = SupabaseProfileRepository(supabase);
      goalRepo = SupabaseGoalRepository(supabase);
      opportunityRepo = SupabaseOpportunityRepository(supabase);
      applicationRepo = SupabaseApplicationRepository(supabase);
      documentRepo = SupabaseDocumentRepository(supabase);
    });

    test('1. App startup', () {
      expect(supabase, isNotNull);
    });

    test('2. Sign Up', () async {
      await authRepo.signUp(
        email: testEmail,
        password: testPassword,
        fullName: 'Test User',
      );
      await Future.delayed(const Duration(seconds: 1));
    });

    test('3. Sign In', () async {
      await authRepo.signIn(email: testEmail, password: testPassword);
    });

    test('4. Session restoration', () async {
      final session = supabase.auth.currentSession;
      expect(session, isNotNull);
    });

    test('5. Sign Out (and sign back in for remaining tests)', () async {
      await authRepo.signOut();
      expect(supabase.auth.currentSession, isNull);

      // Sign back in to allow remaining tests to run authenticated
      await authRepo.signIn(email: testEmail, password: testPassword);
      expect(supabase.auth.currentSession, isNotNull);
    });

    test('6. Profile read', () async {
      final profile = await profileRepo.getProfile();
      expect(profile, isNotNull);
      expect(profile.fullName, isNotEmpty);
    });

    test('7. Profile update', () async {
      final oldProfile = await profileRepo.getProfile();
      final newProfile = UserProfile(
        id: oldProfile.id,
        fullName: 'Updated Test User',
        headline: 'Tester',
        bio: 'Testing ApplyX',
        skills: ['Integration Testing'],
        location: 'Localhost',
      );
      await profileRepo.updateProfile(newProfile);
      final verifyProfile = await profileRepo.getProfile();
      expect(verifyProfile.fullName, equals('Updated Test User'));
    });

    test('9. Goal creation', () async {
      final goal = Goal(
        id: 'g1',
        title: 'Find testing jobs',
        rawGoal: 'I want a QA job',
        createdAt: DateTime.now(),
      );
      await goalRepo.createGoal(goal);
    });

    test('8. Goal list', () async {
      final goals = await goalRepo.getGoals();
      expect(goals, isNotEmpty);
    });

    test('10. Opportunity list (read-only)', () async {
      final opps = await opportunityRepo.getOpportunities();
      expect(opps, isA<List>());
    });

    test('12. Application list', () async {
      final apps = await applicationRepo.getApplications();
      expect(apps, isA<List>());
    });

    test('Document Storage', () async {
      final testFile = File('test_doc.txt');
      await testFile.writeAsString('Hello World');
      final path = await documentRepo.uploadDocument(
        filePath: testFile.path,
        fileName: 'test_doc.txt',
      );
      expect(path, isNotEmpty);

      final bytes = await documentRepo.downloadDocument(path);
      expect(bytes.isNotEmpty, isTrue);

      await documentRepo.deleteDocument(path);
      await testFile.delete();
    });
  });
}
