// lib/models/commande.dart

import 'order_item.dart';

class Commande {
  final int? id;
  final int? clientId;
  final String dateCommande;
  final double total;
  List<OrderItem> items;

  Commande({
    this.id,
    this.clientId,
    required this.dateCommande,
    required this.total,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'dateCommande': dateCommande,
      'total': total,
    };
  }

  factory Commande.fromMap(Map<String, dynamic> map) {
    return Commande(
      id: map['id'],
      clientId: map['clientId'],
      dateCommande: map['dateCommande'] as String? ?? '',
      total: map['total'] as double? ?? 0.0,
      items: [],
    );
  }

  Commande copyWith({
    int? id,
    int? clientId,
    String? dateCommande,
    double? total,
    List<OrderItem>? items,
  }) {
    return Commande(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      dateCommande: dateCommande ?? this.dateCommande,
      total: total ?? this.total,
      items: items ?? this.items,
    );
  }
}
