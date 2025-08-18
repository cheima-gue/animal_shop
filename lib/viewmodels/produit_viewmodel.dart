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

  // Variables pour la réduction des points de fidélité
  double _loyaltyDiscount = 0.0;
  double _loyaltyPointsUsed = 0.0;

  late BuildContext _context;

  List<Produit> get produits => _produits;
  Map<int, Produit> get cartItems => _cartItems;
  Client? get selectedClient => _selectedClient;
  double get loyaltyPointsEarned => _loyaltyPointsEarned;

  double get loyaltyDiscount => _loyaltyDiscount;
  double get loyaltyPointsUsed => _loyaltyPointsUsed; // Nouveau getter

  double get subtotal => _cartItems.values
      .fold(0, (sum, item) => sum + (item.prix * item.quantiteEnStock));

  double get totalPrice {
    return subtotal - _loyaltyDiscount;
  }

  void initialize(BuildContext context) {
    _context = context;
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

  Future<void> updateProduit(Produit produit) async {
    await _dbHelper.updateProduit(produit);
    await fetchProduits();
  }

  Future<void> deleteProduit(int id) async {
    await _dbHelper.deleteProduit(id);
    await fetchProduits();
  }

  Future<bool> addProductByBarcode(String barcode) async {
    final existingProduct = _produits.firstWhere(
      (p) => p.codeBarre == barcode,
      orElse: () =>
          Produit(nom: '', codeBarre: '', prix: 0, quantiteEnStock: 0),
    );

    if (existingProduct.id == null) {
      return false;
    }

    if ((_cartItems[existingProduct.id]?.quantiteEnStock ?? 0) + 1 >
        existingProduct.quantiteEnStock) {
      return false;
    }

    if (_cartItems.containsKey(existingProduct.id)) {
      _cartItems[existingProduct.id]!.quantiteEnStock += 1;
    } else {
      _cartItems[existingProduct.id!] =
          existingProduct.copyWith(quantiteEnStock: 1);
    }
    _calculateLoyaltyPoints();
    resetLoyaltyDiscount();
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
      resetLoyaltyDiscount();
      notifyListeners();
    }
  }

  void removeProductFromCart(int productId) {
    _cartItems.remove(productId);
    _calculateLoyaltyPoints();
    resetLoyaltyDiscount();
    notifyListeners();
  }

  void selectClient(Client client) {
    _selectedClient = client;
    _calculateLoyaltyPoints();
    resetLoyaltyDiscount();
    notifyListeners();
  }

  void resetClient() {
    _selectedClient = null;
    _loyaltyPointsEarned = 0.0;
    resetLoyaltyDiscount();
    notifyListeners();
  }

  // MODIFIÉ : Utilise `pointsPerDinar` pour un calcul plus simple
  void _calculateLoyaltyPoints() {
    if (_selectedClient != null) {
      final double pointsPerDinar =
          Provider.of<ParametreViewModel>(_context, listen: false)
              .pointsPerDinar;
      _loyaltyPointsEarned = subtotal * pointsPerDinar;
    } else {
      _loyaltyPointsEarned = 0.0;
    }
  }

  void applyLoyaltyPoints() {
    if (_selectedClient != null && _selectedClient!.loyaltyPoints > 0) {
      // Conversion des points en dinars (par exemple, 1000 pts = 1 DT)
      final double discountAmount = _selectedClient!.loyaltyPoints / 1000;

      // La réduction ne doit pas dépasser le sous-total
      _loyaltyDiscount = discountAmount > subtotal ? subtotal : discountAmount;
      _loyaltyPointsUsed = _loyaltyDiscount * 1000;

      notifyListeners();
    }
  }

  void resetLoyaltyDiscount() {
    _loyaltyDiscount = 0.0;
    _loyaltyPointsUsed = 0.0;
    notifyListeners();
  }

  Future<void> finalizeOrder() async {
    if (_selectedClient != null) {
      // Met à jour les points du client en déduisant d'abord ceux utilisés
      if (_loyaltyPointsUsed > 0) {
        _selectedClient!.loyaltyPoints -= _loyaltyPointsUsed;
      }
      _selectedClient!.loyaltyPoints += _loyaltyPointsEarned;
      await _dbHelper.updateClient(_selectedClient!);
    }

    // Met à jour le stock pour chaque produit
    for (var cartItem in _cartItems.values) {
      final originalProduct = _produits.firstWhere((p) => p.id == cartItem.id);
      originalProduct.quantiteEnStock -= cartItem.quantiteEnStock;
      await _dbHelper.updateProduit(originalProduct);
    }

    // Réinitialise le panier et les variables après la finalisation
    _cartItems.clear();
    _loyaltyPointsEarned = 0.0;
    resetLoyaltyDiscount();
    notifyListeners();
  }
}
