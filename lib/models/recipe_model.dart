import 'package:flutter/foundation.dart';
import 'food_log.dart';

class RecipeModel {
  final String id;
  final String name;
  final List<FoodLog> ingredients;
  final int servings;
  final bool isDeleted;

  RecipeModel({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.servings,
    this.isDeleted = false,
  });

  double get totalCalories => ingredients.fold(0.0, (sum, item) => sum + item.calories);
  double get totalProtein => ingredients.fold(0.0, (sum, item) => sum + item.protein);
  double get totalCarbs => ingredients.fold(0.0, (sum, item) => sum + item.carbs);
  double get totalFats => ingredients.fold(0.0, (sum, item) => sum + item.fats);

  double get totalWeight {
    return ingredients.fold(0.0, (sum, item) {
      final measure = item.availableMeasures[item.selectedMeasureIndex];
      final weight = (measure['weight'] ?? 100.0) * item.quantity;
      return sum + weight;
    });
  }

  int get caloriesPerServing => servings > 0 ? (totalCalories / servings).round() : 0;
  double get proteinPerServing => servings > 0 ? totalProtein / servings : 0.0;
  double get carbsPerServing => servings > 0 ? totalCarbs / servings : 0.0;
  double get fatsPerServing => servings > 0 ? totalFats / servings : 0.0;

  double get caloriesPer100g => totalWeight > 0 ? (totalCalories / totalWeight) * 100 : 0;
  double get proteinPer100g => totalWeight > 0 ? (totalProtein / totalWeight) * 100 : 0;
  double get carbsPer100g => totalWeight > 0 ? (totalCarbs / totalWeight) * 100 : 0;
  double get fatsPer100g => totalWeight > 0 ? (totalFats / totalWeight) * 100 : 0;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ingredients': ingredients.map((i) => {
        'name': i.name,
        'calories': i.calories,
        'protein': i.protein,
        'carbs': i.carbs,
        'fats': i.fats,
        'servingSize': i.servingSize,
        'quantity': i.quantity,
        'availableMeasures': i.availableMeasures,
        'selectedMeasureIndex': i.selectedMeasureIndex,
        'baseCalories': i.baseCalories,
        'baseProtein': i.baseProtein,
        'baseCarbs': i.baseCarbs,
        'baseFats': i.baseFats,
      }).toList(),
      'servings': servings,
      'isDeleted': isDeleted,
    };
  }

  factory RecipeModel.fromMap(String id, Map<String, dynamic>? map) {
    try {
      if (map == null) {
        return RecipeModel(id: id, name: 'Unknown Recipe', ingredients: [], servings: 1);
      }
      
      final String name = map['name']?.toString() ?? 'Unknown Recipe';
      final int servings = int.tryParse(map['servings']?.toString() ?? '1') ?? 1;
      final bool isDeleted = map['isDeleted'] ?? false;
      
      final List rawIngredients = map['ingredients'] is List ? map['ingredients'] : [];
      
      final List<FoodLog> ingredients = rawIngredients.map<FoodLog>((data) {
        try {
          final Map<String, dynamic> d = data is Map ? Map<String, dynamic>.from(data) : {};
          
          final List rawMeasures = d['availableMeasures'] is List ? d['availableMeasures'] : [];
          final List<Map<String, dynamic>> measures = rawMeasures.map<Map<String, dynamic>>((m) {
            if (m is Map) {
              return {
                'label': m['label']?.toString() ?? 'Serving',
                'weight': double.tryParse(m['weight']?.toString() ?? '100.0') ?? 100.0,
              };
            }
            return {'label': 'Serving', 'weight': 100.0};
          }).toList();

          return FoodLog(
            id: '', 
            name: d['name']?.toString() ?? 'Unknown',
            calories: int.tryParse(d['calories']?.toString() ?? '0') ?? 0,
            protein: double.tryParse(d['protein']?.toString() ?? '0.0') ?? 0.0,
            carbs: double.tryParse(d['carbs']?.toString() ?? '0.0') ?? 0.0,
            fats: double.tryParse(d['fats']?.toString() ?? '0.0') ?? 0.0,
            servingSize: d['servingSize']?.toString() ?? 'Unknown',
            timestamp: DateTime.now(),
            quantity: double.tryParse(d['quantity']?.toString() ?? '1.0') ?? 1.0,
            availableMeasures: measures,
            selectedMeasureIndex: int.tryParse(d['selectedMeasureIndex']?.toString() ?? '0') ?? 0,
            baseCalories: int.tryParse(d['baseCalories']?.toString() ?? '0') ?? 0,
            baseProtein: double.tryParse(d['baseProtein']?.toString() ?? '0.0') ?? 0.0,
            baseCarbs: double.tryParse(d['baseCarbs']?.toString() ?? '0.0') ?? 0.0,
            baseFats: double.tryParse(d['baseFats']?.toString() ?? '0.0') ?? 0.0,
          );
        } catch (e) {
          debugPrint('Error parsing ingredient: $e');
          return FoodLog(
            id: '', name: 'Error Loading Ingredient', calories: 0, protein: 0, carbs: 0, fats: 0,
            servingSize: '', timestamp: DateTime.now(), quantity: 1, availableMeasures: [],
            selectedMeasureIndex: 0, baseCalories: 0, baseProtein: 0, baseCarbs: 0, baseFats: 0
          );
        }
      }).toList();

      return RecipeModel(
        id: id,
        name: name,
        ingredients: ingredients,
        servings: servings,
        isDeleted: isDeleted,
      );
    } catch (e) {
      debugPrint('Error in RecipeModel.fromMap: $e');
      return RecipeModel(id: id, name: 'Error Loading Recipe', ingredients: [], servings: 1);
    }
  }
}
