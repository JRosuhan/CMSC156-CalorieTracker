import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_log.dart';
import 'auth_provider.dart';
import 'ui_state_providers.dart';

final foodLogControllerProvider = Provider((ref) => FoodLogController(ref));

class FoodLogController {
  final Ref _ref;

  FoodLogController(this._ref);

  Future<void> addFood({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
    required String servingSize,
    required double quantity,
    required List<Map<String, dynamic>> availableMeasures,
    required int selectedMeasureIndex,
    required int baseCalories,
    required double baseProtein,
    required double baseCarbs,
    required double baseFats,
    bool fromRecipe = false,
  }) async {
    final selectedDate = _ref.read(selectedDateProvider);
    final now = DateTime.now();
    final logTimestamp = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    final newFood = FoodLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      servingSize: servingSize,
      timestamp: logTimestamp,
      quantity: quantity,
      availableMeasures: availableMeasures,
      selectedMeasureIndex: selectedMeasureIndex,
      baseCalories: baseCalories,
      baseProtein: baseProtein,
      baseCarbs: baseCarbs,
      baseFats: baseFats,
      fromRecipe: fromRecipe,
    );

    await _ref.read(firebaseServiceProvider).addFoodLog(newFood);
  }

  Future<void> restoreFood(String id) async {
    await _ref.read(firebaseServiceProvider).restoreFoodLog(id);
  }

  Future<void> permanentDeleteFood(String id) async {
    await _ref.read(firebaseServiceProvider).hardDeleteFoodLog(id);
  }
}
