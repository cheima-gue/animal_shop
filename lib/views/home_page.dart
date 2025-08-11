// lib/views/home_page.dart

import 'package:flutter/material.dart';
import 'package:my_desktop_app/models/sub_category.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../viewmodels/category_viewmodel.dart';
import '../viewmodels/produit_viewmodel.dart';
import '../widgets/produit_card.dart';
import 'order_page.dart';
import 'produit_home_page.dart';
import 'category_management_page.dart';
import 'produit_list_page.dart';
import 'caisse_page.dart'; // Importez la nouvelle page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // L'erreur vient du fait que _HomePageContent est une classe de widget, pas une méthode de _HomePageState
  final List<Widget> _pages = [
    _HomePageContent(), // Appelez la classe du widget ici
    const ProduitHomePage(),
    const CategoryManagementPage(),
    const CaissePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryViewModel>(context, listen: false).fetchCategories();
      Provider.of<CategoryViewModel>(context, listen: false)
          .fetchSubCategories();
      Provider.of<ProduitViewModel>(context, listen: false).fetchProduits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Produits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Catégories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Caisse',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Le reste de la classe _HomePageContent doit être une classe de widget distincte, définie APART.
class _HomePageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopBar(context),
          _buildHeader(context),
          _buildCategoriesSection(context),
          _buildPromotionsSection(context),
          _buildFeaturedProductsSection(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.phone, color: Colors.grey, size: 16),
              SizedBox(width: 8),
              Text('+216 51 511 511',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(width: 24),
              Icon(Icons.email, color: Colors.grey, size: 16),
              SizedBox(width: 8),
              Text('contact@mypets.tn',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Row(
            children: [
              const Text('Bienvenue, ',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              TextButton(
                onPressed: () {},
                child: const Text('Connexion',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
              ),
              const Text(' ou ',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              TextButton(
                onPressed: () {},
                child: const Text('Créez votre compte',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border:
            const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/pet_shop_icon.png', height: 60,
                  errorBuilder: (context, error, stackTrace) {
                return const Text('Logo not found',
                    style: TextStyle(color: Colors.red));
              }),
              const SizedBox(width: 16),
              const Text('Mypets.tn',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const OrderPage()));
            },
            icon: const Icon(Icons.shopping_cart, color: Colors.teal),
            label: Consumer<ProduitViewModel>(
              builder: (context, produitViewModel, child) {
                final totalItems = produitViewModel.cartItems.length;
                return Text(
                  'Panier: $totalItems Produits',
                  style: const TextStyle(color: Colors.black),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Consumer<CategoryViewModel>(
        builder: (context, categoryViewModel, child) {
          final parentCategories = categoryViewModel.categories;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: parentCategories.map((category) {
              final subCategories = categoryViewModel.subCategories
                  .where((subCat) => subCat.categoryId == category.id)
                  .toList();
              return PopupMenuButton<SubCategory>(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    category.nom,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                itemBuilder: (BuildContext context) {
                  return subCategories.map((subCat) {
                    return PopupMenuItem<SubCategory>(
                      value: subCat,
                      child: Text(subCat.nom),
                    );
                  }).toList();
                },
                onSelected: (SubCategory subCat) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ProduitListPage(subCategory: subCat),
                  ));
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildPromotionsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.purple[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('VOTRE ANIMALERIE EN LIGNE',
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    const SizedBox(height: 16),
                    const Text('Livraison Gratuite Grand Tunis',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.black)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Achetez maintenant'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildFeaturedProductsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CATÉGORIES VEDETTES',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 16),
          Consumer<ProduitViewModel>(
            builder: (context, produitViewModel, child) {
              final featuredProduits =
                  produitViewModel.produits.take(4).toList();
              return SizedBox(
                height: 400,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: featuredProduits.length,
                  itemBuilder: (context, index) {
                    final produit = featuredProduits[index];
                    return ProduitCard(
                      produit: produit,
                      onEdit: null,
                      onDelete: null,
                      onAddToCart: (p) {
                        produitViewModel.addToCart(p);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('${p.nom} a été ajouté au panier')),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
