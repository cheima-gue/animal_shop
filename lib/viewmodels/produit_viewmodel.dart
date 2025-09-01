// lib/viewmodels/produit_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/produit.dart';
import '../services/database_helper.dart';

class ProduitViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Produit> _produits = [];

  List<Produit> get produits => _produits;

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

  // Cette méthode est déplacée ici, car elle concerne la recherche d'un produit.
  Future<Produit?> getProduitByCodeBarre(String codeBarre) async {
    final List<Produit> allProduits = await _dbHelper.getProduits();
    try {
      return allProduits.firstWhere((p) => p.codeBarre == codeBarre);
    } catch (e) {
      return null;
    }
  }

  // Ajout de cette méthode pour obtenir un produit par son ID
  Future<Produit?> getProduitById(int id) async {
    return await _dbHelper.getProduitById(id);
  }
}
