// services/edamam_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EdamamService {
  final String appId = dotenv.get('EDAMAM_APP_ID');
  final String appKey = dotenv.get('EDAMAM_APP_KEY');
  final String baseUrl = 'https://api.edamam.com/api/food-database/v2/parser';

  Future<List<Map<String, dynamic>>> searchFood(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse('$baseUrl?ingr=$query&app_id=$appId&app_key=$appKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List hints = data['hints'] ?? [];

        return hints.map((hint) {
          final food = hint['food'];
          final nutrients = food['nutrients'] ?? {};
          final List measures = hint['measures'] ?? [];

          return {
            'name': food['label'],
            'calories': (nutrients['ENERC_KCAL'] ?? 0).toInt(),
            'protein': (nutrients['PROCNT'] ?? 0.0).toDouble(),
            'carbs': (nutrients['CHOCDF'] ?? 0.0).toDouble(),
            'fats': (nutrients['FAT'] ?? 0.0).toDouble(),
            'image': food['image'],
            'measures': (measures.isEmpty) 
              ? [{'label': 'Serving', 'weight': 100.0}]
              : measures.map((m) => {
                'label': m['label']?.toString() ?? 'Serving',
                'weight': (m['weight'] ?? 100.0).toDouble(),
              }).toList(),
          };
        }).toList();
      } else {
        throw Exception('Failed to load food data');
      }
    } catch (e) {
      print('Error searching food: $e');
      return [];
    }
  }
}
