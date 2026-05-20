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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Adjust your serving size:', style: TextStyle(color: Colors.grey)),
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
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: currentMeasureIndex,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: List.generate(measures.length, (i) {
                              return DropdownMenuItem(
                                value: i,
                                child: Text(measures[i]['label']?.toString() ?? 'Serving', style: const TextStyle(fontWeight: FontWeight.w500)),
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
                    color: const Color(0xFF10B981).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('New Total', style: TextStyle(fontWeight: FontWeight.w500)),
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
                onPressed: () {
                  final String unitLabel = measures[currentMeasureIndex]['label']?.toString() ?? 'Serving';
                  final String servingSize = currentQuantity == 1.0
                      ? '1 $unitLabel'
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Update Meal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    },
  );
}
