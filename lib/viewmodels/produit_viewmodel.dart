import 'package:flutter/material.dart'; //nécessaire pour utiliser ChangeNotifier, qui permet de notifier l’UI (interface utilisateur) quand il y a des changements.
import '../models/produit.dart';
import '../services/database_helper.dart'; // Importez le DatabaseHelper

class ProduitViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Produit> _produits = [];
  List<Produit> get produits => _produits;

  ProduitViewModel() {
    fetchProduits(); // Charge les produits depuis la base de données au démarrage
  }

  // Récupère les produits depuis la base de données
  Future<void> fetchProduits() async {
    _produits = await _dbHelper.getProduits();
    notifyListeners();
  }

  // Ajoute un nouveau produit dans la base de données
  Future<void> addProduit(Produit produit) async {
    await _dbHelper.insertProduit(produit);
    await fetchProduits(); // Met à jour la liste depuis la DB
  }

  // Met à jour un produit existant dans la base de données
  Future<void> updateProduit(Produit updatedProduit) async {
    await _dbHelper.updateProduit(updatedProduit);
    await fetchProduits(); // Met à jour la liste depuis la DB
  }

  // Supprime un produit de la base de données par ID
  Future<void> deleteProduit(int id) async {
    await _dbHelper.deleteProduit(id);
    await fetchProduits(); // Met à jour la liste depuis la DB
  }
}
