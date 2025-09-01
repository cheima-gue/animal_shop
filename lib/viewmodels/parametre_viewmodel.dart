// lib/viewmodels/parametre_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/parametre.dart';
import '../services/database_helper.dart';

class ParametreViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Parametre? _parametre;

  Parametre? get parametre => _parametre;

  Future<void> fetchParametres() async {
    _parametre = await _dbHelper.getParametres();
    if (_parametre == null) {
      _parametre = Parametre(
        id: 1,
        pointsParDinar: 1.0,
        valeurDinar: 0.1,
        margeBeneficiaire: 0.2,
      );
      await _dbHelper.insertParametres(_parametre!);
    }
    notifyListeners();
  }

  Future<void> updateParametres(Parametre newParametre) async {
    await _dbHelper.updateParametres(newParametre);
    _parametre = newParametre;
    notifyListeners();
  }
}
