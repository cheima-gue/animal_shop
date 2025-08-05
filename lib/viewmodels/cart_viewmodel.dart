// lib/viewmodels/cart_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/order_item.dart';
import '../models/produit.dart';

class CartViewModel extends ChangeNotifier {
  final Map<int, OrderItem> _items = {};

  Map<int, OrderItem> get items => _items;

  double get totalPrice {
    return _items.values
        .fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get itemCount {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  void addItem(Produit produit) {
    if (_items.containsKey(produit.id)) {
      _items.update(
          produit.id!,
          (item) => OrderItem(
                produit: item.produit,
                quantity: item.quantity + 1,
                price: item.price,
              ));
    } else {
      _items.putIfAbsent(
          produit.id!,
          () => OrderItem(
                produit: produit,
                quantity: 1,
                price: produit.prix,
              ));
    }
    notifyListeners();
  }

  void removeItem(int produitId) {
    if (_items.containsKey(produitId)) {
      if (_items[produitId]!.quantity > 1) {
        _items.update(
            produitId,
            (item) => OrderItem(
                  produit: item.produit,
                  quantity: item.quantity - 1,
                  price: item.price,
                ));
      } else {
        _items.remove(produitId);
      }
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
