import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';
import '../models/commande.dart'; // NOUVEL IMPORT
import '../models/order_item.dart'; // NOUVEL IMPORT
import '../services/database_helper.dart'; // NOUVEL IMPORT
import '../models/produit.dart'; // NOUVEL IMPORT

class ClientHistoryPage extends StatefulWidget {
  final Client client;

  const ClientHistoryPage({super.key, required this.client});

  @override
  State<ClientHistoryPage> createState() => _ClientHistoryPageState();
}

class _ClientHistoryPageState extends State<ClientHistoryPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Commande> _commandes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final commandesMaps = await _dbHelper.getClientHistory(widget.client.id!);
    List<Commande> tempCommandes = [];
    for (var map in commandesMaps) {
      Commande commande = Commande.fromMap(map);
      final itemsMaps = await _dbHelper.getOrderItems(commande.id!);

      commande.items = itemsMaps.map((itemMap) {
        // CORRECTION ICI: Ajout des nouvelles propriétés au constructeur de Produit
        final produit = Produit(
          id: itemMap['produitId'],
          nom: itemMap['nom'],
          prix: itemMap['price'], // Le prix de l'item au moment de l'achat
          quantiteEnStock: itemMap['quantity'], // Quantité achetée
          subCategoryId: 0,
          image: itemMap['image'],
          codeBarre: '',
          coutAchat: 0.0, // Valeur par défaut
          tva: 0.0, // Valeur par défaut
          marge: 0.0, // Valeur par défaut
        );
        return OrderItem.fromMap(itemMap, produit);
      }).toList();

      tempCommandes.add(commande);
    }

    setState(() {
      _commandes = tempCommandes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Historique de ${widget.client.firstName} ${widget.client.lastName}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informations du client',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                        'Nom: ${widget.client.firstName} ${widget.client.lastName}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Téléphone: ${widget.client.tel}',
                        style: const TextStyle(fontSize: 16)),
                    Text(
                        'Points de fidélité: ${widget.client.loyaltyPoints.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Historique des achats',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: _commandes.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun historique de transaction trouvé pour ce client.',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _commandes.length,
                            itemBuilder: (context, index) {
                              final commande = _commandes[index];
                              final date =
                                  DateTime.parse(commande.dateCommande!);
                              final formattedDate =
                                  DateFormat('dd/MM/yyyy à HH:mm').format(date);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16.0),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Commande #${commande.id} - $formattedDate',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.purple),
                                      ),
                                      const SizedBox(height: 8),
                                      ...commande.items.map((item) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                  '${item.produit.nom} x ${item.quantity}'),
                                              Text(
                                                  '${(item.price * item.quantity).toStringAsFixed(2)} DT'),
                                            ],
                                          ),
                                        );
                                      }),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Total Commande:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                            '${commande.total!.toStringAsFixed(2)} DT',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
