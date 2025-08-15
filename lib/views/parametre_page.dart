// lib/views/parametre_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/parametre_viewmodel.dart';

class ParametrePage extends StatelessWidget {
  const ParametrePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<ParametreViewModel>(
          builder: (context, parametreViewModel, child) {
            final TextEditingController controller = TextEditingController(
              text: parametreViewModel.loyaltyPointsRate.toString(),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Points de fidélité',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText:
                        'Millimes gagnés par dinar (ex: 50 pour 50 millimes)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final newRate = double.tryParse(controller.text) ?? 50.0;
                    parametreViewModel.setLoyaltyPointsRate(newRate);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paramètres sauvegardés avec succès!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Sauvegarder'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
