import 'package:flutter/material.dart';
import 'package:kaufi_alert/pages/favorite_offers.dart';
import 'package:kaufi_alert/pages/offers_page.dart';
import 'package:kaufi_alert/pages/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Keys let us refresh the data-bound tabs when they regain focus, without
  // tearing down their state (which would re-run expensive initState work).
  final GlobalKey<OffersPageState> _offersKey = GlobalKey();
  final GlobalKey<FavoriteOffersState> _favoritesKey = GlobalKey();

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
    // The selected store can change on other tabs, so refresh on focus.
    if (index == 0) _offersKey.currentState?.reload();
    if (index == 1) _favoritesKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps each tab alive so switching doesn't re-fetch
      // offers or re-acquire GPS from scratch every time.
      body: IndexedStack(
        index: _currentIndex,
        children: [
          OffersPage(key: _offersKey),
          FavoriteOffers(key: _favoritesKey),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.percent), label: 'Offers'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white,
        backgroundColor: const Color(0xFF1f1415),
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
