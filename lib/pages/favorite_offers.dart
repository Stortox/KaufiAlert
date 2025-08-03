import 'package:flutter/material.dart';
import 'package:kaufi_allert_v2/pages/offers_page.dart';

class FavoriteOffers extends StatelessWidget {
  const FavoriteOffers({super.key});

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
            Padding(padding: const EdgeInsets.only(top: 10)),
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
                itemCount: OffersPage.favoriteOffers.length,
                itemBuilder: (context, index) {
                  Product product = OffersPage.favoriteOffers[index];
                  return offerCard(product, context);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}