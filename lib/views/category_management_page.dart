import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../viewmodels/category_viewmodel.dart';
import '../viewmodels/produit_viewmodel.dart'; // Import ProduitViewModel to check associated products
import 'package:provider/provider.dart';

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

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _subCategoryNameController =
      TextEditingController();

  Category? _selectedCategoryForSubCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryViewModel>(context, listen: false).fetchCategories();
      Provider.of<CategoryViewModel>(context, listen: false)
          .fetchSubCategories();
      Provider.of<ProduitViewModel>(context, listen: false)
          .fetchProduits(); // Also fetch products to check associations
    });
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _subCategoryNameController.dispose();
    super.dispose();
  }

  void _showCategoryForm(BuildContext context, {Category? category}) {
    _categoryNameController.text = category?.nom ?? '';

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(category == null
              ? 'Ajouter une Catégorie'
              : 'Modifier la Catégorie'),
          content: TextField(
            controller: _categoryNameController,
            decoration: const InputDecoration(labelText: 'Nom de la Catégorie'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final categoryViewModel =
                    Provider.of<CategoryViewModel>(context, listen: false);
                if (_categoryNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Le nom de la catégorie ne peut pas être vide')),
                  );
                  return;
                }

                if (category == null) {
                  await categoryViewModel.addCategory(
                    Category(nom: _categoryNameController.text),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Catégorie ajoutée !'),
                        backgroundColor: Colors.green, // ✅ Correction ici
                      ),
                    );
                  }
                } else {
                  await categoryViewModel.updateCategory(
                    category.copyWith(nom: _categoryNameController.text),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Catégorie modifiée !'),
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
              child: Text(category == null ? 'Ajouter' : 'Modifier'),
            ),
          ],
        );
      },
    );
  }

  void _showSubCategoryForm(BuildContext context, {SubCategory? subCategory}) {
    _subCategoryNameController.text = subCategory?.nom ?? '';
    _selectedCategoryForSubCategory = subCategory != null
        ? Provider.of<CategoryViewModel>(context, listen: false)
            .categories
            .firstWhereOrNull((cat) => cat.id == subCategory.categoryId)
        : null;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            final categoryViewModel = Provider.of<CategoryViewModel>(context);
            return AlertDialog(
              title: Text(subCategory == null
                  ? 'Ajouter une Sous-Catégorie'
                  : 'Modifier la Sous-Catégorie'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _subCategoryNameController,
                      decoration: const InputDecoration(
                          labelText: 'Nom de la Sous-Catégorie'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Category>(
                      value: _selectedCategoryForSubCategory,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie Parent',
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
                          _selectedCategoryForSubCategory = newValue;
                        });
                      },
                      validator: (value) => value == null
                          ? 'Veuillez sélectionner une catégorie parente'
                          : null,
                    ),
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
                    final categoryViewModel =
                        Provider.of<CategoryViewModel>(context, listen: false);
                    if (_subCategoryNameController.text.isEmpty ||
                        _selectedCategoryForSubCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Veuillez remplir tous les champs')),
                      );
                      return;
                    }

                    if (subCategory == null) {
                      await categoryViewModel.addSubCategory(
                        SubCategory(
                          nom: _subCategoryNameController.text,
                          categoryId: _selectedCategoryForSubCategory!.id!,
                        ),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Sous-catégorie ajoutée !'),
                            backgroundColor: Colors.green, // ✅ Déplacé ici
                          ),
                        );
                      }
                    } else {
                      await categoryViewModel.updateSubCategory(
                        subCategory.copyWith(
                          nom: _subCategoryNameController.text,
                          categoryId: _selectedCategoryForSubCategory!.id!,
                        ),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Sous-catégorie modifiée !'),
                            backgroundColor: Colors.blue, // ✅ Déplacé ici
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
                  child: Text(subCategory == null ? 'Ajouter' : 'Modifier'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context,
      {Category? category, SubCategory? subCategory}) async {
    String itemName = category?.nom ?? subCategory?.nom ?? 'cet élément';
    bool hasAssociatedProducts = false;

    if (subCategory != null) {
      final produitViewModel =
          Provider.of<ProduitViewModel>(context, listen: false);
      hasAssociatedProducts = produitViewModel.produits
          .any((p) => p.subCategoryId == subCategory.id);
    } else if (category != null) {
      final categoryViewModel =
          Provider.of<CategoryViewModel>(context, listen: false);
      hasAssociatedProducts = categoryViewModel.subCategories
          .any((subCat) => subCat.categoryId == category.id);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Confirmer la suppression',
              style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Êtes-vous sûr de vouloir supprimer "$itemName" ?'),
              if (hasAssociatedProducts)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    category != null
                        ? 'Toutes les sous-catégories et produits associés à cette catégorie seront également supprimés.'
                        : 'Tous les produits associés à cette sous-catégorie seront également supprimés.',
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              const Text('Cette action est irréversible.'),
            ],
          ),
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
        final categoryViewModel =
            Provider.of<CategoryViewModel>(context, listen: false);
        if (category != null) {
          await categoryViewModel.deleteCategory(category.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catégorie supprimée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (subCategory != null) {
          await categoryViewModel.deleteSubCategory(subCategory.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sous-catégorie supprimée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Catégories'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Catégories',
                            style: Theme.of(context).textTheme.headlineSmall),
                        ElevatedButton.icon(
                          onPressed: () => _showCategoryForm(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter Catégorie'),
                          style: ElevatedButton.styleFrom(
                            // Corrected: Use primary and onPrimary
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 1),
                    Consumer<CategoryViewModel>(
                      builder: (context, categoryViewModel, child) {
                        if (categoryViewModel.categories.isEmpty) {
                          return const Center(
                              child: Text('Aucune catégorie disponible.'));
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categoryViewModel.categories.length,
                          itemBuilder: (context, index) {
                            final category =
                                categoryViewModel.categories[index];
                            return ListTile(
                              title: Text(category.nom),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _showCategoryForm(context,
                                        category: category),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _confirmDelete(context,
                                        category: category),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sous-Catégories',
                              style: Theme.of(context).textTheme.headlineSmall),
                          ElevatedButton.icon(
                            onPressed: () => _showSubCategoryForm(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter Sous-Catégorie'),
                            style: ElevatedButton.styleFrom(
                              // Corrected: Use primary and onPrimary
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                      Expanded(
                        child: Consumer<CategoryViewModel>(
                          builder: (context, categoryViewModel, child) {
                            if (categoryViewModel.subCategories.isEmpty) {
                              return const Center(
                                  child: Text(
                                      'Aucune sous-catégorie disponible.'));
                            }
                            return ListView.builder(
                              itemCount: categoryViewModel.subCategories.length,
                              itemBuilder: (context, index) {
                                final subCategory =
                                    categoryViewModel.subCategories[index];
                                final parentCategory = categoryViewModel
                                    .categories
                                    .firstWhereOrNull(
                                  (cat) => cat.id == subCategory.categoryId,
                                );
                                return ListTile(
                                  title: Text(subCategory.nom),
                                  subtitle: Text(
                                      'Catégorie: ${parentCategory?.nom ?? 'N/A'}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => _showSubCategoryForm(
                                            context,
                                            subCategory: subCategory),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _confirmDelete(context,
                                            subCategory: subCategory),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
