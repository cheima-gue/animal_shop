import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/sub_category.dart';

class CategoryViewModel extends ChangeNotifier {
  // In-memory lists for categories and sub-categories
  final List<Category> _categories = [];
  final List<SubCategory> _subCategories = [];

  int _nextCategoryId = 1;
  int _nextSubCategoryId = 1;

  List<Category> get categories => _categories;
  List<SubCategory> get subCategories => _subCategories;

  // Constructor: Initialize with some dummy data
  CategoryViewModel() {
    // Add dummy categories
    _categories.addAll([
      Category(id: _nextCategoryId++, nom: 'Animaux Domestiques'), // ID 1
      Category(id: _nextCategoryId++, nom: 'Alimentation'), // ID 2
      Category(id: _nextCategoryId++, nom: 'Électronique'), // ID 3
    ]);

    // Add dummy sub-categories (ensure categoryId matches existing category IDs)
    _subCategories.addAll([
      SubCategory(id: _nextSubCategoryId++, nom: 'Chiens', categoryId: 1),
      SubCategory(id: _nextSubCategoryId++, nom: 'Chats', categoryId: 1),
      SubCategory(id: _nextSubCategoryId++, nom: 'Oiseaux', categoryId: 1),
      SubCategory(id: _nextSubCategoryId++, nom: 'Poissons', categoryId: 1),
      SubCategory(
          id: _nextSubCategoryId++, nom: 'Fruits & Légumes', categoryId: 2),
      SubCategory(
          id: _nextSubCategoryId++, nom: 'Produits Laitiers', categoryId: 2),
      SubCategory(id: _nextSubCategoryId++, nom: 'Viandes', categoryId: 2),
      SubCategory(id: _nextSubCategoryId++, nom: 'Smartphones', categoryId: 3),
      SubCategory(id: _nextSubCategoryId++, nom: 'Ordinateurs', categoryId: 3),
      SubCategory(
          id: _nextSubCategoryId++, nom: 'Accessoires Audio', categoryId: 3),
    ]);
    notifyListeners();
  }

  // Fetches categories (simulated)
  Future<void> fetchCategories() async {
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
  }

  // Fetches sub-categories (simulated)
  Future<void> fetchSubCategories() async {
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
  }

  // --- Category CRUD operations (optional for this project, but good to have) ---
  Future<void> addCategory(Category category) async {
    category.id = _nextCategoryId++;
    _categories.add(category);
    notifyListeners();
  }

  Future<void> updateCategory(Category updatedCategory) async {
    final index = _categories.indexWhere((cat) => cat.id == updatedCategory.id);
    if (index != -1) {
      _categories[index] = updatedCategory;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(int id) async {
    _categories.removeWhere((cat) => cat.id == id);
    // Also remove associated sub-categories
    _subCategories.removeWhere((subCat) => subCat.categoryId == id);
    notifyListeners();
  }

  // --- SubCategory CRUD operations (optional) ---
  Future<void> addSubCategory(SubCategory subCategory) async {
    subCategory.id = _nextSubCategoryId++;
    _subCategories.add(subCategory);
    notifyListeners();
  }

  Future<void> updateSubCategory(SubCategory updatedSubCategory) async {
    final index = _subCategories
        .indexWhere((subCat) => subCat.id == updatedSubCategory.id);
    if (index != -1) {
      _subCategories[index] = updatedSubCategory;
      notifyListeners();
    }
  }

  Future<void> deleteSubCategory(int id) async {
    _subCategories.removeWhere((subCat) => subCat.id == id);
    notifyListeners();
  }
}
