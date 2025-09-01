// lib/views/client_history_page.dart

import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../services/database_helper.dart';

class ClientHistoryPage extends StatelessWidget {
  final Client client;

  const ClientHistoryPage({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique de ${client.firstName} ${client.lastName}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper().getClientHistory(client.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune commande trouvée.'));
          }

          final commandes = snapshot.data!;
          return ListView.builder(
            itemCount: commandes.length,
            itemBuilder: (context, index) {
              final commande = Commande.fromMap(commandes[index]);
              return ExpansionTile(
                title: Text(
                    'Commande du ${commande.dateCommande.substring(0, 10)}'),
                subtitle:
                    Text('Total: ${commande.total.toStringAsFixed(2)} TND'),
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: DatabaseHelper().getOrderItems(commande.id!),
                    builder: (context, itemSnapshot) {
                      if (itemSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const LinearProgressIndicator();
                      } else if (itemSnapshot.hasError) {
                        return const Text('Erreur de chargement des articles.');
                      }

                      final items = itemSnapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: items.map((item) {
                            return ListTile(
                              title: Text(item['nom'] ?? 'Produit inconnu'),
                              trailing: Text(
                                  '${item['quantity']} x ${item['price']} TND'),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
