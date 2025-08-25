// lib/viewmodels/produit_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../models/client.dart';
import '../services/database_helper.dart';
import '../models/commande.dart'; // NOUVEL IMPORT
import '../models/order_item.dart'; // NOUVEL IMPORT
import 'parametre_viewmodel.dart';

class ProduitViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Produit> _produits = [];
  final Map<int, Produit> _cartItems = {};
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
  double get loyaltyPointsUsed => _loyaltyPointsUsed;

  // Le sous-total ne change pas, il se base sur le prix de vente
  double get subtotal => _cartItems.values
      .fold(0, (sum, item) => sum + (item.prix * item.quantiteEnStock));

  // Le total de la commande
  double get totalPrice {
    return subtotal - _loyaltyDiscount;
  }

  // NOUVELLE MÉTHODE : Calcule la marge bénéficiaire totale du panier
  double get totalMarge {
    return _cartItems.values.fold(0, (sum, item) {
      final prixHT = item.coutAchat + (item.coutAchat * item.marge / 100);
      final margeUnitaire = prixHT - item.coutAchat;
      return sum + (margeUnitaire * item.quantiteEnStock);
    });
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
      orElse: () => Produit(
        nom: '',
        codeBarre: '',
        prix: 0,
        quantiteEnStock: 0,
        coutAchat: 0,
        tva: 0,
        marge: 0,
      ),
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

  void applyAllLoyaltyPoints() {
    if (_selectedClient != null && _selectedClient!.loyaltyPoints > 0) {
      final double discountAmountFromPoints =
          _selectedClient!.loyaltyPoints / 1000;

      // La remise est la plus petite valeur entre les points et la marge totale
      final double maxDiscount = totalMarge > 0 ? totalMarge : 0;
      _loyaltyDiscount = (discountAmountFromPoints > maxDiscount)
          ? maxDiscount
          : discountAmountFromPoints;

      // S'assurer que la remise ne dépasse pas le sous-total
      _loyaltyDiscount =
          _loyaltyDiscount > subtotal ? subtotal : _loyaltyDiscount;

      // Calculer les points réellement utilisés
      _loyaltyPointsUsed = _loyaltyDiscount * 1000;

      notifyListeners();
    }
  }

  void applyCustomLoyaltyPoints(double pointsToUse) {
    if (_selectedClient == null || pointsToUse <= 0) {
      resetLoyaltyDiscount();
      return;
    }

    final double maxDiscount = totalMarge > 0 ? totalMarge : 0;

    // Calculer la remise potentielle
    final double discountAmount = pointsToUse / 1000;

    // La remise finale est le minimum entre la remise potentielle, la marge totale et le sous-total
    _loyaltyDiscount =
        [discountAmount, maxDiscount, subtotal].reduce((a, b) => a < b ? a : b);

    // Mettre à jour les points utilisés en fonction de la remise appliquée
    _loyaltyPointsUsed = _loyaltyDiscount * 1000;

    notifyListeners();
  }

  void resetLoyaltyDiscount() {
    _loyaltyDiscount = 0.0;
    _loyaltyPointsUsed = 0.0;
    notifyListeners();
  }

  Future<void> finalizeOrder() async {
    // ... (pas de changement)
  }
}
