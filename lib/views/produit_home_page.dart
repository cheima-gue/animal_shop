import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../viewmodels/produit_viewmodel.dart';

class ProduitHomePage extends StatefulWidget {
  const ProduitHomePage({super.key});

  @override
  State<ProduitHomePage> createState() => _ProduitHomePageState();
}

class _ProduitHomePageState extends State<ProduitHomePage> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    // Utiliser addPostFrameCallback pour s'assurer que le contexte est prêt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProduitViewModel>(context, listen: false).fetchProduits();
    });
  }

  /// **Sélectionner une image depuis la galerie**
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  /// **Afficher formulaire d'ajout / modification**
  void _showForm(BuildContext context, {Produit? produit}) {
    // Réinitialiser les contrôleurs et le chemin de l'image
    _nomController.clear();
    _prixController.clear();
    setState(() {
      // setState est important ici pour que l'aperçu de l'image se mette à jour
      _imagePath = null;
    });

    if (produit != null) {
      _nomController.text = produit.nom;
      _prixController.text = produit.prix.toString();
      setState(() {
        _imagePath = produit.image;
      });
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          // Utiliser StatefulBuilder pour mettre à jour le dialogue
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(
                  produit == null ? 'Ajouter Produit' : 'Modifier Produit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _prixController,
                      decoration: const InputDecoration(
                        labelText: 'Prix (DT)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setStateInDialog(() {
                            // Mettre à jour l'état du dialogue
                            _imagePath = pickedFile.path;
                          });
                        }
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal),
                        ),
                        child: _imagePath == null || _imagePath!.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo,
                                      size: 40, color: Colors.teal),
                                  Text('Ajouter une image',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(File(_imagePath!),
                                    width: 120, height: 120, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(_imagePath != null && _imagePath!.isNotEmpty
                        ? 'Image sélectionnée'
                        : 'Aucune image sélectionnée'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: () async {
                    final viewModel =
                        Provider.of<ProduitViewModel>(context, listen: false);
                    if (_nomController.text.isEmpty ||
                        _prixController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Veuillez remplir le nom et le prix du produit')),
                      );
                      return;
                    }

                    final produitData = Produit(
                      id: produit?.id,
                      nom: _nomController.text,
                      prix: double.tryParse(_prixController.text) ?? 0.0,
                      image: _imagePath,
                    );

                    if (produit == null) {
                      await viewModel.addProduit(produitData);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Produit ajouté avec succès !'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      await viewModel.updateProduit(produitData);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Produit modifié avec succès !'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                    }

                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(produit == null ? 'Ajouter' : 'Modifier'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// **Afficher une confirmation avant suppression**
  Future<void> _confirmDelete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Confirmer la suppression',
              style: TextStyle(color: Colors.red)),
          content: const Text(
              'Êtes-vous sûr de vouloir supprimer ce produit ? Cette action est irréversible.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Supprimer')),
          ],
        );
      },
    );
    if (confirmed == true) {
      if (mounted) {
        Provider.of<ProduitViewModel>(context, listen: false).deleteProduit(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit supprimé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Produits'),
        // La couleur de l'appBar est définie dans ThemeData de main.dart
      ),
      body: Consumer<ProduitViewModel>(
        builder: (context, viewModel, child) {
          final produits = viewModel.produits;
          if (produits.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.widgets_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'Aucun produit ajouté pour le moment.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: produits.length,
            itemBuilder: (context, index) {
              final produit = produits[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Image du produit
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: produit.image != null &&
                                produit.image!.isNotEmpty &&
                                File(produit.image!).existsSync()
                            ? Image.file(
                                File(produit.image!),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image,
                                      size: 40, color: Colors.grey),
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported,
                                    size: 40, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 15),
                      // Nom et prix du produit
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              produit.nom,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${produit.prix.toStringAsFixed(2)} DT',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      // Boutons d'action
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showForm(context, produit: produit),
                            tooltip: 'Modifier le produit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _confirmDelete(context, produit.id!),
                            tooltip: 'Supprimer le produit',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter Produit'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
