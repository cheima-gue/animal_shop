// viewmodels/produit_viewmodel.dart
import 'package:flutter/foundation.dart';
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
    if (produit.id == null) {
      throw Exception('Produit sans ID, impossible de le mettre à jour.');
    }
    await _dbHelper.updateProduit(produit);
    await fetchProduits();
  }

  Future<void> deleteProduit(int id) async {
    await _dbHelper.deleteProduit(id);
    await fetchProduits();
  }
}
