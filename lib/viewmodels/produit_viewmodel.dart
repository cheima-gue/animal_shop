// lib/viewmodels/produit_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../models/client.dart';
import '../services/database_helper.dart';
import 'parametre_viewmodel.dart';

class ProduitViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Produit> _produits = [];
  Map<int, Produit> _cartItems = {};
  Client? _selectedClient;
  double _loyaltyPointsEarned = 0.0;

  // Ajoutez un BuildContext pour accéder à ParametreViewModel
  late BuildContext _context;

  List<Produit> get produits => _produits;
  Map<int, Produit> get cartItems => _cartItems;
  Client? get selectedClient => _selectedClient;
  double get loyaltyPointsEarned => _loyaltyPointsEarned;

  double get subtotal => _cartItems.values
      .fold(0, (sum, item) => sum + (item.prix * item.quantiteEnStock));

  double get totalPrice {
    // Implementez ici la logique de réduction si nécessaire
    return subtotal;
  }

  // Initialisez le context pour pouvoir utiliser Provider.of
  void initialize(BuildContext context) {
    _context = context;
    fetchProduits();
  }

  Future<void> fetchProduits() async {
    _produits = await _dbHelper.getProduits();
    notifyListeners();
  }

  // ============== Méthodes de gestion des produits manquantes ============
  Future<void> addProduit(Produit produit) async {
    await _dbHelper.insertProduit(produit);
    await fetchProduits(); // Actualise la liste après l'ajout
  }

  Future<void> updateProduit(Produit produit) async {
    await _dbHelper.updateProduit(produit);
    await fetchProduits(); // Actualise la liste après la mise à jour
  }

  Future<void> deleteProduit(int id) async {
    await _dbHelper.deleteProduit(id);
    await fetchProduits(); // Actualise la liste après la suppression
  }
  // =========================================================================

  Future<bool> addProductByBarcode(String barcode) async {
    final existingProduct = _produits.firstWhere(
      (p) => p.codeBarre == barcode,
      orElse: () =>
          Produit(nom: '', codeBarre: '', prix: 0, quantiteEnStock: 0),
    );

    if (existingProduct.id == null) {
      return false; // Produit non trouvé
    }

    // Vérifie si la quantité demandée ne dépasse pas le stock
    if ((_cartItems[existingProduct.id]?.quantiteEnStock ?? 0) + 1 >
        existingProduct.quantiteEnStock) {
      return false; // Stock insuffisant
    }

    if (_cartItems.containsKey(existingProduct.id)) {
      _cartItems[existingProduct.id]!.quantiteEnStock += 1;
    } else {
      _cartItems[existingProduct.id!] =
          existingProduct.copyWith(quantiteEnStock: 1);
    }
    _calculateLoyaltyPoints();
    notifyListeners();
    return true;
  }

  void updateProductQuantity(int productId, int quantity) {
    if (_cartItems.containsKey(productId)) {
      if (quantity > 0) {
        final originalProduct = _produits.firstWhere((p) => p.id == productId);
        if (quantity <= originalProduct.quantiteEnStock) {
          _cartItems[productId]!.quantiteEnStock = quantity;
        }
      } else {
        _cartItems.remove(productId);
      }
      _calculateLoyaltyPoints();
      notifyListeners();
    }
  }

  void removeProductFromCart(int productId) {
    _cartItems.remove(productId);
    _calculateLoyaltyPoints();
    notifyListeners();
  }

  void selectClient(Client client) {
    _selectedClient = client;
    _calculateLoyaltyPoints();
    notifyListeners();
  }

  void resetClient() {
    _selectedClient = null;
    _loyaltyPointsEarned = 0.0;
    notifyListeners();
  }

  void _calculateLoyaltyPoints() {
    if (_selectedClient != null) {
      final double loyaltyRate =
          Provider.of<ParametreViewModel>(_context, listen: false)
              .loyaltyPointsRate;
      _loyaltyPointsEarned =
          (subtotal * loyaltyRate) / 1000; // Calcule les millimes
    } else {
      _loyaltyPointsEarned = 0.0;
    }
  }

  Future<void> finalizeOrder() async {
    if (_selectedClient != null) {
      _selectedClient!.loyaltyPoints += _loyaltyPointsEarned;
      await _dbHelper.updateClient(_selectedClient!);
    }

    // Mettre à jour le stock pour chaque produit dans le panier
    for (var cartItem in _cartItems.values) {
      final originalProduct = _produits.firstWhere((p) => p.id == cartItem.id);
      originalProduct.quantiteEnStock -= cartItem.quantiteEnStock;
      await _dbHelper.updateProduit(originalProduct);
    }

    _cartItems.clear();
    _loyaltyPointsEarned = 0.0;
    notifyListeners();
  }
}
