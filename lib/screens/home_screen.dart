// screens/home_screen.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/food_log.dart';

class HomeScreen extends StatelessWidget {
  final UserModel user;
  final List<FoodLog> foodLogs;

  final VoidCallback onAddFood;
  final Function(String id) onDeleteFood;
  final Function(FoodLog log) onEditFood;
  final VoidCallback onEditGoal;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.user,
    required this.foodLogs,
    required this.onAddFood,
    required this.onDeleteFood,
    required this.onEditFood,
    required this.onEditGoal,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final totalCalories =
        foodLogs.fold(0, (sum, item) => sum + item.calories);

    final totalProtein =
        foodLogs.fold(0.0, (sum, item) => sum + item.protein);

    final totalCarbs =
        foodLogs.fold(0.0, (sum, item) => sum + item.carbs);

    final totalFats =
        foodLogs.fold(0.0, (sum, item) => sum + item.fats);

    final progress =
        (totalCalories / user.dailyCalorieGoal).clamp(0.0, 1.0);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: onAddFood,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF22C55E),
                    Color(0xFF059669),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Welcome back,\n${user.email.split('@')[0]}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onLogout,
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daily Goal',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextButton(
                              onPressed: onEditGoal,
                              child: const Text(
                                'Edit',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),

                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$totalCalories',
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '/ ${user.dailyCalorieGoal} cal',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  macroCard(
                    'Protein',
                    '${totalProtein.toStringAsFixed(1)}g',
                    Colors.blue,
                  ),
                  const SizedBox(width: 10),
                  macroCard(
                    'Carbs',
                    '${totalCarbs.toStringAsFixed(1)}g',
                    Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  macroCard(
                    'Fats',
                    '${totalFats.toStringAsFixed(1)}g',
                    Colors.purple,
                  ),
                ],
              ),
            ),

            Expanded(
              child: foodLogs.isEmpty
                  ? const Center(
                      child: Text('No meals logged yet'),
                    )
                  : ListView.builder(
                      itemCount: foodLogs.length,
                      itemBuilder: (context, index) {
                        final food = foodLogs[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            title: Text(food.name),
                            subtitle: Text(food.servingSize),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${food.calories} cal'),
                                IconButton(
                                  onPressed: () {
                                    onEditFood(food);
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    onDeleteFood(food.id);
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
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

  Widget macroCard(
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }
}