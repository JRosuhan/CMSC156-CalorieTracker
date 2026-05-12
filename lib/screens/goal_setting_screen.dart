// screens/goal_setting_screen.dart

import 'package:flutter/material.dart';

class GoalSettingScreen extends StatefulWidget {
  final Function(int goal) onSetGoal;

  const GoalSettingScreen({
    super.key,
    required this.onSetGoal,
  });

  @override
  State<GoalSettingScreen> createState() =>
      _GoalSettingScreenState();
}

class _GoalSettingScreenState
    extends State<GoalSettingScreen> {
  String goalType = 'maintain';

  double calories = 2000;

  final List<Map<String, dynamic>> goalOptions = [
    {
      'type': 'cut',
      'label': 'Cut',
      'icon': Icons.trending_down,
      'color1': Color(0xFFEF4444),
      'color2': Color(0xFFF97316),
      'defaultCalories': 1800,
    },
    {
      'type': 'maintain',
      'label': 'Maintain',
      'icon': Icons.remove,
      'color1': Color(0xFF3B82F6),
      'color2': Color(0xFF06B6D4),
      'defaultCalories': 2200,
    },
    {
      'type': 'bulk',
      'label': 'Bulk',
      'icon': Icons.trending_up,
      'color1': Color(0xFFA855F7),
      'color2': Color(0xFFEC4899),
      'defaultCalories': 2800,
    },
  ];

  void selectGoal(Map<String, dynamic> goal) {
    setState(() {
      goalType = goal['type'];
      calories = goal['defaultCalories'].toDouble();
    });
  }

  void handleSubmit() {
    widget.onSetGoal(calories.toInt());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF4ADE80),
                              Color(0xFF059669),
                            ],
                          ),
                          borderRadius:
                              BorderRadius.all(
                            Radius.circular(24),
                          ),
                        ),
                        child: const Icon(
                          Icons.flag,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Set Your Goal',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Let's personalize your journey",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  "What's your goal?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: goalOptions.map((goal) {
                    final bool isSelected =
                        goalType == goal['type'];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          selectGoal(goal);
                        },
                        child: Container(
                          margin:
                              const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green
                                    .withOpacity(0.08)
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                                    18),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(
                                      0xFF10B981)
                                  : Colors.grey
                                      .shade300,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration:
                                    BoxDecoration(
                                  gradient:
                                      LinearGradient(
                                    colors: [
                                      goal[
                                          'color1'],
                                      goal[
                                          'color2'],
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              14),
                                ),
                                child: Icon(
                                  goal['icon'],
                                  color:
                                      Colors.white,
                                ),
                              ),

                              const SizedBox(
                                  height: 10),

                              Text(
                                goal['label'],
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),

                const Text(
                  'Daily calorie target',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        calories
                            .toInt()
                            .toString(),
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'calories per day',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 30),

                      Slider(
                        value: calories,
                        min: 1000,
                        max: 4000,
                        divisions: 60,
                        activeColor:
                            const Color(
                                0xFF10B981),
                        onChanged: (value) {
                          setState(() {
                            calories = value;
                          });
                        },
                      ),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: const [
                          Text(
                            '1000',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '4000',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding:
                      const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          Colors.blue.shade100,
                    ),
                  ),
                  child: const Text(
                    'Tip: Your calorie goal depends on your activity level and goals. You can always adjust this later!',
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: handleSubmit,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                              0xFF10B981),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 18,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(18),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}