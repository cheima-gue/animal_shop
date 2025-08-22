// lib/models/produit.dart

class Produit {
  final int? id;
  final String nom;
  final double prix;
  final String? image;
  final String codeBarre;
  final int? subCategoryId; // Made nullable
  int quantiteEnStock; // Made mutable (not final)

  Produit({
    this.id,
    required this.nom,
    required this.prix,
    this.image,
    required this.codeBarre,
    this.subCategoryId,
    required this.quantiteEnStock,
  });

  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'],
      nom: map['nom'],
      prix: map['prix'],
      image: map['image'],
      codeBarre: map['codeBarre'],
      subCategoryId: map['subCategoryId'],
      quantiteEnStock: map['quantiteEnStock'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prix': prix,
      'image': image,
      'codeBarre': codeBarre,
      'subCategoryId': subCategoryId,
      'quantiteEnStock': quantiteEnStock,
    };
  }

  // ADDED: The copyWith method
  Produit copyWith({
    int? id,
    String? nom,
    double? prix,
    String? image,
    String? codeBarre,
    int? subCategoryId,
    int? quantiteEnStock,
  }) {
    return Produit(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prix: prix ?? this.prix,
      image: image ?? this.image,
      codeBarre: codeBarre ?? this.codeBarre,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      quantiteEnStock: quantiteEnStock ?? this.quantiteEnStock,
    );
  }
}
