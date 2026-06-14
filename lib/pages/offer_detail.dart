import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product.dart';
import '../services/offers_repository.dart';
import '../services/open_food_facts_service.dart';

class OfferDetail extends StatefulWidget {
  const OfferDetail({super.key, required this.product});

  final Product product;

  @override
  State<OfferDetail> createState() => _OfferDetailState();
}

class _OfferDetailState extends State<OfferDetail> {
  List<Product> _favorites = [];
  bool _isFavorite = false;

  ProductFacts _facts = ProductFacts.empty;
  bool _factsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadFacts();
  }

  Future<void> _loadFavorites() async {
    final favorites = OffersRepository.instance.favorites();
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      // Match on Product equality (title + imageUrl), consistent with the
      // de-duplication and availability checks elsewhere.
      _isFavorite = favorites.contains(widget.product);
    });
  }

  Future<void> _loadFacts() async {
    final gtin = widget.product.gtin;
    if (gtin.isEmpty) {
      if (mounted) setState(() => _factsLoading = false);
      return;
    }
    final facts = await OpenFoodFactsService.instance.factsFor(gtin);
    if (!mounted) return;
    setState(() {
      _facts = facts;
      _factsLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      if (_isFavorite) {
        _favorites.removeWhere((p) => p == widget.product);
      } else {
        _favorites.add(widget.product);
      }
      _isFavorite = !_isFavorite;
    });
    await OffersRepository.instance.saveFavorites(_favorites);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF412a2b),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _openOnOpenFoodFacts() async {
    final messenger = ScaffoldMessenger.of(context);
    final gtin = widget.product.gtin;
    if (gtin.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Keine Produktcode verfügbar')),
      );
      return;
    }
    final url = 'https://world.openfoodfacts.org/product/$gtin';
    try {
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        messenger.showSnackBar(
          SnackBar(content: Text('Konnte URL nicht öffnen: $url')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Fehler beim Öffnen der URL: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF1f1415),
      appBar: AppBar(
        title: const Text(
          "Product Details",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1f1415),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
              size: 40,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Hero(
                  tag: product.imageUrl,
                  child: Container(
                    width: size.width - 20,
                    height: size.height * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: size.width - 40,
                        height: size.height * 0.5 - 20,
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 40.0, 10.0, 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        product.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDescription(product),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Text(
                    product.unit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        product.discountValue > 0 ? "-${product.discount}" : "",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    product.price,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: product.unit.indexOf("je kg").isNegative
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Text(
                                product.basePrice.replaceFirst(')', '€)'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (product.oldPrice.isNotEmpty &&
                      product.oldPrice != "0.00€")
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Text(
                          product.oldPrice,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey,
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (product.gtin.isNotEmpty) _buildIngredients(),
              const SizedBox(height: 20),
              if (product.gtin.isNotEmpty) _buildNutrients(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(Product product) {
    if (!product.description.contains("aus eigener Herstellung")) {
      return Text(
        product.description,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.description
              .replaceAll("aus eigener Herstellung", "")
              .trim()
              .replaceAll(RegExp(r',(?!\s)'), ''),
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 5),
            const Text(
              "aus eigener Herstellung",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIngredients() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ingredients:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_facts.ingredients.isNotEmpty)
                GestureDetector(
                  onTap: _openOnOpenFoodFacts,
                  child: const Row(
                    children: [
                      Text(
                        'OpenFoodFacts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      Icon(Icons.arrow_outward, color: Colors.white),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _facts.ingredients.isNotEmpty
                  ? formatIngredientsText(_facts.ingredients)
                  : 'No ingredients information available.',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrients() {
    if (_factsLoading) return const CircularProgressIndicator();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutritional Information:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Nutrient',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              Text(
                'per 100g',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          const Divider(color: Colors.white, thickness: 1, height: 20),
          if (_facts.nutrients.isEmpty)
            const Text(
              'No nutritional information available.',
              style: TextStyle(color: Colors.white, fontSize: 14),
            )
          else
            for (final nutrient in _facts.nutrients)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        nutrient.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      nutrient.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// Normalizes OpenFoodFacts ingredient markup into readable text.
String formatIngredientsText(String ingredientsText) {
  ingredientsText = ingredientsText
      .toLowerCase()
      .replaceAll('<span class="allergen">', '')
      .replaceAll('</span>', '');
  final words = ingredientsText.split(' ').map((word) {
    word = word.trim();
    if (word.isEmpty) return '';
    if (!word.contains(RegExp(r'[a-z]'))) return word;
    return word.replaceFirst(
      RegExp(r'[a-z]'),
      RegExp(r'[a-z]').firstMatch(word)![0]!.toUpperCase(),
    );
  }).toList();
  return words.join(' ');
}
