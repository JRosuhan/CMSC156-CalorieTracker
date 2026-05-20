import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calorie_tracker_app/providers/food_log_provider.dart';
import 'package:calorie_tracker_app/providers/auth_provider.dart';
import 'package:calorie_tracker_app/services/firebase_service.dart';
import 'package:calorie_tracker_app/models/food_log.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

class FoodLogFake extends Fake implements FoodLog {}

void main() {
  late MockFirebaseService mockFirebaseService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FoodLogFake());
  });

  setUp(() {
    mockFirebaseService = MockFirebaseService();
    container = ProviderContainer(
      overrides: [
        firebaseServiceProvider.overrideWithValue(mockFirebaseService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('FoodLogController Tests', () {
    test('addFood calls firebaseServiceProvider.addFoodLog', () async {
      when(() => mockFirebaseService.addFoodLog(any())).thenAnswer((_) async {});

      final controller = container.read(foodLogControllerProvider);
      
      await controller.addFood(
        name: 'Apple',
        calories: 95,
        protein: 0.5,
        carbs: 25.0,
        fats: 0.3,
        servingSize: '1 medium',
        quantity: 1.0,
        availableMeasures: [{'label': 'medium', 'weight': 182.0}],
        selectedMeasureIndex: 0,
        baseCalories: 52,
        baseProtein: 0.3,
        baseCarbs: 14.0,
        baseFats: 0.2,
      );

      verify(() => mockFirebaseService.addFoodLog(any())).called(1);
    });

    test('restoreFood calls firebaseServiceProvider.restoreFoodLog', () async {
      when(() => mockFirebaseService.restoreFoodLog(any())).thenAnswer((_) async {});

      final controller = container.read(foodLogControllerProvider);
      await controller.restoreFood('test_id');

      verify(() => mockFirebaseService.restoreFoodLog('test_id')).called(1);
    });

    test('permanentDeleteFood calls firebaseServiceProvider.hardDeleteFoodLog', () async {
      when(() => mockFirebaseService.hardDeleteFoodLog(any())).thenAnswer((_) async {});

      final controller = container.read(foodLogControllerProvider);
      await controller.permanentDeleteFood('test_id');

      verify(() => mockFirebaseService.hardDeleteFoodLog('test_id')).called(1);
    });
  });
}
