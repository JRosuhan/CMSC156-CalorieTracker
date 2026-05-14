// screens/goal_setting_screen.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/calculator_utils.dart';

class GoalSettingScreen extends StatefulWidget {
  final String email;
  final Function(UserModel userProfile) onSetGoal;

  const GoalSettingScreen({
    super.key,
    required this.email,
    required this.onSetGoal,
  });

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  // Form Data
  String gender = 'Male';
  int age = 25;
  double weight = 70.0;
  double height = 170.0;
  String activityLevel = 'Moderately Active';
  String goalType = 'maintain';
  double manualCalories = 2000;

  // Controllers
  late TextEditingController ageController;
  late TextEditingController weightController;
  late TextEditingController heightController;
  late TextEditingController caloriesController;

  final List<String> activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extra Active'
  ];

  final List<Map<String, dynamic>> goalOptions = [
    {
      'type': 'cut',
      'label': 'Cut',
      'icon': Icons.trending_down,
      'color1': const Color(0xFFEF4444),
      'color2': const Color(0xFFF97316),
      'description': 'Lose weight (~0.5kg/week)',
    },
    {
      'type': 'maintain',
      'label': 'Maintain',
      'icon': Icons.remove,
      'color1': const Color(0xFF3B82F6),
      'color2': const Color(0xFF06B6D4),
      'description': 'Stay at current weight',
    },
    {
      'type': 'bulk',
      'label': 'Bulk',
      'icon': Icons.trending_up,
      'color1': const Color(0xFFA855F7),
      'color2': const Color(0xFFEC4899),
      'description': 'Gain muscle/weight',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    ageController = TextEditingController(text: age.toString());
    weightController = TextEditingController(text: weight.toString());
    heightController = TextEditingController(text: height.toString());
    caloriesController = TextEditingController(text: manualCalories.toInt().toString());

    // Perform initial calculation without setState
    final bmr = CalculatorUtils.calculateBMR(
      gender: gender,
      weight: weight,
      height: height,
      age: age,
    );
    final tdee = CalculatorUtils.calculateTDEE(bmr: bmr, activityLevel: activityLevel);
    manualCalories = CalculatorUtils.calculateDailyGoal(tdee: tdee, goalType: goalType).toDouble();
    caloriesController.text = manualCalories.toInt().toString();
  }

  @override
  void dispose() {
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    caloriesController.dispose();
    super.dispose();
  }

  void _recalculateCalories({bool updateCaloriesField = true}) {
    final bmr = CalculatorUtils.calculateBMR(
      gender: gender,
      weight: weight,
      height: height,
      age: age,
    );
    final tdee = CalculatorUtils.calculateTDEE(bmr: bmr, activityLevel: activityLevel);
    setState(() {
      manualCalories = CalculatorUtils.calculateDailyGoal(tdee: tdee, goalType: goalType).toDouble();
      if (updateCaloriesField) {
        caloriesController.text = manualCalories.toInt().toString();
      }
    });
  }

  void handleSubmit() {
    final userProfile = UserModel(
      email: widget.email,
      dailyCalorieGoal: manualCalories.toInt(),
      age: age,
      gender: gender,
      weight: weight,
      height: height,
      activityLevel: activityLevel,
      goalType: goalType,
    );
    widget.onSetGoal(userProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Goals'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSectionHeader('1. About You', 'Basic metabolic factors'),
              _buildDemographicsPage(),
              
              _buildSectionHeader('2. Metrics', 'Weight and height info'),
              _buildMetricsPage(),
              
              _buildSectionHeader('3. Lifestyle', 'How active is your daily routine?'),
              _buildActivityPage(),
              
              _buildSectionHeader('4. Objective', 'What are you aiming for?'),
              _buildGoalPage(),
              
              _buildSectionHeader('5. Your Plan', 'Recommended daily intake'),
              _buildResultsPage(),

              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Save Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDemographicsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Gender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChoiceChip('Male', gender == 'Male', (val) {
                setState(() => gender = 'Male');
                _recalculateCalories();
              }),
              const SizedBox(width: 12),
              _buildChoiceChip('Female', gender == 'Female', (val) {
                setState(() => gender = 'Female');
                _recalculateCalories();
              }),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Age', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter your age',
              suffixText: 'years',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              final newAge = int.tryParse(val);
              if (newAge != null) {
                setState(() => age = newAge);
                _recalculateCalories();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Weight', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter weight',
              suffixText: 'kg',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              final newWeight = double.tryParse(val);
              if (newWeight != null) {
                setState(() => weight = newWeight);
                _recalculateCalories();
              }
            },
          ),
          const SizedBox(height: 24),
          const Text('Height', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter height',
              suffixText: 'cm',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              final newHeight = double.tryParse(val);
              if (newHeight != null) {
                setState(() => height = newHeight);
                _recalculateCalories();
              }
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Current BMI: ${(weight / ((height / 100) * (height / 100))).toStringAsFixed(1)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...activityLevels.map((level) {
            final isSelected = activityLevel == level;
            return GestureDetector(
              onTap: () {
                setState(() => activityLevel = level);
                _recalculateCalories();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.shade50 : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? const Color(0xFF10B981) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      level,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF059669) : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...goalOptions.map((goal) {
            final bool isSelected = goalType == goal['type'];
            return GestureDetector(
              onTap: () {
                setState(() => goalType = goal['type']);
                _recalculateCalories();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [goal['color1'], goal['color2']]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(goal['icon'], color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goal['label'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(goal['description'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildResultsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text('Your Daily Target', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                TextField(
                  controller: caloriesController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    suffixText: 'cal',
                    suffixStyle: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.normal),
                  ),
                  onChanged: (val) {
                    final newCal = double.tryParse(val);
                    if (newCal != null) {
                      setState(() => manualCalories = newCal);
                    }
                  },
                ),
                const Text('Recommended for your profile', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniSummary(Icons.cake, '$age'),
              _buildMiniSummary(Icons.monitor_weight, '${weight.toInt()}kg'),
              _buildMiniSummary(Icons.height, '${height.toInt()}cm'),
              _buildMiniSummary(Icons.bolt, goalType.toUpperCase()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSummary(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, Function(bool) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF10B981).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF059669) : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
