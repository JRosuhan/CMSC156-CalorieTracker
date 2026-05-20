import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../models/food_log.dart';
import '../models/recipe_model.dart';

final foodLogsProvider = StreamProvider<List<FoodLog>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  return service.getFoodLogsStream();
});

final deletedFoodLogsProvider = StreamProvider<List<FoodLog>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  return service.getDeletedFoodLogsStream();
});

final recipesProvider = StreamProvider<List<RecipeModel>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  return service.getRecipesStream();
});

final deletedRecipesProvider = StreamProvider<List<RecipeModel>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  return service.getDeletedRecipesStream();
});
