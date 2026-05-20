import 'package:flutter/material.dart';
import '../models/food_log.dart';
import '../models/recipe_model.dart';
import '../services/edamam_service.dart';
import '../widgets/macro_info.dart';
import '../widgets/serving_edit_dialog.dart';
import 'dart:async';

class RecipeBuilderScreen extends StatefulWidget {
  final RecipeModel? initialRecipe;
  final Function(RecipeModel recipe) onSaveRecipe;
  final VoidCallback onBack;

  const RecipeBuilderScreen({
    super.key,
    this.initialRecipe,
    required this.onSaveRecipe,
    required this.onBack,
  });

  @override
  State<RecipeBuilderScreen> createState() => _RecipeBuilderScreenState();
}

class _RecipeBuilderScreenState extends State<RecipeBuilderScreen> {
  late TextEditingController _nameController;
  late TextEditingController _servingsController;
  final List<FoodLog> _ingredients = [];
  
  late EdamamService _edamamService;
  List<Map<String, dynamic>> _foodResults = [];
  bool _isLoading = false;
  bool _isSaving = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _edamamService = EdamamService();
    _nameController = TextEditingController(text: widget.initialRecipe?.name ?? '');
    _servingsController = TextEditingController(text: (widget.initialRecipe?.servings ?? 1).toString());
    if (widget.initialRecipe != null) {
      _ingredients.addAll(widget.initialRecipe!.ingredients);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingsController.dispose();
    _debounce?.cancel();
    super.dispose();
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

  void _addIngredient(Map<String, dynamic> food, double quantity, int mIdx) {
    final List measures = food['measures'] ?? [];
    final double unitWeight = measures[mIdx]['weight'] ?? 100.0;
    final String unitLabel = measures[mIdx]['label']?.toString() ?? 'Serving';
    
    final double totalWeight = quantity * unitWeight;
    final double factor = totalWeight / 100.0;

    setState(() {
      _ingredients.add(FoodLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: food['name'] ?? 'Unknown',
        calories: ((food['calories'] ?? 0) * factor).toInt(),
        protein: (food['protein'] ?? 0.0) * factor,
        carbs: (food['carbs'] ?? 0.0) * factor,
        fats: (food['fats'] ?? 0.0) * factor,
        servingSize: quantity == 1.0 ? unitLabel : '${quantity.toString().replaceAll('.0', '')} $unitLabel',
        timestamp: DateTime.now(),
        quantity: quantity,
        availableMeasures: List<Map<String, dynamic>>.from(measures),
        selectedMeasureIndex: mIdx,
        baseCalories: food['calories'] ?? 0,
        baseProtein: (food['protein'] ?? 0.0).toDouble(),
        baseCarbs: (food['carbs'] ?? 0.0).toDouble(),
        baseFats: (food['fats'] ?? 0.0).toDouble(),
      ));
      _foodResults = []; // Clear results after adding
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _editIngredient(int index) {
    final ing = _ingredients[index];
    final List<Map<String, dynamic>> measures = ing.availableMeasures.isNotEmpty
        ? ing.availableMeasures
        : [
            {'label': 'Serving', 'weight': 100.0}
          ];
    int currentMeasureIndex = ing.selectedMeasureIndex;
    if (currentMeasureIndex < 0 || currentMeasureIndex >= measures.length) {
      currentMeasureIndex = 0;
    }

    showServingEditDialog(
      context: context,
      title: 'Edit ${ing.name}',
      initialQuantity: ing.quantity,
      initialMeasureIndex: currentMeasureIndex,
      measures: measures,
      baseCalories: ing.baseCalories,
      baseProtein: ing.baseProtein,
      baseCarbs: ing.baseCarbs,
      baseFats: ing.baseFats,
      onSave: (result) {
        setState(() {
          _ingredients[index] = FoodLog(
            id: ing.id,
            name: ing.name,
            calories: result.calories,
            protein: result.protein,
            carbs: result.carbs,
            fats: result.fats,
            servingSize: result.servingSize,
            timestamp: ing.timestamp,
            quantity: result.quantity,
            availableMeasures: measures,
            selectedMeasureIndex: result.measureIndex,
            baseCalories: ing.baseCalories,
            baseProtein: ing.baseProtein,
            baseCarbs: ing.baseCarbs,
            baseFats: ing.baseFats,
          );
        });
      },
    );
  }

  Future<void> _saveRecipe() async {
    if (_isSaving) return;

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipe name')),
      );
      return;
    }
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    final servings = int.tryParse(_servingsController.text) ?? 1;
    if (servings <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servings must be at least 1')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final recipe = RecipeModel(
        id: widget.initialRecipe?.id ?? '',
        name: _nameController.text,
        ingredients: _ingredients,
        servings: servings,
      );

      await widget.onSaveRecipe(recipe);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save recipe: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int servings = int.tryParse(_servingsController.text) ?? 1;
    final totalCals = _ingredients.fold(0.0, (sum, i) => sum + i.calories);
    final totalProtein = _ingredients.fold(0.0, (sum, i) => sum + i.protein);
    final totalCarbs = _ingredients.fold(0.0, (sum, i) => sum + i.carbs);
    final totalFats = _ingredients.fold(0.0, (sum, i) => sum + i.fats);

    final calsPerServing = servings > 0 ? (totalCals / servings).round() : 0;
    final proteinPerServing = servings > 0 ? totalProtein / servings : 0.0;
    final carbsPerServing = servings > 0 ? totalCarbs / servings : 0.0;
    final fatsPerServing = servings > 0 ? totalFats / servings : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialRecipe == null ? 'Recipe Builder' : 'Edit Recipe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSaving ? null : widget.onBack,
        ),
        actions: [
          _isSaving
              ? const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
              : TextButton(
                  onPressed: _saveRecipe,
                  child: const Text('Save', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Recipe Name (e.g., Chicken Adobo)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _servingsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Number of Servings',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          Expanded(
            child: ListView(
              children: [
                if (_ingredients.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  ...List.generate(_ingredients.length, (index) {
                    final ing = _ingredients[index];
                    return ListTile(
                      title: Text(ing.name),
                      subtitle: Text('${ing.servingSize} - ${ing.calories} cal'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                            onPressed: () => _editIngredient(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                            onPressed: () => _removeIngredient(index),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                ],
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search ingredients to add...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ..._foodResults.map((food) => _buildSearchResultCard(food)),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Per Serving:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$calsPerServing cal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    MacroInfo(label: 'P', value: '${proteinPerServing.toStringAsFixed(1)}g'),
                    MacroInfo(label: 'C', value: '${carbsPerServing.toStringAsFixed(1)}g'),
                    MacroInfo(label: 'F', value: '${fatsPerServing.toStringAsFixed(1)}g'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> food) {
    food['quantity'] ??= 1.0;
    final List measures = food['measures'] ?? [];
    if (measures.isEmpty) {
      measures.add({'label': 'Serving', 'weight': 100.0});
    }

    food['selectedMeasureIndex'] ??= measures.indexWhere(
      (m) => m['label'].toString().toLowerCase() == 'gram'
    );
    if (food['selectedMeasureIndex'] == -1 || food['selectedMeasureIndex'] >= measures.length) {
      food['selectedMeasureIndex'] = 0;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              title: Text(food['name'] ?? 'Unknown'),
              subtitle: Text('${food['calories'] ?? 0} cal / 100g'),
            ),
            Row(
              children: [
                SizedBox(
                  width: 50,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(isDense: true),
                    onChanged: (val) => food['quantity'] = double.tryParse(val) ?? 1.0,
                    controller: TextEditingController(text: food['quantity'].toString().replaceAll('.0', '')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<int>(
                    value: food['selectedMeasureIndex'],
                    isExpanded: true,
                    items: List.generate(measures.length, (i) {
                      return DropdownMenuItem(
                        value: i,
                        child: Text(measures[i]['label']?.toString() ?? 'Serving'),
                      );
                    }),
                    onChanged: (val) {
                      setState(() {
                        food['selectedMeasureIndex'] = val;
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _addIngredient(food, food['quantity'] ?? 1.0, food['selectedMeasureIndex'] ?? 0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
