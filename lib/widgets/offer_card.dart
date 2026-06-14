import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';

/// Grid card for a single offer, shared by the Offers and Favorites screens.
///
/// When [available] is non-null an availability badge is shown (Favorites
/// screen); otherwise the card renders without it (Offers screen).
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.product, this.available});

  final Product product;
  final bool? available;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = (size.width - 20) / 2;
    final imageHeight = size.height * 0.2;

    final card = Card(
      color: const Color(0xFF1f1415),
      child: Column(
        children: [
          Stack(
            children: [
              Center(
                child: Hero(
                  tag: product.imageUrl,
                  child: Container(
                    width: cardWidth,
                    height: imageHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: cardWidth - 20,
                        height: imageHeight - 20,
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
              if (product.discountValue > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/offerDetail', arguments: product),
      child: SizedBox(
        width: cardWidth,
        height: size.height * 0.5,
        child: available == null
            ? card
            : Stack(
                children: [
                  card,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Card(
                      color: available! ? Colors.green : Colors.red,
                      margin: const EdgeInsets.only(top: 5.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Text(
                          available! ? "Available" : "Currently Not Available",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
