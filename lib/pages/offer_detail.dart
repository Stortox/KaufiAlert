import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kaufi_allert_v2/pages/offers_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfferDetail extends StatefulWidget {
  const OfferDetail({super.key, required this.product});

  final Product product;

  @override
  State<OfferDetail> createState() => _OfferDetailState();
}

class _OfferDetailState extends State<OfferDetail> {
  late SharedPreferences prefs;
  List<Product> favoriteOffers = [];

  getSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<List<Product>> initializeFavoriteOffers() async {
    favoriteOffers = await getFavoriteOffers();
    setState(() {});
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
                      ),
                    ).title.isNotEmpty ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                  size: 40,
                ),
                onPressed: () {
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
      body: Center(
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
