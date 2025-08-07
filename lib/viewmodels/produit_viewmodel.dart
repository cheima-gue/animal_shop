// lib/viewmodels/produit_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/produit.dart';
import '../services/database_helper.dart';

class ProduitViewModel extends ChangeNotifier {
  // Crée une nouvelle instance de DatabaseHelper, comme dans votre code initial
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Produit> _produits = [];
  List<Produit> get produits => _produits;

  // Nouvelle liste pour le panier
  List<Produit> _cartItems = [];
  List<Produit> get cartItems => _cartItems;

  ProduitViewModel() {
    // Appelle fetchProduits directement dans le constructeur
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

  // Ajoute un produit au panier
  void addToCart(Produit produit) {
    _cartItems.add(produit);
    notifyListeners();
  }

  // Retire un produit du panier
  void removeFromCart(Produit produit) {
    _cartItems.remove(produit);
    notifyListeners();
  }
}
