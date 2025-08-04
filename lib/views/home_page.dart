import 'package:flutter/material.dart';
import 'produit_home_page.dart'; // Pour ajouter un produit
import 'produit_list_page.dart'; // Pour lister et rechercher des produits

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenue dans la Gestion des Produits'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image pour embellir, avec gestion d'erreur au cas où elle ne serait pas trouvée
              Image.asset(
                'assets/pet_shop_icon.png', // Assurez-vous que cette image existe et est déclarée
                height: 150,
                width: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.pets, // Fallback icon
                  size: 150,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Gérez facilement vos produits pour animaux!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Bouton pour ajouter un produit (ou accéder à la page d'ajout/modification)
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Ajouter / Gérer les produits'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProduitHomePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, 55), // Bouton plus large
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
              ),
              const SizedBox(height: 20),
              // Bouton pour voir la liste des produits avec recherche
              ElevatedButton.icon(
                icon: const Icon(Icons.list_alt),
                label: const Text('Voir la liste des produits'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProduitListPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor:
                      Colors.teal.shade500, // Couleur légèrement différente
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
