import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../viewmodels/produit_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';

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
  const ProduitListPage({super.key});

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
                        // Corrected type
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
                          // Corrected type
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

                List<Produit> currentProducts = produitViewModel.produits
                    .where((p) => p.nom
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase()))
                    .toList();

                if (_selectedFilterCategory != null) {
                  final subCategoriesInSelectedCategory = categoryViewModel
                      .subCategories
                      .where((subCat) =>
                          subCat.categoryId == _selectedFilterCategory!.id)
                      .map((subCat) => subCat.id)
                      .toSet();

                  currentProducts = currentProducts
                      .where((p) => subCategoriesInSelectedCategory
                          .contains(p.subCategoryId))
                      .toList();
                }

                if (_selectedFilterSubCategory != null) {
                  currentProducts = currentProducts
                      .where((p) =>
                          p.subCategoryId == _selectedFilterSubCategory!.id)
                      .toList();
                }

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
                              Provider.of<ProduitViewModel>(context,
                                      listen: false)
                                  .fetchProduits();
                              Provider.of<CategoryViewModel>(context,
                                      listen: false)
                                  .fetchCategories();
                              Provider.of<CategoryViewModel>(context,
                                      listen: false)
                                  .fetchSubCategories();
                            });
                          },
                          child: const Text('Réinitialiser les filtres'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: currentProducts.length,
                  itemBuilder: (_, index) {
                    final p = currentProducts[index];

                    final subCategory =
                        categoryViewModel.subCategories.firstWhereOrNull(
                      (subCat) => subCat.id == p.subCategoryId,
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p.prix.toStringAsFixed(2)} DT'),
                            Text(
                              '$categoryNom > $subCategoryNom',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        onTap: () {
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
