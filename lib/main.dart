// main.dart

import 'package:flutter/material.dart';

import 'models/user_model.dart';
import 'models/food_log.dart';

import 'screens/auth_screen.dart';
import 'screens/goal_setting_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_food_screen.dart';

void main() {
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
}

class _MyAppState extends State<MyApp> {
  AppScreen currentScreen = AppScreen.auth;

  UserModel? currentUser;

  List<FoodLog> foodLogs = [];

  // ---------------- LOGIN ----------------

  void handleLogin(String email) {
    setState(() {
      currentUser = UserModel(
        email: email,
        dailyCalorieGoal: 2000,
      );

      currentScreen = AppScreen.goal;
    });
  }

  // ---------------- SET GOAL ----------------

  void handleSetGoal(int goal) {
    setState(() {
      currentUser = UserModel(
        email: currentUser!.email,
        dailyCalorieGoal: goal,
      );

      currentScreen = AppScreen.home;
    });
  }

  // ---------------- ADD FOOD ----------------

  void handleAddFood({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
    required String servingSize,
  }) {
    final newFood = FoodLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      servingSize: servingSize,
      timestamp: DateTime.now(),
    );

    setState(() {
      foodLogs.add(newFood);

      currentScreen = AppScreen.home;
    });
  }

  // ---------------- DELETE FOOD ----------------

  void handleDeleteFood(String id) {
    setState(() {
      foodLogs.removeWhere((food) => food.id == id);
    });
  }

  // ---------------- LOGOUT ----------------

  void handleLogout() {
    setState(() {
      currentUser = null;
      foodLogs.clear();

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

      home: buildCurrentScreen(),
    );
  }

  Widget buildCurrentScreen() {
    switch (currentScreen) {
      case AppScreen.auth:
        return AuthScreen(
          onLogin: handleLogin,
        );

      case AppScreen.goal:
        return GoalSettingScreen(
          onSetGoal: handleSetGoal,
        );

      case AppScreen.home:
        return HomeScreen(
          user: currentUser!,
          foodLogs: foodLogs,
          onAddFood: goToAddFood,
          onDeleteFood: handleDeleteFood,
          onEditGoal: goToGoalEdit,
          onLogout: handleLogout,
        );

      case AppScreen.addFood:
        return AddFoodScreenWrapper(
          onBack: goBackHome,
          onAddFood: handleAddFood,
        );
    }
  }
}

// ---------------- ADD FOOD WRAPPER ----------------

class AddFoodScreenWrapper extends StatelessWidget {
  final VoidCallback onBack;

  final Function({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
    required String servingSize,
  }) onAddFood;

  const AddFoodScreenWrapper({
    super.key,
    required this.onBack,
    required this.onAddFood,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AddFoodScreenContent(
        onBack: onBack,
        onAddFood: onAddFood,
      ),
    );
  }
}

// ---------------- ADD FOOD CONTENT ----------------

class AddFoodScreenContent extends StatefulWidget {
  final VoidCallback onBack;

  final Function({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
    required String servingSize,
  }) onAddFood;

  const AddFoodScreenContent({
    super.key,
    required this.onBack,
    required this.onAddFood,
  });

  @override
  State<AddFoodScreenContent> createState() =>
      _AddFoodScreenContentState();
}

class _AddFoodScreenContentState
    extends State<AddFoodScreenContent> {
  final List<Map<String, dynamic>> foods = [
    {
      'name': 'Grilled Chicken Breast',
      'calories': 165,
      'protein': 31.0,
      'carbs': 0.0,
      'fats': 3.6,
      'servingSize': '100g',
    },
    {
      'name': 'Brown Rice',
      'calories': 111,
      'protein': 2.6,
      'carbs': 23.0,
      'fats': 0.9,
      'servingSize': '100g',
    },
    {
      'name': 'Banana',
      'calories': 89,
      'protein': 1.1,
      'carbs': 23.0,
      'fats': 0.3,
      'servingSize': '1 medium',
    },
  ];

  String search = '';

  @override
  Widget build(BuildContext context) {
    final filteredFoods = foods.where((food) {
      return food['name']
          .toString()
          .toLowerCase()
          .contains(search.toLowerCase());
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Add Food',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search food...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: filteredFoods.length,
                itemBuilder: (context, index) {
                  final food = filteredFoods[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      title: Text(food['name']),
                      subtitle: Text(
                        '${food['calories']} cal',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          widget.onAddFood(
                            name: food['name'],
                            calories: food['calories'],
                            protein: food['protein'],
                            carbs: food['carbs'],
                            fats: food['fats'],
                            servingSize: food['servingSize'],
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF10B981),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}