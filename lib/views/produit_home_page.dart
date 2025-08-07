import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/produit.dart';
import '../viewmodels/category_viewmodel.dart';
import '../viewmodels/produit_viewmodel.dart';
import '../widgets/produit_card.dart';

class ProduitHomePage extends StatefulWidget {
  const ProduitHomePage({super.key});

  @override
  State<ProduitHomePage> createState() => _ProduitHomePageState();
}

class _ProduitHomePageState extends State<ProduitHomePage> {
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

  void _showFormDialog([Produit? produit]) {
    showDialog(
      context: context,
      builder: (context) {
        return _FormProduit(produit: produit);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final produitViewModel = Provider.of<ProduitViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Produits'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Liste des Produits',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: produitViewModel.produits.isEmpty
                  ? const Center(child: Text('Aucun produit n\'a été ajouté.'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: produitViewModel.produits.length,
                      itemBuilder: (context, index) {
                        final produit = produitViewModel.produits[index];
                        return ProduitCard(
                          produit: produit,
                          onEdit: () => _showFormDialog(produit),
                          onDelete: () =>
                              produitViewModel.deleteProduit(produit.id!),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FormProduit extends StatefulWidget {
  final Produit? produit;

  const _FormProduit({this.produit});

  @override
  _FormProduitState createState() => _FormProduitState();
}

class _FormProduitState extends State<_FormProduit> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prixController = TextEditingController();
  final _codeBarreController =
      TextEditingController(); // NOUVEAU : Contrôleur pour le code-barres
  int? _selectedSubCategoryId;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.produit != null) {
      _nomController.text = widget.produit!.nom;
      _prixController.text = widget.produit!.prix.toString();
      _codeBarreController.text = widget.produit!.codeBarre ?? ''; // NOUVEAU
      _selectedSubCategoryId = widget.produit!.subCategoryId;
      _selectedImagePath = widget.produit!.image;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prixController.dispose();
    _codeBarreController.dispose(); // NOUVEAU
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState!.validate()) {
      final produit = Produit(
        id: widget.produit?.id,
        nom: _nomController.text,
        prix: double.parse(_prixController.text),
        image: _selectedImagePath,
        codeBarre: _codeBarreController.text.isEmpty
            ? null
            : _codeBarreController.text, // NOUVEAU
        subCategoryId: _selectedSubCategoryId!,
      );

      final produitViewModel =
          Provider.of<ProduitViewModel>(context, listen: false);

      if (widget.produit == null) {
        await produitViewModel.addProduit(produit);
      } else {
        await produitViewModel.updateProduit(produit);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.produit == null
          ? 'Ajouter un Produit'
          : 'Modifier le Produit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom du Produit'),
                validator: (value) =>
                    value!.isEmpty ? 'Veuillez entrer un nom' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prixController,
                decoration: const InputDecoration(labelText: 'Prix'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Veuillez entrer un prix';
                  if (double.tryParse(value) == null) return 'Prix invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller:
                    _codeBarreController, // NOUVEAU : Champ pour le code-barres
                decoration: const InputDecoration(
                    labelText: 'Code-barres (facultatif)'),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              Consumer<CategoryViewModel>(
                builder: (context, categoryViewModel, child) {
                  return DropdownButtonFormField<int>(
                    value: _selectedSubCategoryId,
                    decoration:
                        const InputDecoration(labelText: 'Sous-catégorie'),
                    items: categoryViewModel.subCategories.map((subCat) {
                      return DropdownMenuItem<int>(
                        value: subCat.id,
                        child: Text(subCat.nom),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedSubCategoryId = newValue;
                      });
                    },
                    validator: (value) => value == null
                        ? 'Veuillez choisir une sous-catégorie'
                        : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Sélectionner une image'),
                  ),
                  const SizedBox(width: 8),
                  if (_selectedImagePath != null)
                    Expanded(
                      child: Text(
                        _selectedImagePath!.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              if (_selectedImagePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Image.file(
                    File(_selectedImagePath!),
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
