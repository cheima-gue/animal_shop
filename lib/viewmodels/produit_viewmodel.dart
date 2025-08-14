// lib/viewmodels/produit_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/produit.dart';
import '../services/database_helper.dart';
import '../models/client.dart';

class ProduitViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Produit> _produits = [];
  Map<String, Produit> _cartItems = {};
  Client? _selectedClient;

  List<Produit> get produits => _produits;
  Map<String, Produit> get cartItems => _cartItems;
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
    if (produit != null) {
      // Utilisez la nouvelle méthode pour ajouter au panier
      addToCart(produit);
      return true;
    }
    return false;
  }

  void addToCart(Produit produit) {
    if (_cartItems.containsKey(produit.codeBarre)) {
      _cartItems[produit.codeBarre]!.quantite += 1;
    } else {
      // Crée une copie du produit pour l'ajouter au panier avec une quantité de 1
      _cartItems[produit.codeBarre!] = produit.copyWith(quantite: 1);
    }
    notifyListeners();
  }

  void updateProductQuantity(String codeBarre, int newQuantity) {
    if (_cartItems.containsKey(codeBarre)) {
      if (newQuantity > 0) {
        _cartItems[codeBarre]!.quantite = newQuantity;
      } else {
        _cartItems.remove(codeBarre);
      }
      notifyListeners();
    }
  }

  void removeProductFromCart(String codeBarre) {
    _cartItems.remove(codeBarre);
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
        .fold(0.0, (sum, item) => sum + (item.prix * item.quantite));
  }

  double get totalPrice {
    return subtotal;
  }

  double get loyaltyPointsEarned {
    if (_selectedClient == null) {
      return 0.0;
    }
    // Exemple : 10% du sous-total en points de fidélité
    return subtotal * 0.1;
  }

  Future<void> finalizeOrder() async {
    if (_selectedClient != null) {
      final pointsGagnes = loyaltyPointsEarned;
      _selectedClient!.loyaltyPoints += pointsGagnes;
      await _dbHelper.updateClient(_selectedClient!);
    }

    // Réinitialisation du panier et du client
    clearCart();
    notifyListeners();
  }
}
