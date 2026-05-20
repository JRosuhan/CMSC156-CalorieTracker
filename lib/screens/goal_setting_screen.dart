import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/calculator_utils.dart';

class GoalSettingScreen extends ConsumerStatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  ConsumerState<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends ConsumerState<GoalSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  
  String _gender = 'Male';
  String _activityLevel = 'Sedentary';
  String _goalType = 'Maintain';
  int _calculatedGoal = 2000;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _ageController = TextEditingController(text: user?.age?.toString() ?? '0');
    _heightController = TextEditingController(text: user?.height?.toString() ?? '0');
    _weightController = TextEditingController(text: user?.weight?.toString() ?? '0');
    _gender = user?.gender ?? 'Male';
    _activityLevel = user?.activityLevel ?? 'Sedentary';
    _goalType = user?.goalType ?? 'Maintain';
    _calculatedGoal = user?.dailyCalorieGoal ?? 2000;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _updateCalculatedGoal() {
    final double? weight = double.tryParse(_weightController.text);
    final double? height = double.tryParse(_heightController.text);
    final int? age = int.tryParse(_ageController.text);

    if (weight != null && height != null && age != null) {
      final bmr = CalculatorUtils.calculateBMR(
        gender: _gender,
        weight: weight,
        height: height,
        age: age,
      );
      final tdee = CalculatorUtils.calculateTDEE(
        bmr: bmr,
        activityLevel: _activityLevel,
      );
      setState(() {
        _calculatedGoal = CalculatorUtils.calculateDailyGoal(
          tdee: tdee,
          goalType: _goalType,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS Grouped Background
      appBar: AppBar(
        title: const Text('Goal Setting', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: user.needsSetup
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
                onPressed: () => context.pop(),
              ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  children: [
                    const Text(
                      'DAILY TARGET',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_calculatedGoal',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      'calories',
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              _buildSectionHeader('GOAL TYPE'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildGoalCard('Cut', Icons.trending_down, const Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    _buildGoalCard('Maintain', Icons.balance, const Color(0xFF3B82F6)),
                    const SizedBox(width: 12),
                    _buildGoalCard('Bulk', Icons.trending_up, const Color(0xFF10B981)),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('PERSONAL DETAILS'),
              _buildGroupedContainer([
                _buildPickerRow('Gender', _gender, ['Male', 'Female'], (val) {
                  setState(() => _gender = val!);
                  _updateCalculatedGoal();
                }),
                const Divider(height: 1, indent: 16),
                _buildInputRow('Age', _ageController, 'years'),
                const Divider(height: 1, indent: 16),
                _buildInputRow('Height', _heightController, 'cm'),
                const Divider(height: 1, indent: 16),
                _buildInputRow('Weight', _weightController, 'kg'),
              ]),

              const SizedBox(height: 32),
              _buildSectionHeader('LIFESTYLE'),
              _buildGroupedContainer([
                _buildPickerRow('Activity', _activityLevel, 
                  ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extra Active'], 
                  (val) {
                    setState(() => _activityLevel = val!);
                    _updateCalculatedGoal();
                  }
                ),
              ]),

              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final updatedUser = UserModel(
                          email: user.email,
                          dailyCalorieGoal: _calculatedGoal,
                          age: int.tryParse(_ageController.text),
                          gender: _gender,
                          height: double.tryParse(_heightController.text),
                          weight: double.tryParse(_weightController.text),
                          activityLevel: _activityLevel,
                          goalType: _goalType,
                        );
                        await ref.read(userProvider.notifier).setGoal(updatedUser);
                        if (mounted) {
                          if (!context.mounted) return;
                          context.go('/');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated! Time to crush it. 🚀'),
                              backgroundColor: Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Profile',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Color(0xFF6E6E73),
        ),
      ),
    );
  }

  Widget _buildGroupedContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 17)),
          const Spacer(),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.end,
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateCalculatedGoal(),
              decoration: InputDecoration(
                border: InputBorder.none,
                suffixText: ' $unit',
                suffixStyle: const TextStyle(color: Colors.grey, fontSize: 17),
              ),
              style: const TextStyle(fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerRow(String label, String value, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 17)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.chevron_right, color: Colors.grey),
              onChanged: onChanged,
              items: options.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val, style: const TextStyle(fontSize: 17, color: Colors.blue)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String type, IconData icon, Color color) {
    final isSelected = _goalType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _goalType = type);
          _updateCalculatedGoal();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.white,
              width: 2,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
