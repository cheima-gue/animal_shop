// lib/models/produit.dart

class Produit {
  int? id;
  String nom;
  double prix;
  String? image;
  String? codeBarre; // NOUVEAU : Ajout du code-barres
  int subCategoryId;

  Produit({
    this.id,
    required this.nom,
    required this.prix,
    this.image,
    this.codeBarre, // NOUVEAU
    required this.subCategoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prix': prix,
      'image': image,
      'codeBarre': codeBarre, // NOUVEAU
      'subCategoryId': subCategoryId,
    };
  }

  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'],
      nom: map['nom'],
      prix: map['prix'],
      image: map['image'],
      codeBarre: map['codeBarre'], // NOUVEAU
      subCategoryId: map['subCategoryId'],
    );
  }
}
