import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../models/food_log.dart';
import '../models/recipe_model.dart';
import '../services/chatbot_api_service.dart';
import '../services/edamam_service.dart';

final edamamServiceProvider = Provider((ref) => EdamamService());

final chatbotApiServiceProvider = Provider((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final edamamService = ref.watch(edamamServiceProvider);
  return ChatbotApiService(
    firebaseService: firebaseService,
    edamamService: edamamService,
  );
});

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
