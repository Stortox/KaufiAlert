import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kaufi_allert_v2/pages/offer_detail.dart';
import 'package:kaufi_allert_v2/pages/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bakery
}

enum SortOrder {
  none,
  ascending,
  descending,
}

class OffersPage extends StatefulWidget {

  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {

  FilterType currentFilter = FilterType.all;
  SortOrder currentSortOrder = SortOrder.none;
  List<Product> filteredProducts = [];
  List<Product> products = [];
  late SharedPreferences prefs;
  initializeSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  final Map<FilterType, List<Product>> _filteredProductsCache = {};

  @override
  void initState() {
    super.initState();
    fetchManager().then((value) {
      setState(() {
        products = value;
        filteredProducts = products;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1f1415),
      appBar: AppBar(
        title: const Text("Offers", style: TextStyle(color: Colors.white, fontSize: 24)),
        backgroundColor: const Color(0xFF1f1415),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.only(top: 10)),
            SearchAnchor(
              viewBackgroundColor: const Color(0xFF412a2b),
              headerTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
              viewLeading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () {
                Navigator.pop(context);
                FocusScope.of(context).unfocus();
              }),
                builder: (context, controller) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: SearchBar(
                    controller: controller,
                    padding: const WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    hintText: 'Search',
                    backgroundColor: WidgetStateProperty.all(const Color(0xFF412a2b)),
                    textStyle: WidgetStateProperty.all(const TextStyle(color: Colors.white)),
                    onTap: () {
                      controller.openView();
                    },
                    onChanged: (_) {
                      controller.openView();
                    },
                    onTapOutside: (_) {
                      FocusScope.of(context).unfocus();
                    },
                    leading: Icon(Icons.search, color: Colors.white),
                  ),
                );
                },
              suggestionsBuilder: (context, controller) {
                List<ListTile> listTiles = [];
                final filteredProducts = products.where((product) {
                  if (controller.text.isEmpty) {
                    return false;
                  }
                  return product.title.toLowerCase().contains(controller.text.toLowerCase());
                }).toList();
                for(var product in filteredProducts) {
                  listTiles.add(ListTile(
                    title: Text(
                      product.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => OfferDetail(product: product)));
                    },
                  ));
                }
                return listTiles;
              },
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                ],
              ),
            ),
            if(products.isEmpty)
            FutureBuilder<List<Product>>(
              future: fetchManager(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  if(snapshot.data == null || snapshot.data!.isEmpty) {
                    return const Text('No offers found');
                  } else {
                    for (var product in snapshot.data!) {
                      if(products.any((p) => p.title == product.title)) {
                        continue; // Skip if product already exists
                      }
                      products.add(product);
                    }
                    return SizedBox(
                      width: MediaQuery.of(context).size.width - 10,
                      height: MediaQuery.of(context).size.height - 284,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                        Product product = products[index];
                        return offerCard(product, context);
                        },
                      ),
                    );
                  }
                }
              },
            ) else 
            SizedBox(
              width: MediaQuery.of(context).size.width - 10,
              height: MediaQuery.of(context).size.height - 284,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  Product product = filteredProducts[index];
                  return offerCard(product, context);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<List<Product>> fetchManager() async {
    await initializeSharedPreferences();
    //prefs.setString('stores', "");
    if(prefs.getString('stores') == null || prefs.getString('stores')!.isEmpty) {
      fetchStores();
    }
    //prefs.setString('favoriteOffers', "[]");
    if(prefs.getString('storeId') == null || prefs.getString('storeId')!.isEmpty) {
      prefs.setString('storeId', 'DE3940');
    }
    List<Product> cachedOffers = await getCachedOffers();
    if (cachedOffers.isNotEmpty && prefs.getString('offersDate${prefs.getString('storeId') ?? 'DE3940'}') != null && DateTime.now().difference(DateTime.parse(prefs.getString('offersDate${prefs.getString('storeId') ?? 'DE3940'}')!)).inDays < 7) {
      products = cachedOffers;
      filteredProducts = products;
      return cachedOffers;
    } else {
      return fetchData();
    }
  }

  void _applyFilter(FilterType filter) {
    setState(() {
      currentFilter = filter;
      
      // Use cached results if available
      if (_filteredProductsCache.containsKey(filter)) {
        filteredProducts = _filteredProductsCache[filter]!;
        return;
      }
      
      // Calculate and cache results
      filteredProducts = products.where((product) {
        return filter == FilterType.all || 
                filter.toString().split('.').last == product.category;
      }).toList();

      _filteredProductsCache[filter] = filteredProducts;
    });
  }

  Widget _buildFilterChip(String label, FilterType filterType) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: (currentFilter == filterType ? Colors.black : Colors.white),
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

  Future<List<Product>> fetchData() async {
    //print("Fetching offers from API");
    var selectedOffers = ["02_Obst__Gemuese__Pflanzen", "01_Fleisch__Gefluegel__Wurst", "01a_Frischer_Fisch", "03_Molkereiprodukte__Fette", "04_Tiefkuehlkost", "05_Feinkost__Konserven", "06_Grundnahrungsmittel", "07_Kaffee__Tee__Suesswaren__Knabberartikel", "08_Getraenke__Spirituosen", "708_Backshop"];
    List<Product> offersFinal = <Product>[];
    var url = Uri.https('app.kaufland.net', '/data/api/v5/offers/${prefs.getString('storeId') ?? 'DE3940'}');
    var response = await http.get(url, headers: {"Authorization": "Basic S0lTLUtMQVBQOkRyZWNrc3pldWdfMzUyOS1BY2h0c3BubmVy"});
    List<dynamic> jsonObject = jsonDecode(response.body);
    prefs.setString('offersDate${prefs.getString('storeId') ?? 'DE3940'}', DateTime.parse(jsonObject[0]['categories'][0]['dateFrom']).toIso8601String());
    var categories = jsonObject[0]['categories'];
    for (int i = 0; i < categories.length; i++) {
      String title = categories[i]['name'];
      for (String selectedOffersTitle in selectedOffers) {
        if (title == selectedOffersTitle) {
          List<dynamic> offers = categories[i]['offers'];
          for (var offer in offers) {
            String detailTitle = "";
            String currentPrice = "";
            String basePrice = "";
            String oldPrice = "";
            String imageUrl = "";
            String description = "";
            String category = "";
            String unit = "";
            //print("Processing offer: $offer");
            if ((offer['discount'] > 0 || selectedOffersTitle == "02_Obst__Gemuese__Pflanzen") && offer['discount'] != null) {
              String discount = "${offer['discount']}%";
              detailTitle = offer['title'] ?? '';
              detailTitle = "$detailTitle ${offer['subtitle'] ?? ''}";
              detailTitle = detailTitle.replaceAll("/", " ").trim();
              currentPrice = "${offer['formattedPrice'] ?? '0.00'}€";
              basePrice = offer['basePrice'] ?? '';
              oldPrice = "${offer['oldPrice'] ?? '0.00'}€";
              imageUrl = offer['listImage'] ?? 'https://picsum.photos/250?image=9';
              description = offer['detailDescription'] ?? '';
              unit = offer['unit'] ?? '';
              switch (selectedOffersTitle) {
                case "02_Obst__Gemuese__Pflanzen":
                  category = "fruitAndVegetables";
                  break;
                case "01_Fleisch__Gefluegel__Wurst":
                  category = "meatAndPoultry";
                  break;
                case "01a_Frischer_Fisch":
                  category = "fish";
                  break;
                case "03_Molkereiprodukte__Fette":
                  category = "dairyProducts";
                  break;
                case "04_Tiefkuehlkost":
                  category = "frozenFood";
                  break;
                case "05_Feinkost__Konserven":
                  category = "cannedGoods";
                  break;
                case "06_Grundnahrungsmittel":
                  category = "stapleFoods";
                  break;
                case "07_Kaffee__Tee__Suesswaren__Knabberartikel":
                  category = "coffeeTeaSweetsSnacks";
                  break;
                case "08_Getraenke__Spirituosen":
                  category = "beverages";
                  break;
                case "708_Backshop":
                  category = "bakery";
                  break;
              }
              if(!offersFinal.contains(Product(title: detailTitle, price: currentPrice, discount: discount, basePrice: basePrice, oldPrice: oldPrice, imageUrl: imageUrl, description: description, category: category, unit: unit))) {
                offersFinal.add(Product(title: detailTitle, price: currentPrice, discount: discount, basePrice: basePrice, oldPrice: oldPrice, imageUrl: imageUrl, description: description, category: category, unit: unit));
              }
            }
          }
        }
      }
    }

    prefs.setString('offersFinal${prefs.getString('storeId') ?? 'DE3940'}', json.encode(offersFinal.map((product) => product.toJson()).toList()));
    return offersFinal;
  }

  void fetchStores() async {
    var url = Uri.https('app.kaufland.net', '/data/api/v2/stores');
    var response = await http.get(url, headers: {"Authorization": "Basic S0lTLUtMQVBQOkRyZWNrc3pldWdfMzUyOS1BY2h0c3BubmVy"});
    
    List<dynamic> storeList = json.decode(response.body);
    List<Store> stores = [];
    
    for (var storeData in storeList) {
      String address = "${storeData['street']}, ${storeData['city']}";
      
      String openingHoursStr = "";
      if (storeData['openingHours'] != null) {
        List<dynamic> hours = storeData['openingHours'];
        for (var hour in hours) {
          String weekday = hour['weekday'];
          int open = hour['open'];
          int close = hour['close'];

          String openTime = "${open ~/ 100}:${open % 100 == 0 ? '00' : open % 100}";
          String closeTime = "${close ~/ 100}:${close % 100 == 0 ? '00' : close % 100}";
          
          openingHoursStr += "$weekday: $openTime-$closeTime, ";
        }

        if (openingHoursStr.isNotEmpty) {
          openingHoursStr = openingHoursStr.substring(0, openingHoursStr.length - 2);
        }
      }
      
      stores.add(Store(
        storeId: storeData['storeId'],
        name: storeData['name'],
        address: address,
        openingHours: openingHoursStr,
        position: [storeData['latitude'], storeData['longitude']],
        country: storeData['country'],
      ));
    }
    
    prefs.setString('stores', json.encode(stores.map((store) => {
      'storeId': store.storeId,
      'name': store.name,
      'address': store.address,
      'openingHours': store.openingHours,
      'latitude': store.position[0],
      'longitude': store.position[1],
      'country': store.country,
    }).toList()));
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
        unit: json['unit']
      )).toList();
    }
    return [];
  }
}

Widget offerCard(Product product, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context, 
          '/offerDetail',
          arguments: product,
        );
      },
      child: SizedBox(
        width: (MediaQuery.of(context).size.width - 20) / 2,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Card(
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
      ),
    );
  }

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

  Product({
    required this.title,
    required this.price,
    required this.discount,
    required this.basePrice,
    required this.oldPrice,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.unit,
  });

  Product.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        price = json['price'],
        discount = json['discount'],
        basePrice = json['basePrice'],
        oldPrice = json['oldPrice'],
        imageUrl = json['imageUrl'],
        description = json['description'],
        category = json['category'],
        unit = json['unit'];

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
    };
  }
}