// screens/add_food_screen.dart
// screens/add_food_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/edamam_service.dart';

class AddFoodScreenWrapper extends StatelessWidget {
  final VoidCallback onBack;

  final Function({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
    required String servingSize,
    required double quantity,
    required List<Map<String, dynamic>> availableMeasures,
    required int selectedMeasureIndex,
    required int baseCalories,
    required double baseProtein,
    required double baseCarbs,
    required double baseFats,
  }) onAddFood;

  const AddFoodScreenWrapper({
    super.key,
    required this.onBack,
    required this.onAddFood,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AddFoodScreenContent(
        onBack: onBack,
        onAddFood: onAddFood,
      ),
    );
  }
}

class AddFoodScreenContent extends StatefulWidget {
  final VoidCallback onBack;

  final Function({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
    required String servingSize,
    required double quantity,
    required List<Map<String, dynamic>> availableMeasures,
    required int selectedMeasureIndex,
    required int baseCalories,
    required double baseProtein,
    required double baseCarbs,
    required double baseFats,
  }) onAddFood;

  const AddFoodScreenContent({
    super.key,
    required this.onBack,
    required this.onAddFood,
  });

  @override
  State<AddFoodScreenContent> createState() => _AddFoodScreenContentState();
}

class _AddFoodScreenContentState extends State<AddFoodScreenContent> {
  late EdamamService _edamamService;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _foodResults = [];
  bool _isLoading = false;
  String _query = '';
  final List<String> _recentSearches = [];
  final List<String> _commonFoods = [
    'Chicken breast',
    'Boiled egg',
    'Oatmeal',
    'Banana',
    'Brown rice',
    'Greek yogurt',
    'Tuna',
    'Salad',
  ];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _edamamService = EdamamService();
    _foodResults = [];
  }

  void _onSearchChanged(String query) {
    setState(() {
      _query = query;
    });
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      if (query.trim().length < 3) {
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
        final trimmed = query.trim();
        final results = await _edamamService.searchFood(trimmed);
        if (mounted) {
          setState(() {
            _foodResults = results;
            _isLoading = false;
          });
        }
        if (trimmed.isNotEmpty) {
          _addRecentSearch(trimmed);
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

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _applySearch(String value) {
    _searchController.text = value;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    _onSearchChanged(value);
  }

  void _addRecentSearch(String value) {
    if (value.isEmpty) return;
    setState(() {
      _recentSearches.remove(value);
      _recentSearches.insert(0, value);
      if (_recentSearches.length > 6) {
        _recentSearches.removeLast();
      }
    });
  }

  Widget _buildEmptyState() {
    if (_query.trim().isEmpty) {
      return _EmptyState(
        icon: Icons.search,
        title: 'Search foods to add',
        subtitle: 'Type at least 3 characters to see results',
      );
    }
    if (_query.trim().length < 3) {
      return _EmptyState(
        icon: Icons.short_text,
        title: 'Keep typing',
        subtitle: 'Search needs at least 3 characters',
      );
    }
    return _EmptyState(
      icon: Icons.no_food,
      title: 'No results found',
      subtitle: 'Try another keyword or a brand name',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFEFFAF3),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Add Food',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Search by food or brand name',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search food...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _clearSearch,
                          ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              if (_query.trim().isEmpty) ...[
                _SectionHeader(
                  title: 'Popular foods',
                  actionText: 'See all',
                  onAction: () {
                    _applySearch(_commonFoods.first);
                  },
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _commonFoods.map((food) {
                    return ActionChip(
                      label: Text(food),
                      backgroundColor: const Color(0xFFE7F8EE),
                      labelStyle: const TextStyle(color: Color(0xFF059669)),
                      onPressed: () => _applySearch(food),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Recent searches',
                  actionText: 'Clear',
                  onAction: _recentSearches.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _recentSearches.clear();
                          });
                        },
                ),
                if (_recentSearches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'No recent searches yet',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recentSearches.map((food) {
                      return InputChip(
                        label: Text(food),
                        onPressed: () => _applySearch(food),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _recentSearches.remove(food);
                          });
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
              ],

              if (_query.trim().length >= 3 && _foodResults.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_foodResults.length} results',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Text(
                        'Tap Add to log',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _foodResults.isEmpty
                        ? Center(child: _buildEmptyState())
                        : ListView.builder(
                            itemCount: _foodResults.length,
                            itemBuilder: (context, index) {
                              final food = _foodResults[index];

                              food['quantity'] ??= 1.0;
                              final List measures = food['measures'] ?? [];

                              food['selectedMeasureIndex'] ??= measures.indexWhere(
                                (m) => m['label'].toString().toLowerCase() == 'gram',
                              );
                              if (food['selectedMeasureIndex'] == -1 && measures.isNotEmpty) {
                                food['selectedMeasureIndex'] = 0;
                              }

                              final quantityController = TextEditingController(
                                text: food['quantity'].toString().replaceAll('.0', ''),
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFFAF3),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: food['image'] != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(14),
                                                  child: Image.network(
                                                    food['image'],
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) =>
                                                        const Icon(Icons.fastfood),
                                                  ),
                                                )
                                              : const Icon(Icons.fastfood, color: Color(0xFF10B981)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                food['name'] ?? 'Unknown',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${food['calories'] ?? 0} cal per 100g',
                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE7F8EE),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Edamam',
                                            style: TextStyle(
                                              color: Color(0xFF059669),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 64,
                                          height: 42,
                                          child: TextField(
                                            controller: quantityController,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.zero,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            onChanged: (val) {
                                              food['quantity'] = double.tryParse(val) ?? 1.0;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Container(
                                            height: 42,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF4F5F7),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: DropdownButtonHideUnderline(
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
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          onPressed: () {
                                            final double q = food['quantity'] ?? 1.0;
                                            final int mIdx = food['selectedMeasureIndex'] ?? 0;
                                            final double unitWeight = measures[mIdx]['weight'] ?? 100.0;
                                            final String unitLabel = measures[mIdx]['label']?.toString() ?? 'Serving';

                                            final double totalWeight = q * unitWeight;
                                            final double factor = totalWeight / 100.0;

                                            widget.onAddFood(
                                              name: food['name'] ?? 'Unknown',
                                              calories: ((food['calories'] ?? 0) * factor).toInt(),
                                              protein: (food['protein'] ?? 0.0) * factor,
                                              carbs: (food['carbs'] ?? 0.0) * factor,
                                              fats: (food['fats'] ?? 0.0) * factor,
                                              servingSize: q == 1.0 ? unitLabel : '${q.toString().replaceAll('.0', '')} $unitLabel',
                                              quantity: q,
                                              availableMeasures: List<Map<String, dynamic>>.from(measures),
                                              selectedMeasureIndex: mIdx,
                                              baseCalories: food['calories'] ?? 0,
                                              baseProtein: food['protein'] ?? 0.0,
                                              baseCarbs: food['carbs'] ?? 0.0,
                                              baseFats: food['fats'] ?? 0.0,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF10B981),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            'Add',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText,
              style: TextStyle(
                color: onAction == null ? Colors.grey : const Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }
}