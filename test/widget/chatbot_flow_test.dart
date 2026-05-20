import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calorie_tracker_app/main.dart';
import 'package:calorie_tracker_app/providers/auth_provider.dart';
import 'package:calorie_tracker_app/providers/data_providers.dart';
import 'package:calorie_tracker_app/services/firebase_service.dart';
import 'package:calorie_tracker_app/services/chatbot_api_service.dart';
import 'package:calorie_tracker_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockFirebaseService extends Mock implements FirebaseService {}
class MockChatbotApiService extends Mock implements ChatbotApiService {}
class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseService mockFirebaseService;
  late MockChatbotApiService mockChatbotApiService;
  late MockUser mockUser;

  setUp(() {
    dotenv.testLoad(fileInput: 'GROQ_API_KEY=test_key');
    mockFirebaseService = MockFirebaseService();
    mockChatbotApiService = MockChatbotApiService();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn('test_uid');
    when(() => mockUser.email).thenReturn('test@example.com');
    
    when(() => mockFirebaseService.authStateChanges).thenAnswer((_) => Stream.value(mockUser));
    when(() => mockFirebaseService.currentUser).thenReturn(mockUser);
    when(() => mockFirebaseService.fetchUserGoal()).thenAnswer(
      (_) async => UserModel(
        email: 'test@example.com', 
        dailyCalorieGoal: 2000,
        age: 25,
        gender: 'Male',
        weight: 70,
        height: 175,
      )
    );
    when(() => mockFirebaseService.getFoodLogsStream()).thenAnswer((_) => Stream.value([]));
    when(() => mockFirebaseService.getRecipesStream()).thenAnswer((_) => Stream.value([]));
    
    when(() => mockChatbotApiService.uiMessages).thenReturn([]);
  });

  testWidgets('Should interact with chatbot and show confirmation dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Mock sendMessage to trigger onConfirm for create_recipe
    when(() => mockChatbotApiService.sendMessage(any(), onConfirm: any(named: 'onConfirm')))
        .thenAnswer((invocation) async {
      final onConfirm = invocation.namedArguments[#onConfirm] as Future<bool> Function(String, Map<String, dynamic>)?;
      if (onConfirm != null) {
        await onConfirm('create_recipe', {'name': 'Pasta', 'servings': 1});
      }
      return 'Successfully processed request';
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseServiceProvider.overrideWithValue(mockFirebaseService),
          chatbotApiServiceProvider.overrideWithValue(mockChatbotApiService),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Find and tap the chatbot button
    final chatbotButton = find.byIcon(Icons.auto_awesome);
    await tester.tap(chatbotButton);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify chat window is expanded
    expect(find.text('NomNom Assistant'), findsOneWidget);

    // Enter a message to create a recipe
    await tester.enterText(find.byType(TextField).last, 'Create a recipe called Pasta');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify confirmation dialog for create_recipe appeared
    expect(find.text('Create Recipe'), findsOneWidget);

    // Tap Confirm
    await tester.tap(find.text('Confirm'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify sendMessage was called
    verify(() => mockChatbotApiService.sendMessage(any(), onConfirm: any(named: 'onConfirm'))).called(1);
  });
}

