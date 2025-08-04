import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import '../models/produit.dart';
import '../viewmodels/produit_viewmodel.dart';

class ProduitListPage extends StatefulWidget {
  const ProduitListPage({super.key});

  @override
  _ProduitListPageState createState() => _ProduitListPageState();
}

class _ProduitListPageState extends State<ProduitListPage> {
  final TextEditingController _searchController = TextEditingController();
  // La liste filtrée n'est plus gérée par setState ici, mais par le Consumer
  // et une variable temporaire dans la fonction de build.

  @override
  void initState() {
    super.initState();
    // Nous appelons fetchProduits une fois au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProduitViewModel>(context, listen: false).fetchProduits();
    });

    // Écoutez les changements dans le champ de recherche pour filtrer
    _searchController.addListener(() {
      // Nous déclenchons une reconstruction ici via setState (qui est sûr dans le listener)
      // pour que le Consumer utilise la nouvelle chaîne de recherche.
      // En réalité, le Consumer écoutera les changements du ViewModel si on met la logique de filtre directement
      // dans son builder, mais pour que l'interface de recherche mette à jour la liste sans toucher
      // directement le viewModel, on peut utiliser un setState local.
      // Cependant, le filtrage sera fait au sein du builder du Consumer pour éviter le setState pendant le build.
      setState(
          () {}); // Un simple setState pour déclencher le Consumer à reconstruire avec la nouvelle query.
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Très important de disposer du contrôleur
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste et Recherche Produits'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un produit...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          // Pas besoin de filterProduits ici, le listener et le Consumer gèrent ça.
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          Expanded(
            // Le Consumer écoute les changements dans ProduitViewModel
            child: Consumer<ProduitViewModel>(
              builder: (context, viewModel, child) {
                // Obtenez tous les produits du ViewModel
                final allProduits = viewModel.produits;
                // Filtrez les produits basés sur la requête de recherche actuelle
                final filteredProduits = allProduits
                    .where((p) => p.nom
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase()))
                    .toList();

                if (filteredProduits.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 80, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Aucun produit disponible.'
                              : 'Aucun produit trouvé pour "${_searchController.text}"',
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchController.text.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              // setState est appelé par le listener, donc la liste se rafraîchit.
                            },
                            child: const Text('Afficher tous les produits'),
                          ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: filteredProduits.length,
                  itemBuilder: (_, index) {
                    final p = filteredProduits[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: p.image != null &&
                                  p.image!.isNotEmpty &&
                                  File(p.image!).existsSync()
                              ? Image.file(
                                  File(p.image!),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image,
                                        size: 30, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported,
                                      size: 30, color: Colors.grey),
                                ),
                        ),
                        title: Text(
                          p.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${p.prix.toStringAsFixed(2)} DT'),
                        onTap: () {
                          // Optionnel: Naviguer vers la page de gestion/modification
                          // ou afficher une SnackBar pour les détails
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Détails de ${p.nom}')),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
