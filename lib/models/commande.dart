// lib/models/commande.dart

import 'order_item.dart';

class Commande {
  int? id;
  String? dateCommande;
  double? total;
  List<OrderItem> items;

  Commande({
    this.id,
    this.dateCommande,
    this.total,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateCommande': dateCommande,
      'total': total,
    };
  }

  factory Commande.fromMap(Map<String, dynamic> map) {
    return Commande(
      id: map['id'],
      dateCommande: map['dateCommande'],
      total: map['total'],
      items: [], // Les items seront chargés séparément
    );
  }
}
