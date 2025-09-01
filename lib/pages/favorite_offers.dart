import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kaufi_allert_v2/pages/offers_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteOffers extends StatefulWidget {
  const FavoriteOffers({super.key});

  @override
  State<FavoriteOffers> createState() => _FavoriteOffersState();
}

class _FavoriteOffersState extends State<FavoriteOffers> {
  late SharedPreferences prefs;
  List<FavouriteProduct> favoriteOffers = [];

  Future<void> getSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<List<FavouriteProduct>> initializeFavoriteOffers() async {
    favoriteOffers = await getFavoriteOffers();
    if(mounted) {
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
        title: const Text("Favorite Offers", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1f1415),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: 
            favoriteOffers.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80.0),
                    child: Center(
                      child: Text(
                        "No favorite offers found",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ]
              : [
                  Padding(padding: const EdgeInsets.only(top: 10)),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: favoriteOffers.length,
                      itemBuilder: (context, index) {
                        FavouriteProduct product = favoriteOffers[index];
                        return offerCard(product, context);
                      },
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  Future<List<FavouriteProduct>> getFavoriteOffers() async {
    String? favoriteOffers = prefs.getString('favoriteOffers');
    if(prefs.getString('storeId') == null || prefs.getString('storeId')!.isEmpty) {
      prefs.setString('storeId', 'DE3940');
    }
    List<Product> cachedOffers = await getCachedOffers();
    if (favoriteOffers != null && favoriteOffers.isNotEmpty && cachedOffers.isNotEmpty) {
      List<dynamic> jsonList = jsonDecode(favoriteOffers);
      List<FavouriteProduct> favoriteProducts = jsonList.map((json) {
        bool isAvailable = cachedOffers.any((offerJson) =>
          offerJson.title == json['title'] &&
          offerJson.imageUrl == json['imageUrl']
        );
        return FavouriteProduct(
          title: json['title'],
          price: json['price'],
          discount: json['discount'],
          basePrice: json['basePrice'],
          oldPrice: json['oldPrice'],
          imageUrl: json['imageUrl'],
          description: json['description'],
          category: json['category'],
          unit: json['unit'],
          gtin: json['gtin'],
          stillAvailable: isAvailable ? "true" : "false",
        );
      }).toList();
      return favoriteProducts;
    }
    return [];
  }

  Future<List<Product>> getCachedOffers() async {
    //print("Fetching cached offers from SharedPreferences");
    String? cachedData = prefs.getString('offersFinal${prefs.getString('storeId') ?? 'DE3940'}');
    if (cachedData != null) {
      List<dynamic> jsonList = json.decode(cachedData);
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
}

Widget offerCard(FavouriteProduct product, BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(
        context, 
        '/offerDetail',
        arguments: product.toProduct(),
      );
    },
    child: SizedBox(
      width: (MediaQuery.of(context).size.width - 20) / 2,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Stack(
        children: [
          Card(
            color: const Color(0xFF1f1415),
            child: Column(
              children: [
                Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: product.imageUrl,
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 20) / 2,
                        height: MediaQuery.of(context).size.height * 0.2,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: (MediaQuery.of(context).size.width - 20) / 2 - 20,
                            height: MediaQuery.of(context).size.height * 0.2 - 20,
                            child: CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => CircularProgressIndicator(),
                              errorWidget: (context, url, error) => Icon(Icons.broken_image, color: Colors.grey),
                            )
                          ),
                        ),
                      ),
                    ),
                  ),
                  if(int.parse(product.discount.replaceAll("%", "").replaceAll("-", "").trim()) > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: Text(
                        "-${product.discount}",
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.title,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 23.0),
                      child: Text(
                        product.price,
                        style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Card(
            color: product.stillAvailable == "true" ? Colors.green : Colors.red,
            margin: const EdgeInsets.only(top: 5.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                product.stillAvailable == "true" ? "Available" : "Currently Not Available",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
        ],
      ),
    ),
  );
}

  class FavouriteProduct {
  final String title;
  final String price;
  final String discount;
  final String basePrice;
  final String oldPrice;
  final String imageUrl;
  final String description;
  final String category;
  final String unit;
  final String gtin;
  final String stillAvailable;

  FavouriteProduct({
    required this.title,
    required this.price,
    required this.discount,
    required this.basePrice,
    required this.oldPrice,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.unit,
    required this.gtin,
    required this.stillAvailable,
  });

  FavouriteProduct.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        price = json['price'],
        discount = json['discount'],
        basePrice = json['basePrice'],
        oldPrice = json['oldPrice'],
        imageUrl = json['imageUrl'],
        description = json['description'],
        category = json['category'],
        unit = json['unit'],
        gtin = json['gtin'],
        stillAvailable = json['stillAvailable'];

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'price': price,
      'discount': discount,
      'basePrice': basePrice,
      'oldPrice': oldPrice,
      'imageUrl': imageUrl,
      'description': description,
      'category': category,
      'unit': unit,
      'gtin': gtin,
      'stillAvailable': stillAvailable,
    };
  }

  Product toProduct() {
    return Product(
      title: title,
      price: price,
      discount: discount,
      basePrice: basePrice,
      oldPrice: oldPrice,
      imageUrl: imageUrl,
      description: description,
      category: category,
      unit: unit,
      gtin: gtin,
    );
  }
}