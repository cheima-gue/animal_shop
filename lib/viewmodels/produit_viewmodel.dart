// lib/viewmodels/produit_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/produit.dart';
import '../models/client.dart';
import '../services/database_helper.dart';

class ProduitViewModel extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Produit> _produits = [];
  Map<String, Produit> _cartItems = {};
  Client? _selectedClient;

  List<Produit> get produits => _produits;
  Map<String, Produit> get cartItems => _cartItems;
  Client? get selectedClient => _selectedClient;

  double get subtotal => _cartItems.values
      .fold(0.0, (sum, item) => sum + (item.prix * item.quantite));

  // Remplacer la réduction par le système de points de fidélité
  double get loyaltyPointsEarned {
    if (_selectedClient != null) {
      // 50 millimes par dinar, soit 0.05 dinar par dinar
      return subtotal * 0.05;
    }
    return 0.0;
  }

  // Le prix total est maintenant le sous-total, sans réduction
  double get totalPrice => subtotal;

  Future<void> fetchProduits() async {
    _produits = await _databaseHelper.getProduits();
    notifyListeners();
  }

  Future<void> deleteProduit(int id) async {
    await _databaseHelper.deleteProduit(id);
    await fetchProduits();
  }

  Future<void> addProduit(Produit produit) async {
    await _databaseHelper.insertProduit(produit);
    await fetchProduits();
  }

  Future<void> updateProduit(Produit produit) async {
    await _databaseHelper.updateProduit(produit);
    await fetchProduits();
  }

  void addToCart(Produit produit) {
    if (_cartItems.containsKey(produit.codeBarre)) {
      _cartItems[produit.codeBarre]!.quantite++;
    } else {
      produit.quantite = 1;
      _cartItems[produit.codeBarre!] = produit;
    }
    notifyListeners();
  }

  Future<bool> addProductByBarcode(String barcode) async {
    final produit = await _databaseHelper.getProduitByCodeBarre(barcode);
    if (produit != null) {
      if (_cartItems.containsKey(produit.codeBarre)) {
        _cartItems[produit.codeBarre]!.quantite++;
      } else {
        produit.quantite = 1;
        _cartItems[produit.codeBarre!] = produit;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeProductFromCart(String codeBarre) {
    if (_cartItems.containsKey(codeBarre)) {
      _cartItems.remove(codeBarre);
      notifyListeners();
    }
  }

  void updateProductQuantity(String codeBarre, int quantity) {
    if (_cartItems.containsKey(codeBarre)) {
      if (quantity > 0) {
        _cartItems[codeBarre]!.quantite = quantity;
      } else {
        _cartItems.remove(codeBarre);
      }
      notifyListeners();
    }
  }

  Future<void> selectClientByTel(String tel) async {
    _selectedClient = await _databaseHelper.getClientByTel(tel);
    notifyListeners();
  }

  void resetClient() {
    _selectedClient = null;
    notifyListeners();
  }

  // Nouvelle méthode pour finaliser la commande et mettre à jour les points de fidélité
  Future<void> finalizeOrder() async {
    if (_selectedClient != null) {
      final pointsEarned = loyaltyPointsEarned;
      _selectedClient!.loyaltyPoints += pointsEarned;
      await _databaseHelper.updateClientLoyaltyPoints(_selectedClient!);
    }
    _cartItems.clear();
    resetClient();
    notifyListeners();
  }
}
