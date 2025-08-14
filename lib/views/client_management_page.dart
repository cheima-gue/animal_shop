// lib/views/client_management_page.dart

import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/database_helper.dart';

class ClientManagementPage extends StatefulWidget {
  const ClientManagementPage({super.key});

  @override
  State<ClientManagementPage> createState() => _ClientManagementPageState();
}

class _ClientManagementPageState extends State<ClientManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _telController =
      TextEditingController(); // Utilisation du contrôleur pour le numéro de téléphone

  void _addClient() async {
    if (_formKey.currentState!.validate()) {
      final newClient = Client(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        tel: _telController.text, // Passage du numéro de téléphone
        loyaltyPoints:
            0.0, // Initialise les points de fidélité à 0 pour un nouveau client
      );
      await _dbHelper.insertClient(newClient);

      // Rafraîchir la liste des clients ou notifier un changement si cette page liste les clients
      // (Si vous avez une liste de clients à afficher sur cette page)
      // Par exemple, si vous avez un ClientViewModel
      // Provider.of<ClientViewModel>(context, listen: false).fetchClients();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client ajouté avec succès!')),
      );

      _firstNameController.clear();
      _lastNameController.clear();
      _telController.clear(); // Nettoyage du contrôleur de téléphone
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _telController.dispose(); // Libération du contrôleur de téléphone
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
        child: Form(
          key: _formKey,
          child: Column(
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
                controller: _telController, // Changement ici
                decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone'), // Changement du label
                keyboardType:
                    TextInputType.phone, // Changement du type de clavier
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un numéro de téléphone';
                  }
                  // Vous pouvez ajouter une validation de format de téléphone ici si nécessaire
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addClient,
                child: const Text('Ajouter le client'),
              ),
              // Si vous souhaitez afficher la liste des clients sur cette page, vous devriez
              // ajouter un Consumer<ClientViewModel> ici et un ListView.builder.
              // Actuellement, cette page sert uniquement à l'ajout.
            ],
          ),
        ),
      ),
    );
  }
}
