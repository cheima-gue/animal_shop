// lib/views/produit_list_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../viewmodels/produit_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
import '../widgets/produit_card.dart';

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

class ProduitListPage extends StatefulWidget {
  final SubCategory? subCategory;
  const ProduitListPage({super.key, this.subCategory});

  @override
  _ProduitListPageState createState() => _ProduitListPageState();
}

class _ProduitListPageState extends State<ProduitListPage> {
  final TextEditingController _searchController = TextEditingController();
  Category? _selectedFilterCategory;
  SubCategory? _selectedFilterSubCategory;
  List<SubCategory> _availableFilterSubCategories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProduitViewModel>(context, listen: false).fetchProduits();
      Provider.of<CategoryViewModel>(context, listen: false).fetchCategories();
      Provider.of<CategoryViewModel>(context, listen: false)
          .fetchSubCategories();

      if (widget.subCategory != null) {
        final categoryViewModel =
            Provider.of<CategoryViewModel>(context, listen: false);
        _selectedFilterSubCategory = widget.subCategory;
        _selectedFilterCategory = categoryViewModel.categories.firstWhereOrNull(
          (cat) => cat.id == widget.subCategory!.categoryId,
        );
        _updateAvailableFilterSubCategories(_selectedFilterCategory);
      }
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _updateAvailableFilterSubCategories(Category? category) {
    final categoryViewModel =
        Provider.of<CategoryViewModel>(context, listen: false);
    if (category == null) {
      _availableFilterSubCategories = [];
    } else {
      _availableFilterSubCategories = categoryViewModel.subCategories
          .where((subCat) => subCat.categoryId == category.id)
          .toList();
    }
    if (_selectedFilterSubCategory != null &&
        !_availableFilterSubCategories.contains(_selectedFilterSubCategory)) {
      _selectedFilterSubCategory = null;
    }
    setState(() {});
  }

  void _showEditProductForm(Produit produit) {
    // Cette fonction doit naviguer vers votre page d'édition
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Édition de ${produit.nom}')),
    );
  }

  void _confirmDeleteProduct(Produit produit) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer ${produit.nom} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<ProduitViewModel>(context, listen: false)
                    .deleteProduit(produit.id!);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${produit.nom} supprimé avec succès')),
                );
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subCategory != null
            ? 'Produits - ${widget.subCategory!.nom}'
            : 'Liste et Recherche Produits'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Rechercher un produit...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 10),
                Consumer<CategoryViewModel>(
                  builder: (context, categoryViewModel, child) {
                    return DropdownButtonFormField<Category>(
                      value: _selectedFilterCategory,
                      decoration: const InputDecoration(
                        labelText: 'Filtrer par Catégorie',
                      ),
                      items: [
                        const DropdownMenuItem<Category>(
                          value: null,
                          child: Text('Toutes les catégories'),
                        ),
                        ...categoryViewModel.categories.map((Category cat) {
                          return DropdownMenuItem<Category>(
                            value: cat,
                            child: Text(cat.nom),
                          );
                        }),
                      ],
                      onChanged: (Category? newValue) {
                        setState(() {
                          _selectedFilterCategory = newValue;
                          _updateAvailableFilterSubCategories(newValue);
                          _selectedFilterSubCategory = null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<SubCategory>(
                  value: _selectedFilterSubCategory,
                  decoration: const InputDecoration(
                    labelText: 'Filtrer par Sous-Catégorie',
                  ),
                  items: [
                    const DropdownMenuItem<SubCategory>(
                      value: null,
                      child: Text('Toutes les sous-catégories'),
                    ),
                    ..._availableFilterSubCategories.map((SubCategory subCat) {
                      return DropdownMenuItem<SubCategory>(
                        value: subCat,
                        child: Text(subCat.nom),
                      );
                    }),
                  ],
                  onChanged: (_selectedFilterCategory == null &&
                          _availableFilterSubCategories.isEmpty)
                      ? null
                      : (SubCategory? newValue) {
                          setState(() {
                            _selectedFilterSubCategory = newValue;
                          });
                        },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ProduitViewModel>(
              builder: (context, produitViewModel, child) {
                final categoryViewModel =
                    Provider.of<CategoryViewModel>(context);
                List<Produit> currentProducts =
                    produitViewModel.produits.where((p) {
                  bool matchesSearch = p.nom
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase());
                  bool matchesCategory = true;
                  if (_selectedFilterCategory != null) {
                    final subCategory =
                        categoryViewModel.subCategories.firstWhereOrNull(
                      (subCat) => subCat.id == p.subCategoryId,
                    );
                    matchesCategory = subCategory != null &&
                        subCategory.categoryId == _selectedFilterCategory!.id;
                  }
                  bool matchesSubCategory = true;
                  if (_selectedFilterSubCategory != null) {
                    matchesSubCategory =
                        p.subCategoryId == _selectedFilterSubCategory!.id;
                  }
                  return matchesSearch && matchesCategory && matchesSubCategory;
                }).toList();

                if (currentProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 80, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text(
                          'Aucun produit trouvé avec les filtres actuels.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _selectedFilterCategory = null;
                              _selectedFilterSubCategory = null;
                              _availableFilterSubCategories = [];
                            });
                          },
                          child: const Text('Réinitialiser les filtres'),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: currentProducts.length,
                  itemBuilder: (_, index) {
                    final p = currentProducts[index];
                    return ProduitCard(
                      produit: p,
                      onEdit: () => _showEditProductForm(p),
                      onDelete: () => _confirmDeleteProduct(p),
                      onAddToCart:
                          null, // Pas de bouton "ajouter au panier" sur cette page
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
