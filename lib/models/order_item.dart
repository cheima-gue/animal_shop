// lib/models/order_item.dart

import 'produit.dart';

class OrderItem {
  int? id;
  int? commandeId;
  Produit produit;
  int quantity;
  double price;

  OrderItem({
    this.id,
    this.commandeId,
    required this.produit,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'commandeId': commandeId,
      'produitId': produit.id,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map, Produit produit) {
    return OrderItem(
      id: map['id'],
      commandeId: map['commandeId'],
      produit: produit,
      quantity: map['quantity'],
      price: map['price'],
    );
  }
}
