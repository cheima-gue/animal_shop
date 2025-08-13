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
  double get discountAmount => _selectedClient != null ? subtotal * 0.05 : 0.0;
  double get totalPrice => subtotal - discountAmount;

  Future<void> fetchProduits() async {
    _produits = await _databaseHelper.getProduits();
    notifyListeners();
  }

  Future<void> addProduit(Produit produit) async {
    await _databaseHelper.insertProduit(produit);
    fetchProduits();
  }

  Future<void> updateProduit(Produit produit) async {
    await _databaseHelper.updateProduit(produit);
    fetchProduits();
  }

  Future<void> deleteProduit(int id) async {
    await _databaseHelper.deleteProduit(id);
    fetchProduits();
  }

  Future<bool> addProductByBarcode(String codeBarre) async {
    final produit = await _databaseHelper.getProduitByCodeBarre(codeBarre);
    print('Scanned barcode: $codeBarre');
    if (produit != null) {
      print('Produit trouvé: ${produit.nom}');
      addToCart(produit);
      return true; // Succès
    } else {
      print('Produit avec le code-barres "$codeBarre" non trouvé.');
      return false; // Échec
    }
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

  void updateProductQuantity(String codeBarre, int newQuantity) {
    if (_cartItems.containsKey(codeBarre)) {
      _cartItems[codeBarre]!.quantite = newQuantity;
      notifyListeners();
    }
  }

  void removeProductFromCart(String codeBarre) {
    _cartItems.remove(codeBarre);
    notifyListeners();
  }

  Future<void> selectClientByCin(String cin) async {
    _selectedClient = await _databaseHelper.getClientByCin(cin);
    notifyListeners();
  }

  void resetClient() {
    _selectedClient = null;
    notifyListeners();
  }
}
