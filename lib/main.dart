import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FutureBuilder<String>(
            future: fetchData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return Text(snapshot.data ?? 'No data');
              }
            },
          ),
        ),
      ),
    );
  }
}

Future<String> fetchData() async {
  var selectedOffers = ["02_Obst__Gemuese__Pflanzen", "01_Fleisch__Gefluegel__Wurst", "01a_Frischer_Fisch", "03_Molkereiprodukte__Fette", "04_Tiefkuehlkost", "05_Feinkost__Konserven", "06_Grundnahrungsmittel", "07_Kaffee__Tee__Suesswaren__Knabberartikel", "08_Getraenke__Spirituosen", "708_Backshop"];
  List<String> angebote = <String>[];
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
          //print("Processing offer: $offer");
          if (offer['discount'] > 0 && offer['discount'] != null) {
            String discount = "${offer['discount']}%";
            if (offer['title'] != null) {
              detailTitle = offer['title'];
            }
            if (offer['subtitle'] != null) {
              detailTitle = "$detailTitle ${offer['subtitle']}";
              detailTitle = detailTitle.replaceAll("/", " ");
            }
            if(offer['formattedPrice'] != null) {
              currentPrice = "${offer['formattedPrice']}€";
            }
            if(offer['basePrice'] != null) {
              basePrice = offer['basePrice'];
            }
            if(offer['oldPrice'] != null) {
              oldPrice = "${offer['oldPrice']}€";
            }
            angebote.add("Offer: Title: $detailTitle, Price: $currentPrice, Discount: $discount, Baseprice: $basePrice, Oldprice: $oldPrice");
          }
        }
      }
    }
  }
  return angebote.toString();
}