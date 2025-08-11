import 'dart:convert';

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
  List<Product> favoriteOffers = [];

  getSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<List<Product>> initializeFavoriteOffers() async {
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
                        Product product = favoriteOffers[index];
                        return offerCard(product, context);
                      },
                    ),
                  ),
                ],
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
        unit: json['unit']
      )).toList();
    }
    return [];
  }
}