// lib/views/client_management_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../viewmodels/client_viewmodel.dart';
import 'client_history_page.dart';

class ClientManagementPage extends StatefulWidget {
  const ClientManagementPage({super.key});

  @override
  State<ClientManagementPage> createState() => _ClientManagementPageState();
}

class _ClientManagementPageState extends State<ClientManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _telController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientViewModel>(context, listen: false).fetchClients();
    });
    _searchController.addListener(() {
      Provider.of<ClientViewModel>(context, listen: false)
          .searchClients(_searchController.text);
    });
  }

  void _addClient() async {
    if (_formKey.currentState!.validate()) {
      final newClient = Client(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        tel: _telController.text,
        loyaltyPoints: 0.0,
      );
      final clientViewModel =
          Provider.of<ClientViewModel>(context, listen: false);
      await clientViewModel.addClient(newClient);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client ajouté avec succès!')),
      );

      _firstNameController.clear();
      _lastNameController.clear();
      _telController.clear();
    }
  }

  void _editClient(Client client) {
    _firstNameController.text = client.firstName;
    _lastNameController.text = client.lastName;
    _telController.text = client.tel;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le client'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un prénom';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _telController,
                  decoration:
                      const InputDecoration(labelText: 'Numéro de téléphone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un numéro de téléphone';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _firstNameController.clear();
                _lastNameController.clear();
                _telController.clear();
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final updatedClient = client.copyWith(
                    firstName: _firstNameController.text,
                    lastName: _lastNameController.text,
                    tel: _telController.text,
                  );
                  final clientViewModel =
                      Provider.of<ClientViewModel>(context, listen: false);
                  await clientViewModel.updateClient(updatedClient);
                  Navigator.of(context).pop();
                  _firstNameController.clear();
                  _lastNameController.clear();
                  _telController.clear();
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _deleteClient(Client client) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le client'),
          content: Text(
              'Êtes-vous sûr de vouloir supprimer le client ${client.firstName} ${client.lastName} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final clientViewModel =
                    Provider.of<ClientViewModel>(context, listen: false);
                await clientViewModel.deleteClient(client.id!);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Client supprimé avec succès!')),
                );
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _telController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des clients'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Ajouter un nouveau client',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration:
                                  const InputDecoration(labelText: 'Prénom'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Entrez un prénom';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration:
                                  const InputDecoration(labelText: 'Nom'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Entrez un nom';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _telController,
                              decoration:
                                  const InputDecoration(labelText: 'Téléphone'),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Entrez un numéro de téléphone';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _addClient,
                            child: const Text('Ajouter'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher par nom, prénom ou téléphone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<ClientViewModel>(
                builder: (context, clientViewModel, child) {
                  if (clientViewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final clients = clientViewModel.filteredClients;
                  if (clients.isEmpty) {
                    return const Center(
                      child: Text('Aucun client trouvé.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('${client.firstName} ${client.lastName}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Téléphone: ${client.tel}'),
                              Text(
                                  'Points de fidélité: ${client.loyaltyPoints}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.history,
                                    color: Colors.blue),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ClientHistoryPage(client: client),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.amber),
                                onPressed: () => _editClient(client),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteClient(client),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
