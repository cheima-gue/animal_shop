// lib/viewmodels/category_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../services/database_helper.dart';

class CategoryViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Category> _categories = [];
  List<SubCategory> _subCategories = [];

  // New property for loading state
  bool _isLoading = false;

  List<Category> get categories => _categories;
  List<SubCategory> get subCategories => _subCategories;

  // Getter for the loading state
  bool get isLoading => _isLoading;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();
    _categories = await _dbHelper.getCategories();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    await _dbHelper.insertCategory(category);
    await fetchCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _dbHelper.updateCategory(category);
    await fetchCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _dbHelper.deleteCategory(id);
    await fetchCategories();
    await fetchSubCategories();
  }

  Future<void> fetchSubCategories() async {
    _isLoading = true;
    notifyListeners();
    _subCategories = await _dbHelper.getSubCategories();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSubCategory(SubCategory subCategory) async {
    await _dbHelper.insertSubCategory(subCategory);
    await fetchSubCategories();
  }

  Future<void> updateSubCategory(SubCategory subCategory) async {
    await _dbHelper.updateSubCategory(subCategory);
    await fetchSubCategories();
  }

  Future<void> deleteSubCategory(int id) async {
    await _dbHelper.deleteSubCategory(id);
    await fetchSubCategories();
  }
}
