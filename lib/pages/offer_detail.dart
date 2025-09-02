import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kaufi_allert_v2/pages/offers_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OfferDetail extends StatefulWidget {
  const OfferDetail({super.key, required this.product});

  final Product product;

  @override
  State<OfferDetail> createState() => _OfferDetailState();
}

class _OfferDetailState extends State<OfferDetail> {
  late SharedPreferences prefs;
  List<Product> favoriteOffers = [];
  String ingredientsText = '';

  Future<void> getSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<List<Product>> initializeFavoriteOffers() async {
    if (mounted) {
      favoriteOffers = await getFavoriteOffers();
      setState(() {});
    }
    return favoriteOffers;
  }

  Future<void> initializeSharedPreferences() async {
    await getSharedPreferences();
  }

  @override
  void initState() {
    super.initState();
    initializeSharedPreferences().then((_) {
      initializeFavoriteOffers();
    });
    http.get(Uri.parse('https://world.openfoodfacts.org/api/v2/product/${widget.product.gtin}.json')).then((response) {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          ingredientsText = data['product']['ingredients_text_with_allergens_de'] ?? '';
        });
      }
    });
    formatIngredientsText(ingredientsText);
    getOpenFoodFactsGtin(widget.product.gtin);
  }

  @override
  void dispose() {
    favoriteOffers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1f1415),
      appBar: AppBar(
        title: Text("Product Details", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1f1415),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return IconButton(
                icon: Icon(
                  favoriteOffers.firstWhere(
                      (product) => product.title == widget.product.title,
                      orElse: () => Product(
                        title: '',
                        price: '',
                        discount: '',
                        basePrice: '',
                        oldPrice: '',
                        imageUrl: '',
                        description: '',
                        category: '',
                        unit: '',
                        gtin: '',
                      ),
                    ).title.isNotEmpty ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                  size: 40,
                ),
                onPressed: () {
                  if(mounted){
                    setState(() {
                      Product existingProduct = favoriteOffers.firstWhere(
                        (product) => product.title == widget.product.title,
                        orElse: () => Product(
                          title: '',
                          price: '',
                          discount: '',
                          basePrice: '',
                          oldPrice: '',
                          imageUrl: '',
                          description: '',
                          category: '',
                          unit: '',
                          gtin: '',
                        ),
                      );
                      if (existingProduct.title.isNotEmpty) {
                        favoriteOffers.remove(existingProduct);
                        prefs.setString('favoriteOffers', json.encode(favoriteOffers.map((product) => product.toJson()).toList()));
                      } else {
                        favoriteOffers.add(widget.product);
                        prefs.setString('favoriteOffers', json.encode(favoriteOffers.map((product) => product.toJson()).toList()));
                      }
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                      favoriteOffers.contains(widget.product)
                        ? 'Added to favorites'
                        : 'Removed from favorites',
                      style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF412a2b),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Hero(
                  tag: widget.product.imageUrl,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 20,
                    height: MediaQuery.of(context).size.height * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        height: MediaQuery.of(context).size.height * 0.5 - 20,
                        child: CachedNetworkImage(
                          imageUrl: widget.product.imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.broken_image, color: Colors.grey),
                        )
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
                        widget.product.title,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (widget.product.description.contains("aus eigener Herstellung"))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.description.replaceAll("aus eigener Herstellung", "").trim().replaceAll(RegExp(r',(?!\s)'), ''),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            textAlign: TextAlign.start,
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 5),
                              Text(
                                "aus eigener Herstellung",
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.visible,
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Text(
                        widget.product.description,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.visible,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Text(
                    widget.product.unit,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        int.parse(widget.product.discount.replaceAll("%", "").replaceAll("-", "").trim()) > 0 ? "-${widget.product.discount}" : "",
                        style: const TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.product.price,
                    style: const TextStyle(color: Colors.amber, fontSize: 30, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: widget.product.unit.indexOf("je kg").isNegative
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Text(
                                widget.product.basePrice.replaceFirst(')', '€)'),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          )
                        : SizedBox.shrink(),
                  ),
                  if (widget.product.oldPrice.isNotEmpty && widget.product.oldPrice != "0.00€")
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: Text(
                        widget.product.oldPrice,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.grey,
                          decorationThickness: 2,
                        ),
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                children: [
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
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
                      if(ingredientsText.isNotEmpty)
                      GestureDetector(
                      onTap: () async {
                        final gtin = widget.product.gtin;
                        if (gtin.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Keine Produktcode verfügbar')),
                          );
                          return;
                        }
                        
                        final url = 'https://world.openfoodfacts.org/product/$gtin';
                        final uri = Uri.parse(url);
                        
                        try {
                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Konnte URL nicht öffnen: $url')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Fehler beim Öffnen der URL: $e')),
                          );
                        }
                      },
                      child: Row(
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
                    child: Text(ingredientsText.isNotEmpty ? formatIngredientsText(ingredientsText) : 'No ingredients information available.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              ),
              const SizedBox(height: 20),
              FutureBuilder(future: getOpenFoodFactsGtin(widget.product.gtin), builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final nutriments = snapshot.data as List<MapEntry<String, dynamic>>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nutritional Information:', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
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
                        const Divider(
                          color: Colors.white,
                          thickness: 1,
                          height: 20,
                        ),
                        Builder(builder: (context) {
                          if (nutriments.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: nutriments.map((entry) {
                                return IngredientTile([entry]);
                              }).toList(),
                            );
                          } else {
                            return Text('No nutritional information available.', style: TextStyle(color: Colors.white, fontSize: 14));
                          }
                        }),
                      ],
                    ),
                  );
                }
              },
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Product>> getFavoriteOffers() async {
    //print("Fetching favorite offers from SharedPreferences");
    String? favoriteOffers = prefs.getString('favoriteOffers');
    if (favoriteOffers != null && favoriteOffers.isNotEmpty) {
      List<dynamic> jsonList = jsonDecode(favoriteOffers);
      return jsonList.map((json) => Product(
        title: json['title'],
        price: json['price'],
        discount: json['discount'],
        basePrice: json['basePrice'],
        oldPrice: json['oldPrice'],
        imageUrl: json['imageUrl'],
        description: json['description'],
        category: json['category'],
        unit: json['unit'],
        gtin: json['gtin']
      )).toList();
    }
    return [];
  }

  Future<List<MapEntry<String, dynamic>>> getOpenFoodFactsGtin(String gtin) async {
    final response = await http.get(Uri.parse('https://world.openfoodfacts.org/api/v2/product/$gtin.json'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final nutriments = data['product']['nutriments'] ?? {};
      List<String> nutrimentNames = [];
      List<String> nutrimentValues = [];
      List<String> nutrimentUnit = [];
      List<MapEntry<String, dynamic>> nutrimentsList = [];
      for(var nutriment in nutriments.entries) {
        if(nutriment.key.toString().contains("energy") && !nutriment.key.toString().contains("kcal")){
          continue;
        }
        if(!nutriment.key.toString().contains("-") && !nutriment.key.toString().contains("_")) {
          nutrimentNames.add(nutriment.key.toString()[0].toUpperCase() + nutriment.key.toString().substring(1));
        } else if (nutriment.key.toString() == "energy-kcal") {
          nutrimentNames.add(nutriment.key.toString()[0].toUpperCase() + nutriment.key.toString().substring(1, nutriment.key.toString().indexOf("-kcal")));
        } else if(nutriment.key.toString().contains("100g")) {
          if(nutriment.value.toString().contains(".")){
            if(nutriment.value.toString().substring(nutriment.value.toString().indexOf(".") + 1).length > 3){
              nutrimentValues.add(nutriment.value.toString().substring(0, (nutriment.value.toString().indexOf(".") + 3)));
            } else {
              nutrimentValues.add(nutriment.value.toString());
            }
          } else {
            nutrimentValues.add(nutriment.value.toString().substring(0, nutriment.value.toString().length > 4 ? 4 : nutriment.value.toString().length));
          }
        } else if(nutriment.key.contains("unit")) {
          nutrimentUnit.add(nutriment.value);
        }
      }
      if(!(nutrimentNames.length > nutrimentUnit.length) && !(nutrimentNames.length > nutrimentValues.length)) {
        nutrimentsList.addAll(nutrimentNames.map((name) => MapEntry(name, '${nutrimentValues[nutrimentNames.indexOf(name)]} ${nutrimentUnit[nutrimentNames.indexOf(name)]}')));
      }
      return nutrimentsList;
    }
    return [];
  }
}

String formatIngredientsText(String ingredientsText) {
  ingredientsText = ingredientsText.toLowerCase()
      .replaceAll('<span class="allergen">', '')
      .replaceAll('</span>', '');
  // Split by space, trim, capitalize first letter, rest lowercase
  final words = ingredientsText.split(' ').map((word) {
    word = word.trim();
    if (word.isEmpty) return '';
    if(!word.contains(RegExp(r'[a-z]'))) return word;
    return word.replaceFirst(RegExp(r'[a-z]'), RegExp(r'[a-z]').firstMatch(word)![0]!.toUpperCase());
  }).toList();
  return words.join(' ');
}

Widget IngredientTile(List<MapEntry<String, dynamic>> ingredient) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ingredient.map((entry) {
        return Row(
          children: [
            Expanded(
              child: Text(
                entry.key,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            Text(
              entry.value,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        );
      }).toList(),
    ),
  );
}