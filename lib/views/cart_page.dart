// lib/views/cart_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/cart_viewmodel.dart';
// ignore: unused_import
import '../models/order_item.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre Panier'),
      ),
      body: Consumer<CartViewModel>(
        builder: (context, cartViewModel, child) {
          if (cartViewModel.items.isEmpty) {
            return const Center(
              child: Text('Votre panier est vide.'),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartViewModel.items.length,
                  itemBuilder: (context, index) {
                    final item = cartViewModel.items[index];
                    final quantityController =
                        TextEditingController(text: item.quantity.toString());

                    // Écoutez les changements dans le TextField pour mettre à jour le ViewModel
                    quantityController.addListener(() {
                      final newQuantity =
                          int.tryParse(quantityController.text) ?? 0;
                      if (newQuantity != item.quantity) {
                        cartViewModel.updateItemQuantity(
                            item.produit.id!, newQuantity);
                      }
                    });

                    return ListTile(
                      title: Text(item.produit.nom),
                      subtitle: Text('${item.price.toStringAsFixed(2)} DT'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => cartViewModel
                                .decreaseQuantity(item.produit.id!),
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
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => cartViewModel
                                .increaseQuantity(item.produit.id!),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                cartViewModel.removeItem(item.produit.id!),
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
                      '${cartViewModel.totalPrice.toStringAsFixed(2)} DT',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    cartViewModel.clearCart();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Commande finalisée avec succès !')),
                    );
                    Navigator.of(context).pop();
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
