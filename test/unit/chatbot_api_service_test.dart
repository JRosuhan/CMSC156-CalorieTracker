import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:calorie_tracker_app/services/chatbot_api_service.dart';
import 'package:calorie_tracker_app/services/firebase_service.dart';
import 'package:calorie_tracker_app/services/edamam_service.dart';
import 'package:calorie_tracker_app/models/food_log.dart';
import 'package:calorie_tracker_app/models/recipe_model.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockFirebaseService extends Mock implements FirebaseService {}
class MockEdamamService extends Mock implements EdamamService {}
class FoodLogFake extends Fake implements FoodLog {}
class RecipeModelFake extends Fake implements RecipeModel {}

void main() {
  late MockFirebaseService mockFirebaseService;
  late MockEdamamService mockEdamamService;
  late ChatbotApiService chatbotService;

  setUpAll(() {
    registerFallbackValue(FoodLogFake());
    registerFallbackValue(RecipeModelFake());
  });

  setUp(() async {
    dotenv.testLoad(fileInput: 'GROQ_API_KEY=test_key');
    mockFirebaseService = MockFirebaseService();
    mockEdamamService = MockEdamamService();
    ChatbotApiService.resetInstance();
    chatbotService = ChatbotApiService(
      firebaseService: mockFirebaseService,
      edamamService: mockEdamamService,
    );
  });

  group('ChatbotApiService - Tool Calls Delegation', () {
    test('add_food_log tool delegates to FirebaseService.addFoodLog', () async {
      when(() => mockFirebaseService.addFoodLog(any())).thenAnswer((_) async {});

      final params = {
        'name': 'Banana',
        'calories': 105,
        'protein': 1.3,
        'carbs': 27.0,
        'fats': 0.4,
        'servingSize': '1 medium',
        'quantity': 1.0,
      };

      await chatbotService.handleFunctionCall('add_food_log', params);

      verify(() => mockFirebaseService.addFoodLog(any())).called(1);
    });

    test('delete_food_log tool delegates to FirebaseService.softDeleteFoodLog', () async {
      when(() => mockFirebaseService.softDeleteFoodLog(any())).thenAnswer((_) async {});

      final params = {'id': 'test_log_id'};

      await chatbotService.handleFunctionCall('delete_food_log', params);

      verify(() => mockFirebaseService.softDeleteFoodLog('test_log_id')).called(1);
    });

    test('update_food_log tool delegates to FirebaseService.updateFoodLog', () async {
      // Mock getFoodLogsStream to return an existing log
      final existingLog = FoodLog(
        id: 'test_id',
        name: 'Apple',
        calories: 95,
        protein: 0.5,
        carbs: 25.0,
        fats: 0.3,
        servingSize: '1 medium',
        timestamp: DateTime.now(),
        quantity: 1.0,
        availableMeasures: [{'label': 'serving', 'weight': 100.0}],
        selectedMeasureIndex: 0,
        baseCalories: 52,
        baseProtein: 0.3,
        baseCarbs: 14.0,
        baseFats: 0.2,
      );

      when(() => mockFirebaseService.getFoodLogsStream()).thenAnswer(
        (_) => Stream.value([existingLog])
      );
      when(() => mockFirebaseService.updateFoodLog(any())).thenAnswer((_) async {});

      final params = {'id': 'test_id', 'quantity': 2.0};

      await chatbotService.handleFunctionCall('update_food_log', params);

      verify(() => mockFirebaseService.updateFoodLog(any())).called(1);
    });

    test('create_recipe tool delegates to FirebaseService.addRecipe', () async {
      when(() => mockFirebaseService.addRecipe(any())).thenAnswer((_) async {});

      final params = {'name': 'New Recipe', 'servings': 4};

      await chatbotService.handleFunctionCall('create_recipe', params);

      verify(() => mockFirebaseService.addRecipe(any())).called(1);
    });

    test('add_recipe_ingredient tool delegates to FirebaseService.updateRecipe', () async {
      final existingRecipe = RecipeModel(
        id: 'recipe_123',
        name: 'Test Recipe',
        ingredients: [],
        servings: 1,
      );

      when(() => mockFirebaseService.getRecipesStream()).thenAnswer(
        (_) => Stream.value([existingRecipe])
      );
      when(() => mockFirebaseService.updateRecipe(any())).thenAnswer((_) async {});

      final params = {
        'recipe_id': 'recipe_123',
        'name': 'Salt',
        'calories': 0,
        'servingSize': '1 pinch',
      };

      await chatbotService.handleFunctionCall('add_recipe_ingredient', params);

      verify(() => mockFirebaseService.updateRecipe(any())).called(1);
    });

    test('update_recipe_ingredient tool delegates to FirebaseService.updateRecipe', () async {
      final ingredient = FoodLog(
        id: 'ing_1',
        name: 'Sugar',
        calories: 10,
        protein: 0,
        carbs: 2.5,
        fats: 0,
        servingSize: '1 tsp',
        timestamp: DateTime.now(),
        quantity: 1.0,
        availableMeasures: [{'label': 'tsp', 'weight': 5.0}],
        selectedMeasureIndex: 0,
        baseCalories: 200,
        baseProtein: 0,
        baseCarbs: 50,
        baseFats: 0,
      );
      final existingRecipe = RecipeModel(
        id: 'recipe_123',
        name: 'Sweet Tea',
        ingredients: [ingredient],
        servings: 1,
      );

      when(() => mockFirebaseService.getRecipesStream()).thenAnswer(
        (_) => Stream.value([existingRecipe])
      );
      when(() => mockFirebaseService.updateRecipe(any())).thenAnswer((_) async {});

      final params = {
        'recipe_id': 'recipe_123',
        'ingredient_name': 'Sugar',
        'quantity': 2.0,
      };

      await chatbotService.handleFunctionCall('update_recipe_ingredient', params);

      verify(() => mockFirebaseService.updateRecipe(any())).called(1);
    });

    test('delete_recipe_ingredient tool delegates to FirebaseService.updateRecipe', () async {
      final ingredient = FoodLog(
        id: 'ing_1',
        name: 'Sugar',
        calories: 10,
        protein: 0,
        carbs: 2.5,
        fats: 0,
        servingSize: '1 tsp',
        timestamp: DateTime.now(),
        quantity: 1.0,
        availableMeasures: [{'label': 'tsp', 'weight': 5.0}],
        selectedMeasureIndex: 0,
        baseCalories: 200,
        baseProtein: 0,
        baseCarbs: 50,
        baseFats: 0,
      );
      final existingRecipe = RecipeModel(
        id: 'recipe_123',
        name: 'Sweet Tea',
        ingredients: [ingredient],
        servings: 1,
      );

      when(() => mockFirebaseService.getRecipesStream()).thenAnswer(
        (_) => Stream.value([existingRecipe])
      );
      when(() => mockFirebaseService.updateRecipe(any())).thenAnswer((_) async {});

      final params = {
        'recipe_id': 'recipe_123',
        'ingredient_name': 'Sugar',
      };

      await chatbotService.handleFunctionCall('delete_recipe_ingredient', params);

      verify(() => mockFirebaseService.updateRecipe(any())).called(1);
    });
  });
}
