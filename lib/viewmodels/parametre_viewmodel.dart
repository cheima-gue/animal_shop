// lib/viewmodels/parametre_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParametreViewModel extends ChangeNotifier {
  static const String _pointsPerDinarKey = 'points_per_dinar';
  double _pointsPerDinar = 50.0; // Valeur par défaut : 50 points par dinar

  double get pointsPerDinar => _pointsPerDinar;

  ParametreViewModel() {
    _loadLoyaltySettings();
  }

  Future<void> _loadLoyaltySettings() async {
    final prefs = await SharedPreferences.getInstance();
    _pointsPerDinar = prefs.getDouble(_pointsPerDinarKey) ?? 50.0;
    notifyListeners();
  }

  /// Met à jour les paramètres de fidélité en calculant le taux de points par dinar.
  Future<void> updateLoyaltySettings(double points, double montant) async {
    if (montant > 0) {
      final double newRate = points / montant;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_pointsPerDinarKey, newRate);
      _pointsPerDinar = newRate;
      notifyListeners();
    }
  }
}
