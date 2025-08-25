// lib/models/produit.dart

class Produit {
  int? id;
  String nom;
  double prix;
  String? image;
  String codeBarre;
  int? subCategoryId;
  int quantiteEnStock;
  double coutAchat; // NOUVEAU
  double tva; // NOUVEAU
  double marge; // NOUVEAU

  Produit({
    this.id,
    required this.nom,
    required this.prix,
    this.image,
    required this.codeBarre,
    this.subCategoryId,
    required this.quantiteEnStock,
    this.coutAchat = 0.0, // Initialisation par défaut
    this.tva = 0.0, // Initialisation par défaut
    this.marge = 0.0, // Initialisation par défaut
  });

  // Convertir un Produit en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prix': prix,
      'image': image,
      'codeBarre': codeBarre,
      'subCategoryId': subCategoryId,
      'quantiteEnStock': quantiteEnStock,
      'coutAchat': coutAchat, // Ajout de la nouvelle colonne
      'tva': tva, // Ajout de la nouvelle colonne
      'marge': marge, // Ajout de la nouvelle colonne
    };
  }

  // Créer un Produit à partir d'une Map de la base de données
  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'],
      nom: map['nom'],
      prix: map['prix'],
      image: map['image'],
      codeBarre: map['codeBarre'],
      subCategoryId: map['subCategoryId'],
      quantiteEnStock: map['quantiteEnStock'],
      coutAchat: map['coutAchat'] ??
          0.0, // Utilisation de ?? pour gérer les anciennes données
      tva: map['tva'] ?? 0.0, // Utilisation de ??
      marge: map['marge'] ?? 0.0, // Utilisation de ??
    );
  }

  Produit copyWith({
    int? id,
    String? nom,
    double? prix,
    String? image,
    String? codeBarre,
    int? subCategoryId,
    int? quantiteEnStock,
    double? coutAchat,
    double? tva,
    double? marge,
  }) {
    return Produit(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prix: prix ?? this.prix,
      image: image ?? this.image,
      codeBarre: codeBarre ?? this.codeBarre,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      quantiteEnStock: quantiteEnStock ?? this.quantiteEnStock,
      coutAchat: coutAchat ?? this.coutAchat,
      tva: tva ?? this.tva,
      marge: marge ?? this.marge,
    );
  }
}
