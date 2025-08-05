import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../viewmodels/produit_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showOrderConfirmationDialog(CartViewModel cartViewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation de la commande'),
          content: Text(
            'Êtes-vous sûr de vouloir passer cette commande pour un total de ${cartViewModel.totalPrice.toStringAsFixed(2)} DT ?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirmer'),
              onPressed: () {
                // TODO: Logique pour enregistrer la commande
                cartViewModel.clearCart();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Commande passée avec succès !')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final produitViewModel = Provider.of<ProduitViewModel>(context);
    final cartViewModel = Provider.of<CartViewModel>(context);

    // Filtrer les produits en fonction de la recherche
    final filteredProduits = produitViewModel.produits.where((produit) {
      return produit.nom.toLowerCase().contains(_searchText.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passage de Commandes'),
      ),
      body: Row(
        children: [
          // Section gauche : Recherche et liste des produits
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Rechercher un produit...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredProduits.length,
                      itemBuilder: (context, index) {
                        final produit = filteredProduits[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(produit.nom),
                            subtitle:
                                Text('${produit.prix.toStringAsFixed(2)} DT'),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_shopping_cart,
                                  color: Colors.teal),
                              onPressed: () {
                                cartViewModel.addItem(produit);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Section droite : Panier
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Panier',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartViewModel.items.length,
                      itemBuilder: (context, index) {
                        final orderItem =
                            cartViewModel.items.values.toList()[index];
                        return ListTile(
                          title: Text(orderItem.produit.nom),
                          subtitle: Text(
                              'Quantité: ${orderItem.quantity} x ${orderItem.price.toStringAsFixed(2)} DT'),
                          trailing: Text(
                              '${(orderItem.quantity * orderItem.price).toStringAsFixed(2)} DT'),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${cartViewModel.totalPrice.toStringAsFixed(2)} DT',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: cartViewModel.items.isEmpty
                              ? null
                              : () =>
                                  _showOrderConfirmationDialog(cartViewModel),
                          child: const Text('Passer la Commande'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: cartViewModel.items.isEmpty
                              ? null
                              : () => cartViewModel.clearCart(),
                          child: const Text('Vider le Panier'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
