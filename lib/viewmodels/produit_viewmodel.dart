// lib/viewmodels/produit_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/produit.dart';
import '../services/database_helper.dart';

class ProduitViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Produit> _produits = [];
  List<Produit> get produits => _produits;

  // Utiliser le code-barres (String) comme clé au lieu de l'ID (int?)
  Map<String, Produit> _cartItems = {};
  Map<String, Produit> get cartItems => _cartItems;

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

  // --- Méthodes corrigées pour la gestion du panier ---

  void addToCart(Produit produit) {
    if (produit.codeBarre == null) return;

    if (_cartItems.containsKey(produit.codeBarre)) {
      final existingProduct = _cartItems[produit.codeBarre]!;
      _cartItems[produit.codeBarre!] =
          existingProduct.copyWith(quantite: existingProduct.quantite + 1);
    } else {
      _cartItems[produit.codeBarre!] = produit.copyWith(quantite: 1);
    }
    notifyListeners();
  }

  void removeFromCart(Produit produit) {
    if (produit.codeBarre == null) return;

    if (_cartItems.containsKey(produit.codeBarre)) {
      final existingProduct = _cartItems[produit.codeBarre]!;
      if (existingProduct.quantite > 1) {
        _cartItems[produit.codeBarre!] =
            existingProduct.copyWith(quantite: existingProduct.quantite - 1);
      } else {
        _cartItems.remove(produit.codeBarre);
      }
    }
    notifyListeners();
  }

  void removeAllFromCart(Produit produit) {
    if (produit.codeBarre == null) return;
    _cartItems.remove(produit.codeBarre);
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

  // Méthodes de mise à jour et de suppression de produit corrigées
  void updateProductQuantity(String codeBarre, int nouvelleQuantite) {
    if (cartItems.containsKey(codeBarre)) {
      final existingProduct = cartItems[codeBarre]!;
      existingProduct.quantite = nouvelleQuantite;
      cartItems[codeBarre] = existingProduct;
      notifyListeners();
    }
  }

  void removeProductFromCart(String codeBarre) {
    if (cartItems.containsKey(codeBarre)) {
      cartItems.remove(codeBarre);
      notifyListeners();
    }
  }
}
