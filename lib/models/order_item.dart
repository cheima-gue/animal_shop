// lib/models/order_item.dart

class OrderItem {
  int? id;
  int? commandeId;
  final int productId;
  final int quantity;
  final double price;
  final double subtotal;

  OrderItem({
    this.id,
    this.commandeId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'commandeId': commandeId,
      'productId': productId,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      commandeId: map['commandeId'],
      productId: map['productId'],
      quantity: map['quantity'],
      price: map['price'],
      subtotal: map['subtotal'],
    );
  }
}
