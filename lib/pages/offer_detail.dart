import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kaufi_allert_v2/pages/offers_page.dart';

class OfferDetail extends StatelessWidget {
  const OfferDetail({super.key, required this.product});

  final Product product;

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
                  OffersPage.favoriteOffers.contains(product) ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    if (OffersPage.favoriteOffers.contains(product)) {
                      OffersPage.favoriteOffers.remove(product);
                    } else {
                      OffersPage.favoriteOffers.add(product);
                    }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                      OffersPage.favoriteOffers.contains(product)
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
                tag: product.imageUrl,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 40.0, 10.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      product.title,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (product.description.contains("aus eigener Herstellung"))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.description.replaceAll("aus eigener Herstellung", "").trim().replaceAll(RegExp(r',(?!\s)'), ''),
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
                      product.description,
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
                  product.unit,
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
                      int.parse(product.discount.replaceAll("%", "").replaceAll("-", "").trim()) > 0 ? "-${product.discount}" : "",
                      style: const TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  product.price,
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
}