import 'package:flutter/material.dart';
import '../models/produit.dart';

class ProduitViewModel extends ChangeNotifier {
  // In-memory list to simulate database storage
  final List<Produit> _produits = [];
  int _nextProduitId = 1; // Simple ID counter

  List<Produit> get produits => _produits;

  // Constructor: Initialize with some dummy data for testing
  ProduitViewModel() {
    _produits.addAll([
      Produit(
          id: _nextProduitId++,
          nom: 'Croquettes pour chien',
          prix: 25.50,
          subCategoryId: 1),
      Produit(
          id: _nextProduitId++,
          nom: 'Laisse pour chat',
          prix: 12.00,
          subCategoryId: 2),
      Produit(
          id: _nextProduitId++,
          nom: 'Jouet pour oiseaux',
          prix: 7.99,
          subCategoryId: 3),
      Produit(
          id: _nextProduitId++,
          nom: 'Cage de transport grand',
          prix: 60.00,
          subCategoryId: 4),
      Produit(
          id: _nextProduitId++,
          nom: 'Shampoing anti-puces',
          prix: 18.25,
          subCategoryId: 1),
      Produit(
          id: _nextProduitId++,
          nom: 'Arbre à chat mural',
          prix: 85.00,
          subCategoryId: 2),
      Produit(
          id: _nextProduitId++,
          nom: 'Nourriture pour poissons',
          prix: 9.50,
          subCategoryId: 4),
      Produit(
          id: _nextProduitId++,
          nom: 'Lit douillet chien',
          prix: 35.00,
          subCategoryId: 1),
    ]);
    notifyListeners();
  }

  // Fetches products (simulated)
  Future<void> fetchProduits() async {
    // Simulate API call or database fetch
    await Future.delayed(const Duration(milliseconds: 300));
    notifyListeners(); // Notify listeners even if no data changed, to update UI state
  }

  // Adds a new product
  Future<void> addProduit(Produit produit) async {
    produit.id = _nextProduitId++; // Assign a new ID
    _produits.add(produit);
    notifyListeners(); // Notify UI to re-render
  }

  // Updates an existing product
  Future<void> updateProduit(Produit updatedProduit) async {
    final index = _produits.indexWhere((p) => p.id == updatedProduit.id);
    if (index != -1) {
      _produits[index] = updatedProduit;
      notifyListeners(); // Notify UI to re-render
    }
  }

  // Deletes a product by ID
  Future<void> deleteProduit(int id) async {
    _produits.removeWhere((p) => p.id == id);
    notifyListeners(); // Notify UI to re-render
  }
}
