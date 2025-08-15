// lib/viewmodels/produit_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/produit.dart';
import '../services/database_helper.dart';
import '../models/client.dart';

class ProduitViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Produit> _produits = [];
  Map<int, Produit> _cartItems = {};
  Client? _selectedClient;

  List<Produit> get produits => _produits;
  Map<int, Produit> get cartItems => _cartItems;
  Client? get selectedClient => _selectedClient;

  ProduitViewModel() {
    fetchProduits();
  }

  // Méthodes pour la gestion des produits
  Future<void> fetchProduits() async {
    _produits = await _dbHelper.getProduits();
    notifyListeners();
  }

  Future<void> addProduit(Produit produit) async {
    await _dbHelper.insertProduit(produit);
    await fetchProduits();
  }

  Future<void> updateProduit(Produit produit) async {
    await _dbHelper.updateProduit(produit);
    await fetchProduits();
  }

  Future<void> deleteProduit(int id) async {
    await _dbHelper.deleteProduit(id);
    await fetchProduits();
  }

  // Méthodes pour la gestion du panier (caisse)
  Future<bool> addProductByBarcode(String codeBarre) async {
    Produit? produit = await _dbHelper.getProduitByCodeBarre(codeBarre);
    if (produit != null && produit.id != null) {
      if (_cartItems.containsKey(produit.id)) {
        int currentQuantity = _cartItems[produit.id]!.quantiteEnStock;
        if (currentQuantity < produit.quantiteEnStock) {
          _cartItems[produit.id!] =
              produit.copyWith(quantiteEnStock: currentQuantity + 1);
          notifyListeners();
          return true;
        } else {
          return false;
        }
      } else {
        if (produit.quantiteEnStock > 0) {
          _cartItems[produit.id!] = produit.copyWith(quantiteEnStock: 1);
          notifyListeners();
          return true;
        } else {
          return false;
        }
      }
    }
    return false;
  }

  void updateProductQuantity(int produitId, int newQuantity) {
    if (_cartItems.containsKey(produitId)) {
      final produitOriginal = _produits.firstWhere((p) => p.id == produitId);
      if (newQuantity > 0) {
        if (newQuantity <= produitOriginal.quantiteEnStock) {
          _cartItems[produitId] =
              produitOriginal.copyWith(quantiteEnStock: newQuantity);
        } else {
          _cartItems[produitId] = produitOriginal.copyWith(
              quantiteEnStock: produitOriginal.quantiteEnStock);
        }
      } else {
        _cartItems.remove(produitId);
      }
      notifyListeners();
    }
  }

  void removeProductFromCart(int produitId) {
    _cartItems.remove(produitId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _selectedClient = null;
    notifyListeners();
  }

  // Méthodes pour la gestion des clients dans la caisse
  void selectClient(Client client) {
    _selectedClient = client;
    notifyListeners();
  }

  void resetClient() {
    _selectedClient = null;
    notifyListeners();
  }

  // Calculs pour la caisse
  double get subtotal {
    return _cartItems.values
        .fold(0.0, (sum, item) => sum + (item.prix * item.quantiteEnStock));
  }

  double get totalPrice {
    return subtotal;
  }

  double get loyaltyPointsEarned {
    if (_selectedClient == null) {
      return 0.0;
    }
    return subtotal * 0.1;
  }

  Future<void> _updateStock() async {
    for (var produitInCart in _cartItems.values) {
      if (produitInCart.id != null) {
        // Find the original product from the list
        final index = _produits.indexWhere((p) => p.id == produitInCart.id);
        if (index != -1) {
          final produitOriginal = _produits[index];
          // Calculate new stock and create a new object with copyWith
          final newStock =
              produitOriginal.quantiteEnStock - produitInCart.quantiteEnStock;
          final updatedProduit =
              produitOriginal.copyWith(quantiteEnStock: newStock);

          // Update the database
          await _dbHelper.updateProduit(updatedProduit);

          // Update the local list in the view model
          _produits[index] = updatedProduit;
        }
      }
    }
    notifyListeners();
  }

  Future<void> finalizeOrder() async {
    if (_selectedClient != null) {
      final pointsGagnes = loyaltyPointsEarned;
      _selectedClient!.loyaltyPoints += pointsGagnes;
      await _dbHelper.updateClient(_selectedClient!);
    }
    await _updateStock();
    clearCart();
    notifyListeners();
  }
}
