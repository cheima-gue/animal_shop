// lib/viewmodels/parametre_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParametreViewModel extends ChangeNotifier {
  static const String _loyaltyPointsKey = 'loyalty_points_rate';
  double _loyaltyPointsRate = 50.0; // Valeur par défaut : 50 millimes par dinar

  double get loyaltyPointsRate => _loyaltyPointsRate;

  ParametreViewModel() {
    _loadLoyaltyPointsRate();
  }

  Future<void> _loadLoyaltyPointsRate() async {
    final prefs = await SharedPreferences.getInstance();
    _loyaltyPointsRate = prefs.getDouble(_loyaltyPointsKey) ?? 50.0;
    notifyListeners();
  }

  Future<void> setLoyaltyPointsRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_loyaltyPointsKey, rate);
    _loyaltyPointsRate = rate;
    notifyListeners();
  }
}
