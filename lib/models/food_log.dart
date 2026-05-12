// models/food_log.dart

class FoodLog {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final String servingSize;
  final DateTime timestamp;

  // Fields for recalculation
  final double quantity;
  final List<Map<String, dynamic>> availableMeasures;
  final int selectedMeasureIndex;
  final int baseCalories; // per 100g
  final double baseProtein;
  final double baseCarbs;
  final double baseFats;

  FoodLog({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.servingSize,
    required this.timestamp,
    required this.quantity,
    required this.availableMeasures,
    required this.selectedMeasureIndex,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFats,
  });
}