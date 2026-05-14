// screens/bin_screen.dart

import 'package:flutter/material.dart';
import '../models/food_log.dart';
import '../models/recipe_model.dart';

class BinScreen extends StatelessWidget {
  final List<FoodLog>? deletedLogs;
  final List<RecipeModel>? deletedRecipes;
  final Function(String id) onRestoreLog;
  final Function(String id) onPermanentDeleteLog;
  final Function(String id) onRestoreRecipe;
  final Function(String id) onPermanentDeleteRecipe;
  final VoidCallback onBack;

  const BinScreen({
    super.key,
    this.deletedLogs,
    this.deletedRecipes,
    required this.onRestoreLog,
    required this.onPermanentDeleteLog,
    required this.onRestoreRecipe,
    required this.onPermanentDeleteRecipe,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final List<FoodLog> logs = deletedLogs ?? [];
    final List<RecipeModel> recipes = deletedRecipes ?? [];
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recycle Bin'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Meals'),
              Tab(text: 'Recipes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLogsList(context, logs),
            _buildRecipesList(context, recipes),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsList(BuildContext context, List<FoodLog> logs) {
    if (logs.isEmpty) {
      return const Center(child: Text('No deleted meals'));
    }
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(log.name),
            subtitle: Text('${log.calories} cal - ${log.servingSize}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore, color: Colors.green),
                  onPressed: () => onRestoreLog(log.id),
                  tooltip: 'Restore',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () => _confirmPermanentDelete(context, log.id, true),
                  tooltip: 'Delete Permanently',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipesList(BuildContext context, List<RecipeModel> recipes) {
    if (recipes.isEmpty) {
      return const Center(child: Text('No deleted recipes'));
    }
    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(recipe.name),
            subtitle: Text('${recipe.caloriesPerServing} cal - ${recipe.ingredients.length} ingredients'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore, color: Colors.green),
                  onPressed: () => onRestoreRecipe(recipe.id),
                  tooltip: 'Restore',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () => _confirmPermanentDelete(context, recipe.id, false),
                  tooltip: 'Delete Permanently',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmPermanentDelete(BuildContext context, String id, bool isLog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanent Delete'),
        content: const Text('Are you sure you want to permanently delete this? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (isLog) {
                onPermanentDeleteLog(id);
              } else {
                onPermanentDeleteRecipe(id);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
