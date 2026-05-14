// main.dart

import 'package:flutter/material.dart';

import 'models/user_model.dart';
import 'models/food_log.dart';

import 'screens/auth_screen.dart';
import 'screens/goal_setting_screen.dart';
import 'screens/home_screen.dart';
import 'screens/bin_screen.dart';
import 'services/edamam_service.dart';
import 'services/firebase_service.dart' as fs;
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
}

class _MyAppState extends State<MyApp> {
  final fs.FirebaseService _firebaseService = fs.FirebaseService();
  AppScreen currentScreen = AppScreen.auth;

  UserModel? currentUser;
  DateTime selectedDate = DateTime.now();

  List<FoodLog> foodLogs = [];
  List<FoodLog> deletedLogs = [];
  StreamSubscription? _foodLogsSubscription;
  StreamSubscription? _deletedLogsSubscription;

  @override
  void dispose() {
    _foodLogsSubscription?.cancel();
    _deletedLogsSubscription?.cancel();
    super.dispose();
  }

  void _listenToFoodLogs() {
    _foodLogsSubscription?.cancel();
    _foodLogsSubscription = _firebaseService.getFoodLogsStream().listen((logs) {
      setState(() {
        foodLogs = logs;
      });
    });

    _deletedLogsSubscription?.cancel();
    _deletedLogsSubscription = _firebaseService.getDeletedFoodLogsStream().listen((logs) {
      setState(() {
        deletedLogs = logs;
      });
    });
  }

  // ---------------- LOGIN ----------------

  Future<void> handleLogin(String email) async {
    final goal = await _firebaseService.fetchUserGoal();

    setState(() {
      currentUser = UserModel(
        email: email,
        dailyCalorieGoal: goal ?? 2000,
      );

      _listenToFoodLogs();

      if (goal == null) {
        currentScreen = AppScreen.goal;
      } else {
        currentScreen = AppScreen.home;
      }
    });
  }

  // ---------------- SET GOAL ----------------

  Future<void> handleSetGoal(int goal) async {
    await _firebaseService.saveUserGoal(goal);
    setState(() {
      currentUser = UserModel(
        email: currentUser!.email,
        dailyCalorieGoal: goal,
      );

      currentScreen = AppScreen.home;
    });
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
    // Combine selected date with current time
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
    double currentQuantity = log.quantity;
    int currentMeasureIndex = log.selectedMeasureIndex;
    final quantityController = TextEditingController(
      text: currentQuantity.toString().replaceAll('.0', ''),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double unitWeight = log.availableMeasures[currentMeasureIndex]['weight'] ?? 100.0;
            final double totalWeight = currentQuantity * unitWeight;
            final double factor = totalWeight / 100.0;

            final int calculatedCalories = (log.baseCalories * factor).toInt();

            return AlertDialog(
              title: Text('Edit ${log.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Adjust your serving size:'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(
                        width: 70,
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
                              currentQuantity = double.tryParse(val) ?? 0.0;
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
                            child: DropdownButton<int>(
                              value: currentMeasureIndex,
                              isExpanded: true,
                              items: List.generate(log.availableMeasures.length, (i) {
                                return DropdownMenuItem(
                                  value: i,
                                  child: Text(log.availableMeasures[i]['label']),
                                );
                              }),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    currentMeasureIndex = val;
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('New Total:'),
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
                    final String unitLabel = log.availableMeasures[currentMeasureIndex]['label'];
                    final updated = FoodLog(
                      id: log.id,
                      name: log.name,
                      calories: calculatedCalories,
                      protein: log.baseProtein * factor,
                      carbs: log.baseCarbs * factor,
                      fats: log.baseFats * factor,
                      servingSize: currentQuantity == 1.0 ? unitLabel : '${currentQuantity.toString().replaceAll('.0', '')} $unitLabel',
                      timestamp: log.timestamp,
                      quantity: currentQuantity,
                      availableMeasures: log.availableMeasures,
                      selectedMeasureIndex: currentMeasureIndex,
                      baseCalories: log.baseCalories,
                      baseProtein: log.baseProtein,
                      baseCarbs: log.baseCarbs,
                      baseFats: log.baseFats,
                    );
                    handleEditFood(updated);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  child: const Text('Update', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- LOGOUT ----------------

  Future<void> handleLogout() async {
    await _firebaseService.signOut();
    _foodLogsSubscription?.cancel();
    _deletedLogsSubscription?.cancel();
    setState(() {
      currentUser = null;
      foodLogs.clear();
      deletedLogs.clear();

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
        );

      case AppScreen.addFood:
        return AddFoodScreenWrapper(
          onBack: goBackHome,
          onAddFood: handleAddFood,
        );

      case AppScreen.bin:
        return BinScreen(
          deletedLogs: deletedLogs,
          onRestore: (id) => handleRestoreFood(id),
          onPermanentDelete: (id) => handlePermanentDeleteFood(id),
          onBack: goBackHome,
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
    required double quantity,
    required List<Map<String, dynamic>> availableMeasures,
    required int selectedMeasureIndex,
    required int baseCalories,
    required double baseProtein,
    required double baseCarbs,
    required double baseFats,
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
    required double quantity,
    required List<Map<String, dynamic>> availableMeasures,
    required int selectedMeasureIndex,
    required int baseCalories,
    required double baseProtein,
    required double baseCarbs,
    required double baseFats,
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
  late EdamamService _edamamService;
  List<Map<String, dynamic>> _foodResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _edamamService = EdamamService();
    _foodResults = [];
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      if (query.length < 3) {
        if (mounted) {
          setState(() {
            _foodResults = [];
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      try {
        final results = await _edamamService.searchFood(query);
        if (mounted) {
          setState(() {
            _foodResults = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              onChanged: _onSearchChanged,
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _foodResults.isEmpty
                      ? const Center(child: Text('Search for some food!'))
                      : ListView.builder(
                          itemCount: _foodResults.length,
                          itemBuilder: (context, index) {
                            final food = _foodResults[index];
                            
                            // Initialize default values if not present
                            food['quantity'] ??= 1.0;
                            final List measures = food['measures'] ?? [];
                            
                            // Try to find 'Gram' or default to first measure
                            food['selectedMeasureIndex'] ??= measures.indexWhere(
                              (m) => m['label'].toString().toLowerCase() == 'gram'
                            );
                            if (food['selectedMeasureIndex'] == -1 && measures.isNotEmpty) {
                              food['selectedMeasureIndex'] = 0;
                            }

                            final quantityController = TextEditingController(
                              text: food['quantity'].toString().replaceAll('.0', ''),
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: food['image'] != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                food['image'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) =>
                                                    const Icon(Icons.fastfood),
                                              ),
                                            )
                                          : const Icon(Icons.fastfood),
                                      title: Text(
                                        food['name'] ?? 'Unknown',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        '${food['calories'] ?? 0} cal per 100g',
                                      ),
                                    ),
                                    const Divider(),
                                    Row(
                                      children: [
                                        // Quantity Input
                                        SizedBox(
                                          width: 60,
                                          height: 45,
                                          child: TextField(
                                            controller: quantityController,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.zero,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            onChanged: (val) {
                                              food['quantity'] = double.tryParse(val) ?? 1.0;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Unit Dropdown
                                        Expanded(
                                          child: Container(
                                            height: 45,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade400),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<int>(
                                                value: food['selectedMeasureIndex'],
                                                isExpanded: true,
                                                items: List.generate(measures.length, (i) {
                                                  return DropdownMenuItem(
                                                    value: i,
                                                    child: Text(measures[i]['label']),
                                                  );
                                                }),
                                                onChanged: (val) {
                                                  setState(() {
                                                    food['selectedMeasureIndex'] = val;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Add Button
                                        ElevatedButton(
                                          onPressed: () {
                                            final double q = food['quantity'] ?? 1.0;
                                            final int mIdx = food['selectedMeasureIndex'] ?? 0;
                                            final double unitWeight = measures[mIdx]['weight'] ?? 100.0;
                                            final String unitLabel = measures[mIdx]['label'] ?? 'g';
                                            
                                            final double totalWeight = q * unitWeight;
                                            final double factor = totalWeight / 100.0;

                                            widget.onAddFood(
                                              name: food['name'] ?? 'Unknown',
                                              calories: ((food['calories'] ?? 0) * factor).toInt(),
                                              protein: (food['protein'] ?? 0.0) * factor,
                                              carbs: (food['carbs'] ?? 0.0) * factor,
                                              fats: (food['fats'] ?? 0.0) * factor,
                                              servingSize: q == 1.0 ? unitLabel : '${q.toString().replaceAll('.0', '')} $unitLabel',
                                              quantity: q,
                                              availableMeasures: List<Map<String, dynamic>>.from(measures),
                                              selectedMeasureIndex: mIdx,
                                              baseCalories: food['calories'] ?? 0,
                                              baseProtein: food['protein'] ?? 0.0,
                                              baseCarbs: food['carbs'] ?? 0.0,
                                              baseFats: food['fats'] ?? 0.0,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF10B981),
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Add',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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