// lib/views/parametre_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/parametre_viewmodel.dart';
import '../models/parametre.dart';

class ParametrePage extends StatefulWidget {
  const ParametrePage({super.key});

  @override
  State<ParametrePage> createState() => _ParametrePageState();
}

class _ParametrePageState extends State<ParametrePage> {
  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _margeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final paramViewModel =
        Provider.of<ParametreViewModel>(context, listen: false);
    paramViewModel.fetchParametres().then((_) {
      final parametre = paramViewModel.parametre;
      if (parametre != null) {
        _pointsController.text = parametre.pointsParDinar.toStringAsFixed(0);
        _montantController.text = parametre.valeurDinar.toStringAsFixed(2);
        _margeController.text =
            (parametre.margeBeneficiaire * 100).toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _montantController.dispose();
    _margeController.dispose();
    super.dispose();
  }

  void _saveParameters() async {
    final double points = double.tryParse(_pointsController.text) ?? 0.0;
    final double montant = double.tryParse(_montantController.text) ?? 0.0;
    final double marge = (double.tryParse(_margeController.text) ?? 0.0) / 100;

    if (points > 0 && montant > 0) {
      final newParametre = Parametre(
        id: Provider.of<ParametreViewModel>(context, listen: false)
                .parametre
                ?.id ??
            1,
        pointsParDinar: points,
        valeurDinar: montant,
        margeBeneficiaire: marge,
      );

      await Provider.of<ParametreViewModel>(context, listen: false)
          .updateParametres(newParametre);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres sauvegardés avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer des valeurs valides.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Consumer<ParametreViewModel>(
        builder: (context, paramViewModel, child) {
          if (paramViewModel.parametre == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paramètres de fidélité',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Définissez la règle de conversion des points de fidélité. Exemple: "10 points pour chaque 10 dinars dépensés".',
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
                            labelText: 'Points gagnés',
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
                  const SizedBox(height: 32),
                  const Text(
                    'Paramètres de commande',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Définissez la marge bénéficiaire maximum pour appliquer une réduction.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _margeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Marge bénéficiaire max. (%)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('%', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveParameters,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 20),
                      ),
                      child: const Text('Sauvegarder',
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
