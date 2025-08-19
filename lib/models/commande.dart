// lib/models/commande.dart

import 'order_item.dart';

class Commande {
  int? id;
  int? clientId; // NOUVEAU: Pour lier la commande à un client
  String? dateCommande;
  double? total;
  List<OrderItem> items;

  Commande({
    this.id,
    this.clientId, // NOUVEAU
    this.dateCommande,
    this.total,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId, // NOUVEAU
      'dateCommande': dateCommande,
      'total': total,
    };
  }

  factory Commande.fromMap(Map<String, dynamic> map) {
    return Commande(
      id: map['id'],
      clientId: map['clientId'], // NOUVEAU
      dateCommande: map['dateCommande'],
      total: map['total'],
      items: [],
    );
  }
}
