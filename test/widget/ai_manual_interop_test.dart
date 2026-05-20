import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calorie_tracker_app/main.dart';
import 'package:calorie_tracker_app/providers/auth_provider.dart';
import 'package:calorie_tracker_app/providers/data_providers.dart';
import 'package:calorie_tracker_app/services/firebase_service.dart';
import 'package:calorie_tracker_app/services/chatbot_api_service.dart';
import 'package:calorie_tracker_app/services/edamam_service.dart';
import 'package:calorie_tracker_app/models/user_model.dart';
import 'package:calorie_tracker_app/models/food_log.dart';
import 'package:calorie_tracker_app/models/recipe_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockFirebaseService extends Mock implements FirebaseService {}
class MockUser extends Mock implements User {}
class RecipeModelFake extends Fake implements RecipeModel {}
class FoodLogFake extends Fake implements FoodLog {}

class MockEdamamService extends Mock implements EdamamService {}
class MockChatbotApiService extends Mock implements ChatbotApiService {}

void main() {
  late MockFirebaseService mockFirebaseService;
  late MockEdamamService mockEdamamService;
  late MockChatbotApiService mockChatbotApiService;
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(RecipeModelFake());
    registerFallbackValue(FoodLogFake());
  });

  setUp(() {
    dotenv.testLoad(fileInput: 'GROQ_API_KEY=test_key');
    mockFirebaseService = MockFirebaseService();
    mockEdamamService = MockEdamamService();
    mockChatbotApiService = MockChatbotApiService();
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
    
    // Default mock for recipes stream
    when(() => mockFirebaseService.getRecipesStream()).thenAnswer((_) => Stream.value([]));
    
    // Mock chatbot service
    when(() => mockChatbotApiService.uiMessages).thenReturn([]);
  });

  testWidgets('AI recipe creation and manual edit/delete interoperability', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final aiRecipeId = 'ai_recipe_123';
    final aiRecipe = RecipeModel(
      id: aiRecipeId,
      name: 'AI Pasta',
      ingredients: [
        FoodLog(
          id: 'ing_1',
          name: 'Noodles',
          calories: 200,
          protein: 5,
          carbs: 40,
          fats: 1,
          servingSize: '100g',
          timestamp: DateTime.now(),
          quantity: 1.0,
          availableMeasures: [{'label': 'g', 'weight': 1.0}],
          selectedMeasureIndex: 0,
          baseCalories: 200,
          baseProtein: 5,
          baseCarbs: 40,
          baseFats: 1,
        )
      ],
      servings: 2,
    );

    // 1. Initial State: Empty
    when(() => mockFirebaseService.getRecipesStream()).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseServiceProvider.overrideWithValue(mockFirebaseService),
          edamamServiceProvider.overrideWithValue(mockEdamamService),
          chatbotApiServiceProvider.overrideWithValue(mockChatbotApiService),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Simulate AI adding a recipe
    when(() => mockFirebaseService.getRecipesStream()).thenAnswer((_) => Stream.value([aiRecipe]));
    
    // Find and tap the "My Recipes" nav item (it might be in a Drawer or BottomNav)
    // Looking at HomeScreen, it's a TextButton in the 'What's on the menu?' section or similar?
    // Actually, in HomeScreen, "My Recipes" is a section header or button.
    final myRecipesButton = find.text('My Recipes');
    await tester.ensureVisible(myRecipesButton);
    await tester.tap(myRecipesButton);
    await tester.pumpAndSettle();

    // Verify AI-created recipe appears in the list
    expect(find.text('AI Pasta'), findsOneWidget);

    // 3. Verify manual EDIT works on the AI-created recipe
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Verify we are in the Recipe Builder for the AI recipe
    expect(find.text('Edit Recipe'), findsOneWidget);
    expect(find.text('AI Pasta'), findsAtLeastNWidgets(1));
    expect(find.text('Noodles'), findsOneWidget);

    // Edit the ingredient quantity manually
    await tester.tap(find.text('Noodles'));
    await tester.pumpAndSettle();
    
    // Change quantity to 2
    await tester.enterText(find.byType(TextField).at(0), '2');
    await tester.tap(find.text('Update Meal'));
    await tester.pumpAndSettle();

    // Save the recipe
    when(() => mockFirebaseService.updateRecipe(any())).thenAnswer((_) async {});
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify manual update was called
    verify(() => mockFirebaseService.updateRecipe(any())).called(1);

    // 4. Verify manual DELETE works on the AI-created recipe
    when(() => mockFirebaseService.softDeleteRecipe(aiRecipeId)).thenAnswer((_) async {});
    
    // Back on Recipe List
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Verify manual soft delete was called
    verify(() => mockFirebaseService.softDeleteRecipe(aiRecipeId)).called(1);
  });
}
