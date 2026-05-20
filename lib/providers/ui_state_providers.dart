import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';
import '../models/food_log.dart';

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(() {
  return SelectedDateNotifier();
});

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) {
    state = date;
  }
}

final editingRecipeProvider = NotifierProvider<EditingRecipeNotifier, RecipeModel?>(() {
  return EditingRecipeNotifier();
});

class EditingRecipeNotifier extends Notifier<RecipeModel?> {
  @override
  RecipeModel? build() => null;

  void setRecipe(RecipeModel? recipe) {
    state = recipe;
  }

  void addIngredient(FoodLog ingredient) {
    if (state == null) {
      state = RecipeModel(
        id: '',
        name: '',
        ingredients: [ingredient],
        servings: 1,
      );
    } else {
      state = RecipeModel(
        id: state!.id,
        name: state!.name,
        ingredients: [...state!.ingredients, ingredient],
        servings: state!.servings,
        isDeleted: state!.isDeleted,
      );
    }
  }

  void removeIngredient(int index) {
    if (state != null) {
      final newIngredients = List<FoodLog>.from(state!.ingredients)..removeAt(index);
      state = RecipeModel(
        id: state!.id,
        name: state!.name,
        ingredients: newIngredients,
        servings: state!.servings,
        isDeleted: state!.isDeleted,
      );
    }
  }

  void updateIngredient(int index, FoodLog updatedIngredient) {
    if (state != null) {
      final newIngredients = List<FoodLog>.from(state!.ingredients);
      newIngredients[index] = updatedIngredient;
      state = RecipeModel(
        id: state!.id,
        name: state!.name,
        ingredients: newIngredients,
        servings: state!.servings,
        isDeleted: state!.isDeleted,
      );
    }
  }

  void updateName(String name) {
    if (state != null) {
      state = RecipeModel(
        id: state!.id,
        name: name,
        ingredients: state!.ingredients,
        servings: state!.servings,
        isDeleted: state!.isDeleted,
      );
    } else {
      state = RecipeModel(
        id: '',
        name: name,
        ingredients: [],
        servings: 1,
      );
    }
  }

  void updateServings(int servings) {
    if (state != null) {
      state = RecipeModel(
        id: state!.id,
        name: state!.name,
        ingredients: state!.ingredients,
        servings: servings,
        isDeleted: state!.isDeleted,
      );
    }
  }
}
