import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../services/database_helper.dart'; // Importez le DatabaseHelper

class CategoryViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Category> _categories = [];
  List<SubCategory> _subCategories = [];

  List<Category> get categories => _categories;
  List<SubCategory> get subCategories => _subCategories;

  CategoryViewModel() {
    fetchData();
  }

  // Méthode pour récupérer toutes les données au démarrage
  Future<void> fetchData() async {
    await fetchCategories();
    await fetchSubCategories();
  }

  // Récupère les catégories depuis la base de données
  Future<void> fetchCategories() async {
    _categories = await _dbHelper.getCategories();
    notifyListeners();
  }

  // Récupère les sous-catégories depuis la base de données
  Future<void> fetchSubCategories() async {
    _subCategories = await _dbHelper.getSubCategories();
    notifyListeners();
  }

  // --- Opérations CRUD pour les catégories ---
  Future<void> addCategory(Category category) async {
    await _dbHelper.insertCategory(category);
    await fetchCategories(); // Met à jour la liste depuis la DB
  }

  Future<void> updateCategory(Category updatedCategory) async {
    await _dbHelper.updateCategory(updatedCategory);
    await fetchCategories(); // Met à jour la liste depuis la DB
  }

  Future<void> deleteCategory(int id) async {
    await _dbHelper.deleteCategory(id);
    await fetchCategories(); // Met à jour la liste des catégories
    await fetchSubCategories(); // Met à jour les sous-catégories (car elles sont supprimées en cascade)
  }

  // --- Opérations CRUD pour les sous-catégories ---
  Future<void> addSubCategory(SubCategory subCategory) async {
    await _dbHelper.insertSubCategory(subCategory);
    await fetchSubCategories(); // Met à jour la liste depuis la DB
  }

  Future<void> updateSubCategory(SubCategory updatedSubCategory) async {
    await _dbHelper.updateSubCategory(updatedSubCategory);
    await fetchSubCategories(); // Met à jour la liste depuis la DB
  }

  Future<void> deleteSubCategory(int id) async {
    await _dbHelper.deleteSubCategory(id);
    await fetchSubCategories(); // Met à jour la liste depuis la DB
  }
}
