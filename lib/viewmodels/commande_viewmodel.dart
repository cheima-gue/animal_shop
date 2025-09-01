import 'package:flutter/material.dart';
import '../models/produit.dart';
import '../models/client.dart';
import '../models/parametre.dart';
import '../models/commande.dart';
import '../models/order_item.dart';
import '../services/database_helper.dart';

class CommandeViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Map<int, Produit> _cartItems = {};
  Client? _selectedClient;
  double _loyaltyPointsEarned = 0.0;
  double _loyaltyDiscount = 0.0;
  double _loyaltyPointsUsed = 0.0;
  Parametre? _parametre;

  Map<int, Produit> get cartItems => _cartItems;
  Client? get selectedClient => _selectedClient;
  double get loyaltyPointsEarned => _loyaltyPointsEarned;
  double get loyaltyDiscount => _loyaltyDiscount;
  double get loyaltyPointsUsed => _loyaltyPointsUsed;

  double get subtotal => _cartItems.values
      .fold(0, (sum, item) => sum + (item.prix * item.quantiteEnStock));

  double get total => subtotal - _loyaltyDiscount;

  double get totalMarge {
    return _cartItems.values.fold(0, (sum, item) {
      final margeUnitaire = item.prix - item.coutAchat;
      return sum + (margeUnitaire * item.quantiteEnStock);
    });
  }

  void setParametre(Parametre? parametre) {
    _parametre = parametre;
    _recalculateValues();
  }

  Future<bool> addProductByBarcode(Produit produit) async {
    final existingProduct =
        await _dbHelper.getProduitByCodeBarre(produit.codeBarre);

    if (existingProduct == null) {
      return false;
    }

    // Check if adding one more product would exceed the stock
    final currentQuantityInCart =
        _cartItems[existingProduct.id]?.quantiteEnStock ?? 0;
    if (currentQuantityInCart + 1 > existingProduct.quantiteEnStock) {
      return false;
    }

    if (_cartItems.containsKey(existingProduct.id)) {
      _cartItems[existingProduct.id]!.quantiteEnStock += 1;
    } else {
      _cartItems[existingProduct.id!] =
          existingProduct.copyWith(quantiteEnStock: 1);
    }
    _recalculateValues();
    notifyListeners();
    return true;
  }

  void updateProductQuantity(int productId, int quantity) async {
    if (_cartItems.containsKey(productId)) {
      final originalProduct = await _dbHelper.getProduitById(productId);
      if (originalProduct == null) return;

      if (quantity > 0) {
        if (quantity <= originalProduct.quantiteEnStock) {
          _cartItems[productId]!.quantiteEnStock = quantity;
        } else {
          _cartItems[productId]!.quantiteEnStock =
              originalProduct.quantiteEnStock;
        }
      } else {
        _cartItems.remove(productId);
      }
      _recalculateValues();
      notifyListeners();
    }
  }

  void removeProductFromCart(int productId) {
    _cartItems.remove(productId);
    _recalculateValues();
    notifyListeners();
  }

  void selectClient(Client client) {
    _selectedClient = client;
    _recalculateValues();
    notifyListeners();
  }

  void resetClient() {
    _selectedClient = null;
    _recalculateValues();
    notifyListeners();
  }

  void applyLoyaltyPoints(double pointsToUse) {
    if (_selectedClient == null || pointsToUse <= 0 || _parametre == null) {
      resetLoyaltyDiscount();
      return;
    }

    final double maxClientPoints = _selectedClient!.loyaltyPoints;
    double actualPointsToUse =
        pointsToUse > maxClientPoints ? maxClientPoints : pointsToUse;

    final double maxDiscount = totalMarge > 0 ? totalMarge : 0;
    final double discountAmountFromPoints =
        (actualPointsToUse / _parametre!.pointsParDinar) *
            _parametre!.valeurDinar;

    _loyaltyDiscount = [discountAmountFromPoints, maxDiscount, subtotal]
        .reduce((a, b) => a < b ? a : b);
    _loyaltyPointsUsed = (_loyaltyDiscount / _parametre!.valeurDinar) *
        _parametre!.pointsParDinar;

    notifyListeners();
  }

  void resetLoyaltyDiscount() {
    _loyaltyDiscount = 0.0;
    _loyaltyPointsUsed = 0.0;
    notifyListeners();
  }

  void _recalculateValues() {
    if (_selectedClient != null && _parametre != null) {
      final double pointsPerDinar = (_parametre!.valeurDinar > 0)
          ? _parametre!.pointsParDinar / _parametre!.valeurDinar
          : 0.0;
      _loyaltyPointsEarned = subtotal * pointsPerDinar;
    } else {
      _loyaltyPointsEarned = 0.0;
    }
    resetLoyaltyDiscount();
  }

  Future<double> finalizeOrder() async {
    if (_cartItems.isEmpty) return 0.0;

    // 1. Update product stock
    for (var cartItem in _cartItems.values) {
      final originalProduct = await _dbHelper.getProduitById(cartItem.id!);
      if (originalProduct != null) {
        originalProduct.quantiteEnStock -= cartItem.quantiteEnStock;
        await _dbHelper.updateProduit(originalProduct);
      }
    }

    // 2. Create and save the order
    final newCommande = Commande(
      clientId: _selectedClient?.id,
      dateCommande: DateTime.now().toIso8601String(),
      total: total,
    );
    final commandeId = await _dbHelper.insertCommande(newCommande);

    // 3. Save order items
    for (var cartItem in _cartItems.values) {
      final orderItem = OrderItem(
        commandeId: commandeId,
        productId: cartItem.id!,
        quantity: cartItem.quantiteEnStock,
        price: cartItem.prix,
        subtotal: cartItem.prix * cartItem.quantiteEnStock,
      );
      await _dbHelper.insertOrderItem(orderItem);
    }

    double newLoyaltyPoints = 0.0;
    if (_selectedClient != null) {
      newLoyaltyPoints = _selectedClient!.loyaltyPoints +
          _loyaltyPointsEarned -
          _loyaltyPointsUsed;
      final updatedClient =
          _selectedClient!.copyWith(loyaltyPoints: newLoyaltyPoints);
      await _dbHelper.updateClient(updatedClient);
      _selectedClient = updatedClient;
    }

    // 5. Reset the cart
    _cartItems.clear();
    _selectedClient = null;
    _loyaltyPointsEarned = 0.0;
    _loyaltyDiscount = 0.0;
    _loyaltyPointsUsed = 0.0;
    notifyListeners();

    // 6. Return the calculated value
    return newLoyaltyPoints;
  }
}
