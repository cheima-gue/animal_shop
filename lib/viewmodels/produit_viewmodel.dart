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

  // NOUVEAU: Variables pour la réduction des points de fidélité
  double _loyaltyDiscount = 0.0;
  double _loyaltyPointsUsed = 0.0;

  // Ajoutez un BuildContext pour accéder à ParametreViewModel
  late BuildContext _context;

  List<Produit> get produits => _produits;
  Map<int, Produit> get cartItems => _cartItems;
  Client? get selectedClient => _selectedClient;
  double get loyaltyPointsEarned => _loyaltyPointsEarned;

  // NOUVEAU: Getter pour la réduction des points de fidélité
  double get loyaltyDiscount => _loyaltyDiscount;

  double get subtotal => _cartItems.values
      .fold(0, (sum, item) => sum + (item.prix * item.quantiteEnStock));

  double get totalPrice {
    // MODIFIÉ: Le total est le sous-total moins la réduction des points
    return subtotal - _loyaltyDiscount;
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
    resetLoyaltyDiscount(); // Réinitialise la réduction à chaque ajout d'article
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
      resetLoyaltyDiscount(); // Réinitialise la réduction
      notifyListeners();
    }
  }

  void removeProductFromCart(int productId) {
    _cartItems.remove(productId);
    _calculateLoyaltyPoints();
    resetLoyaltyDiscount(); // Réinitialise la réduction
    notifyListeners();
  }

  void selectClient(Client client) {
    _selectedClient = client;
    _calculateLoyaltyPoints();
    resetLoyaltyDiscount(); // Réinitialise la réduction lorsqu'un nouveau client est sélectionné
    notifyListeners();
  }

  void resetClient() {
    _selectedClient = null;
    _loyaltyPointsEarned = 0.0;
    resetLoyaltyDiscount(); // Réinitialise la réduction
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

  // NOUVEAU: Méthode pour appliquer les points de fidélité comme réduction
  void applyLoyaltyPoints() {
    if (_selectedClient != null && _selectedClient!.loyaltyPoints > 0) {
      // Conversion des points en dinars (par exemple, 1000 pts = 1 DT)
      final double discountAmount = _selectedClient!.loyaltyPoints / 1000;

      // La réduction ne doit pas dépasser le sous-total
      _loyaltyDiscount = discountAmount > subtotal ? subtotal : discountAmount;
      _loyaltyPointsUsed =
          _loyaltyDiscount * 1000; // Calcule les points utilisés

      notifyListeners();
    }
  }

  // NOUVEAU: Méthode pour réinitialiser la réduction
  void resetLoyaltyDiscount() {
    _loyaltyDiscount = 0.0;
    _loyaltyPointsUsed = 0.0;
    notifyListeners();
  }

  Future<void> finalizeOrder() async {
    if (_selectedClient != null) {
      // MODIFIÉ: On déduit d'abord les points utilisés, puis on ajoute les points gagnés.
      if (_loyaltyPointsUsed > 0) {
        _selectedClient!.loyaltyPoints -= _loyaltyPointsUsed;
      }
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
    resetLoyaltyDiscount(); // S'assurer que la réduction est réinitialisée après la finalisation
    notifyListeners();
  }
}
