import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

void main() {
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {

  List<Product> products = [];
  late List<bool> selected;

  FilterType currentFilter = FilterType.all;
  SortOrder currentSortOrder = SortOrder.none;

  @override
  void initState() {
    super.initState();
    selected = List<bool>.generate(products.length, (index) => false);
  }

  @override
  void dispose() {
    products.clear();
    selected.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF1f1415),
        body: Center(
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.only(top: 20)),
              Text(
                'Offers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
              Padding(padding: const EdgeInsets.only(top: 20)),
              SearchAnchor(
                viewBackgroundColor: const Color(0xFF412a2b),
                headerTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
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
                        controller.closeView(null);
                        controller.clear();
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
                  FilterChip(
                    label: Text(
                    'All',
                    style: TextStyle(color: (currentFilter == FilterType.all ? Colors.black : Colors.white)),
                    ),
                    selected: currentFilter == FilterType.all,
                    onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                      currentFilter = FilterType.all;
                      });
                    }
                    },
                    backgroundColor: Color(0xFF412a2b),
                    selectedColor: Color.fromARGB(255, 120, 80, 80),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Colors.black, width: 0),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FilterChip(
                    label: Text(
                    'Fruits & Vegetables',
                      style: TextStyle(color: (currentFilter == FilterType.fruitAndVegetables ? Colors.black : Colors.white)),
                    ),
                    selected: currentFilter == FilterType.fruitAndVegetables,
                    onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                      currentFilter = FilterType.fruitAndVegetables;
                      });
                    }
                    },
                    backgroundColor: Color(0xFF412a2b),
                    selectedColor: Color.fromARGB(255, 120, 80, 80),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Colors.black, width: 0),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FilterChip(
                    label: Text(
                    'Meat & Poultry',
                    style: TextStyle(color: (currentFilter == FilterType.meatAndPoultry ? Colors.black : Colors.white)),
                    ),
                    selected: currentFilter == FilterType.meatAndPoultry,
                    onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                      currentFilter = FilterType.meatAndPoultry;
                      });
                    }
                    },
                    backgroundColor: Color(0xFF412a2b),
                    selectedColor: Color.fromARGB(255, 120, 80, 80),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Colors.black, width: 0),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FilterChip(
                    label: Text(
                    'Fish',
                    style: TextStyle(color: (currentFilter == FilterType.fish ? Colors.black : Colors.white)),
                    ),
                    selected: currentFilter == FilterType.fish,
                    onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                      currentFilter = FilterType.fish;
                      });
                    }
                    },
                    backgroundColor: Color(0xFF412a2b),
                    selectedColor: Color.fromARGB(255, 120, 80, 80),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Colors.black, width: 0),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FilterChip(
                    label: Text(
                    'Dairy Products',
                    style: TextStyle(color: (currentFilter == FilterType.dairyProducts ? Colors.black : Colors.white)),
                    ),
                    selected: currentFilter == FilterType.dairyProducts,
                    onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                      currentFilter = FilterType.dairyProducts;
                      });
                    }
                    },
                    backgroundColor: Color(0xFF412a2b),
                    selectedColor: Color.fromARGB(255, 120, 80, 80),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Colors.black, width: 0),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FilterChip(
                    label: Text(
                    'Frozen Food',
                    style: TextStyle(color: (currentFilter == FilterType.frozenFood ? Colors.black : Colors.white)),
                    ),
                    selected: currentFilter == FilterType.frozenFood,
                    onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                      currentFilter = FilterType.frozenFood;
                      });
                    }
                    },
                    backgroundColor: Color(0xFF412a2b),
                    selectedColor: Color.fromARGB(255, 120, 80, 80),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Colors.black, width: 0),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FilterChip(
                    label: Text(
                    'Canned Goods',
                    style: TextStyle(color: (currentFilter == FilterType.cannedGoods ? Colors.black : Colors.white)),
                    ),
                    selected: currentFilter == FilterType.cannedGoods,
                    onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                      currentFilter = FilterType.cannedGoods;
                      });
                    }
                    },
                    backgroundColor: Color(0xFF412a2b),
                    selectedColor: Color.fromARGB(255, 120, 80, 80),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Colors.black, width: 0),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FilterChip(
                    label: Text(
                    'Staple Foods',
                    style: TextStyle(color: (currentFilter == FilterType.stapleFoods ? Colors.black : Colors.white)),
                    ),
                    selected: currentFilter == FilterType.stapleFoods,
                    onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                      currentFilter = FilterType.stapleFoods;
                      });
                    }
                    },
                    backgroundColor: Color(0xFF412a2b),
                    selectedColor: Color.fromARGB(255, 120, 80, 80),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Colors.black, width: 0),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FilterChip(
                    label: Text(
                    'Coffee, Tea & Sweets',
                    style: TextStyle(color: (currentFilter == FilterType.coffeeTeaSweetsSnacks ? Colors.black : Colors.white)),
                    ),
                    selected: currentFilter == FilterType.coffeeTeaSweetsSnacks,
                    onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                      currentFilter = FilterType.coffeeTeaSweetsSnacks;
                      });
                    }
                    },
                    backgroundColor: Color(0xFF412a2b),
                    selectedColor: Color.fromARGB(255, 120, 80, 80),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Colors.black, width: 0),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FilterChip(
                    label: Text(
                    'Beverages',
                    style: TextStyle(color: (currentFilter == FilterType.beverages ? Colors.black : Colors.white)),
                    ),
                    selected: currentFilter == FilterType.beverages,
                    onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                      currentFilter = FilterType.beverages;
                      });
                    }
                    },
                    backgroundColor: Color(0xFF412a2b),
                    selectedColor: Color.fromARGB(255, 120, 80, 80),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Colors.black, width: 0),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FilterChip(
                    label: Text(
                      'Bakery',
                      style: TextStyle(color: (currentFilter == FilterType.bakery ? Colors.black : Colors.white)),
                    ),
                    selected: currentFilter == FilterType.bakery,
                    onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                      currentFilter = FilterType.bakery;
                      });
                    }
                    },
                    backgroundColor: Color(0xFF412a2b),
                    selectedColor: Color.fromARGB(255, 120, 80, 80),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Colors.black, width: 0),
                    ),
                  ),
                  ],
                ),
              ),
              FutureBuilder<List<Product>>(
                future: fetchData(),
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
                        height: MediaQuery.of(context).size.height - 210,
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 0.7,
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
              ),
            ],
          ),
        ),
      )
    );
  }
}

Future<List<Product>> fetchData() async {
  var selectedOffers = ["02_Obst__Gemuese__Pflanzen", "01_Fleisch__Gefluegel__Wurst", "01a_Frischer_Fisch", "03_Molkereiprodukte__Fette", "04_Tiefkuehlkost", "05_Feinkost__Konserven", "06_Grundnahrungsmittel", "07_Kaffee__Tee__Suesswaren__Knabberartikel", "08_Getraenke__Spirituosen", "708_Backshop"];
  List<Product> angebote = <Product>[];
  var url = Uri.https('app.kaufland.net', '/data/api/v5/offers/DE3940');
  var response = await http.get(url, headers: {"Authorization": "Basic S0lTLUtMQVBQOkRyZWNrc3pldWdfMzUyOS1BY2h0c3BubmVy"});
  List<dynamic> jsonObject = jsonDecode(response.body);
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
          //print("Processing offer: $offer");
          if (offer['discount'] > 0 && offer['discount'] != null) {
            String discount = "${offer['discount']}%";
            detailTitle = offer['title'] ?? '';
            detailTitle = "$detailTitle ${offer['subtitle'] ?? ''}";
            detailTitle = detailTitle.replaceAll("/", " ");
            currentPrice = "${offer['formattedPrice'] ?? '0.00'}€";
            basePrice = offer['basePrice'] ?? '';
            oldPrice = "${offer['oldPrice'] ?? '0.00'}€";
            imageUrl = offer['listImage'] ?? 'https://picsum.photos/250?image=9';
            if(!angebote.contains(Product(title: detailTitle, price: currentPrice, discount: discount, basePrice: basePrice, oldPrice: oldPrice, imageUrl: imageUrl))) {
              angebote.add(Product(title: detailTitle, price: currentPrice, discount: discount, basePrice: basePrice, oldPrice: oldPrice, imageUrl: imageUrl));
            }
          }
        }
      }
    }
  }
  return angebote;
}

class Product {
  final String title;
  final String price;
  final String discount;
  final String basePrice;
  final String oldPrice;
  final String imageUrl;

  Product({
    required this.title,
    required this.price,
    required this.discount,
    required this.basePrice,
    required this.oldPrice,
    required this.imageUrl,
  });
}

Widget offerCard(Product product, BuildContext context) {
  return SizedBox(
    width: (MediaQuery.of(context).size.width - 20) / 2,
    height: MediaQuery.of(context).size.height * 0.5,
    child: Card(
      color: const Color(0xFF1f1415),
      child: Column(
        children: [
          Stack(
            children: [
              Center(
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
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
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
  );
}