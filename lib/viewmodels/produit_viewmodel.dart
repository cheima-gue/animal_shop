// lib/viewmodels/produit_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/produit.dart';
import '../services/database_helper.dart';

class ProduitViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Produit> _produits = [];
  List<Produit> get produits => _produits;

  Map<int, Produit> _cartItems = {};
  Map<int, Produit> get cartItems => _cartItems;

  ProduitViewModel() {
    fetchProduits();
  }

  Future<void> fetchProduits() async {
    _produits = await _dbHelper.getProduits();
    notifyListeners();
  }

  Future<void> addProduit(Produit produit) async {
    await _dbHelper.insertProduit(produit);
    await fetchProduits();
  }

  Future<void> updateProduit(Produit updatedProduit) async {
    await _dbHelper.updateProduit(updatedProduit);
    await fetchProduits();
  }

  Future<void> deleteProduit(int id) async {
    await _dbHelper.deleteProduit(id);
    await fetchProduits();
  }

  // --- Nouvelles méthodes pour la gestion du panier ---

  void addToCart(Produit produit) {
    if (_cartItems.containsKey(produit.id)) {
      final existingProduct = _cartItems[produit.id]!;
      _cartItems[produit.id!] =
          existingProduct.copyWith(quantite: existingProduct.quantite + 1);
    } else {
      _cartItems[produit.id!] = produit.copyWith(quantite: 1);
    }
    notifyListeners();
  }

  void removeFromCart(Produit produit) {
    if (_cartItems.containsKey(produit.id)) {
      final existingProduct = _cartItems[produit.id]!;
      if (existingProduct.quantite > 1) {
        _cartItems[produit.id!] =
            existingProduct.copyWith(quantite: existingProduct.quantite - 1);
      } else {
        _cartItems.remove(produit.id);
      }
    }
    notifyListeners();
  }

  void removeAllFromCart(Produit produit) {
    _cartItems.remove(produit.id);
    notifyListeners();
  }

  double get totalPrice {
    return _cartItems.values
        .fold(0, (total, current) => total + (current.prix * current.quantite));
  }

  Future<void> addProductByBarcode(String codeBarre) async {
    final produit = await _dbHelper.getProduitByCodeBarre(codeBarre);
    if (produit != null) {
      addToCart(produit);
    }
  }
}
