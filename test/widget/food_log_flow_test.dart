import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calorie_tracker_app/main.dart';
import 'package:calorie_tracker_app/providers/auth_provider.dart';
import 'package:calorie_tracker_app/providers/data_providers.dart';
import 'package:calorie_tracker_app/providers/ui_state_providers.dart';
import 'package:calorie_tracker_app/services/firebase_service.dart';
import 'package:calorie_tracker_app/models/user_model.dart';
import 'package:calorie_tracker_app/models/food_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:calorie_tracker_app/services/edamam_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockFirebaseService extends Mock implements FirebaseService {}
class MockEdamamService extends Mock implements EdamamService {}
class MockUser extends Mock implements User {}
class FoodLogFake extends Fake implements FoodLog {}

void main() {
  late MockFirebaseService mockFirebaseService;
  late MockEdamamService mockEdamamService;
  late MockUser mockUser;
  final testDate = DateTime(2026, 5, 21);

  setUpAll(() {
    registerFallbackValue(FoodLogFake());
  });

  setUp(() {
    dotenv.testLoad(fileInput: 'GROQ_API_KEY=test_key');
    mockFirebaseService = MockFirebaseService();
    mockEdamamService = MockEdamamService();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn('test_uid');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.displayName).thenReturn('test');
    
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
    when(() => mockFirebaseService.addFoodLog(any())).thenAnswer((_) async {});
    
    // Mock Edamam search
    when(() => mockEdamamService.searchFood(any())).thenAnswer((_) async => [
      {
        'name': 'Apple',
        'calories': 52,
        'protein': 0.3,
        'carbs': 14.0,
        'fats': 0.2,
        'measures': [
          {'label': 'gram', 'weight': 1.0},
          {'label': 'serving', 'weight': 100.0},
        ],
      }
    ]);
  });

  testWidgets('Should navigate to Add Food and log a food item', (WidgetTester tester) async {
    // Set a larger screen size to avoid overflow errors in tests
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseServiceProvider.overrideWithValue(mockFirebaseService),
          edamamServiceProvider.overrideWithValue(mockEdamamService),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify we are on Home Screen
    expect(find.textContaining('test'), findsAtLeastNWidgets(1));

    // Tap on FAB to add food
    final fab = find.byType(FloatingActionButton);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Verify we are on Add Food screen
    expect(find.text('Add Food'), findsOneWidget);

    // Enter search query
    await tester.enterText(find.byType(TextField), 'Apple');
    await tester.pump(const Duration(milliseconds: 1000)); // Wait for debounce
    await tester.pumpAndSettle();

    // Verify search results appear (using a mock or assuming search results appear)
    expect(find.text('Apple'), findsAtLeastNWidgets(1));

    // Tap on the add button (+) of the first result
    final addIcon = find.byIcon(Icons.add).first;
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    // Should be back on Home Screen
    expect(find.textContaining('test'), findsAtLeastNWidgets(1));

    // Verify addFoodLog was called
    verify(() => mockFirebaseService.addFoodLog(any())).called(1);
  });

  testWidgets('Should delete a food log (move to bin)', (WidgetTester tester) async {
    final existingLog = FoodLog(
      id: 'test_id',
      name: 'Apple',
      calories: 95,
      protein: 0.5,
      carbs: 25.0,
      fats: 0.3,
      servingSize: '1 medium',
      timestamp: testDate,
      quantity: 1.0,
      availableMeasures: [{'label': 'medium', 'weight': 182.0}],
      selectedMeasureIndex: 0,
      baseCalories: 52,
      baseProtein: 0.3,
      baseCarbs: 14.0,
      baseFats: 0.2,
    );

    when(() => mockFirebaseService.getFoodLogsStream()).thenAnswer((_) => Stream.value([existingLog]));
    when(() => mockFirebaseService.softDeleteFoodLog(any())).thenAnswer((_) async {});

    final container = ProviderContainer(
      overrides: [
        firebaseServiceProvider.overrideWithValue(mockFirebaseService),
        edamamServiceProvider.overrideWithValue(mockEdamamService),
      ],
    );
    container.read(selectedDateProvider.notifier).setDate(testDate);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Swipe left on the Apple log card to delete
    await tester.drag(find.text('Apple'), const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    // Verify softDeleteFoodLog was called
    verify(() => mockFirebaseService.softDeleteFoodLog('test_id')).called(1);
    container.dispose();
  });
}
