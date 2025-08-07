// lib/widgets/produit_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/produit.dart';

class ProduitCard extends StatelessWidget {
  final Produit produit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(Produit)? onAddToCart;

  const ProduitCard({
    super.key,
    required this.produit,
    this.onEdit,
    this.onDelete,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            // MODIFIÉ
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: Container(
                width: double.infinity,
                child: produit.image != null &&
                        produit.image!.isNotEmpty &&
                        File(produit.image!).existsSync()
                    ? Image.file(
                        File(produit.image!),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              size: 50, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.fastfood,
                            size: 50, color: Colors.grey),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              produit.nom,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              produit.codeBarre,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              '${produit.prix.toStringAsFixed(2)} DT',
              style: const TextStyle(color: Colors.teal, fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
                if (onAddToCart != null)
                  IconButton(
                    icon:
                        const Icon(Icons.add_shopping_cart, color: Colors.teal),
                    onPressed: () => onAddToCart!(produit),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
