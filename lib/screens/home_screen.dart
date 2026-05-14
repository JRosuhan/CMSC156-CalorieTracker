// screens/home_screen.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/food_log.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  final List<FoodLog> foodLogs;
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  final VoidCallback onAddFood;
  final Function(String id) onDeleteFood;
  final Function(FoodLog log) onEditFood;
  final VoidCallback onEditGoal;
  final VoidCallback onLogout;
  final VoidCallback onGoToBin;

  const HomeScreen({
    super.key,
    required this.user,
    required this.foodLogs,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onAddFood,
    required this.onDeleteFood,
    required this.onEditFood,
    required this.onEditGoal,
    required this.onLogout,
    required this.onGoToBin,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    // Filter logs for the selected date
    final dailyLogs = widget.foodLogs.where((log) {
      return log.timestamp.year == widget.selectedDate.year &&
          log.timestamp.month == widget.selectedDate.month &&
          log.timestamp.day == widget.selectedDate.day;
    }).toList();

    final totalCalories = dailyLogs.fold(0, (sum, item) => sum + item.calories);

    final totalProtein = dailyLogs.fold(0.0, (sum, item) => sum + item.protein);

    final totalCarbs = dailyLogs.fold(0.0, (sum, item) => sum + item.carbs);

    final totalFats = dailyLogs.fold(0.0, (sum, item) => sum + item.fats);

    final progress = (totalCalories / widget.user.dailyCalorieGoal).clamp(
      0.0,
      1.0,
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: widget.onAddFood,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,\n${widget.user.email.split('@')[0]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDate(widget.selectedDate),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: widget.onLogout,
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),


                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.2),
                          borderRadius: BorderRadius.circular(16),
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
                                      onPressed: widget.onEditGoal,
                                      child: const Text(
                                        'Edit',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$totalCalories',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '/ ${widget.user.dailyCalorieGoal} cal',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ],
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
                              macroCard(
                                'Protein',
                                '${totalProtein.toStringAsFixed(1)}g',
                                Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              macroCard(
                                'Carbs',
                                '${totalCarbs.toStringAsFixed(1)}g',
                                Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              macroCard(
                                'Fats',
                                '${totalFats.toStringAsFixed(1)}g',
                                Colors.purple,
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: widget.onGoToBin,
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
                        child: Text('No meals logged for this day'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: dailyLogs.length,
                      itemBuilder: (context, index) {
                        final food = dailyLogs[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                                    widget.onEditFood(food);
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    widget.onDeleteFood(food.id);
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
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

  Widget macroCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
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
    if (picked != null && picked != widget.selectedDate) {
      widget.onDateChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Today";
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }
}
