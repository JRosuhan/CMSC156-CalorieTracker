import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/edamam_service.dart';
import '../providers/food_log_provider.dart';
import '../providers/data_providers.dart';

class AddFoodScreenWrapper extends StatelessWidget {
  const AddFoodScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: AddFoodScreenContent(),
    );
  }
}

class AddFoodScreenContent extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>)? onFoodSelected;
  const AddFoodScreenContent({super.key, this.onFoodSelected});

  @override
  ConsumerState<AddFoodScreenContent> createState() => _AddFoodScreenContentState();
}

class _AddFoodScreenContentState extends ConsumerState<AddFoodScreenContent> {
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
    _edamamService = ref.read(edamamServiceProvider);
    _foodResults = [];
  }

  void _onSearchChanged(String query) {
    setState(() {
      _query = query;
    });
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
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
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      'Add Food',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer for centering
                ],
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search food or brand...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: _clearSearch,
                          ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_query.trim().isEmpty) ...[
                _SectionHeader(title: 'Popular', onAction: null, actionText: ''),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _commonFoods.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ActionChip(
                          label: Text(_commonFoods[index]),
                          backgroundColor: Colors.white,
                          elevation: 0,
                          side: BorderSide(color: Colors.grey[200]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                          onPressed: () => _applySearch(_commonFoods[index]),
                        ),
                      );
                    },
                  ),
                ),
                if (_recentSearches.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Recent',
                    actionText: 'Clear',
                    onAction: () {
                      setState(() => _recentSearches.clear());
                    },
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _recentSearches.map((food) {
                      return InputChip(
                        label: Text(food),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey[200]!),
                        onPressed: () => _applySearch(food),
                        onDeleted: () {
                          setState(() => _recentSearches.remove(food));
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                    : _foodResults.isEmpty
                        ? Center(child: _buildEmptyState())
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 10, bottom: 20),
                            itemCount: _foodResults.length,
                            itemBuilder: (context, index) {
                              final food = _foodResults[index];
                              return _FoodResultCard(
                                food: food,
                                onAdd: (params) async {
                                  if (widget.onFoodSelected != null) {
                                    widget.onFoodSelected!(params);
                                    return;
                                  }
                                  await ref.read(foodLogControllerProvider).addFood(
                                    name: params['name'],
                                    calories: params['calories'],
                                    protein: params['protein'],
                                    carbs: params['carbs'],
                                    fats: params['fats'],
                                    servingSize: params['servingSize'],
                                    quantity: params['quantity'],
                                    availableMeasures: params['availableMeasures'],
                                    selectedMeasureIndex: params['selectedMeasureIndex'],
                                    baseCalories: params['baseCalories'],
                                    baseProtein: params['baseProtein'],
                                    baseCarbs: params['baseCarbs'],
                                    baseFats: params['baseFats'],
                                  );
                                  if (context.mounted) {
                                    context.go('/');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Meal logged! Keep it up. 🥗'),
                                        backgroundColor: Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
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

class _FoodResultCard extends StatefulWidget {
  final Map<String, dynamic> food;
  final Function(Map<String, dynamic>) onAdd;

  const _FoodResultCard({required this.food, required this.onAdd});

  @override
  State<_FoodResultCard> createState() => _FoodResultCardState();
}

class _FoodResultCardState extends State<_FoodResultCard> {
  late double quantity;
  late int selectedMeasureIndex;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    quantity = 1.0;
    _quantityController = TextEditingController(text: '1');
    final measures = widget.food['measures'] as List? ?? [];
    selectedMeasureIndex = measures.indexWhere((m) => m['label'].toString().toLowerCase() == 'gram');
    if (selectedMeasureIndex == -1 && measures.isNotEmpty) selectedMeasureIndex = 0;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final measures = widget.food['measures'] as List? ?? [];
    final unitWeight = measures.isNotEmpty ? (measures[selectedMeasureIndex]['weight'] ?? 100.0) : 100.0;
    final factor = (quantity * unitWeight) / 100.0;

    final displayCals = ((widget.food['calories'] ?? 0) * factor).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.food['image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://wsrv.nl/?url=${Uri.encodeComponent(widget.food['image'])}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, color: Colors.grey),
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
                      widget.food['name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$displayCals kcal total',
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      const Text('Qty:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          onChanged: (val) {
                            setState(() => quantity = double.tryParse(val) ?? 0.0);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedMeasureIndex,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                      items: List.generate(measures.length, (i) {
                        return DropdownMenuItem(
                          value: i,
                          child: Text(measures[i]['label'] ?? 'Serving'),
                        );
                      }),
                      onChanged: (val) {
                        setState(() => selectedMeasureIndex = val!);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final String unitLabel = measures.isNotEmpty ? (measures[selectedMeasureIndex]['label'] ?? 'Serving') : 'Serving';
                  widget.onAdd({
                    'name': widget.food['name'],
                    'calories': displayCals,
                    'protein': (widget.food['protein'] ?? 0.0) * factor,
                    'carbs': (widget.food['carbs'] ?? 0.0) * factor,
                    'fats': (widget.food['fats'] ?? 0.0) * factor,
                    'servingSize': quantity == 1.0 ? '1 $unitLabel' : '${quantity.toString().replaceAll('.0', '')} $unitLabel',
                    'quantity': quantity,
                    'availableMeasures': List<Map<String, dynamic>>.from(measures),
                    'selectedMeasureIndex': selectedMeasureIndex,
                    'baseCalories': widget.food['calories'] ?? 0,
                    'baseProtein': widget.food['protein'] ?? 0.0,
                    'baseCarbs': widget.food['carbs'] ?? 0.0,
                    'baseFats': widget.food['fats'] ?? 0.0,
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
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
        Icon(icon, size: 60, color: Colors.grey[200]),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionText,
                style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
