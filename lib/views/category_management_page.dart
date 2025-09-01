// lib/views/category_management_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../viewmodels/category_viewmodel.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _categoryNameController = TextEditingController();
  final _subCategoryNameController = TextEditingController();
  Category? _selectedParentCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryViewModel>(context, listen: false).fetchCategories();
      Provider.of<CategoryViewModel>(context, listen: false)
          .fetchSubCategories();
    });
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _subCategoryNameController.dispose();
    super.dispose();
  }

  void _addCategory() {
    if (_formKey.currentState!.validate()) {
      if (_selectedParentCategory == null) {
        final newCategory = Category(nom: _categoryNameController.text);
        Provider.of<CategoryViewModel>(context, listen: false)
            .addCategory(newCategory);
      } else {
        final newSubCategory = SubCategory(
          nom: _subCategoryNameController.text,
          categoryId: _selectedParentCategory!.id!,
        );
        Provider.of<CategoryViewModel>(context, listen: false)
            .addSubCategory(newSubCategory);
      }
      _categoryNameController.clear();
      _subCategoryNameController.clear();
      setState(() {
        _selectedParentCategory = null; // Reset selection
      });
    }
  }

  void _editCategory(dynamic item) {
    if (item is Category) {
      _categoryNameController.text = item.nom;
      setState(() {
        _selectedParentCategory = null;
      });
    } else if (item is SubCategory) {
      _subCategoryNameController.text = item.nom;
      final parentCat = Provider.of<CategoryViewModel>(context, listen: false)
          .categories
          .firstWhere((cat) => cat.id == item.categoryId);
      setState(() {
        _selectedParentCategory = parentCat;
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item is Category
              ? 'Modifier la catégorie'
              : 'Modifier la sous-catégorie'),
          content: Form(
            key: _formKey,
            child: item is Category
                ? TextFormField(
                    controller: _categoryNameController,
                    decoration:
                        const InputDecoration(labelText: 'Nom de la catégorie'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom de catégorie';
                      }
                      return null;
                    },
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _subCategoryNameController,
                        decoration: const InputDecoration(
                            labelText: 'Nom de la sous-catégorie'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un nom de sous-catégorie';
                          }
                          return null;
                        },
                      ),
                      Consumer<CategoryViewModel>(
                        builder: (context, categoryViewModel, child) {
                          return DropdownButtonFormField<Category>(
                            decoration: const InputDecoration(
                                labelText: 'Catégorie parente'),
                            value: _selectedParentCategory,
                            items: categoryViewModel.categories
                                .map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat.nom),
                                    ))
                                .toList(),
                            onChanged: (Category? newValue) {
                              setState(() {
                                _selectedParentCategory = newValue;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _categoryNameController.clear();
                _subCategoryNameController.clear();
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (item is Category) {
                    final updatedCategory =
                        item.copyWith(nom: _categoryNameController.text);
                    Provider.of<CategoryViewModel>(context, listen: false)
                        .updateCategory(updatedCategory);
                  } else if (item is SubCategory) {
                    final updatedSubCategory = item.copyWith(
                      nom: _subCategoryNameController.text,
                      categoryId: _selectedParentCategory!.id,
                    );
                    Provider.of<CategoryViewModel>(context, listen: false)
                        .updateSubCategory(updatedSubCategory);
                  }
                  Navigator.of(context).pop();
                  _categoryNameController.clear();
                  _subCategoryNameController.clear();
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(dynamic item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item is Category
              ? 'Supprimer la catégorie'
              : 'Supprimer la sous-catégorie'),
          content: Text('Êtes-vous sûr de vouloir supprimer "${item.nom}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (item is Category) {
                  Provider.of<CategoryViewModel>(context, listen: false)
                      .deleteCategory(item.id!);
                } else if (item is SubCategory) {
                  Provider.of<CategoryViewModel>(context, listen: false)
                      .deleteSubCategory(item.id!);
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${item.nom} a été supprimé avec succès!')),
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
        title: const Text('Gestion des catégories'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Ajouter une nouvelle catégorie/sous-catégorie',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Consumer<CategoryViewModel>(
                        builder: (context, categoryViewModel, child) {
                          return DropdownButtonFormField<Category>(
                            decoration: const InputDecoration(
                                labelText: 'Sélectionner la catégorie parente'),
                            value: _selectedParentCategory,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Aucune (catégorie principale)'),
                              ),
                              ...categoryViewModel.categories
                                  .map((cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat.nom),
                                      ))
                                  .toList(),
                            ],
                            onChanged: (Category? newValue) {
                              setState(() {
                                _selectedParentCategory = newValue;
                                if (newValue != null) {
                                  _categoryNameController.clear();
                                } else {
                                  _subCategoryNameController.clear();
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_selectedParentCategory == null)
                        TextFormField(
                          controller: _categoryNameController,
                          decoration: const InputDecoration(
                              labelText:
                                  'Nom de la nouvelle catégorie principale'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un nom';
                            }
                            return null;
                          },
                        )
                      else
                        TextFormField(
                          controller: _subCategoryNameController,
                          decoration: const InputDecoration(
                              labelText: 'Nom de la nouvelle sous-catégorie'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un nom';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addCategory,
                        child: const Text('Ajouter'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<CategoryViewModel>(
                builder: (context, categoryViewModel, child) {
                  if (categoryViewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allItems = [
                    ...categoryViewModel.categories,
                    ...categoryViewModel.subCategories
                  ];

                  if (allItems.isEmpty) {
                    return const Center(
                        child: Text(
                            'Aucune catégorie ou sous-catégorie trouvée.'));
                  }

                  return ListView.builder(
                    itemCount: allItems.length,
                    itemBuilder: (context, index) {
                      final item = allItems[index];
                      String name = '';
                      String? subtitle;

                      if (item is Category) {
                        name = item.nom;
                      } else if (item is SubCategory) {
                        name = item.nom;
                        final parentCategory = categoryViewModel.categories
                            .firstWhere((cat) => cat.id == item.categoryId);
                        subtitle = 'Sous-catégorie de ${parentCategory.nom}';
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(name),
                          subtitle: subtitle != null ? Text(subtitle) : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.amber),
                                onPressed: () => _editCategory(item),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCategory(item),
                              ),
                            ],
                          ),
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
    );
  }
}
