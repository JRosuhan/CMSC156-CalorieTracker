// main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'models/food_log.dart';
import 'models/recipe_model.dart';
import 'models/user_model.dart';
import 'screens/add_food_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/bin_screen.dart';
import 'screens/goal_setting_screen.dart';
import 'screens/home_screen.dart';
import 'screens/recipe_builder_screen.dart';
import 'screens/recipe_list_screen.dart';
import 'services/chatbot_api_service.dart';
import 'services/firebase_service.dart' as fs;
import 'widgets/macro_info.dart';
import 'widgets/serving_edit_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: .env not found or failed to load: $e');
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

enum AppScreen {
  auth,
  goal,
  home,
  addFood,
  bin,
  recipeList,
  recipeBuilder,
}

class _MyAppState extends State<MyApp> {
  final fs.FirebaseService _firebaseService = fs.FirebaseService();
  AppScreen currentScreen = AppScreen.auth;

  UserModel? currentUser;
  DateTime selectedDate = DateTime.now();

  List<FoodLog> foodLogs = [];
  List<FoodLog> deletedLogs = [];
  List<RecipeModel> recipes = [];
  List<RecipeModel> deletedRecipes = [];

  RecipeModel? editingRecipe;

  StreamSubscription? _foodLogsSubscription;
  StreamSubscription? _deletedLogsSubscription;
  StreamSubscription? _recipesSubscription;
  StreamSubscription? _deletedRecipesSubscription;

  @override
  void dispose() {
    _foodLogsSubscription?.cancel();
    _deletedLogsSubscription?.cancel();
    _recipesSubscription?.cancel();
    _deletedRecipesSubscription?.cancel();
    super.dispose();
  }

  void _listenToData() {
    _foodLogsSubscription?.cancel();
    _foodLogsSubscription = _firebaseService.getFoodLogsStream().listen(
      (logs) {
        setState(() {
          foodLogs = logs;
        });
      },
      onError: (e) => debugPrint('Error in foodLogsStream: $e'),
    );

    _deletedLogsSubscription?.cancel();
    _deletedLogsSubscription = _firebaseService.getDeletedFoodLogsStream().listen(
      (logs) {
        setState(() {
          deletedLogs = logs;
        });
      },
      onError: (e) => debugPrint('Error in deletedLogsStream: $e'),
    );

    _recipesSubscription?.cancel();
    _recipesSubscription = _firebaseService.getRecipesStream().listen(
      (r) {
        setState(() {
          recipes = r;
        });
      },
      onError: (e) => debugPrint('Error in recipesStream: $e'),
    );

    _deletedRecipesSubscription?.cancel();
    _deletedRecipesSubscription = _firebaseService.getDeletedRecipesStream().listen(
      (r) {
        setState(() {
          deletedRecipes = r;
        });
      },
      onError: (e) => debugPrint('Error in deletedRecipesStream: $e'),
    );
  }

  // ---------------- LOGIN ----------------

  Future<void> handleLogin(String email) async {
    final userProfile = await _firebaseService.fetchUserGoal();

    setState(() {
      if (userProfile != null) {
        currentUser = userProfile;
      } else {
        currentUser = UserModel(
          email: email,
          dailyCalorieGoal: 2000,
        );
      }

      _listenToData();

      if (userProfile == null) {
        currentScreen = AppScreen.goal;
      } else {
        currentScreen = AppScreen.home;
      }
    });
  }

  // ---------------- SET GOAL ----------------

  Future<void> handleSetGoal(UserModel userProfile) async {
    await _firebaseService.saveUserGoal(userProfile);
    setState(() {
      currentUser = userProfile;
      currentScreen = AppScreen.home;
    });
  }

  // ---------------- RECIPES ----------------

  Future<void> handleSaveRecipe(RecipeModel recipe) async {
    try {
      if (recipe.id.isEmpty) {
        await _firebaseService.addRecipe(recipe);
      } else {
        await _firebaseService.updateRecipe(recipe);
      }
      if (mounted) {
        setState(() {
          editingRecipe = null;
          currentScreen = AppScreen.recipeList;
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> handleLogRecipe(RecipeModel recipe) async {
    final now = DateTime.now();
    final logTimestamp = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    final newLog = FoodLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: recipe.name,
      calories: recipe.caloriesPerServing,
      protein: recipe.proteinPerServing,
      carbs: recipe.carbsPerServing,
      fats: recipe.fatsPerServing,
      servingSize: '1 serving',
      timestamp: logTimestamp,
      quantity: 1.0,
      availableMeasures: [
        {'label': 'serving', 'weight': 1.0}
      ],
      selectedMeasureIndex: 0,
      baseCalories: recipe.caloriesPerServing,
      baseProtein: recipe.proteinPerServing,
      baseCarbs: recipe.carbsPerServing,
      baseFats: recipe.fatsPerServing,
    );

    await _firebaseService.addFoodLog(newLog);
    setState(() {
      currentScreen = AppScreen.home;
    });
  }

  Future<void> handleEditRecipe(RecipeModel recipe) async {
    setState(() {
      editingRecipe = recipe;
      currentScreen = AppScreen.recipeBuilder;
    });
  }

  void showLogRecipeDialog(BuildContext context, RecipeModel recipe) {
    String selectedUnit = 'Servings';
    double quantity = 1.0;
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final int calculatedCalories = selectedUnit == 'Servings'
                ? (recipe.caloriesPerServing * quantity).toInt()
                : (recipe.caloriesPer100g * quantity / 100.0).toInt();

            final double calculatedProtein = selectedUnit == 'Servings'
                ? (recipe.proteinPerServing * quantity)
                : (recipe.proteinPer100g * quantity / 100.0);
            final double calculatedCarbs = selectedUnit == 'Servings'
                ? (recipe.carbsPerServing * quantity)
                : (recipe.carbsPer100g * quantity / 100.0);
            final double calculatedFats = selectedUnit == 'Servings'
                ? (recipe.fatsPerServing * quantity)
                : (recipe.fatsPer100g * quantity / 100.0);

            return AlertDialog(
              title: Text('Log ${recipe.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How much are you eating?'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.zero,
                          ),
                          controller: quantityController,
                          onChanged: (val) {
                            setDialogState(() {
                              quantity = double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedUnit,
                              isExpanded: true,
                              items: ['Servings', 'Grams'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selectedUnit = val;
                                    if (selectedUnit == 'Grams') {
                                      quantity = recipe.servings > 0
                                          ? (recipe.totalWeight / recipe.servings)
                                          : 100.0;
                                      quantityController.text = quantity.toStringAsFixed(0);
                                    } else {
                                      quantity = 1.0;
                                      quantityController.text = '1';
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Calories:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '$calculatedCalories cal',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            MacroInfo(label: 'P', value: '${calculatedProtein.toStringAsFixed(1)}g'),
                            MacroInfo(label: 'C', value: '${calculatedCarbs.toStringAsFixed(1)}g'),
                            MacroInfo(label: 'F', value: '${calculatedFats.toStringAsFixed(1)}g'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    final logTimestamp = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      now.hour,
                      now.minute,
                      now.second,
                    );

                    final double factorForNutrients = selectedUnit == 'Servings'
                        ? (recipe.servings > 0 ? quantity / recipe.servings : 0)
                        : (recipe.totalWeight > 0 ? quantity / recipe.totalWeight : 0);

                    final newLog = FoodLog(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: recipe.name,
                      calories: calculatedCalories,
                      protein: recipe.totalProtein * factorForNutrients,
                      carbs: recipe.totalCarbs * factorForNutrients,
                      fats: recipe.totalFats * factorForNutrients,
                      servingSize: selectedUnit == 'Servings'
                          ? (quantity == 1.0 ? '1 serving' : '${quantity.toString().replaceAll('.0', '')} servings')
                          : '${quantity.toString().replaceAll('.0', '')} g',
                      timestamp: logTimestamp,
                      quantity: quantity,
                      availableMeasures: [
                        {
                          'label': selectedUnit,
                          'weight': selectedUnit == 'Servings'
                              ? (recipe.servings > 0 ? (recipe.totalWeight / recipe.servings) : 1.0)
                              : 1.0
                        }
                      ],
                      selectedMeasureIndex: 0,
                      baseCalories: recipe.caloriesPer100g.toInt(),
                      baseProtein: recipe.proteinPer100g,
                      baseCarbs: recipe.carbsPer100g,
                      baseFats: recipe.fatsPer100g,
                    );

                    _firebaseService.addFoodLog(newLog);
                    setState(() {
                      currentScreen = AppScreen.home;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  child: const Text('Log', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> handleSoftDeleteRecipe(String id) async {
    await _firebaseService.softDeleteRecipe(id);
  }

  Future<void> handleRestoreRecipe(String id) async {
    await _firebaseService.restoreRecipe(id);
  }

  Future<void> handlePermanentDeleteRecipe(String id) async {
    await _firebaseService.hardDeleteRecipe(id);
  }

  // ---------------- ADD FOOD ----------------

  Future<void> handleAddFood({
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
  }) async {
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
    );

    await _firebaseService.addFoodLog(newFood);

    setState(() {
      currentScreen = AppScreen.home;
    });
  }

  // ---------------- DELETE FOOD ----------------

  Future<void> handleDeleteFood(String id) async {
    await _firebaseService.softDeleteFoodLog(id);
  }

  Future<void> handleRestoreFood(String id) async {
    await _firebaseService.restoreFoodLog(id);
  }

  Future<void> handlePermanentDeleteFood(String id) async {
    await _firebaseService.hardDeleteFoodLog(id);
  }

  // ---------------- EDIT FOOD ----------------

  Future<void> handleEditFood(FoodLog updatedLog) async {
    await _firebaseService.updateFoodLog(updatedLog);
  }

  void showEditDialog(BuildContext context, FoodLog log) {
    final List<Map<String, dynamic>> measures = log.availableMeasures.isNotEmpty
        ? log.availableMeasures
        : [
            {'label': 'serving', 'weight': 100.0}
          ];

    int currentMeasureIndex = log.selectedMeasureIndex;
    if (currentMeasureIndex < 0 || currentMeasureIndex >= measures.length) {
      currentMeasureIndex = 0;
    }

    showServingEditDialog(
      context: context,
      title: 'Edit ${log.name}',
      initialQuantity: log.quantity,
      initialMeasureIndex: currentMeasureIndex,
      measures: measures,
      baseCalories: log.baseCalories,
      baseProtein: log.baseProtein,
      baseCarbs: log.baseCarbs,
      baseFats: log.baseFats,
      onSave: (result) {
        final updated = FoodLog(
          id: log.id,
          name: log.name,
          calories: result.calories,
          protein: result.protein,
          carbs: result.carbs,
          fats: result.fats,
          servingSize: result.servingSize,
          timestamp: log.timestamp,
          quantity: result.quantity,
          availableMeasures: measures,
          selectedMeasureIndex: result.measureIndex,
          baseCalories: log.baseCalories,
          baseProtein: log.baseProtein,
          baseCarbs: log.baseCarbs,
          baseFats: log.baseFats,
        );
        handleEditFood(updated);
      },
    );
  }

  // ---------------- LOGOUT ----------------

  Future<void> handleLogout() async {
    await _firebaseService.signOut();
    _foodLogsSubscription?.cancel();
    _deletedLogsSubscription?.cancel();
    _recipesSubscription?.cancel();
    _deletedRecipesSubscription?.cancel();
    ChatbotApiService().clearHistory();
    setState(() {
      currentUser = null;
      editingRecipe = null;
      foodLogs.clear();
      deletedLogs.clear();
      recipes.clear();
      deletedRecipes.clear();
      currentScreen = AppScreen.auth;
    });
  }

  // ---------------- NAVIGATION ----------------

  void goToAddFood() {
    setState(() {
      currentScreen = AppScreen.addFood;
    });
  }

  void goToGoalEdit() {
    setState(() {
      currentScreen = AppScreen.goal;
    });
  }

  void goBackHome() {
    setState(() {
      currentScreen = AppScreen.home;
    });
  }

  void goToBin() {
    setState(() {
      currentScreen = AppScreen.bin;
    });
  }

  void goToRecipeList() {
    setState(() {
      currentScreen = AppScreen.recipeList;
    });
  }

  void goToRecipeBuilder() {
    setState(() {
      currentScreen = AppScreen.recipeBuilder;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NomNomTracker',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
        ),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (innerContext) => buildCurrentScreen(innerContext),
      ),
    );
  }

  Widget buildCurrentScreen(BuildContext context) {
    if (currentUser == null && currentScreen != AppScreen.auth) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (currentScreen) {
      case AppScreen.auth:
        return AuthScreen(
          onLogin: handleLogin,
        );

      case AppScreen.goal:
        return GoalSettingScreen(
          email: currentUser!.email,
          onSetGoal: handleSetGoal,
        );

      case AppScreen.home:
        return HomeScreen(
          user: currentUser!,
          foodLogs: foodLogs,
          selectedDate: selectedDate,
          onDateChanged: (date) {
            setState(() {
              selectedDate = date;
            });
          },
          onAddFood: goToAddFood,
          onDeleteFood: (id) => handleDeleteFood(id),
          onEditFood: (log) => showEditDialog(context, log),
          onEditGoal: goToGoalEdit,
          onLogout: handleLogout,
          onGoToBin: goToBin,
          onGoToRecipes: goToRecipeList,
        );

      case AppScreen.addFood:
        return AddFoodScreenWrapper(
          onBack: goBackHome,
          onAddFood: handleAddFood,
        );

      case AppScreen.bin:
        return BinScreen(
          deletedLogs: deletedLogs,
          deletedRecipes: deletedRecipes,
          onRestoreLog: handleRestoreFood,
          onPermanentDeleteLog: handlePermanentDeleteFood,
          onRestoreRecipe: handleRestoreRecipe,
          onPermanentDeleteRecipe: handlePermanentDeleteRecipe,
          onBack: goBackHome,
        );

      case AppScreen.recipeList:
        return RecipeListScreen(
          recipes: recipes,
          onLogRecipe: (recipe) => showLogRecipeDialog(context, recipe),
          onEditRecipe: handleEditRecipe,
          onDeleteRecipe: handleSoftDeleteRecipe,
          onCreateNew: () {
            setState(() {
              editingRecipe = null;
              currentScreen = AppScreen.recipeBuilder;
            });
          },
          onBack: goBackHome,
        );

      case AppScreen.recipeBuilder:
        return RecipeBuilderScreen(
          initialRecipe: editingRecipe,
          onSaveRecipe: handleSaveRecipe,
          onBack: () {
            setState(() {
              editingRecipe = null;
              currentScreen = AppScreen.recipeList;
            });
          },
        );
    }
  }
}
