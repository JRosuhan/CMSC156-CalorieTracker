import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/food_log.dart';
import '../providers/auth_provider.dart';
import '../providers/ui_state_providers.dart';
import '../utils/error_translator.dart';
import '../widgets/serving_edit_dialog.dart';
import 'add_food_screen.dart';

class RecipeBuilderScreen extends ConsumerStatefulWidget {
  const RecipeBuilderScreen({super.key});

  @override
  ConsumerState<RecipeBuilderScreen> createState() => _RecipeBuilderScreenState();
}

class _RecipeBuilderScreenState extends ConsumerState<RecipeBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _servingsController;

  @override
  void initState() {
    super.initState();
    final initialRecipe = ref.read(editingRecipeProvider);
    _nameController = TextEditingController(text: initialRecipe?.name ?? '');
    _servingsController = TextEditingController(text: initialRecipe?.servings.toString() ?? '1');
    
    _nameController.addListener(() {
      ref.read(editingRecipeProvider.notifier).updateName(_nameController.text);
    });
    _servingsController.addListener(() {
      final s = int.tryParse(_servingsController.text) ?? 1;
      ref.read(editingRecipeProvider.notifier).updateServings(s);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      final recipe = ref.read(editingRecipeProvider);
      if (recipe == null || recipe.ingredients.isEmpty) {
        _showSnackBar('Please add at least one ingredient', isError: true);
        return;
      }

      try {
        final service = ref.read(firebaseServiceProvider);
        if (recipe.id.isEmpty) {
          await service.addRecipe(recipe);
          _showSnackBar('Recipe created! 👨‍🍳');
        } else {
          await service.updateRecipe(recipe);
          _showSnackBar('Recipe updated! ✨');
        }
        if (mounted) {
          ref.read(editingRecipeProvider.notifier).setRecipe(null);
          context.pop();
        }
      } catch (e) {
        _showSnackBar(ErrorTranslator.translate(e), isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editIngredient(int index, FoodLog ingredient) {
    showServingEditDialog(
      context: context,
      title: 'Edit ${ingredient.name}',
      initialQuantity: ingredient.quantity,
      initialMeasureIndex: ingredient.selectedMeasureIndex,
      measures: ingredient.availableMeasures,
      baseCalories: ingredient.baseCalories,
      baseProtein: ingredient.baseProtein,
      baseCarbs: ingredient.baseCarbs,
      baseFats: ingredient.baseFats,
      onSave: (result) {
        final updated = FoodLog(
          id: ingredient.id,
          name: ingredient.name,
          calories: result.calories,
          protein: result.protein,
          carbs: result.carbs,
          fats: result.fats,
          servingSize: result.servingSize,
          timestamp: ingredient.timestamp,
          quantity: result.quantity,
          availableMeasures: ingredient.availableMeasures,
          selectedMeasureIndex: result.measureIndex,
          baseCalories: ingredient.baseCalories,
          baseProtein: ingredient.baseProtein,
          baseCarbs: ingredient.baseCarbs,
          baseFats: ingredient.baseFats,
        );
        ref.read(editingRecipeProvider.notifier).updateIngredient(index, updated);
      },
    );
  }

  void _openIngredientSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add Ingredient',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: AddFoodScreenContent(
                  onFoodSelected: (params) {
                    final ingredient = FoodLog(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: params['name'],
                      calories: params['calories'],
                      protein: params['protein'],
                      carbs: params['carbs'],
                      fats: params['fats'],
                      servingSize: params['servingSize'],
                      timestamp: DateTime.now(),
                      quantity: params['quantity'],
                      availableMeasures: List<Map<String, dynamic>>.from(params['availableMeasures']),
                      selectedMeasureIndex: params['selectedMeasureIndex'],
                      baseCalories: params['baseCalories'],
                      baseProtein: params['baseProtein'],
                      baseCarbs: params['baseCarbs'],
                      baseFats: params['baseFats'],
                    );
                    ref.read(editingRecipeProvider.notifier).addIngredient(ingredient);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = ref.watch(editingRecipeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(recipe?.id.isEmpty ?? true ? 'New Recipe' : 'Edit Recipe', 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            ref.read(editingRecipeProvider.notifier).setRecipe(null);
            context.pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: _saveRecipe,
            child: const Text('Save', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            _buildSectionHeader('GENERAL INFO'),
            _buildGroupedContainer([
              _buildInputRow('Name', _nameController, 'e.g. Pasta', Icons.restaurant_menu),
              const Divider(height: 1, indent: 56),
              _buildInputRow('Servings', _servingsController, '1', Icons.people_outline, isNumeric: true),
            ]),
            
            const SizedBox(height: 32),
            _buildSectionHeader('INGREDIENTS'),
            if (recipe != null && recipe.ingredients.isNotEmpty)
              _buildGroupedContainer(
                recipe.ingredients.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      Dismissible(
                        key: Key('ingredient_${idx}_${item.id}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          ref.read(editingRecipeProvider.notifier).removeIngredient(idx);
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: ListTile(
                          onTap: () => _editIngredient(idx, item),
                          leading: const Icon(Icons.drag_handle, color: Colors.grey),
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('${item.servingSize} • ${item.calories} kcal'),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                        ),
                      ),
                      if (idx < recipe.ingredients.length - 1)
                        const Divider(height: 1, indent: 16),
                    ],
                  );
                }).toList(),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton.icon(
                onPressed: _openIngredientSearch,
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF10B981)),
                label: const Text('Add Ingredient', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              ),
            ),

            if (recipe != null && recipe.ingredients.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildSectionHeader('NUTRITION PER SERVING'),
              _buildGroupedContainer([
                _buildNutritionRow('Calories', '${recipe.caloriesPerServing} kcal'),
                const Divider(height: 1, indent: 16),
                _buildNutritionRow('Protein', '${recipe.proteinPerServing.toStringAsFixed(1)}g'),
                const Divider(height: 1, indent: 16),
                _buildNutritionRow('Carbs', '${recipe.carbsPerServing.toStringAsFixed(1)}g'),
                const Divider(height: 1, indent: 16),
                _buildNutritionRow('Fats', '${recipe.fatsPerServing.toStringAsFixed(1)}g'),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF6E6E73)),
      ),
    );
  }

  Widget _buildGroupedContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, String hint, IconData icon, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 22),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 17)),
          const Spacer(),
          SizedBox(
            width: 150,
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.end,
              keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
              style: const TextStyle(fontSize: 17),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 17)),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }
}
