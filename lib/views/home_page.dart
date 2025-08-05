import 'package:flutter/material.dart';
import '../views/produit_home_page.dart';
import '../views/produit_list_page.dart';
import '../views/category_management_page.dart';
import '../views/order_page.dart'; // NOUVEAU : Importez la page de commandes

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          ProduitHomePage(), // Page 1: Gérer les produits
          ProduitListPage(), // Page 2: Lister et rechercher les produits
          CategoryManagementPage(), // Page 3: Gérer les catégories et sous-catégories
          OrderPage(), // NOUVEAU : Page 4: Passer une commande
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Permet plus de 3 onglets
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Produits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Catégories',
          ),
          BottomNavigationBarItem(
            // NOUVEAU : Onglet pour la page de commandes
            icon: Icon(Icons.shopping_cart),
            label: 'Commandes',
          ),
        ],
      ),
    );
  }
}
