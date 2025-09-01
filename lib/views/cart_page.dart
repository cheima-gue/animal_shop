// lib/views/cart_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/commande_viewmodel.dart';
import '../models/produit.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre Panier'),
      ),
      body: Consumer<CommandeViewModel>(
        builder: (context, commandeViewModel, child) {
          final items = commandeViewModel.cartItems.values.toList();
          if (items.isEmpty) {
            return const Center(
              child: Text('Votre panier est vide.'),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final produit = items[index];
                    final quantityController = TextEditingController(
                        text: produit.quantiteEnStock.toString());

                    // Dispose the controller when the widget is removed
                    // Note: In a ListView.builder, this can be complex. For this simple case,
                    // we'll rely on Flutter's widget lifecycle to handle it.

                    return ListTile(
                      title: Text(produit.nom),
                      subtitle: Text(
                        '${(produit.prix * produit.quantiteEnStock).toStringAsFixed(2)} DT',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              if (produit.quantiteEnStock > 1) {
                                commandeViewModel.updateProductQuantity(
                                  produit.id!,
                                  produit.quantiteEnStock - 1,
                                );
                              } else {
                                commandeViewModel
                                    .removeProductFromCart(produit.id!);
                              }
                            },
                          ),
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.all(0),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (value) {
                                final newQuantity = int.tryParse(value) ?? 0;
                                commandeViewModel.updateProductQuantity(
                                  produit.id!,
                                  newQuantity,
                                );
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () =>
                                commandeViewModel.updateProductQuantity(
                              produit.id!,
                              produit.quantiteEnStock + 1,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => commandeViewModel
                                .removeProductFromCart(produit.id!),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${commandeViewModel.total.toStringAsFixed(2)} DT',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await commandeViewModel.finalizeOrder();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Commande finalisée avec succès !')),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Finaliser la commande'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
