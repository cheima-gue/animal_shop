import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/produit.dart';
import '../models/category.dart';
import '../models/sub_category.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    Directory documentsDirectory = await getApplicationSupportDirectory();
    String path = join(documentsDirectory.path, "product_app.db");

    // Ensure the directory exists
    if (!await Directory(dirname(path)).exists()) {
      await Directory(dirname(path)).create(recursive: true);
    }

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Category table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL UNIQUE
      )
    ''');

    // Create SubCategory table with foreign key to Category
    await db.execute('''
      CREATE TABLE sub_categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL UNIQUE,
        categoryId INTEGER NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    // Create Produit table with foreign key to SubCategory
    await db.execute('''
      CREATE TABLE produits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prix REAL NOT NULL,
        image TEXT,
        subCategoryId INTEGER NOT NULL,
        FOREIGN KEY (subCategoryId) REFERENCES sub_categories(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implement schema migrations here if your database schema changes in future versions
    // For now, we are at version 1, so this will not be called unless we increase the version.
  }

  Future<void> populateInitialData() async {
    final db = await database;

    // Check if categories already exist to prevent duplicates on app restart
    final List<Map<String, dynamic>> existingCategories =
        await db.query('categories');
    if (existingCategories.isEmpty) {
      // Insert initial categories
      await db
          .insert('categories', {'nom': 'Animaux Domestiques'}); // id will be 1
      await db.insert('categories', {'nom': 'Alimentation'}); // id will be 2
      await db.insert('categories', {'nom': 'Électronique'}); // id will be 3

      // Insert initial sub-categories (ensure categoryId matches inserted category IDs)
      await db.insert('sub_categories', {'nom': 'Chiens', 'categoryId': 1});
      await db.insert('sub_categories', {'nom': 'Chats', 'categoryId': 1});
      await db.insert('sub_categories', {'nom': 'Oiseaux', 'categoryId': 1});
      await db.insert('sub_categories', {'nom': 'Poissons', 'categoryId': 1});

      await db.insert(
          'sub_categories', {'nom': 'Fruits & Légumes', 'categoryId': 2});
      await db.insert(
          'sub_categories', {'nom': 'Produits Laitiers', 'categoryId': 2});
      await db.insert('sub_categories', {'nom': 'Viandes', 'categoryId': 2});

      await db
          .insert('sub_categories', {'nom': 'Smartphones', 'categoryId': 3});
      await db
          .insert('sub_categories', {'nom': 'Ordinateurs', 'categoryId': 3});
      await db.insert(
          'sub_categories', {'nom': 'Accessoires Audio', 'categoryId': 3});

      // Insert initial products
      await db.insert('produits', {
        'nom': 'Croquettes pour chien',
        'prix': 25.50,
        'subCategoryId': 1,
        'image': null
      });
      await db.insert('produits', {
        'nom': 'Laisse pour chat',
        'prix': 12.00,
        'subCategoryId': 2,
        'image': null
      });
      await db.insert('produits', {
        'nom': 'Jouet pour oiseaux',
        'prix': 7.99,
        'subCategoryId': 3,
        'image': null
      });
    }
  }

  // --- Produit Operations ---
  Future<int> insertProduit(Produit produit) async {
    final db = await database;
    return await db.insert('produits', produit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Produit>> getProduits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('produits');
    return List.generate(maps.length, (i) {
      return Produit.fromMap(maps[i]);
    });
  }

  Future<int> updateProduit(Produit produit) async {
    final db = await database;
    return await db.update(
      'produits',
      produit.toMap(),
      where: 'id = ?',
      whereArgs: [produit.id],
    );
  }

  Future<int> deleteProduit(int id) async {
    final db = await database;
    return await db.delete(
      'produits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Category Operations ---
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- SubCategory Operations ---
  Future<int> insertSubCategory(SubCategory subCategory) async {
    final db = await database;
    return await db.insert('sub_categories', subCategory.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SubCategory>> getSubCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sub_categories');
    return List.generate(maps.length, (i) {
      return SubCategory.fromMap(maps[i]);
    });
  }

  Future<int> updateSubCategory(SubCategory subCategory) async {
    final db = await database;
    return await db.update(
      'sub_categories',
      subCategory.toMap(),
      where: 'id = ?',
      whereArgs: [subCategory.id],
    );
  }

  Future<int> deleteSubCategory(int id) async {
    final db = await database;
    return await db.delete(
      'sub_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
