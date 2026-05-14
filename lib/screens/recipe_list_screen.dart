import 'package:flutter/material.dart';
import '../models/recipe_model.dart';

class RecipeListScreen extends StatelessWidget {
  final List<RecipeModel> recipes;
  final Function(RecipeModel recipe) onLogRecipe;
  final Function(RecipeModel recipe) onEditRecipe;
  final Function(String id) onDeleteRecipe;
  final VoidCallback onCreateNew;
  final VoidCallback onBack;

  const RecipeListScreen({
    super.key,
    required this.recipes,
    required this.onLogRecipe,
    required this.onEditRecipe,
    required this.onDeleteRecipe,
    required this.onCreateNew,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onCreateNew,
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.add),
        label: const Text('New Recipe'),
      ),
      body: recipes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No recipes saved yet', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onCreateNew,
                    child: const Text('Create Your First Recipe'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => onEditRecipe(recipe),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, recipe),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${recipe.ingredients.length} ingredients • ${recipe.servings} servings',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${recipe.caloriesPerServing} cal',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                                const Text('per serving', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => onLogRecipe(recipe),
                              icon: const Icon(Icons.add_task),
                              label: const Text('Log Recipe'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: [
                            _macroInfo('P', '${recipe.proteinPerServing.toStringAsFixed(1)}g'),
                            _macroInfo('C', '${recipe.carbsPerServing.toStringAsFixed(1)}g'),
                            _macroInfo('F', '${recipe.fatsPerServing.toStringAsFixed(1)}g'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _macroInfo(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _confirmDelete(BuildContext context, RecipeModel recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe?'),
        content: Text('Are you sure you want to delete "${recipe.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              onDeleteRecipe(recipe.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
