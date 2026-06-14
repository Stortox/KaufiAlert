import 'dart:convert';

import 'package:http/http.dart' as http;

/// Ingredients + nutrient table for a product, fetched from OpenFoodFacts.
class ProductFacts {
  final String ingredients;
  final List<MapEntry<String, String>> nutrients;

  const ProductFacts({required this.ingredients, required this.nutrients});

  static const empty = ProductFacts(ingredients: '', nutrients: []);
}

/// Fetches product facts from OpenFoodFacts.
///
/// Each GTIN is requested at most once and cached in memory for the app
/// session, replacing the previous behaviour where the same URL was fetched
/// twice per detail screen and re-fetched on every widget rebuild.
class OpenFoodFactsService {
  OpenFoodFactsService._();
  static final OpenFoodFactsService instance = OpenFoodFactsService._();

  final Map<String, ProductFacts> _cache = {};

  Future<ProductFacts> factsFor(String gtin) async {
    if (gtin.isEmpty) return ProductFacts.empty;
    final cached = _cache[gtin];
    if (cached != null) return cached;

    final response = await http.get(
      Uri.parse('https://world.openfoodfacts.org/api/v2/product/$gtin.json'),
    );
    if (response.statusCode != 200) return ProductFacts.empty;

    final product = jsonDecode(response.body)['product'] ?? <String, dynamic>{};
    final facts = ProductFacts(
      ingredients: product['ingredients_text_with_allergens_de'] ?? '',
      nutrients: _parseNutrients(product['nutriments'] ?? <String, dynamic>{}),
    );
    _cache[gtin] = facts;
    return facts;
  }

  /// Extracts the relevant per-100g nutrients into name/value pairs.
  static List<MapEntry<String, String>> _parseNutrients(
    Map<String, dynamic> nutriments,
  ) {
    const wanted = [
      'carbohydrates',
      'energy',
      'fat',
      'proteins',
      'salt',
      'saturated-fat',
      'sodium',
      'sugars',
    ];

    final names = <String>[];
    final values = <String>[];
    final units = <String>[];

    for (final entry in nutriments.entries) {
      final key = entry.key.toString();
      final prefixEnd = key.contains('-')
          ? key.indexOf('-')
          : key.contains('_')
          ? key.indexOf('_')
          : key.length;
      if (!wanted.contains(key.substring(0, prefixEnd))) continue;

      // Energy is reported in both kJ and kcal; keep only kcal.
      if (key.contains('energy') && !key.contains('kcal')) continue;

      if (!key.contains('-') && !key.contains('_')) {
        names.add(key[0].toUpperCase() + key.substring(1));
      } else if (key == 'energy-kcal') {
        names.add(key[0].toUpperCase() + key.substring(1, key.indexOf('-kcal')));
      } else if (key.contains('100g')) {
        final value = entry.value.toString();
        if (value.contains('.')) {
          final decimals = value.substring(value.indexOf('.') + 1).length;
          values.add(
            decimals > 3 ? value.substring(0, value.indexOf('.') + 3) : value,
          );
        } else {
          values.add(value.substring(0, value.length > 4 ? 4 : value.length));
        }
      } else if (key.contains('unit')) {
        units.add(entry.value.toString());
      }
    }

    if (names.length > units.length || names.length > values.length) {
      return [];
    }
    return [
      for (var i = 0; i < names.length; i++)
        MapEntry(names[i], '${values[i]} ${units[i]}'),
    ];
  }
}
