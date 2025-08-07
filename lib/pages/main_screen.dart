import 'package:flutter/material.dart';
import 'package:kaufi_allert_v2/pages/favorite_offers.dart';
import 'package:kaufi_allert_v2/pages/offers_page.dart';
import 'package:kaufi_allert_v2/pages/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    OffersPage(),
    FavoriteOffers(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    if(mounted){
    setState(() {
      _currentIndex = index;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.percent), label: 'Offers'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
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