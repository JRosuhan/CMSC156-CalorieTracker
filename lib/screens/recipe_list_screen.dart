import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/recipe_model.dart';
import '../providers/data_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/ui_state_providers.dart';
import '../widgets/macro_info.dart';
import '../models/food_log.dart';

class RecipeListScreen extends ConsumerWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Recipes', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(editingRecipeProvider.notifier).setRecipe(null);
          context.push('/recipe-builder');
        },
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Recipe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: recipesAsync.when(
        data: (recipes) => recipes.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return _buildRecipeCard(context, ref, recipe);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'No recipes yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your favorite meals for quick logging!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, WidgetRef ref, RecipeModel recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'edit') {
                            ref.read(editingRecipeProvider.notifier).setRecipe(recipe);
                            context.push('/recipe-builder');
                          } else if (value == 'delete') {
                            ref.read(firebaseServiceProvider).softDeleteRecipe(recipe.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Recipe moved to Bin. 🗑️'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildNutrientBadge('${recipe.caloriesPerServing.toInt()} kcal', const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _buildNutrientBadge('${recipe.proteinPerServing.toStringAsFixed(1)}g P', Colors.blue),
                      const SizedBox(width: 8),
                      _buildNutrientBadge('${recipe.carbsPerServing.toStringAsFixed(1)}g C', Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: () => _showLogRecipeDialog(context, ref, recipe),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Log this Meal',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  void _showLogRecipeDialog(BuildContext context, WidgetRef ref, RecipeModel recipe) {
    String selectedUnit = 'Servings';
    double quantity = 1.0;
    final quantityController = TextEditingController(text: '1');
    final selectedDate = ref.read(selectedDateProvider);

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Log ${recipe.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How much are you eating?', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                            ),
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
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedUnit,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: ['Servings', 'Grams'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Calories', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text(
                              '$calculatedCalories kcal',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            MacroInfo(label: 'Protein', value: '${calculatedProtein.toStringAsFixed(1)}g'),
                            MacroInfo(label: 'Carbs', value: '${calculatedCarbs.toStringAsFixed(1)}g'),
                            MacroInfo(label: 'Fats', value: '${calculatedFats.toStringAsFixed(1)}g'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final logTimestamp = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      now.hour,
                      now.minute,
                      now.second,
                    );

                    final factorForNutrients = selectedUnit == 'Servings'
                        ? (recipe.servings > 0 ? quantity / recipe.servings : 0)
                        : (recipe.totalWeight > 0 ? quantity / recipe.totalWeight : 0);

                    // Create measures list for better editability on Home Screen
                    final List<Map<String, dynamic>> availableMeasures = [
                      {
                        'label': 'Servings',
                        'weight': recipe.servings > 0 ? (recipe.totalWeight / recipe.servings) : 100.0,
                      },
                    ];
                    
                    if (recipe.totalWeight > 0) {
                      availableMeasures.add({
                        'label': 'Grams',
                        'weight': 1.0,
                      });
                    }

                    final selectedMeasureIndex = selectedUnit == 'Servings' ? 0 : 1;

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
                      availableMeasures: availableMeasures,
                      selectedMeasureIndex: selectedMeasureIndex,
                      baseCalories: recipe.caloriesPer100g.toInt(),
                      baseProtein: recipe.proteinPer100g,
                      baseCarbs: recipe.carbsPer100g,
                      baseFats: recipe.fatsPer100g,
                      fromRecipe: true,
                    );

                    await ref.read(firebaseServiceProvider).addFoodLog(newLog);
                    if (context.mounted) {
                      context.go('/');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Meal logged! Keep it up. 🥗'),
                          backgroundColor: Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirm & Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
