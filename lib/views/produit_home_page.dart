import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../viewmodels/produit_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

class ProduitHomePage extends StatefulWidget {
  const ProduitHomePage({super.key});

  @override
  State<ProduitHomePage> createState() => _ProduitHomePageState();
}

class _ProduitHomePageState extends State<ProduitHomePage> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  String? _imagePath;

  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;
  List<SubCategory> _availableSubCategories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProduitViewModel>(context, listen: false).fetchProduits();
      Provider.of<CategoryViewModel>(context, listen: false).fetchCategories();
      Provider.of<CategoryViewModel>(context, listen: false)
          .fetchSubCategories();
    });
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  Future<void> _pickImageAndSave() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String imagesDirPath = p.join(appDocDir.path, 'images');

      if (!await Directory(imagesDirPath).exists()) {
        await Directory(imagesDirPath).create(recursive: true);
      }

      final String fileName = p.basename(pickedFile.path);
      final String newPath = p.join(imagesDirPath, fileName);

      try {
        final File newImage = await File(pickedFile.path).copy(newPath);
        setState(() {
          _imagePath = newImage.path;
        });
      } catch (e) {
        print('Error saving image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Erreur lors de l\'enregistrement de l\'image: $e')),
          );
        }
      }
    }
  }

  void _filterSubCategories(Category? category, BuildContext context) {
    if (category == null) {
      _availableSubCategories = [];
    } else {
      _availableSubCategories =
          Provider.of<CategoryViewModel>(context, listen: false)
              .subCategories
              .where((subCat) => subCat.categoryId == category.id)
              .toList();
    }
    if (_selectedSubCategory != null &&
        !_availableSubCategories.contains(_selectedSubCategory)) {
      _selectedSubCategory = null;
    }
  }

  void _showForm(BuildContext context, {Produit? produit}) {
    _nomController.clear();
    _prixController.clear();
    _imagePath = null;
    _selectedCategory = null;
    _selectedSubCategory = null;
    _availableSubCategories = [];

    if (produit != null) {
      _nomController.text = produit.nom;
      _prixController.text = produit.prix.toString();
      _imagePath = produit.image;

      final categoryViewModel =
          Provider.of<CategoryViewModel>(context, listen: false);

      _selectedSubCategory = categoryViewModel.subCategories.firstWhereOrNull(
        (subCat) => subCat.id == produit.subCategoryId,
      );

      if (_selectedSubCategory != null) {
        _selectedCategory = categoryViewModel.categories.firstWhereOrNull(
          (cat) => cat.id == _selectedSubCategory!.categoryId,
        );
        _filterSubCategories(_selectedCategory, context);
      }
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            final categoryViewModel = Provider.of<CategoryViewModel>(context);
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
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _prixController,
                      decoration: const InputDecoration(
                        labelText: 'Prix (DT)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie',
                      ),
                      items: categoryViewModel.categories.map((Category cat) {
                        return DropdownMenuItem<Category>(
                          value: cat,
                          child: Text(cat.nom),
                        );
                      }).toList(),
                      onChanged: (Category? newValue) {
                        // Corrected type
                        setStateInDialog(() {
                          _selectedCategory = newValue;
                          _filterSubCategories(newValue, context);
                          _selectedSubCategory = null;
                        });
                      },
                      validator: (value) => value == null
                          ? 'Veuillez sélectionner une catégorie'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<SubCategory>(
                      value: _selectedSubCategory,
                      decoration: const InputDecoration(
                        labelText: 'Sous-Catégorie',
                      ),
                      items: _availableSubCategories.map((SubCategory subCat) {
                        return DropdownMenuItem<SubCategory>(
                          value: subCat,
                          child: Text(subCat.nom),
                        );
                      }).toList(),
                      onChanged: (SubCategory? newValue) {
                        // Corrected type
                        setStateInDialog(() {
                          _selectedSubCategory = newValue;
                        });
                      },
                      validator: (value) => value == null
                          ? 'Veuillez sélectionner une sous-catégorie'
                          : null,
                      isExpanded: true,
                      menuMaxHeight: 200,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        await _pickImageAndSave();
                        setStateInDialog(() {});
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal),
                        ),
                        child: _imagePath == null ||
                                _imagePath!.isEmpty ||
                                !File(_imagePath!).existsSync()
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
                                child: Image.file(
                                  File(_imagePath!),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image,
                                        size: 40, color: Colors.grey),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(_imagePath != null &&
                            _imagePath!.isNotEmpty &&
                            File(_imagePath!).existsSync()
                        ? 'Image sélectionnée'
                        : 'Aucune image sélectionnée'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final produitViewModel =
                        Provider.of<ProduitViewModel>(context, listen: false);
                    if (_nomController.text.isEmpty ||
                        _prixController.text.isEmpty ||
                        _selectedSubCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Veuillez remplir tous les champs et sélectionner une sous-catégorie')),
                      );
                      return;
                    }

                    final produitData = Produit(
                      id: produit?.id,
                      nom: _nomController.text,
                      prix: double.tryParse(_prixController.text) ?? 0.0,
                      image: _imagePath,
                      subCategoryId: _selectedSubCategory!.id,
                    );

                    if (produit == null) {
                      await produitViewModel.addProduit(produitData);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Produit ajouté !'),
                            backgroundColor: Colors.green, // ✅ Correction ici
                          ),
                        );
                      }
                    } else {
                      await produitViewModel.updateProduit(produitData);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Produit modifié !'),
                            backgroundColor: Colors.blue, // ✅ Correction ici
                          ),
                        );
                      }
                    }

                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    // Corrected: Use primary and onPrimary
                    foregroundColor: Colors.white, backgroundColor: Colors.teal,
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
                  // Corrected: Use primary and onPrimary
                  foregroundColor: Colors.white, backgroundColor: Colors.red,
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
      ),
      body: Consumer<ProduitViewModel>(
        builder: (context, produitViewModel, child) {
          final categoryViewModel = Provider.of<CategoryViewModel>(context);

          final produits = produitViewModel.produits;
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

              final subCategory =
                  categoryViewModel.subCategories.firstWhereOrNull(
                (subCat) => subCat.id == produit.subCategoryId,
              );

              // ignore: unnecessary_null_comparison
              final parentCategory = (subCategory != null)
                  ? categoryViewModel.categories.firstWhereOrNull(
                      (cat) => cat.id == subCategory.categoryId,
                    )
                  : null;

              final categoryNom = parentCategory?.nom ?? 'N/A';
              final subCategoryNom = subCategory?.nom ?? 'N/A';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
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
                            Text(
                              '$categoryNom > $subCategoryNom',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
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
        // These properties are still backgroundColor and foregroundColor for FloatingActionButton
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
