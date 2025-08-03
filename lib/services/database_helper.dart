// services/database_helper.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/produit.dart';

class DatabaseHelper {
  static const String tableProduit = 'produits';
  static const String columnId = 'id';
  static const String columnNom = 'nom';
  static const String columnPrix = 'prix';
  static const String columnImage = 'image';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _database = await initDb();
    return _database!;
  }

  Future<Database> initDb() async {
    final dbPath = await databaseFactory.getDatabasesPath();
    final path = '$dbPath/produits.db';

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2, // ⬅️ Version augmentée pour activer la migration
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $tableProduit (
              $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
              $columnNom TEXT NOT NULL,
              $columnPrix REAL NOT NULL,
              $columnImage TEXT
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Si l'image n'existait pas avant, on l'ajoute
          if (oldVersion < 2) {
            await db.execute(
                'ALTER TABLE $tableProduit ADD COLUMN $columnImage TEXT');
          }
        },
      ),
    );
  }

  Future<int> insertProduit(Produit produit) async {
    final db = await database;
    return await db.insert(tableProduit, produit.toMap());
  }

  Future<List<Produit>> getProduits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableProduit);
    return maps.map((map) => Produit.fromMap(map)).toList();
  }

  Future<int> updateProduit(Produit produit) async {
    if (produit.id == null) {
      throw Exception('Impossible de mettre à jour : ID du produit manquant.');
    }
    final db = await database;
    return await db.update(
      tableProduit,
      produit.toMap(),
      where: '$columnId = ?',
      whereArgs: [produit.id],
    );
  }

  Future<int> deleteProduit(int id) async {
    final db = await database;
    return await db.delete(
      tableProduit,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
