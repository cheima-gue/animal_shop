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
  final _categoryController = TextEditingController();
  final _subCategoryController = TextEditingController();
  Category? _selectedCategory;
  Category? _editingCategory;
  SubCategory? _editingSubCategory;

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
    _categoryController.dispose();
    _subCategoryController.dispose();
    super.dispose();
  }

  void _onSaveCategory() {
    if (_categoryController.text.isNotEmpty) {
      final categoryViewModel =
          Provider.of<CategoryViewModel>(context, listen: false);
      if (_editingCategory == null) {
        final newCategory = Category(nom: _categoryController.text);
        categoryViewModel.addCategory(newCategory);
      } else {
        final updatedCategory = Category(
          id: _editingCategory!.id,
          nom: _categoryController.text,
        );
        categoryViewModel.updateCategory(updatedCategory);
      }
      _clearCategoryForm();
    }
  }

  void _clearCategoryForm() {
    _categoryController.clear();
    setState(() {
      _editingCategory = null;
    });
  }

  void _onEditCategory(Category category) {
    setState(() {
      _editingCategory = category;
      _categoryController.text = category.nom;
    });
  }

  Future<void> _onDeleteCategory(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette catégorie et toutes ses sous-catégories ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Provider.of<CategoryViewModel>(context, listen: false)
          .deleteCategory(id);
    }
  }

  void _onSaveSubCategory() {
    if (_subCategoryController.text.isNotEmpty && _selectedCategory != null) {
      final categoryViewModel =
          Provider.of<CategoryViewModel>(context, listen: false);
      if (_editingSubCategory == null) {
        final newSubCategory = SubCategory(
          nom: _subCategoryController.text,
          categoryId: _selectedCategory!.id!,
        );
        categoryViewModel.addSubCategory(newSubCategory);
      } else {
        final updatedSubCategory = SubCategory(
          id: _editingSubCategory!.id,
          nom: _subCategoryController.text,
          categoryId: _selectedCategory!.id!,
        );
        categoryViewModel.updateSubCategory(updatedSubCategory);
      }
      _clearSubCategoryForm();
    }
  }

  void _clearSubCategoryForm() {
    _subCategoryController.clear();
    setState(() {
      _editingSubCategory = null;
      _selectedCategory = null;
    });
  }

  void _onEditSubCategory(SubCategory subCategory) {
    setState(() {
      _editingSubCategory = subCategory;
      _subCategoryController.text = subCategory.nom;
      _selectedCategory = context
          .read<CategoryViewModel>()
          .categories
          .firstWhere((cat) => cat.id == subCategory.categoryId);
    });
  }

  Future<void> _onDeleteSubCategory(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la sous-catégorie'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette sous-catégorie ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Provider.of<CategoryViewModel>(context, listen: false)
          .deleteSubCategory(id);
    }
  }

  Widget _buildCategoryForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editingCategory == null
                      ? 'Ajouter une Catégorie'
                      : 'Modifier la Catégorie',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_editingCategory != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearCategoryForm,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Nom de la Catégorie',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _onSaveCategory,
              icon: Icon(_editingCategory == null ? Icons.add : Icons.save),
              label: Text(_editingCategory == null
                  ? 'Ajouter Catégorie'
                  : 'Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategoryForm(CategoryViewModel categoryViewModel) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editingSubCategory == null
                      ? 'Ajouter une Sous-Catégorie'
                      : 'Modifier la Sous-Catégorie',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_editingSubCategory != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSubCategoryForm,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Category>(
              decoration: const InputDecoration(labelText: 'Catégorie Parent'),
              value: _selectedCategory,
              items: categoryViewModel.categories.map((category) {
                return DropdownMenuItem<Category>(
                  value: category,
                  child: Text(category.nom),
                );
              }).toList(),
              onChanged: (Category? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subCategoryController,
              decoration: const InputDecoration(
                labelText: 'Nom de la Sous-Catégorie',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _onSaveSubCategory,
              icon: Icon(_editingSubCategory == null ? Icons.add : Icons.save),
              label: Text(_editingSubCategory == null
                  ? 'Ajouter Sous-Catégorie'
                  : 'Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(CategoryViewModel categoryViewModel) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListView.builder(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(), // Important pour éviter les conflits de défilement
        itemCount: categoryViewModel.categories.length,
        itemBuilder: (context, index) {
          final category = categoryViewModel.categories[index];
          return ListTile(
            title: Text(category.nom),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _onEditCategory(category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _onDeleteCategory(category.id!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubCategoryList(CategoryViewModel categoryViewModel) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // Important
        itemCount: categoryViewModel.subCategories.length,
        itemBuilder: (context, index) {
          final subCategory = categoryViewModel.subCategories[index];
          final parentCategory = categoryViewModel.categories.firstWhere(
            (cat) => cat.id == subCategory.categoryId,
            orElse: () => Category(nom: 'Inconnue'),
          );
          return ListTile(
            title: Text(subCategory.nom),
            subtitle: Text('Catégorie: ${parentCategory.nom}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _onEditSubCategory(subCategory),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _onDeleteSubCategory(subCategory.id!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Catégories'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Consumer<CategoryViewModel>(
          builder: (context, categoryViewModel, child) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    // Ajout du défilement ici pour le panneau de gauche
                    child: Column(
                      children: [
                        _buildCategoryForm(),
                        const SizedBox(height: 24),
                        _buildSubCategoryForm(categoryViewModel),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                const VerticalDivider(width: 1, color: Colors.grey),
                const SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    // Ajout du défilement ici pour le panneau de droite
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Catégories',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryList(categoryViewModel),
                        const SizedBox(height: 24),
                        const Text(
                          'Sous-Catégories',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildSubCategoryList(categoryViewModel),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
