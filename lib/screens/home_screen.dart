import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../models/food_log.dart';
import '../widgets/chatbot_widget.dart';
import '../widgets/macro_card.dart';
import '../widgets/nutrient_gauge.dart';
import '../providers/auth_provider.dart';
import '../providers/data_providers.dart';
import '../providers/ui_state_providers.dart';
import '../widgets/serving_edit_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final foodLogsAsync = ref.watch(foodLogsProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return foodLogsAsync.when(
      data: (foodLogs) => _HomeScreenContent(
        user: user,
        foodLogs: foodLogs,
        selectedDate: selectedDate,
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _HomeScreenContent extends ConsumerWidget {
  final UserModel user;
  final List<FoodLog> foodLogs;
  final DateTime selectedDate;

  const _HomeScreenContent({
    required this.user,
    required this.foodLogs,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter logs for the selected date
    final dailyLogs = foodLogs.where((log) {
      return log.timestamp.year == selectedDate.year &&
          log.timestamp.month == selectedDate.month &&
          log.timestamp.day == selectedDate.day;
    }).toList();

    final totalCalories = dailyLogs.fold(0, (sum, item) => sum + item.calories);
    final totalProtein = dailyLogs.fold(0.0, (sum, item) => sum + item.protein);
    final totalCarbs = dailyLogs.fold(0.0, (sum, item) => sum + item.carbs);
    final totalFats = dailyLogs.fold(0.0, (sum, item) => sum + item.fats);

    final goal = user.dailyCalorieGoal;

    String formatDate(DateTime date) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final d = DateTime(date.year, date.month, date.day);

      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final monthName = months[date.month - 1];
      final day = date.day;

      if (d == today) return 'Today, $monthName $day';
      if (d == yesterday) return 'Yesterday, $monthName $day';

      return '$monthName $day, ${date.year}';
    }

    String formatDateTime(DateTime date) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final monthName = months[date.month - 1];
      final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '$monthName ${date.day}, ${date.year} • $hour:$minute $period';
    }

    void showSnackBar(String message, {bool isError = false}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: () => context.push('/add-food'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Section (Macros & Goal)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF059669)],
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Hi, ${(user.email.isNotEmpty ? user.email : "User").split('@')[0]} 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      ref.read(userProvider.notifier).logout();
                                    },
                                    icon: const Icon(Icons.logout, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _showFullCalendar(context, ref, selectedDate),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatDate(selectedDate),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          NutrientGauge(
                            totalCalories: totalCalories,
                            goalCalories: goal,
                            activeColor: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => context.push('/goal-setting'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Update Goal',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              MacroCard(
                                title: 'Protein',
                                value: '${totalProtein.toStringAsFixed(1)}g',
                                color: Colors.blue,
                                progress: (totalProtein / 100).clamp(0.0, 1.0),
                              ),
                              const SizedBox(width: 8),
                              MacroCard(
                                title: 'Carbs',
                                value: '${totalCarbs.toStringAsFixed(1)}g',
                                color: Colors.orange,
                                progress: (totalCarbs / 250).clamp(0.0, 1.0),
                              ),
                              const SizedBox(width: 8),
                              MacroCard(
                                title: 'Fats',
                                value: '${totalFats.toStringAsFixed(1)}g',
                                color: Colors.purple,
                                progress: (totalFats / 70).clamp(0.0, 1.0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () => context.push('/recipes'),
                                icon: const Icon(Icons.restaurant_menu, size: 18),
                                label: const Text('My Recipes'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF059669),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => context.push('/bin'),
                                icon: const Icon(Icons.delete_sweep, size: 18),
                                label: const Text('View Recycle Bin'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[600],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bottom List Section (Food Logs)
                Expanded(
                  child: dailyLogs.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.restaurant_menu, color: Colors.grey, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'Your plate is empty!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Ready to log your first meal?',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: dailyLogs.length,
                          itemBuilder: (context, index) {
                            final food = dailyLogs[index];

                            return Dismissible(
                              key: Key(food.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                ref.read(firebaseServiceProvider).softDeleteFoodLog(food.id);
                                showSnackBar('Moved to Recycle Bin. 🗑️');
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    title: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            food.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (food.fromRecipe)
                                          Container(
                                            margin: const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Recipe',
                                              style: TextStyle(
                                                color: Color(0xFF059669),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${formatDateTime(food.timestamp)} • ${food.servingSize}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${food.calories}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'cal',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _showEditDialog(context, ref, food);
                                        },
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            // Chatbot overlay
            const Positioned(
              right: 0,
              bottom: 80, // Positioned above the FAB
              child: ChatbotWidget(),
            ),
          ],
        ),
      ),
    );
  }

    void _showEditDialog(BuildContext context, WidgetRef ref, FoodLog log) {
    final List<Map<String, dynamic>> measures = log.fromRecipe
        ? [
            {'label': 'Servings', 'weight': log.availableMeasures.isNotEmpty ? (log.availableMeasures[0]['weight'] ?? 100.0) : 100.0},
            {'label': 'Grams', 'weight': 1.0},
          ]
        : log.availableMeasures.isNotEmpty
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
          fromRecipe: log.fromRecipe,
        );
        ref.read(firebaseServiceProvider).updateFoodLog(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal updated! ✨'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Future<void> _showFullCalendar(BuildContext context, WidgetRef ref, DateTime currentDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != currentDate) {
      ref.read(selectedDateProvider.notifier).setDate(picked);
    }
  }
}
