import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/data_providers.dart';
import '../providers/food_log_provider.dart';
import '../providers/auth_provider.dart';

class BinScreen extends ConsumerWidget {
  const BinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletedLogsAsync = ref.watch(deletedFoodLogsProvider);
    final deletedRecipesAsync = ref.watch(deletedRecipesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Recycle Bin', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                tabs: [
                  Tab(text: 'Meals'),
                  Tab(text: 'Recipes'),
                ],
                labelColor: Color(0xFF10B981),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF10B981),
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  deletedLogsAsync.when(
                    data: (logs) => _buildLogsList(context, ref, logs),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  ),
                  deletedRecipesAsync.when(
                    data: (recipes) => _buildRecipesList(context, ref, recipes),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsList(BuildContext context, WidgetRef ref, List logs) {
    if (logs.isEmpty) {
      return _buildEmptyState(Icons.delete_outline, 'No deleted meals', 'Items you delete will appear here for 30 days.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildBinItem(
          context,
          title: log.name,
          subtitle: '${log.calories} kcal',
          onRestore: () => ref.read(foodLogControllerProvider).restoreFood(log.id),
          onDelete: () => ref.read(foodLogControllerProvider).permanentDeleteFood(log.id),
          restoreMessage: 'Meal restored! ✨',
        );
      },
    );
  }

  Widget _buildRecipesList(BuildContext context, WidgetRef ref, List recipes) {
    if (recipes.isEmpty) {
      return _buildEmptyState(Icons.restaurant_menu, 'No deleted recipes', 'Your deleted custom recipes will show up here.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _buildBinItem(
          context,
          title: recipe.name,
          subtitle: 'Recipe',
          onRestore: () => ref.read(firebaseServiceProvider).restoreRecipe(recipe.id),
          onDelete: () => ref.read(firebaseServiceProvider).hardDeleteRecipe(recipe.id),
          restoreMessage: 'Recipe restored! ✨',
        );
      },
    );
  }

  Widget _buildBinItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onRestore,
    required VoidCallback onDelete,
    required String restoreMessage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore, color: Color(0xFF10B981)),
              onPressed: () {
                onRestore();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(restoreMessage), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              onPressed: () {
                _showDeleteConfirmation(context, onDelete);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permanent Delete?'),
        content: const Text('This action cannot be undone. This item will be gone forever.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deleted forever.'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
