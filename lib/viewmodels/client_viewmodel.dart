// lib/viewmodels/client_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/database_helper.dart';

class ClientViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Client> _clients = [];
  List<Client> _filteredClients = [];

  List<Client> get clients => _clients;
  List<Client> get filteredClients => _filteredClients;

  ClientViewModel() {
    fetchClients();
  }

  Future<void> fetchClients() async {
    _clients = await _dbHelper.getClients();
    _filteredClients = _clients;
    notifyListeners();
  }

  void searchClients(String query) {
    if (query.isEmpty) {
      _filteredClients = _clients;
    } else {
      _filteredClients = _clients.where((client) {
        final fullName =
            '${client.firstName.toLowerCase()} ${client.lastName.toLowerCase()}';
        final tel = client.tel.toLowerCase();
        final lowerCaseQuery = query.toLowerCase();
        return fullName.contains(lowerCaseQuery) ||
            tel.contains(lowerCaseQuery);
      }).toList();
    }
    notifyListeners();
  }
}
