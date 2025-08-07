// lib/views/order_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../viewmodels/produit_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import 'cart_page.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showQuantityDialog(Produit produit) async {
    final quantityController = TextEditingController(text: '1');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter ${produit.nom} au panier'),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantité',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text) ?? 0;
              if (quantity > 0) {
                Navigator.of(context).pop(quantity);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      Provider.of<CartViewModel>(context, listen: false)
          .addItemWithQuantity(produit, result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$result x ${produit.nom} a été ajouté au panier.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passer une commande'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher un produit',
                hintText: 'Nom ou Code-barres',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ProduitViewModel>(
                builder: (context, produitViewModel, child) {
                  final query = _searchController.text.toLowerCase();
                  final filteredProduits =
                      produitViewModel.produits.where((produit) {
                    return produit.nom.toLowerCase().contains(query) ||
                        produit.codeBarre.toLowerCase().contains(query);
                  }).toList();

                  if (filteredProduits.isEmpty) {
                    return const Center(child: Text('Aucun produit trouvé.'));
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredProduits.length,
                    itemBuilder: (context, index) {
                      final produit = filteredProduits[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15)),
                                child: produit.image != null &&
                                        produit.image!.isNotEmpty
                                    ? Image.file(File(produit.image!),
                                        fit: BoxFit.cover)
                                    : const Icon(Icons.image,
                                        size: 50, color: Colors.grey),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(produit.nom,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text('${produit.prix.toStringAsFixed(2)} DT'),
                                  Text(produit.codeBarre,
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _showQuantityDialog(produit),
                                    child: const Text('Ajouter au panier'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
