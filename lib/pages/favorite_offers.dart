/// This file contains the implementation of the Favorite Offers screen
/// It displays a grid of product offers that the user has saved as favorites
/// and indicates whether those offers are still available in the current store
library;
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kaufi_alert_v2/pages/offers_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FavoriteOffers widget displays a list of the user's saved favorite offers
/// Shows availability status of each offer based on current store's inventory
class FavoriteOffers extends StatefulWidget {
  const FavoriteOffers({super.key});

  @override
  State<FavoriteOffers> createState() => _FavoriteOffersState();
}

class _FavoriteOffersState extends State<FavoriteOffers> {
  late SharedPreferences prefs;
  List<FavouriteProduct> favoriteOffers = [];
  List<FavouriteProduct> filteredFavoriteOffers = [];
  
  // Current filter selection
  FilterType currentFilter = FilterType.all;
  
  // Sorting options
  String currentSorting = 'category';
  
  // List of available sorting options
  final List<Map<String, dynamic>> sortOptions = [
    {'label': 'Category', 'value': 'category'},
    {'label': 'Price (low to high)', 'value': 'priceLow'},
    {'label': 'Price (high to low)', 'value': 'priceHigh'},
    {'label': 'Highest discount', 'value': 'discount'},
    {'label': 'Available first', 'value': 'available'},
  ];
  
  // Filter cache to improve performance
  final Map<FilterType, List<FavouriteProduct>> _filteredProductsCache = {};
  
  // Flag to control filter expansion
  bool filtersExpanded = false;

  /// Initializes SharedPreferences instance
  Future<void> getSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  /// Initializes favorite offers list
  Future<void> initializeFavoriteOffers() async {
    favoriteOffers = await getFavoriteOffers();
    if(mounted) {
      setState(() {
        // Initialize filtered offers with all offers
        filteredFavoriteOffers = favoriteOffers;
        
        // Apply initial sorting based on saved preferences
        getSortingBy().then((value) {
          currentSorting = value;
          _applySorting(currentSorting);
        });
      });
    }
  }

  /// Helper method to initialize SharedPreferences
  Future<void> initializeSharedPreferences() async {
    await getSharedPreferences();
  }

  @override
  void initState() {
    super.initState();
    // Initialize data when the widget is created
    initializeSharedPreferences().then((_) {
      initializeFavoriteOffers();
    });
  }

  @override
  void dispose() {
    // Clean up resources when the widget is removed
    favoriteOffers.clear();
    filteredFavoriteOffers.clear();
    _filteredProductsCache.clear();
    super.dispose();
  }

  /// Retrieves the saved sorting preference
  /// 
  /// Returns:
  ///   [String] The current sorting preference (defaults to 'category')
  Future<String> getSortingBy() async {
    // Get sorting preference from SharedPreferences
    return prefs.getString('favoriteSortBy') ?? 'category';
  }

  /// Saves the current sorting preference
  /// 
  /// Parameters:
  ///   [sortBy] - The sorting option to save
  Future<void> setSortingBy(String sortBy) async {
    await prefs.setString('favoriteSortBy', sortBy);
  }

  /// Applies a filter to the favorite offers
  /// Uses a cache to improve performance on repeated filter operations
  void _applyFilter(FilterType filter) {
    if(mounted) {
      setState(() {
        currentFilter = filter;

        // Use cached results if available
        if (_filteredProductsCache.containsKey(filter)) {
          filteredFavoriteOffers = _filteredProductsCache[filter]!;
          // Apply current sorting to filtered results
          _applySorting(currentSorting);
          return;
        }
        
        // Calculate and cache results
        filteredFavoriteOffers = favoriteOffers.where((product) {
          return filter == FilterType.all || 
                 filter.toString().split('.').last == product.category;
        }).toList();

        _filteredProductsCache[filter] = filteredFavoriteOffers;
        
        // Apply current sorting to filtered results
        _applySorting(currentSorting);
      });
    }
  }

  /// Applies sorting to the filtered favorite offers
  /// 
  /// Parameters:
  ///   [sortBy] - The sorting option to apply
  void _applySorting(String sortBy) {
    if(!mounted) return;
    
    setState(() {
      switch(sortBy) {
        case 'category':
          // Sort by category
          filteredFavoriteOffers.sort((a, b) => a.category.compareTo(b.category));
          break;
          
        case 'priceLow':
          // Sort by price (low to high)
          filteredFavoriteOffers.sort((a, b) {
            double priceA = double.tryParse(a.price.replaceAll('€', '').replaceAll(',', '.').trim()) ?? 0.0;
            double priceB = double.tryParse(b.price.replaceAll('€', '').replaceAll(',', '.').trim()) ?? 0.0;
            return priceA.compareTo(priceB);
          });
          break;
          
        case 'priceHigh':
          // Sort by price (high to low)
          filteredFavoriteOffers.sort((a, b) {
            double priceA = double.tryParse(a.price.replaceAll('€', '').replaceAll(',', '.').trim()) ?? 0.0;
            double priceB = double.tryParse(b.price.replaceAll('€', '').replaceAll(',', '.').trim()) ?? 0.0;
            return priceB.compareTo(priceA);
          });
          break;
          
        case 'discount':
          // Sort by discount (highest first)
          filteredFavoriteOffers.sort((a, b) {
            int discountA = int.tryParse(a.discount.replaceAll('%', '').replaceAll('-', '').trim()) ?? 0;
            int discountB = int.tryParse(b.discount.replaceAll('%', '').replaceAll('-', '').trim()) ?? 0;
            return discountB.compareTo(discountA);
          });
          break;
          
        case 'available':
          // Sort by availability (available first)
          filteredFavoriteOffers.sort((a, b) => 
            b.stillAvailable.compareTo(a.stillAvailable));
          break;
      }
    });
    
    // Save the current sorting preference
    setSortingBy(sortBy);
  }

  /// Creates a filter chip widget for category selection
  Widget _buildFilterChip(String label, FilterType filterType) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: (currentFilter == filterType ? Colors.black : Colors.white),
          fontWeight: (currentFilter == filterType ? FontWeight.bold : FontWeight.normal),
        ),
      ),
      selected: currentFilter == filterType,
      onSelected: (bool selected) {
        if (selected) {
          _applyFilter(filterType);
        }
      },
      backgroundColor: const Color(0xFF412a2b),
      selectedColor: const Color.fromARGB(255, 120, 80, 80),
      checkmarkColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Colors.black, width: 0),
      ),
    );
  }

  /// Creates a sort chip widget for sorting selection
  Widget _buildSortChip(Map<String, dynamic> option, String selectedSort) {
    return Padding(
      padding: option['value'] != sortOptions.last['value'] ? const EdgeInsets.only(right: 8.0) : EdgeInsets.zero,
      child: FilterChip(
        label: Text(
          option['label'],
          style: TextStyle(
            color: selectedSort == option['value'] ? Colors.black : Colors.white,
            fontWeight: selectedSort == option['value'] ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: selectedSort == option['value'],
        onSelected: (bool selected) async {
          if (selected) {
            await setSortingBy(option['value']).then((_) {
              setState(() {
                _applySorting(option['value']);
              });
            });
          }
        },
        backgroundColor: const Color(0xFF412a2b),
        selectedColor: const Color.fromARGB(255, 120, 80, 80),
        checkmarkColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: const BorderSide(color: Colors.black, width: 0),
        ),
      ),
    );
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
          children: [
            if(favoriteOffers.isEmpty) ...[
              // Display a message when no favorites are found
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 80.0),
                child: Center(
                  child: Text(
                    "No favorite offers found",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ] else ...[
              // Filters and sorting section
              Padding(padding: const EdgeInsets.only(top: 10)),
              // Filters toggle button
              GestureDetector(
                onTap: () {
                  setState(() {
                  filtersExpanded = !filtersExpanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end, // Align to the right
                  children: [
                    Text(
                      "Filters",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Icon(
                      filtersExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white,
                    ),
                    Padding(padding: const EdgeInsets.only(right: 10)),
                  ],
                ),
              ),
                
              // Expandable filters section (Categories + Sorting)
              if (filtersExpanded) ...[
                // Categories section
                const SizedBox(height: 8.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Categories", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      _buildFilterChip('All', FilterType.all),
                      const SizedBox(width: 8.0),
                      _buildFilterChip('Fruits & Vegetables', FilterType.fruitAndVegetables),
                      const SizedBox(width: 8.0),
                      _buildFilterChip('Meat & Poultry', FilterType.meatAndPoultry),
                      const SizedBox(width: 8.0),
                      _buildFilterChip('Fish', FilterType.fish),
                      const SizedBox(width: 8.0),
                      _buildFilterChip('Dairy', FilterType.dairyProducts),
                      const SizedBox(width: 8.0),
                      _buildFilterChip('Frozen Food', FilterType.frozenFood),
                      const SizedBox(width: 8.0),
                      _buildFilterChip('Canned Goods', FilterType.cannedGoods),
                      const SizedBox(width: 8.0),
                      _buildFilterChip('Staple Foods', FilterType.stapleFoods),
                      const SizedBox(width: 8.0),
                      _buildFilterChip('Coffee, Tea, Sweets & Snacks', FilterType.coffeeTeaSweetsSnacks),
                      const SizedBox(width: 8.0),
                      _buildFilterChip('Beverages', FilterType.beverages),
                      const SizedBox(width: 8.0),
                      _buildFilterChip('Bakery', FilterType.bakery),
                      const SizedBox(width: 8.0),
                      _buildFilterChip('Organic', FilterType.organic),
                    ],
                  ),
                ),
                
                // Sorting section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Sort Offers By", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
                FutureBuilder<String>(
                  future: getSortingBy(),
                  builder: (context, snapshot) {
                    String selectedSort = snapshot.data ?? 'category';
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: sortOptions.map((option) {
                          if(currentFilter != FilterType.all && option['value'] == 'category') {
                            return const SizedBox.shrink();
                          } else {
                            return _buildSortChip(option, selectedSort);
                          }
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ],
            const SizedBox(height: 8.0),
            // Display grid of filtered favorite offers
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredFavoriteOffers.length,
                itemBuilder: (context, index) {
                  FavouriteProduct product = filteredFavoriteOffers[index];
                  return offerCard(product, context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Retrieves favorite offers from local storage and checks if they're still available
  /// by comparing with the current store's active offers
  Future<List<FavouriteProduct>> getFavoriteOffers() async {
    String? favoriteOffers = prefs.getString('favoriteOffers');
    if(prefs.getString('storeId') == null || prefs.getString('storeId')!.isEmpty) {
      prefs.setString('storeId', 'DE3283');
    }
    // Get current offers from the selected store
    List<Product> cachedOffers = await getCachedOffers();
    if (favoriteOffers != null && favoriteOffers.isNotEmpty && cachedOffers.isNotEmpty) {
      List<dynamic> jsonList = jsonDecode(favoriteOffers);
      List<FavouriteProduct> favoriteProducts = jsonList.map((json) {
        // Check if the favorite offer is still available in current offers
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
          stillAvailable: isAvailable ? "true" : "false", // Mark availability status
        );
      }).toList();
      return favoriteProducts;
    }
    return [];
  }

  /// Retrieves cached offers for the currently selected store
  Future<List<Product>> getCachedOffers() async {
    String? cachedData = prefs.getString('offersFinal${prefs.getString('storeId') ?? prefs.getString('defaultStoreId')}');
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

/// Creates a card widget for displaying a favorite product offer
/// Shows product image, title, price, discount, and availability status
Widget offerCard(FavouriteProduct product, BuildContext context) {
  return GestureDetector(
    onTap: () {
      // Navigate to offer detail screen when tapped
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
                  // Product image with hero animation for smooth transitions
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
                  // Discount badge (only shown if discount > 0)
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
              // Product title and price
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
        // Availability badge (green for available, red for unavailable)
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

/// Model class for a favorite product
/// Extends the basic Product class with additional availability information
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
  final String stillAvailable; // Indicates if the offer is still active

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

  /// Create a FavouriteProduct from JSON data
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

  /// Convert FavouriteProduct to JSON for storage
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

  /// Convert FavouriteProduct to standard Product for detail view
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

/// Filter type enumeration for offer categories
enum FilterType {
  all,
  fruitAndVegetables,
  meatAndPoultry,
  fish,
  dairyProducts,
  frozenFood,
  cannedGoods,
  stapleFoods,
  coffeeTeaSweetsSnacks,
  beverages,
  bakery,
  organic
}