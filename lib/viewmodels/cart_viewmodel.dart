// lib/viewmodels/cart_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/order_item.dart';
import '../models/produit.dart';

class CartViewModel extends ChangeNotifier {
  final Map<int, OrderItem> _items = {};

  List<OrderItem> get items => _items.values.toList();

  double get totalPrice {
    return _items.values.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  void addItem(Produit produit) {
    if (produit.id == null) return;

    if (_items.containsKey(produit.id)) {
      _items.update(
        produit.id!,
        (item) => OrderItem(
          productId: item.productId,
          quantity: item.quantity + 1,
          price: item.price,
          subtotal: item.price * (item.quantity + 1),
        ),
      );
    } else {
      _items.putIfAbsent(
        produit.id!,
        () => OrderItem(
          productId: produit.id!,
          quantity: 1,
          price: produit.prix,
          subtotal: produit.prix * 1,
        ),
      );
    }
    notifyListeners();
  }

  void addItemWithQuantity(Produit produit, int quantity) {
    if (produit.id == null || quantity <= 0) return;

    if (_items.containsKey(produit.id)) {
      final currentItem = _items[produit.id]!;
      _items.update(
        produit.id!,
        (item) => OrderItem(
          productId: item.productId,
          quantity: currentItem.quantity + quantity,
          price: item.price,
          subtotal: item.price * (currentItem.quantity + quantity),
        ),
      );
    } else {
      _items.putIfAbsent(
        produit.id!,
        () => OrderItem(
          productId: produit.id!,
          quantity: quantity,
          price: produit.prix,
          subtotal: produit.prix * quantity,
        ),
      );
    }
    notifyListeners();
  }

  void updateItemQuantity(int productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity > 0) {
        final item = _items[productId]!;
        _items.update(
          productId,
          (oldItem) => OrderItem(
            productId: item.productId,
            quantity: quantity,
            price: item.price,
            subtotal: item.price * quantity,
          ),
        );
      } else {
        _items.remove(productId);
      }
      notifyListeners();
    }
  }

  void increaseQuantity(int productId) {
    if (_items.containsKey(productId)) {
      final item = _items[productId]!;
      _items.update(
        productId,
        (oldItem) => OrderItem(
          productId: item.productId,
          quantity: item.quantity + 1,
          price: item.price,
          subtotal: item.price * (item.quantity + 1),
        ),
      );
      notifyListeners();
    }
  }

  void decreaseQuantity(int productId) {
    if (_items.containsKey(productId)) {
      final item = _items[productId]!;
      if (item.quantity > 1) {
        _items.update(
          productId,
          (oldItem) => OrderItem(
            productId: item.productId,
            quantity: item.quantity - 1,
            price: item.price,
            subtotal: item.price * (item.quantity - 1),
          ),
        );
      } else {
        _items.remove(productId);
      }
      notifyListeners();
    }
  }

  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
