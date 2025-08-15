// lib/services/database_helper.dart

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/produit.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../models/client.dart';

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
    print('Database path: $path');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 5, // Incrément de la version pour le stock
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
              nom TEXT NOT NULL,
              categoryId INTEGER NOT NULL,
              FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE
            )
          ''');

          // Correction: Changed 'stock' to 'quantiteEnStock' to match the model
          await db.execute('''
            CREATE TABLE produits(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nom TEXT NOT NULL,
              prix REAL NOT NULL,
              image TEXT,
              codeBarre TEXT UNIQUE NOT NULL,
              subCategoryId INTEGER,
              quantiteEnStock INTEGER NOT NULL DEFAULT 0, -- Corrected column name
              FOREIGN KEY (subCategoryId) REFERENCES sub_categories(id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE TABLE clients(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              firstName TEXT,
              lastName TEXT,
              tel TEXT UNIQUE,
              loyaltyPoints REAL NOT NULL DEFAULT 0.0
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 3) {
            await db.execute('DROP TABLE IF EXISTS clients');
            await db.execute('''
              CREATE TABLE clients(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                firstName TEXT,
                lastName TEXT,
                tel TEXT UNIQUE,
                loyaltyPoints REAL NOT NULL DEFAULT 0.0
              )
            ''');
          }
          if (oldVersion < 4) {
            final columns = await db.rawQuery('PRAGMA table_info(clients)');
            final hasLoyaltyPoints =
                columns.any((column) => column['name'] == 'loyaltyPoints');
            if (!hasLoyaltyPoints) {
              await db.execute(
                  'ALTER TABLE clients ADD COLUMN loyaltyPoints REAL NOT NULL DEFAULT 0.0');
            }
          }
          if (oldVersion < 5) {
            // Correction: Ajout de la colonne 'quantiteEnStock'
            final columns = await db.rawQuery('PRAGMA table_info(produits)');
            final hasQuantiteEnStock =
                columns.any((column) => column['name'] == 'quantiteEnStock');
            if (!hasQuantiteEnStock) {
              await db.execute(
                  'ALTER TABLE produits ADD COLUMN quantiteEnStock INTEGER NOT NULL DEFAULT 0');
            }
          }
        },
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }

  // ---------------- PRODUITS ----------------
  Future<int> insertProduit(Produit produit) async {
    final db = await database;
    try {
      return await db.insert('produits', produit.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort);
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('Un produit avec ce code-barres existe déjà.');
      }
      rethrow;
    }
  }

  Future<List<Produit>> getProduits() async {
    final db = await database;
    final maps = await db.query('produits');
    return maps.map((map) => Produit.fromMap(map)).toList();
  }

  Future<int> updateProduit(Produit produit) async {
    final db = await database;
    try {
      return await db.update('produits', produit.toMap(),
          where: 'id = ?', whereArgs: [produit.id]);
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('Un autre produit a déjà ce code-barres.');
      }
      rethrow;
    }
  }

  Future<int> deleteProduit(int id) async {
    final db = await database;
    return await db.delete('produits', where: 'id = ?', whereArgs: [id]);
  }

  Future<Produit?> getProduitByCodeBarre(String codeBarre) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'produits',
      where: 'codeBarre = ?',
      whereArgs: [codeBarre],
    );
    if (maps.isNotEmpty) {
      return Produit.fromMap(maps.first);
    }
    return null;
  }

  // ---------------- CATEGORIES ----------------
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
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
    return await db.insert('sub_categories', subCategory.toMap());
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

  // ---------------- NOUVELLES MÉTHODES POUR LES CLIENTS ----------------
  Future<int> insertClient(Client client) async {
    final db = await database;
    return await db.insert(
      'clients',
      client.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateClient(Client client) async {
    final db = await database;
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Client>> getClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clients');
    return List.generate(maps.length, (i) {
      return Client.fromMap(maps[i]);
    });
  }

  Future<Client?> getClientByTel(String tel) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: 'tel = ?',
      whereArgs: [tel],
    );
    if (maps.isNotEmpty) {
      return Client.fromMap(maps.first);
    }
    return null;
  }
}
