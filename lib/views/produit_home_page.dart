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
    if (produit != null) {
      _nomController.text = produit.nom;
      _prixController.text = produit.prix.toString();
      _imagePath = produit.image;
    } else {
      _nomController.clear();
      _prixController.clear();
      _imagePath = null;
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(produit == null ? 'Ajouter Produit' : 'Modifier Produit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: _prixController,
                  decoration: const InputDecoration(labelText: 'Prix'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImage,
                  child: _imagePath == null
                      ? Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.add_a_photo),
                        )
                      : Image.file(File(_imagePath!),
                          width: 100, height: 100, fit: BoxFit.cover),
                ),
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
                        content: Text('Veuillez remplir tous les champs')),
                  );
                  return;
                }

                final produitData = Produit(
                  id: produit?.id,
                  nom: _nomController.text,
                  prix: double.parse(_prixController.text),
                  image: _imagePath,
                );

                if (produit == null) {
                  await viewModel.addProduit(produitData);
                } else {
                  await viewModel.updateProduit(produitData);
                }

                Navigator.pop(context);
              },
              child: Text(produit == null ? 'Ajouter' : 'Modifier'),
            ),
          ],
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
          title: const Text('Confirmation'),
          content:
              const Text('Êtes-vous sûr de vouloir supprimer ce produit ?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer')),
          ],
        );
      },
    );
    if (confirmed == true) {
      Provider.of<ProduitViewModel>(context, listen: false).deleteProduit(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des Produits')),
      body: Consumer<ProduitViewModel>(
        builder: (context, viewModel, child) {
          final produits = viewModel.produits;
          if (produits.isEmpty) {
            return const Center(child: Text('Aucun produit'));
          }
          return ListView.builder(
            itemCount: produits.length,
            itemBuilder: (context, index) {
              final produit = produits[index];
              return ListTile(
                leading: produit.image != null
                    ? Image.file(File(produit.image!),
                        width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.image_not_supported),
                title: Text(produit.nom),
                subtitle: Text('${produit.prix} DT'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showForm(context, produit: produit)),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmDelete(context, produit.id!),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
