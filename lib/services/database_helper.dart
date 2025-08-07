import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/produit.dart';
import '../models/category.dart';
import '../models/sub_category.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, 'product_app.db');
    //await deleteDatabase(path);

    // DÉCOMMENTEZ CETTE LIGNE UNE FOIS SEULEMENT pour recréer la DB
    // avec le nouveau champ 'codeBarre'.
    // Après avoir lancé l'application, commentez à nouveau cette ligne.
    // await deleteDatabase(path);

    return await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE categories(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nom TEXT NOT NULL UNIQUE
              )
            ''');

            await db.execute('''
              CREATE TABLE sub_categories(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nom TEXT NOT NULL UNIQUE,
                categoryId INTEGER NOT NULL,
                FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE
              )
            ''');

            await db.execute('''
              CREATE TABLE produits(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nom TEXT NOT NULL,
                prix REAL NOT NULL,
                image TEXT,
                codeBarre TEXT,
                subCategoryId INTEGER NOT NULL,
                FOREIGN KEY (subCategoryId) REFERENCES sub_categories(id) ON DELETE CASCADE
              )
            ''');
          },
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
        ));
  }

  // ---------------- PRODUITS ----------------
  Future<int> insertProduit(Produit produit) async {
    final db = await database;
    return await db.insert('produits', produit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Produit>> getProduits() async {
    final db = await database;
    final maps = await db.query('produits');
    return maps.map((map) => Produit.fromMap(map)).toList();
  }

  Future<int> updateProduit(Produit produit) async {
    final db = await database;
    return await db.update('produits', produit.toMap(),
        where: 'id = ?', whereArgs: [produit.id]);
  }

  Future<int> deleteProduit(int id) async {
    final db = await database;
    return await db.delete('produits', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- CATEGORIES ----------------
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- SOUS-CATEGORIES ----------------
  Future<int> insertSubCategory(SubCategory subCategory) async {
    final db = await database;
    return await db.insert('sub_categories', subCategory.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SubCategory>> getSubCategories() async {
    final db = await database;
    final maps = await db.query('sub_categories');
    return maps.map((map) => SubCategory.fromMap(map)).toList();
  }

  Future<int> updateSubCategory(SubCategory subCategory) async {
    final db = await database;
    return await db.update('sub_categories', subCategory.toMap(),
        where: 'id = ?', whereArgs: [subCategory.id]);
  }

  Future<int> deleteSubCategory(int id) async {
    final db = await database;
    return await db.delete('sub_categories', where: 'id = ?', whereArgs: [id]);
  }
}
