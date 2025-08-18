// lib/views/parametre_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/parametre_viewmodel.dart';

class ParametrePage extends StatefulWidget {
  const ParametrePage({super.key});

  @override
  State<ParametrePage> createState() => _ParametrePageState();
}

class _ParametrePageState extends State<ParametrePage> {
  // Contrôleurs pour les champs de texte
  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialise les contrôleurs avec des valeurs par défaut
    // La logique de récupération des valeurs précédentes se ferait dans le ViewModel,
    // mais la vue peut utiliser des valeurs par défaut si ce n'est pas nécessaire.
    _pointsController.text = '50';
    _montantController.text = '1.00';
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  void _saveParameters() {
    final double points = double.tryParse(_pointsController.text) ?? 0.0;
    final double montant = double.tryParse(_montantController.text) ?? 0.0;

    if (points > 0 && montant > 0) {
      // MODIFIÉ : Appelle la nouvelle méthode du ViewModel et lui passe les deux valeurs
      Provider.of<ParametreViewModel>(context, listen: false)
          .updateLoyaltySettings(points, montant);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paramètres de fidélité mis à jour avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Veuillez entrer des valeurs valides pour les points et le montant.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Points de fidélité',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Définissez la règle de conversion des points de fidélité. Exemple: "100 points pour chaque 50 dinars dépensés".',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pointsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de points gagnés',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('points pour chaque',
                    style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _montantController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Montant dépensé (DT)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('DT', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveParameters,
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }
}
