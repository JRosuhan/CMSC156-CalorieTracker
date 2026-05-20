import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calorie_tracker_app/main.dart';
import 'package:calorie_tracker_app/providers/auth_provider.dart';
import 'package:calorie_tracker_app/providers/data_providers.dart';
import 'package:calorie_tracker_app/services/firebase_service.dart';
import 'package:calorie_tracker_app/models/user_model.dart';
import 'package:calorie_tracker_app/models/food_log.dart';
import 'package:calorie_tracker_app/models/recipe_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:calorie_tracker_app/services/edamam_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockFirebaseService extends Mock implements FirebaseService {}
class MockEdamamService extends Mock implements EdamamService {}
class MockUser extends Mock implements User {}
class RecipeModelFake extends Fake implements RecipeModel {}

void main() {
  late MockFirebaseService mockFirebaseService;
  late MockEdamamService mockEdamamService;
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(RecipeModelFake());
  });

  setUp(() {
    dotenv.testLoad(fileInput: 'GROQ_API_KEY=test_key');
    mockFirebaseService = MockFirebaseService();
    mockEdamamService = MockEdamamService();
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
    when(() => mockFirebaseService.addRecipe(any())).thenAnswer((_) async {});
    
    // Mock Edamam search for adding ingredients
    when(() => mockEdamamService.searchFood(any())).thenAnswer((_) async => [
      {
        'name': 'Pasta',
        'calories': 131,
        'protein': 5.0,
        'carbs': 25.0,
        'fats': 1.1,
        'measures': [{'label': 'gram', 'weight': 1.0}],
      }
    ]);
  });

  testWidgets('Should create a new recipe with an ingredient', (WidgetTester tester) async {
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

    // Navigate to Recipes
    await tester.tap(find.text('My Recipes'));
    await tester.pumpAndSettle();

    // Tap "Create Recipe" (FAB)
    await tester.tap(find.text('Create Recipe'));
    await tester.pumpAndSettle();

    // Enter Recipe Name
    final nameField = find.widgetWithText(TextFormField, 'e.g. Pasta');
    await tester.enterText(nameField, 'Test Recipe');
    await tester.pumpAndSettle();

    // Tap "Add Ingredient" (The one in the list area)
    await tester.tap(find.text('Add Ingredient').last);
    await tester.pumpAndSettle();

    // Search for ingredient in the bottom sheet
    await tester.enterText(find.byType(TextField).last, 'Pasta');
    await tester.pump(const Duration(milliseconds: 1000)); // Wait for debounce
    await tester.pumpAndSettle();

    // Add first ingredient result
    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();

    // Verify ingredient added to builder list
    expect(find.text('Pasta'), findsOneWidget);

    // Save recipe
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify addRecipe was called
    verify(() => mockFirebaseService.addRecipe(any())).called(1);
  });
}
