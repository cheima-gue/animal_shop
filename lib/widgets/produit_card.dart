// lib/widgets/produit_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/produit.dart';

class ProduitCard extends StatelessWidget {
  final Produit produit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProduitCard({
    super.key,
    required this.produit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: produit.image != null && produit.image!.isNotEmpty
                      ? Image.file(
                          File(produit.image!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 50),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.fastfood,
                              size: 50, color: Colors.grey),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  produit.nom,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  '${produit.prix.toStringAsFixed(2)} DT',
                  style: const TextStyle(color: Colors.teal, fontSize: 14),
                ),
              ),
            ],
          ),
          Positioned(
            top: 5,
            right: 5,
            child: PopupMenuButton<String>(
              onSelected: (String result) {
                if (result == 'edit') {
                  onEdit();
                } else if (result == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit, color: Colors.blue),
                    title: Text('Modifier'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Supprimer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
