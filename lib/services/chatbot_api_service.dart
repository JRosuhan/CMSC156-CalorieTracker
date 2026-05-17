import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';
import 'edamam_service.dart';
import '../models/food_log.dart';
import '../models/recipe_model.dart';
import 'dart:convert';
import 'dart:async';

class ChatbotApiService {
  static final ChatbotApiService _instance = ChatbotApiService._internal();
  factory ChatbotApiService() => _instance;

  final FirebaseService _firebaseService = FirebaseService();
  final EdamamService _edamamService = EdamamService();
  
  late final String _apiKey;
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // Model configuration
  final String _primaryModel = 'llama-3.3-70b-versatile';
  final String _fallbackModel = 'llama-3.1-8b-instant';
  String _currentModel = 'llama-3.3-70b-versatile';

  final List<Map<String, dynamic>> _history = [];
  final List<Map<String, String>> uiMessages = [];

  ChatbotApiService._internal() {
    _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    print('DEBUG: Groq API Key loaded: ${_apiKey.isNotEmpty ? "YES (${_apiKey.substring(0, 5)}...)" : "NO"}');
    
    _resetHistory();
  }

  void _resetHistory() {
    _history.clear();
    _history.add({
      'role': 'system',
      'content': 'You are a strict, focused nutrition assistant for NomNomTracker. '
          'Your ONLY purpose is to help users track their food, view daily summaries, and manage recipes. '
          'DO NOT write code (Python, Dart, etc.), perform general programming tasks, or engage in off-topic conversations. If a user asks for code or off-topic information, politely refuse and remind them of your purpose. '
          'Always use the provided tools to interact with the database. '
          'To perform updates or deletions, you need the exact ID. You MUST first call the \'get_recipes\' or \'get_daily_summary\' tool to find the ID. NEVER guess an ID, and NEVER use placeholders like \'find_recipe_by_name\'. '
          'For accuracy, if you need to log a food but do not have the nutrition facts, use the nutrition search tool to get real data from the Edamam database. '
          'For destructive operations like deleting, updating, or modifying recipes, simply call the appropriate tool directly. The app will automatically handle user confirmation. DO NOT ask the user for permission to call tools. '
          'Deleted food logs go to the "meals bin". Deleted recipes go to the "recipe bin". '
          'IMPORTANT: Always use the native JSON tool calling API. NEVER output raw <function> XML tags. Always ensure tool calls use perfectly formatted JSON with all required closing braces `}`. '
          'Maintain context of previous messages.'
    });
  }

  void _trimHistory() {
    // Keep system message + last 10 messages (5 rounds of conversation)
    if (_history.length > 11) {
      final systemMessage = _history[0];
      final recentHistory = _history.sublist(_history.length - 10);
      _history.clear();
      _history.add(systemMessage);
      _history.addAll(recentHistory);
    }
  }

  // --- TOOL DEFINITIONS ---

  List<Map<String, dynamic>> get _tools => [
    {
      'type': 'function',
      'function': {
        'name': 'get_daily_summary',
        'description': 'Retrieves a summary of food logs, total calories, and macronutrients for a specific date.',
        'parameters': {
          'type': 'object',
          'properties': {
            'date': {'type': 'string', 'description': 'The date in YYYY-MM-DD format. Defaults to today if not provided.'},
          },
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_recipes',
        'description': 'Retrieves a list of all saved recipes.',
        'parameters': {'type': 'object', 'properties': {}},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'log_recipe',
        'description': 'Logs a saved recipe as a food entry.',
        'parameters': {
          'type': 'object',
          'properties': {
            'recipe_id': {'type': 'string', 'description': 'The unique ID of the recipe to log.'},
            'unit': {'type': 'string', 'description': 'The unit to log the recipe in, strictly either "Servings" or "Grams".'},
            'quantity': {'type': 'number', 'description': 'The amount eaten (e.g., number of servings or number of grams).'},
          },
          'required': ['recipe_id', 'unit', 'quantity'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'search_food_nutrition',
        'description': 'Searches the Edamam database for accurate nutrition facts for a specific food item.',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {'type': 'string', 'description': 'The food item to search for (e.g., "Big Mac", "100g Chicken").'},
          },
          'required': ['query'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'add_food_log',
        'description': 'Adds a new food log entry.',
        'parameters': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'description': 'Name of the food item.'},
            'calories': {'type': 'number', 'description': 'Total calories for this entry.'},
            'protein': {'type': 'number', 'description': 'Grams of protein.'},
            'carbs': {'type': 'number', 'description': 'Grams of carbohydrates.'},
            'fats': {'type': 'number', 'description': 'Grams of fats.'},
            'servingSize': {'type': 'string', 'description': 'Display string for serving size (e.g., "1 serving", "200g").'},
            'quantity': {'type': 'number', 'description': 'The quantity multiplier.'},
            'baseCalories': {'type': 'number', 'description': 'Base calories per 100g or per unit.'},
            'baseProtein': {'type': 'number', 'description': 'Base protein per 100g or per unit.'},
            'baseCarbs': {'type': 'number', 'description': 'Base carbs per 100g or per unit.'},
            'baseFats': {'type': 'number', 'description': 'Base fats per 100g or per unit.'},
          },
          'required': ['name', 'calories', 'servingSize'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'add_recipe_ingredient',
        'description': 'Adds a new ingredient to an existing saved recipe.',
        'parameters': {
          'type': 'object',
          'properties': {
            'recipe_id': {'type': 'string', 'description': 'The unique ID of the recipe to modify.'},
            'name': {'type': 'string', 'description': 'Name of the ingredient.'},
            'calories': {'type': 'number', 'description': 'Total calories for this ingredient.'},
            'protein': {'type': 'number', 'description': 'Grams of protein.'},
            'carbs': {'type': 'number', 'description': 'Grams of carbohydrates.'},
            'fats': {'type': 'number', 'description': 'Grams of fats.'},
            'servingSize': {'type': 'string', 'description': 'Display string for serving size.'},
            'quantity': {'type': 'number', 'description': 'The quantity multiplier.'},
            'baseCalories': {'type': 'number', 'description': 'Base calories per 100g or per unit.'},
            'baseProtein': {'type': 'number', 'description': 'Base protein per 100g or per unit.'},
            'baseCarbs': {'type': 'number', 'description': 'Base carbs per 100g or per unit.'},
            'baseFats': {'type': 'number', 'description': 'Base fats per 100g or per unit.'},
          },
          'required': ['recipe_id', 'name', 'calories', 'servingSize'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'update_food_log',
        'description': 'Updates an existing food log entry. Requires ID and new quantity.',
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {'type': 'string', 'description': 'The unique ID of the food log to update.'},
            'quantity': {'type': 'number', 'description': 'The new quantity multiplier.'},
            'selectedMeasureIndex': {'type': 'number', 'description': 'The index of the selected measure.'},
          },
          'required': ['id', 'quantity'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'delete_food_log',
        'description': 'Deletes (soft delete) a food log entry. Requires the ID of the log.',
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {'type': 'string', 'description': 'The unique ID of the food log to delete.'},
          },
          'required': ['id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'delete_recipe',
        'description': 'Deletes (soft delete) a saved recipe. Requires the unique ID of the recipe.',
        'parameters': {
          'type': 'object',
          'properties': {
            'recipe_id': {'type': 'string', 'description': 'The unique ID of the recipe to delete.'},
          },
          'required': ['recipe_id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'delete_recipe_ingredient',
        'description': 'Removes a specific ingredient from a saved recipe.',
        'parameters': {
          'type': 'object',
          'properties': {
            'recipe_id': {'type': 'string', 'description': 'The unique ID of the recipe to modify.'},
            'ingredient_name': {'type': 'string', 'description': 'The exact or partial name of the ingredient to remove.'},
          },
          'required': ['recipe_id', 'ingredient_name'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'update_recipe_ingredient',
        'description': 'Updates the quantity of an ingredient within a saved recipe.',
        'parameters': {
          'type': 'object',
          'properties': {
            'recipe_id': {'type': 'string', 'description': 'The unique ID of the recipe to modify.'},
            'ingredient_name': {'type': 'string', 'description': 'The name of the ingredient to update.'},
            'quantity': {'type': 'number', 'description': 'The new quantity multiplier (e.g., 2.0 for 2 servings/units).'},
          },
          'required': ['recipe_id', 'ingredient_name', 'quantity'],
        },
      },
    },
  ];

  // --- CHAT INTERACTION ---

  Future<String> sendMessage(
    String message, {
    required Future<bool> Function(String action, Map<String, dynamic> params) onConfirm,
  }) async {
    _history.add({'role': 'user', 'content': message});
    
    if (uiMessages.isEmpty || uiMessages.last['text'] != message) {
      uiMessages.add({'role': 'user', 'text': message});
    }
    
    try {
      while (true) {
        _trimHistory(); // Optimize context before sending
        
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _currentModel,
            'messages': _history,
            'tools': _tools,
            'temperature': 0.0,
            'tool_choice': 'auto',
          }),
        );

        if (response.statusCode != 200) {
          // Handle Rate Limit (429) with Fallback
          if (response.statusCode == 429 && _currentModel == _primaryModel) {
            print('DEBUG: Primary model rate limited. Switching to fallback...');
            _currentModel = _fallbackModel;
            continue; // Retry immediately with fallback model
          }

          if (response.statusCode == 400) {
            final errorData = jsonDecode(response.body);
            final failedGen = errorData['error']['failed_generation'] as String?;
            if (failedGen != null && failedGen.contains('<function=')) {
              print('DEBUG: Recovering tool call from failed_generation: $failedGen');
              final recoveredCalls = _parseHallucinatedToolCalls(failedGen);
              if (recoveredCalls.isNotEmpty) {
                for (final call in recoveredCalls) {
                  final name = call['name'];
                  final args = call['args'];
                  
                  // Handle destructive operations for recovered calls
                  if (name == 'delete_food_log' || 
                      name == 'update_food_log' ||
                      name == 'delete_recipe' ||
                      name == 'delete_recipe_ingredient' ||
                      name == 'update_recipe_ingredient' ||
                      name == 'add_recipe_ingredient') {
                    final confirmed = await onConfirm(name, args);
                    if (!confirmed) {
                      _history.add({
                        'role': 'tool',
                        'tool_call_id': 'recovered_${DateTime.now().millisecondsSinceEpoch}',
                        'name': name,
                        'content': jsonEncode({'status': 'cancelled', 'message': 'User cancelled the operation.'}),
                      });
                      continue;
                    }
                  }

                  final result = await _handleFunctionCall(name, args);
                  _history.add({
                    'role': 'tool',
                    'tool_call_id': 'recovered_${DateTime.now().millisecondsSinceEpoch}',
                    'name': name,
                    'content': jsonEncode(result),
                  });
                }
                continue;
              }
            }
          }
          
          String friendlyError = "I'm having trouble with the API right now.";
          if (response.statusCode == 429) {
            friendlyError = "The AI is currently at its daily limit. Please try again tomorrow.";
          }
          throw Exception('$friendlyError (${response.statusCode})');
        }

        // Reset to primary model for next turn if we were successful
        _currentModel = _primaryModel;

        final data = jsonDecode(response.body);
        final choice = data['choices'][0];
        final assistantMessage = choice['message'];
        final assistantContent = assistantMessage['content'] as String? ?? '';
        
        _history.add(assistantMessage);

        // Check for hallucinations in valid response content as well
        if (assistantContent.contains('<function=')) {
          final recoveredCalls = _parseHallucinatedToolCalls(assistantContent);
          if (recoveredCalls.isNotEmpty) {
            for (final call in recoveredCalls) {
              final result = await _handleFunctionCall(call['name'], call['args']);
              _history.add({
                'role': 'tool',
                'tool_call_id': 'hallucinated_${DateTime.now().millisecondsSinceEpoch}',
                'name': call['name'],
                'content': jsonEncode(result),
              });
            }
            continue;
          }
        }

        if (choice['finish_reason'] == 'tool_calls') {
          final toolCalls = assistantMessage['tool_calls'] as List;
          
          for (final toolCall in toolCalls) {
            final functionName = toolCall['function']['name'];
            final toolCallId = toolCall['id'];
            
            Map<String, dynamic> functionArgs = {};
            final rawArgs = toolCall['function']['arguments'];
            if (rawArgs != null && rawArgs.toString().trim().isNotEmpty) {
              try {
                final decoded = jsonDecode(rawArgs.toString());
                if (decoded is Map) {
                  functionArgs = Map<String, dynamic>.from(decoded);
                }
              } catch (e) {
                print('DEBUG: Error decoding tool arguments: $e');
              }
            }

            // Check for destructive operations
            if (functionName == 'delete_food_log' || 
                functionName == 'update_food_log' ||
                functionName == 'delete_recipe' ||
                functionName == 'delete_recipe_ingredient' ||
                functionName == 'update_recipe_ingredient' ||
                functionName == 'add_recipe_ingredient') {
              final confirmed = await onConfirm(functionName, functionArgs);
              if (!confirmed) {
                _history.add({
                  'role': 'tool',
                  'tool_call_id': toolCallId,
                  'name': functionName,
                  'content': jsonEncode({'status': 'cancelled', 'message': 'User cancelled the operation.'}),
                });
                continue;
              }
            }

            final result = await _handleFunctionCall(functionName, functionArgs);
            _history.add({
              'role': 'tool',
              'tool_call_id': toolCallId,
              'name': functionName,
              'content': jsonEncode(result),
            });
          }
          // Continue loop to send tool responses back to Groq
          continue;
        }

        // No tool calls, we have a final response
        final responseText = assistantMessage['content'] ?? "I've processed your request.";
        uiMessages.add({'role': 'assistant', 'text': responseText});
        
        return responseText;
      }
    } catch (e) {
      print('AI Error: $e');
      final errorMsg = e.toString().contains('Exception:') 
          ? e.toString().replaceFirst('Exception: ', '')
          : "I'm having trouble with that request right now. ($e)";
      uiMessages.add({'role': 'assistant', 'text': errorMsg});
      return errorMsg;
    }
  }

  List<Map<String, dynamic>> _parseHallucinatedToolCalls(String text) {
    final List<Map<String, dynamic>> calls = [];
    final regExp = RegExp(r'<function=(\w+)>(.*?)(?:</function>|$)');
    final matches = regExp.allMatches(text);
    
    for (final match in matches) {
      final name = match.group(1)!;
      String jsonStr = match.group(2)!.trim();
      
      // Cleanup common AI JSON errors
      if (!jsonStr.startsWith('{')) jsonStr = '{$jsonStr';
      if (!jsonStr.endsWith('}')) jsonStr = '$jsonStr}';
      
      try {
        final args = jsonDecode(jsonStr);
        calls.add({'name': name, 'args': Map<String, dynamic>.from(args)});
      } catch (e) {
        print('DEBUG: Failed to parse hallucinated JSON: $jsonStr');
      }
    }
    return calls;
  }

  Future<Map<String, dynamic>> _handleFunctionCall(String name, Map<String, dynamic> params) async {
    switch (name) {
      case 'get_daily_summary':
        String dateStr = params['date'] as String? ?? DateTime.now().toIso8601String().split('T')[0];
        if (dateStr.toLowerCase() == 'today') {
          dateStr = DateTime.now().toIso8601String().split('T')[0];
        }
        
        DateTime date;
        try {
          date = DateTime.parse(dateStr);
        } catch (e) {
          print('DEBUG: Invalid date format: $dateStr. Falling back to today.');
          date = DateTime.now();
        }
        final logs = await _firebaseService.getFoodLogsStream().first;
        final dailyLogs = logs.where((log) => 
          log.timestamp.year == date.year && 
          log.timestamp.month == date.month && 
          log.timestamp.day == date.day
        ).toList();

        return {
          'total_calories': dailyLogs.fold(0, (sum, item) => sum + item.calories),
          'total_protein': dailyLogs.fold(0.0, (sum, item) => sum + item.protein),
          'total_carbs': dailyLogs.fold(0.0, (sum, item) => sum + item.carbs),
          'total_fats': dailyLogs.fold(0.0, (sum, item) => sum + item.fats),
          'logs': dailyLogs.map((l) => {
            'id': l.id, 
            'name': l.name, 
            'calories': l.calories,
            'quantity': l.quantity,
            'servingSize': l.servingSize,
            'selectedMeasureIndex': l.selectedMeasureIndex,
          }).toList(),
        };

      case 'get_recipes':
        final recipes = await _firebaseService.getRecipesStream().first;
        return {
          'recipes': recipes.map((r) => {
            'id': r.id,
            'name': r.name,
            'calories_per_serving': r.caloriesPerServing,
            'total_weight': r.totalWeight,
            'servings': r.servings,
            'ingredients': r.ingredients.map((i) => {
              'name': i.name,
              'quantity': i.quantity,
              'servingSize': i.servingSize
            }).toList()
          }).toList()
        };

      case 'log_recipe':
        final recipeId = params['recipe_id'] as String;
        final unit = params['unit'] as String? ?? 'Servings';
        final quantity = (params['quantity'] as num? ?? 1.0).toDouble();
        final recipes = await _firebaseService.getRecipesStream().first;
        try {
          final recipe = recipes.firstWhere((r) => r.id == recipeId);
          
          final double factorForNutrients = unit == 'Servings'
              ? (recipe.servings > 0 ? quantity / recipe.servings : 0)
              : (recipe.totalWeight > 0 ? quantity / recipe.totalWeight : 0);

          final int calculatedCalories = unit == 'Servings'
              ? (recipe.caloriesPerServing * quantity).toInt()
              : (recipe.caloriesPer100g * quantity / 100.0).toInt();

          final newLog = FoodLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: recipe.name,
            calories: calculatedCalories,
            protein: recipe.totalProtein * factorForNutrients,
            carbs: recipe.totalCarbs * factorForNutrients,
            fats: recipe.totalFats * factorForNutrients,
            servingSize: unit == 'Servings'
                ? (quantity == 1.0 ? '1 serving' : '${quantity.toString().replaceAll('.0', '')} servings')
                : '${quantity.toString().replaceAll('.0', '')} g',
            timestamp: DateTime.now(),
            quantity: quantity,
            availableMeasures: [
              {'label': unit, 'weight': unit == 'Servings' ? (recipe.totalWeight / recipe.servings) : 1.0}
            ],
            selectedMeasureIndex: 0,
            baseCalories: recipe.caloriesPer100g.toInt(),
            baseProtein: recipe.proteinPer100g,
            baseCarbs: recipe.carbsPer100g,
            baseFats: recipe.fatsPer100g,
          );
          await _firebaseService.addFoodLog(newLog);
          return {'status': 'success', 'message': 'Logged ${recipe.name}'};
        } catch (e) {
          return {'error': 'Recipe not found or error logging: $e'};
        }

      case 'search_food_nutrition':
        final query = params['query'] as String;
        try {
          final results = await _edamamService.searchFood(query);
          if (results.isEmpty) return {'error': 'No food found for "$query"'};
          
          final food = results.first;
          return {
            'name': food['name'],
            'calories_per_100g': food['calories'],
            'protein_per_100g': food['protein'],
            'carbs_per_100g': food['carbs'],
            'fats_per_100g': food['fats'],
            'measures': food['measures'],
          };
        } catch (e) {
          return {'error': 'Edamam search failed: $e'};
        }

      case 'add_food_log':
        final log = FoodLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: params['name'] as String? ?? 'Unknown Food',
          calories: (params['calories'] as num? ?? 0).toInt(),
          protein: (params['protein'] as num? ?? 0.0).toDouble(),
          carbs: (params['carbs'] as num? ?? 0.0).toDouble(),
          fats: (params['fats'] as num? ?? 0.0).toDouble(),
          servingSize: params['servingSize'] as String? ?? '1 serving',
          timestamp: DateTime.now(),
          quantity: (params['quantity'] as num? ?? 1.0).toDouble(),
          availableMeasures: [{'label': 'serving', 'weight': 100.0}],
          selectedMeasureIndex: 0,
          baseCalories: (params['baseCalories'] as num? ?? (params['calories'] as num? ?? 0)).toInt(),
          baseProtein: (params['baseProtein'] as num? ?? (params['protein'] as num? ?? 0.0)).toDouble(),
          baseCarbs: (params['baseCarbs'] as num? ?? (params['carbs'] as num? ?? 0.0)).toDouble(),
          baseFats: (params['baseFats'] as num? ?? (params['fats'] as num? ?? 0.0)).toDouble(),
        );
        await _firebaseService.addFoodLog(log);
        return {'status': 'success', 'added': log.name};

      case 'add_recipe_ingredient':
        final recipeId = params['recipe_id'] as String;
        final recipes = await _firebaseService.getRecipesStream().first;
        try {
          final recipe = recipes.firstWhere((r) => r.id == recipeId);
          final newIngredient = FoodLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: params['name'] as String? ?? 'Unknown Food',
            calories: (params['calories'] as num? ?? 0).toInt(),
            protein: (params['protein'] as num? ?? 0.0).toDouble(),
            carbs: (params['carbs'] as num? ?? 0.0).toDouble(),
            fats: (params['fats'] as num? ?? 0.0).toDouble(),
            servingSize: params['servingSize'] as String? ?? '1 serving',
            timestamp: DateTime.now(),
            quantity: (params['quantity'] as num? ?? 1.0).toDouble(),
            availableMeasures: [{'label': 'serving', 'weight': 100.0}],
            selectedMeasureIndex: 0,
            baseCalories: (params['baseCalories'] as num? ?? (params['calories'] as num? ?? 0)).toInt(),
            baseProtein: (params['baseProtein'] as num? ?? (params['protein'] as num? ?? 0.0)).toDouble(),
            baseCarbs: (params['baseCarbs'] as num? ?? (params['carbs'] as num? ?? 0.0)).toDouble(),
            baseFats: (params['baseFats'] as num? ?? (params['fats'] as num? ?? 0.0)).toDouble(),
          );
          
          final updatedIngredients = List<FoodLog>.from(recipe.ingredients)..add(newIngredient);
          final updatedRecipe = RecipeModel(
            id: recipe.id,
            name: recipe.name,
            ingredients: updatedIngredients,
            servings: recipe.servings,
            isDeleted: recipe.isDeleted,
          );
          await _firebaseService.updateRecipe(updatedRecipe);
          return {'status': 'success', 'message': 'Ingredient "${newIngredient.name}" added to recipe.'};
        } catch (e) {
          return {'error': 'Recipe not found or error adding ingredient: $e'};
        }

      case 'update_food_log':
        final id = params['id'] as String;
        final logs = await _firebaseService.getFoodLogsStream().first;
        try {
          final existing = logs.firstWhere((l) => l.id == id);
          final newQuantity = (params['quantity'] as num? ?? existing.quantity).toDouble();
          final newMeasureIndex = (params['selectedMeasureIndex'] as num? ?? existing.selectedMeasureIndex).toInt();
          
          final weight = existing.availableMeasures[newMeasureIndex]['weight'] as double;
          final multiplier = (weight / 100.0) * newQuantity;

          final updated = FoodLog(
            id: id,
            name: existing.name,
            calories: (existing.baseCalories * multiplier).round(), 
            protein: existing.baseProtein * multiplier,
            carbs: existing.baseCarbs * multiplier,
            fats: existing.baseFats * multiplier,
            servingSize: existing.availableMeasures[newMeasureIndex]['label'] == 'serving' 
                ? (newQuantity == 1.0 ? '1 serving' : '${newQuantity.toString().replaceAll('.0', '')} servings')
                : '${(newQuantity * weight).toString().replaceAll('.0', '')} g',
            timestamp: existing.timestamp,
            quantity: newQuantity,
            availableMeasures: existing.availableMeasures,
            selectedMeasureIndex: newMeasureIndex,
            baseCalories: existing.baseCalories,
            baseProtein: existing.baseProtein,
            baseCarbs: existing.baseCarbs,
            baseFats: existing.baseFats,
          );
          await _firebaseService.updateFoodLog(updated);
          return {'status': 'success', 'updated': updated.name};
        } catch (e) {
          return {'error': 'Log entry not found: $e'};
        }

      case 'delete_food_log':
        final id = params['id'] as String;
        await _firebaseService.softDeleteFoodLog(id);
        return {'status': 'success', 'message': 'Log deleted.'};

      case 'delete_recipe':
        final recipeId = params['recipe_id'] as String;
        await _firebaseService.softDeleteRecipe(recipeId);
        return {'status': 'success', 'message': 'Recipe deleted.'};

      case 'delete_recipe_ingredient':
        final recipeId = params['recipe_id'] as String;
        final ingredientName = params['ingredient_name'] as String;
        final recipes = await _firebaseService.getRecipesStream().first;
        try {
          final recipe = recipes.firstWhere((r) => r.id == recipeId);
          final updatedIngredients = recipe.ingredients
              .where((i) => !i.name.toLowerCase().contains(ingredientName.toLowerCase()))
              .toList();
          
          final updatedRecipe = RecipeModel(
            id: recipe.id,
            name: recipe.name,
            ingredients: updatedIngredients,
            servings: recipe.servings,
            isDeleted: recipe.isDeleted,
          );
          await _firebaseService.updateRecipe(updatedRecipe);
          return {'status': 'success', 'message': 'Ingredient "$ingredientName" removed from recipe.'};
        } catch (e) {
          return {'error': 'Recipe or ingredient not found: $e'};
        }

      case 'update_recipe_ingredient':
        final recipeId = params['recipe_id'] as String;
        final ingredientName = params['ingredient_name'] as String;
        final newQuantity = (params['quantity'] as num).toDouble();
        final recipes = await _firebaseService.getRecipesStream().first;
        try {
          final recipe = recipes.firstWhere((r) => r.id == recipeId);
          final index = recipe.ingredients.indexWhere(
            (i) => i.name.toLowerCase().contains(ingredientName.toLowerCase())
          );
          
          if (index == -1) return {'error': 'Ingredient "$ingredientName" not found in recipe.'};
          
          final existing = recipe.ingredients[index];
          final weight = existing.availableMeasures[existing.selectedMeasureIndex]['weight'] as double;
          final multiplier = (weight / 100.0) * newQuantity;

          final updatedIngredient = FoodLog(
            id: existing.id,
            name: existing.name,
            calories: (existing.baseCalories * multiplier).round(), 
            protein: existing.baseProtein * multiplier,
            carbs: existing.baseCarbs * multiplier,
            fats: existing.baseFats * multiplier,
            servingSize: existing.availableMeasures[existing.selectedMeasureIndex]['label'] == 'serving' 
                ? (newQuantity == 1.0 ? '1 serving' : '${newQuantity.toString().replaceAll('.0', '')} servings')
                : '${(newQuantity * weight).toString().replaceAll('.0', '')} g',
            timestamp: existing.timestamp,
            quantity: newQuantity,
            availableMeasures: existing.availableMeasures,
            selectedMeasureIndex: existing.selectedMeasureIndex,
            baseCalories: existing.baseCalories,
            baseProtein: existing.baseProtein,
            baseCarbs: existing.baseCarbs,
            baseFats: existing.baseFats,
          );
          
          final updatedIngredients = List<FoodLog>.from(recipe.ingredients);
          updatedIngredients[index] = updatedIngredient;

          final updatedRecipe = RecipeModel(
            id: recipe.id,
            name: recipe.name,
            ingredients: updatedIngredients,
            servings: recipe.servings,
            isDeleted: recipe.isDeleted,
          );
          await _firebaseService.updateRecipe(updatedRecipe);
          return {'status': 'success', 'message': 'Updated "$ingredientName" quantity in recipe.'};
        } catch (e) {
          return {'error': 'Recipe or ingredient not found: $e'};
        }

      default:
        return {'error': 'Unknown function'};
    }
  }

  void clearHistory() {
    _resetHistory();
    uiMessages.clear();
  }
}
