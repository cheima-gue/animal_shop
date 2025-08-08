// lib/viewmodels/cart_viewmodel.dart :

import 'package:flutter/material.dart';
import '../models/order_item.dart'; //article dans le panier
import '../models/produit.dart';

class CartViewModel extends ChangeNotifier {
  //observateur : quand le panier change on appelle notifylisteners
  final Map<int, OrderItem> _items = {};

  List<OrderItem> get items => _items.values.toList();

  double get totalPrice {
    return _items.values
        .fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  void addItem(Produit produit) {
    if (_items.containsKey(produit.id)) {
      _items.update(
          produit.id!,
          (item) => OrderItem(
              produit: item.produit,
              quantity: item.quantity + 1,
              price: item.price));
    } else {
      _items.putIfAbsent(produit.id!,
          () => OrderItem(produit: produit, quantity: 1, price: produit.prix));
    }
    notifyListeners();
  }

  // NOUVELLE MÉTHODE : Permet d'ajouter une quantité spécifique
  void addItemWithQuantity(Produit produit, int quantity) {
    if (_items.containsKey(produit.id)) {
      _items.update(
          produit.id!,
          (item) => OrderItem(
              produit: item.produit,
              quantity: item.quantity + quantity,
              price: item.price));
    } else {
      _items.putIfAbsent(
          produit.id!,
          () => OrderItem(
              produit: produit, quantity: quantity, price: produit.prix));
    }
    notifyListeners();
  }

  void updateItemQuantity(int produitId, int quantity) {
    if (_items.containsKey(produitId)) {
      if (quantity > 0) {
        _items.update(
            produitId,
            (item) => OrderItem(
                produit: item.produit, quantity: quantity, price: item.price));
      } else {
        _items.remove(produitId);
      }
      notifyListeners();
    }
  }

  void increaseQuantity(int produitId) {
    if (_items.containsKey(produitId)) {
      _items.update(
          produitId,
          (item) => OrderItem(
              produit: item.produit,
              quantity: item.quantity + 1,
              price: item.price));
      notifyListeners();
    }
  }

  void decreaseQuantity(int produitId) {
    if (_items.containsKey(produitId)) {
      if (_items[produitId]!.quantity > 1) {
        _items.update(
            produitId,
            (item) => OrderItem(
                produit: item.produit,
                quantity: item.quantity - 1,
                price: item.price));
      } else {
        _items.remove(produitId);
      }
      notifyListeners();
    }
  }

  void removeItem(int produitId) {
    _items.remove(produitId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
