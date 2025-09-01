// lib/viewmodels/client_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/parametre.dart';
import '../services/database_helper.dart';

class ClientViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  bool _isLoading = false;

  List<Client> get clients => _clients;
  List<Client> get filteredClients => _filteredClients;
  bool get isLoading => _isLoading;

  ClientViewModel() {
    fetchClients();
  }

  Future<void> fetchClients() async {
    _isLoading = true;
    notifyListeners();
    _clients = await _dbHelper.getClients();
    _filteredClients = _clients;
    _isLoading = false;
    notifyListeners();
  }

  void searchClients(String query) {
    if (query.isEmpty) {
      _filteredClients = _clients;
    } else {
      final lowerCaseQuery = query.toLowerCase();
      _filteredClients = _clients.where((client) {
        final fullName =
            '${client.firstName.toLowerCase()} ${client.lastName.toLowerCase()}';
        final tel = client.tel.toLowerCase();
        return fullName.contains(lowerCaseQuery) ||
            tel.contains(lowerCaseQuery);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> addClient(Client client) async {
    final newClientId = await _dbHelper.insertClient(client);
    final newClient = client.copyWith(id: newClientId);
    _clients.add(newClient);
    _filteredClients = _clients;
    notifyListeners();
  }

  Future<void> updateClient(Client client) async {
    await _dbHelper.updateClient(client);
    final index = _clients.indexWhere((c) => c.id == client.id);
    if (index != -1) {
      _clients[index] = client;
      _filteredClients = _clients;
      notifyListeners();
    }
  }

  Future<void> deleteClient(int id) async {
    await _dbHelper.deleteClient(id);
    _clients.removeWhere((client) => client.id == id);
    _filteredClients = _clients;
    notifyListeners();
  }

  double calculateDinarEquivalent(double points, Parametre parametre) {
    if (parametre.pointsParDinar == 0 || parametre.valeurDinar == 0) {
      return 0.0;
    }
    return (points / parametre.pointsParDinar) * parametre.valeurDinar;
  }
}
