// lib/views/client_list_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/client_viewmodel.dart';
import 'client_history_page.dart'; // NOUVEL IMPORT

class ClientListPage extends StatefulWidget {
  const ClientListPage({super.key});

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientViewModel>(context, listen: false).fetchClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des clients'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher un client',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                Provider.of<ClientViewModel>(context, listen: false)
                    .searchClients(query);
              },
            ),
          ),
          Expanded(
            child: Consumer<ClientViewModel>(
              builder: (context, clientViewModel, child) {
                if (clientViewModel.filteredClients.isEmpty) {
                  return const Center(child: Text('Aucun client trouvé.'));
                }
                return ListView.builder(
                  itemCount: clientViewModel.filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = clientViewModel.filteredClients[index];
                    return ListTile(
                      title: Text('${client.firstName} ${client.lastName}'),
                      subtitle: Text(
                          'Tél: ${client.tel} | Points: ${client.loyaltyPoints.toStringAsFixed(2)}'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          // Redirige vers la page d'historique du client
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ClientHistoryPage(client: client),
                            ),
                          );
                        },
                        child: const Text('Voir l\'historique'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
