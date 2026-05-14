// screens/bin_screen.dart

import 'package:flutter/material.dart';
import '../models/food_log.dart';

class BinScreen extends StatelessWidget {
  final List<FoodLog>? deletedLogs;
  final Function(String id) onRestore;
  final Function(String id) onPermanentDelete;
  final VoidCallback onBack;

  const BinScreen({
    super.key,
    this.deletedLogs,
    required this.onRestore,
    required this.onPermanentDelete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // Defensive check to handle potential null or uninitialized list
    final List<FoodLog> logs = deletedLogs ?? [];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: logs.isEmpty
          ? const Center(
              child: Text('Your bin is empty'),
            )
          : ListView.builder(
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
                          onPressed: () => onRestore(log.id),
                          tooltip: 'Restore',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () => _confirmPermanentDelete(context, log.id),
                          tooltip: 'Delete Permanently',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanent Delete'),
        content: const Text('Are you sure you want to permanently delete this entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onPermanentDelete(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
