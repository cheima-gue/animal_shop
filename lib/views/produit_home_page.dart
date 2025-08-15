// lib/views/produit_home_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../viewmodels/produit_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
import '../widgets/produit_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class ProduitHomePage extends StatefulWidget {
  const ProduitHomePage({super.key});

  @override
  State<ProduitHomePage> createState() => _ProduitHomePageState();
}

class _ProduitHomePageState extends State<ProduitHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prixController = TextEditingController();
  final _codeBarreController = TextEditingController();
  final _quantiteEnStockController = TextEditingController();
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;
  String? _imagePath;
  Produit? _editingProduit;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
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
    _codeBarreController.dispose();
    _quantiteEnStockController.dispose();
    super.dispose();
  }

  void _onEditProduit(Produit produit) {
    setState(() {
      _editingProduit = produit;
      _nomController.text = produit.nom;
      _prixController.text = produit.prix.toString();
      _codeBarreController.text = produit.codeBarre;
      _quantiteEnStockController.text = produit.quantiteEnStock.toString();
      _imagePath = produit.image;

      final categoryViewModel =
          Provider.of<CategoryViewModel>(context, listen: false);

      if (produit.subCategoryId != null) {
        final subCategory = categoryViewModel.subCategories.firstWhere(
          (sub) => sub.id == produit.subCategoryId,
          orElse: () => SubCategory(nom: '', categoryId: -1),
        );
        _selectedSubCategory = subCategory.id != -1 ? subCategory : null;
        _selectedCategory = _selectedSubCategory != null
            ? categoryViewModel.categories.firstWhere(
                (cat) => cat.id == _selectedSubCategory!.categoryId,
                orElse: () => Category(nom: ''),
              )
            : null;
      } else {
        _selectedSubCategory = null;
        _selectedCategory = null;
      }
    });
  }

  void _clearForm() {
    setState(() {
      _formKey.currentState?.reset();
      _nomController.clear();
      _prixController.clear();
      _codeBarreController.clear();
      _quantiteEnStockController.clear();
      _selectedCategory = null;
      _selectedSubCategory = null;
      _imagePath = null;
      _editingProduit = null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  Future<void> _scanBarcode() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
      '#ff6666', // Couleur de la ligne de scan
      'Annuler', // Texte du bouton d'annulation
      true, // Afficher le flash
      ScanMode.BARCODE, // Mode de scan (code-barres)
    );

    if (!mounted) return;

    if (barcodeScanRes != '-1') {
      setState(() {
        _codeBarreController.text = barcodeScanRes;
      });
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newProduit = Produit(
        id: _editingProduit?.id,
        nom: _nomController.text,
        prix: double.tryParse(_prixController.text) ?? 0.0,
        image: _imagePath,
        codeBarre: _codeBarreController.text,
        subCategoryId: _selectedSubCategory?.id,
        quantiteEnStock: int.tryParse(_quantiteEnStockController.text) ?? 0,
      );

      try {
        if (_editingProduit == null) {
          await Provider.of<ProduitViewModel>(context, listen: false)
              .addProduit(newProduit);
        } else {
          await Provider.of<ProduitViewModel>(context, listen: false)
              .updateProduit(newProduit);
        }
        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingProduit == null
                ? 'Produit ajouté avec succès !'
                : 'Produit mis à jour avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(int id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation de suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce produit ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (result == true) {
      await Provider.of<ProduitViewModel>(context, listen: false)
          .deleteProduit(id);
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Image du Produit', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _imagePath != null && File(_imagePath!).existsSync()
                  ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 50, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file),
              label: const Text('Sélectionner une image'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormProduit() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editingProduit == null
                    ? 'Ajouter un Produit'
                    : 'Modifier le Produit',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom du Produit'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom de produit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prixController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Prix'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prix';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeBarreController,
                decoration: InputDecoration(
                  labelText: 'Code-Barres',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanBarcode,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le code-barres est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantiteEnStockController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Quantité en Stock'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La quantité en stock est obligatoire';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre entier valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Consumer<CategoryViewModel>(
                builder: (context, categoryViewModel, child) {
                  return Column(
                    children: [
                      DropdownButtonFormField<Category>(
                        value: _selectedCategory,
                        decoration:
                            const InputDecoration(labelText: 'Catégorie'),
                        items: categoryViewModel.categories.map((category) {
                          return DropdownMenuItem<Category>(
                            value: category,
                            child: Text(category.nom),
                          );
                        }).toList(),
                        onChanged: (Category? newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                            _selectedSubCategory = null;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner une catégorie';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<SubCategory>(
                        value: _selectedSubCategory,
                        decoration: const InputDecoration(
                            labelText: 'Sous-catégorie du Produit'),
                        items: _selectedCategory == null
                            ? []
                            : categoryViewModel.subCategories
                                .where((sub) =>
                                    sub.categoryId == _selectedCategory!.id)
                                .map((subCategory) {
                                return DropdownMenuItem<SubCategory>(
                                  value: subCategory,
                                  child: Text(subCategory.nom),
                                );
                              }).toList(),
                        onChanged: (SubCategory? newValue) {
                          setState(() {
                            _selectedSubCategory = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner une sous-catégorie';
                          }
                          return null;
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _onSave,
                    child: Text(
                        _editingProduit == null ? 'Ajouter' : 'Mettre à jour'),
                  ),
                  if (_editingProduit != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _clearForm,
                      child: const Text('Annuler'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return Consumer<ProduitViewModel>(
      builder: (context, produitViewModel, child) {
        if (produitViewModel.produits.isEmpty) {
          return const Center(child: Text('Aucun produit n\'a été ajouté.'));
        }
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: produitViewModel.produits.length,
          itemBuilder: (context, index) {
            final produit = produitViewModel.produits[index];
            return ProduitCard(
              produit: produit,
              onEdit: () => _onEditProduit(produit),
              onDelete: () => _confirmDelete(produit.id!),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Produits'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: _buildFormProduit()),
            const SizedBox(width: 32),
            const VerticalDivider(width: 1, color: Colors.grey),
            const SizedBox(width: 32),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Liste des Produits',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildProductList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
