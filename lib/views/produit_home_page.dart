// lib/views/produit_home_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../viewmodels/produit_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
import '../widgets/produit_card.dart'; // Assurez-vous que ProduitCard est correct
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
  final _coutAchatController = TextEditingController();
  final _margeController = TextEditingController();
  double _tva = 0.0;

  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;
  String? _imagePath;
  Produit? _editingProduit;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _coutAchatController.addListener(_calculatePrix);
    _margeController.addListener(_calculatePrix);
  }

  void _calculatePrix() {
    final double coutAchat = double.tryParse(_coutAchatController.text) ?? 0.0;
    final double marge = double.tryParse(_margeController.text) ?? 0.0;
    final double prixHT = coutAchat + (coutAchat * marge / 100);
    final double prixTTC = prixHT + (prixHT * _tva / 100);
    _prixController.text = prixTTC.toStringAsFixed(2);
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
    _coutAchatController.dispose();
    _margeController.dispose();
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

      _coutAchatController.text = produit.coutAchat.toString();
      _margeController.text = produit.marge.toString();
      _tva = produit.tva;
      _calculatePrix();

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
      _coutAchatController.clear();
      _margeController.clear();
      _selectedCategory = null;
      _selectedSubCategory = null;
      _imagePath = null;
      _editingProduit = null;
      _tva = 0.0;
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
      '#ff6666',
      'Annuler',
      true,
      ScanMode.BARCODE,
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
        coutAchat: double.tryParse(_coutAchatController.text) ?? 0.0,
        tva: _tva,
        marge: double.tryParse(_margeController.text) ?? 0.0,
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
      children: [
        if (_imagePath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Image.file(
              File(_imagePath!),
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          ),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image),
          label: const Text('Choisir une image'),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _coutAchatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Coût d\'achat',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (double.tryParse(value ?? '') == null) {
                          return 'Nombre invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _margeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Marge (%)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (double.tryParse(value ?? '') == null) {
                          return 'Nombre invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<double>(
                      value: _tva,
                      decoration: const InputDecoration(
                        labelText: 'TVA (%)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0.0, child: Text('0%')),
                        DropdownMenuItem(value: 7.0, child: Text('7%')),
                        DropdownMenuItem(value: 19.0, child: Text('19%')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _tva = value!;
                          _calculatePrix();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prixController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Prix de vente unitaire (TTC)',
                  filled: true,
                  fillColor: Colors.grey[200],
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                ),
                readOnly: true,
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
                  final filteredSubCategories = _selectedCategory != null
                      ? categoryViewModel.subCategories
                          .where(
                              (sub) => sub.categoryId == _selectedCategory!.id)
                          .toList()
                      : <SubCategory>[];

                  if (_editingProduit != null &&
                      _selectedSubCategory != null &&
                      filteredSubCategories.isEmpty) {
                    final foundCategory =
                        categoryViewModel.categories.firstWhere(
                      (cat) => cat.id == _selectedSubCategory!.categoryId,
                      orElse: () => Category(nom: '', id: -1),
                    );
                    if (foundCategory.id != -1) {
                      _selectedCategory = foundCategory;
                    }
                  }

                  return Column(
                    children: [
                      DropdownButtonFormField<Category?>(
                        decoration:
                            const InputDecoration(labelText: 'Catégorie'),
                        value: _selectedCategory,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Aucune')),
                          ...categoryViewModel.categories
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat.nom),
                                  ))
                        ],
                        onChanged: (Category? newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                            _selectedSubCategory = null;
                          });
                        },
                      ),
                      if (filteredSubCategories.isNotEmpty)
                        DropdownButtonFormField<SubCategory?>(
                          decoration: const InputDecoration(
                              labelText: 'Sous-catégorie'),
                          value: _selectedSubCategory,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Aucune')),
                            ...filteredSubCategories
                                .map((sub) => DropdownMenuItem(
                                      value: sub,
                                      child: Text(sub.nom),
                                    ))
                          ],
                          onChanged: (SubCategory? newValue) {
                            setState(() {
                              _selectedSubCategory = newValue;
                            });
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
          return const Center(child: Text('Aucun produit trouvé.'));
        }
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: produitViewModel.produits.length,
          itemBuilder: (context, index) {
            final produit = produitViewModel.produits[index];
            return ProduitCard(
              produit: produit,
              // Utilisation d'une fonction anonyme pour passer le produit et l'ID
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
      body: Row(
        children: [
          // Formulaire d'ajout/modification
          Expanded(
            flex: 2,
            child: _buildFormProduit(),
          ),
          // Liste des produits
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildProductList(),
            ),
          ),
        ],
      ),
    );
  }
}
