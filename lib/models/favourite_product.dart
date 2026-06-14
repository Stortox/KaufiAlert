import 'product.dart';

/// A favorited [Product] enriched with whether it is still available in the
/// user's currently selected store.
///
/// Availability is computed at display time (favorites are persisted as plain
/// [Product] JSON), so it is never read back from storage.
class FavouriteProduct extends Product {
  final bool stillAvailable;

  const FavouriteProduct({
    required super.title,
    required super.price,
    required super.discount,
    required super.basePrice,
    required super.oldPrice,
    required super.imageUrl,
    required super.description,
    required super.category,
    required super.unit,
    required super.gtin,
    required this.stillAvailable,
  });

  /// Wraps an existing [product] with its computed [available] status.
  factory FavouriteProduct.fromProduct(Product product, {required bool available}) =>
      FavouriteProduct(
        title: product.title,
        price: product.price,
        discount: product.discount,
        basePrice: product.basePrice,
        oldPrice: product.oldPrice,
        imageUrl: product.imageUrl,
        description: product.description,
        category: product.category,
        unit: product.unit,
        gtin: product.gtin,
        stillAvailable: available,
      );
}
