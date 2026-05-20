import 'package:flutter/material.dart';
import 'macro_info.dart';

class ServingEditResult {
  final double quantity;
  final int measureIndex;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final String servingSize;

  ServingEditResult({
    required this.quantity,
    required this.measureIndex,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.servingSize,
  });
}

Future<void> showServingEditDialog({
  required BuildContext context,
  required String title,
  required double initialQuantity,
  required int initialMeasureIndex,
  required List<Map<String, dynamic>> measures,
  required int baseCalories,
  required double baseProtein,
  required double baseCarbs,
  required double baseFats,
  required void Function(ServingEditResult result) onSave,
}) async {
  double currentQuantity = initialQuantity;
  int currentMeasureIndex = initialMeasureIndex;

  final quantityController = TextEditingController(
    text: currentQuantity.toString().replaceAll('.0', ''),
  );

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final double unitWeight = measures[currentMeasureIndex]['weight'] ?? 100.0;
          final double totalWeight = currentQuantity * unitWeight;
          final double factor = totalWeight / 100.0;

          final int calculatedCalories = (baseCalories * factor).toInt();
          final double calculatedProtein = baseProtein * factor;
          final double calculatedCarbs = baseCarbs * factor;
          final double calculatedFats = baseFats * factor;

          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Adjust your serving size:'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.zero,
                        ),
                        controller: quantityController,
                        onChanged: (val) {
                          setDialogState(() {
                            currentQuantity = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: currentMeasureIndex,
                            isExpanded: true,
                            items: List.generate(measures.length, (i) {
                              return DropdownMenuItem(
                                value: i,
                                child: Text(measures[i]['label']?.toString() ?? 'Serving'),
                              );
                            }),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  currentMeasureIndex = val;
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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('New Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '$calculatedCalories cal',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          MacroInfo(label: 'P', value: '${calculatedProtein.toStringAsFixed(1)}g'),
                          MacroInfo(label: 'C', value: '${calculatedCarbs.toStringAsFixed(1)}g'),
                          MacroInfo(label: 'F', value: '${calculatedFats.toStringAsFixed(1)}g'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final String unitLabel = measures[currentMeasureIndex]['label']?.toString() ?? 'Serving';
                  final String servingSize = currentQuantity == 1.0
                      ? unitLabel
                      : '${currentQuantity.toString().replaceAll('.0', '')} $unitLabel';

                  onSave(ServingEditResult(
                    quantity: currentQuantity,
                    measureIndex: currentMeasureIndex,
                    calories: calculatedCalories,
                    protein: calculatedProtein,
                    carbs: calculatedCarbs,
                    fats: calculatedFats,
                    servingSize: servingSize,
                  ));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                child: const Text('Update', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  );
}
