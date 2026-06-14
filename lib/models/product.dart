/// A single Kaufland offer.
///
/// Equality is based on [title] + [imageUrl], which is the natural identity
/// used everywhere in the app (de-duplication of fetched offers and matching
/// favorites against the current store's inventory).
class Product {
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

  const Product({
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
  });

  /// Builds a [Product] from cached/stored JSON, tolerating missing fields.
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    title: json['title'] ?? '',
    price: json['price'] ?? '',
    discount: json['discount'] ?? '',
    basePrice: json['basePrice'] ?? '',
    oldPrice: json['oldPrice'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
    description: json['description'] ?? '',
    category: json['category'] ?? '',
    unit: json['unit'] ?? '',
    gtin: json['gtin'] ?? '',
  );

  Map<String, dynamic> toJson() => {
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
  };

  /// Numeric price in euros (e.g. "1,99€" -> 1.99), or 0 when unparseable.
  double get priceValue =>
      double.tryParse(price.replaceAll('€', '').replaceAll(',', '.').trim()) ??
      0.0;

  /// Numeric discount percentage (e.g. "-20%" -> 20), or 0 when unparseable.
  int get discountValue =>
      int.tryParse(discount.replaceAll('%', '').replaceAll('-', '').trim()) ?? 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && other.title == title && other.imageUrl == imageUrl;

  @override
  int get hashCode => Object.hash(title, imageUrl);
}
